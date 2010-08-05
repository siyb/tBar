prefix = $(DESTDIR)

install:
	mkdir -p $(DESTDIR)/etc/tbar/
	mkdir -p $(DESTDIR)/usr/share/man/man1/
	mkdir -p $(DESTDIR)/usr/bin/

	cp -r tbar $(DESTDIR)/usr/bin/tbar
	cp -r config.tcl $(DESTDIR)/etc/tbar/
	cp tbar.1.gz $(DESTDIR)/usr/share/man/man1/

uninstall:
	rm -rf $(DESTDIR)/etc/tbar/ $(DESTDIR)/usr/bin/tbar $(DESTDIR)/usr/share/man/man1/tbar.1.gz
