/*----------------------------------------------------------------------------------
	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
	02111-1307, USA.

	©2005-2010 - X Engineering Software Systems Corp.
----------------------------------------------------------------------------------*/

#ifndef USBCMD_H
#define USBCMD_H

/**
Definitions of commands sent in USB packets.
*/
typedef enum
{
    READ_VERSION_CMD       = 0x00,  // Read the product version information.
    READ_FLASH_CMD         = 0x01,  // Read from the device flash.
    WRITE_FLASH_CMD        = 0x02,  // Write to the device flash.
    ERASE_FLASH_CMD        = 0x03,  // Erase the device flash.
    READ_EEDATA_CMD        = 0x04,  // Read from the device EEPROM.
    WRITE_EEDATA_CMD       = 0x05,  // Write to the device EEPROM.
    READ_CONFIG_CMD        = 0x06,  // Read from the device configuration memory.
    WRITE_CONFIG_CMD       = 0x07,  // Write to the device configuration memory.
    ID_BOARD_CMD           = 0x31,  // Flash the device LED to identify which device is being communicated with.
    UPDATE_LED_CMD         = 0x32,  // Change the state of the device LED.
    INFO_CMD               = 0x40,  // Get information about the USB interface.
    SENSE_INVERTERS_CMD    = 0x41,  // ** Sense inverters on TCK and TDO pins of the secondary JTAG port.
    TMS_TDI_CMD            = 0x42,  // ** Send a single TMS and TDI bit.
    TMS_TDI_TDO_CMD        = 0x43,  // ** Send a single TMS and TDI bit and receive TDO bit.
    TDI_TDO_CMD            = 0x44,  // ** Send multiple TDI bits and receive multiple TDO bits.
    TDO_CMD                = 0x45,  // ** Receive multiple TDO bits.
    TDI_CMD                = 0x46,  // ** Send multiple TDI bits.
    RUNTEST_CMD            = 0x47,  // ** Pulse TCK a given number of times.
    NULL_TDI_CMD           = 0x48,  // ** Send string of TDI bits.
    PROG_CMD               = 0x49,  // Change the level of the FPGA PROGRAM# pin.
    SINGLE_TEST_VECTOR_CMD = 0x4a,  // ** Send a single, byte-wide test vector.
    GET_TEST_VECTOR_CMD    = 0x4b,  // ** Read the current test vector being output.
    SET_OSC_FREQ_CMD       = 0x4c,  // ** Set the frequency of the DS1075 oscillator.
    ENABLE_RETURN_CMD      = 0x4d,  // ** Enable return of info in response to a command.
    DISABLE_RETURN_CMD     = 0x4e,  // ** Disable return of info in response to a command.
    JTAG_CMD               = 0x4f,  // Send multiple TMS & TDI bits while receiving multiple TDO bits.
    FLASH_ONOFF_CMD        = 0x50,  // Enable/disable the FPGA configuration flash.
    RESET_CMD              = 0xff   // Cause a power-on reset.
} USBCMD;

#endif
