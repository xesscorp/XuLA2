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

library ieee, XESS;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use XESS.CommonPckg.all;
use XESS.ClkGenPckg.all;
use XESS.HostIoPckg.all;
use XESS.PulsePckg.all;
--library unisim;
--use unisim.vcomponents.all;

entity RGBLed is
  port (
    fpgaClk_i  : in  std_logic;
    redLed_o : out std_logic;
    grnLed_o : out std_logic;
    bluLed_o : out std_logic
    );
end entity;

architecture arch of RGBLed is
  signal rgb_s               : std_logic_vector(23 downto 0);
  signal red_s, grn_s, blu_s : std_logic_vector(7 downto 0);
  signal redLed_s, grnLed_s, bluLed_s: std_logic;
  signal waste_s             : std_logic_vector(0 downto 0);
begin

  uHostIoToDut : HostIoToDut
    generic map (
      ID_G     => "11111111",
      SIMPLE_G => true
      )
    port map (
      vectorFromDut_i => waste_s,
      vectorToDut_o   => rgb_s
      );

  red_s <= rgb_s(23 downto 16);
  grn_s <= rgb_s(15 downto 8);
  blu_s <= rgb_s(7 downto 0);

  uRedPwm : Pwm
    port map(
      clk_i  => fpgaClk_i,
      duty_i => red_s,
      pwm_o  => redLed_s
      );
  redLed_o <= LO when redLed_s = HI else HIZ; 

  uGrnPwm : Pwm
    port map(
      clk_i  => fpgaClk_i,
      duty_i => grn_s,
      pwm_o  => grnLed_s
      );
  grnLed_o <= LO when grnLed_s = HI else HIZ; 

  uBluPwm : Pwm
    port map(
      clk_i  => fpgaClk_i,
      duty_i => blu_s,
      pwm_o  => bluLed_s
      );
  bluLed_o <= LO when bluLed_s = HI else HIZ; 

end architecture;

