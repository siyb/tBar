prefix = $(DESTDIR)

#
# Settings
#

# tbar version
version=1.3
# kit name
deploykit=tbar_$(version)_kit
# tbar name
deploy=tbar_$(version)
# git head version of tbar
gitv=`git rev-parse HEAD`
# uncomment lines for experimental versions
deploy=tbar_$(version)_git_$(gitv)
deploykit=tbar_$(version)_kit_git_$(gitv)

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
	mkdir $(deploykit)
	starkit/mkstarkit.sh

	cp tbar.kit $(deploykit)/tbar
	cp README $(deploykit)
	cp LICENSE $(deploykit)
	cp starkit/Makefile $(deploykit)

	gzip -c tbar.1 >> $(deploykit)/tbar.1.gz
	cp -r config.tcl $(deploykit)
	tar -cf $(deploykit).tar $(deploykit)
	gzip --best $(deploykit).tar

deploy: clean
	git archive --format=tar --prefix=$(deploy)/ $(gitv) . | gzip --best > $(deploy).tar.gz

uninstall:
	rm -rf $(DESTDIR)/etc/tbar/ $(DESTDIR)/usr/bin/tbar $(DESTDIR)/usr/lib/tbar/ $(DESTDIR)/usr/share/tbar/ $(DESTDIR)/usr/share/man/man1/tbar.1.gz

clean:
	rm -rf tbar.1.gz tbar.kit lib/pkgIndex.tcl $(deploy).tar.gz $(deploykit) $(deploykit).tar.gz
