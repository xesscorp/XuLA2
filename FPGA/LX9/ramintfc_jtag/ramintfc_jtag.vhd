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
-- ©1997-2012 - X Engineering Software Systems Corp. (www.xess.com)
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- SDRAM/RAM upload/download via JTAG.
-- See userinstr_jtag.vhd for details of operation.
--------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use work.CommonPckg.all;
use work.UserInstrJtagPckg.all;
use work.SdramCntlPckg.all;
use work.ClkgenPckg.all;

library UNISIM;
use UNISIM.VComponents.all;


entity ramintfc_jtag is
  generic(
    BASE_FREQ_G   : real    := 12.0;    -- base frequency in MHz
    CLK_MUL_G     : natural := 25;      -- multiplier for base frequency
    CLK_DIV_G     : natural := 3;       -- divider for base frequency
    PIPE_EN_G     : boolean := true;
    DATA_WIDTH_G  : natural := 16;      -- width of data
    HADDR_WIDTH_G : natural := 24;      -- host-side address width
    SADDR_WIDTH_G : natural := 13;      -- SDRAM address bus width
    NROWS_G       : natural := 8192;    -- number of rows in each SDRAM bank
    NCOLS_G       : natural := 512      -- number of words in each row
    );
  port(
    fpgaClk_i : in    std_logic;  -- main clock input from external clock source
    sdClk_o   : out   std_logic;        -- clock to SDRAM
    sdClkFb_i : in    std_logic;        -- SDRAM clock comes back in
    sdCke_o   : out   std_logic;        -- Clock-enable to SDRAM.
    sdCe_bo   : out   std_logic;        -- Chip-select to SDRAM.
    sdRas_bo  : out   std_logic;        -- SDRAM row address strobe.
    sdCas_bo  : out   std_logic;        -- SDRAM column address strobe.
    sdWe_bo   : out   std_logic;        -- SDRAM write enable.
    sdBs_o    : out   std_logic_vector(1 downto 0);  -- SDRAM bank address.
    sdAddr_o  : out   std_logic_vector(SADDR_WIDTH_G-1 downto 0);  -- SDRAM row/column address.
    sdData_io : inout std_logic_vector(DATA_WIDTH_G-1 downto 0);  -- Data to/from SDRAM.
    sdDqmh_o  : out   std_logic;  -- Enable upper-byte of SDRAM databus if true.
    sdDqml_o  : out   std_logic  -- Enable lower-byte of SDRAM databus if true.
    );
end entity;


architecture arch of ramintfc_jtag is

  constant FREQ_G : real := (BASE_FREQ_G * real(CLK_MUL_G)) / real(CLK_DIV_G);
  signal clk_s    : std_logic;
  signal clkP_s   : std_logic;
  signal clkN_s   : std_logic;

  -- signals to/from the JTAG BSCAN module
  signal bscanDrck_s   : std_logic;     -- JTAG clock from BSCAN module
  signal bscanReset_s  : std_logic;     -- true when BSCAN module is reset
  signal bscanSel_s    : std_logic;     -- true when BSCAN module selected
  signal bscanShift_s  : std_logic;     -- true when TDI & TDO are shifting data
  signal bscanUpdate_s : std_logic;     -- BSCAN TAP is in update-dr state
  signal bscanTdi_s    : std_logic;     -- data received on TDI pin
  signal bscanTdo_s    : std_logic;     -- scan data sent to TDO pin

  -- signals to/from the SDRAM controller
  signal sdramReset_s   : std_logic;    -- reset to SDRAM controller
  signal hRd_s          : std_logic;    -- host read enable
  signal hWr_s          : std_logic;    -- host write enable
  signal earlyOpBegun_s : std_logic;  -- true when current read/write has begun
  signal done_s         : std_logic;  -- true when current read/write is done_s
  signal hAddr_s        : std_logic_vector(HADDR_WIDTH_G-1 downto 0);  -- host address
  signal hDIn_s         : std_logic_vector(DATA_WIDTH_G-1 downto 0);  -- data input from host
  signal hDOut_s        : std_logic_vector(DATA_WIDTH_G-1 downto 0);  -- host data output to host
  
