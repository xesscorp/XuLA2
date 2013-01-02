//*********************************************************************
// Copyright (C) 2010-2013 Dave Vanden Bout / XESS Corp. / www.xess.com
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
// The code for reading the analog I/O pins of the uC was developed
// by Alireza Moini (amx1345@yahoo.com.au).
// 
//====================================================================
//
// Module Description:
//  This module manages the interface between the USB port and the JTAG
//  port of the FPGA.
//
//********************************************************************

#include "USB/usb.h"
#include "USB/usb_function_generic.h"
#include "HardwareProfile.h"
#include "GenericTypeDefs.h"
#include "version.h"
#include "user.h"
#include "usbcmd.h"
#include "eeprom_flags.h"
#include "utils.h"
#include "blinker.h"

// Information structure for device.
typedef struct DEVICE_INFO
{
    CHAR8 product_id[2];
    CHAR8 version_id[2];
    struct
    {
        // description string is size of max. USB packet minus storage for
        // product ID, device ID, checksum and command.
        CHAR8 str[USBGEN_EP_SIZE - 2 - 2 - 1 - 1];
    }     desc;
    CHAR8 checksum;
} DEVICE_INFO;

// USB data packet definitions
typedef union DATA_PACKET
{
    BYTE _byte[USBGEN_EP_SIZE];     //For byte access
    WORD _word[USBGEN_EP_SIZE / 2];   //For word access(USBGEN_EP_SIZE must be even)
    struct
    {
        USBCMD cmd;
        BYTE   len;
    };
    struct // for ADC conversions
    {
        USBCMD cmd;
        BYTE   adc_high;
        BYTE   adc_low;
    };
    struct
    {
        USBCMD      cmd;
        DEVICE_INFO device_info;
    };
    struct
    {
        USBCMD   cmd;
        unsigned tms : 1;
        unsigned tdi : 1;
        unsigned tdo : 1;
        unsigned : 5;
    };
    struct
    {
        USBCMD cmd;
        DWORD  num_tck_pulses;
    };
    struct
    {
        USBCMD   cmd;
        unsigned prog : 1;
    };
    struct // JTAG_CMD structure
    {
        USBCMD cmd;
        DWORD  num_clks;
        BYTE   flags;
    };
    struct // FLASH_ONOFF_CMD
    {
        USBCMD cmd;
        BYTE   flash_on;
    };
    struct // EEPROM read/write structure
    {
        USBCMD cmd;
        BYTE len;
        union
        {
            rom far char *pAdr;             //Address Pointer
            struct
            {
                BYTE low;                   //Little-endian order
                BYTE high;
                BYTE upper;
            };
        }ADR;
        BYTE data[USBGEN_EP_SIZE - 5];
    };
} DATA_PACKET;

// Definitions for JTAG_CMD
#define JTAG_CMD_HDR_LEN 6

// Flag bits for JTAG_CMD
#define GET_TDO_MASK 0x01                       // Set if gathering TDO bits.
#define PUT_TMS_MASK 0x02                       // Set if TMS bits are included in the packets.
#define TMS_VAL_MASK 0x04                       // Static value for TMS if PUT_TMS_MASK is cleared.
#define PUT_TDI_MASK 0x08                       // Set if TDI bits are included in the packets.
#define TDI_VAL_MASK 0x10                       // Static value for TDI if PUT_TDI_MASK is cleared.

#define MIPS 12                         // Number of processor instructions per microsecond.
#define MAX_BYTE_VAL 0xFF               // Maximum value that can be stored in a byte.
#define NUM_ACTIVITY_BLINKS 10          // Indicate activity by blinking the LED this many times.
#define BLINK_SCALER 10                 // Make larger to stretch the time between LED blinks.
#define DO_DELAY_THRESHOLD 5461UL       // Threshold between pulsing TCK or using a timer = (1000000 / (12000000 / 256))
#define USE_MSSP     1                  // True if driving JTAG with MSSP block; false to use bit-banging.


#pragma romdata
static const rom DEVICE_INFO device_info
    = {
    0x00, 0x02,         // Product ID.
    MAJOR_VERSION, MINOR_VERSION,         // Version.
    { "XuLA" },         // Description string.
    0x00                // Checksum (filled in later).
    }; // Change version in usb_descriptors.c as well!!

// This table is used to reverse the bits within a byte.  The table has to be located at
// the beginning of a page because we index into the table by placing the byte value
// whose bits are to be reversed into TBLPTRL without changing TBLPTRH or TBLPTRU.
#pragma romdata reverse_bits_section=0x3F00
static rom const BYTE reverse_bits [] = {
    0x00, 0x80, 0x40, 0xc0, 0x20, 0xa0, 0x60, 0xe0, 0x10, 0x90, 0x50, 0xd0, 0x30, 0xb0, 0x70, 0xf0,
    0x08, 0x88, 0x48, 0xc8, 0x28, 0xa8, 0x68, 0xe8, 0x18, 0x98, 0x58, 0xd8, 0x38, 0xb8, 0x78, 0xf8,
    0x04, 0x84, 0x44, 0xc4, 0x24, 0xa4, 0x64, 0xe4, 0x14, 0x94, 0x54, 0xd4, 0x34, 0xb4, 0x74, 0xf4,
    0x0c, 0x8c, 0x4c, 0xcc, 0x2c, 0xac, 0x6c, 0xec, 0x1c, 0x9c, 0x5c, 0xdc, 0x3c, 0xbc, 0x7c, 0xfc,
    0x02, 0x82, 0x42, 0xc2, 0x22, 0xa2, 0x62, 0xe2, 0x12, 0x92, 0x52, 0xd2, 0x32, 0xb2, 0x72, 0xf2,
    0x0a, 0x8a, 0x4a, 0xca, 0x2a, 0xaa, 0x6a, 0xea, 0x1a, 0x9a, 0x5a, 0xda, 0x3a, 0xba, 0x7a, 0xfa,
    0x06, 0x86, 0x46, 0xc6, 0x26, 0xa6, 0x66, 0xe6, 0x16, 0x96, 0x56, 0xd6, 0x36, 0xb6, 0x76, 0xf6,
    0x0e, 0x8e, 0x4e, 0xce, 0x2e, 0xae, 0x6e, 0xee, 0x1e, 0x9e, 0x5e, 0xde, 0x3e, 0xbe, 0x7e, 0xfe,
    0x01, 0x81, 0x41, 0xc1, 0x21, 0xa1, 0x61, 0xe1, 0x11, 0x91, 0x51, 0xd1, 0x31, 0xb1, 0x71, 0xf1,
    0x09, 0x89, 0x49, 0xc9, 0x29, 0xa9, 0x69, 0xe9, 0x19, 0x99, 0x59, 0xd9, 0x39, 0xb9, 0x79, 0xf9,
    0x05, 0x85, 0x45, 0xc5, 0x25, 0xa5, 0x65, 0xe5, 0x15, 0x95, 0x55, 0xd5, 0x35, 0xb5, 0x75, 0xf5,
    0x0d, 0x8d, 0x4d, 0xcd, 0x2d, 0xad, 0x6d, 0xed, 0x1d, 0x9d, 0x5d, 0xdd, 0x3d, 0xbd, 0x7d, 0xfd,
    0x03, 0x83, 0x43, 0xc3, 0x23, 0xa3, 0x63, 0xe3, 0x13, 0x93, 0x53, 0xd3, 0x33, 0xb3, 0x73, 0xf3,
    0x0b, 0x8b, 0x4b, 0xcb, 0x2b, 0xab, 0x6b, 0xeb, 0x1b, 0x9b, 0x5b, 0xdb, 0x3b, 0xbb, 0x7b, 0xfb,
    0x07, 0x87, 0x47, 0xc7, 0x27, 0xa7, 0x67, 0xe7, 0x17, 0x97, 0x57, 0xd7, 0x37, 0xb7, 0x77, 0xf7,
    0x0f, 0x8f, 0x4f, 0xcf, 0x2f, 0xaf, 0x6f, 0xef, 0x1f, 0x9f, 0x5f, 0xdf, 0x3f, 0xbf, 0x7f, 0xff,
};

