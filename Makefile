ifeq ($(DESTDIR),)
	DESTDIR = /
endif
prefix = $(DESTDIR)

install:
	mkdir -p $(DESTDIR)etc/tbar/
	mkdir -p $(DESTDIR)usr/share/tbar/
	mkdir -p $(DESTDIR)usr/lib/tbar/
	mkdir -p $(DESTDIR)usr/bin/
	
	cp -r config.tcl $(DESTDIR)etc/tbar/
	cp -r tbar.tcl $(DESTDIR)usr/bin/tbar
	cp -r lib/* $(DESTDIR)usr/lib/tbar/
	cp -r widget/* $(DESTDIR)usr/share/tbar/
	
uninstall:
	rm -rf $(DESTDIR)etc/tbar/ $(DESTDIR)usr/bin/tbar $(DESTDIR)usr/lib/tbar/ $(DESTDIR)usr/share/tbar/