/*********************************************************************
 *
 *      Microchip USB C18 Firmware -  USB Bootloader Version 1.00
 *
 *********************************************************************
 * FileName:        boot.h
 * Dependencies:    See INCLUDES section below
 * Processor:       PIC18
 * Compiler:        C18 2.30.01+
 * Company:         Microchip Technology, Inc.
 *
 * Software License Agreement
 *
 * The software supplied herewith by Microchip Technology Incorporated
 * (the “Company”) for its PICmicro® Microcontroller is intended and
 * supplied to you, the Company’s customer, for use solely and
 * exclusively on Microchip PICmicro Microcontroller products. The
 * software is owned by the Company and/or its supplier, and is
 * protected under applicable copyright laws. All rights are reserved.
 * Any use in violation of the foregoing restrictions may subject the
 * user to criminal sanctions under applicable laws, as well as to
 * civil liability for the breach of the terms and conditions of this
 * license.
 *
 * THIS SOFTWARE IS PROVIDED IN AN “AS IS” CONDITION. NO WARRANTIES,
 * WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED
 * TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE COMPANY SHALL NOT,
 * IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL OR
 * CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
 *
 * Author               Date        Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Rawin Rojvanit       11/19/04    Original.
 ********************************************************************/
#ifndef BOOT_H
#define BOOT_H

/** I N C L U D E S **********************************************************/
#include "system\typedefs.h"
#include "usbcmd.h"

/** D E F I N I T I O N S ****************************************************/
/****** Compiler Specific Definitions *******************************/

#if defined(HI_TECH_C)
    #define HITECH_C18
#else
    #define MCHP_C18
#endif

#if defined(MCHP_C18) && defined(HITECH_C18)
#error "Invalid Compiler selection."
#endif

#if !defined(MCHP_C18) && !defined(HITECH_C18)
#error "Compiler not supported."
#endif

#if defined(MCHP_C18)
    #define EECON1_RD       EECON1bits.RD
    #define EECON1_WR       EECON1bits.WR
#endif

/****** Processor Specific Definitions ******************************/

#if defined(__18F2455) || defined(__18F2550) ||\
    defined(__18F4455)|| defined(__18F4550) ||\
    defined(__18F14K50)

   /****** Remapped Vectors ********************
    *   _____________________
    *   |       RESET       |   0x000000
    *   |      LOW_INT      |   0x000008
    *   |      HIGH_INT     |   0x000018
    *   |       TRAP        |   0x000028
    *   |     Bootloader    |   0x00002E
    *   .                   .
    *   .                   .
    *   |     USER_RESET    |   0x000800
    *   |    USER_LOW_INT   |   0x000808
    *   |    USER_HIGH_INT  |   0x000818
    *   |      USER_TRAP    |   0x000828
    *   |                   |
    *   |   Program Memory  |
    *   .                   .
    *   |___________________|   0x0005FFF / 0x0007FFF
    */
    #define RM_RESET_VECTOR             0x000800
    #define RM_HIGH_INTERRUPT_VECTOR    0x000808
    #define RM_LOW_INTERRUPT_VECTOR     0x000818
#else
    "Processor not supported."
#endif

/* Bootloader Version */
//#define MINOR_VERSION   0x00    //Bootloader Version 1.00
//#define MAJOR_VERSION   0x01

/* State Machine */
#define WAIT_FOR_CMD    0x00    //Wait for Command packet
#define SENDING_RESP    0x01    //Sending Response

/******************************************************************************
 * Macro:           (bit) mBootRxIsBusy(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        This macro is used to check if the bulk OUT endpoint is
 *                  busy (owned by SIE) or not.
 *                  Typical Usage: if(mBootRxIsBusy())
 *
 * Note:            None
 *****************************************************************************/
#define mBootRxIsBusy()             BOOT_BD_OUT.Stat.UOWN

/******************************************************************************
 * Macro:           (bit) mBootTxIsBusy(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        This macro is used to check if the bulk IN endpoint is
 *                  busy (owned by SIE) or not.
 *                  Typical Usage: if(mBootTxIsBusy())
 *
 * Note:            None
 *****************************************************************************/
#define mBootTxIsBusy()             BOOT_BD_IN.Stat.UOWN

/** S T R U C T U R E S ******************************************************/

/*********************************************************************
 * General Data Packet Structure:
 * ACCESS RAM: Buffer Starting Address is assigned by compiler.
 * __________________           DATA_PACKET.FIELD
 * |    COMMAND     |   0       [CMD]
 * |      LEN       |   1       [LEN]
 * |     ADDRL      |   2       [        ]  [ADR.LOW]
 * |     ADDRH      |   3       [ADR.pAdr]: [ADR.HIGH]
 * |     ADDRU      |   4       [        ]  [ADR.UPPER]
 * |                |   5       [DATA]
 * |                |
 * .      DATA      .
 * .                .
 * |                |   62
 * |________________|   63
 *
 ********************************************************************/

#define OVER_HEAD   5           //Overhead: <CMD_CODE><LEN><ADDR:3>
#define DATA_SIZE   (BOOT_EP_SIZE - OVER_HEAD)

typedef union _BOOT_DATA_PACKET
{
    byte _byte[BOOT_EP_SIZE];  //For Byte Access
    struct
    {
        USBCMD CMD;     // Command for requested action
        byte len;
        union
        {
            rom far char *pAdr;             //Address Pointer
            struct
            {
                byte low;                   //Little-indian order
                byte high;
                byte upper;
            };
        }ADR;
        byte data[DATA_SIZE];
    };
    struct
    {
        unsigned :8;
        byte led_num;
        byte led_status;
    };
} BOOT_DATA_PACKET;

/** E X T E R N S ************************************************************/

/** P U B L I C  P R O T O T Y P E S *****************************************/
void BootInitEP(void);
void BootService(void);

#endif //BOOT_H
