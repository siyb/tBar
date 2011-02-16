package provide mixer 1.0

package require logger

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
		set sys($w,originalCommand) $w

		# create an array containing all controldevices
		# listed by amixer
		updateControlList $w

		frame ${w}
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
		foreach device [getControlDeviceList $w] {
			set info [getControlDeviceInfo $w $device]
			if {[shouldDeviceBeShown $w $device]} {
				drawVolumeControl [dict get $info "name"] ${w}.{$device}
			}
		}
	}

	# updates the volume control bar
	proc updateVolumeControl {path volume} {
	
	}

	# draws a single volume scrollbar element
	proc drawVolumeControl {name path} {
		set controlPath ${path}
		pack [frame $controlPath] -fill y -expand 1 -side right
		pack [label ${controlPath}.label -text "$name"] -side top
		pack [scrollbar ${controlPath}.bar -command [list geekosphere::tbar::widget::mixer::changeYView $controlPath]] -expand 1 -fill y
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

	#
	# AMIXER related stuff
	#

	# sets the sys($w,control,numid,key) array, containing information from all available controls
	proc updateControlList {w} {
		variable sys
		set sys($w,amixerControls) [dict create];# reset the dict (or create it)
		set data [read [set fl [open |[list amixer controls]]]]
		close $fl
		foreach control [split $data "\n"] {
			set splitControl [split $control ","]
			set controlDeviceDict [dict create]
			set numId -1
			foreach item $splitControl {
				set splitItem [split $item "="]
				set key [lindex $splitItem 0]
				set value [lindex $splitItem 1]
				if {$key eq "numid"} { 
					set numId $value
				} else {
					dict set controlDeviceDict $key $value
				}
			}
			if {$numId == -1} { continue };# do not add devices with -1 numid
			dict set sys($w,amixerControls) $numId $controlDeviceDict
		}
	}

	proc getControlDeviceInfo {w numid} {
		variable sys
		if {![dict exists $sys($w,amixerControls) $numid]} { error "Control with numid='$numid' does not exist" }
		dict get $sys($w,amixerControls) $numid
	}

	proc getControlDeviceList {w} {
		variable sys
		return [dict keys $sys($w,amixerControls)]
	}

	proc getInformationOnDevice {w numid} {
		variable sys
		#set data [split [read [set fl [open |[list amixer cget numid=$numid]]]] "\n"];close $fl
		set data [read [set fl [open |[list amixer cget numid=$numid]]]];close $fl
		puts "----------------------------------"
		puts $data
		puts "----------------------------------"
	}

	proc shouldDeviceBeShown {w numid} {
		variable sys
		if {![info exists sys($w,activatedDevices)] || [lsearch sys($w,activatedDevices) $numid] != -1} { return 1 } else { return 0 }
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
