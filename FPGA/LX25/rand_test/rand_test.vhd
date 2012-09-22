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
-- (c)2011 - X Engineering Software Systems Corp. (www.xess.com)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.CommonPckg.all;
use work.ClkGenPckg.all;
use work.RandPckg.all;
use work.HostIoPckg.all;

entity rand_test is
  port(
    fpgaClk_i : std_logic
    );
end entity;

architecture Behavioral of rand_test is
  signal clk_s       : std_logic;
  signal randCke_s   : std_logic;
  signal wr_s        : std_logic;
  signal rd_s        : std_logic;
  signal rand_s      : std_logic_vector(11 downto 0);
  signal seed_s      : std_logic_vector(rand_s'range);
  signal inShiftDr_s : std_logic;
  signal drck_s      : std_logic;
  signal tdi_s       : std_logic;
  signal tdo_s       : std_logic;
  signal addr_s      : std_logic_vector(0 downto 0);
begin

  UClkGen : ClkGen port map(i => fpgaClk_i, o => clk_s);

  randCke_s <= wr_s or rd_s;

  URandGen : RandGen
    port map(
      clk_i  => clk_s,
      cke_i  => randCke_s,
      ld_i   => wr_s,
      seed_i => seed_s,
      rand_o => rand_s
      );

  UHostIoToRand : HostIoToRam
    generic map(
      FPGA_DEVICE_G => SPARTAN6, 
      ID_G => "00000001", 
      SIMPLE_G => true
      )
    port map(
      clk_i          => clk_s,
      addr_o         => addr_s,
      wr_o           => wr_s,
      dataFromHost_o => seed_s,
      rd_o           => rd_s,
      dataToHost_i   => rand_s
      );

end architecture;

