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
		set sys($w,originalCommand) ${w}_

		# create an array containing all controldevices
		# listed by amixer
		updateControlList $w

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
		foreach device [getControlDeviceList $w] {
			getInformationOnDevice $w $device
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

	# parses the information provided by "amixer cget numid="
	proc getInformationOnDevice {numid} {
		set data [read [set fl [open |[list amixer cget numid=$numid]]]];close $fl
		set tmpKey "";# stores the current tmpKey of a key/value pair
		set tmpValue "";# stores the current tmpValue of a key/value pair
		set type "";# stores the type of the device
		set items 0;# if type ==  ENUMERATED, this var will store how many items can be parsed
		set readingItems 0;# is 1 if we are currently reading in items
		set readingItemsEndLine 0;# the line of the last item
		set readingKey 1;# is 1 if we are currently reading the key part of ley=value, when 0, we are reading the value
		set informationDict [dict create];# the dict that stores the parsed data
		set lineNumber 1;# the current line number we are on
		for {set i 0} {$i < [string length $data]} {incr i} {
			set letter [string index $data $i]
			if {$letter eq "|" || $letter eq ";" || $letter eq ":" || $letter eq ","} {
				set readingKey 1

				if {$tmpKey eq "type"} { 
					set type $tmpValue
					puts "TYPE is $type"
				}
				
				if {[info exists type] && $type eq "ENUMERATED" && $tmpKey eq "items"} { 
					set items $tmpValue
					set readingItems 1
					set readingItemsEndLine [expr {$lineNumber + $items}]
					puts "READING $items items to line $readingItemsEndLine"
					set tmpKey ""; set tmpValue ""
					continue
				}

				if {$readingItems} {
					puts "ADDING: $tmpKey"
					dict lappend informationDict items $tmpKey
				} else {
					dict set informationDict $tmpKey $tmpValue
				}

				set tmpKey ""; set tmpValue ""
				continue
			}
			if {$letter eq " "} {
				continue
			}
			if {$letter eq "\n"} { 
				if {$readingItems && $lineNumber == $readingItemsEndLine} {
					puts "ALL ITEMS READ, last item -> $tmpKey|$tmpValue"
					set readingItems 0
				}
				puts "LINENUMBER: $lineNumber"
				incr lineNumber
				continue
			}
			if {$letter eq "="} {
				set readingKey 0 
				continue
			}
			if {$readingKey} {
				append tmpKey $letter
			} else {
				append tmpValue $letter
			}
		}
		puts $informationDict
	}
	getInformationOnDevice 1
	getInformationOnDevice 26

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
