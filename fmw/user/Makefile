# MPLAB IDE generated this makefile for use with GNU make.
# Project: XuLA_jtag.mcp
# Date: Sun Nov 14 09:25:31 2010

AS = MPASMWIN.exe
CC = mcc18.exe
LD = mplink.exe
AR = mplib.exe
RM = rm
#OPTFLAGS = -Ou- -Ot- -Ob- -Op- -Or- -Od- -Opa-
OPTFLAGS = 

_output/XuLA_jtag.cof : _output/main.o _output/configbits.o _output/user.o _output/usb_device.o _output/usb_function_generic.o _output/usb_descriptors.o _output/utils.o _output/blinker.o
	$(LD) /p 18f14k50 /l"C:\MCC18\lib" /k"C:\MCC18\bin\LKR" "18f14k50_g.lkr" "_output\main.o" "_output\configbits.o" "_output\user.o" "_output\usb_device.o" "_output\usb_function_generic.o" "_output\usb_descriptors.o" "_output\utils.o" "_output\blinker.o" /u_CRUNTIME /z__MPLAB_BUILD=1 /m"_output\XuLA_jtag.map" /o"_output\XuLA_jtag.cof"

_output/main.o : main.c ../../../../../MCC18/h/stdio.h ../../../../../MCC18/h/stdlib.h ../../../../../MCC18/h/string.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_common.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_device.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_hal.h main.c ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/GenericTypeDefs.h ../../../../../MCC18/h/stddef.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/Compiler.h ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h ../../../../../MCC18/h/stdarg.h usb_config.h ../../../../../MCC18/h/limits.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_ch9.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb_hal_pic18.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb_function_generic.h HardwareProfile.h user.h Blinker.h
	$(CC) -p=18F14K50 /i"." -I"C:\Microchip Solutions v2012-10-15\Microchip\Include" -I"C:\MCC18\h" "main.c" -fo="_output\main.o" -w3 $(OPTFLAGS)

_output/configbits.o : configbits.c
	$(CC) -p=18F14K50 /i"." -I"C:\Microchip Solutions v2012-10-15\Microchip\Include" -I"C:\MCC18\h" "configbits.c" -fo="_output\configbits.o" -w3 $(OPTFLAGS)

_output/user.o : user.c ../../../../../MCC18/h/stdio.h ../../../../../MCC18/h/stdlib.h ../../../../../MCC18/h/string.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_common.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_device.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_hal.h utils.h user.c ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/GenericTypeDefs.h ../../../../../MCC18/h/stddef.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/Compiler.h ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h ../../../../../MCC18/h/stdarg.h usb_config.h ../../../../../MCC18/h/limits.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_ch9.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb_hal_pic18.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb_function_generic.h HardwareProfile.h user.h usbcmd.h eeprom_flags.h blinker.h
	$(CC) -p=18F14K50 /i"." -I"C:\Microchip Solutions v2012-10-15\Microchip\Include" -I"C:\MCC18\h" "user.c" -fo="_output\user.o" -w3 $(OPTFLAGS)

_output/usb_device.o : ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/USB/usb_device.c ../../../../../MCC18/h/stdio.h ../../../../../MCC18/h/stdlib.h ../../../../../MCC18/h/string.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_common.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_device.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_hal.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/USB/usb_device.c ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/GenericTypeDefs.h ../../../../../MCC18/h/stddef.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/Compiler.h ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h ../../../../../MCC18/h/stdarg.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/USB.h usb_config.h ../../../../../MCC18/h/limits.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_ch9.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb_hal_pic18.h HardwareProfile.h
	$(CC) -p=18F14K50 /i"." -I"C:\Microchip Solutions v2012-10-15\Microchip\Include" -I"C:\MCC18\h" "C:\Microchip Solutions v2012-10-15\Microchip\USB\usb_device.c" -fo="_output\usb_device.o" -w3 $(OPTFLAGS)

_output/usb_function_generic.o : ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/USB/Generic\ Device\ Driver/usb_function_generic.c ../../../../../MCC18/h/stdio.h ../../../../../MCC18/h/stdlib.h ../../../../../MCC18/h/string.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_common.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_device.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_hal.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/GenericTypeDefs.h ../../../../../MCC18/h/stddef.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/Compiler.h ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h ../../../../../MCC18/h/stdarg.h usb_config.h ../../../../../MCC18/h/limits.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_ch9.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb_hal_pic18.h
	$(CC) -p=18F14K50 /i"." -I"C:\Microchip Solutions v2012-10-15\Microchip\Include" -I"C:\MCC18\h" "C:\Microchip Solutions v2012-10-15\Microchip\USB\Generic Device Driver\usb_function_generic.c" -fo="_output\usb_function_generic.o" -w3 $(OPTFLAGS)

_output/usb_descriptors.o : usb_descriptors.c ../../../../../MCC18/h/stdio.h ../../../../../MCC18/h/stdlib.h ../../../../../MCC18/h/string.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_common.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_device.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_hal.h usb_descriptors.c ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/GenericTypeDefs.h ../../../../../MCC18/h/stddef.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/Compiler.h ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h ../../../../../MCC18/h/stdarg.h usb_config.h ../../../../../MCC18/h/limits.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_ch9.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb_hal_pic18.h
	$(CC) -p=18F14K50 /i"." -I"C:\Microchip Solutions v2012-10-15\Microchip\Include" -I"C:\MCC18\h" "usb_descriptors.c" -fo="_output\usb_descriptors.o" -w3 $(OPTFLAGS)

_output/utils.o : utils.c ../../../../../MCC18/h/delays.h utils.c ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/GenericTypeDefs.h ../../../../../MCC18/h/stddef.h HardwareProfile.h
	$(CC) -p=18F14K50 /i"." -I"C:\Microchip Solutions v2012-10-15\Microchip\Include" -I"C:\MCC18\h" "utils.c" -fo="_output\utils.o" -w3 $(OPTFLAGS)

_output/blinker.o : blinker.c ../../../../../MCC18/h/stdio.h ../../../../../MCC18/h/stdlib.h ../../../../../MCC18/h/string.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_common.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_device.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_hal.h blinker.c ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/GenericTypeDefs.h ../../../../../MCC18/h/stddef.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/Compiler.h ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h ../../../../../MCC18/h/stdarg.h usb_config.h ../../../../../MCC18/h/limits.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/usb/usb_ch9.h ../../../../../Microchip\ Solutions\ v2012-10-15/Microchip/Include/USB/usb_hal_pic18.h HardwareProfile.h user.h
	$(CC) -p=18F14K50 /i"." -I"C:\Microchip Solutions v2012-10-15\Microchip\Include" -I"C:\MCC18\h" "blinker.c" -fo="_output\blinker.o" -w3 $(OPTFLAGS)

clean : 
	$(RM) "_output\main.o" "_output\configbits.o" "_output\user.o" "_output\usb_device.o" "_output\usb_function_generic.o" "_output\usb_descriptors.o" "_output\utils.o" "_output\blinker.o" "_output\XuLA_jtag.cof" "_output\XuLA_jtag.hex" "_output\XuLA_jtag.cod" "_output\XuLA_jtag.lst" "_output\XuLA_jtag.map"

total : _output/XuLA_jtag.cof ../boot/_output/XuLA_boot.hex
	head --lines=-1 ../boot/_output/XuLA_boot.hex > _output/XuLA_total.hex
	mp2hex /r 0x000800-0xFFFFFF _output/XuLA_jtag.cof
	cat _output/XuLA_jtag.hex >> _output/XuLA_total.hex
    echo "Remove one of the config bits sections from the final hex file!!!"

