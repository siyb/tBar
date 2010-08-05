package provide tbar 1.1

package require util
package require logger

# TODO 1.x: language files
# TODO 1.x: add icon support for widgets
# TODO 1.x: stop update activities if screensaver is on
# TODO 1.X: make popup windows more customizable (e.g. let the user decide which and if calendar window appears) -> subwidget or something
catch {
	namespace import ::geekosphere::tbar::util::logger::*
	namespace import ::geekosphere::tbar::util::*
}
namespace eval geekosphere::tbar {
	initLogger;# init logger for this namespace

	# setting loglevel, can be overridden by userconfig
	setGlobalLogLevel "TRACE"
	
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

	#
	# Code
	#

	# Variables holding system relevant information
	set sys(bar,version) 1.2
	set sys(bar,toplevel) .
	set sys(widget,dict) [dict create]
	set sys(screen,width) 0
	set sys(screen,height) 0


	# Initializes the bar
	proc init {} {
		variable conf
		variable sys
		wm manage $sys(bar,toplevel)
		wm client $sys(bar,toplevel) "tbar"
		wm geometry $sys(bar,toplevel) 0x0+$conf(geom,xpos)+$conf(geom,ypos)
		wm minsize $sys(bar,toplevel) $conf(geom,width) $conf(geom,height)
		wm maxsize $sys(bar,toplevel) $conf(geom,width) $conf(geom,height)
		$sys(bar,toplevel) configure -bg $conf(color,background)
		wm overrideredirect $sys(bar,toplevel) 1
		lappend conf(widget,path) [file join / usr share tbar]
		lappend conf(widget,path) [file join widget]
		loadWidgets
	}

	# adds text to widget
	proc addText {text color} {
		variable sys
		incr sys(widget,counter)
		addWidgetToBar text $sys(widget,counter) -1 -text $text -fg $color
		return $sys(widget,counter)
	}

	# add a widget to the bar
	set sys(widget,counter) 0
	proc addWidget {proc updateInterval args} {
		variable sys
		incr sys(widget,counter)
		log "WARNING" "From version 1.2 onwards, using this procedure to add widgets to the bar is _DEPRECATED_! Use addWidgetToBar instead. (widget: $proc)"
		if {[dict exists $sys(widget,dict) $sys(widget,counter)]} { error "A widget named $name already exists" }
		dict set sys(widget,dict) $sys(widget,counter) widgetName $proc 
		dict set sys(widget,dict) $sys(widget,counter) updateInterval $updateInterval
		dict set sys(widget,dict) $sys(widget,counter) arguments $args
		dict set sys(widget,dict) $sys(widget,counter) path [geekosphere::tbar::util::generateComponentName]
		return $sys(widget,counter)
	}
	
	# add a widget to the bar
	proc addWidgetToBar {proc name updateInterval args} {
		variable sys
		if {[dict exists $sys(widget,dict) $name]} { error "A widget named $name already exists" }
		dict set sys(widget,dict) $name widgetName $proc 
		dict set sys(widget,dict) $name updateInterval $updateInterval
		dict set sys(widget,dict) $name arguments $args
		dict set sys(widget,dict) $name path [geekosphere::tbar::util::generateComponentName]
	}
	
	# load all widgets
	proc loadWidgets {} {
		variable sys
		variable conf
		dict for {key value} $sys(widget,dict) {
			set widget [dict get $sys(widget,dict) $key widgetName]
			set updateInterval [dict get $sys(widget,dict) $key updateInterval]
			set settingsList [dict get $sys(widget,dict) $key arguments]
			set path [dict get $sys(widget,dict) $key path]
			if {[catch {
				log "INFO" "Attempting to load Widget: $widget Updateinterval: $updateInterval Settings: $settingsList | Searching in: $conf(widget,path)"
				foreach widgetPath $conf(widget,path) {
					log "TRACE" "Looping widgetPath: $widgetPath"
					set widgetFile [file join $widgetPath ${widget}.tcl]
					if {[file exists $widgetFile]} {
						uplevel #0 source $widgetFile
						geekosphere::tbar::wrapper::${widget}::init $path $settingsList
						makeBindings $key
						if {$updateInterval > 0} { updateWidget $path $widget $updateInterval }
						log "INFO" "Widget $widget loaded from $widgetFile"
						set loadSuccess 1
						break
					}
				}
				# check if widget could be found in $conf(widget,path) and inform user if not
				if {[info exists loadSuccess]} {
					unset loadSuccess
				} else {
					log "WARNING" "Widget $widget can not be found in: $conf(widget,path)"
				}
			} err]} {
				log "ERROR" "Failed loading widget $widget: $::errorInfo"
			}
		}
	}
	
	proc makeBindings {widgetName} {
		variable sys
		if {![info exists sys(widget,events,$widgetName)]} { return };# no events -> no need to continue
		set path [dict get $sys(widget,dict) $widgetName path]
		
		foreach {event command} $sys(widget,events,$widgetName) {
			foreach child [returnNestedChildren ${path}] {
				bind ${child} $event +$command
			}
		}
	}

	# a recursive proc that handles widget updates by calling the widget's update procedure
	proc updateWidget {path widget interval} {
		geekosphere::tbar::wrapper::${widget}::update $path
		after [expr { $interval * 1000 }] [namespace code [list updateWidget $path $widget $interval]]
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

	proc setLogLevel {level} {
		setGlobalLogLevel $level
	}
	
	proc addEventTo {widgetName event args} {
		variable sys
		# dict lappend does not work with nested dicts yet, using an array instead of ugly hacking
		lappend sys(widget,events,$widgetName) $event $args
		log "INFO" "Event ${event} added to ${widgetName}, invoking ${args}"
	}

	namespace export addWidget addText setWidth setHeight setXposition setYposition setBarColor setTextColor \
	positionBar alignWidgets setHoverColor setClickedColor setFontName setFontSize setFontBold setWidgetPath \
	setLogLevel addWidgetToBar addEventTo
}

# GLOBAL NAMESPACE!
initLogger
proc bgerror {message} {
	geekosphere::tbar::saveBugreport $message   
	log "ERROR" "Background error encountered ${::errorInfo}"
}

