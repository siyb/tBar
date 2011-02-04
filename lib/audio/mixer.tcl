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

	proc drawAllVolumeControls {} {
		variable sys
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
		set data [read [set fl [open |[list amixer controls]]]]
		close $fl
		foreach control [split $data "\n"] {
			set splitControl [split $control ","]
			foreach item $splitControl {
				set splitItem [split $item "="]
				set key [lindex $splitItem 0]
				set value [lindex $splitItem 1]
				if {$key eq "numid"} {
					set arrayKey $value
				} else {
					set sys($w,control,$arrayKey,$key) $value 
				}
			}
		}
	}

	proc getInformationOnDevice {w numid} {
		variable sys
		set data [split [read [set fl [open |[list amixer cget numid=$numid]]]] "\n"]
		
		
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

	drawVolumeControl "Foo" .foo
	drawVolumeControl "Bar" .bar
	drawVolumeControl "Lol" .lol
	drawVolumeControl "Kay" .kay
	updateControlList LOL
	getInformationOnDevice LOL 22
	foreach {key value} [array get sys] {
		puts "$key -> $value"
	}
}
