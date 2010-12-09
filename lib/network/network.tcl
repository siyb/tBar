package provide network 1.2

package require statusBar
package require util

proc network {w args} {
	geekosphere::tbar::widget::network::makeNetwork $w $args

	proc $w {args} {
		geekosphere::tbar::widget::network::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

catch { namespace import ::geekosphere::tbar::util::* }
namespace eval geekosphere::tbar::widget::network {
	
	if {$::tcl_platform(os) eq "Linux"} {
		set sys(netInfo) [file join / proc net dev]
	} else {
		error "Network widget does not support your OS ($::tcl_platform(os)) yet. Please report this issue to help improove the software."
	}
	

	proc makeNetwork {w arguments} {
		variable sys
		if {[set sys($w,device) [getOption "-device" $arguments]] eq ""} { error "Specify a device using the -device option." }
		if {[set sys($w,updateInterval) [getOption "-updateinterval" $arguments]] eq ""} { error "Specify an update interval using the -updateinterval option." }
		set sys($w,additionalDevices) [getOption "-additionalDevices" $arguments]
		set sys($w,originalCommand) ${w}_

		frame ${w}
		pack [label ${w}.network -anchor w] -side left -fill both

		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_

		# run configuration
		action $w configure $arguments
		
		set sys($w,initialized) 1
		
		# the location of the info window
		set sys($w,infoWindow) ${w}.infoWindow
		
		# the data of all devices
		set sys($w,allDeviceData) [list]

		bind ${w}.network <Button-1> [namespace code [list actionHandler $w %W]]
	}

	proc isInitialized {w} {
		variable sys
		return [info exists sys($w,initialized)]
	}
	
	proc updateWidget {w} {
		variable sys
		updateAllDevices $w
		set netDict [getDeviceData $w $sys($w,device)]
		set tx [dict get $netDict "TX"]
		set rx [dict get $netDict "RX"]
		${w}.network configure -text "$sys($w,device) - Up: ${tx} kB/s Down: ${rx} kB/s"
		updateInfoWindow $w $sys($w,additionalDevices)
	}

	proc updateInfoWindow {w deviceList} {
		variable sys
		foreach device $deviceList {
		set netDict [getDeviceData $w $device];# even if there is no info window open, we still wanna update all devices which are being watched
			set tx [dict get $netDict "TX"]
			set rx [dict get $netDict "RX"]
			if {![winfo exists $sys($w,infoWindow)]} { continue }
			if {[winfo exists $sys($w,infoWindow).${device}]} {
				$sys($w,infoWindow).${device} configure -text "$device - Up: ${tx} kB/s Down: ${rx} kB/s" -fg $sys($w,foreground) -bg $sys($w,background)
			} else {
				pack [label $sys($w,infoWindow).${device} -text "$device - Up: ${tx} kB/s Down: ${rx} kB/s" -fg $sys($w,foreground) -bg $sys($w,background)] -anchor w
			}
		}
	}

	proc drawInfoWindow {w deviceList} {
		variable sys
		if {[llength $sys($w,additionalDevices)] == 0} { return }
		toplevel $sys($w,infoWindow) -background $sys($w,background)
		updateInfoWindow $w $deviceList
		positionWindowRelativly $sys($w,infoWindow) $w
	}
		
	proc destroyInfoWindow {w} {
		variable sys
		destroy $sys($w,infoWindow)	
	}

	proc actionHandler {w invokerWindow} {
		variable sys
		if {[winfo exists $sys($w,infoWindow)]} {
			destroyInfoWindow $w
		} else {
			drawInfoWindow $w $sys($w,additionalDevices)
		}
	}

	proc updateAllDevices {w} {
		variable sys
		set sys($w,allDeviceData) [list];# reset list
		set mainDeviceData [getNetworkSpeedFor $w $sys($w,device)]
		lappend sys($w,allDeviceData) [list $sys($w,device) $mainDeviceData]
		foreach device $sys($w,additionalDevices) {
			if {[lsearch -index 0 $sys($w,allDeviceData) $device] != -1} { continue };# do not update the same device twice!
			lappend sys($w,allDeviceData) [list $device [getNetworkSpeedFor $w $device]]
		}
	}

	proc getDeviceData {w device} {
		variable sys
		set position [lsearch -index 0 $sys($w,allDeviceData) $device]
		if {$position == -1} { error "Device could not be found in list: $device" }
		return [lindex $sys($w,allDeviceData) $position 1]
	}

	# calling this proc async to the update time will cause erroneous netspeed calculations, use with care ;)
	proc getNetworkSpeedFor {w device} {
		variable sys
		if {![info exists sys($w,lastTx,$device)]} {  
			set sys($w,lastTx,$device) 0
		}
		if {![info exists sys($w,lastRx,$device)]} {
			set sys($w,lastRx,$device) 0
		}
		set netDict [parseNetworkSpeed $device]
		set returnDict [dict create]
		set rx [dict get $netDict "rx"]
		set tx [dict get $netDict "tx"]
		if {$sys($w,lastTx,$device) == 0} {
			dict set returnDict "TX" "N/A"
		} else {
			dict set returnDict "TX" [::tcl::mathfunc::round [calculateNetspeed $sys($w,lastTx,$device) $tx $sys($w,updateInterval)]]
		}
		if {$sys($w,lastRx,$device) == 0} {
			dict set returnDict "RX" "N/A"
		} else {
			dict set returnDict "RX" [::tcl::mathfunc::round [calculateNetspeed $sys($w,lastRx,$device) $rx $sys($w,updateInterval)]]
		}
		set sys($w,lastTx,$device) $tx
		set sys($w,lastRx,$device) $rx
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
					"-additionalDevices" {
						 if {[isInitialized $w]} { error "Additional devices cannot be changed after widget initialization" }
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
		variable sys
		${w}.network configure -fg $color
		set sys($w,foreground) $color
	}
	
	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		${w}.network configure -bg $color
		set sys($w,background) $color
	}
	
	proc changeFont {w font} {
		variable sys
		${w}.network configure -font $font
	}
}
