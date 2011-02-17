namespace eval geekosphere::amixer {
	set sys(iter) 0
	
	proc amixer {} {
		variable sys
		proc amixer_$sys(iter) {} {
		}
		return $sys(iter)
	}
	
	proc updateControlList {} {
		variable sys
		set sys(amixerControls) [dict create];# reset the dict (or create it)
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
			dict set sys(amixerControls) $numId $controlDeviceDict
		}
	}
	
	proc getControlDeviceInfo {numid} {
		variable sys
		if {![dict exists $sys(amixerControls) $numid]} { error "Control with numid='$numid' does not exist" }
		dict get $sys(amixerControls) $numid
	}

	proc getControlDeviceList {} {
		variable sys
		if {![info exists sys(amixerControls)]} { updateControlList }
		return [dict keys $sys(amixerControls)]
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
		set insideString 0;# a flag to determine if the parser is currently within a string
		set valuesToRead 0;# number of values to read
		set readingValues 0;# flag to signal parser that values should be read
		for {set i 0} {$i < [string length $data]} {incr i} {
			set letter [string index $data $i]
			if {$readingValues == 2} {
				set valueBuffer ""
				dict lappend informationDict values $tmpValue
				for {} {$i < [string length $data]} {incr i} {
					set letter [string index $data $i]
					if {$letter eq "," || $letter eq "\n"} {
						dict lappend informationDict values $valueBuffer
						set valueBuffer ""
						incr valuesToRead -1
					} else {
						append valueBuffer $letter
					}
					if {$valuesToRead == 0} { break }
				}
				set tmpKey ""; set tmpValue ""
				set readingValues 0
				continue
			}
			if {$letter eq "|" || $letter eq ";" || $letter eq ":" || $letter eq ","} {
				set readingKey 1

				if {$tmpKey eq "type"} { 
					set type $tmpValue
				} elseif {$tmpKey eq "values"} {
					if {$readingValues == 0} {
						set valuesToRead [expr {$tmpValue -1}]
					}
					incr readingValues
					set tmpKey ""
					continue
				}
				
				if {[info exists type] && $type eq "ENUMERATED" && $tmpKey eq "items"} { 
					set items $tmpValue
					set readingItems 1
					set readingItemsEndLine [expr {$lineNumber + $items}]
					set tmpKey ""; set tmpValue ""
					continue
				}
				if {$readingItems} {
					dict lappend informationDict items $tmpKey
					if {$lineNumber == $readingItemsEndLine} {
						set readingItems 0
					}
				} else {
					if {$tmpKey ne ""} { dict set informationDict $tmpKey $tmpValue }
				}

				set tmpKey ""; set tmpValue ""
				continue
			}
			if {$letter eq "'"} {
				set insideString [expr {!$insideString}]
			}
			if {$letter eq " " && !$insideString} {
				continue
			}
			if {$letter eq "\n"} { 
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
		return $informationDict
	}
}