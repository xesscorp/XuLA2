--**********************************************************************
-- Copyright 2012 by XESS Corp <http://www.xess.com>.
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

--*********************************************************************
-- SD MEMORY CARD INTERFACE
--
-- Reads/writes a single or multiple blocks of data to/from an SD Flash card.
-- (Based on work by by Steven J. Merrifield, June 2008:
-- http : //stevenmerrifield.com/tools/sd.vhd)
--
-- OPERATION
--
-- Give the interface a clock that has a higher frequency than the SPI SCLK.
--
-- Pulse the reset_i input. The interface will initialize the SD card so
-- it will work in SPI mode. Basically, it sends the card CMD0 and then
-- ACMD41 (which is CMD55 followed by CMD41). The busy_o output will be
-- high during the initialization.
--
-- After the initialization command sequence, the SD card will send back 
-- an all-zero R1 response. If only the IDLE bit of the R1 response is 
-- set, then the interface will repeatedly re-try the ACMD41 command while
-- busy_o remains high.
--
-- If any other bit of the R1 response is set, then an error occurred. 
-- The interface will stall and lower busy_o and reset_i must be raised to
-- unfreeze it. The R1 response will be output on the error_o output bus.
--
-- If the R1 response is all zeroes, then the interface will lower busy_o 
-- and wait for a read or write operation from the host. The interface 
-- will only accept new operations when busy_o is low.
--
-- To write data to the SD card, the address of a block is placed on
-- the addr_i input bus and the wr_i input is raised. The address and
-- write strobe can be removed once busy_o goes high to indicate 
-- the write operation is underway. The data to be written to the 
-- SD card is passed as follows:
--   1. The hndShk_o output from the interface goes high.
--   2. The host applies the next data word to the data_i input bus
--      and raises the hndShk_i input.
--   3. The interface lowers the hndShk_o output.
--   4. The host lowers the hndShk_i input.
-- This sequence of steps is repeated until all BLOCK_SIZE_G data
-- words are passed from the host to the interface. Once all the data 
-- is passed, the sector on the SD card will be written and the busy_o
-- output will be lowered.
--
-- To read data from the SD card, the address of a block is placed on
-- the addr_i input bus and the rd_i input is raised. The address and
-- read strobe can be removed once busy_o goes high to indicate 
-- the read operation is underway. The data read from the SD card 
-- is passed to the host as follows:
--   1. The hndShk_o output from the interface goes high.
--   2. The host reads the next data word from the data_o output bus
--      and raises the hndShk_i input.
--   3. The interface lowers the hndShk_o output.
--   4. The host lowers the hndShk_i input.
-- This sequence of steps is repeated until all BLOCK_SIZE_G data
-- words are passed from the interface to the host. Once all the data 
-- is read, the busy_o output will be lowered.
--
-- If an error is detected during either a read or write operation,
-- then the interface will stall and lower busy_o and reset_i must be raised to
-- unfreeze it. An error code will be output on the error_o output bus.
--*********************************************************************


  library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CommonPckg.all;

package SdCardPckg is

  component SdCardCtrl is
    generic (
      FREQ_G          : real    := 100.0;  -- Master clock frequency (MHz).
      INIT_SPI_FREQ_G : real    := 0.4;  -- Slow SPI clock freq. during initialization (MHz).
      SPI_FREQ_G      : real    := 1.0;  -- Operational SPI freq. to the SD card (MHz).
      BLOCK_SIZE_G    : natural := 512  -- Number of bytes in an SD card block or sector.
      );
    port (
      -- Host-side interface signals.
      clk_i      : in  std_logic;       -- Master clock.
      reset_i    : in  std_logic                     := NO;  -- active-high, synchronous  reset.
      rd_i       : in  std_logic                     := NO;  -- active-high read block request.
      wr_i       : in  std_logic                     := NO;  -- active-high write block request.
      continue_i : in  std_logic                     := NO;  -- If true, inc address and continue R/W.
      addr_i     : in  std_logic_vector(31 downto 0);        -- Block address.
      data_i     : in  std_logic_vector(7 downto 0)  := x"00";  -- Data to write to block.
      data_o     : out std_logic_vector(7 downto 0);  -- Data read from block.
      busy_o     : out std_logic;  -- High when controller is busy performing some operation.
      hndShk_i   : in  std_logic;  -- High when host has data to give or has taken data.
      hndShk_o   : out std_logic;  -- High when controller has taken data or has data to give.
      error_o    : out std_logic_vector(15 downto 0) := (others => NO);
      -- I/O signals to the external SD card.
      cs_bo      : out std_logic                     := HI;  -- Active-low chip-select.
      sclk_o     : out std_logic                     := LO;  -- Serial clock to SD card.
      mosi_o     : out std_logic                     := HI;  -- Serial data output to SD card.
      miso_i     : in  std_logic                     := ZERO  -- Serial data input from SD card.
      );
  end component;

  component SdCardCtrlTest is
    generic (
      BASE_FREQ_G : real    := 12.0;
      CLK_MUL_G   : natural := 25;
      CLK_DIV_G   : natural := 3
      );
    port (
      fpgaClk_i     : in  std_logic;
      flashCs_bo    : out std_logic;
      usdflashCs_bo : out std_logic;
      sclk_o        : out std_logic;
      miso_i        : in  std_logic;
      mosi_o        : out std_logic
      );
  end component;

end package;




library ieee;
use ieee.math_real.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CommonPckg.all;

entity SdCardCtrl is
  generic (
    FREQ_G          : real    := 100.0;  -- Master clock frequency (MHz).
    INIT_SPI_FREQ_G : real    := 0.4;  -- Slow SPI clock freq. during initialization (MHz).
    SPI_FREQ_G      : real    := 1.0;  -- Operational SPI freq. to the SD card (MHz).
    BLOCK_SIZE_G    : natural := 512  -- Number of bytes in an SD card block or sector.
    );
  port (
    -- Host-side interface signals.
    clk_i      : in  std_logic;         -- Master clock.
    reset_i    : in  std_logic                     := NO;  -- active-high, synchronous  reset.
    rd_i       : in  std_logic                     := NO;  -- active-high read block request.
    wr_i       : in  std_logic                     := NO;  -- active-high write block request.
    continue_i : in  std_logic                     := NO;  -- If true, inc address and continue R/W.
    addr_i     : in  std_logic_vector(31 downto 0);        -- Block address.
    data_i     : in  std_logic_vector(7 downto 0)  := x"00";  -- Data to write to block.
    data_o     : out std_logic_vector(7 downto 0);  -- Data read from block.
    busy_o     : out std_logic;  -- High when controller is busy performing some operation.
    hndShk_i   : in  std_logic;  -- High when host has data to give or has taken data.
    hndShk_o   : out std_logic;  -- High when controller has taken data or has data to give.
    error_o    : out std_logic_vector(15 downto 0) := (others => NO);
    -- I/O signals to the external SD card.
    cs_bo      : out std_logic                     := HI;  -- Active-low chip-select.
    sclk_o     : out std_logic                     := LO;  -- Serial clock to SD card.
    mosi_o     : out std_logic                     := HI;  -- Serial data output to SD card.
    miso_i     : in  std_logic                     := ZERO  -- Serial data input from SD card.
    );
end entity;



architecture arch of SdCardCtrl is

  signal sclk_r   : std_logic := ZERO;  -- Register output drives SD card clock.
  signal hndShk_r : std_logic := NO;  -- Register output drives handshake output to host.

begin
  
  process(clk_i)  -- FSM process for the SD card controller.

    type FsmState_t is (               -- States of the SD card controller FSM.
      INIT,  -- Send initialization clock pulses to the deselected SD card.    
      SEND_CMD0,                        -- Send CMD0 to the SD card.
      SEND_CMD55,                       -- Send CMD55 to the SD card. 
      SEND_CMD41,                       -- Send CMD41 to the SD card.
      CHECK_IDLE,  -- Check if the SD card has left the IDLE state.     
      WAIT_FOR_HOST_RW,  -- Wait for the host to issue a read or write command.
      READ_START_TOKEN,  -- Scan for token at the start of block of read data. 
      READ_DATA,   -- Read a block of data from the SD card.
      READ_CRC,  -- Get the CRC that follows a block of data from the SD card.
      WRITE_DATA,  -- Write a start token, block of data and two CRC bytes.
      WRITE_BUSY_WAIT,   -- Wait for SD card to finish writing the data block.
      END_BLOCK_RW,      -- Disable SD card chip-select after each block R/W.
      TRANSMIT,                         -- Start sending command/data.
      SHIFT_OUT,   -- Shift out remaining command/data bits.
      GET_CMD_RESPONSE,  -- Get the R1 response of the SD card to a command.
      RECEIVE,                          -- Receive bits from the SD card.
      DESELECT,  -- De-select the SD card and send some clock pulses (Must enter with sclk at zero.)
      PULSE_SCLK,  -- Issue some clock pulses. (Must enter with sclk at zero.)
      REPORT_ERROR  -- Report error and stall until reset.
      );
    variable state_v    : FsmState_t := INIT;  -- Current state of the FSM.
    variable rtnState_v : FsmState_t;  -- State FSM returns to when FSM subroutine completes.

    -- Timing constants based on the master clock frequency and the SPI SCLK frequencies.
    constant CLKS_PER_INIT_SCLK_C      : real    := FREQ_G / INIT_SPI_FREQ_G;
    constant CLKS_PER_SCLK_C           : real    := FREQ_G / SPI_FREQ_G;
    constant MAX_CLKS_PER_SCLK_C       : real    := realmax(CLKS_PER_INIT_SCLK_C, CLKS_PER_SCLK_C);
    constant MAX_CLKS_PER_SCLK_PHASE_C : natural := integer(round(MAX_CLKS_PER_SCLK_C / 2.0));
    constant INIT_SCLK_PHASE_PERIOD_C  : natural := integer(round(CLKS_PER_INIT_SCLK_C / 2.0));
    constant SCLK_PHASE_PERIOD_C       : natural := integer(round(CLKS_PER_SCLK_C / 2.0));
    constant DELAY_BETWEEN_BLOCK_RW_C  : natural := SCLK_PHASE_PERIOD_C;

    -- Registers for generating slow SPI SCLK from the faster master clock.
    variable clkDivider_v     : natural range 0 to MAX_CLKS_PER_SCLK_PHASE_C;  -- Holds the SCLK period.
    variable sclkPhaseTimer_v : natural range 0 to MAX_CLKS_PER_SCLK_PHASE_C;  -- Counts down to zero, then SCLK toggles.

    constant NUM_INIT_CLKS_C : natural := 160;  -- Number of initialization clocks to SD card.
    variable bitCnt_v        : natural range 0 to NUM_INIT_CLKS_C;  -- Tx/Rx bit counter.

    constant CRC_SIZE_C        : natural := 2;  -- Number of CRC bytes for read/write blocks.
    constant WRITE_DATA_SIZE_C : natural := 1 + BLOCK_SIZE_G + CRC_SIZE_C;
    variable byteCnt_v         : natural range 0 to WRITE_DATA_SIZE_C;  -- Tx/Rx byte counter.

    -- Command bytes for various SD card operations.
    constant CMD0_C          : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(16#40# + 0, 8));
    constant CMD55_C         : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(16#40# + 55, 8));
    constant CMD41_C         : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(16#40# + 41, 8));
    constant READ_BLK_CMD_C  : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(16#40# + 17, 8));
    constant WRITE_BLK_CMD_C : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(16#40# + 24, 8));

    -- Except for CMD0, SD card ops don't need a CRC, so use a fake one for that slot in the command.
    constant FAKE_CRC_C : std_logic_vector(7 downto 0) := x"FF";

    variable addr_v : unsigned(addr_i'range);  -- Address of current block for R/W operations.

    -- Maximum Tx to SD card consists of command + address + CRC. Data Tx is just a single byte.
    variable tx_v : std_logic_vector(CMD0_C'length + addr_v'length + FAKE_CRC_C'length - 1 downto 0);  -- Data/command to SD card.
    alias txCmd_v is tx_v;              -- Command transmission shift register.
    alias txData_v is tx_v(tx_v'high downto tx_v'high - data_i'length + 1);  -- Data byte transmission shift register.

    variable rx_v              : std_logic_vector(data_i'range);  -- Data/status byte received from SD card.
    constant R1_IDLE_BIT_POS_C : natural := rx_v'low;  -- Position of IDLE bit in R1 response from SD card.

    -- Flags that are set/cleared to affect the operation of the FSM.
    variable getCmdResponse_v : boolean;  -- When true, get R1 response to command sent to SD card.
    variable rtnData_v        : boolean;  -- When true, signal to host when a data byte arrives from SD card.
    variable doDeselect_v     : boolean;  -- When true, de-select SD card after a command is issued.
    
  begin
    if rising_edge(clk_i) then

      if reset_i = YES then             -- Perform a reset.
        state_v          := INIT;  -- Send the FSM to the initialization entry-point.
        sclkPhaseTimer_v := 0;  -- Don't delay the initialization right after reset.
        busy_o           <= YES;  -- Busy while the SD card interface is being initialized.

      elsif sclkPhaseTimer_v /= 0 then
        -- Setting the clock phase timer to a non-zero value delays any further actions
        -- and generates the slower SPI clock from the faster master clock.
        sclkPhaseTimer_v := sclkPhaseTimer_v - 1;

        -- Clock phase timer has reached zero, so check handshaking sync. between host and controller.

        -- Handshaking lets the host control the flow of data to/from the SD card controller.
        -- Handshaking between the SD card controller and the host proceeds as follows:
        --   1: Controller raises its handshake and waits.
        --   2: Host sees controller handshake and raises its handshake in acknowledgement.
        --   3: Controller sees host handshake acknowledgement and lowers its handshake.
        --   4: Host sees controller lower its handshake and removes its handshake.
        --
        -- Handshaking is bypassed when the controller FSM is initializing the SD card.
        
      elsif state_v /= INIT and hndShk_r = HI and hndShk_i = LO then
        null;            -- Waiting for host to acknowledge handshake.
      elsif state_v /= INIT and hndShk_r = HI and hndShk_i = HI then
        hndShk_r <= LO;  -- Host acknowledged, so lower the controller handshake.
      elsif state_v /= INIT and hndShk_r = LO and hndShk_i = HI then
        null;            -- Waiting for host to lower its handshake.
      elsif (state_v = INIT) or (hndShk_r = LO and hndShk_i = LO) then
        -- Both handshakes are low, so the controller operations can proceed.
        
        busy_o <= YES;  -- SD card interface is busy by default. (Only false when waiting for R/W from host.)

        case state_v is
          
          when INIT =>  -- Deselect the SD card and send it a bunch of clock pulses with MOSI high.
            error_o          <= (others => ZERO);  -- Clear error flags.
            clkDivider_v     := INIT_SCLK_PHASE_PERIOD_C;  -- Use slow SPI clock freq during init.
            sclkPhaseTimer_v := INIT_SCLK_PHASE_PERIOD_C;  -- and set the duration of the next clock phase.
            sclk_r           <= LO;     -- Start with low clock to the SD card.
            hndShk_r         <= LO;     -- Initialize handshake signal.
            addr_v           := (others => ZERO);  -- Initialize address.
            bitCnt_v         := NUM_INIT_CLKS_C;  -- Generate this many clock pulses.
            state_v          := DESELECT;  -- De-select the SD card and pulse SCLK.
            rtnState_v       := SEND_CMD0;  -- Then go to this state after the clock pulses are done.
            
          when SEND_CMD0 =>             -- Send CMD0 to the SD card.
            cs_bo            <= LO;     -- Enable the SD card.
            txCmd_v          := CMD0_C & std_logic_vector(addr_v) & x"95";  -- 0x95 is the only correct CRC needed.
            bitCnt_v         := txCmd_v'length;  -- Set bit counter to the size of the command.
            getCmdResponse_v := true;  -- Sending a command that generates a response.
            rtnData_v        := false;  -- Make this false after debugging!
            doDeselect_v     := true;  -- De-select SD card after this command finishes.
            state_v          := TRANSMIT;  -- Go to FSM subroutine to send the command.
            rtnState_v       := SEND_CMD55;  -- Then go to this state after the command is sent.

          when SEND_CMD55 =>            -- Send CMD55 to the SD card.
            cs_bo            <= LO;     -- Enable the SD card.
            txCmd_v          := CMD55_C & std_logic_vector(addr_v) & FAKE_CRC_C;
            bitCnt_v         := txCmd_v'length;  -- Set bit counter to the size of the command.
            getCmdResponse_v := true;  -- Sending a command that generates a response.
            rtnData_v        := false;  -- Make this false after debugging!
            doDeselect_v     := true;  -- De-select SD card after this command finishes.
            state_v          := TRANSMIT;  -- Go to FSM subroutine to send the command.
            rtnState_v       := SEND_CMD41;  -- Then go to this state after the command is sent.
            
          when SEND_CMD41 =>            -- Send CMD41 to the SD card.
            cs_bo            <= LO;     -- Enable the SD card.
            txCmd_v          := CMD41_C & std_logic_vector(addr_v) & FAKE_CRC_C;
            bitCnt_v         := txCmd_v'length;  -- Set bit counter to the size of the command.
            getCmdResponse_v := true;  -- Sending a command that generates a response.
            rtnData_v        := false;  -- Make this false after debugging!
            doDeselect_v     := true;  -- De-select SD card after this command finishes.
            state_v          := TRANSMIT;  -- Go to FSM subroutine to send the command.
            rtnState_v       := CHECK_IDLE;  -- Then go to this state after the command is sent.
            
          when CHECK_IDLE =>
            -- The CMD55, CMD41 sequence should cause the SD card to leave the IDLE state
            -- and become ready for SPI read/write operations. If still IDLE, then repeat the CMD55, CMD41 sequence.
            -- If one of the R1 error flags is set, then just stay in this state until a reset occurs.
            if rx_v = std_logic_vector(TO_UNSIGNED(0, rx_v'length)) then  -- Not IDLE, no errors.
              state_v := WAIT_FOR_HOST_RW;  -- Start processing R/W commands from the host.
            elsif rx_v = std_logic_vector(TO_UNSIGNED(1, rx_v'length)) then  -- Still IDLE but no errors. 
              state_v := SEND_CMD55;    -- Repeat the CMD55, CMD41 sequence.
            else                        -- Some error occurred.
              state_v := REPORT_ERROR;  -- Report the error.
            end if;
            
          when WAIT_FOR_HOST_RW =>  -- Wait for the host to read or write a block of data from the SD card.
            clkDivider_v     := SCLK_PHASE_PERIOD_C;  -- Set SPI clock frequency for normal operation.
            getCmdResponse_v := true;  -- Get R1 response to any commands issued to the SD card.
            if rd_i = YES then  -- send READ command and address to the SD card.
              cs_bo <= LO;              -- Enable the SD card.
              if continue_i = YES then
                addr_v  := addr_v + 1;
                txCmd_v := READ_BLK_CMD_C & std_logic_vector(addr_v) & FAKE_CRC_C;
              else
                txCmd_v := READ_BLK_CMD_C & addr_i & x"FF";
                addr_v  := unsigned(addr_i);
              end if;
              bitCnt_v   := txCmd_v'length;  -- Set bit counter to the size of the command.
              state_v    := TRANSMIT;  -- Go to FSM subroutine to send the command.
              rtnState_v := READ_START_TOKEN;  -- Then go to this state after the command is sent.
            elsif wr_i = YES then  -- send WRITE command and address to the SD card.
              cs_bo <= LO;              -- Enable the SD card.
              if continue_i = YES then
                addr_v  := addr_v + 1;
                txCmd_v := WRITE_BLK_CMD_C & std_logic_vector(addr_v) & FAKE_CRC_C;
              else
                txCmd_v := WRITE_BLK_CMD_C & addr_i & x"FF";
                addr_v  := unsigned(addr_i);
              end if;
              bitCnt_v   := txCmd_v'length;  -- Set bit counter to the size of the command.
              state_v    := TRANSMIT;  -- Go to FSM subroutine to send the command.
              rtnState_v := WRITE_DATA;  -- Then go to this state after the command is sent.
              byteCnt_v  := WRITE_DATA_SIZE_C;
            else              -- Do nothing and wait for command from host.
              cs_bo   <= HI;            -- Deselect the SD card.
              busy_o  <= NO;  -- SD card interface is waiting for R/W from host, so it's not busy.
              state_v := WAIT_FOR_HOST_RW;  -- Keep waiting for command from host.
            end if;
            
          when READ_START_TOKEN =>
            -- The SD card will output 0xFE token at the start of the block of read data. So scan 
            -- MISO for a low bit and then get the block of data bytes that follows. 
            if sclk_r = HI and miso_i = LO then
              byteCnt_v := BLOCK_SIZE_G - 1;  -- Set the byte counter for the # of data bytes in a block.
              state_v   := READ_DATA;  -- Go to FSM subroutine to read the data block.
            end if;
            sclk_r           <= not sclk_r;   -- Toggle the SPI clock...
            sclkPhaseTimer_v := clkDivider_v;  -- and set the duration of the next clock phase.

          when READ_DATA =>         -- Read a block of data from the SD card.
            rtnData_v := true;
            bitCnt_v  := rx_v'length - 1;  -- Set the bit counter for the next data byte.
            state_v   := RECEIVE;       -- Get the next data byte.
            if byteCnt_v /= 0 then  -- Haven't received the entire block of data from the SD card, yet.
              byteCnt_v  := byteCnt_v - 1;   -- One less byte to receive.
              rtnState_v := READ_DATA;  -- Then return here to keep getting more data bytes.
            else  -- This is the last byte of data to read from the SD card block.
              rtnState_v := READ_CRC;   -- Then get the CRC for the data block.
              byteCnt_v  := CRC_SIZE_C - 1;  -- CRC is multi-byte.
            end if;
            
          when READ_CRC =>  -- Get the CRC that follows a block of data from the SD card.
            rtnData_v := false;
            bitCnt_v  := rx_v'length - 1;  -- Set the bit counter for the CRC byte.
            state_v   := RECEIVE;       -- Get a CRC byte.
            if byteCnt_v /= 0 then
              byteCnt_v  := byteCnt_v - 1;  -- One less CRC byte to receive.
              rtnState_v := READ_CRC;   -- Still reading CRC.
            else
              rtnState_v := END_BLOCK_RW;  -- Done reading CRC, so terminate this block read op.
            end if;
            
          when WRITE_DATA =>  -- Write a start token, block of data and two CRC bytes.
            getCmdResponse_v := false;  -- Sending data bytes so there's no command response from SD card.
            if byteCnt_v /= 0 then
              tx_v := (others => ONE);  -- Only using 8 bits, so make sure others are set high.
              if byteCnt_v = WRITE_DATA_SIZE_C then
                txData_v := x"FE";      -- Starting data block token.
              elsif byteCnt_v = 2 or byteCnt_v = 1 then
                txData_v := x"FF";      -- Two (phony) CRC bytes.
              else                      -- Send bytes in data block.
                txData_v := data_i;  -- Load shift register with data from host.
                data_o   <= data_i;
              end if;
              if byteCnt_v > 3 then
                hndShk_r <= HI;         -- Signal host to provide data.
              end if;
              bitCnt_v   := txData_v'length;
              state_v    := TRANSMIT;   -- Send data byte to SD card.
              rtnState_v := WRITE_DATA;
              byteCnt_v  := byteCnt_v - 1;
            else
              bitCnt_v   := rx_v'length - 1;
              state_v    := RECEIVE;  -- Get response of SD card to the write operation.
              rtnState_v := WRITE_BUSY_WAIT;
            end if;
            
          when WRITE_BUSY_WAIT =>  -- Wait for SD card to finish writing the data block.
            sclk_r           <= not sclk_r;    -- Toggle the SPI clock...
            sclkPhaseTimer_v := clkDivider_v;  -- and set the duration of the next clock phase.
            if sclk_r = HI and miso_i = HI then
              -- The SD card will pull MISO low while it is busy, and raise it when it is done.
              sclkPhaseTimer_v := 0;
              state_v          := END_BLOCK_RW;  -- SD card done, so terminate this block write op.
            end if;
            
          when END_BLOCK_RW =>  -- Disable SD card chip-select after each block R/W.
            sclk_r           <= LO;
            sclkPhaseTimer_v := DELAY_BETWEEN_BLOCK_RW_C;
            state_v          := DESELECT;
            rtnState_v       := WAIT_FOR_HOST_RW;
            
          when TRANSMIT =>
            -- Start sending command/data by lowering SCLK and outputing MSB of command/data
            -- so it has plenty of setup before the rising edge of SCLK.
            sclk_r           <= LO;  -- Lower the SCLK (although it should already be low).
            sclkPhaseTimer_v := clkDivider_v;  -- Set the duration of the low SCLK.
            mosi_o           <= tx_v(tx_v'high);  -- Output MSB of command/data.
            tx_v             := tx_v(tx_v'high-1 downto 0) & ONE;  -- Shift command/data register by one bit.
            bitCnt_v         := bitCnt_v - 1;  -- The first bit has been sent, so decrement bit counter.
            state_v          := SHIFT_OUT;  -- Go here to shift out the rest of the command/data bits.
            
          when SHIFT_OUT =>  -- Shift out remaining command/data bits and (possibly) get response from SD card.
            sclk_r           <= not sclk_r;    -- Toggle the SPI clock...
            sclkPhaseTimer_v := clkDivider_v;  -- and set the duration of the next clock phase.
            if sclk_r = HI then
              -- SCLK is going to be flipped from high to low, so output the next command/data bit
              -- so it can setup while SCLK is low.
              if bitCnt_v /= 0 then  -- Keep sending bits until the bit counter hits zero.
                mosi_o   <= tx_v(tx_v'high);
                tx_v     := tx_v(tx_v'high-1 downto 0) & ONE;
                bitCnt_v := bitCnt_v - 1;
              else
                if getCmdResponse_v then
                  state_v  := GET_CMD_RESPONSE;  -- Get a response to the command from the SD card.
                  bitCnt_v := 7;        -- Length of the expected response.
                else
                  state_v := rtnState_v;  -- Return to calling state (no need to get a response).
--                  sclkPhaseTimer_v := 0;  -- Clear timer so next SPI op can begin ASAP with SCLK low.
                end if;
              end if;
            end if;

          when GET_CMD_RESPONSE =>  -- Get the response of the SD card to a command.
            if sclk_r = HI and miso_i = LO then  -- MISO will be held high by SD card until 1st bit of R1 response, which is 0.
              -- Shift in the MSB bit of the response.
              rx_v     := rx_v(rx_v'high-1 downto 0) & miso_i;
              bitCnt_v := bitCnt_v - 1;
              state_v  := RECEIVE;  -- Now receive the reset of the response.
            end if;
            sclk_r           <= not sclk_r;    -- Toggle the SPI clock...
            sclkPhaseTimer_v := clkDivider_v;  -- and set the duration of the next clock phase.

          when RECEIVE =>               -- Receive bits from the SD card.
            if sclk_r = HI then    -- Bits enter after the rising edge of SCLK.
              rx_v := rx_v(rx_v'high-1 downto 0) & miso_i;
              if bitCnt_v /= 0 then     -- More bits left to receive.
                bitCnt_v := bitCnt_v - 1;
              else                      -- Last bit has been received.
                if rtnData_v then       -- Send the received data to the host.
                  data_o   <= rx_v;
                  hndShk_r <= HI;  -- Signal to the host that the data is ready.
                end if;
                if getCmdResponse_v then
                  error_o             <= (others => ZERO);
                  error_o(rx_v'range) <= rx_v;
                end if;
                if doDeselect_v then
                  state_v      := DESELECT;
                  doDeselect_v := false;
                else
                  state_v := rtnState_v;       -- Return to calling state.
                end if;
              end if;
            end if;
            sclk_r           <= not sclk_r;    -- Toggle the SPI clock...
            sclkPhaseTimer_v := clkDivider_v;  -- and set the duration of the next clock phase.
            
          when DESELECT =>  -- De-select the SD card and send some clock pulses (Must enter with sclk at zero.)
            bitCnt_v         := 1;
            cs_bo            <= HI;
            mosi_o           <= HI;
            sclk_r           <= LO;
            state_v          := PULSE_SCLK;
            sclkPhaseTimer_v := clkDivider_v;  -- and set the duration of the next clock phase.
            
          when PULSE_SCLK =>  -- Issue some clock pulses. (Must enter with sclk at zero.)
            if sclk_r = HI then
              if bitCnt_v /= 0 then
                bitCnt_v := bitCnt_v - 1;
              else
                state_v := rtnState_v;
              end if;
            end if;
            sclk_r           <= not sclk_r;    -- Toggle the SPI clock...
            sclkPhaseTimer_v := clkDivider_v;  -- and set the duration of the next clock phase.
            
          when REPORT_ERROR => -- Report the error code and stall here until a reset occurs.
            error_o(rx_v'range) <= rx_v;  -- Output the R1 status as the error code.

          when others =>
            state_v := INIT;
        end case;
      end if;
    end if;
  end process;

  sclk_o   <= sclk_r;  -- Output the generated SPI clock for the SD card.
  hndShk_o <= hndShk_r;
  
end architecture;




--**********************************************************************
-- This module connects the SD card controller interface to a HostIoToDut
-- interface so the controller can be tested from a PC over a USB link.
--**********************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.CommonPckg.all;
use work.ClkGenPckg.all;
use work.HostIoPckg.all;
use work.SdCardPckg.all;
use work.SyncToClockPckg.all;

entity SdCardCtrlTest is
  generic (
    BASE_FREQ_G : real    := 12.0;
    CLK_MUL_G   : natural := 25;
    CLK_DIV_G   : natural := 3
    );
  port (
    fpgaClk_i     : in  std_logic;
    flashCs_bo    : out std_logic;
    usdflashCs_bo : out std_logic;
    sclk_o        : out std_logic;
    miso_i        : in  std_logic;
    mosi_o        : out std_logic
    );
end entity;

architecture arch of SdCardCtrlTest is
  signal clk_s           : std_logic;
  signal rd_is           : std_logic;
  signal wr_is           : std_logic;
  signal rdFromPc_s      : std_logic;
  signal wrFromPc_s      : std_logic;
  signal continue_is     : std_logic;
  signal addr_is         : std_logic_vector(31 downto 0);
  signal data_is         : std_logic_vector(7 downto 0);
  signal hndShkFromPc_s  : std_logic;
  signal hndShk_is       : std_logic;
  signal reset_is        : std_logic;
  signal vectorToDut_s   : std_logic_vector(44 downto 0);
  signal data_os         : std_logic_vector(7 downto 0);
  signal busy_os         : std_logic;
  signal hndShk_os       : std_logic;
  signal error_os        : std_logic_vector(15 downto 0);
  signal vectorFromDut_s : std_logic_vector(25 downto 0);
  signal cs_bs           : std_logic;
  signal mosi_s          : std_logic;
  signal sclk_s          : std_logic;
begin

  --**********************************************************************
  -- Keep the serial configuration flash turned off.
  --**********************************************************************
  flashCs_bo <= HI;

  --**********************************************************************
  -- Generate a higher frequency clock.
  --**********************************************************************
  u0 : ClkGen
    generic map (BASE_FREQ_G => BASE_FREQ_G, CLK_MUL_G => CLK_MUL_G, CLK_DIV_G => CLK_DIV_G)
    port map(I               => fpgaClk_i, O => clk_s);

  --**********************************************************************
  -- Interface a PC to the DUT which is the SD card controller.
  --**********************************************************************
  u1 : HostIoToDut
    generic map(
      FPGA_DEVICE_G => SPARTAN6,
      SIMPLE_G      => true
      )
    port map(
      vectorToDut_o   => vectorToDut_s,
      vectorFromDut_i => vectorFromDut_s
      );
  rdFromPc_s      <= vectorToDut_s(0);
  wrFromPc_s      <= vectorToDut_s(1);
  continue_is     <= vectorToDut_s(2);
  addr_is         <= vectorToDut_s(34 downto 3);
  data_is         <= vectorToDut_s(42 downto 35);
  hndShkFromPc_s  <= vectorToDut_s(43);
  reset_is        <= vectorToDut_s(44);
  vectorFromDut_s <= cs_bs & sclk_s & mosi_s & miso_i & error_os(11 downto 0) & hndShk_os & busy_os & data_os;

  --**********************************************************************
  -- Synchronize some control signals from the HostIoToDut to the SD card controller.
  --**********************************************************************
  u2a : SyncToClock
    port map(
      clk_i      => clk_s,
      unsynced_i => hndShkFromPc_s,
      synced_o   => hndShk_is
      );

  u2b : SyncToClock
    port map(
      clk_i      => clk_s,
      unsynced_i => rdFromPc_s,
      synced_o   => rd_is
      );

  u2c : SyncToClock
    port map(
      clk_i      => clk_s,
      unsynced_i => wrFromPc_s,
      synced_o   => wr_is
      );

  --**********************************************************************
  -- SD card controller module.
  --**********************************************************************
  u3 : SdCardCtrl
    generic map (
      FREQ_G => BASE_FREQ_G * real(CLK_MUL_G) / real(CLK_DIV_G)
      )
    port map (
      clk_i      => clk_s,
      -- Host interface.
      reset_i    => reset_is,
      rd_i       => rd_is,
      wr_i       => wr_is,
      continue_i => continue_is,
      addr_i     => addr_is,
      data_i     => data_is,
      data_o     => data_os,
      busy_o     => busy_os,
      hndShk_i   => hndShk_is,
      hndShk_o   => hndShk_os,
      error_o    => error_os,
      -- I/O signals to the external SD card.
      cs_bo      => cs_bs,
      sclk_o     => sclk_s,
      mosi_o     => mosi_s,
      miso_i     => miso_i
      );
  usdFlashCs_bo <= cs_bs;
  sclk_o        <= sclk_s;
  mosi_o        <= mosi_s;

end architecture;
