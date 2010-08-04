package provide network 1.1

package require statusBar
package require util

proc network {w args} {
	geekosphere::tbar::widget::network::makeNetwork $w $args

	proc $w {args} {
		geekosphere::tbar::widget::network::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

catch {namespace import ::geekosphere::tbar::util::* }
namespace eval geekosphere::tbar::widget::network {
	set sys(netInfo) "/proc/net/dev"

	proc makeNetwork {w arguments} {

		variable sys
		if {[set sys($w,device) [getOption "-device" $arguments]] eq ""} { error "Specify a device using the -device option." }
		if {[set sys($w,updateInterval) [getOption "-updateinterval" $arguments]] eq ""} { error "Specify an update interval using the -updateinterval option." }

		set sys($w,originalCommand) ${w}_
		# create traffic holder for each device
		set sys($w,lastTx) 0
		set sys($w,lastRx) 0

		frame ${w}
		pack [label ${w}.network -anchor w] -side left -fill both

		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_

		# run configuration
		action $w configure $arguments
		
		set sys($w,initialized) 1
	}

	proc isInitialized {w} {
		variable sys
		return [info exists sys($w,initialized)]
	}
	
	proc updateWidget {w} {
		variable sys
		set netDict [getNetworkSpeedFor $w $sys($w,device)]
		set tx [dict get $netDict "TX"]
		set rx [dict get $netDict "RX"]
		${w}.network configure -text "$sys($w,device) - Up: ${tx} kB/s Down: ${rx} kB/s"
	}
	
	proc getNetworkSpeedFor {w device} {
		variable sys
		if {![info exists sys($w,lastTx)]} { error "You haven't registed $device properly ..." }
		set netDict [parseNetworkSpeed $device]
		set returnDict [dict create]
		set rx [dict get $netDict "rx"]
		set tx [dict get $netDict "tx"]
		if {$sys($w,lastTx) == 0} {
			dict set returnDict "TX" "N/A"
		} else {
			dict set returnDict "TX" [::tcl::mathfunc::round [calculateNetspeed $sys($w,lastTx) $tx $sys($w,updateInterval)]]
		}
		if {$sys($w,lastRx) == 0} {
			dict set returnDict "RX" "N/A"
		} else {
			dict set returnDict "RX" [::tcl::mathfunc::round [calculateNetspeed $sys($w,lastRx) $rx $sys($w,updateInterval)]]
		}
		set sys($w,lastTx) $tx
		set sys($w,lastRx) $rx
		return $returnDict
	}
	
	# parses the network speed for the specified device
	proc parseNetworkSpeed {device} {
		variable sys
		set returnDict [dict create]
		set data [read [set fl [open $sys(netInfo) r]]]
		close $fl
		foreach line [split $data "\n"] {
			set splitLine [split $line ":"]
			if {[llength $splitLine] != 2} { continue }
			if {[string trim [lindex $splitLine 0]] ne $device} { continue }
			set splitLine [split [join [lindex $splitLine 1]]]
			dict set returnDict "tx" [lindex $splitLine 8]
			dict set returnDict "rx" [lindex $splitLine 0]
		}
		if {![dict exists $returnDict "tx"] || ![dict exists $returnDict "tx"]} { 
			error "no tx / rx data, make sure that the device you specified exists"
		}
		return $returnDict
	}
	
	# calculates the netspeed
	proc calculateNetspeed {last current interval} {
		variable conf
		set difference [expr {$current * 1.0 - $last}]
		if {$difference < 0} { return 0 }
		return [expr {$difference/$interval / 1024}]
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
					"-device" {
						if {[isInitialized $w]} { error "Device cannot be changed after widget initialization" }
					}
					"-updateinterval" {
						if {[isInitialized $w]} { error "Updateinterval cannot be changed after widget initialization" }
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
	# Widget configuration procs
	#
	
	proc changeForegroundColor {w color} {
		${w}.network configure -fg $color
	}
	
	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		${w}.network configure -bg $color
	}
	
	proc changeFont {w font} {
		${w}.network configure -font $font
	}
}
