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
//  Common utility routines.
//
//********************************************************************


#include <delays.h>
#include "GenericTypeDefs.h"
#include "HardwareProfile.h"


//
// Insert a delay of the requested number of microseconds.
//
void insert_delay( DWORD u_secs )
{
    DWORD instr_cycles = u_secs * MIPS;

    if ( instr_cycles < 10U )
        ;
    else if ( instr_cycles < 10U * 0xFFU )
        Delay10TCYx( instr_cycles / 10U );
    else if ( instr_cycles < 100U * 0xFFU )
        Delay100TCYx( instr_cycles / 100U );
    else if ( instr_cycles < 1000U * 0xFFU )
        Delay1KTCYx( instr_cycles / 1000U );
    else
    {
        for ( ; instr_cycles > 10000U; instr_cycles -= 10000 )
            Delay10KTCYx( 1 );
        insert_delay( instr_cycles / MIPS );
    }
}



//
// Calculate the checksum for a byte array.
//
BYTE calc_checksum( BYTE *byte, WORD len )
{
    BYTE checksum;
    for ( checksum = 0U; len > 0U; len-- )
        checksum += *byte++;
    return -checksum;
}
