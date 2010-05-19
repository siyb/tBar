package provide calClock 1.1

package require callib
package require util

proc calClock {w args} {
	geekosphere::tbar::widget::calClock::makeCalClock $w $args

	proc $w {args} {
		geekosphere::tbar::widget::calClock::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

namespace eval geekosphere::tbar::widget::calClock {
	
	proc makeCalClock {w args} {
		variable sys
		
		bind Label <Button-1> [namespace code [list calWindow $w %W]]
		
		set sys($w,originalCommand) ${w}_
		set sys($w,timeDateFormat) "%+"
		
		set sys($w,background) "grey"
		set sys($w,foreground) "black"
		set sys($w,calcolor,hover) "yellow"
		set sys($w,calcolor,clicked) "red"
		set sys($w,calcolor,today)  "blue"
		
		frame ${w}
		pack [label ${w}.clock] -side left
		
		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_
		
		# run configuration
		action $w configure [join $args]
	}
	
	proc updateWidget {w} {
		${w}.clock configure -text [timeDate $w]
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
					"-format" {
						changeFormat $w $value
					}
					"-hovercolor" {
						changeHoverColor $w $value
					}
					"-clickedcolor" {
						changeClickedColor $w $value
					}
					"-todaycolor" {
						changeTodayColor $w $value
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
	
	# gets the time and date according to the specified format
	proc timeDate {w} {
		variable sys
		return [clock format [clock seconds] -format $sys($w,timeDateFormat)]
	}
	
	# create a calendar window
	# TODO 1.x: add possibility to enter appointments (balloon stuff)
	proc calWindow {w invokerWindow} {
		variable sys
		
		if {"$invokerWindow" ne "$w.clock"} { return }
		
		set calWin ${w}.calendar
		if {[winfo exists $calWin]} { 
			destroy $calWin
			return 
		}
		toplevel $calWin -bg $sys($w,background)
		pack [calwid ${calWin}.cal \
				-font			{ helvetica 10 bold } \
				-dayfont			{Arial 10 bold } \
				-background		$sys($w,background)\
				-foreground		$sys($w,foreground) \
				-activebackground	$sys($w,calcolor,hover) \
				-clickedcolor		$sys($w,calcolor,clicked) \
				-startsunday		0 \
				-delay			1000 \
				-daynames		{Su Mo Tu Wed Th Fr Sa} \
				-month			[clock format [clock seconds ] -format "%N" ] \
				-year			[clock format [clock seconds ] -format "%Y" ] \
				-relief 			groove \
			]
		# mark today
		${calWin}.cal configure -mark [eval list [clock format [clock seconds ] -format "%e %N %Y 1 $sys($w,calcolor,today) { Today }" ]]
		
		wm geometry $calWin [geekosphere::tbar::util::getNewWindowGeometry_ [winfo rootx $w]  [winfo rooty $w] 200 200 [winfo height $w] [winfo screenheight $w] [winfo screenwidth $w]]
		wm overrideredirect $calWin 1
	}
	
	#
	# Widget configuration procs
	#
	
	proc changeForegroundColor {w color} {
		variable sys
		${w}.clock configure -fg $color
		set sys($w,foreground) $color
	}
	
	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		${w}.clock configure -bg $color
		set sys($w,background) $color
	}
	
	proc changeHoverColor {w color} {
		variable sys
		set sys($w,calcolor,hover) $color
	}
	
	proc changeClickedColor {w color} {
		variable sys
		set sys($w,calcolor,clicked) $color
	}
	
	proc changeFormat {w format} {
		variable sys
		set sys($w,timeDateFormat) $format
	}
	
	proc changeTodayColor {w color} {
		variable sys
		set sys($w,calcolor,today) $color
	}
	
	proc changeFont {w font} {
		${w}.clock configure -font $font
	}
}


