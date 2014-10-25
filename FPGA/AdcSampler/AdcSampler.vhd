--**********************************************************************
-- Copyright 2013 by XESS Corp <http://www.xess.com>.
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--**********************************************************************


library IEEE, XESS;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use XESS.CommonPckg.all;
use work.XessBoardPckg.all;

package AdcPckg is
  component Adc_088S_108S_128S_Intfc is
    generic (
      FREQ_G        : real := 96.0;     -- Master clock frequency in MHz.
      SAMPLE_FREQ_G : real := 1.0       -- Sample freq in MHz.
      );
    port (
      clk_i        : in  std_logic;     -- Master clock input.
      -- Sampling setup.
      analogChan_i : in  std_logic_vector;  -- Analog input of the ADC that will be sampled.
      startAddr_i  : in  std_logic_vector(SDRAM_HADDR_WIDTH_C-1 downto 0);  -- Start address for storing samples.
      numSamples_i : in  std_logic_vector(SDRAM_HADDR_WIDTH_C-1 downto 0);  --# of samples to store.
      -- Sampling control and status.
      run_i        : in  std_logic := NO;  -- When true, sampling is enabled.
      busy_o       : out std_logic := NO;  -- When true, sampling is occurring.
      done_o       : out std_logic := NO;  -- When true, sampling run has completed.
      -- RAM interface for storing samples.
      wr_o         : out std_logic := NO;  -- Write strobe to RAM.
      sampleAddr_o : out std_logic_vector(SDRAM_HADDR_WIDTH_C-1 downto 0);  -- Current sample RAM address.
      sampleData_o : out std_logic_vector(SDRAM_DATA_WIDTH_C-1 downto 0);  -- Current sample value for RAM.
      wrDone_i     : in  std_logic := NO;  -- True when sample write to RAM has completed.
      -- Interface signals to ADC chip.
      cs_bo        : out std_logic := HI;  -- Active-low ADC chip-select.
      sclk_o       : out std_logic := HI;  -- ADC clock.
      mosi_o       : out std_logic;     -- Output to ADC serial input.
      miso_i       : in  std_logic      -- Input from ADC serial output.
      );
  end component;

end package;



library IEEE, XESS;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use XESS.CommonPckg.all;
use XESS.ClkGenPckg.all;
use XESS.SyncToClockPckg.all;
use XESS.HostIoPckg.all;
use XESS.SdramCntlPckg.all;
use work.AdcPckg.all;
use work.XessBoardPckg.all;

entity AdcSampler is
  generic (
    FREQ_G        : real    := 8.0 * BASE_FREQ_C;  -- Master clock frequency in MHz.
    NUM_SAMPLES_G : natural := 10000
    );
  port (
    fpgaClk_i : in    std_logic;
    -- ADC SPI port.
    cs_bo     : out   std_logic;
    sclk_o    : out   std_logic;
    mosi_o    : out   std_logic;
    miso_i    : in    std_logic;
    -- SDRAM port.
    sdCke_o   : out   std_logic;
    sdClk_o   : out   std_logic;
    sdClkFb_i : in    std_logic;
    sdCe_bo   : out   std_logic;
    sdRas_bo  : out   std_logic;
    sdCas_bo  : out   std_logic;
    sdWe_bo   : out   std_logic;
    sdDqml_o  : out   std_logic;
    sdDqmh_o  : out   std_logic;
    sdBs_o    : out   std_logic_vector(1 downto 0);
    sdAddr_o  : out   std_logic_vector(SDRAM_SADDR_WIDTH_C-1 downto 0);
    sdData_io : inout std_logic_vector(SDRAM_DATA_WIDTH_C-1 downto 0)
    );
end entity;

