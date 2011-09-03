package provide weather 1.0

proc weather {w args} {
	geekosphere::tbar::widget::weather::makeWeather $w $args

	proc $w {args} {
		geekosphere::tbar::widget::weather::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

catch { namespace import ::geekosphere::tbar::util::* }
namespace eval geekosphere::tbar::widget::weather {

	proc makeNotify {w arguments} {
		variable sys
		set sys($w,originalCommand) ${w}_

		# rename widget so that it will not receive commands
		uplevel #0 rename $w ${w}_

		# run configuration
		action $w configure $arguments

		# mark the widget as initialized
		set sys($w,initialized) 1
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
					"-font" {
						changeFont $w $value
					}
					"-height" {
						changeHeight $w $value
					}
					"-width" {
						changeWidth $w $value
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
	# Widget configuration procs
	#

	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		#${w}.displayLabel configure -bg $color
	}

	proc changeForegroundColor {w color} {
		variable sys
		#${w}.displayLabel configure -fg $color
	}

	proc changeFont {w font} {
		variable sys
		#${w}.displayLabel configure -font $font
	}

	proc changeHeight {w height} {
		variable sys
		$sys($w,originalCommand) configure -height $height
	}

	proc changeWidth {w width} {
		variable sys
		$sys($w,originalCommand) configure -width $width
	}
}
