package provide txt 1.1

proc txt {w args} {
	geekosphere::tbar::widget::txt::makeTxt $w $args

	proc $w {args} {
		geekosphere::tbar::widget::txt::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

namespace eval geekosphere::tbar::widget::txt {

	proc makeTxt {w args} {
		variable sys
		frame ${w}
		pack [label ${w}.display] -fill both
		
		set sys($w,originalCommand) ${w}_
		
		# stores command to be executed
		set sys($w,command) ""
		
		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_
		
		# run configuration
		action $w configure [join $args]
	}
	
	proc updateWidget {w} {
		variable sys
		if {$sys($w,command) ne ""} {
			${w}.display configure -text [eval $sys($w,command)]
		}
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
					"-text" {
						changeText $w $value
					}
					"-textvariable" {
						changeTextVariable $w $value
					}
					"-command" {
						changeCommand $w $value
					}
					"-width" {
						changeWidth $w $value
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
		${w}.display configure -fg $color
	}
	
	proc changeBackgroundColor {w color} {
		${w}.display configure -bg $color
	}
	
	proc changeText {w text} {
		${w}.display configure -text $text
	}
	
	proc changeTextVariable {w textvariable} {
		${w}.display configure -textvariable $textvariable
	}
	
	proc changeWidth {w width} {
		variable sys
		$sys($w,originalCommand) configure -width $width
		${w}.display configure -width $width
	}
	
	proc changeCommand {w command} {
		variable sys
		set sys($w,command) $command
	}
	
	proc changeFont {w font} {
		${w}.display configure -font $font
	}
}
