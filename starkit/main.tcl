package require starkit
if {[starkit::startup] eq "sourced"} { return }
cd $::starkit::topdir
source tbar.tcl