begin

  -- Generate a 100 MHz clock from the 12 MHz input clock.
  u0 : Clkgen
    generic map (BASE_FREQ_G => BASE_FREQ_G, CLK_MUL_G => CLK_MUL_G, CLK_DIV_G => CLK_DIV_G)
    port map(I               => fpgaClk_i, O => clkP_s, O_b => clkN_s);
  u1 : ClkToLogic
    port map(clk_i => clkP_s, clk_ib => clkN_s, clk_o => sdClk_o);

  clk_s <= sdClkFb_i;  -- main clock is SDRAM clock fed back into FPGA

  -- Generate a reset signal for the SDRAM controller.  
  process(clk_s)
    constant reset_dly_c : natural                        := 10;
    variable rst_cntr    : natural range 0 to reset_dly_c := 0;
  begin
    if rising_edge(clk_s) then
      sdramReset_s <= NO;
      if rst_cntr < reset_dly_c then
        sdramReset_s <= YES;
        rst_cntr     := rst_cntr + 1;
      end if;
    end if;
  end process;

  -- Boundary-scan interface to FPGA JTAG port.
  u_bscan : BSCAN_SPARTAN6
    generic map(
      JTAG_CHAIN => 1
      )
    port map(
      DRCK  => bscanDrck_s,   -- Data clock after USER instruction received.
      RESET => bscanReset_s,            -- JTAG TAP FSM reset.
      SEL   => bscanSel_s,    -- True when USER instruction enters IR.
      SHIFT => bscanShift_s,  -- True when JTAG TAP FSM is in the SHIFT-DR state.
      TDI   => bscanTdi_s,    -- Data bits from the host arrive through here.
      TDO   => bscanTdo_s  -- Bits from the FPGA app. logic go to the TDO pin and back to the host.
      );

  -- JTAG interface
  u3 : UserInstrJtag
    generic map(
      FPGA_TYPE_G        => SPARTAN3_G,
      ENABLE_RAM_INTFC_G => true,
      DATA_WIDTH_G       => DATA_WIDTH_G,
      ADDR_WIDTH_G       => HADDR_WIDTH_G
      )
    port map(
      clk           => clk_s,
      bscan_drck    => bscanDrck_s,
      bscan_reset   => bscanReset_s,
      bscan_sel     => bscanSel_s,
      bscan_shift   => bscanShift_s,
      bscan_update  => bscanUpdate_s,
      bscan_tdi     => bscanTdi_s,
      bscan_tdo     => bscanTdo_s,
      rd            => hRd_s,
      wr            => hWr_s,
      begun         => earlyOpBegun_s,
      done          => done_s,
      addr          => hAddr_s,
      din           => hDOut_s,
      dout          => hDIn_s,
      test_progress => "11",
      test_failed   => NO
      );

  -- SDRAM controller
  u4 : SdramCntl
    generic map(
      FREQ_G        => FREQ_G,
      IN_PHASE_G    => true,
      PIPE_EN_G     => PIPE_EN_G,
      MAX_NOP_G     => 10000,
      DATA_WIDTH_G  => DATA_WIDTH_G,
      NROWS_G       => NROWS_G,
      NCOLS_G       => NCOLS_G,
      HADDR_WIDTH_G => HADDR_WIDTH_G,
      SADDR_WIDTH_G => SADDR_WIDTH_G
      )
    port map(
      clk_i          => clk_s,  -- master clock from external clock source (unbuffered)
      lock_i         => YES,    -- no DLLs, so frequency is always locked
      rst_i          => sdramReset_s,   -- reset
      rd_i           => hRd_s,  -- host-side SDRAM read control from memory tester
      wr_i           => hWr_s,  -- host-side SDRAM write control from memory tester
      earlyOpBegun_o => earlyOpBegun_s,  -- SDRAM memory read/write done_s indicator
      done_o         => done_s,  -- SDRAM memory read/write done_s indicator
      addr_i         => hAddr_s,  -- host-side address from memory tester to SDRAM
      data_i         => hDIn_s,  -- test data pattern from memory tester to SDRAM
      data_o         => hDOut_s,        -- SDRAM data output to memory tester
      sdCke_o        => sdCke_o,
      sdCe_bo        => sdCe_bo,
      sdRas_bo       => sdRas_bo,       -- SDRAM RAS
      sdCas_bo       => sdCas_bo,       -- SDRAM CAS
      sdWe_bo        => sdWe_bo,        -- SDRAM write-enable
      sdBs_o         => sdBs_o,         -- SDRAM bank address
      sdAddr_o       => sdAddr_o,       -- SDRAM address
      sdData_io      => sdData_io,      -- data to/from SDRAM
      sdDqmh_o       => sdDqmh_o,  -- upper-byte enable for SDRAM data bus.
      sdDqml_o       => sdDqml_o  -- lower-byte enable for SDRAM data bus.
      );

end architecture;
