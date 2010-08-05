prefix = $(DESTDIR)

essential:
	mkdir -p $(DESTDIR)/etc/tbar/
	mkdir -p $(DESTDIR)/usr/share/man/man1/
	mkdir -p $(DESTDIR)/usr/bin/

	cp -r config.tcl $(DESTDIR)/etc/tbar/
	gzip -c tbar.1 >> tbar.1.gz
	cp tbar.1.gz $(DESTDIR)/usr/share/man/man1/

	echo "pkg_mkIndex -verbose -direct lib/ */* */*/*" | tclsh

install: clean essential
	mkdir -p $(DESTDIR)/usr/share/tbar/
	mkdir -p $(DESTDIR)/usr/lib/tbar/

	cp -r tbar.tcl $(DESTDIR)/usr/bin/tbar
	cp -r lib/* $(DESTDIR)/usr/lib/tbar/
	cp -r widget/* $(DESTDIR)/usr/share/tbar/

starkit: clean essential
	./mkstarpack.sh	
	cp ./tbar.kit $(DESTDIR)/usr/bin/tbar

uninstall:
	rm -rf $(DESTDIR)/etc/tbar/ $(DESTDIR)/usr/bin/tbar $(DESTDIR)/usr/lib/tbar/ $(DESTDIR)/usr/share/tbar/ $(DESTDIR)/usr/share/man/man1/tbar.1.gz

clean:
	rm -f tbar.1.gz tbar.kit lib/pkgIndex.tcl
