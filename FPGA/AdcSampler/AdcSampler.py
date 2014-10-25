import sys
from xstools.xsmemio import *
from xstools.xsdutio import *

USB_ID = 0
RAM_ID = 255
ADC_ID = 254

# Create an object for reading the samples stored in SDRAM.
ram = XsMemIo(xsusb_id=USB_ID, module_id=RAM_ID)
# Create an object for controlling and monitoring the ADC.
adc = XsDutIo(xsusb_id=USB_ID, module_id=ADC_ID, dut_output_widths=[1], dut_input_widths=[1,8])

adc.write(1,9) # Start sampling ADC. Increase successive ADC samples by 9.
# Wait until the ADC lowers it's busy status signal.
while adc.read().unsigned != 0:
    pass;
adc.write(0,9) # Lower the sampling enable signal.

# Read some samples from the SDRAM, starting at address 0.
data = ram.read(0, 0x1000)
# Display the first twenty samples.
for d in data[:20]:
    print "%d" % d.unsigned
