package provide battery 1.0

package require logger

proc battery {w args} {
	if {[geekosphere::tbar::widget::battery::makeBattery $w $args] == -1} {
		return -1
	}

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
		set sys($w,warnat) -1
		set sys($w,hasBeenWarned) 0
		set sys($w,lastStatus) -1
		set sys($w,notifyFullyCharged) 0
		set sys($w,hasBeenNotified) 0
		
		set sys($w,lowBattery) 10
		set sys($w,highBattery) 65
		
		set sys($w,height) 0
		set sys($w,width) 0
		
		if {[setBatteryDirs $w] == -1} {;# determine battery directory
			return -1
		}
		determineBatteryInformationFiles $w $sys($w,batteryDir);# set files which contain charging information
		
		
		frame ${w}
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
					"-lc" - "-lowColor" {
						changeLowColor $w $value
					}
					"-mc" - "-mediumColor" {
						changeMediumColor $w $value
					}
					"-hc" - "-highColor" {
						changeHighColor $w $value
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
					"-warnAt" {
						setWarnAt $w $value
					}
					"-notifyFullyCharged" {
						setNotifyFullyCharged $w $value
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
		if {![info exists sys($w,batteryDir)]} { return }
		set chargeDict [calculateCharge $w]
		set sys($w,timeRemaining) [dict get $chargeDict time]
		set sys($w,chargeInPercent) [dict get $chargeDict percent]
		if {[info exists sys($w,status)]} {
			set sys($w,lastStatus) $sys($w,status);# saving last status
		}
		set sys($w,status) [dict get $chargeDict status]
		
		# reset warning / notification status if charger has been connected / disconnected etc
		if {$sys($w,status) ne $sys($w,lastStatus)} {
			set sys($w,hasBeenWarned) 0
			set sys($w,hasBeenNotified) 0
		}
		
		drawWarnWindow $w
		drawFullyChargedWindow $w
		drawBatteryDisplay $w $sys($w,chargeInPercent)
	}

	#
	# GUI related stuff
	#
	
	# draws a battery on a canvas
	proc drawBatteryDisplay {w fillStatus} {
		variable sys
		if {$fillStatus < 0 || $fillStatus > 100} {
			error "Fillstatus must be between 0 and 100 percent"
		}
		set canvasPath ${w}.batterydisplay
		set color [determineColorOfWidgetByBatteryStatus $w $fillStatus]
		if {![winfo exists $canvasPath]} {
			pack [canvas $canvasPath -height 10 -width 10 -bg $sys($w,background) -height $sys($w,height) -width $sys($w,width) -highlightthickness 0]
			set cWidth [$canvasPath cget -width]
			set cHeight [$canvasPath cget -height]

			# drawing battery + pole
			set startPoleX [expr {($cWidth / 2) - ($cWidth / 10)}]
			set startPoleY 1
			set endPoleX [expr {($cWidth / 2) + ($cWidth / 10)}]
			set endPoleY [expr {$cHeight - ($cHeight - ($cHeight/5))}]
			set sys($w,batteryPole) [$canvasPath create rectangle $startPoleX $startPoleY $endPoleX $endPoleY]
			if {$fillStatus == 100} {
				$canvasPath itemconfigure $sys($w,batteryPole) -fill $color
			}

			# drawing battery "body"
			set startBodyX [expr {($cWidth / 2) - ($cWidth / 5)}]
			set startBodyY $endPoleY
			set endBodyX [expr {($cWidth / 2) + ($cWidth / 5)}]
			set endBodyY $cHeight
			set sys($w,batteryBody) [$canvasPath create rectangle $startBodyX $startBodyY $endBodyX $endBodyY]
		
			bind $canvasPath <Button-1> [namespace code [list displayBatteryInfo $w]]
			
			# some vars for drawing the fillstatus
			set sys($w,batterydisplay,cWidth) $cWidth
			set sys($w,batterydisplay,cHeight) $cHeight
			set sys($w,batterydisplay,endPoleY) $endPoleY
		}
		
		if {[info exists sys($w,lastBatteryStatusBox)]} {
			$canvasPath delete $sys($w,lastBatteryStatusBox)
		}
		
		# drawing the fill status
		set sys($w,lastBatteryStatusBox) [$canvasPath create rectangle \
			[expr {($sys($w,batterydisplay,cWidth) / 2) - ($sys($w,batterydisplay,cWidth) / 5)}] \
			[expr {$sys($w,batterydisplay,cHeight) - ($fillStatus / 100.0 * ($sys($w,batterydisplay,cHeight)-$sys($w,batterydisplay,endPoleY)))}] \
			[expr {($sys($w,batterydisplay,cWidth) / 2) + ($sys($w,batterydisplay,cWidth) / 5)}] \
			$sys($w,batterydisplay,cHeight) \
			-fill $color \
			-outline $color]
		
		# coloring over the ugly line, separating pole and body
		if {![info exists sys($w,lastColorOverLine)]} {
			set startLineX [expr {$startPoleX+1}]
			set startLineY $endPoleY
			set endLineX [expr {$endPoleX-1}]
			set endLineY $endPoleY
			set sys($w,lastColorOverLine) [$canvasPath create rectangle $startLineX $startLineY $endLineX $endLineY]
		}
		if {$fillStatus == 100} {
			$canvasPath itemconfigure $sys($w,lastColorOverLine) -fill $color -outline $color
		} else {
			$canvasPath itemconfigure $sys($w,lastColorOverLine) -fill $sys($w,background)  -outline $sys($w,background) 
		}
		
		# updating color of all boxes
		$canvasPath itemconfigure $sys($w,batteryPole) -outline $color
		$canvasPath itemconfigure $sys($w,batteryBody) -outline $color
	}

	# determine the color of the widget by loading status
	proc determineColorOfWidgetByBatteryStatus {w fillStatus} {
		variable sys
		if {$fillStatus < $sys($w,lowBattery)} {
			return "red"
		} elseif {$fillStatus > $sys($w,highBattery)} {
			return "green"
		} else {
			return "yellow"
		}
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
		pack [label ${batteryWindow}.status -text "Status: $sys($w,status)" -fg $sys($w,foreground) -bg $sys($w,background) -font $sys($w,font) -anchor w] -fill x
		positionWindowRelativly $batteryWindow $w
	}

	# draws the warning window if appropriate
	proc drawWarnWindow {w} {
		variable sys
		if {$sys($w,warnat) != -1 && $sys($w,chargeInPercent) <= $sys($w,warnat) && ![winfo exists ${w}.warnWindow] && !$sys($w,hasBeenWarned) && $sys($w,status) ne "Charging" && $sys($w,status) ne "+"} {
			tk_dialog ${w}.warnWindow "Battery warning" "Warning, $sys($w,chargeInPercent)% battery left" "" 0 Ok
			set sys($w,hasBeenWarned) 1
		}
	}
	
	# draws a notification window if the battery has been fully charged and if the notification has been enabled ;)
	proc drawFullyChargedWindow {w} {
		variable sys
		if {$sys($w,notifyFullyCharged) && $sys($w,chargeInPercent) == 100 && !$sys($w,hasBeenNotified)} {
			tk_dialog ${w}.warnWindow "Battery info" "Battery has been fully charged!" "" 0 Ok
			set sys($w,hasBeenNotified) 1
		}
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
		if {[llength $batteryDirs] != 1} { log "ERROR" "No batteries or mulptiple batteries found, use the -battery option to specify the battery you wish to monitor."; return -1}
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
		} else {
			set timeLeft -1
			dict set returnDict time "N/A"
			return $returnDict
		}
		set h [expr {round(floor($timeLeft))}]
		set m [expr {round(floor(($timeLeft - $h) * 60.0))}]
		dict set returnDict time [format "%02d:%02d" ${h} ${m}]
		dict set returnDict status $status
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
		set sys($w,background) $color
	}
	
	proc changeForegroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		set sys($w,foreground) $color

	}
	
	proc changeFont {w font} {
		variable sys
		set sys($w,font) $font
	}
	
	proc changeLowColor {w color} {
		variable sys
		set sys($w,lowColor) $color
	}

	proc changeMediumColor {w color} {
		variable sys
		set sys($w,mediumColor) $color
	}

	proc changeHighColor {w color} {
		variable sys
		set sys($w,highColor) $color
	}

	proc changeWidth {w width} {
		variable sys
		set sys($w,width) $width
		$sys($w,originalCommand) configure -width $width
	}
	
	proc changeHeight {w height} {
		variable sys
		set sys($w,height) $height
		$sys($w,originalCommand) configure -height $height
	}
	
	proc setNotifyFullyCharged {w notify} {
		variable sys
		if {$notify != 0 &&  $notify != 1} {
			log "ERROR" "-notifyFullyCharged must be 1 or 0, falling back to 0"
			return
		}
		set sys($w,notifyFullyCharged) $notify
	}
	
	proc setWarnAt {w warnat} {
		variable sys
		if {![string is integer $warnat]} { 
			log "ERROR" "-warnAt value is not an integer, falling back to 5%"
			set sys($w,warnat) 5
		} else {
			set sys($w,warnat) $warnat
		}
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
