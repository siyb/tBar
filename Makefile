prefix = $(DESTDIR)
version=1.2rc1
deploy=tbar_$(version)
kit=tbar_$(version)_kit

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
	mkdir $(kit)
	starkit/mkstarkit.sh

	cp tbar.kit $(kit)/tbar
	cp README $(kit)
	cp LICENSE $(kit)
	cp starkit/Makefile $(kit)

	gzip -c tbar.1 >> $(kit)/tbar.1.gz
	cp -r config.tcl $(kit)
	tar -cf $(kit).tar $(kit)
	gzip --best $(kit).tar
	
deploy:
	git archive --prefix=$(deploy)/ --format=tar $(version) | gzip --best > $(deploy).tar.gz

uninstall:
	rm -rf $(DESTDIR)/etc/tbar/ $(DESTDIR)/usr/bin/tbar $(DESTDIR)/usr/lib/tbar/ $(DESTDIR)/usr/share/tbar/ $(DESTDIR)/usr/share/man/man1/tbar.1.gz

clean:
	rm -rf tbar.1.gz tbar.kit lib/pkgIndex.tcl $(kit) $(kit).tar.gz $(deploy).tar.gz
