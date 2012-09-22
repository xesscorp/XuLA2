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
-- Module for driving StickIt! seven-segment LED string.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use work.CommonPckg.all;

package LedDigitsPckg is

  -- Subtype definition for the vector of bits that drive a seven-segment LED.
  subtype LedDigit_t is std_logic_vector(6 downto 0);

--**************************************************************************************************
-- This function takes an ASCII character or hex number as input and outputs the 
-- LED segment activations that will display that character.
-- ASCII values 0x00 .. 0x0F display as the hexadecimal digits 0, 1, .. E, F. 
--**************************************************************************************************
  function CharToLedDigit(
    asciiChar_i : std_logic_vector      -- ASCII char. code.
    ) return LedDigit_t;            -- Return LED segment activation pattern.

--**************************************************************************************************
-- This module outputs a set of LED activation bit vectors to a charlie-plexed string of LED digits.
--**************************************************************************************************
  component LedDigitsDisplay is
    generic (
      FREQ_G        : real := 100.0;    -- Operating frequency in MHz.
      UPDATE_FREQ_G : real := 1.0  -- Desired update frequency for the LED segments in MHz.
      );
    port (clk_i          : in  std_logic;  -- Input clock.
          -- The following 7-bit vector inputs are the segment activations for the 8 LED digits.
          -- A 1 in a vector bit lights-up the corresponding LED segment. The bit indices correspond to
          -- the following LED segments: 0->A, 1->B, 2->C, 3->D, 4->E, 5->F, 6->G.
          ledDigit1_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
          ledDigit2_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
          ledDigit3_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
          ledDigit4_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
          ledDigit5_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
          ledDigit6_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
          ledDigit7_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
          ledDigit8_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
          -- This is the same thing as all the individual 7-bit vectors combined into a single vector.
          -- The following bit slices correspond to the vector inputs shown above:
          -- (6 downto 0)->ledDigit1_i, (13 downto 7)->ledDigit2_i, (20 downto 8)->ledDigit3_i, (27 downto 21)->ledDigit4_i, 
          -- (34 downto 28)->ledDigit5_i, (41 downto 35)->ledDigit6_i, (48 downto 42)->ledDigit7_i, (55 downto 49)->ledDigit8_i. 
          ledAllDigits_i : in  std_logic_vector(55 downto 0) := (others => ZERO);
          -- These are the 3-state drivers for the LED digits.
          ledDrivers_o   : out std_logic_vector (7 downto 0)
          );
  end component;

end package;




--**************************************************************************************************
-- This function takes an ASCII character as input and outputs the 
-- LED segment activations that will display that character.
-- ASCII values 0x00 .. 0x0F display as the hexadecimal digits 0, 1, .. E, F. 
--**************************************************************************************************

library IEEE, UNISIM;
use IEEE.MATH_REAL.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use UNISIM.vcomponents.all;
use work.CommonPckg.all;

