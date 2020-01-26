package provide networkmanager 1.0

if {![info exist geekosphere::tbar::packageloader::available]} {
	package require tbar_logger
	package require BWidget
}

proc networkmanager {w args} {
	if {[geekosphere::tbar::widget::networkmanager::makeNetworkManager $w $args] == -1} {
		return -1
	}

	proc $w {args} {
		geekosphere::tbar::widget::networkmanager::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}
catch {namespace import ::geekosphere::tbar::util::logger::* }

namespace eval geekosphere::tbar::widget::networkmanager {
	initLogger

	proc makeNetworkManager {w arguments} {
		variable sys

		set driverPackage [getOption "-driverPackage" $arguments]
		if {$driverPackage == ""} {
			error "No -driverPackage set"
		}
		set driverNameSpace [getOption "-driverNameSpace" $arguments]
		if {$driverNameSpace == ""} {
			error "No -driverNameSpace set"
		}

		package require $driverPackage

		if {![namespace exists $driverNameSpace]} {
			error "-driveNamespace not found ${driverNameSpace}"
		}

		namespace import "${driverNameSpace}::*"

		connect

		set sys($w,originalCommand) ${w}_
		set sys($w,networkWindow) ${w}.networkWindow
		set sys($w,networkDetailWindow) ${w}.networkDetailWindow
		dict set sys($w,networkDetailCurrentNetwork) id -1
		set sys($w,signalStrength) 0
		set sys($w,signalStrengthId) -1
		set sys($w,signalStrengthTextId) -1
		set sys($w,gc,goodSignal) green
		set sys($w,gc,mediumSignal) yellow
		set sys($w,gc,badSignal) red
		set sys($w,background) black

		frame ${w}
		uplevel #0 rename $w ${w}_

		set sys($w,canvas) [canvas ${w}.canvas -bg $sys($w,background)]
		pack $sys($w,canvas)

		foreach window [returnNestedChildren $w] {
			bind $window <Button-1> [namespace code [list showNetworkWindow $w]]
		}
		
		action $w configure $arguments
	
		set sys($w,initialized) 1

		initLogger
	}

	proc isInitialized {w} {
		variable sys
		return [info exists sys($w,initialized)]
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
					"-gss" {
						changeGraphicsColorGoodSignal $w $value
					}
					"-mss" {
						changeGraphicsColorMediumSignal $w $value
					}
					"-bss" {
						changeGraphicsColorBadSignal $w $value
					}
					"-driverPackage" {
						if {[isInitialized $w]} { error "cannot set -driverPackage after widget was initialized" }
					}
					"-driverNameSpace" {
						if {[isInitialized $w]} { error  "cannot set -driverNameSpace after widget was initialized" }
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

	proc showNetworkWindow {w} {
		variable sys
		if {[winfo exists $sys($w,networkWindow)]} {
			destroy $sys($w,networkWindow)
			return
		} else {
			toplevel $sys($w,networkWindow)
		}
		$sys($w,networkWindow) configure -bg $sys($w,background)
		set wirelessInfo [collectDataForAllWirelessNetworks]
		set currentNetworkId [getWirelessCurrentNetworkId]

		set sw [ScrolledWindow $sys($w,networkWindow).sw \
			-bg $sys($w,background)]
		grid $sw -sticky nswe

		set sf [ScrollableFrame ${sw}.sf \
			-height [expr {[winfo screenheight .] / 2}] \
			-bg $sys($w,background)]
		grid $sf -sticky nswe

		$sw setwidget $sf
		set root [$sf getframe]

		foreach network $wirelessInfo {

			set networkPath $root.[dict get $network id]
			grid [frame $networkPath -bg $sys($w,background)] -sticky nswe
			set quality [dict get $network quality]

			grid [label ${networkPath}.name \
				-text "essid: [dict get $network ssid]" \
				-font $sys($w,font) \
				-fg $sys($w,foreground) \
				-bg $sys($w,background)] -sticky w -columnspan 2

			grid [label ${networkPath}.quality \
				-text "quality: $quality" \
				-font $sys($w,font) \
				-fg [getColorBySignalStrength $w $quality] \
				-bg $sys($w,background)] -sticky w -columnspan 2

			barChart ${networkPath}.barChart \
				-height $sys($w,height) \
				-fg $sys($w,foreground) \
				-bg $sys($w,background) \
				-font $sys($w,font) \
				-gc  "green" \
				-width 300

			grid ${networkPath}.barChart -sticky ew -columnspan 2

			set connected [expr [dict get $network id] == $currentNetworkId]
			if {$connected} {
				set buttonText "Disconnect"
			} else {
				set buttonText "Connect"
			}

			button ${networkPath}.connect \
				-text $buttonText \
				-font $sys($w,font) \
				-fg $sys($w,foreground) \
				-bg $sys($w,background) \
				-command [list geekosphere::tbar::widget::networkmanager::handleConnection $w $network $connected]

			button ${networkPath}.configure \
				-text "Configure" \
				-font $sys($w,font) \
				-fg $sys($w,foreground) \
				-bg $sys($w,background) \
				-command [list geekosphere::tbar::widget::networkmanager::showNetworkDetail $w $network]

			grid ${networkPath}.connect ${networkPath}.configure -sticky ew
		}

		positionWindowRelativly $sys($w,networkWindow) $w
	}

	proc handleConnection {w network connected} {
		if {$connected} {			
			disconnectWireless
		} else {

		}
	}

	proc showNetworkDetail {w network} {
		variable sys
		if {[winfo exists $sys($w,networkDetailWindow)]} {
			destroy $sys($w,networkDetailWindow)
			if {[dict get $sys($w,networkDetailCurrentNetwork) id] == [dict get $network id]} {
				set sys($w,networkDetailCurrentNetwork) $network
				return
			}
		}
		set sys($w,networkDetailCurrentNetwork) $network
		set f $sys($w,networkDetailWindow).frame
		toplevel $sys($w,networkDetailWindow)
		wm title $sys($w,networkDetailWindow) "Network Detail"
		wm attributes $sys($w,networkDetailWindow) -type dialog
		pack [frame $f -bg $sys($w,background)] -fill both -expand 1
		set ip [getWirelessIp]
		grid [label ${f}.name \
			-text "essid: [dict get $network ssid]" \
			-font $sys($w,font) \
			-fg $sys($w,foreground) \
			-bg $sys($w,background)] -columnspan 1 -sticky w
		grid [label ${f}.bssid \
			-text "mac: [dict get $network bssid]" \
			-font $sys($w,font) \
			-fg $sys($w,foreground) \
			-bg $sys($w,background)] -columnspan 1 -sticky w
		grid [label ${f}.channel \
			-text "channel: [dict get $network channel]" \
			-font $sys($w,font) \
			-fg $sys($w,foreground) \
			-bg $sys($w,background)] -columnspan 1 -sticky w
		grid [label ${f}.encryption \
			-text "encryption: [dict get $network encryptionMode]" \
			-font $sys($w,font) \
			-fg $sys($w,foreground) \
			-bg $sys($w,background)] -columnspan 1 -sticky w
		grid [label ${f}.mode \
			-text "mode: [dict get $network mode]" \
			-font $sys($w,font) \
			-fg $sys($w,foreground) \
			-bg $sys($w,background)] -columnspan 1 -sticky w
		label ${f}.key \
			-text "key:" \
			-font $sys($w,font) \
			-fg $sys($w,foreground) \
			-bg $sys($w,background)
		set sys($w,key,[dict get $network id]) ""
		entry ${f}.keyEntry \
			-fg $sys($w,foreground) \
			-bg $sys($w,background) \
			-font $sys($w,font) \
			-textvariable ::geekosphere::tbar::widget::networkmanager::sys($w,key,[dict get $network id])
		grid ${f}.key ${f}.keyEntry -sticky w
		button ${f}.save \
			-text "save" \
			-fg $sys($w,foreground) \
			-bg $sys($w,background) \
			-font $sys($w,font) \
			-command [list ::geekosphere::tbar::widget::networkmanager::saveNetwork $w $network]
		button ${f}.cancel \
			-text "cancel" \
			-fg $sys($w,foreground) \
			-bg $sys($w,background) \
			-font $sys($w,font) \
			-command [list ::geekosphere::tbar::widget::networkmanager::destroyDetailWindow $w]
		grid ${f}.save ${f}.cancel -sticky ew

	}

	proc saveNetwork {w network} {
		variable sys
		set key $sys($w,key,[dict get $network id])
		set sys($w,key,[dict get $network id]) ""
		puts $key
		destroy $sys($w,networkDetailWindow)
	}

	proc destroyDetailWindow {w} {
		variable sys
		destroy $sys($w,networkDetailWindow)
	}

	proc updateWidget {w} {
		variable sys

		set currentNetworkId [getWirelessCurrentNetworkId]
		set quality [getQualityFor $currentNetworkId]
		log "INFO" "Connected to network $currentNetworkId, updating signal strength accordingly ($quality)."
		set sys($w,signalStrength) $quality
		drawSignalStrength $w
		log "TRACE" "IWCONFIG: [getIwConfig]"
		recordWirelessStrengthHistory $w
		# TODO: if the detail window is open, rerender all networks!
		renderSignalHistoryIfNetworkWindowIsOpen $w
	}

	proc recordWirelessStrengthHistory {w} {
		variable sys
		foreach wireless [collectDataForAllWirelessNetworks] {
			set quality [dict get $wireless quality]
			set id [dict get $wireless id]
			if {![info exists sys($w,history,strength,$id)]} {
				set sys($w,history,strength,$id) [::geekosphere::tbar::simplerle::simplerle new]
			}
			$sys($w,history,strength,$id) add [dict get $wireless quality].0
			log "TRACE" "Added $quality to $id"
		}
	}

	proc renderSignalHistoryIfNetworkWindowIsOpen {w} {
		variable sys
		if {[winfo exists $sys($w,networkWindow)]} {
			foreach network [collectDataForAllWirelessNetworks] {
				set id [dict get $network id]
				log "TRACE" "Trying to render history for $id"
				set barchart $sys($w,networkWindow).sw.sf.frame.${id}.barChart
				if {[info exists sys($w,history,strength,$id)] && [winfo exists $barchart]} {
					set decompressed [$sys($w,history,strength,$id) decompress]
					log "TRACE" "Rendering history for $id in $barchart -> $decompressed"
					$barchart setValues $decompressed
					$barchart update
				}
			}
		}
	}

	proc drawSignalStrength {w} {
		variable sys
		if {$sys($w,signalStrengthId) != -1} {
			$sys($w,canvas) delete $sys($w,signalStrengthId)
		}
		if {$sys($w,signalStrengthTextId) != -1} {
			$sys($w,canvas) delete $sys($w,signalStrengthTextId)
		}
		set canvasHeight [winfo height $sys($w,canvas)]
		set canvasWidth [winfo width $sys($w,canvas)]
		if {$canvasHeight == 1} {
			return
		}
		set heightOfSignalStrength [expr {($canvasHeight * $sys($w,signalStrength) / 100)}]
		log "INFO" "canvasHeight: $canvasHeight canvasWidth: $canvasWidth heightOfSignalStrength: $heightOfSignalStrength ($sys($w,signalStrength))"

		set sys($w,signalStrengthId) [$sys($w,canvas) create rectangle \
				0 $canvasHeight \
				$canvasWidth [expr {$canvasHeight - $heightOfSignalStrength}] \
			-fill [getCurrentColorBySignalStrength $w]]

		set sys($w,signalStrengthTextId) [$sys($w,canvas) create text \
			[expr {$canvasWidth / 2}] [expr {$canvasHeight / 2}] \
			-text $sys($w,signalStrength) \
			-font $sys($w,font) \
			-fill $sys($w,foreground)]
	}

	proc getCurrentColorBySignalStrength {w} {
		variable sys
		return [getColorBySignalStrength $w $sys($w,signalStrength)]
	}

	proc getColorBySignalStrength {w ss} {
		variable sys
		if {$ss > 70} {
			return $sys($w,gc,goodSignal)
		} elseif {$ss > 40} {
			return $sys($w,gc,mediumSignal)
		} else {
			return $sys($w,gc,badSignal)
		}
	}

	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		$sys($w,canvas) configure -bg $color
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
		$sys($w,canvas) configure -width $width
	}

	proc changeHeight {w height} {
		variable sys
		set sys($w,height) $height
		$sys($w,originalCommand) configure -height $height
		$sys($w,canvas) configure -height $height
	}

	proc changeGraphicsColorGoodSignal {w color} {
		variable sys
		set sys($w,gc,goodSignal) $color
	}

	proc changeGraphicsColorMediumSignal {w color} {
		variable sys
		set sys($w,gc,mediumSignal) $color
	}

	proc changeGraphicsColorBadSignal {w color} {
		variable sys
		set sys($w,gc,badSignal) $color
	}
}
