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
//  This module manages the LED blinker.
//
//********************************************************************

#include "GenericTypeDefs.h"
#include "USB/usb.h"
#include "HardwareProfile.h"
#include "user.h"


#define BLINK_SCALER 10                 // Make larger to stretch the time between LED blinks.


BYTE blink_counter;          // Holds the number of times to blink the LED.
BYTE blink_scaler;           // Scaler to reduce blink rate over what can be achieved with only the TIMER3 hardware.


void InitBlinker( void )
{
    blink_counter    = 0;   // No blinks of the LED, yet.
    T3CON            = 0b00000000;  // 12 MHz clock input to TIMER3; TIMER3 disabled.
    IPR2bits.TMR3IP  = 0;   // Make TIMER3 overflow a low-priority interrupt.
    PIR2bits.TMR3IF  = 0;   // Clear TIMER3 interrupt flag.
    PIE2bits.TMR3IE  = 1;   // Enable TIMER3 interrupt.
    T3CONbits.TMR3ON = 1;   // Enable TIMER3.
}



void Blinker( void )
{
    PIR2bits.TMR3IF = 0;    // Clear the timer interrupt flag.

    runtest_timer--;

    // Decrement the scaler and reload it when it reaches zero.
    if ( blink_scaler == 0U )
        blink_scaler = BLINK_SCALER;
    blink_scaler--;

    if ( blink_counter > 0U ) // Toggle the LED as long as the blink counter is non-zero.
    {
        if ( blink_scaler == 0U ) // Only update the LED state when the scaler reaches zero.
        {
            LED_TOGGLE();
            blink_counter--;
        }
    }
    else    // Make sure the LED is left on after the blinking is done.
    {
        if ( USBGetDeviceState() < ADDRESS_STATE )
        {
            LED_OFF(); // Turn off the LED if the USB device has not linked with the PC yet.
        }
        else
        {
            LED_ON(); // The USB device has linked with the PC, so activate the LED.
        }
    }
}
