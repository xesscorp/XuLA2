//*********************************************************************
// Copyright (C) 2010 Dave Vanden Bout / XESS Corp. / www.xess.com
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
//
//====================================================================
//
// Module Description:
//  This module maps pins to their functions.  This provides a layer
//  of abstraction.
//
//********************************************************************

#ifndef HARDWAREPROFILE_H
#define HARDWAREPROFILE_H

//Uncomment one of the following lines to make the output HEX of this
//  project work with the HID or Microchip Bootloader
//#define PROGRAMMABLE_WITH_USB_HID_BOOTLOADER
#define PROGRAMMABLE_WITH_USB_MCHPUSB_BOOTLOADER

#define CLOCK_FREQ  48000000           // Clock frequency in Hz.
#define MIPS        12                 // Number of processor instructions per microsecond.

#define PRODUCTION_VERSION

#define INPUT_PIN   1
#define OUTPUT_PIN  0

/** Pin definition macros *******************************************/
#define TRIS( P, B )        ( TRIS ## P ## bits.TRIS ## P ## B )
#define PORT( P, B )        ( PORT ## P ## bits.R ## P ## B )
#define PORT_ASM( P, B )    PORT ## P ##, B, ACCESS
#define LATCH( P, B )       ( LAT ## P ## bits.LAT ## P ## B )
#define LATCH_ASM( P, B )   LAT ## P ##, B, ACCESS

/** Sense presence of external power (not used) *********************/
#if defined( USE_SELF_POWER_SENSE_IO )
#define tris_self_power     TRIS( A, 2 )
#define self_power          PORT( A, 2 )
#else
#define self_power          1
#endif

/** TDO *************************************************************/
#define TDO_PORT        B
#define TDO_BIT         4
#define TDO_MASK        ( 1 << TDO_BIT )
#define TDO_TRIS        TRIS( B, 4 )
#define TDO             PORT( B, 4 )
#define TDO_ASM         PORT_ASM( B, 4 )
#define INIT_TDO()      TDO_TRIS = INPUT_PIN

/** Serial flash disable *******************************************/
#ifdef PRODUCTION_VERSION
#define FLSHDSBL_PORT   B
#define FLSHDSBL_BIT    7
#define FLSHDSBL_MASK   ( 1 << FLSHDSBL_BIT )
#define FLSHDSBL_TRIS   TRIS( B, 7 )
#define FLSHDSBL        PORT( B, 7 )
#define FLSHDSBL_ASM    PORT_ASM( B, 7 )
#define INIT_FLSHDSBL() FLSHDSBL = 1, FLSHDSBL_TRIS = OUTPUT_PIN
#else
#define FLSHDSBL_PORT   B
#define FLSHDSBL_BIT    5
#define FLSHDSBL_MASK   ( 1 << FLSHDSBL_BIT )
#define FLSHDSBL_TRIS   TRIS( B, 5 )
#define FLSHDSBL        PORT( B, 5 )
#define FLSHDSBL_ASM    PORT_ASM( B, 5 )
#define INIT_FLSHDSBL() FLSHDSBL = 1, FLSHDSBL_TRIS = OUTPUT_PIN
#endif

/** Analog I/O 1 pin control ******************************************/
#define ANIO1_PORT      B
#define ANIO1_BIT       5
#define ANIO1_MASK      ( 1 << ANIO1_BIT )
#define ANIO1_TRIS      TRIS( B, 5 )
#define ANIO1           LATCH( B, 5 )
#define ANIO1_ASM       PORT_ASM( B, 5 )
#define INIT_ANIO1()    ANIO1 = 0, ANIO1_TRIS = INPUT_PIN

/** TCK *************************************************************/
#define TCK_PORT        B
#define TCK_BIT         6
#define TCK_MASK        ( 1 << TCK_BIT )
#define TCK_TRIS        TRIS( B, 6 )
#define TCK             LATCH( B, 6 )
#define TCK_ASM         PORT_ASM( B, 6 )
// Disable Port B pullups so they don't interfere with the TCK signal during switchover to MSSP.
#define INIT_TCK()      INTCON2bits.NOT_RABPU = 1, TCK = 0, TCK_TRIS = OUTPUT_PIN

