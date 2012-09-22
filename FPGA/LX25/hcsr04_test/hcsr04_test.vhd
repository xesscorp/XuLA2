----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:16:18 05/17/2012 
-- Design Name: 
-- Module Name:    hcsr04_test - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.CommonPckg.all;
use work.Hcsr04Pckg.all;
use work.LedDigitsPckg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hcsr04_test is
    Port ( clk_i : in  STD_LOGIC;
           trig_o : out  STD_LOGIC;
           echo_i : in  STD_LOGIC;
           s_o : out  STD_LOGIC_VECTOR (7 downto 0));
end hcsr04_test;

architecture Behavioral of hcsr04_test is
  signal dist_s : std_logic_vector(31 downto 0);
begin

u0 : Hcsr04
    generic map (
      FREQ_G => 12.0
      )
    port map (
      clk_i   => clk_i,
      trig_o  => trig_o,
      echo_i  => echo_i,
      dist_o  => dist_s,
      clear_o => open
      );
      
u1 : LedHexDisplay
  generic map (
    FREQ_G        => 12.0
    )
  port map (
    clk_i          => clk_i,
    hexAllDigits_i => dist_s,
    ledDrivers_o   => s_o
    );

end Behavioral;

