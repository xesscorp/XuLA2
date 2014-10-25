from xstools.xscomm import XsComm

# logging.root.setLevel(logging.DEBUG)

print '\n', '='*70, "\nThe FPGA should be freshly loaded before running this test script!\n", '='*70, '\n'

USB_ID = 0  # This is the USB index for the XuLA board connected to the host PC.
comm = XsComm(xsusb_id=USB_ID, module_id=255)
print comm._memio._get_mem_widths()

comm.get_levels()
recv = comm.receive(14)
print "Receive = ", [d.unsigned for d in recv]
comm.get_levels()
recv = comm.receive(drain=True)
print "Receive = ", [d.unsigned for d in recv]
comm.get_levels()
comm.send([15, 16, 17, 18, 19, 20, 21, 22, 23, 24])
comm.send([15, 16, 17, 18, 19, 20, 21, 22, 23, 24])
comm.get_levels()
recv = comm.receive(10)
print "Receive = ", [d.unsigned for d in recv]
comm.get_levels()
recv = comm.receive(10)
print "Receive = ", [d.unsigned for d in recv]
comm.get_levels()

print "\n\nRESET\n\n"
comm.reset()

comm.get_levels()
comm.send([1, 2, 3, 4, 5, 6, 7, 8])
comm.get_levels()
comm.send([9, 10, 11, 12, 13, 14, 15, 16])
comm.get_levels()
recv = comm.receive(15)
print "Receive = ", [d.unsigned for d in recv]
comm.get_levels()
comm.send([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
comm.get_levels()
recv = comm.receive()
comm.get_levels()
print "Receive = ", [d.unsigned for d in recv]
comm.get_levels()
