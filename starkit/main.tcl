package require starkit
if {[starkit::startup] eq "sourced"} { return }
cd $::starkit::topdir
lappend auto_path \
[file join $::starkit::topdir sqlite] [file join $::starkit::topdir tcllib] \
[file join $::starkit::topdir libtkimg] [file join $::starkit::topdir unixsockets]
source tbar.tcl