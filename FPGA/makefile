projects := AdcSampler blinker counter fast_blinker \
			hcsr04_test hostio_test HostIoCommTest HostIoToI2cTest \
			rand_test RGBLed SdcardCtrlTest SdcardSfwTest \
			test_board_jtag ramintfc_jtag fintf_jtag \
			test_board_jtag_old ramintfc_jtag_old fintf_jtag_old

xstools_projects := fintf_jtag ramintfc_jtag test_board_jtag

old_xstools_projects := fintf_jtag_old ramintfc_jtag_old test_board_jtag_old

all         : $(projects:=.all)
xstools     : $(xstools_projects:=.all)
xstools-dist: DIST_DIR := ../../xstools/xstools/xula2
xstools-dist: xstools $(xstools_projects:=.dist)
old_xstools : $(old_xstools_projects:=.all)
clean       : $(projects:=.clean)

%.all:
	$(MAKE) -C $(subst .all,,$@) all
    
%.dist:
	cp $(subst .dist,,$@)/*.bit $(DIST_DIR) 

%.clean:
	$(MAKE) -C $(subst .clean,,$@) clean
