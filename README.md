# Installation

## Install
- Install Tcl/Tk 8.5 or higher, libtk-img, tcllib, unix_sockets and libsqlite3-tcl (read 2.2 for more information!)
- Run: make install (or: make DESTFILE=mydir install)
- Modify /etc/tbar/config.tcl to fit your needs or create ~/.tbar/ and copy /etc/tbar/config.tcl there, to have a user specific config
- Run: tbar

## Uninstall
- To uninstall run: make uninstall, make sure to specify DESTFILE if you have done so in the install

# User specific libraries, widgets and snippets

## Libraries
From version 1.2 onwards, users are able to integrate custom libraries and widgets using folders located in their userland.
Place custom libraries (along with a pkgIndex.tcl file) in ~/.tbar/lib, in order to make the libraries accessible to tbar. You will
have to create the folder manually, if it exists, it will be automatically appended to tcl's auto_path of the interpreter tbar is
running in.

## Widgets
If you wish to install custom widgets on a per user basis (for your user only), create ~/.tbar/widget and copy the widget wrapper
files to be loaded there. The widget wrapper file must be named after the widget, e.g. widgetname foobar would imply foobar.tcl	as 
widget wrapper file name.

## Snippets
From version 1.4 onwards, users can create small snippets and place them in ~/.tbar/snips. Snippets are meant to decrease the config
file size. They should be used when a widget offers the execution of TCL code. Please check out the example snippet, located in
/usr/share/doc/tbar/examples/snippet.tcl for more information.

# Dependencies	
From version 1.4 onwards, tBar manages dependencies automatically. Packages are loaded on demand and warning messages are logged
if a package is not available. tBar knows about widget dependency on the widget and parameter level. It will remove parameters
from widgets, which require packages, that are not installed, thus preventing widget loading errors.

# Widget
This section contains notes on some widgets that are a bit more complicated to run.

## i3_workspace
This widget requires the domain socket library from http://sourceforge.net/projects/tcl-unixsockets/.

## wicd
This experimental widget requires the dbus library from http://chiselapp.com/user/schelte/repository/dbus/wiki?name=Manual+page.

# Notes

## Makefile
The Makefile supports the following parameters:

EXPERIMENTAL - Effects the deploy option only. Will create a version containing the git hash of the commit, which was used
			to create the build.

## Versioning
Starting from 1.4.0, tBar uses semver.

# License
tBar is licensed under the terms of the Apache 2.0 License. Please refer to the LICENSE file for more information.

## Acknowledgement
- Thanks to Jaafar Mejri aka Jaf (http://wiki.tcl.tk/13498) for his contribution to the program (calendar widget: http://wiki.tcl.tk/13497)
- Thanks to David Easton (http://wiki.tcl.tk/10511) for his contribution to the program (image resizer: http://wiki.tcl.tk/11196)
- Thanks to Colin McCormack (http://wiki.tcl.tk/3650) for his contribution to the program (ical library: http://wiki.tcl.tk/_repo/tcal/)
- Thanks to Cybex (http://cybex.b0rk.de/files/tcl/) for the hexdump script

# Contact
Website: http://siyb.mount.at/tbar
Email: siyb@geekosphere.org
IRC: #woot @ irc.teranetworks.de:6697 (SSL only!)
