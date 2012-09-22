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

    ©2010 - X Engineering Software Systems Corp.
   ----------------------------------------------------------------------------------*/

#ifndef EEPROM_FLAGS_H
#define EEPROM_FLAGS_H

/**
   Definitions of flags stored in EEPROM of the uC.
 */

#define JTAG_DISABLE_FLAG_ADDR 0xFD
#define DISABLE_JTAG 0x69

#define FLASH_ENABLE_FLAG_ADDR 0xFE
#define ENABLE_FLASH 0xAC

#define BOOT_SELECT_FLAG_ADDR 0xFF
#define BOOT_INTO_USER_MODE 0xC5
#define BOOT_INTO_REFLASH_MODE 0x3A

#endif
