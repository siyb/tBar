package provide battery 1.0

package require logger

proc battery {w args} {
	geekosphere::tbar::widget::battery::makeBattery $w $args

	proc $w {args} {
		geekosphere::tbar::widget::battery::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

catch {namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::widget::battery {
	initLogger

	# Information files for battery status
	dict set sys(battery) dir [file join / sys class power_supply]
	
	dict set sys(battery) energy_full_design "energy_full_design"
	dict set sys(battery) energy_now "energy_now"
	dict set sys(battery) energy_full "energy_full"
	
	dict set sys(battery) charge_now "charge_now"
	dict set sys(battery) charge_full "charge_full"
	
	dict set sys(battery) current_now "current_now"
	
	dict set sys(battery) present "present";# is the battery present
	dict set sys(battery) status "status";# e.g. charging
	
	dict set sys(battery) voltage_min_design "voltage_min_design"
	dict set sys(battery) voltage_now "voltage_now"
	
	# some more stuff
	dict set sys(battery) manufacturer "manufacturer"
	dict set sys(battery) model_name "model_name"
	dict set sys(battery) power_now "power_now"
	dict set sys(battery) serial_number "serial_number"
	dict set sys(battery) technology "technology"
	dict set sys(battery) type "type"


	proc makeBattery {w arguments} {
		variable sys
		set sys($w,originalCommand) ${w}_
		set sys($w,batteryInformation,now) -1
		set sys($w,batteryInformation,full) -1
		
		setBatteryDirs $w;# determine battery directory
		determineBatteryInformationFiles $w $sys($w,batteryDir);# set files which contain charging information
		
		
		frame ${w}
		drawBatteryWidget $w
		uplevel #0 rename $w ${w}_
		
		action $w configure $arguments
		
		log "INFO" "Battery information: [getInfo $sys($w,batteryDir)]"
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
					"-battery" {
						setBattery $w $value
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
	
	proc updateWidget {w} {
		variable sys
		set chargeDict [calculateCharge $w]
		set sys($w,timeRemaining) [dict get $chargeDict time]
		set sys($w,chargeInPercent) [dict get $chargeDict percent]
	}

	#
	# GUI related stuff
	#
	
	# draws a battery display for each battery found. Requires
	# setBatteryDirs to be called beforehand
	proc drawBatteryWidget {w} {
		variable sys
		pack [label ${w}.batteryDisplay -text "Battery"]
		bind ${w}.batteryDisplay <Button-1> [namespace code [list displayBatteryInfo $w]]
	}

	# battery display
	proc displayBatteryInfo {w} {
		variable sys
		set batteryWindow ${w}.batteryWindow
		if {![winfo exists $batteryWindow]} {
			toplevel $batteryWindow
		} else {
			destroy $batteryWindow
			return
		}
		pack [label ${batteryWindow}.time -text "Time Remaining: $sys($w,timeRemaining)" -fg $sys($w,foreground) -bg $sys($w,background) -font $sys($w,font) -anchor w] -fill x
		pack [label ${batteryWindow}.percent -text "Battery Left: $sys($w,chargeInPercent)%" -fg $sys($w,foreground) -bg $sys($w,background) -font $sys($w,font) -anchor w] -fill x
		positionWindowRelativly $batteryWindow $w
	}

	#
	# Stuff required to obtain battery charging status
	#

	# sets widget dependant variables for battery directories
	proc setBatteryDirs {w} {
		variable sys
		if {[info exists sys($w,batteryDir)]} { return }
		set iter 0
		set batteryDirs [getBatteryDirs]
		if {[llength $batteryDirs] != 1} { log "ERROR" "No batteries or mulptiple batteries found, use the -battery option to specify the battery you wish to monitor." }
		set sys($w,batteryDir) $batteryDirs
		log "INFO" "Found battery at '$batteryDirs'"
	}

	# returns all directories containing battery status data
	proc getBatteryDirs {} {
		variable sys
		return [glob -nocomplain [file join [dict get $sys(battery) dir] BAT*]]
	}

	# sets the information files
	proc determineBatteryInformationFiles {w batteryFolder} {
		variable sys
		if {[info exists [file join $batteryFolder energy_now]]} {
			set sys($w,batteryInformation,now) [file join $sys($w,batteryDir) "energy_now"]
			set sys($w,batteryInformation,full) [file join $sys($w,batteryDir) "energy_full"]
		} elseif {[file exists [file join $batteryFolder charge_now]]} {
			set sys($w,batteryInformation,now) [file join $sys($w,batteryDir) "charge_now"]
			set sys($w,batteryInformation,full) [file join $sys($w,batteryDir) "charge_full"]
		} else {
			log "ERROR" "Unable to determine the battery unit"
		}
	}
	
	# calculates charging / discharging time and percent of battery charge
	proc calculateCharge {w} {
		variable sys
		set total [getTotalCapacity $w]
		set remaining [getRemainingCapacity $w]
		set status [getStatus $sys($w,batteryDir)]
		set rate [getCurrentNow $sys($w,batteryDir)]
		dict set returnDict percent [expr {floor(min($remaining*1.0 / $total*1.0 * 100,100))}]
		if {$status eq "+" || $status eq "Charging"} {
			set timeLeft [expr {($total*1.0 - $remaining) / $rate}]
		} elseif {$status eq "-" || $status eq "Discharging"} {
			set timeLeft [expr {$remaining*1.0 / $rate}]
		} elseif {$status eq "full"} {
			# do something here
		} else {
			set timeLeft -1
			dict set returnDict time "N/A"
			return $returnDict
		}
		set h [expr {round(floor($timeLeft))}]
		set m [expr {round(floor(($timeLeft - $h) * 60.0))}]
		dict set returnDict time "${h}:${m}"
		return $returnDict
	}

	# get the state of the battery
	proc getStatus {batteryFolder} {
		variable sys
		set data [gets [set fl [open [file join $batteryFolder [dict get $sys(battery) status]] r]]];close $fl
		return $data
	}

	# returns a dict containing some additional data, that is not required to display charging data
	proc getInfo {batteryFolder} {
		variable sys
		dict set retDict manufacturer [gets [set fl0 [open [file join $batteryFolder [dict get $sys(battery) manufacturer]] r]]]
		dict set retDict model_name [gets [set fl1 [open [file join $batteryFolder [dict get $sys(battery) model_name]] r]]]
		dict set retDict technology [gets [set fl2 [open [file join $batteryFolder [dict get $sys(battery) technology]] r]]]
		dict set retDict type [gets [set fl3 [open [file join $batteryFolder [dict get $sys(battery) type]] r]]]
		close $fl0;close $fl1;close $fl2;close $fl3
		return $retDict
	}
	
	# get current now
	proc getCurrentNow {batteryFolder} {
		variable sys
		set data [gets [set fl [open [file join $batteryFolder [dict get $sys(battery) current_now]] r]]];close $fl
		return $data
	}
	
	# get remaining capacity
	proc getRemainingCapacity {w} {
		variable sys
		if {$sys($w,batteryInformation,now) == -1} { log "ERROR" "Current capacity file wasn't determined correctly."; return }
		set data [gets [set fl [open $sys($w,batteryInformation,now) r]]];close $fl
		return $data
	}
	
	# get total capacity
	proc getTotalCapacity {w} {
		variable sys
		if {$sys($w,batteryInformation,full) == -1} { log "ERROR" "Full capacity file wasn't determined correctly."; return }
		set data [gets [set fl [open $sys($w,batteryInformation,full) r]]];close $fl
		return $data
	}

	#
	# Widget configuration procs
	#
	
	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		${w}.batteryDisplay configure -bg $color
		set sys($w,background) $color
	}
	
	proc changeForegroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		${w}.batteryDisplay configure -fg $color
		set sys($w,foreground) $color

	}
	
	proc changeFont {w font} {
		variable sys
		${w}.batteryDisplay configure -font $font
		set sys($w,font) $font
	}
	
	proc changeDisplayColor {w width} {
	}

	proc changeWidth {w width} {
		variable sys
		${w}.batteryDisplay configure -width $width
	}
	
	proc changeHeight {w height} {
		variable sys
		$sys($w,originalCommand) configure -height $height
		${w}.batteryDisplay configure -height $height
	}
	
	proc changeLoadColor {w color} {
		variable sys
	}
	
	proc setBattery {w battery} {
		variable sys
		set batteryDir [file join [dict get $sys(battery) dir] $battery]
		if {![file exists $batteryDir] || ![file isdirectory $batteryDir]} {
			log "ERROR" "The battery you specified '$battery' could not be found in '$batteryDir', attempting auto detection"
			return
		}
		set sys($w,batteryDir) $batteryDir
	}
}
