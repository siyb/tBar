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
		
		bind Label <Button-1> [namespace code [list actionHandler $w %W]]
		
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
	

	proc actionHandler {w invokerWindow} {
		variable sys
		
		if {"$invokerWindow" eq "${w}.clock"} {
			drawCalendarWindow $w
		}
	}

	# create a calendar window
	# TODO 1.x: add possibility to enter appointments (balloon stuff)
	proc drawCalendarWindow {w} {
		variable sys
		set currentYear [clock format [clock seconds ] -format "%Y" ]
		set currentMonth [clock format [clock seconds ] -format "%N" ]
		set calWin ${w}.calendar
		if {[winfo exists $calWin]} { 
			destroy $calWin
			return 
		}
		toplevel $calWin -bg $sys($w,background)
		pack [frame ${calWin}.navigate -bg $sys($w,background)]
		pack [spinbox ${calWin}.navigate.month \
			-background		$sys($w,background)\
			-foreground		$sys($w,foreground) \
			-activebackground	$sys($w,calcolor,hover) \
			-from			1 \
			-to				12 \
			-width			10 \
			-increment			1 \
			-command			[list geekosphere::tbar::widget::calClock::updateWrapper $w $calWin]
		] -side left -fill x -expand 1
		
		pack [spinbox ${calWin}.navigate.year \
			-background		$sys($w,background)\
			-foreground		$sys($w,foreground) \
			-activebackground	$sys($w,calcolor,hover) \
			-from			[expr {$currentYear - 100}] \
			-to				[expr {$currentYear + 100}] \
			-increment			1 \
			-command			[list geekosphere::tbar::widget::calClock::updateWrapper $w $calWin]
			
		] -side right -fill x -expand 1

		${calWin}.navigate.year set $currentYear
		${calWin}.navigate.month set $currentMonth
		
		drawCalendar $w $calWin $currentYear $currentMonth
		
		# mark today
		${calWin}.cal configure -mark [eval list [clock format [clock seconds ] -format "%e %N %Y 1 $sys($w,calcolor,today) { Today }" ]]
		
		wm geometry $calWin [geekosphere::tbar::util::getNewWindowGeometry_ [winfo rootx $w]  [winfo rooty $w] 200 200 [winfo height $w] [winfo screenheight $w] [winfo screenwidth $w]]
		wm overrideredirect $calWin 1
	}
	
	proc updateWrapper {w calWin} {
		drawCalendar $w $calWin [${calWin}.navigate.year get] [${calWin}.navigate.month get]
	}	
	
	proc drawCalendar {w calWin year month} {
		variable sys
		if {[winfo exists ${calWin}.cal]} {
			destroy ${calWin}.cal
		}
		pack [calwid ${calWin}.cal \
			-font				{ helvetica 10 bold } \
			-dayfont			{Arial 10 bold } \
			-background		$sys($w,background)\
			-foreground		$sys($w,foreground) \
			-activebackground	$sys($w,calcolor,hover) \
			-clickedcolor		$sys($w,calcolor,clicked) \
			-startsunday		0 \
			-delay			1000 \
			-daynames		{Su Mo Tu Wed Th Fr Sa} \
			-month			$month \
			-year				$year \
			-relief 			groove \
		]
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


