`timescale 1ns / 1ps
//**********************************************************************
// This is a simple design for echoing characters received from a host
// back to the host from an FPGA module.
//**********************************************************************
module EchoTestVerilog(
  input fpgaClk_i
);

// architecture arch of EchoTestVerilog is
  // signal clk_s                : std_logic;         -- Clock.
  // signal reset_s              : std_logic  := HI;  -- Active-high reset.
  // signal rmv_r                : std_logic  := LO;
  // signal add_r                : std_logic  := LO;
  // signal dly_r                : natural range 0 to 1;
  // signal dataFromHost_s       : std_logic_vector(7 downto 0);
  // signal dataToHost_r         : unsigned(7 downto 0);
  // signal empty_s, full_s      : std_logic;
  reg [7:0] dataToHost_r;
  reg rmv_r, add_r, dly_r;
  wire reset_s, clk_s, empty_s, full_s;
  wire [7:0] dataFromHost_s;

  // Generate 100 MHz clock from 12 MHz XuLA clock.
  //u0 : ClkGen generic map(CLK_MUL_G => 25, CLK_DIV_G => 3) port map(i => fpgaClk_i, o => clk_s);
  ClkGen u0(.i(fpgaClk_i), .o(clk_s));
  defparam u0.CLK_MUL_G = 25;
  defparam u0.CLK_DIV_G = 3;
  
  // Generatre active-high reset.
  //u1: ResetGenerator generic map(PULSE_DURATION_G => 10) port map(clk_i => clk_s, reset_o => reset_s);
  ResetGenerator u1(.clk_i(clk_s), .reset_o(reset_s));
  defparam u1.PULSE_DURATION_G = 10;

  // Instantiate the communication interface.
  // u2 : HostIoComm
    // generic map(
      // SIMPLE_G  => true
      // )
    // port map(
      // reset_i   => reset_s,
      // clk_i     => clk_s,
      // rmv_i     => rmv_r, -- Remove data received from the host.
      // data_o    => dataFromHost_s, -- Data from the host.
      // dnEmpty_o => empty_s,
      // add_i     => add_r, -- Add received data to FIFO going back to host (echo).
      // data_i    => std_logic_vector(dataToHost_r), -- Data to host.
      // upFull_o  => full_s
      // );
  HostIoComm u2(
    .reset_i(reset_s),
    .clk_i(clk_s),
    .rmv_i(rmv_r),
    .data_o(dataFromHost_s),
    .dnEmpty_o(empty_s),
    .add_i(add_r),
    .data_i(dataToHost_r),
    .upFull_o(full_s)
    );
  defparam u2.SIMPLE_G = 1;

  // This process scans the incoming FIFO for characters received from the host.
  // Then it removes a character from the host FIFO and places it in the FIFO that
  // transmits back to the host. It then waits a clock cycle while the FIFO statuses
  // are updated. Then it repeats the process.
  // echoProcess : process(clk_s)
  // begin
    // if rising_edge(clk_s) then
      // rmv_r  <= LO;
      // add_r  <= LO;
      // dly_r  <= 0;
      // if (reset_s = LO) and (dly_r = 0) and (empty_s = NO) and (full_s = NO) then
        // rmv_r        <= HI; -- Removes char received from host.
        // dataToHost_r <= unsigned(dataFromHost_s);  -- Store the char.
        // add_r        <= HI; -- Places char on FIFO back to host.
        // dly_r        <= 1;  -- Delay one cycle so FIFO statuses can update.
      // end if;
    // end if;
  // end process;
  always @(posedge clk_s) 
  begin
    rmv_r <= 1'b0;
    add_r <= 1'b0;
    dly_r <= 1'b0;
    if ((reset_s==1'b0) && (dly_r==1'b0) && (empty_s == 1'b0) && (full_s == 1'b0))
    begin
      rmv_r <= 1'b1;
      dataToHost_r <= dataFromHost_s;
      add_r <= 1'b1;
      dly_r <= 1'b1;
    end
  end

//end architecture;
endmodule