#pragma udata access my_access
static near DWORD lcntr;                    // Large counter for fast loops.
static near BYTE buffer_cntr;               // Holds the number of bytes left to process in the USB packet.
static near WORD save_FSR0, save_FSR1;      // Used for saving the contents of PIC hardware registers.

#pragma udata
static USB_HANDLE OutHandle[2] = {0,0}; // Handles to endpoint buffers that are receiving packets from the host.
static BYTE OutIndex           = 0;     // Index of endpoint buffer has received a complete packet from the host.
static DATA_PACKET *OutPacket;          // Pointer to the buffer with the most-recently received packet.
static BYTE OutPacketLength    = 0;     // Length (in bytes) of most-recently received packet.
static USB_HANDLE InHandle[2]  = {0,0}; // Handles to ping-pong endpoint buffers that are sending packets to the host.
static BYTE InIndex            = 0;     // Index of the endpoint buffer that is currently being filled before being sent to the host.
static DATA_PACKET *InPacket;           // Pointer to the buffer that is currently being filled.
WORD runtest_timer;                     // Timer for RUNTEST command.

#pragma udata usbram2
static DATA_PACKET InBuffer[2];     // Ping-pong buffers in USB RAM for sending packets to host.
static DATA_PACKET OutBuffer[2];    // Ping-pong buffers in USB RAM for receiving packets from host.


#pragma code

BYTE ReadEeprom(BYTE address)
{
    EECON1 = 0x00;
    EEADR = address;
    EECON1bits.RD = 1;
    return EEDATA;
}

void WriteEeprom(BYTE address, BYTE data)
{
    EEADR = address;
    EEDATA = data;
    EECON1 = 0b00000100;    //Setup writes: EEPGD=0,WREN=1
    EECON2 = 0x55;
    EECON2 = 0xAA;
    EECON1bits.WR = 1;
    while(EECON1bits.WR);       //Wait till WR bit is clear
}

void ProcessEepromFlags(void)
{
    if(ReadEeprom(FLASH_ENABLE_FLAG_ADDR) == ENABLE_FLASH)
    {
        // Enable flash access by FPGA by releasing flash chip-enable.
        FLSHDSBL_TRIS = INPUT_PIN; // The uC no longer holds the flash chip-enable high.
    }
    else
    {
        // Disable flash by pulling flash chip-enable high.
        FLSHDSBL = 1;
        FLSHDSBL_TRIS = OUTPUT_PIN;
    }

    if(ReadEeprom(JTAG_DISABLE_FLAG_ADDR) == DISABLE_JTAG)
    {
        // Disable uC from driving FPGA JTAG pins so external JTAG cable can do it.
        TCK_TRIS = INPUT_PIN;
        TMS_TRIS = INPUT_PIN;
        TDI_TRIS = INPUT_PIN;
        TDO_TRIS = INPUT_PIN;
        // Release PROGB so external JTAG programmer can program the FPGA.
        PROGB    = 1;
    }
    else
    {
        // Enable uC drivers of FPGA JTAG pins.
        TCK = 0;    // Make sure TCK starts at low level.
        TCK_TRIS = OUTPUT_PIN;
        TMS_TRIS = OUTPUT_PIN;
        TDI_TRIS = OUTPUT_PIN;
        TDO_TRIS = INPUT_PIN;
        // If uC is in charge of FPGA programming, then pull PROGB low if flash didn't config FPGA.
        if(DONE == 0)
            PROGB = 0; // FPGA didn't configure, so erase it and hold it in unconfigured state.

    }   
}

