package provide battery 1.0

package require logger

proc battery {w args} {
	geekosphere::tbar::widget::battery::makeBattery $w $args

	proc $w {args} {
		geekosphere::tbar::widget::battery::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

namespace import ::geekosphere::tbar::util::logger::*
namespace eval geekosphere::tbar::widget::battery {
	initLogger

	# Information files for battery status
	dict set sys(battery) dir [file join / sys class power_supply]
	dict set sys(battery) energy_full "energy_full"
	dict set sys(battery) energy_full_design "energy_full_design"
	dict set sys(battery) energy_now "energy_now"
	dict set sys(battery) manufacturer "manufacturer"
	dict set sys(battery) model_name "model_name"
	dict set sys(battery) power_now "power_now"
	dict set sys(battery) present "present"
	dict set sys(battery) serial_number "serial_number"
	dict set sys(battery) status "status"
	dict set sys(battery) technology "technology"
	dict set sys(battery) type "type"
	dict set sys(battery) voltage_min_design "voltage_min_design"
	dict set sys(battery) voltage_now "voltage_now"

	proc makeBattery {w arguments} {
		variable sys
		set sys($w,originalCommand) ${w}_
		setBatteryDirs $w
		drawBatteryWidget $w
		
		uplevel #0 rename $w ${w}_
	}


	proc action {w args} {
		variable sys
		set args [join $args]
		set command [lindex $args 0]
		set rest [lrange $args 1 end]
		if {$command eq "configure"} {
			foreach {opt value} $rest {
				switch $opt {
					"-fg" - "-foreground" {
						changeForegroundColor $w $value
					}
					"-bg" - "-background" {
						changeBackgroundColor $w $value
					}
					"-dc" - "-displayColor" {
						changeDisplayColor $w $value
					}
					"-width" {
						changeWidth $w $value
					}
					"-height" {
						changeHeight $w $value
					}
					"-font" {
						changeFont $w $value
					}
					default {
						error "${opt} not supported"
					}
				}
			}
		} elseif {$command == "update"} {
			updateWidget $w
		} else {
			error "Command ${command} not supported"
		}

	}

	#
	# GUI related stuff
	#
	
	# draws a battery display for each battery found. Requires
	# setBatteryDirs to be called beforehand
	proc drawBatteryWidget {w} {
		variable sys
		frame ${w}
		for {set iter 0} {$iter <= $sys($w,batteryCount)} {incr iter} {
			pack [canvas ${w}.batteryDisplay${iter}]
		}
	}

	#
	# Stuff required to obtain battery charging status
	#

	# sets widget dependant variables for battery directories
	proc setBatteryDirs {w} {
		variable sys
		set iter 0
		set batteryDirs [getBatteryDirs]
		if {[llength $batteryDirs] < 1} { log "ERROR" "No batteries found" }
		foreach dir $batteryDirs {
			set sys($w,batteryDir,$iter) $dir
			incr iter
		}
		set sys($w,batteryCount) $iter
	}

	# returns all directories containing battery status data
	proc getBatteryDirs {} {
		variable sys
		return [glob -nocomplain [file join [dict get $sys(battery) dir] BAT]]
	}

	# returns the unit (either µW or µA) for the specified battery folder
	proc returnUnit {batteryFolder} {
		variable sys
		if {[info exists [file join $batteryFolder energy_now]]} {
			return "uW"
		} else if {[info exists [file join $batteryFolder charge_now]]} {
			return "aW"
		} else {
			log "ERROR" "Unable to determine the battery unit"
		}
	}

	# get the state of the battery
	proc getState {batteryFolder} {
		set data [read [set fl [open [file join $batteryFolder status] r]]];close $fl
		return $data
	}

	# returns a dict containing some additional data, that is not required to display charging data
	proc getInfo {batteryFolder} {
		dict set retDict manufacturer [read [set fl0 [open [file join $batteryFolder manufacturer] r]]]
		dict set retDict model_name [read [set fl1 [open [file join $batteryFolder model_name] r]]]
		dict set retDict technology [read [set fl2 [open [file join $batteryFolder technology] r]]]
		dict set retDict type [read [set fl3 [open [file join $batteryFolder type] r]]]
		close $fl0;close $fl1;close $fl2;close $fl3
		return $retDict
	}

	#
	# Widget configuration procs
	#
	
	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		
		set sys($w,background) $color
	}
	
	proc changeForegroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color

		set sys($w,foreground) $color
	}

	proc changeDisplayColor {w width} {
	}

	proc changeWidth {w width} {
		variable sys
		for {set iter 0} {$iter <= sys($w,batteryCount)} {incr iter} {
			${w}.batteryDisplay${iter} configure -width $width
		}
	}
	
	proc changeHeight {w height} {
		variable sys
		$sys($w,originalCommand) configure -height $height
		for {set iter 0} {$iter <= sys($w,batteryCount)} {incr iter} {
			${w}.batteryDisplay${iter} configure -height $height
		}
	}
	
	proc changeLoadColor {w color} {
		variable sys
	}
	
	proc changeFont {w font} {
		variable sys
		
		set sys($w,font) $font
	}

}

#test
#pack [battery .foo -displayColor red]
