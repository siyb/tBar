prefix = $(DESTDIR)

install: clean
	mkdir -p $(DESTDIR)/etc/tbar/
	mkdir -p $(DESTDIR)/usr/share/tbar/
	mkdir -p $(DESTDIR)/usr/lib/tbar/
	mkdir -p $(DESTDIR)/usr/bin/
	mkdir -p $(DESTDIR)/usr/share/man/man1/		
	
	#echo "lappend auto_path [file normalize lib/]; pkg_mkIndex -verbose lib/ */**" | tclsh
	cp -r config.tcl $(DESTDIR)/etc/tbar/
	cp -r tbar.tcl $(DESTDIR)/usr/bin/tbar
	cp -r lib/* $(DESTDIR)/usr/lib/tbar/
	cp -r widget/* $(DESTDIR)/usr/share/tbar/
	
	gzip --best tbar.1
	zcat tbar.1.gz >> tbar.1
	cp tbar.1.gz $(DESTDIR)/usr/share/man/man1/	

starkit:
	./mkstarpack.sh	

uninstall:
	rm -rf $(DESTDIR)/etc/tbar/ $(DESTDIR)/usr/bin/tbar $(DESTDIR)/usr/lib/tbar/ $(DESTDIR)/usr/share/tbar/ $(DESTDIR)/usr/share/man/man1/tbar.1.gz

clean:
	rm -f tbar.1.gz
