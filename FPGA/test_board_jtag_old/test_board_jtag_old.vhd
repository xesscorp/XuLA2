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
-- Test board via JTAG.
----------------------------------------------------------------------------------


library IEEE, XESS;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use XESS.CommonPckg.all;
use XESS.UserInstrJtagPckg.all;
use XESS.TestBoardCorePckg.all;
use XESS.ClkgenPckg.all;
use work.XessBoardPckg.all;

library UNISIM;
use UNISIM.VComponents.all;

entity test_board_jtag is
  generic(
    BASE_FREQ_G : real             := BASE_FREQ_C;   -- Base frequency in MHz.
    -- Using a MUL/DIV of 25/6 causes the diagnostic to fail for an unknown reason.
    CLK_MUL_G   : natural          := 25;  -- Multiplier for base frequency.
    CLK_DIV_G   : natural          := 3;    -- Divider for base frequency.
    PIPE_EN_G   : boolean          := true  -- Enable SDRAM controller pipelining.
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
    sdAddr_o  : out   std_logic_vector(SDRAM_SADDR_WIDTH_C-1 downto 0);  -- SDRAM row/column address.
    sdData_io : inout std_logic_vector(SDRAM_DATA_WIDTH_C-1 downto 0);  -- Data to/from SDRAM.
    sdDqmh_o  : out   std_logic;  -- Enable upper-byte of SDRAM databus if true.
    sdDqml_o  : out   std_logic  -- Enable lower-byte of SDRAM databus if true.
    );
end entity;


architecture arch of test_board_jtag is
  constant FREQ_C        : real                          := (BASE_FREQ_G * real(CLK_MUL_G)) / real(CLK_DIV_G);

  signal clk_s          : std_logic;
  signal clkP_s, clkN_s : std_logic;    -- Positive and negative clock phases.

  -- signals to/from the JTAG BSCAN module
  signal bscan_drck   : std_logic;      -- JTAG clock from BSCAN module
  signal bscan_reset  : std_logic;      -- true when BSCAN module is reset
  signal bscan_sel    : std_logic;      -- true when BSCAN module selected
  signal bscan_shift  : std_logic;  -- true when TDI & TDO are shifting data
  signal bscan_update : std_logic;      -- BSCAN TAP is in update-dr state
  signal bscan_tdi    : std_logic;      -- data received on TDI pin
  signal bscan_tdo    : std_logic;      -- scan data sent to TDO pin

  signal run_test_s      : std_logic;
  signal reset_s         : std_logic;
  signal test_progress_s : std_logic_vector(1 downto 0);  -- progress of the test
  signal test_failed_s   : std_logic;  -- true if an error was found during the test
begin

  -- Generate 100 MHz clock from 12 MHz input clock.
  u0 : Clkgen
    generic map (BASE_FREQ_G => BASE_FREQ_G, CLK_MUL_G => CLK_MUL_G, CLK_DIV_G => CLK_DIV_G)
    port map(I               => fpgaClk_i, O => clkP_s, O_b => clkN_s);
  -- Transfer clock from clock network to output pin.
  u1 : ClkToLogic
    port map(clk_i => clkP_s, clk_ib => clkN_s, clk_o => sdClk_o);

  clk_s <= sdClkFb_i;  -- main clock is SDRAM clock fed back into FPGA

  -- Boundary-scan interface to FPGA JTAG port.
  u_bscan : BSCAN_SPARTAN6
    generic map(
      JTAG_CHAIN => 1
      )
    port map(
      DRCK  => bscan_drck,   -- Data clock after USER instruction received.
      RESET => bscan_reset,             -- JTAG TAP FSM reset.
      SEL   => bscan_sel,    -- True when USER instruction enters IR.
      SHIFT => bscan_shift,  -- True when JTAG TAP FSM is in the SHIFT-DR state.
      TDI   => bscan_tdi,    -- Data bits from the host arrive through here.
      TDO   => bscan_tdo  -- Bits from the FPGA app. logic go to the TDO pin and back to the host.
      );

  -- JTAG interface
  u2 : UserinstrJtag
    generic map(
      ENABLE_TEST_INTFC_G => true,
      DATA_WIDTH_G        => SDRAM_DATA_WIDTH_C
      )
    port map(
      clk           => clk_s,
      bscan_drck    => bscan_drck,
      bscan_reset   => bscan_reset,
      bscan_sel     => bscan_sel,
      bscan_shift   => bscan_shift,
      bscan_update  => bscan_update,
      bscan_tdi     => bscan_tdi,
      bscan_tdo     => bscan_tdo,
      begun         => YES,                 -- don't care
      done          => YES,                 -- don't care
      din           => "0000000000000000",  -- don't care
      run_test      => run_test_s,
      test_progress => test_progress_s,
      test_failed   => test_failed_s
      );

  reset_s <= not run_test_s;

  -- board diagnostic unit
  u3 : TestBoardCore
    generic map(
      FREQ_G        => FREQ_C,
      PIPE_EN_G     => PIPE_EN_G
      )
    port map(
      rst_i      => reset_s,
      do_again_i => NO,
      clk_i      => clk_s,
      progress_o => test_progress_s,
      err_o      => test_failed_s,
      sdCke_o    => sdCke_o,
      sdCe_bo    => sdCe_bo,
      sdRas_bo   => sdRas_bo,           -- SDRAM RAS
      sdCas_bo   => sdCas_bo,           -- SDRAM CAS
      sdWe_bo    => sdWe_bo,            -- SDRAM write-enable
      sdBs_o     => sdBs_o,             -- SDRAM bank address
      sdAddr_o   => sdAddr_o,           -- SDRAM address
      sdData_io  => sdData_io,          -- data to/from SDRAM
      sdDqmh_o   => sdDqmh_o,   -- upper-byte enable for SDRAM data bus.
      sdDqml_o   => sdDqml_o    -- lower-byte enable for SDRAM data bus.
      );

end architecture;

