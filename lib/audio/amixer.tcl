package provide amixer 1.0

namespace eval geekosphere::amixer {
	variable sys

	# sets or updates the sys(amixerControls) dictionary. This dictionary will store
	# device information of each device found.
	# The key is the numid, value is another dict with two key, "iface" and "name"
	proc updateControlList {card} {
		variable sys
		set sys(amixerControls) [dict create];# reset the dict (or create it)
		set data [read [set fl [open |[list amixer -c $card controls]]]]
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
			dict set sys(amixerControls) $numId $controlDeviceDict
		}
	}

	# returns a sorted list containing the numid of all devices
	proc getControlDeviceList {card} {
		variable sys
		updateControlList $card
		return [lsort -integer [dict keys $sys(amixerControls)]]
	}
	
	# takes the numid of a device as input. will call amixer cget numid=$numid
	# and parse its output to create a return dict
	proc getInformationOnDevice {card numid} {
		set data [read [set fl [open |[list amixer -c $card cget numid=$numid]]]];close $fl
		set returnDict [dict create]
		dict set returnDict "card" $card
		foreach line [split $data "\n"] {
			set trimmedLine [string trim $line]
			set splitLine [split $trimmedLine]

			set lineMarker [lindex $splitLine 0]
			set values [split [lindex $splitLine 1] ","]

			# db line (maybe something else too Oo)
			if {$lineMarker eq "|"} {
				foreach value $values {
					set splitValue [split $value "="]
					dict set returnDict db_[lindex $splitValue 0] [lindex $splitValue 1]
				}
			# device meta data
			} elseif {$lineMarker eq ";"} {
				set startString [string range $values 0 3]
				
				# presumably first line -> key=value
				if {[llength $values] > 1} {
					foreach value $values {
						set splitValue [split $value "="]
						dict set returnDict meta [dict set meta [lindex $splitValue 0] [lindex $splitValue 1]]
					}
				}

				# enumerated (maybe other types provide items as well?!)
				if {$startString eq "Item"} {
					dict lappend returnDict items [lindex [regexp -inline "'(.*)'" $splitLine] 1]
				}
			# values line
			} elseif {$lineMarker eq ":"} {
				set splitLine [split $line "="]
				set values [split [lindex $splitLine 1] ","]
				foreach value $values {
					dict lappend returnDict values $value
				}	
			# first line
			} else {
				set values [split $splitLine ","]
				foreach value $values {
					set splitValue [split $value "="]
					dict set returnDict info [dict set info [lindex $splitValue 0] [lindex $splitValue 1]]
				}
			}
		}
		return $returnDict
	}

	# set the device specified by infoDict to percentage
	# infoDict is a dict returned by getInformationOnDevice 
	proc setDevicePercent {infoDict percentage} {
		set info [dict get $infoDict "info"]
		set card [dict get $infoDict "card"]
		set command [list amixer -c $card cset numid=[dict get $info "numid"] "${percentage}%"]
		set data [read [set cmd [open |$command]]]; close $cmd
	}

	proc setDeviceBoolean {infoDict bool} {
		if {$bool != 1 && $bool != 0} { error "Must be 1 or 0" }
		set info [dict get $infoDict "info"]
		set card [dict get $infoDict "card"]
		set command [list amixer -c $card cset numid=[dict get $info "numid"] $bool]
		set data [read [set cmd [open |$command]]]; close $cmd
	}	

	proc setDeviceEnum {infoDict enum} {
		set info [dict get $infoDict "info"]
		set card [dict get $infoDict "card"]
		set command [list amixer -c $card cset numid=[dict get $info "numid"] $enum]
		set data [read [set cmd [open |$command]]]; close $cmd
	}
}
