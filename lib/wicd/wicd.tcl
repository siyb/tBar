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
		set wirelessInfo [collectDataForAllWirelessNetworks]
		foreach network $wirelessInfo {
			set networkPath $sys($w,networkWindow).[dict get $network id]

			set networkFrame [frame ${networkPath}]
			grid [label ${networkPath}.name -anchor w -text "essid: [dict get $network ssid]"] -column 0
			grid [label ${networkPath}.quality -anchor w -text "quality: [dict get $network quality]"] -row 0 -column 1

			grid $networkFrame
		}

		positionWindowRelativly $sys($w,networkWindow) $w
	}

	proc updateWidget {w} {
		variable sys

		set currentNetworkId [getWirelessCurrentNetworkId]
		set quality [getQualityFor $currentNetworkId]
		log "INFO" "Connected to network $currentNetworkId, updating signal strength accordingly ($quality)."
		set sys($w,signalStrength) $quality
		drawSignalStrength $w
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
			-fill [getColorBySignalStrength $w]]

		set sys($w,signalStrengthTextId) [$sys($w,canvas) create text \
			[expr {$canvasWidth / 2}] [expr {$canvasHeight / 2}] \
			-text $sys($w,signalStrength) \
			-font $sys($w,font) \
			-fill $sys($w,foreground)]
	}

	proc getColorBySignalStrength {w} {
		variable sys
		if {$sys($w,signalStrength) > 70} {
			return $sys($w,gc,goodSignal)
		} elseif {$sys($w,signalStrength > 40} {
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
