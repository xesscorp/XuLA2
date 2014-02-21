==========================================
XuLA2 FPGA Design Examples
==========================================

Each of these directories contains a complete Xilinx ISE project for the XuLA2-LX9 board.
(Go to the ``LX25`` subdirectory for a more complete collection of projects.
You can recompile them for the XuLA2-LX9 board by changing the **Device** field in the **Design Properties**
to ``XC6SLX9``.)

    fintf_jtag/:
        This design is used by GXSLOAD when it needs to read or write the contents of the
        serial flash configuration memory on the XuLA2 board.

    fintf_jtag_new/:
        This design is used by the Python version of XSLOAD when it needs to read or write 
        the contents of the serial flash configuration memory on the XuLA2 board.

    ramintfc_jtag/:
        This design is used by GXSLOAD when it needs to read or write the contents of the
        SDRAM on the XuLA2 board.

    ramintfc_jtag_new/:
        This design is used by the Python version of XSLOAD when it needs to read or write 
        the contents of the SDRAM on the XuLA2 board.

    test_board_jtag/:
        This design is used by GXSTEST to test the SDRAM and report the success or failure
        through the JTAG and USB links.

    test_board_jtag_new/:
        This design is used by the Python version of XSTEST to test the SDRAM and report 
        the success or failure through the JTAG and USB links.
