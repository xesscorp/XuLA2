# Copyright (C) 2015 by XESS Corporation.
# 
# This library is free software: you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
#  
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#  
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see <http://www.gnu.org/licenses/>.

import sys
import time
from xstools.xsdutio import *  # Import the funcs/objects for the PC <=> FPGA link.
from random import *  # Import some random number generator routines.

BLOCK_SIZE = 512

print '''
##################################################################
# Test the SD card on the XuLA-2 using the PC to transfer data
# to/from the SD card controller with handshake sync.
##################################################################
'''


def reset_sdcard():
    sdcard.write(0, 0, 0, 0, 0, 0, 1)  # Raise reset.
    sdcard.write(0, 0, 0, 0, 0, 0, 0)  # Lower reset.


def sdcard_is_busy():
    '''Return True if SD card is busy doing something.'''

    # (data_out, busy, hand_shake, error) = sdcard.read()
    # if hand_shake.unsigned != 0:
    # print "Handshake still asserted!"
    # if error.unsigned != 0:
    # print "Error!"
    (data_out, busy, hand_shake, error) = sdcard.read()
    return busy.unsigned == 1


def handshake_is_active():
    '''Return true if SD card has raised its handshake signal.'''

    (data_out, busy, hand_shake, error) = sdcard.read()
    return hand_shake.unsigned == 1
    #return sdcard.read()[2].unsigned == 1


def init_sdcard():
    reset_sdcard()
    time.sleep(1)
    while sdcard_is_busy():
        reset_sdcard()
        time.sleep(1)
    return


def start_rw(address=0, rd=0, wr=0, ):
    '''Start a block read or write operation with the SD card.'''
    
    # Wait for current operation (if any) to complete.
    while sdcard_is_busy():
        pass
    sdcard.write(rd, wr, 0, address, 0, 0, 0)  # Raise read or write control.
    # Wait for R/W operation to start.
    while not sdcard_is_busy():
        pass
    sdcard.write(0, 0, 0, 0, 0, 0, 0)  # R/W started, so lower control.


def write_byte(byte):
    # Wait for handshake.
    while not handshake_is_active():
        pass
    sdcard.write(0, 0, 0, 0, byte, 1, 0)  # Send byte and acknowledge handshake.
    # Wait for handshake to be released.
    while handshake_is_active():
        pass
    sdcard.write(0, 0, 0, 0, byte, 0, 0)  # Remove our acknowledgement.


def write_block(address, data):
    start_rw(address, wr=1)
    # Write the bytes in the data list to the SD card.
    for byte in data:
        write_byte(byte)
    # Pad the data (if necessary) to fill-out the block.
    for byte in range(len(data), BLOCK_SIZE):
        write_byte(0xff)
    # Wait for the block-write to complete.
    while sdcard_is_busy():
        pass


def read_byte():
    # Wait for handshake.
    while not handshake_is_active():
        pass
    # Read byte and acknowledge handshake.
    byte = sdcard.execute(0, 0, 0, 0, 0, 1, 0)[0].unsigned
    # Wait for handshake to be released.
    while handshake_is_active():
        pass
    sdcard.write(0, 0, 0, 0, 0, 0, 0)  # Remove our acknowledgement.
    return byte


def read_block(address):
    start_rw(address, rd=1)
    data = []
    for i in range(BLOCK_SIZE):
        data.append(read_byte())
    while sdcard_is_busy():
        pass
    return data


USB_ID = 0  # USB port index for the XuLA2 board connected to the host PC.
SDCARD_ID = 0xff  # This is the identifier for the SD card interface in the FPGA.

# Create intfc obj.
# Sdcard controller outputs = [data(8), busy(1), handshake(1), error(16)]
# Sdcard controller inputs = [rd(1), wr(1), continue(1), address(32), data(8), handshake_ack(1), reset(1)]
sdcard = XsDutIo(xsusb_id=USB_ID,
                 module_id=SDCARD_ID,
                 dut_output_widths=[8, 1, 1, 16],
                 dut_input_widths=[1, 1, 1, 32, 8, 1, 1])

print 'Initializing SD card ...',
init_sdcard()
print 'done'

# Write a block of random bytes to the SD card.
print 'Writing data ...',
wr_data = [randint(0, 0xff) for b in range(BLOCK_SIZE)]
block_address = 0
write_block(block_address, wr_data)
print 'done'

# Read the block of data from the SD card.
print 'Reading data ...',
rd_data = read_block(block_address)
print 'done'

# Print the data written and read as pairs of bytes (which should match).
rd_wr_data = zip(rd_data, wr_data)
print rd_wr_data

# Compare the written data to the data read back and see if they match.
num_errors = 0
for (rd, wr) in rd_wr_data:
    if rd != wr:
        num_errors += 1
        print 'Data error: %02x != %02x' % (rd, wr)
print "\n%d errors detected!" % num_errors