void UserInit( void )
{
    DWORD config_delay;

    // Initialize the I/O pins.
    // Enable high slew-rate for the I/O pins.
    SLRCON = 0;
    // Disable analog functions of the I/O pins.
    // Enable the one for RB5 and RC2
    ANSEL = 0;
    ANSELH = 0;
    ANSELbits.ANS6  = 1;
    ANSELHbits.ANS11 = 1;
    // Initialize the JTAG pins to/from the FPGA.
    INIT_TCK();
    INIT_TMS();
    INIT_TDI();
    INIT_TDO();
    // Initialize disable pin for FPGA config. flash.
    INIT_FLSHDSBL();
    // Initialize the analog I/O pins.
    // INIT_ANIO0();
    // INIT_ANIO1();
    TRISCbits.TRISC2  = 1;              // Make the pin an analog input.
    TRISBbits.TRISB5  = 1;              // Make the pin an analog input.
    REFCON0bits.FVR1EN= 1;              // Enable the fixed voltage reference.
    REFCON0bits.FVR1S1= 1;              // Set the voltage reference ...
    REFCON0bits.FVR1S0= 0;              // ... output to 2.048V.
    ADCON2bits.ADCS   = 0x6;            // ADC conversion clock = F/64.
    ADCON2bits.ACQT   = 0x5;            // Acquisition time = 12 * Tad.
    ADCON1bits.NVCFG0 = 0;              // Set negative voltage reference ...
    ADCON1bits.NVCFG1 = 0;              // ... for the ADC to GND.
    ADCON1bits.PVCFG0 = 0;              // Set positive voltage reference ...
    ADCON1bits.PVCFG1 = 1;              // ... for the ADC to fixed voltage ref.
    ADCON0bits.ADON   = 1;              // Turn the ADC on.
    ADCON2bits.ADFM   = 1;              // Right-justify the ADC output.
    // Initialize the FPGA configuration pins.
    INIT_DONE();
    INIT_PROGB();
    // Initialize the clock to the FPGA.
    INIT_FPGACLK();
    // Initialize the status LED.
    INIT_LED();

    #if defined( USE_USB_BUS_SENSE_IO )
    tris_usb_bus_sense = INPUT_PIN;
    #endif

    #if defined( USE_SELF_POWER_SENSE_IO )
    tris_self_power    = INPUT_PIN;
    #endif

    InitBlinker();  // Initialize LED status blinker.

    #if USE_MSSP
    // Setup the Master Synchronous Serial Port in SPI mode for driving the FPGA JTAG pins.
    PIE1bits.SSPIE    = 0;      // Disable SSP interrupts.
    SSPCON1bits.SSPEN = 0;      // Disable the SSP until it's needed.
    SSPSTATbits.SMP   = 0;      // Sample TDO on the rising clock edge.  (TDO changes on the falling clock edge.)
    SSPSTATbits.CKE   = 1;      // Change the bit output to TDI on the falling clock edge. (TDI is sampled on rising clock edge.)
    SSPCON1bits.CKP   = 0;      // Make the clock's idle state be the low logic level (logic 0).
    SSPCON1bits.SSPM0 = 0;      // Set the SSP into SPI master mode with clock = Fosc/4 (fastest setting).
    SSPCON1bits.SSPM1 = 0;      //    MUST STAY AT THIS SETTING BECAUSE WE ASSUME BYTE TRANSMISSION
    SSPCON1bits.SSPM2 = 0;      //    TAKES 8 INSTRUCTION CYCLES IN THE TDI, TDO LOOPS BELOW!!!
    SSPCON1bits.SSPM3 = 0;
    #endif

    // Initialize interrupts.
    RCONbits.IPEN     = 1;      // Enable prioritized interrupts.
    INTERRUPTS_ON();            // Enable high and low-priority interrupts.

    // Try to configure the FPGA from the serial flash.
    PROGB = 0;                  // Erase the FPGA.
    // Keep the flash disabled for 1000 us = 1ms.
    FLSHDSBL = 1;
    FLSHDSBL_TRIS = OUTPUT_PIN;
    insert_delay(1000);
    FLSHDSBL_TRIS = INPUT_PIN;  // Give FPGA control of the serial flash chip-select.
    PROGB = 1;                  // Release FPGA and let it try to configure from the serial flash.
    // Now wait for a while and see if the FPGA configuration done pin goes high.
    for(config_delay=0L; config_delay<500000L; config_delay++)
    {
        if(DONE == 1)
            break;
    }
    FLSHDSBL_TRIS = OUTPUT_PIN; // Any FPGA configuration is done, so disable the flash.

    // Process EEPROM flags only AFTER FPGA tries to config from flash.
    ProcessEepromFlags();       // Process the non-volatile flags stored in EEPROM.

    FPGACLK_ON();               // Give the FPGA a clock whether it is configured or not.
}



// This function is called when the device becomes initialized, which occurs after the host sends a
// SET_CONFIGURATION (wValue not = 0) request.  This callback function should initialize the endpoints
// for the device's usage according to the current configuration.
void USBCBInitEP( void )
{
    // Enable the endpoint.
    USBEnableEndpoint( USBGEN_EP_NUM, USB_OUT_ENABLED | USB_IN_ENABLED | USB_HANDSHAKE_ENABLED | USB_DISALLOW_SETUP );
    // Now begin waiting for the first packets to be received from the host via this endpoint.
    OutIndex = 0;
    OutHandle[0] = USBGenRead( USBGEN_EP_NUM, (BYTE *)&OutBuffer[0], USBGEN_EP_SIZE );
    OutHandle[1] = USBGenRead( USBGEN_EP_NUM, (BYTE *)&OutBuffer[1], USBGEN_EP_SIZE );
    // Initialize the pointer to the buffer which will return data to the host via this endpoint.
    InIndex = 0;
    InPacket  = &InBuffer[0];
}



void ProcessIO( void )
{
    if ( ( USBGetDeviceState() < CONFIGURED_STATE ) || USBIsDeviceSuspended() )
        return;

    ServiceRequests();
}



