==========================================
XuLA-200 FPGA Design Examples
==========================================

Each of these directories contains a complete Xilinx ISE WebPACK 13 design project for the XuLA-200 board.

    blinker/:
        A simple LED blinker design from chapter 4 of the book "FPGAs!? Now What?".

    counter/:
        A simple 26-bit counter that is driven by a 100 MHz clock and whose bits are output
        throuogh the prototyping header. This is a good design to check the functioning of
        the XuLA board. *Check the setting for the startup-clock - either JTAGCLK or CCLK -
        to make sure it complies with how you are using the XuLA board - either USB-connected
        or standalone.*

    fast_blinker/:
        The LED blinker design sped-up by using a DCM from chapter 5 of the book "FPGAs!? Now What?".

    fintf_jtag/:
        This design is used by GXSLOAD when it needs to read or write the contents of the
        serial flash configuration memory on the XuLA board.

    hcsr04_test/:
        A simple interface to test an HCSR04 ultrasonic distance measurement module.

    hostio_test/:
        This design is used to test the ability of the HostIo modules to pass
        data back-and-forth between the FPGA and the host PC.
		
	LedDigitsWings/:
		A design that uses three StickIt! LED Modules for testing the wing connectors on the StickIt! motherboard.

    ramintfc_jtag/:
        This design is used by GXSLOAD when it needs to read or write the contents of the
        SDRAM on the XuLA board.

    rand_test/:
        This design uses the hostio module to gather samples from the random-number generator module.

    test_board_jtag/:
        This design is used by GXSTEST to test the SDRAM and report the success or failure
        through the JTAG and USB links.

=back