architecture arch of AdcSampler is
  signal clk_s        : std_logic;
  signal inShiftDr_s  : std_logic;
  signal drck_s       : std_logic;
  signal tdi_s        : std_logic;
  signal sdramTdo_s   : std_logic;
  signal adcTdo_s     : std_logic;
  signal rd_s         : std_logic := NO;
  signal rdAddr_s     : std_logic_vector(SDRAM_HADDR_WIDTH_C-1 downto 0);
  signal rdData_s     : std_logic_vector(SDRAM_DATA_WIDTH_C-1 downto 0);
  signal dummyData_s  : std_logic_vector(SDRAM_DATA_WIDTH_C-1 downto 0);
  signal rdOpBegun_s  : std_logic;
  signal rdDone_s     : std_logic;
  signal wr_s         : std_logic := NO;
  signal wrAddr_s     : std_logic_vector(SDRAM_HADDR_WIDTH_C-1 downto 0);
  signal wrData_s     : std_logic_vector(SDRAM_DATA_WIDTH_C-1 downto 0);
  signal wrOpBegun_s  : std_logic;
  signal wrDone_s     : std_logic;
  signal adcStatus_s  : std_logic_vector(1 downto 0);
  signal busy_s       : std_logic;
  signal done_s       : std_logic;
  signal adcControl_s : std_logic_vector(8 downto 0);
  signal run_s        : std_logic;
  signal dataInc_s    : std_logic_vector(7 downto 0);
