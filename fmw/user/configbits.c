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
//  Configuration bit settings.
//
//********************************************************************

#pragma config  CPUDIV  = NOCLKDIV // CPU gets the same 48 MHz clock as the USB block.
#pragma config  USBDIV  = OFF // Doesn't really matter since we are using high-speed USB.
#pragma config  FOSC    = HS // Use an external 12 MHz crystal.
#pragma config  PLLEN   = ON // Multiply 12 MHz up to 48 MHz.
#pragma config  PCLKEN  = ON // Enable primary clock.
#pragma config  FCMEN   = OFF // Disable fail-safe clock monitor.
#pragma config  IESO    = OFF // Disable two-speed startup.
#pragma config  PWRTEN  = ON // Enable delay upon power-up.
#pragma config  BOREN   = SBORDIS // Hardware brown-out detection enabled.
#pragma config  BORV    = 27 // Brown-out level: 30=3.0V, 27=2.7V, 22=2.2V, 19=1.9V.
#pragma config  WDTEN   = OFF // Disable watch-dog timer.
#pragma config  WDTPS   = 32768 // Watch-dog timer postscaler.
#pragma config  MCLRE   = ON // Enable MCLR pin.
#pragma config  HFOFST  = OFF // HFINTOSC is not used, so who cares about fast start-up.
#pragma config  STVREN  = ON // Stack overflow causes a reset.
#pragma config  LVP     = OFF // No low-voltage programming.
#pragma config  BBSIZ   = OFF // Set boot block size to 2 KB (1 KW).
#pragma config  XINST   = OFF // Disable extended instructions.

// Boot block (0x0000 - 0x07FF)
#pragma config  CPB     = OFF
#pragma config  WRTB    = ON // Write-protect boot block.
#pragma config  EBTRB   = OFF

// Block 0 (0x0800 - 0x0FFF)
#pragma config  CP0     = OFF
#pragma config  WRT0    = OFF
#pragma config  EBTR0   = OFF

// Block 1 (0x1000 - 0x1FFF)
#pragma config  CP1     = OFF
#pragma config  WRT1    = OFF
#pragma config  EBTR1   = OFF

// Data EEPROM
#pragma config  CPD     = OFF
#pragma config  WRTD    = OFF
