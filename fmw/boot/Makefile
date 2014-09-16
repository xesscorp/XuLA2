# MPLAB IDE generated this makefile for use with GNU make.
# Project: XuLA_boot.mcp
# Date: Sun Nov 14 10:13:18 2010

AS = MPASMWIN.exe
CC = mcc18.exe
LD = mplink.exe
AR = mplib.exe
RM = rm
#OPTFLAGS = -Opa-
OPTFLAGS =

_output/XuLA_boot.cof : _output/main.o _output/usbmmap.o _output/usbdrv.o _output/usb9.o _output/usbdsc.o _output/usbctrltrf.o _output/boot.o _output/configbits.o
	$(LD) /p 18f14k50 /l"c:\mcc18\lib" "..\..\..\..\..\MCC18\bin\LKR\18f14k50_g.lkr" "_output\main.o" "_output\usbmmap.o" "_output\usbdrv.o" "_output\usb9.o" "_output\usbdsc.o" "_output\usbctrltrf.o" "_output\boot.o" "_output\configbits.o" /u_CRUNTIME /z__MPLAB_BUILD=1 /m"_output\XuLA_boot.map" /o"_output\XuLA_boot.cof"

_output/main.o : main.c ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h system/typedefs.h system/usb/usb.h autofiles/usbcfg.h system/usb/usbdefs/usbdefs_std_dsc.h autofiles/usbdsc.h system/usb/class/boot/boot.h usbcmd.h system/usb/usbdefs/usbdefs_ep0_buff.h system/usb/usbmmap.h system/usb/usbdrv/usbdrv.h system/usb/usbctrltrf/usbctrltrf.h system/usb/usb9/usb9.h io_cfg.h eeprom_flags.h system/usb/usb_compile_time_validation.h
	$(CC) -p=18F14K50 /i"C:\MCC18\h" -I"C:\xesscorp\PRODUCTS\USB_firmware\usb_boot" "main.c" -fo="_output\main.o" -scs $(OPTFLAGS)

_output/usbmmap.o : system/usb/usbmmap.c system/typedefs.h system/usb/usb.h autofiles/usbcfg.h system/usb/usbdefs/usbdefs_std_dsc.h autofiles/usbdsc.h system/usb/class/boot/boot.h usbcmd.h system/usb/usbdefs/usbdefs_ep0_buff.h system/usb/usbmmap.h system/usb/usbdrv/usbdrv.h system/usb/usbctrltrf/usbctrltrf.h system/usb/usb9/usb9.h
	$(CC) -p=18F14K50 /i"C:\MCC18\h" -I"C:\xesscorp\PRODUCTS\USB_firmware\usb_boot" "system\usb\usbmmap.c" -fo="_output\usbmmap.o" -scs $(OPTFLAGS)

_output/usbdrv.o : system/usb/usbdrv/usbdrv.c ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h system/typedefs.h system/usb/usb.h autofiles/usbcfg.h system/usb/usbdefs/usbdefs_std_dsc.h autofiles/usbdsc.h system/usb/class/boot/boot.h usbcmd.h system/usb/usbdefs/usbdefs_ep0_buff.h system/usb/usbmmap.h system/usb/usbdrv/usbdrv.h system/usb/usbctrltrf/usbctrltrf.h system/usb/usb9/usb9.h io_cfg.h
	$(CC) -p=18F14K50 /i"C:\MCC18\h" -I"C:\xesscorp\PRODUCTS\USB_firmware\usb_boot" "system\usb\usbdrv\usbdrv.c" -fo="_output\usbdrv.o" -scs $(OPTFLAGS)

_output/usb9.o : system/usb/usb9/usb9.c ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h system/typedefs.h system/usb/usb.h autofiles/usbcfg.h system/usb/usbdefs/usbdefs_std_dsc.h autofiles/usbdsc.h system/usb/class/boot/boot.h usbcmd.h system/usb/usbdefs/usbdefs_ep0_buff.h system/usb/usbmmap.h system/usb/usbdrv/usbdrv.h system/usb/usbctrltrf/usbctrltrf.h system/usb/usb9/usb9.h io_cfg.h
	$(CC) -p=18F14K50 /i"C:\MCC18\h" -I"C:\xesscorp\PRODUCTS\USB_firmware\usb_boot" "system\usb\usb9\usb9.c" -fo="_output\usb9.o" -scs $(OPTFLAGS)

_output/usbdsc.o : autofiles/usbdsc.c system/typedefs.h system/usb/usb.h autofiles/usbcfg.h system/usb/usbdefs/usbdefs_std_dsc.h autofiles/usbdsc.h system/usb/class/boot/boot.h usbcmd.h system/usb/usbdefs/usbdefs_ep0_buff.h system/usb/usbmmap.h system/usb/usbdrv/usbdrv.h system/usb/usbctrltrf/usbctrltrf.h system/usb/usb9/usb9.h
	$(CC) -p=18F14K50 /i"C:\MCC18\h" -I"C:\xesscorp\PRODUCTS\USB_firmware\usb_boot" "autofiles\usbdsc.c" -fo="_output\usbdsc.o" -scs $(OPTFLAGS)

_output/usbctrltrf.o : system/usb/usbctrltrf/usbctrltrf.c ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h system/typedefs.h system/usb/usb.h autofiles/usbcfg.h system/usb/usbdefs/usbdefs_std_dsc.h autofiles/usbdsc.h system/usb/class/boot/boot.h usbcmd.h system/usb/usbdefs/usbdefs_ep0_buff.h system/usb/usbmmap.h system/usb/usbdrv/usbdrv.h system/usb/usbctrltrf/usbctrltrf.h system/usb/usb9/usb9.h
	$(CC) -p=18F14K50 /i"C:\MCC18\h" -I"C:\xesscorp\PRODUCTS\USB_firmware\usb_boot" "system\usb\usbctrltrf\usbctrltrf.c" -fo="_output\usbctrltrf.o" -scs $(OPTFLAGS)

_output/boot.o : system/usb/class/boot/boot.c ../../../../../MCC18/h/p18cxxx.h ../../../../../MCC18/h/p18f14k50.h system/typedefs.h system/usb/usb.h autofiles/usbcfg.h system/usb/usbdefs/usbdefs_std_dsc.h autofiles/usbdsc.h system/usb/class/boot/boot.h usbcmd.h system/usb/usbdefs/usbdefs_ep0_buff.h system/usb/usbmmap.h system/usb/usbdrv/usbdrv.h system/usb/usbctrltrf/usbctrltrf.h system/usb/usb9/usb9.h io_cfg.h
	$(CC) -p=18F14K50 /i"C:\MCC18\h" -I"C:\xesscorp\PRODUCTS\USB_firmware\usb_boot" "system\usb\class\boot\boot.c" -fo="_output\boot.o" -scs $(OPTFLAGS)

_output/configbits.o : configbits.c
	$(CC) -p=18F14K50 /i"C:\MCC18\h" -I"C:\xesscorp\PRODUCTS\USB_firmware\usb_boot" "configbits.c" -fo="_output\configbits.o" -scs $(OPTFLAGS)

clean : 
	$(RM) "_output\main.o" "_output\usbmmap.o" "_output\usbdrv.o" "_output\usb9.o" "_output\usbdsc.o" "_output\usbctrltrf.o" "_output\boot.o" "_output\configbits.o" "_output\XuLA_boot.cof" "_output\XuLA_boot.hex" "_output\XuLA_boot.cod" "_output\XuLA_boot.lst" "_output\XuLA_boot.map"

