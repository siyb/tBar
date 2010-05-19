package require util

package provide tbar 1.1

# TODO 1.x: remove args parameter at action proc of widgets (no list)
# TODO 1.x move getOption to util
namespace eval geekosphere::tbar {

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
	set sys(bar,version) 1.0
	set sys(bar,toplevel) .
	set sys(widget,list) [list]
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
		loadWidgets
	}

	# adds text to widget
	proc addText {text color} {
		addWidget text -1 -text $text -fg $color
	}

	# add a widget to the bar
	proc addWidget {proc updateInterval args} {
		variable sys
		lappend sys(widget,list) $proc $updateInterval $args
	}

	# load all widgets
	proc loadWidgets {} {
		variable sys
		foreach {widget updateInterval settingsList} $sys(widget,list) {
			if {[catch {
				uplevel #0 source [file join widget ${widget}.tcl]
				geekosphere::tbar::widget::${widget}::init $settingsList
				if {$updateInterval > 0} { updateWidget $widget $updateInterval }
			} err]} {
				puts $::errorInfo
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

	namespace export addWidget addText setWidth setHeight setXposition setYposition setBarColor setTextColor \
	positionBar alignWidgets setHoverColor setClickedColor setFontName setFontSize setFontBold


}

