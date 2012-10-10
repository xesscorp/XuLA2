--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:25:34 07/06/2012
-- Design Name:   
-- Module Name:   C:/xesscorp/PRODUCTS/XuLA/FPGA/LX25/SdcardTest/SdCardCtrlTestBench.vhd
-- Project Name:  SdcardTest
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: SdCardCtrl
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
USE ieee.math_real.all;
 
ENTITY SdCardCtrlTestBench IS
END SdCardCtrlTestBench;
 
ARCHITECTURE behavior OF SdCardCtrlTestBench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT SdCardCtrl
    GENERIC(
         FREQ_G : REAL;
         SPI_FREQ_G : REAL;
         BLOCK_SIZE_G : NATURAL
         );
    PORT(
         reset_i : IN  std_logic;
         clk_i : IN  std_logic;
         addr_i : IN  std_logic_vector(31 downto 0);
         rd_i : IN  std_logic;
         wr_i : IN  std_logic;
         continue_i : IN  std_logic;
         data_i : IN  std_logic_vector(7 downto 0);
         data_o : OUT  std_logic_vector(7 downto 0);
         busy_o : OUT  std_logic;
         hndShk_i : IN std_logic;
         hndShk_o : OUT  std_logic;
         cs_bo : OUT  std_logic;
         mosi_o : OUT  std_logic;
         miso_i : IN  std_logic;
         sclk_o : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal reset_i : std_logic := '0';
   signal clk_i : std_logic := '0';
   signal addr_i : std_logic_vector(31 downto 0) := (others => '0');
   signal rd_i : std_logic := '0';
   signal wr_i : std_logic := '0';
   signal continue_i : std_logic := '0';
   signal hndShk_i : std_logic := '0';
   signal data_i : std_logic_vector(7 downto 0) := (others => '0');
   signal miso_i : std_logic := '0';

 	--Outputs
   signal data_o : std_logic_vector(7 downto 0);
   signal busy_o : std_logic;
   signal hndShk_o : std_logic;
   signal cs_bo : std_logic;
   signal mosi_o : std_logic;
   signal sclk_o : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: SdCardCtrl 
        GENERIC MAP (
          FREQ_G => 100.0,
          SPI_FREQ_G => 10.0,
          BLOCK_SIZE_G => 5
        )
        PORT MAP (
          reset_i => reset_i,
          clk_i => clk_i,
          addr_i => addr_i,
          rd_i => rd_i,
          wr_i => wr_i,
          continue_i => continue_i,
          data_i => data_i,
          data_o => data_o,
          busy_o => busy_o,
          hndShk_i => hndShk_i,
          hndShk_o => hndShk_o,
          cs_bo => cs_bo,
          mosi_o => mosi_o,
          miso_i => miso_i,
          sclk_o => sclk_o
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
   
   -- Handshake process
   hndShk_proc: process(hndShk_o)
   begin
     hndShk_i <= hndShk_o;
   end process;
 

   -- Stimulus process
   stim_proc: process
      variable randn : real := 0.5;
      variable seed1: positive := 1;
      variable seed2: positive := 1;
   begin		
      -- hold reset state for 100 ns.
      addr_i <= x"12345678";
      rd_i <= '0';
      wr_i <= '0';
      continue_i <= '0';
      data_i <= x"01";
      miso_i <= '0';
      reset_i <= '1';
      wait for 100 ns;
      
      reset_i <= '0';
      wait until busy_o = '0';
      
      wr_i <= '1';
      wait until busy_o = '1';
      continue_i <= '1';
      
      for i in 0 to 4 loop
        data_i <= std_logic_vector(to_unsigned(2*i,4)) & std_logic_vector(to_unsigned(2*i+1,4));
        wait until hndShk_o = '1';
      end loop;
      
      for i in 0 to 40 loop
        wait until sclk_o = '0';
      end loop;
      miso_i <= '1';
      wait until sclk_o = '0';
      miso_i <= '0';
      
      for i in 0 to 4 loop
        data_i <= std_logic_vector(to_unsigned(3*i,4)) & std_logic_vector(to_unsigned(3*i+1,4));
        wait until hndShk_o = '1';
        continue_i <= '0';
        wr_i <= '0';
      end loop;
      
      for i in 0 to 40 loop
        wait until sclk_o = '0';
      end loop;
      miso_i <= '1';
      
      wait until busy_o = '0';
      
      rd_i <= '1';
      wait until busy_o = '1';
      continue_i <= '1';
      
      for i in 0 to 1000 loop
        uniform(seed1,seed2,randn);
        if integer(randn) = 1 then
          miso_i <= '1';
        else
          miso_i <= '0';
        end if;
        wait until sclk_o = '0';
      end loop;

      wait;
   end process;

END;
