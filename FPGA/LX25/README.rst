==========================================
XuLA2 FPGA Design Examples
==========================================

Each of these directories contains a complete Xilinx ISE WebPACK 13 design project for the XuLA2-LX25 board.
(It's easy to re-target these to the XuLA2-LX9 board: just select **Project => Design Properties...** and change
the **Device** field to ``XC6SLX9``.)

    blinker/:
        A simple LED blinker design from chapter 4 of the book "FPGAs!? Now What?".

    counter/:
        A simple 26-bit counter that is driven by a 100 MHz clock and whose bits are output
        throuogh the prototyping header. This is a good design to check the functioning of
        the XuLA2 board. *Check the setting for the startup-clock - either JTAGCLK or CCLK -
        to make sure it complies with how you are using the XuLA2 board - either USB-connected
        or standalone.*

    fast_blinker/:
        The LED blinker design sped-up by using a DCM from chapter 5 of the book "FPGAs!? Now What?".

    fintf_jtag/:
        This design is used by GXSLOAD when it needs to read or write the contents of the
        serial flash configuration memory on the XuLA2 board.

    fintf_jtag_new/:
        This design is used by the Python version of XSLOAD when it needs to read or write the contents of the
        serial flash configuration memory on the XuLA2 board.

    hcsr04_test/:
        A simple interface to test an HCSR04 ultrasonic distance measurement module.

    hostio_test/:
        This design is used to test the ability of the HostIo modules to pass
        data back-and-forth between the FPGA and the host PC.
        
    HostIoToI2c:
        This design allows a host PC to talk to an I2C peripheral.
		
    ramintfc_jtag/:
        This design is used by GXSLOAD when it needs to read or write the contents of the
        SDRAM on the XuLA2 board.

    ramintfc_jtag_new/:
        This design is used by Python version of XSLOAD when it needs to read or write the contents of the
        SDRAM on the XuLA2 board.

    rand_test/:
        This design uses the hostio module to gather samples from the random-number generator module.
        
    SdcardTest/:
        This design tests the SD card controller module by having a PC write and read data blocks
        through the USB link.

    test_board_jtag/:
        This design is used by GXSTEST to test the SDRAM and report the success or failure
        through the JTAG and USB links.

    test_board_jtag_new/:
        This design is used by Python version of XSTEST to test the SDRAM and report the success or failure
        through the JTAG and USB links.