begin

  -- Take 12 MHz XuLA2 clock, generate a 96 MHz clock, send that to the SDRAM, and then
  -- input the SDRAM clock through another FPGA pin and use it as the main clock for
  -- this design. (This syncs the design and the SDRAM.) 
  uClk : ClkGen
    generic map(
      BASE_FREQ_G => BASE_FREQ_C,
      CLK_MUL_G   => 16,
      CLK_DIV_G   => 2
      )
    port map(i => fpgaClk_i, clkToLogic_o => sdClk_o);
  clk_s <= sdClkFb_i;

  -- Bring in the JTAG signals that connect to the SDRAM and ADC HostIo interface modules.
  uBscan : BscanToHostIo
    port map (
      inShiftDr_o => inShiftDr_s,
      drck_o      => drck_s,   -- Clock to the SDRAM and ADC interfaces.
      tdi_o       => tdi_s,             -- Bits to SDRAM and ADC interfaces.
      tdo_i       => sdramTdo_s,        -- Bits from the SDRAM interface.
      tdoa_i      => adcTdo_s  -- Bits from the ADC status/control interface.
      );

  -- Interface for sending SDRAM data back to PC.
  uHostIoToSdram : HostIoToRam
    generic map (
      ID_G       => "11111111",         -- The ID this module responds to: 255.
      ADDR_INC_G => 1  -- Increment address after each read to point to next data location.
      )
    port map (
      -- JTAG interface.
      inShiftDr_i    => inShiftDr_s,
      drck_i         => drck_s,
      tdi_i          => tdi_s,
      tdo_o          => sdramTdo_s,
      -- RAM signals that go to one port of the dualport SDRAM controller.
      clk_i          => clk_s,
      addr_o         => rdAddr_s,
      rd_o           => rd_s,
      dataToHost_i   => rdData_s,
      dataFromHost_o => dummyData_s,
      opBegun_i      => rdOpBegun_s,
      done_i         => rdDone_s
      );

  -- Interface for controlling/monitoring the ADC sampling.
  uHostIoToAdc : HostIoToDut
    generic map (
      ID_G => "11111110"                -- The ID this module responds to: 254.
      )
    port map (
      -- JTAG interface.
      inShiftDr_i     => inShiftDr_s,
      drck_i          => drck_s,
      tdi_i           => tdi_s,
      tdo_o           => adcTdo_s,
      -- ADC control/monitor interface.
      vectorToDut_o   => adcControl_s,
      vectorFromDut_i => adcStatus_s
      );
  run_s          <= adcControl_s(0);    -- When high, enable ADC sampling.
  adcStatus_s(0) <= busy_s;  -- High when ADC is sampling and storing data.
  adcStatus_s(1) <= done_s;  -- High when ADC has completed sampling and storing data.
  --dataInc_s <= adcControl_s(8 downto 1);  -- Increment each successive data sample by this much.

  -- Fake ADC that demonstrates how to write data values to the SDRAM.
  -- fakeADC : process (clk_s)
  -- variable addr_v, data_v : natural := 0;
  -- begin
  -- if rising_edge(clk_s) then
  -- if run_s = YES then            -- Sampling has been enabled.
  -- if addr_v < 3000000 then     -- If all samples have not been collected.
  -- busy_s <= YES;             -- Indicate ADC is busy gathering samples.
  -- if wr_s = NO then          -- If not writing sample data to SDRAM...
  -- wr_s <= YES;                -- then initiate a write.
  -- elsif wrDone_s = YES then     -- If write to SDRAM has completed...
  -- wr_s   <= NO;               -- lower SDRAM write control line...
  -- addr_v := addr_v + 1;       -- increment to next SDRAM address...
  -- data_v := data_v + TO_INTEGER(signed(dataInc_s));  -- and inc fake sample data.
  -- end if;
  -- else
  -- busy_s <= NO;  -- No longer busy once all samples have been written to SDRAM.
  -- end if;
  -- else                              -- Sampling has not been enabled.
  -- addr_v := 0;     -- Start storing samples at this address.
  -- data_v := 0;                    -- Initial fake sample data value.
  -- busy_s <= NO;    -- Indicate ADC is not busy sampling data.
  -- end if;
  -- end if;
  -- -- Send address and data to the SDRAM port.
  -- wrAddr_s <= std_logic_vector(TO_UNSIGNED(addr_v, SDRAM_HADDR_WIDTH_C));
  -- wrData_s <= std_logic_vector(TO_UNSIGNED(data_v, SDRAM_DATA_WIDTH_C));
  -- end process;

  uAdc : Adc_088S_108S_128S_Intfc
    generic map (
      FREQ_G        => FREQ_G,
      SAMPLE_FREQ_G => 1.0
      )
    port map (
      clk_i        => clk_s,
      analogChan_i => "000",
      run_i        => run_s,
      startAddr_i  => (others => '0'),
      numSamples_i => std_logic_vector(TO_UNSIGNED(NUM_SAMPLES_G, SDRAM_HADDR_WIDTH_C)),
      busy_o       => busy_s,
      done_o       => done_s,
      wr_o         => wr_s,
      sampleAddr_o => wrAddr_s,
      sampleData_o => wrData_s,
      wrDone_i     => wrDone_s,
      cs_bo        => cs_bo,
      sclk_o       => sclk_o,
      mosi_o       => mosi_o,
      miso_i       => miso_i
      );

  -- Dualport SDRAM controller.
  uDualPortSdram : DualPortSdram
    generic map (
      FREQ_G                 => 96.0,
      PORT_TIME_SLOTS_G      => "1111111111111110",
      MULTIPLE_ACTIVE_ROWS_G => true
      )
    port map (
      clk_i => clk_s,

      -- Host-side port 0 connected to USB link so the PC can access the samples from the SDRAM.
      rd0_i      => rd_s,
      opBegun0_o => rdOpBegun_s,
      addr0_i    => rdAddr_s,
      data0_o    => rdData_s,
      done0_o    => rdDone_s,

      -- Host-side port 1 connected to ADC interface so the samples can be written to SDRAM.
      wr1_i   => wr_s,
      addr1_i => wrAddr_s,
      data1_i => wrData_s,
      done1_o => wrDone_s,

      -- SDRAM side.
      sdCke_o   => sdCke_o,
      sdCe_bo   => sdCe_bo,
      sdRas_bo  => sdRas_bo,
      sdCas_bo  => sdCas_bo,
      sdWe_bo   => sdWe_bo,
      sdBs_o    => sdBs_o,
      sdAddr_o  => sdAddr_o,
      sdData_io => sdData_io,
      sdDqmh_o  => sdDqmh_o,
      sdDqml_o  => sdDqml_o
      );

