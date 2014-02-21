==========================================
XuLA FPGA Design Examples
==========================================

This directory contains the following subdirectories of FPGA example designs for the XuLA2 board:

    XuLA_lib/:
        A directory of HDL files for modules that are useful in a variety of larger designs.

    LX25/:
        A directory of design projects for the XuLA2-LX25 board (done using Xilinx ISE WebPACK 13).
                
==========================================
XuLA2 FPGA Design Examples
==========================================

This directory contains the following subdirectories of FPGA example designs for the XuLA2 board:

    XuLA_lib/:
        A directory of HDL files for modules that are useful in a variety of larger designs.
        (These modules are retained for some legacy projects, but have been superseded by those 
        in the `VHDL_Lib repository <https://github.com/xesscorp/VHDL_Lib>`_.)

    LX9/:
        A directory of design projects for the XuLA2-LX9 board.

    LX25/:
        A directory of design projects for the XuLA2-LX25 board.

        
Really, Really Important Note!!!
==========================================

Many of these projects use the new unified library of VHDL components stored in the
`VHDL_Lib repository <https://github.com/xesscorp/VHDL_Lib>`_. If you try to compile 
these projects and you get a bunch of warnings about missing files, then you don't 
have this library installed or it's in the wrong place. Please look in the 
`VHDL_Lib README <https://github.com/xesscorp/VHDL_Lib/blob/master/README.rst>`_ for 
instructions on how to install and use it.