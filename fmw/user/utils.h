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

#ifndef UTILS_H
#define UTILS_H

#include "GenericTypeDefs.h"

#define INTERRUPTS_ON() INTCONbits.GIEH  = 1, INTCONbits.GIEL = 1
#define INTERRUPTS_OFF() INTCONbits.GIEH = 0, INTCONbits.GIEL = 0

void insert_delay( DWORD u_secs );
BYTE calc_checksum( BYTE *byte, WORD len );

#endif
