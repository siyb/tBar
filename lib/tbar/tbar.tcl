package require util
package require logger

package provide tbar 1.1

# TODO 1.2: frequency scaling
# TODO 1.2: stop update activities if screensaver is on
# TODO 1.2: allow multiple widget of the same kind; addWidget clock 1; addWidget clock 1
# TODO 1.2: implement error handler (-> bug report) and logger
# TODO 1.x: add icon support for widgets
namespace import geekosphere::tbar::util::logger::*
namespace import geekosphere::tbar::util::*
namespace eval geekosphere::tbar {
	
	# setting loglevel, can be overridden by userconfig
	setGlobalLogLevel "DEBUG"
	
	#
	# Config (use config.tcl to make changes!)
	#
	set conf(color,background) "black"
	set conf(color,hovercolor) "blue"
	set conf(color,clickedcolor) "red"
	set conf(color,text) "white"
	
	set conf(font,name) "DejaVu Sans Mono"
	set conf(font,size) 12
	set conf(font,bold) normal
	set conf(font,sysFont) -1
	
	set conf(geom,width) 1000
	set conf(geom,height) 20
	set conf(geom,xpos) 750
	set conf(geom,ypos) 1031

	set conf(widgets,position) "left"
	set conf(widget,path) [file join / usr share tbar]

	#
	# Code
	#

	# Variables holding system relevant information
	set sys(bar,version) 1.2
	set sys(bar,toplevel) .
	set sys(widget,list) [list]
	set sys(screen,width) 0
	set sys(screen,height) 0


	# Initializes the bar
	proc init {} {
		variable conf
		variable sys
		initLogger;# init logger for this namespace
		wm manage $sys(bar,toplevel)
		wm client $sys(bar,toplevel) "tbar"
		wm geometry $sys(bar,toplevel) 0x0+$conf(geom,xpos)+$conf(geom,ypos)
		wm minsize $sys(bar,toplevel) $conf(geom,width) $conf(geom,height)
		wm maxsize $sys(bar,toplevel) $conf(geom,width) $conf(geom,height)
		$sys(bar,toplevel) configure -bg $conf(color,background)
		wm overrideredirect $sys(bar,toplevel) 1
		loadWidgets
	}

	# adds text to widget
	proc addText {text color} {
		addWidget text -1 -text $text -fg $color
	}

	# add a widget to the bar
	proc addWidget {proc updateInterval args} {
		variable sys
		#if {[isWidgetAdded $proc] >= 0} { error "Adding a widget multiple times is not supported yet!" }
		lappend sys(widget,list) $proc $updateInterval $args
	}
	
	# returns >= 0 if widget has been added
#	proc isWidgetAdded {proc} {
#		variable sys
#		puts $sys(widget,list)
#		return [lsearch -index 0 $sys(widget,list) $proc]
#	}

	# load all widgets
	proc loadWidgets {} {
		variable sys
		variable conf
		foreach {widget updateInterval settingsList} $sys(widget,list) {
			if {[catch {
				log "INFO" "Attempting to load Widget: $widget Updateinterval: $updateInterval Settings: $settingsList"
				if {![file exists $conf(widget,path)]} { log "ERROR" "Widget path does not exists, use setWidgetPath to set it correctly, if not set it will default to \$installDir/usr/share/tbar/"; exit }
				uplevel #0 source [file join $conf(widget,path) ${widget}.tcl]
				geekosphere::tbar::widget::${widget}::init $settingsList
				if {$updateInterval > 0} { updateWidget $widget $updateInterval }
			} err]} {
				log "ERROR" "Failed loading widget $widget: $::errorInfo"
			}
		}
	}

	# a recursive proc that handles widget updates by calling the widget's update procedure
	proc updateWidget {widget interval} {
		geekosphere::tbar::widget::${widget}::update
		after [expr { $interval * 1000 }] [namespace code [list updateWidget $widget $interval]]
	}

	# gets the update interval for the specified widget
	proc getUpdateInterval {searchWidget} {
		variable sys
		foreach {widget updateInterval settingsList} $sys(widget,list) {
			if {$searchWidget eq $widget} { return $updateInterval }
		}
	}