end architecture;


--****************************************************************************
-- Interface to TI ADC088S, ADC108S, and ADC128S analog-to-digital converters.
--
-- This interface grabs a number of samples from the ADC chip and stores them
-- into RAM.
--
-- HOW TO USE:
--   1. Apply a clock input that can be easily divided down to 16 MHz.
--   2. Apply the code for the analog channel you want to sample.
--   3. Apply the lower RAM address where the sample storage will begin.
--   4. Apply the number of samples you want to collect.
--   5. Raise the run input.
--   6. Wait until the done output is true. The samples are now in RAM.
--   7. Once you have processed the samples in RAM, lower the run input.
--   8. To do another sample run, go to step #2.
--****************************************************************************

library IEEE, XESS;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use XESS.CommonPckg.all;
use XESS.ClkGenPckg.all;
use work.XessBoardPckg.all;

entity Adc_088S_108S_128S_Intfc is
  generic (
    FREQ_G        : real := 96.0;       -- Master clock frequency in MHz.
    SAMPLE_FREQ_G : real := 1.0         -- Sample freq in MHz.
    );
  port (
    clk_i        : in  std_logic;       -- Master clock input.
    -- Sampling setup.
    analogChan_i : in  std_logic_vector;  -- Analog input of the ADC that will be sampled.
    startAddr_i  : in  std_logic_vector(SDRAM_HADDR_WIDTH_C-1 downto 0);  -- Start address for storing samples.
    numSamples_i : in  std_logic_vector(SDRAM_HADDR_WIDTH_C-1 downto 0);  --# of samples to store.
    -- Sampling control and status.
    run_i        : in  std_logic := NO;  -- When true, sampling is enabled.
    busy_o       : out std_logic := NO;  -- When true, sampling is occurring.
    done_o       : out std_logic := NO;  -- When true, sampling run has completed.
    -- RAM interface for storing samples.
    wr_o         : out std_logic := NO;  -- Write strobe to RAM.
    sampleAddr_o : out std_logic_vector(SDRAM_HADDR_WIDTH_C-1 downto 0);  -- Current sample RAM address.
    sampleData_o : out std_logic_vector(SDRAM_DATA_WIDTH_C-1 downto 0);  -- Current sample value for RAM.
    wrDone_i     : in  std_logic := NO;  -- True when sample write to RAM has completed.
    -- Interface signals to ADC chip.
    cs_bo        : out std_logic := HI;  -- Active-low ADC chip-select.
    sclk_o       : out std_logic := HI;  -- ADC clock.
    mosi_o       : out std_logic;       -- Output to ADC serial input.
    miso_i       : in  std_logic        -- Input from ADC serial output.
    );
end entity;