void ServiceRequests( void )
{
    BYTE num_return_bytes;          // Number of bytes to return in response to received command.
    BYTE *tdi;                      // Pointer to the buffer of received TDI bits.
    BYTE *tdo;                      // Pointer to the buffer for returning TDO bits.
    BYTE *tms_tdi;                  // Pointer to the buffer of received TDI & TMS bits.
    DWORD num_clks;                 // # of TCK pulses to send TMS/TDI bits to JTAG device.
    DWORD num_bytes;                // # of total bytes in the stream of TMS/TDI/TDO bits.
    BYTE flags;                     // local storage for JTAG_CMD flags.
    BYTE bit_mask;                  // Mask to select bit from a byte.
    BYTE bit_cntr;                  // Counter within a byte of bits.
    BYTE tms_byte, tdi_byte, tdo_byte;      // Temporary bytes of TMS, TDI and TDO bits.
    BYTE cmd;                     // Store the command in the received packet.

    // Process packets received through the primary endpoint.
    if ( !USBHandleBusy( OutHandle[OutIndex] ) )
    {
        num_return_bytes = 0;   // Initially, assume nothing needs to be returned.

        // Got a packet, so start getting another packet while we process this one.
        OutPacket        = &OutBuffer[OutIndex]; // Store pointer to just-received packet.
        OutPacketLength  = USBHandleGetLength( OutHandle[OutIndex] );   // Store length of received packet.
        cmd              = OutPacket->cmd;

        blink_counter    = NUM_ACTIVITY_BLINKS; // Blink the LED whenever a USB transaction occurs.

        switch ( cmd )  // Process the contents of the packet based on the command byte.
        {
            case ID_BOARD_CMD:
                // Blink the LED in order to identify the board.
                blink_counter                  = 50;
                InPacket->cmd                  = cmd;
                num_return_bytes               = 1;
                break;

            case INFO_CMD:
                // Return a packet with information about this USB interface device.
                InPacket->cmd                  = cmd;
                memcpypgm2ram( ( void * )( (BYTE *)InPacket + 1 ), (const rom void *)&device_info, sizeof( DEVICE_INFO ) );
                InPacket->device_info.checksum = calc_checksum( (CHAR8 *)InPacket, sizeof( DEVICE_INFO ) );
                num_return_bytes               = sizeof( DEVICE_INFO ) + 1; // Return information stored in packet.
                break;

            case TMS_TDI_CMD:
                // Output TMS and TDI values and pulse TCK.
                TMS = OutPacket->tms;
                TDI = OutPacket->tdi;
                TCK = 1;
                TCK = 0;
                // Don't return any packets.
                break;

            case TMS_TDI_TDO_CMD:
                // Sample TDO, output TMS and TDI values, pulse TCK, and return TDO value.
                InPacket->cmd    = cmd;
                InPacket->tdo    = TDO; // Place TDO pin value into the command packet.
                TMS              = OutPacket->tms;
                TDI              = OutPacket->tdi;
                TCK              = 1;
                TCK              = 0;
                num_return_bytes = 2;           // Return the packet with the TDO value in it.
                break;

            case TDI_CMD:       // get USB packets of TDI data, output data to TDI pin of JTAG device
            case TDI_TDO_CMD:   // get USB packets, output data to TDI pin, input data from TDO pin, send USB packets
            case TDO_CMD:       // input data from TDO pin of JTAG device, send USB packets of TDO data
                blink_counter = MAX_BYTE_VAL;   // Blink LED continuously during the long duration of this command.

                // The first packet received contains the TDI_CMD command and the number
                // of TDI bits that will follow in succeeding packets.
                num_clks      = OutPacket->num_clks;

                // Exit if no TDI bits will follow (this is probably an error...).
                if ( num_clks == 0U )
                    break;
                num_bytes     = ( num_clks + 7 ) / 8; // Total number of bytes in all the packets that will follow.

                TCK           = 0; // Initialize TCK (should have been low already).
                TMS           = 0; // Initialize TMS to keep TAP FSM in Shift-IR or Shift-DR state).

                #if USE_MSSP
                if ( num_clks > 8U )
                {
                    TCK_TRIS          = INPUT_PIN; // Disable the TCK output so that the clock won't glitch when the MSSP is enabled.
                    SSPCON1bits.SSPEN = 1; // Enable the MSSP.
                    TCK_TRIS          = OUTPUT_PIN; // Enable the TCK output after the MSSP glitch is over.
                }
                #endif

                if ( ( cmd == TDI_TDO_CMD ) || ( cmd == TDI_CMD ) )
                {
                    // Wait until a completely filled packet of TDI bits arrives.
                    // This command packet has been handled, so get another.
                    OutHandle[OutIndex] = USBGenRead( USBGEN_EP_NUM, (BYTE *)&OutBuffer[OutIndex], USBGEN_EP_SIZE );
                    OutIndex ^= 1; // Point to next ping-pong buffer.

                    // Wait until the next packet of TMS & TDI bits arrives.
                    while ( USBHandleBusy( OutHandle[OutIndex] ) )
                        ;
                    OutPacketLength = USBHandleGetLength( OutHandle[OutIndex] );    // Store length of received packet.
                    OutPacket       = &OutBuffer[OutIndex]; // Store pointer to just-received packet.
                    tdi             = (BYTE *)OutPacket; // Init pointer to the just-received TDI data.
                }
                else if( cmd = TDO_CMD )
                {
                    // When we are not receiving any further TDI packets and are just returning packets of TDO bits,
                    // then set the received packet length to the maximum size so the following 'while' loop will
                    // work even though no new packets are arriving.  This is a sloppy fix, but it's the easiest
                    // way to make the code work.
                    OutPacketLength = USBGEN_EP_SIZE;
                }
                tdo         = (BYTE *)InPacket; // TDO data will be written here.

                // Process the first M-1 of M packets that are completely filled with TDI and/or TDO bits.
                while ( num_bytes > OutPacketLength )
                {
                    num_bytes -= OutPacketLength;

                    if ( blink_counter == 0U )
                        blink_counter = MAX_BYTE_VAL;   // Blink LED continuously during the long duration of this command.

                    // Process the bytes in the TDI packet.
                    buffer_cntr = OutPacketLength;
                    save_FSR0   = FSR0;
                    save_FSR1   = FSR1;

                    if ( cmd == TDI_CMD )
                    {
                        TBLPTR = (UINT24)reverse_bits;  // Setup the pointer to the bit-order table.
                        FSR0   = (WORD)tdi;
                        #if USE_MSSP
                        _asm
                        MOVFF POSTINC0, TBLPTRL             // Get the current TDI byte and use it to index into the bit-order table.
                        TBLRD                               // TABLAT now contains the TDI byte in the proper bit-order.
                        MOVFF TABLAT, SSPBUF                // Load TDI byte into SPI transmitter.
                        NOP
                        NOP
PRI_TDI_LOOP_0:
                        DCFSNZ buffer_cntr, 1, ACCESS       // Decrement the buffer counter and continue if not zero
                        BRA PRI_TDI_LOOP_1
                        MOVFF POSTINC0, TBLPTRL             // Get the current TDI byte and use it to index into the bit-order table.
                        TBLRD                               // TABLAT now contains the TDI byte in the proper bit-order.
                        MOVFF SSPBUF, TBLPTRL               // Get the TDO byte just to clear the buffer-full flag (don't use TDO).
                        MOVFF TABLAT, SSPBUF                // Load TDI byte into SPI transmitter ASAP.
                        BRA PRI_TDI_LOOP_0
PRI_TDI_LOOP_1:
                        NOP
                        NOP
                        NOP
                        MOVFF SSPBUF, TBLPTRL               // Get the TDO byte just to clear the buffer-full flag (don't use TDO).
                        _endasm
                        #else
                        _asm
PRI_TDI_LOOP_0:
                        MOVFF POSTINC0, TBLPTRL             // Get the current TDI byte and use it to index into the bit-order table.
                        TBLRD                               // TABLAT now contains the TDI byte in the proper bit-order.
                        // Bit 7 of a byte of TDI/TDO bits.
                        RLCF TABLAT, 1, ACCESS              // Rotate TDI bit into carry.
                        BSF TDI_ASM                     // Set TDI pin of JTAG device to value of TDI bit.
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM                     // Toggle TCK pin of JTAG device.
                        BCF TCK_ASM
                        // Bit 6
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 5
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 4
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 3
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 2
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 1
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 0
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        DECFSZ buffer_cntr, 1, ACCESS       // Decrement the buffer counter and continue
                        BRA PRI_TDI_LOOP_0                  //   processing TDI bytes until it is 0.
                        _endasm
                        #endif
                    }
                    else if ( cmd == TDI_TDO_CMD )
                    {
                        TBLPTR = (UINT24)reverse_bits;  // Setup the pointer to the bit-order table.
                        FSR0   = (WORD)tdi;
                        FSR1   = (WORD)tdo;
                        #if USE_MSSP
                        _asm
PRI_TDI_TDO_LOOP_0:
                        MOVFF POSTINC0, TBLPTRL             // Get the current TDI byte and use it to index into the bit-order table.
                        TBLRD                               // TABLAT now contains the TDI byte in the proper bit-order.
                        MOVFF TABLAT, SSPBUF                // Load TDI byte into SPI transmitter.
                        NOP                                 // The NOPs are used to insert delay while the SSPBUF is tx/rx'ed.
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
                        MOVFF SSPBUF, TBLPTRL               // Get the TDO byte that was received and use it to index into the bit-order table.
                        TBLRD                               // TABLAT now contains the TDO byte in the proper bit-order.
                        MOVFF TABLAT, POSTINC1              // Store the TDO byte into the buffer and inc. the pointer.
                        DECFSZ buffer_cntr, 1, ACCESS       // Decrement the buffer counter and continue
                        BRA PRI_TDI_TDO_LOOP_0              //   processing TDI bytes until it is 0.
                        _endasm
                        #else
                        _asm
PRI_TDI_TDO_LOOP_0:
                        MOVFF POSTINC0, TBLPTRL             // Get the current TDI byte and use it to index into the bit-order table.
                        TBLRD                               // TABLAT now contains the TDI byte in the proper bit-order.
                        // Bit 7 of a byte of TDI/TDO bits.
                        BCF CARRY_BIT_ASM                   // Set carry to value on TDO pin of JTAG device.
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS              // Rotate TDO value into TABLAT register and TDI bit into carry.
                        BSF TDI_ASM                     // Set TDI pin of JTAG device to value of TDI bit.
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM                     // Toggle TCK pin of JTAG device.
                        BCF TCK_ASM
                        // Bit 6
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 5
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 4
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 3
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 2
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 1
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 0
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TDI_ASM
                        BTFSS CARRY_BIT_ASM
                        BCF TDI_ASM
                        BSF TCK_ASM
                        BCF TCK_ASM

                        MOVFF TABLAT, TBLPTRL               // Get the TDO byte that was received and use it to index into the bit-order table.
                        TBLRD                               // TABLAT now contains the TDO byte in the proper bit-order.
                        MOVFF TABLAT, POSTINC1              // Store the TDO byte into the buffer and inc. the pointer.
                        DECFSZ buffer_cntr, 1, ACCESS       // Decrement the buffer counter and continue
                        BRA PRI_TDI_TDO_LOOP_0              //   processing TDI bytes until it is 0.
                        _endasm
                        #endif
                    }
                    else // cmd == TDO_CMD
                    {
                        TBLPTR = (UINT24)reverse_bits;  // Setup the pointer to the bit-order table.
                        FSR0   = (WORD)tdo;
                        #if USE_MSSP
                        _asm
                        MOVLW   0                           // Load the SPI transmitter with 0's
                        MOVWF SSPBUF, ACCESS                //   so TDI is cleared while TDO is collected.
                        NOP                                 // The NOPs are used to insert delay while the SSPBUF is tx/rx'ed.
                        NOP
                        NOP
                        NOP
                        NOP
                        NOP
PRI_TDO_LOOP_0:
                        NOP
                        NOP
                        DCFSNZ buffer_cntr, 1, ACCESS
                        BRA PRI_TDO_LOOP_1
                        MOVFF SSPBUF, TBLPTRL               // Get the TDO byte that was received and use it to index into the bit-order table.
                        MOVWF SSPBUF, ACCESS
                        TBLRD                               // TABLAT now contains the TDO byte in the proper bit-order.
                        MOVFF TABLAT, POSTINC0              // Store the TDO byte into the buffer and inc. the pointer.
                        BRA PRI_TDO_LOOP_0
PRI_TDO_LOOP_1:
                        MOVFF SSPBUF, TBLPTRL               // Get the TDO byte that was received and use it to index into the bit-order table.
                        TBLRD                               // TABLAT now contains the TDO byte in the proper bit-order.
                        MOVFF TABLAT, POSTINC0              // Store the TDO byte into the buffer and inc. the pointer.
                        _endasm
                        #else
                        _asm
PRI_TDO_LOOP_0:
                        // Bit 7 of a byte of TDI/TDO bits.
                        BCF CARRY_BIT_ASM                   // Set carry to value on TDO pin of JTAG device.
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS              // Rotate TDO value into TABLAT register.
                        BSF TCK_ASM                     // Toggle TCK pin of JTAG device.
                        BCF TCK_ASM
                        // Bit 6
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 5
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 4
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 3
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 2
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 1
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TCK_ASM
                        BCF TCK_ASM
                        // Bit 0
                        BCF CARRY_BIT_ASM
                        BTFSC TDO_ASM
                        BSF CARRY_BIT_ASM
                        RLCF TABLAT, 1, ACCESS
                        BSF TCK_ASM
                        BCF TCK_ASM

                        MOVFF TABLAT, TBLPTRL               // Get the TDO byte that was received and use it to index into the bit-order table.
                        TBLRD                               // TABLAT now contains the TDO byte in the proper bit-order.
                        MOVFF TABLAT, POSTINC0              // Store the TDO byte into the buffer and inc. the pointer.
                        DECFSZ buffer_cntr, 1, ACCESS       // Decrement the buffer counter and continue
                        BRA PRI_TDO_LOOP_0                  //   processing TDI bytes until it is 0.
                        _endasm
                        #endif
                    }  // All the TDI bytes in the current packet have been processed.

                    FSR1 = save_FSR1;
                    FSR0 = save_FSR0;

                    // Once all the TDI bits from a complete packet are sent to the JTAG port,
                    // send all the recorded TDO bits back in a complete packet.
                    if ( ( cmd == TDI_TDO_CMD ) || ( cmd == TDO_CMD ) )
                    {
                        InHandle[InIndex] = USBGenWrite( USBGEN_EP_NUM, (BYTE *)InPacket, OutPacketLength );
                        InIndex ^= 1;
                        while ( USBHandleBusy( InHandle[InIndex] ) )
                            ;                             // Wait until USB transmitter is not busy.
                        InPacket = &InBuffer[InIndex];
                        tdo      = (BYTE *)InPacket; // TDO data will be written here.
                    }
    
                    if ( ( cmd == TDI_TDO_CMD ) || ( cmd == TDI_CMD ) )
                    {
                        // Wait until a completely filled packet of TDI bits arrives.
                        // This command packet has been handled, so get another.
                        OutHandle[OutIndex] = USBGenRead( USBGEN_EP_NUM, (BYTE *)&OutBuffer[OutIndex], USBGEN_EP_SIZE );
                        OutIndex ^= 1; // Point to next ping-pong buffer.
    
                        // Wait until the next packet of TMS & TDI bits arrives.
                        while ( USBHandleBusy( OutHandle[OutIndex] ) )
                            ;
                        OutPacketLength = USBHandleGetLength( OutHandle[OutIndex] );    // Store length of received packet.
                        OutPacket       = &OutBuffer[OutIndex]; // Store pointer to just-received packet.
                        tdi             = (BYTE *)OutPacket; // Init pointer to the just-received TDI data.
                    }

                }  // First M-1 TDI packets have been processed.

                // Process all except the last byte in the final packet of TDI bits.
                for ( buffer_cntr = num_bytes; buffer_cntr > 1U; buffer_cntr-- )
                {
                    // Read a byte from the packet, re-order the bits (if necessary), and transmit it
                    // through the SSP starting at the most-significant bit.
                    #if USE_MSSP
                    if ( ( cmd == TDI_TDO_CMD ) || ( cmd == TDI_CMD ) )
                        SSPBUF = reverse_bits[*tdi++];
                    else
                        SSPBUF = 0;
                    _asm
BF_TEST_LOOP_1:
                    MOVF SSPSTAT, TO_WREG, ACCESS           // Wait for the TDI byte to be transmitted.
                    BTFSS MSSP_BF_ASM                       // (Can't check SSPSTAT directly or else the transfer doesn't work.)
                    BRA BF_TEST_LOOP_1
                    _endasm
                    *tdo++ = reverse_bits[SSPBUF];      // Always read the SSPBUFF to clear the buffer-full flag, even if TDO bits are not needed.
                    #else
                    if ( ( cmd == TDI_TDO_CMD ) || ( cmd == TDI_CMD ) )
                        tdi_byte = reverse_bits[*tdi++];
                    else
                        tdi_byte = 0;
                    tdo_byte = 0;
                    for ( bit_cntr = 8, bit_mask = 0x80; bit_cntr > 0U; bit_cntr--, bit_mask >>= 1 )
                    {
                        if ( TDO )
                            tdo_byte |= bit_mask;
                        TDI = tdi_byte & bit_mask ? 1 : 0;
                        TCK = 1;
                        TCK = 0;
                    }     // The final bits in the last TDI byte have been processed.
                    if ( ( cmd == TDI_TDO_CMD ) || ( cmd == TDO_CMD ) )
                        *tdo++ = reverse_bits[tdo_byte];
                    #endif
                }

                // Send the last few bits of the last packet of TDI bits.
                #if USE_MSSP
                TCK               = 0;
                SSPCON1bits.SSPEN = 0;      // Turn off the MSSP.  The remaining bits are transmitted manually.
                #endif

                // Compute the number of TDI bits in the final byte of the final packet.
                // (This computation only works because num_clks != 0.)
                bit_cntr          = num_clks & 0x7;
                if ( bit_cntr == 0U )
                    bit_cntr = 8U;
                if ( ( cmd == TDI_TDO_CMD ) || ( cmd == TDI_CMD ) )
                    tdi_byte = reverse_bits[*tdi];
                else
                    tdi_byte = 0;
                tdo_byte          = 0;
                for ( bit_mask = 0x80; bit_cntr > 0U; bit_cntr--, bit_mask >>= 1 )
                {
                    if ( bit_cntr == 1U )
                        TMS = 1;    // Raise TMS to exit Shift-IR or Shift-DR state on the final TDI bit.
                    if ( TDO )
                        tdo_byte |= bit_mask;
                    TDI = tdi_byte & bit_mask ? 1 : 0;
                    TCK = 1;
                    TCK = 0;
                } // The final bits in the last TDI byte have been processed.

                if ( ( cmd == TDI_TDO_CMD ) || ( cmd == TDO_CMD ) )
                {
                    *tdo = reverse_bits[tdo_byte]; // Store last few TDO bits into the outgoing packet.
                    num_return_bytes = num_bytes;
                }

                // Blink the LED a few times after a long command completes.
                if ( blink_counter < MAX_BYTE_VAL - NUM_ACTIVITY_BLINKS )
                    blink_counter = 0;  // Already done enough LED blinks.
                else
                    blink_counter -= ( MAX_BYTE_VAL - NUM_ACTIVITY_BLINKS );    // Do at least the minimum number of blinks.
                break;

            case JTAG_CMD:       // Output TMS & TDI values; get TDO value

                // The first packet received contains the JTAG_CMD command and the number
                // of TDI bits that will follow in succeeding packets.
                num_clks         = OutPacket->num_clks;

                // Exit if no TDI bits will follow (this is probably an error...).
                if ( num_clks == 0U )
                    break; 

                // Get flags from the first packet that indicate how TMS and TDO bits are handled.
                flags = OutPacket->flags;

                // Initialize TCK, TMS and TDI levels.
                TCK        = 0;                     // Initialize TCK (should have been low already).
                if ( !( flags & PUT_TMS_MASK ) )
                {
                    TMS = ( flags & TMS_VAL_MASK ) ? 1 : 0; // No TMS bits in packets, so set TMS to the static value indicated in the flag bit.
                }
                if ( !( flags & PUT_TDI_MASK ) )
                {
                    TDI = ( flags & TDI_VAL_MASK ) ? 1 : 0; // No TDI bits in packets, so set TDI to the static value indicated in the flag bit.
                }
                // Keep only the flags we need at this point. (Reduces code size.)
                flags &= ( PUT_TDI_MASK | PUT_TMS_MASK | GET_TDO_MASK );

                // Total number of header+TMS+TDI bytes in all the packets for this command.
                num_bytes  = (DWORD)( ( num_clks + 7 ) / 8 );
                if ( (flags & PUT_TDI_MASK) && (flags & PUT_TMS_MASK) )
                    num_bytes *= 2; // Twice the number of bytes if TMS and TDI bits are both being sent.
                OutPacketLength -= JTAG_CMD_HDR_LEN;    // Subtract command header size to get number of data bytes in this packet.
                tms_tdi    = (BYTE *)OutPacket + JTAG_CMD_HDR_LEN; // Pointer to TMS+TDI bits that follow command bytes in first packet.
                tdo        = (BYTE *)InPacket;             // Pointer to buffer for storing TDO bits.

                switch ( flags )
                {
                    case GET_TDO_MASK:
                        // If we are only getting TDO bits from the FPGA, then the outbound packet from the PC 
                        // only contains the command header (no TMS or TDI bits). But we still set the length as 
                        // if there were so the following loop will behave correctly.
                        OutPacketLength = USBGEN_EP_SIZE;
                        // *** Fall-through to the next case. Do not break! ***
                    case PUT_TDI_MASK:
                        #if USE_MSSP
                        // Use the MSSP for speed if only sending TDI bits or only receiving TDO bits.
                        TCK_TRIS          = INPUT_PIN; // Disable the TCK output so that the clock won't glitch when the MSSP is enabled.
                        SSPCON1bits.SSPEN = 1; // Enable the MSSP.
                        TCK_TRIS          = OUTPUT_PIN; // Enable the TCK output after the MSSP glitch is over.
                        #endif
                        break;
                    default:
                        // The rest of the modes use bit-banging to send the JTAG bits.
                        break;
                }

                // Process the first M-1 of M packets that are completely filled with TMS+TDI bits.
                // (We fake the out-bound packet length for the case where we are just collecting TDO bits without TMS/TDI.)
                while ( num_bytes > OutPacketLength )
                {
                    // Reduce the number of bytes left to process NOW, before OutPacketLength changes at the loop bottom!
                    num_bytes -= OutPacketLength;

                    if ( blink_counter == 0U )
                    {
                        blink_counter = NUM_ACTIVITY_BLINKS;   // Keep LED blinking during this command to indicate activity.
                    }
                    // Process the TMS & TDI bytes in the packet and collect the TDO bits.
                    switch ( flags )
                    {
                        case GET_TDO_MASK:  // Just gather TDO bits
                            #if USE_MSSP
                            {
                                buffer_cntr       = OutPacketLength;
                                save_FSR0         = FSR0;
                                TBLPTR            = (UINT24)reverse_bits; // Setup the pointer to the bit-order table.
                                FSR0              = (WORD)tdo;
                                _asm
                                MOVLW   0                       // Load the SPI transmitter with 0's
                                MOVWF SSPBUF, ACCESS            //   so TDI is cleared while TDO is collected.
                                NOP                             // The NOPs are used to insert delay while the SSPBUF is tx/rx'ed.
                                NOP
                                NOP
                                NOP
                                NOP
                                NOP
PRI_TAP_LOOP_2:
                                NOP
                                NOP
                                DCFSNZ buffer_cntr, 1, ACCESS
                                BRA PRI_TAP_LOOP_3
                                MOVFF SSPBUF, TBLPTRL           // Get the TDO byte that was received and use it to index into the bit-order table.
                                MOVWF SSPBUF, ACCESS
                                TBLRD                           // TABLAT now contains the TDO byte in the proper bit-order.
                                MOVFF TABLAT, POSTINC0          // Store the TDO byte into the buffer and inc. the pointer.
                                BRA PRI_TAP_LOOP_2
PRI_TAP_LOOP_3:
                                MOVFF SSPBUF, TBLPTRL           // Get the TDO byte that was received and use it to index into the bit-order table.
                                TBLRD                           // TABLAT now contains the TDO byte in the proper bit-order.
                                MOVFF TABLAT, POSTINC0          // Store the TDO byte into the buffer and inc. the pointer.
                                _endasm                                
                                FSR0              = save_FSR0;
                                tdo += OutPacketLength; // Update pointer because it's used for packet length later.
                                TCK = 0;
                            }
                            #else
                            {
                                for ( buffer_cntr = OutPacketLength; buffer_cntr != 0U; buffer_cntr-- )
                                {
                                    tdo_byte = 0; // Clear byte for receiving TDO bits.
                                    for ( bit_cntr = 8, bit_mask = 0x01; bit_cntr != 0U; bit_cntr--, bit_mask <<= 1 )
                                    {
                                        if ( TDO )
                                            tdo_byte |= bit_mask;
                                        TCK = 1;
                                        TCK = 0;
                                    }
                                    *tdo++ = tdo_byte; // Store received TDO bits into the outgoing packet.
                                }
                            }
                            #endif
                            break;

                        case PUT_TDI_MASK:  // Just output the TDI bits to the FPGA.
                            #if USE_MSSP
                            {
                                buffer_cntr       = OutPacketLength;
                                save_FSR0         = FSR0;
                                TBLPTR            = (UINT24)reverse_bits; // Setup the pointer to the bit-order table.
                                FSR0              = (WORD)tms_tdi;
                                _asm
                                MOVFF POSTINC0, TBLPTRL         // Get the current TDI byte and use it to index into the bit-order table.
                                TBLRD                           // TABLAT now contains the TDI byte in the proper bit-order.
                                MOVFF TABLAT, SSPBUF            // Load TDI byte into SPI transmitter.
                                NOP
                                NOP
PRI_TAP_LOOP_0:
                                DCFSNZ buffer_cntr, 1, ACCESS   // Decrement the buffer counter and continue if not zero
                                BRA PRI_TAP_LOOP_1
                                MOVFF POSTINC0, TBLPTRL         // Get the current TDI byte and use it to index into the bit-order table.
                                TBLRD                           // TABLAT now contains the TDI byte in the proper bit-order.
                                MOVFF SSPBUF, TBLPTRL           // Get the TDO byte just to clear the buffer-full flag (don't use TDO).
                                MOVFF TABLAT, SSPBUF            // Load TDI byte into SPI transmitter ASAP.
                                BRA PRI_TAP_LOOP_0
PRI_TAP_LOOP_1:
                                NOP
                                NOP
                                NOP
                                MOVFF SSPBUF, TBLPTRL           // Get the TDO byte just to clear the buffer-full flag (don't use TDO).
                                _endasm
                                TCK = 0;
                                FSR0              = save_FSR0;
                            }
                            #else
                            {
                                for ( buffer_cntr = OutPacketLength; buffer_cntr != 0U; buffer_cntr-- )
                                {
                                    tdi_byte = *tms_tdi++;
                                    for ( bit_cntr = 8, bit_mask = 0x01; bit_cntr != 0U; bit_cntr--, bit_mask <<= 1 )
                                    {
                                        TDI = tdi_byte & bit_mask ? 1 : 0;
                                        TCK = 1;
                                        TCK = 0;
                                    }
                                }
                            }
                            #endif
                            break;

                        case 0:
                            // No TDI, TMS or TDO bits to handle so do nothing. (This must be an error!)
                            break;

                        default:
                            // Handle combination of TDI, TMS and/or TDO bits. This can be done slowly
                            // so we don't worry about all the conditionals in the loop.
                            buffer_cntr = OutPacketLength;
                            if( (flags & PUT_TDI_MASK) && (flags & PUT_TMS_MASK) )
                                buffer_cntr /= 2;
                            for ( ; buffer_cntr != 0U; buffer_cntr-- )
                            {
                                if( flags & PUT_TMS_MASK )
                                    tms_byte = *tms_tdi++;
                                if( flags & PUT_TDI_MASK )
                                    tdi_byte = *tms_tdi++;
                                tdo_byte = 0; // Clear byte for receiving TDO bits.
                                for ( bit_cntr = 8, bit_mask = 0x01; bit_cntr != 0U; bit_cntr--, bit_mask <<= 1 )
                                {
                                    if ( TDO )
                                        tdo_byte |= bit_mask;
                                    if( flags & PUT_TMS_MASK )
                                        TMS = tms_byte & bit_mask ? 1 : 0;
                                    if( flags & PUT_TDI_MASK )
                                        TDI = tdi_byte & bit_mask ? 1 : 0;
                                    TCK = 1;
                                    TCK = 0;
                                }
                                if( flags & GET_TDO_MASK )
                                    *tdo++ = tdo_byte; // Store received TDO bits into the outgoing packet.
                            }
                            break;
                    } /* switch */

                    // Send all the recorded TDO bits back in a complete packet.
                    if ( flags & GET_TDO_MASK )
                    {
                        InHandle[InIndex] = USBGenWrite( USBGEN_EP_NUM, (BYTE *)InPacket, tdo - (BYTE*)InPacket );
                        // TDO bits have now been queued for transmission, so move pointer to next ping-pong buffer.
                        InIndex ^= 1;
                        // Wait until previous packet of TDO bits has been transmitted so we don't overwrite it.
                        while ( USBHandleBusy( InHandle[InIndex] ) )
                            ;                             // Wait until USB transmitter is not busy.
                        InPacket = &InBuffer[InIndex];
                        if( flags == GET_TDO_MASK )
                        {
                            // If we are only getting TDO bits from the FPGA and sending them over the USB link,
                            // then there are no outbound packets coming from the PC. But we still set the length as 
                            // if there were so this loop will still keep running until all of the TDO bits have
                            // been sent to the PC (except for the final packet).
                            OutPacketLength = USBGEN_EP_SIZE;
                        }
                    }

                    if ( flags & ( PUT_TDI_MASK | PUT_TMS_MASK ) )
                    {
                        // This command packet has been handled, so get another.
                        OutHandle[OutIndex] = USBGenRead( USBGEN_EP_NUM, (BYTE *)&OutBuffer[OutIndex], USBGEN_EP_SIZE );
                        OutIndex ^= 1; // Point to next ping-pong buffer.

                        // Wait until the next packet of TMS and/or TDI bits arrives.
                        while ( USBHandleBusy( OutHandle[OutIndex] ) )
                            ;
                        OutPacket       = &OutBuffer[OutIndex]; // Store pointer to just-received packet.
                        OutPacketLength = USBHandleGetLength( OutHandle[OutIndex] );    // Store length of received packet.
                    }

                    tms_tdi  = (BYTE *)OutPacket;
                    tdo      = (BYTE *)InPacket;
                }  // Process all but the final packet of TMS/TDI/TDO bits.

                #if USE_MSSP
                TCK = 0;
                SSPCON1bits.SSPEN = 0;  // Turn off the MSSP.  The remaining bits are transmitted bit-bang style.
                #endif

                // Process the final packet.
                buffer_cntr = num_bytes;
                if( (flags & PUT_TDI_MASK) && (flags & PUT_TMS_MASK) )
                    buffer_cntr /= 2;
                // This sets the number of bytes that will be returned from this final packet to the PC.
                if( flags & GET_TDO_MASK )
                    num_return_bytes = buffer_cntr;
                // This is the last packet, so we can afford to be slow with conditionals in the loop.
                for ( ; buffer_cntr != 0; buffer_cntr-- )
                {
                    if( flags & PUT_TMS_MASK )
                        tms_byte = *tms_tdi++;
                    if( flags & PUT_TDI_MASK )
                        tdi_byte = *tms_tdi++;
                    tdo_byte = 0; // Clear byte for receiving TDO bits.

                    bit_cntr = 8; // All except last byte have 8 bits to process.
                    if( buffer_cntr == 1 )
                    {
                        // Send the last few bits of the last byte of TDI bits.
                        // Compute the number of bits in the final byte of the final packet.
                        // (This computation only works because num_clks != 0.)
                        bit_cntr = num_clks & 0x7;
                        if ( bit_cntr == 0U )
                        {
                            bit_cntr = 8U;
                        }
                    }
                    // bit_cntr was set up above.
                    for ( bit_mask = 0x01; bit_cntr != 0U; bit_cntr--, bit_mask <<= 1 )
                    {
                        if ( TDO )
                            tdo_byte |= bit_mask;
                        if( flags & PUT_TMS_MASK )
                            TMS = tms_byte & bit_mask ? 1 : 0;
                        if( flags & PUT_TDI_MASK )
                            TDI = tdi_byte & bit_mask ? 1 : 0;
                        TCK = 1;
                        TCK = 0;
                    }
                    if( flags & GET_TDO_MASK )
                        *tdo++ = tdo_byte; // Store received TDO bits into the outgoing packet.
                }
                break;

            case RUNTEST_CMD:
                if ( OutPacket->num_tck_pulses > DO_DELAY_THRESHOLD )
                {
                    // For RUNTEST with large number of TCK pulses, just use a timer.
                    runtest_timer = 1 + OutPacket->num_tck_pulses / DO_DELAY_THRESHOLD; // Set timer for needed time delay.
                    while ( runtest_timer )
                    {
                        ;   // Timer is decremented by the timer interrupt routine.
                    }
                }
                else
                    // For RUNTEST with a smaller number of TCK pulses, actually pulse the TCK pin.
                    for ( lcntr = OutPacket->num_tck_pulses; lcntr != 0UL; lcntr-- )
                    {
                        TCK ^= 1;
                        TCK ^= 1;
                    }

                memcpy( (void *)InPacket, (void *)OutPacket, 5 );
                num_return_bytes = 5; // return the entire command as an acknowledgement
                break;

            case PROG_CMD:
                PROGB            = OutPacket->prog;
                num_return_bytes = 0;           // Don't return any acknowledgement.
                break;

            case FLASH_ONOFF_CMD:
                if(OutPacket->flash_on)
                {
                    // The uC releases its hold on the flash chip-select so the FPGA can control it.
                    FLSHDSBL_TRIS = INPUT_PIN;
                }
                else
                {
                    // The uC grabs the flash chip-select and forces it high to disable the flash.
                    FLSHDSBL = 1;
                    FLSHDSBL_TRIS = OUTPUT_PIN;
                }
                num_return_bytes = 2;           // Return the entire command as an acknowledgement.
                break;

            case AIO0_ADC_CMD: //Perform an adc conversion and return the value
                InPacket->cmd = cmd;
                ADCON0bits.CHS = 0x6;              // select channel AN6
                ADCON0bits.GO = 1;              // Start AD conversion
                while(ADCON0bits.NOT_DONE);     // Wait for conversion
                InPacket->adc_high = ADRESH;
                InPacket->adc_low = ADRESL;
                num_return_bytes = 3;
                break;

            case AIO1_ADC_CMD: //Perform an adc conversion and return the value
                InPacket->cmd = cmd;
                ADCON0bits.CHS = 0xb;              // select channel AN11
                ADCON0bits.GO = 1;              // Start AD conversion
                while(ADCON0bits.NOT_DONE);     // Wait for conversion
                InPacket->adc_high = ADRESH;
                InPacket->adc_low = ADRESL;
                num_return_bytes = 3;
                break;

            case READ_EEDATA_CMD:
                InPacket->cmd = OutPacket->cmd;
                for(buffer_cntr=0; buffer_cntr < OutPacket->len; buffer_cntr++)
                {
                    InPacket->data[buffer_cntr] = ReadEeprom((BYTE)OutPacket->ADR.pAdr + buffer_cntr);
                }
                num_return_bytes = buffer_cntr + 5;
                break;

            case WRITE_EEDATA_CMD:
                InPacket->cmd = OutPacket->cmd;
                for(buffer_cntr=0; buffer_cntr < OutPacket->len; buffer_cntr++)
                {
                    WriteEeprom((BYTE)OutPacket->ADR.pAdr + buffer_cntr, OutPacket->data[buffer_cntr]);
                }
                ProcessEepromFlags();   // Update uC behavior based on any new EEPROM flag settings.
                num_return_bytes = 1;
                break;

            case RESET_CMD:
                // When resetting, make sure to drop the device off the bus
                // for a period of time. Helps when the device is suspended.
                UCONbits.USBEN = 0;
                lcntr = 0xFFFF;
                for(lcntr = 0xFFFF; lcntr; lcntr--)
                    ;
                Reset();
                break;

            default:
                num_return_bytes = 0;
                break;
        } /* switch */

        // This command packet has been handled, so get another.
        OutHandle[OutIndex] = USBGenRead( USBGEN_EP_NUM, (BYTE *)&OutBuffer[OutIndex], USBGEN_EP_SIZE );
        OutIndex ^= 1; // Point to next ping-pong buffer.

        // Packets of data are returned to the PC here.
        // The counter indicates the number of data bytes in the outgoing packet.
        if ( num_return_bytes != 0U )
        {
            InHandle[InIndex] = USBGenWrite( USBGEN_EP_NUM, (BYTE *)InPacket, num_return_bytes ); // Now send the packet.
            InIndex ^= 1;
            while ( USBHandleBusy( InHandle[InIndex] ) )
            {
                ;                           // Wait until transmitter is not busy.
            }
            InPacket = &InBuffer[InIndex];
        }
    }
} /* ServiceRequests */