package body LedDigitsPckg is

  function CharToLedDigit(
    asciiChar_i : std_logic_vector      -- ASCII char. code.
    ) return LedDigit_t is  -- Return LED segment activation pattern.
    variable ledDigit_o : LedDigit_t;   -- LED segment activation pattern.
  begin
    case TO_INTEGER(unsigned(asciiChar_i)) is
      when 16#20#                   => ledDigit_o := "0000000";  -- Space.
      when 16#2d#                   => ledDigit_o := "1000000";  -- Minus sign (-).
      when 16#00# | 16#30#          => ledDigit_o := "0111111";  -- Zero.
      when 16#01# | 16#31#          => ledDigit_o := "0000110";  -- One.
      when 16#02# | 16#32#          => ledDigit_o := "1011011";  -- Two. 
      when 16#03# | 16#33#          => ledDigit_o := "1001111";  -- Three.
      when 16#04# | 16#34#          => ledDigit_o := "1100110";  -- Four.
      when 16#05# | 16#35#          => ledDigit_o := "1101101";  -- Five.
      when 16#06# | 16#36#          => ledDigit_o := "1111101";  -- Six.
      when 16#07# | 16#37#          => ledDigit_o := "0000111";  -- Seven.
      when 16#08# | 16#38#          => ledDigit_o := "1111111";  -- Eight.
      when 16#09# | 16#39#          => ledDigit_o := "1101111";  -- Nine.
      when 16#0A# | 16#41# | 16#61# => ledDigit_o := "1110111";  -- A
      when 16#0B# | 16#42# | 16#62# => ledDigit_o := "1111100";  -- b
      when 16#0C# | 16#43# | 16#63# => ledDigit_o := "0111001";  -- C
      when 16#0D# | 16#44# | 16#64# => ledDigit_o := "1011110";  -- d
      when 16#0E# | 16#45# | 16#65# => ledDigit_o := "1111001";  -- E
      when 16#0F# | 16#46# | 16#66# => ledDigit_o := "1110001";  -- F
      when 16#47# | 16#67#          => ledDigit_o := "0111101";  -- G
      when 16#48# | 16#68#          => ledDigit_o := "1110100";  -- H
      when 16#49# | 16#69#          => ledDigit_o := "0110000";  -- I
      when 16#4a# | 16#6a#          => ledDigit_o := "0011110";  -- J
      when 16#4b# | 16#6b#          => ledDigit_o := "0001000";  --  
      when 16#4c# | 16#6c#          => ledDigit_o := "0111000";  -- L
      when 16#4d# | 16#6d#          => ledDigit_o := "0001000";  --  
      when 16#4e# | 16#6e#          => ledDigit_o := "1010100";  -- n  
      when 16#4f# | 16#6f#          => ledDigit_o := "1011100";  -- o
      when 16#50# | 16#70#          => ledDigit_o := "1110011";  -- P
      when 16#51# | 16#71#          => ledDigit_o := "0001000";  --  
      when 16#52# | 16#72#          => ledDigit_o := "1010000";  -- r
      when 16#53# | 16#73#          => ledDigit_o := "1101101";  -- S
      when 16#54# | 16#74#          => ledDigit_o := "1111000";  -- t
      when 16#55# | 16#75#          => ledDigit_o := "0011100";  -- U
      when 16#56# | 16#76#          => ledDigit_o := "0001000";  --  
      when 16#57# | 16#77#          => ledDigit_o := "0001000";  --  
      when 16#58# | 16#78#          => ledDigit_o := "0001000";  --  
      when 16#59# | 16#79#          => ledDigit_o := "1101110";  -- y
      when 16#5a# | 16#7a#          => ledDigit_o := "0001000";  --
      when 16#5F#                   => ledDigit_o := "0001000";  -- Underscore (_).
      when others                   => ledDigit_o := "0001000";  -- _
    end case;
    return ledDigit_o;
  end function;
end package body;




--**************************************************************************************************
-- This module outputs a set of LED activation bit vectors to a charlie-plexed string of LED digits.
--**************************************************************************************************

library IEEE, UNISIM;
use IEEE.MATH_REAL.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use UNISIM.vcomponents.all;
use work.CommonPckg.all;

entity LedDigitsDisplay is
  generic (
    FREQ_G        : real := 100.0;      -- Operating frequency in MHz.
    UPDATE_FREQ_G : real := 1.0  -- Desired update frequency for the LED segments in KHz.
    );
  port (clk_i          : in  std_logic;  -- Input clock.
        -- The following 7-bit vector inputs are the segment activations for the 8 LED digits.
        -- A 1 in a vector bit lights-up the corresponding LED segment. The bit indices correspond to
        -- the following LED segments: 0->A, 1->B, 2->C, 3->D, 4->E, 5->F, 6->G.
        ledDigit1_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
        ledDigit2_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
        ledDigit3_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
        ledDigit4_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
        ledDigit5_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
        ledDigit6_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
        ledDigit7_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
        ledDigit8_i    : in  std_logic_vector (6 downto 0) := (others => ZERO);
        -- This is the same thing as all the individual 7-bit vectors combined into a single vector.
        -- The following bit slices correspond to the vector inputs shown above:
        -- (6 downto 0)->ledDigit1_i, (13 downto 7)->ledDigit2_i, (20 downto 8)->ledDigit3_i, (27 downto 21)->ledDigit4_i, 
        -- (34 downto 28)->ledDigit5_i, (41 downto 35)->ledDigit6_i, (48 downto 42)->ledDigit7_i, (55 downto 49)->ledDigit8_i. 
        ledAllDigits_i : in  std_logic_vector(55 downto 0) := (others => ZERO);
        -- These are the 3-state drivers for the LED digits.
        ledDrivers_o   : out std_logic_vector (7 downto 0)
        );
end entity;