/** FPGA DONE pin***************************************************/
#define DONE_PORT       C
#define DONE_BIT        0
#define DONE_MASK       ( 1 << DONE_BIT )
#define DONE_TRIS       TRIS( C, 0 )
#define DONE            PORT( C, 0 )
#define DONE_ASM        PORT_ASM( C, 0 )
#define INIT_DONE()     DONE_TRIS = INPUT_PIN

/** Sense presence of USB bus (not used) *****************************/
#if defined( USE_USB_BUS_SENSE_IO )
#define tris_usb_bus_sense  TRIS( C, 1 )
#define USB_BUS_SENSE       PORT( C, 1 )
#else
#define USB_BUS_SENSE       1
#endif

/** Analog I/O 0 pin control ******************************************/
#define ANIO0_PORT      C
#define ANIO0_BIT       2
#define ANIO0_MASK      ( 1 << ANIO0_BIT )
#define ANIO0_TRIS      TRIS( C, 2 )
#define ANIO0           LATCH( C, 2 )
#define ANIO0_ASM       PORT_ASM( C, 2 )
#define INIT_ANIO0()    ANIO0 = 0, ANIO0_TRIS = INPUT_PIN

/** FPGA PROG# pin control ******************************************/
#define PROGB_PORT      C
#define PROGB_BIT       3
#define PROGB_MASK      ( 1 << PROGB_BIT )
#define PROGB_TRIS      TRIS( C, 3 )
#define PROGB           LATCH( C, 3 )
#define PROGB_ASM       PORT_ASM( C, 3 )
#define INIT_PROGB()    PROGB = 0, PROGB_TRIS = OUTPUT_PIN

/** FPGA clock pin control ******************************************/
#define FPGACLK_PORT    C
#define FPGACLK_BIT     4
#define FPGACLK_MASK    ( 1 << FPGACLK_BIT )
#define FPGACLK_TRIS    TRIS( C, 4 )
#define FPGACLK         LATCH( C, 4 )
#define FPGACLK_ON()    PSTRCON = 0b00000010
#define FPGACLK_OFF()   PSTRCON = 0
// Setup the FPGA clock by initializing the PWM B channel to output a 12 MHz clock.
#define INIT_FPGACLK()  FPGACLK_OFF(), FPGACLK = 0, FPGACLK_TRIS = OUTPUT_PIN, \
                        T2CON = 0b00000100, PR2 = 0, CCPR1L = 0, CCP1CON = 0b00101100

/** LED *************************************************************/
#define LED_PORT        C
#define LED_BIT         5
#define LED_MASK        ( 1 << LED_BIT )
#define LED_TRIS        TRIS( C, 5 )
#define LED             LATCH( C, 5 )
#define LED_ASM         PORT_ASM( C, 5 )
#define LED_OFF()       LED = 0
#define LED_ON()        LED = 1
#define LED_TOGGLE()    LED = !LED
#define INIT_LED()      LED_OFF(), LED_TRIS = OUTPUT_PIN

/** TMS *************************************************************/
#define TMS_PORT        C
#define TMS_BIT         6
#define TMS_MASK        ( 1 << TMS_BIT )
#define TMS_TRIS        TRIS( C, 6 )
#define TMS             LATCH( C, 6 )
#define TMS_ASM         PORT_ASM( C, 6 )
#define INIT_TMS()      TMS = 0, TMS_TRIS = OUTPUT_PIN

/** TDI *************************************************************/
#define TDI_PORT        C
#define TDI_BIT         7
#define TDI_MASK        ( 1 << TDI_BIT )
#define TDI_TRIS        TRIS( C, 7 )
#define TDI             LATCH( C, 7 )
#define TDI_ASM         PORT_ASM( C, 7 )
#define INIT_TDI()      TDI = 0, TDI_TRIS = OUTPUT_PIN


/** Some common uC bits ********************************************/
// ALU carry bit.
#define CARRY_POS       0
#define CARRY_BIT_ASM   STATUS, CARRY_POS, ACCESS
// MSSP buffer-full bit.
#define MSSP_BF_POS     0
#define MSSP_BF_ASM     WREG, MSSP_BF_POS, ACCESS

// Converse of using ACCESS flag for destination register.
#define TO_WREG         0


#endif
