prefix = $(DESTDIR)
deploy=tbar_1.2rc1_kit
all: install

essential: pkgindex
	mkdir -p $(DESTDIR)/etc/tbar/
	mkdir -p $(DESTDIR)/usr/share/man/man1/
	mkdir -p $(DESTDIR)/usr/bin/

	cp -r config.tcl $(DESTDIR)/etc/tbar/
	gzip -c tbar.1 >> tbar.1.gz
	cp tbar.1.gz $(DESTDIR)/usr/share/man/man1/

pkgindex:
	echo "pkg_mkIndex -verbose -direct lib/ */* */*/*" | tclsh

install: clean essential
	mkdir -p $(DESTDIR)/usr/share/tbar/
	mkdir -p $(DESTDIR)/usr/lib/tbar/

	cp -r tbar.tcl $(DESTDIR)/usr/bin/tbar
	cp -r lib/* $(DESTDIR)/usr/lib/tbar/
	cp -r widget/* $(DESTDIR)/usr/share/tbar/

starkit: clean pkgindex
	mkdir $(deploy)
	starkit/mkstarkit.sh

	cp tbar.kit $(deploy)/tbar
	cp README $(deploy)
	cp LICENSE $(deploy)
	cp starkit/Makefile $(deploy)

	gzip -c tbar.1 >> $(deploy)/tbar.1.gz
	cp -r config.tcl $(deploy)
	tar -cf $(deploy).tar $(deploy)
	gzip --best $(deploy).tar
	
uninstall:
	rm -rf $(DESTDIR)/etc/tbar/ $(DESTDIR)/usr/bin/tbar $(DESTDIR)/usr/lib/tbar/ $(DESTDIR)/usr/share/tbar/ $(DESTDIR)/usr/share/man/man1/tbar.1.gz

clean:
	rm -rf tbar.1.gz tbar.kit lib/pkgIndex.tcl $(deploy) $(deploy).tar.gz
