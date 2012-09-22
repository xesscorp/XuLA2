objects := 50 200

all             : cfg
cfg             : $(objects:=.cfg)
config          : $(objects:=.config)
exo             : $(objects:=.exo)
timing          : $(objects:=.timing)
clean           : $(objects:=.clean)
distclean       : $(objects:=.distclean)
maintainer-clean: $(objects:=.maintainer-clean)
nice            : $(objects:=.nice) XULA_LIB.nice

$(objects:=.cfg):
	$(MAKE) -C $(subst .cfg,,$@) cfg

$(objects:=.config):
	$(MAKE) -C $(subst .config,,$@) config

$(objects:=.exo):
	$(MAKE) -C $(subst .exo,,$@) exo

$(objects:=.timing):
	$(MAKE) -C $(subst .timing,,$@) timing

$(objects:=.clean):
	$(MAKE) -C $(subst .clean,,$@) clean

$(objects:=.distclean):
	$(MAKE) -C $(subst .distclean,,$@) distclean

$(objects:=.maintainer-clean):
	$(MAKE) -C $(subst .maintainer-clean,,$@) maintainer-clean

$(objects:=.nice) XULA_LIB.nice:
	$(MAKE) -C $(subst .nice,,$@) nice

.PHONY: design_files
design_files:
	perl make_files.pl > files.txt
	tar -c -f tmp.tar -T files.txt
	erase files.txt
	-rmdir /s /q design_files
	-mkdir design_files
	tar -C design_files -x -f tmp.tar
	erase tmp.tar
	pod2text -l readme.pod > design_files\readme.txt
	pod2html readme.pod > design_files\readme.html 
	erase pod2htm*.tmp
	echo "*** Now run Winzip on the design_files directory ***"