architecture arch of Adc_088S_108S_128S_Intfc is
  signal adcClk_s           : std_logic;  -- ADC clock signal generated from master clock.
  signal busy_r             : std_logic := NO;  -- True when gathering samples from ADC.
  signal done_s             : std_logic := NO;  -- True when all samples are gathered.
  signal wr_r               : std_logic;  -- Write strobe for RAM.
  signal shiftReg_r         : std_logic_vector(15 downto 0);  -- Bits shifted in and out of the ADC.
  signal bitCntr_r          : natural range 0 to shiftReg_r'length-1;  -- Shift reg bit counter.
  constant BITS_PER_FRAME_C : natural   := shiftReg_r'length;  -- # bits in ADC conversion frame.
  constant MAX_ADDR_C       : natural   := 2**sampleAddr_o'length - 1;  -- Highest possible RAM address.
  subtype Address_t is natural range 0 to MAX_ADDR_C;  -- Address sub type.
  signal sampleCntr_r       : Address_t := 1;  -- Holds # of samples that still need to be taken.
  signal sampleAddr_r       : Address_t;  -- Holds RAM address where next sample will be stored.
  signal sampleData_r       : std_logic_vector(sampleData_o'range);  -- Sample from ADC chip.
begin

  -- Generate a clock to shift all the ADC bits within the ADC conversion frame.
  uAdcClk : SlowClkGen
    generic map (INPUT_FREQ_G => FREQ_G, OUTPUT_FREQ_G => SAMPLE_FREQ_G * real(BITS_PER_FRAME_C))
    port map (clk_i           => clk_i, clk_o => adcClk_s);

  -- The sample run is done when the sample counter reaches 0.
  done_s <= YES when sampleCntr_r = 0 else NO;

  process(adcClk_s)
  begin
    if falling_edge(adcClk_s) then
      -- By default, shift out bits to ADC and shift in bits from ADC.
      shiftReg_r <= shiftReg_r(shiftReg_r'high-1 downto 0) & miso_i;
      bitCntr_r  <= bitCntr_r + 1;

      -- Release the write strobe and inc address once a sample has been written into RAM. 
      if wr_r = YES and wrDone_i = YES then
        wr_r         <= NO;
        sampleAddr_r <= sampleAddr_r + 1;
      end if;

      -- If the run input is not asserted, then clear the busy
      -- and done flags in preparation for when the next sampling run does begin.
      if run_i = NO then                -- run=NO, busy=XXX, done=XXX.
        busy_r       <= NO;
        sampleCntr_r <= TO_INTEGER(unsigned(numSamples_i));  -- This clears the done flag.
        sampleAddr_r <= TO_INTEGER(unsigned(startAddr_i));

      -- The run input is asserted, but sampling isn't occurring.
      elsif busy_r = NO then            -- run=YES, busy=NO, done=XXX.
        if done_s = NO then             -- run=YES, busy=NO, done=NO.
          -- A sampling run has not been completed, so get ready to start one.
          busy_r     <= YES;  -- Sampling is occurring, ADC is enabled.
          shiftReg_r <= "00" & analogChan_i & "00000000000";  -- Init shift register.
          bitCntr_r  <= 1;    -- First bit of shift register is being output.
        else                            -- run=YES, busy=NO, done=YES.
          -- A sampling run has completed, so just hold still.
          null;
        end if;

      -- Sampling is occurring but all the samples haven't been collected.
      elsif done_s = NO then            -- run=YES, busy=YES, done=NO.
        if bitCntr_r = 0 then
          -- Output the sample taken in the previous 16-cycle interval.
          sampleData_r <= "0000" & shiftReg_r(10 downto 0) & miso_i;
          wr_r         <= YES;
          sampleCntr_r <= sampleCntr_r - 1;  -- Got another sample, so dec the sample counter.
          shiftReg_r   <= "00" & analogChan_i & "00000000000";  -- Init shift register for the next sample.
        end if;

      -- Sampling run has completed, but don't shut off the ADC chip-select until
      -- all the bits in the current frame are clocked out.
      else                              -- run=YES, busy=YES, done=YES.
        if bitCntr_r = BITS_PER_FRAME_C - 1 then
          busy_r <= NO;
        end if;

      end if;
    end if;
  end process;

  -- Output control and data signal to the ADC chip.
  sclk_o <= adcClk_s;    -- The ADC clock input is always toggling.
  cs_bo  <= not busy_r;  -- The ADC is enabled when the interface is busy sampling.
  mosi_o <= shiftReg_r(shiftReg_r'high);  -- MSB of shift register goes to ADC DIN pin.

  -- Output address, data and write signals for storing the sample into RAM.
  sampleAddr_o <= std_logic_vector(TO_UNSIGNED(sampleAddr_r, sampleAddr_o'length));
  sampleData_o <= sampleData_r;
  wr_o         <= wr_r;

  -- Output the signals that show the status of the sampling run.
  busy_o <= busy_r;
  done_o <= done_s;

end architecture;

