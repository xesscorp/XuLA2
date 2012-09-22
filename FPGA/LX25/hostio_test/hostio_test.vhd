----------------------------------------------------------------------------------
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
-- 02111-1307, USA.
--
-- ©2011 - X Engineering Software Systems Corp. (www.xess.com)
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Test of modules for passing bits back and forth from the host PC
-- to FPGA application logic through the JTAG port.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.CommonPckg.all;
use work.ClkgenPckg.all;
use work.HostIoPckg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity hostio_test is
  port (
    fpgaClk_i : in  std_logic;
    chan_io   : out std_logic_vector(7 downto 0)
    );
end hostio_test;


architecture Behavioral of hostio_test is
  
  signal clk_s          : std_logic;
  signal inShiftDr_s    : std_logic;
  signal drck_s         : std_logic;
  signal tdi_s          : std_logic;
  signal tdo_s          : std_logic;
  signal tdoReg_s       : std_logic;
  signal reg_r          : std_logic_vector(31 downto 0) := "11011110101011011011111011101111";
  signal addrReg_s      : std_logic_vector(0 downto 0);
  signal dataToReg_s    : std_logic_vector(reg_r'range);
  signal wrReg_s        : std_logic;
  signal tdoBram_s      : std_logic;
  signal addrBram_s     : std_logic_vector(9 downto 0);
  signal dataToBram_s   : std_logic_vector(15 downto 0);
  signal dataFromBram_s : std_logic_vector(15 downto 0);
  signal wrBram_s       : std_logic;
  signal tdoCntr_s      : std_logic;
  signal cntr_r         : std_logic_vector(3 downto 0)  := "1011";
  signal cntrUpDn_s     : std_logic_vector(0 downto 0);
  signal cntrClk_s      : std_logic;
  signal tdoSub_s       : std_logic;
  signal toSub_s        : std_logic_vector(15 downto 0);
  signal difference_s   : std_logic_vector(8 downto 0);

begin

  -- Generate a faster clock from the 12 MHz clock for the FPGA application logic.
  UClkGen : ClkGen generic map (CLK_MUL_G => 3, CLK_DIV_G => 3) port map (I => fpgaClk_i, O => clk_s);

  -- This is the main entry point for the JTAG signals that communicate with this design.
  UBscanToHostIo : BscanToHostIo
    generic map (
      FPGA_DEVICE_G => SPARTAN6
      )
    port map (
      inShiftDr_o => inShiftDr_s,  -- True when bits are shifting between the PC host and the FPGA.
      drck_o      => drck_s,            -- Bit shift clock.
      tdi_o       => tdi_s,             -- Bits from the host PC.
      tdo_i       => tdo_s              -- Bits that go back to the host PC.
      );

  -- OR the bits from all the user's modules and send them back to the PC.
  -- (Non-selected modules pull their TDO outputs low, so only bits from the active module are transferred.)
  tdo_s <= tdoReg_s or tdoBram_s or tdoCntr_s or tdoSub_s;

  -- This module interfaces a single register to the JTAG port so that it can be read/written by the PC host.
  UHostIoToReg : HostIoToRam
    generic map (
      ID_G => "00000001"  -- The identifier used by the PC host to access this module.
      )
    port map (
      -- Connections to the JTAG signals.
      inShiftDr_i    => inShiftDr_s,
      drck_i         => drck_s,
      tdi_i          => tdi_s,
      tdo_o          => tdoReg_s,  -- Bits from the attached register back to the PC host.
      -- Interface to the memory.
      addr_o         => addrReg_s,  -- This is just a dummy output to set the bus-width of this unconstrained output.
      clk_i          => clk_s,  -- Put this interface in the same clock domain as the register.
      wr_o           => wrReg_s,
      dataFromHost_o => dataToReg_s,  -- Get new register contents from PC host here.
      dataToHost_i   => reg_r   -- Send register contents back to PC host here.
      );

  -- This is the simple readable/writable register that interfaces to the module above.
  process(clk_s)
  begin
    if rising_edge(clk_s) then
      if wrReg_s = HI then
        reg_r <= dataToReg_s;
      end if;
    end if;
  end process;

  -- This module interfaces a block RAM to the JTAG port so that it can be read/written by the PC host.
  UHostIoToBram : HostIoToRam
    generic map (
      ID_G => "00000010"  -- The identifier used by the PC host to access this module.
      )
    port map (
      inShiftDr_i    => inShiftDr_s,
      drck_i         => drck_s,
      tdi_i          => tdi_s,
      tdo_o          => tdoBram_s,  -- Bits from the attached BRAM to the PC host.
      -- Interface to the memory.
      clk_i          => clk_s,  -- Put this interface in the same clock domain as the BRAM.
      addr_o         => addrBram_s,
      wr_o           => wrBram_s,
      dataFromHost_o => dataToBram_s,
      dataToHost_i   => dataFromBram_s
      );

  -- This is the block RAM that interfaces to the module above.
  URAMB16_S18 : RAMB16_S18
    generic map (
      INIT       => X"000000000",  --  Value of output RAM registers at startup
      SRVAL      => X"000000000",       --  Ouput value upon SSR assertion
      write_mode => "WRITE_FIRST"  --  WRITE_FIRST, READ_FIRST or NO_CHANGE
      )
    port map (
      DO   => dataFromBram_s,           -- 32-bit Data Output
      ADDR => addrBram_s,               -- 9-bit Address Input
      CLK  => clk_s,                    -- Clock
      DI   => dataToBram_s,             -- 32-bit Data Input
      DIP  => "00",
      EN   => HI,                       -- RAM Enable Input
      SSR  => LO,                       -- Synchronous Set/Reset Input
      WE   => wrBram_s                  -- Write Enable Input
      );

  -- This module interfaces a counter to the JTAG port so that it can be read/modified by the PC host.
  UHostIoToCntr : HostIoToDut
    generic map (
      ID_G => "00000011"  -- The identifier used by the PC host to access this module.
      )
    port map (
      inShiftDr_i     => inShiftDr_s,
      drck_i          => drck_s,
      tdi_i           => tdi_s,
      tdo_o           => tdoCntr_s,
      -- Test vector I/O.
      clkToDut_o      => cntrClk_s,
      vectorToDut_o   => cntrUpDn_s,
      vectorFromDut_i => cntr_r
      );

  -- This is the counter that interfaces to the module above.
  process(cntrClk_s)
  begin
    if rising_edge(cntrClk_s) then
      case cntrUpDn_s is
        when "1" =>
          cntr_r <= cntr_r + 1;
        when others =>
          cntr_r <= cntr_r - 1;
      end case;
    end if;
  end process;
  
  -- This module interfaces a subtractor to the JTAG port so that it can be exercised by the PC host.
  UHostIoToSubtractor : HostIoToDut
    generic map (
      ID_G => "00000100"  -- The identifier used by the PC host to access this module.
      )
    port map (
      inShiftDr_i     => inShiftDr_s,
      drck_i          => drck_s,
      tdi_i           => tdi_s,
      tdo_o           => tdoSub_s,
      -- Test vector I/O.
      vectorToDut_o   => toSub_s,
      vectorFromDut_i => difference_s
      );
      
  -- This is the subtractor that interfaces to the module above.
  difference_s <= ('0' & toSub_s(7 downto 0)) - toSub_s(15 downto 8);

  -- Output a byte of the test register so we can probe it externally.
  chan_io(7 downto 0) <= reg_r(7 downto 0);

end Behavioral;
