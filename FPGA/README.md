==========================================
XuLA2 FPGA Design Examples
==========================================

This directory contains example designs for all models of the XuLA2 board.

Any of the examples can be re-built using the `.xise` file in each directory along
with Xilinx ISE 14.

The following files also allow the examples to be rebuilt using `make`:

`setenv.bat`:
    This sets the PATH to include the Xilinx tools. It's only needed on Windows
    and you'll have to change it depending upon where you have your Xilinx tools
    installed.
    
`makefile`:
    Master makefile that compiles all the design examples for each XuLA2 board model.
    
`fpga_project.mk`:
    The makefile template for each design example. This file is included by the 
    makefile in each design example directory.
    
`fpga_project_rules.mk`:
    The rules for building an FPGA bitstream file from the files in the design
    example directory. This file is used by `fpga_project.mk`.

        
Really, Really Important Note!!!
------------------------------------------

All of these projects use the new unified library of VHDL components stored in the
[XESS VHDL_Lib repository](https://github.com/xesscorp/VHDL_Lib). If you try to compile 
these projects and you get a bunch of warnings about missing files, then you don't 
have this library installed or it's in the wrong place. Please look in the 
[VHDL_Lib README](https://github.com/xesscorp/VHDL_Lib/blob/master/README.rst) for 
instructions on how to install and use it.


FPGA Design Example Directories
------------------------------------------

`AdcSampler`:
    This example reads samples from a TI ADC108S ADC and stores them in the SDRAM.

`blinker`:
    A simple LED blinker from chapter 4 of the book "FPGAs!? Now What?".

`counter`:
    A simple 26-bit counter that is driven by a 100 MHz clock and whose bits are output
    through the prototyping header. This is a good design to check the functioning of
    the XuLA2 board. *Check the setting for the startup-clock - either JTAGCLK or CCLK -
    to make sure it complies with how you are using the XuLA2 board - either USB-connected
    or standalone.*

`fast_blinker`:
    The LED blinker design sped-up by using a DCM from chapter 5 of the book "FPGAs!? Now What?".

`fintf_jtag`:
    This design is used by the Python version of XSLOAD when it needs to read or write 
    the contents of the serial flash configuration memory on the XuLA2 board.

`fintf_jtag_old`:
    This design is used by GXSLOAD.EXE when it needs to read or write the contents of the
    serial flash configuration memory on the XuLA2 board.

`hcsr04_test`:
    A simple interface to test an HCSR04 ultrasonic distance measurement module.

`hostio_test`:
    This example tests the ability of the HostIo modules to pass
    data back-and-forth between the FPGA and the host PC.

`HostIoCommTest`:
    This example tests the ability of the HostIo communication module to pass
    data back-and-forth between the FPGA and the host PC.
    
`HostIoToI2cTest`:
    This example allows a host PC to talk to an I2C peripheral.
	
`ramintfc_jtag`:
    This design is used by the Python version of XSLOAD when it needs to read or write 
    the contents of the SDRAM on the XuLA2 board.

`ramintfc_jtag_old`:
    This design is used by GXSLOAD.EXE when it needs to read or write the contents of the
    SDRAM on the XuLA2 board.

`rand_test`:
    This example uses the hostio module to gather samples from a random-number generator module.
    
`RGBLed`:
    This example drives an RGB LED using three pulse-width modulators.
    
`SdcardCtrlTest`:
    This example tests the SD card controller module by having a PC write and read data blocks
    through the USB link.
    
`SdcardSfwTest`:
    This example tests an SD card by having a PC do low-level register reads and writes 
    to the card through the USB link.

`test_board_jtag`:
    This design is used by the Python version of XSTEST to test the SDRAM and report 
    the success or failure through the JTAG and USB links.

`test_board_jtag_old`:
    This design is used by GXSTEST.EXE to test the SDRAM and report the success or failure
    through the JTAG and USB links.