architecture arch of LedDigitsDisplay is
  signal digitShf_r : unsigned(ledDrivers_o'range) := "00000001";  -- Shift reg indicates which digit is active.
  signal segShf_r   : unsigned(ledDrivers_o'range) := "00010100";  -- Shift reg indicates which LED segment is active.
  signal segments_s : std_logic_vector(ledAllDigits_i'range);  -- 1 indicates segment is on, 0 means off.
  signal cathodes_s : std_logic_vector(6 downto 0);  -- Cathode levels for the LEDs of the active digit.
  signal tris_s     : std_logic_vector(ledDrivers_o'range);  -- Output driver tristate settings.
begin

  -- Shift the active LED segment every MAX_CNTR clock cycles, and shift the active digit after every eight shifts of the LED segment.
  process(clk_i)
    constant MAX_CNTR    : natural := integer(ceil(FREQ_G * 1000.0 / (UPDATE_FREQ_G * real(ledAllDigits_i'length))));
    variable segCntr_v   : natural range 0 to MAX_CNTR;
    variable digitCntr_v : natural range ledDrivers_o'range;
  begin
    if rising_edge(clk_i) then
      if segCntr_v /= 0 then
        segCntr_v := segCntr_v - 1;  -- Decrement LED segment counter until it reaches 0.
      else                           -- The LED segment counter has reached 0.
        segShf_r  <= segShf_r rol 1;
        segCntr_v := MAX_CNTR;          -- Restart the LED segment counter.
        if digitCntr_v /= 0 then
          digitCntr_v := digitCntr_v - 1;  -- Decrement digit counter until it reaches 0.
        else                            -- The digit counter has reached 0.
          digitShf_r  <= digitShf_r rol 1;   -- Shift to next digit.
          digitCntr_v := ledDrivers_o'high;  -- Restart the digit counter.
        end if;
      end if;
    end if;
  end process;

  -- Combine all the LED segment activation inputs into one large vector.
  segments_s <= ledAllDigits_i or (ledDigit8_i & ledDigit7_i & ledDigit6_i & ledDigit5_i & ledDigit4_i & ledDigit3_i & ledDigit2_i & ledDigit1_i);

  -- Select a slice of the total LED segment activation vector corresponding to the LEDs for the currently active digit.
  -- The cathode level will be low for each active segment.
  process(digitShf_r, segments_s)
  begin
    case digitShf_r is
      when "00000001" => cathodes_s <= not segments_s(6 downto 0);
      when "00000010" => cathodes_s <= not segments_s(13 downto 7);
      when "00000100" => cathodes_s <= not segments_s(20 downto 14);
      when "00001000" => cathodes_s <= not segments_s(27 downto 21);
      when "00010000" => cathodes_s <= not segments_s(34 downto 28);
      when "00100000" => cathodes_s <= not segments_s(41 downto 35);
      when "01000000" => cathodes_s <= not segments_s(48 downto 42);
      when "10000000" => cathodes_s <= not segments_s(55 downto 49);
      when others     => cathodes_s <= (others => HI);
    end case;
  end process;

  -- Connect the cathode levels to the cathode drivers of the active digit and activate the driver for every
  -- cathode at a low level. Tristate the driver for cathodes at a high level. Also, activate the driver
  -- for the anode pin of the active LED digit. The anode for LED digit i is at signal index i. The cathodes
  -- connect to all the other indices.
  process(digitShf_r, segShf_r, cathodes_s)
    variable j : natural range digitShf_r'range := 0;
  begin
    j      := 0;
    tris_s <= not std_logic_vector(digitShf_r);
    for i in digitShf_r'low to digitShf_r'high loop
      if digitShf_r(i) = LO then  -- The cathodes for the active digit have low levels in the digit shift register. Skip the anode.
        tris_s(i) <= not (segShf_r(i) and not cathodes_s(j));  -- Activate tristate driver if the segment is active and the cathode level is low.
        j         := j + 1;             -- Move to the next cathode bit.
      end if;
    end loop;
  end process;

  -- Instantiate the tristate drivers. The active digit shift register is attached to the driver inputs so the anode of the currently
  -- active LED digit is driven high. The other drivers will pull the cathode pins low if the corresponding LED segment is active.
  ObuftLoop : for i in ledDrivers_o'low to ledDrivers_o'high generate
    UObuft : OBUFT generic map(DRIVE => 24, IOSTANDARD => "LVTTL") port map(T => tris_s(i), I => digitShf_r(i), O => ledDrivers_o(i));
  end generate;
  
end architecture;




--**************************************************************************************************
-- This module tests the StickIt! main board by outputing the following on LED displays
-- connected to the WING sockets:
--   WING1: "-shipout"
--   WING2: "-righton"
--   WING3: "-correct"
--**************************************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.LedDigitsPckg.all;

entity LedDigitsTest is
  generic (
    FREQ_G : real := 12.0
    );
  port(
    clk_i : in  std_logic;
    s1_o   : out std_logic_vector(7 downto 0);
    s2_o   : out std_logic_vector(7 downto 0);
    s3_o   : out std_logic_vector(7 downto 0)
    );
end entity;

architecture arch of LedDigitsTest is
  signal ascii1_r : std_logic_vector(55 downto 0) := "01011011010011100100010010011010000100111110101011010100"; -- -shipout
  signal ascii2_r : std_logic_vector(55 downto 0) := "01011011010010100100110001111001000101010010011111001110"; -- -righton
  signal ascii3_r : std_logic_vector(55 downto 0) := "01011011000011100111110100101010010100010110000111010100"; -- -correct
begin
  
  process(clk_i) is
    variable cntr_r      : integer := 0;
    variable asciiChar_v : unsigned(6 downto 0) := "0000000";
  begin
    if rising_edge(clk_i) then
      if cntr_r = 0 then
        cntr_r      := integer(FREQ_G / 2.0 * 1_000_000.0);
        ascii1_r     <= ascii1_r(48 downto 0) & ascii1_r(55 downto 49);
        ascii2_r     <= ascii2_r(48 downto 0) & ascii2_r(55 downto 49);
        ascii3_r     <= ascii3_r(48 downto 0) & ascii3_r(55 downto 49);
      else
        cntr_r := cntr_r - 1;
      end if;
    end if;
  end process;

  u1 : LedDigitsDisplay
    generic map(
      FREQ_G => FREQ_G
      )
    port map (
      clk_i        => clk_i,
      ledDigit1_i  => CharToLedDigit(ascii1_r(6 downto 0)),
      ledDigit2_i  => CharToLedDigit(ascii1_r(13 downto 7)),
      ledDigit3_i  => CharToLedDigit(ascii1_r(20 downto 14)),
      ledDigit4_i  => CharToLedDigit(ascii1_r(27 downto 21)),
      ledDigit5_i  => CharToLedDigit(ascii1_r(34 downto 28)),
      ledDigit6_i  => CharToLedDigit(ascii1_r(41 downto 35)),
      ledDigit7_i  => CharToLedDigit(ascii1_r(48 downto 42)),
      ledDigit8_i  => CharToLedDigit(ascii1_r(55 downto 49)),
      ledDrivers_o => s1_o
      );

  u2 : LedDigitsDisplay
    generic map(
      FREQ_G => FREQ_G
      )
    port map (
      clk_i        => clk_i,
      ledDigit1_i  => CharToLedDigit(ascii2_r(6 downto 0)),
      ledDigit2_i  => CharToLedDigit(ascii2_r(13 downto 7)),
      ledDigit3_i  => CharToLedDigit(ascii2_r(20 downto 14)),
      ledDigit4_i  => CharToLedDigit(ascii2_r(27 downto 21)),
      ledDigit5_i  => CharToLedDigit(ascii2_r(34 downto 28)),
      ledDigit6_i  => CharToLedDigit(ascii2_r(41 downto 35)),
      ledDigit7_i  => CharToLedDigit(ascii2_r(48 downto 42)),
      ledDigit8_i  => CharToLedDigit(ascii2_r(55 downto 49)),
      ledDrivers_o => s2_o
      );

  u3 : LedDigitsDisplay
    generic map(
      FREQ_G => FREQ_G
      )
    port map (
      clk_i        => clk_i,
      ledDigit1_i  => CharToLedDigit(ascii3_r(6 downto 0)),
      ledDigit2_i  => CharToLedDigit(ascii3_r(13 downto 7)),
      ledDigit3_i  => CharToLedDigit(ascii3_r(20 downto 14)),
      ledDigit4_i  => CharToLedDigit(ascii3_r(27 downto 21)),
      ledDigit5_i  => CharToLedDigit(ascii3_r(34 downto 28)),
      ledDigit6_i  => CharToLedDigit(ascii3_r(41 downto 35)),
      ledDigit7_i  => CharToLedDigit(ascii3_r(48 downto 42)),
      ledDigit8_i  => CharToLedDigit(ascii3_r(55 downto 49)),
      ledDrivers_o => s3_o
      );

end architecture;
