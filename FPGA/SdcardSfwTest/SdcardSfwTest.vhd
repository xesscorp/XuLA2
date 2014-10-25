-- ********************************************************************
-- Copyright 2012 by XESS Corp <http://www.xess.com>.

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- ********************************************************************


library ieee, XESS;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
--library unisim;
--use unisim.vcomponents.all;
use XESS.CommonPckg.all;
use XESS.HostIoPckg.all;


entity SdcardSfwTest is
  port (
    flashCs_bo    : out std_logic;
    usdflashCs_bo : out std_logic;
    sclk_o        : out std_logic;
    miso_i        : in  std_logic;
    mosi_o        : out std_logic
    );
end entity;


architecture arch of SdcardSfwTest is
  signal vectorFromDut_s : std_logic_vector(0 downto 0);
  signal vectorToDut_s   : std_logic_vector(2 downto 0);
begin

  flashCs_bo <= HI;

  u1 : HostIoToDut
    generic map(
      SIMPLE_G      => true
      )
    port map(
      vectorFromDut_i => vectorFromDut_s,
      vectorToDut_o   => vectorToDut_s
      );

  vectorFromDut_s(0)              <= miso_i;
  (mosi_o, sclk_o, usdflashCs_bo) <= vectorToDut_s;
  
end architecture;

