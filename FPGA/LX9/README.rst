==========================================
XuLA2 FPGA Design Examples
==========================================

Each of these directories contains a complete Xilinx ISE WebPACK 13 design project for the XuLA2-LX9 board.
(You can find a more extensive collection of projects in the LX25 directory along with directions for how
to compile them for the Spartan-6 LX9 FPGA.)

    fintf_jtag/:
        This design is used by GXSLOAD when it needs to read or write the contents of the
        serial flash configuration memory on the XuLA2 board.

    fintf_jtag_new/:
        This design is used by the Python version of XSLOAD when it needs to read or write the contents of the
        serial flash configuration memory on the XuLA2 board.

    ramintfc_jtag/:
        This design is used by GXSLOAD when it needs to read or write the contents of the
        SDRAM on the XuLA2 board.

    ramintfc_jtag_new/:
        This design is used by the Python version of XSLOAD when it needs to read or write the contents of the
        SDRAM on the XuLA2 board.

    test_board_jtag/:
        This design is used by GXSTEST to test the SDRAM and report the success or failure
        through the JTAG and USB links.

    test_board_jtag_new/:
        This design is used by the Python version of XSTEST to test the SDRAM and report the success or failure
        through the JTAG and USB links.

=back
