package provide mixer 1.0

package require logger
package require amixer

proc mixer {w args} {
	if {[geekosphere::tbar::widget::mixer::makeMixer $w $args] == -1} {
		return -1
	}

	proc $w {args} {
		geekosphere::tbar::widget::mixer::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}
catch {namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::widget::mixer {
	initLogger

	proc makeMixer {w arguments} {
		variable sys
		set sys($w,originalCommand) ${w}_

		# create an array containing all controldevices
		# listed by amixer
		geekosphere::amixer::updateControlList

		frame ${w}

		pack [label ${w}.mixer -text "MIXER"]
		bind ${w}.mixer <Button-1> [namespace code [list drawAllVolumeControls $w]]

		uplevel #0 rename $w ${w}_
		action $w configure $arguments
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
					"-width" {
						changeWidth $w $value
					}
					"-height" {
						changeHeight $w $value
					}
					"-font" {
						changeFont $w $value
					}
					"-devices" {
						setDevices $w $value
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
	}

	#
	# GUI related stuff
	#

	proc drawAllVolumeControls {w} {
		variable sys
		if {[winfo exists ${w}.mixerWindow]} {
			destroy ${w}.mixerWindow
			return
		} else {
			toplevel ${w}.mixerWindow -bg $sys($w,background) -height 400 
		}
		foreach device [geekosphere::amixer::getControlDeviceList $w] {
			set deviceInformation [getInformationOnDevice $device]
			puts "DI: $deviceInformation"
			set info [getControlDeviceInfo $w $device]
			if {[shouldDeviceBeShown $w $device]} {
				drawVolumeControl $w [dict get $info "name"] ${w}.mixerWindow.${device}
			}
		}
		pack [label ${w}.mixerWindow.l -text "\n\n\n\n\n\n\n\n" -bg $sys($w,background)] -expand 1 -fill y
		positionWindowRelativly ${w}.mixerWindow $w
	}

	# updates the volume control bar
	proc updateVolumeControl {path volume} {
	
	}

	# draws a single volume scrollbar element
	proc drawVolumeControl {w name path} {
		variable sys
		set controlPath ${path}
		pack [frame $controlPath -bg $sys($w,background)] -fill y -expand 1 -side right 
		pack [label ${controlPath}.label -text "$name" -bg $sys($w,background) -font $sys($w,font) -fg $sys($w,foreground)] -side top
		pack [scrollbar ${controlPath}.bar -command [list geekosphere::tbar::widget::mixer::changeYView $controlPath] -bg $sys($w,background)] -expand 1 -fill y 
		${controlPath}.bar set 0.0 0.0
	}
	
	# the action handler for the volume scrollbars
	proc changeYView {args} {
		set path [lindex $args 0]
		set command [lindex $args 1]
		set number [lindex $args 2]
		set postfix ""
		if {[llength $args] == 4} {
			set postfix [lindex $args 3]
		}
		switch $command {
			"moveto" {
				${path}.bar set $number $number
			}
			"scroll" {
				set pos [lindex [${path}.bar get] 0]
				if {$postfix eq "pages"} {
					set factor 0.1
				} elseif {$postfix eq "units"} {
					set factor 0.01
				}

				set newVal [expr {$pos + ($number * $factor)}]
				${path}.bar set $newVal $newVal
			}
		}
	}
	
	proc shouldDeviceBeShown {w numid} {
		variable sys
		if {![info exists sys($w,activatedDevices)] || [lsearch $sys($w,activatedDevices) $numid] != -1} { return 1 } else { return 0 }
	}

	#
	# Widget configuration procs
	#

	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		${w}.mixer configure -bg $color
		set sys($w,background) $color
	}

	proc changeForegroundColor {w color} {
		variable sys
		${w}.mixer configure -fg $color
		set sys($w,foreground) $color
	}

	proc changeFont {w font} {
		variable sys
		${w}.mixer configure -font $font
		set sys($w,font) $font
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

	proc setDevices {w devices} {
		variable sys
		set sys($w,activatedDevices) $devices
	}
}
