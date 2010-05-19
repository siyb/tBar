#!/usr/bin/env wish8.5
set appendDir [file normalize lib/]
if {[file exists $appendDir]} {
	lappend auto_path $appendDir
}
package require tbar

# Importing some important commands to ease configuration creation
namespace import geekosphere::tbar::*

# setting window dimensions
set geekosphere::tbar::sys(screen,width) [winfo screenwidth $geekosphere::tbar::sys(bar,toplevel)]
set geekosphere::tbar::sys(screen,height) [winfo screenheight $geekosphere::tbar::sys(bar,toplevel)]

# parsing command line parameters
foreach {parameter value} $argv {
	switch $parameter {
		"--config" {
			if {![file exists $value]} { puts "The config file you specifed does not exist"; exit }
			set geekosphere::tbar::sys(config) $value
		}
		"--widget" {
			set geekosphere::tbar::conf(widget,path) $value
		}
		"--help" {
			puts "tBar help
--config <path>			specify a config file to load
--widget <path>			specify the widget path"
			exit
		}
	}
}

# sourcing configs
if {[file exists [file join . config.tcl]]} {
	source [file join . config.tcl]
}
if {[file exists [file join etc tbar config.tcl]]} {
	source [file join / etc tbar config.tcl]
}
if {[file exists [file join $::env(HOME) .tbar config.tcl]]} {
	source [file join $::env(HOME) .tbar config.tcl]
}
if {[info exists geekosphere::tbar::sys(config)] && [file exists $geekosphere::tbar::sys(config)]} {
	source $geekosphere::tbar::sys(config)
}

# creating font
set geekosphere::tbar::conf(font,sysFont) [font create -family $geekosphere::tbar::conf(font,name) \
		-size $geekosphere::tbar::conf(font,size) \
		-weight $geekosphere::tbar::conf(font,bold)
]

# gogogo!
geekosphere::tbar::init
