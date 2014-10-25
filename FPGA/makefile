projects := AdcSampler blinker counter fast_blinker \
			hcsr04_test hostio_test HostIoCommTest HostIoToI2cTest \
			rand_test RGBLed SdcardCtrlTest SdcardSfwTest \
			test_board_jtag ramintfc_jtag fintf_jtag \
			test_board_jtag_old ramintfc_jtag_old fintf_jtag_old

xstools_projects := fintf_jtag ramintfc_jtag test_board_jtag

old_xstools_projects := fintf_jtag_old ramintfc_jtag_old test_board_jtag_old

all         : $(projects:=.all)
xstools     : $(xstools_projects:=.all)
old_xstools : $(old_xstools_projects:=.all)
clean       : $(projects:=.clean)

%.all:
	echo $@
	$(MAKE) -C $(subst .all,,$@) all

%.clean:
	echo $@
	$(MAKE) -C $(subst .clean,,$@) clean
