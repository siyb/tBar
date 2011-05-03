#!/usr/bin/env tclsh
if {$::tcl_version < 8.5} {
	puts "tBar requires TCL 8.5 or higher to function correctly, $::tcl_version installed, exiting."
	exit
} elseif {$::tcl_version < 8.6 && $::tcl_patchLevel != "8.5.9"} {
	puts "You are running a version lower than TCL 8.9.5, you need to enable the compatibility mode in your config in order to run tBar"
}

package require Tk
package require tbar
package require logger
namespace import ::geekosphere::tbar::util::logger::*
initLogger

# extend library to user specific lib in /home/user/.tbar/lib
set userLib [file join $::env(HOME) .tbar lib]
if {[file exists $userLib]} {
	lappend auto_path $userLib
	log "DEBUG" "Extended library path to $auto_path"
}

# extend library to user specific widget in /home/user/.tbar/widget
set userWidget [file join $::env(HOME) .tbar widget]
if {[file exists $userWidget]} {
	set geekosphere::tbar::conf(widget,path) [list $userWidget]
	log "DEBUG" "Extended widget path to $geekosphere::tbar::conf(widget,path)"
} else {
	set geekosphere::tbar::conf(widget,path) [list]
}

# Importing some important commands to ease configuration creation
namespace import geekosphere::tbar::*

# setting window dimensions
set geekosphere::tbar::sys(screen,width) [winfo screenwidth $geekosphere::tbar::sys(bar,toplevel)]
set geekosphere::tbar::sys(screen,height) [winfo screenheight $geekosphere::tbar::sys(bar,toplevel)]

# parsing command line parameters
foreach {parameter value} $argv {
	switch $parameter {
		"--config" {
			if {![file exists $value] || [file isdirectory $value]} { puts "The config file you specifed does not exist or is a directory"; exit }
			set geekosphere::tbar::sys(config) $value
		}
		"--help" {
			puts "tBar help
--config <path>			specify a config file to load"
			exit
		}
	}
}

# sourcing configs
if {[info exists geekosphere::tbar::sys(config)] && [file exists $geekosphere::tbar::sys(config)]} {
	source $geekosphere::tbar::sys(config)
} elseif {[file exists [file join $::env(HOME) .tbar config.tcl]]} {
	source [file join $::env(HOME) .tbar config.tcl]
} elseif {[file exists [file join / etc tbar config.tcl]]} {
	source [file join / etc tbar config.tcl]
} elseif {[file exists [file join . config.tcl]]} {
	source [file join . config.tcl]
}

# creating font
set geekosphere::tbar::conf(font,sysFont) [font create -family $geekosphere::tbar::conf(font,name) \
		-size $geekosphere::tbar::conf(font,size) \
		-weight $geekosphere::tbar::conf(font,bold)
]

# gogogo!
geekosphere::tbar::init
