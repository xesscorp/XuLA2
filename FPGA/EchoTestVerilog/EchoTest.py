from xstools.xscomm import XsComm

# logging.root.setLevel(logging.DEBUG)

USB_ID = 0  # This is the USB index for the XuLA board connected to the host PC.
comm = XsComm(xsusb_id=USB_ID, module_id=255)
print comm._memio._get_mem_widths()

for c in range(0x41,0x5b):
    comm.send(c)
    echo_c = comm.receive().unsigned
    print chr(echo_c),
print
import sys
