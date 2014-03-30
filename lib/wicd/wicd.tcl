package provide wicd 1.0

if {![info exist geekosphere::tbar::packageloader::available]} {
	package require logger
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

		frame ${w}
		uplevel #0 rename $w ${w}_
		pack [label ${w}.mixer -text "|N|"]
		bind ${w}.mixer <Button-1> [namespace code [list showNetworkWindow $w]]

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
			grid [label ${networkPath}.name -justify left -text "essid: [dict get $network ssid]"] -column 0
			grid [label ${networkPath}.quality -justify left -text "quality: [dict get $network quality]"] -row 0 -column 1

			grid $networkFrame
		}

		positionWindowRelativly $sys($w,networkWindow) $w
	}

	proc updateWidget {w} {
		variable sys
	}

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

}