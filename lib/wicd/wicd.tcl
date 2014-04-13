package provide wicd 1.0

if {![info exist geekosphere::tbar::packageloader::available]} {
	package require logger
	package require wicd_dbus
}

proc wicd {w args} {
	if {[geekosphere::tbar::widget::wicd::makeWicd $w $args] == -1} {
		return -1
	}

	proc $w {args} {
		geekosphere::tbar::widget::wicd::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}
catch {namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::widget::wicd {
	initLogger

	proc makeWicd {w arguments} {
		variable sys

		# wicd dbus connection
		connect

		set sys($w,originalCommand) ${w}_
		set sys($w,networkWindow) ${w}.networkWindow
		set sys($w,networkDetailWindow) ${w}.networkDetailWindow
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
		foreach network $wirelessInfo {

			set networkPath $sys($w,networkWindow).[dict get $network id]

			set networkInfoPath ${networkPath}.info
			set networkControlPath ${networkPath}.control

			set quality [dict get $network quality]

			set networkFrame [frame ${networkPath} -bg $sys($w,background)]
			set infoFrame [frame ${networkInfoPath} -bg $sys($w,background)]
			set controlFrame [frame ${networkControlPath} -bg $sys($w,background)]

			grid $infoFrame -row 0
			grid $controlFrame -row 1

			grid [label ${networkInfoPath}.name \
				-text "essid: [dict get $network ssid]" \
				-font $sys($w,font) \
				-fg $sys($w,foreground) \
				-bg $sys($w,background)] -row 0 -column 0 -columnspan 1 -sticky w

			grid [label ${networkInfoPath}.quality \
				-text "quality: $quality" \
				-font $sys($w,font) \
				-fg [getColorBySignalStrength $w $quality] \
				-bg $sys($w,background)] -row 1 -column 0 -columnspan 1 -sticky w

			if {[dict get $network id] == $currentNetworkId} {
				set buttonText "Disconnect"
			} else {
				set buttonText "Connect"
			}

			grid [button ${networkControlPath}.connect \
				-text $buttonText \
				-font $sys($w,font) \
				-fg $sys($w,foreground) \
				-bg $sys($w,background) \
				-command [list puts $network]] -row 1 -column 0 -columnspan 1 -sticky w

			grid [button ${networkControlPath}.configure \
				-text "Configure" \
				-font $sys($w,font) \
				-fg $sys($w,foreground) \
				-bg $sys($w,background) \
				-command [list geekosphere::tbar::widget::wicd::showNetworkDetail $w $network]] -row 1 -column 1 -columnspan 1 -sticky e

			grid $infoFrame -sticky w
			grid $controlFrame -sticky w
			grid $networkFrame -sticky w
		}

		positionWindowRelativly $sys($w,networkWindow) $w
	}

	proc showNetworkDetail {w network} {
		variable sys
		if {[winfo exists $sys($w,networkDetailWindow)]} {
			destroy $sys($w,networkDetailWindow)
		} else {
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
				-text "mode: [dict get $network mode] : $ip" \
				-font $sys($w,font) \
				-fg $sys($w,foreground) \
				-bg $sys($w,background)] -columnspan 1 -sticky w

		}
	}

	proc updateWidget {w} {
		variable sys

		set currentNetworkId [getWirelessCurrentNetworkId]
		set quality [getQualityFor $currentNetworkId]
		log "INFO" "Connected to network $currentNetworkId, updating signal strength accordingly ($quality)."
		set sys($w,signalStrength) $quality
		drawSignalStrength $w
		log "TRACE" "IWCONFIG: [getIwConfig]"
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