	# returns the way how widgets are to be aligned in the bar
	proc getWidgetAlignment {} {
		variable conf
		return $conf(widgets,position)
	}

	# writes bugreports
	proc saveBugreport {message} {
		variable sys
		set timeStamp [clock format [clock seconds] -format "%+"]
		set bugreportPath [file join $::env(HOME) .tbar]
		if {![file exists $bugreportPath]} { return }
		set file [string map {" " _} [file join $bugreportPath BUGREPORT_${timeStamp}]]
		set fl [open $file a+]
		puts $fl "
Bugreport

DATE/TIME: [clock format [clock seconds] -format "%+"]]
VERSION: $sys(bar,version)
HOSTNAME: [info hostname]
EXECUTABLE: [info nameofexecutable]
SCRIPT: [info script]

SYSTEM:
-------
TCL:          [info patchlevel]
OS:           $::tcl_platform(os)
OSVersion:    $::tcl_platform(osVersion)
Threaded:     $::tcl_platform(threaded)
Machine:      $::tcl_platform(machine)

PACKAGES:
---------"
		foreach item [info loaded] {
			puts $fl "$item"
		}
			puts $fl "
SETTINGS:
---------"

		foreach {item value} [array get geekosphere::tbar::conf] {
			puts $fl "$item ---> $value"
		}

		puts $fl "
WIDGETS:
-------"

		foreach sysArray [getSysArrays] {
			puts $fl "\n${sysArray}\n"
			foreach {item value} [array get $sysArray] {
				puts $fl "$item --> $value"
			}
		}

		puts $fl "
ERRORINFO:
----------
$::errorInfo

ERRORCODE:
----------
$::errorCode"
		close $fl
		log "INFO" "Bugreport written to $file"
	}

	# CONFIG PROCS

	proc setWidth {width} {
		variable conf
		set conf(geom,width) $width
	}

        proc setHeight {height} {
                variable conf
                set conf(geom,height) $height
        }

	proc positionBar {where} {
		variable sys
		variable conf
		switch $where {
			"top" {
				setXposition 0
				setYposition 0
				setWidth $sys(screen,width)
			}
			"bottom" {
				setXposition 0
				setYposition [expr $sys(screen,height) - $conf(geom,height)]
				setWidth $sys(screen,width)
			}
			default {
				error "'where' must be bottom or top"
			}
		}
	}

	proc alignWidgets {where} {
		variable sys
		variable conf
		switch $where {
			"left" {
				set conf(widgets,position) "left"
			}
			"right" {
				set conf(widgets,position) "right"
			}
			default {
				error "'where' must be left or right"
			}
		}
	}

	proc setXposition {x} {
		variable conf
		set conf(geom,xpos) $x
	}

	proc setYposition {y} {
		variable conf
		set conf(geom,ypos) $y
	}

	proc setBarColor {color} {
		variable conf
		set conf(color,background) $color
	}

	proc setTextColor {color} {
		variable conf
		set conf(color,text) $color
	}

	proc setHoverColor {color} {
		variable conf
		set conf(color,hovercolor) $color
	}

	proc setClickedColor {color} {
		variable conf
		set conf(color,clickedcolor) $color
	}
	
	proc setFontName {font} {
		variable conf
		set conf(font,name) $font
	}

	proc setFontSize {font} {
		variable conf
		set conf(font,size) $font
	}

	proc setFontBold {status} {
		variable conf
		set conf(font,bold) $status
	}
	
	proc setWidgetPath {path} {
		variable conf
		set conf(widget,path) $path
	}

	proc setLogLevel {level} {
		setGlobalLogLevel $level
	}

	namespace export addWidget addText setWidth setHeight setXposition setYposition setBarColor setTextColor \
	positionBar alignWidgets setHoverColor setClickedColor setFontName setFontSize setFontBold setWidgetPath \
	setLogLevel
}
initLogger
proc bgerror {message} {
	geekosphere::tbar::saveBugreport $message   
	log "ERROR" "Background error encountered ${::errorInfo}"
}

