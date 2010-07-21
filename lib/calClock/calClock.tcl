package provide calClock 1.1

package require callib
package require util
package require logger

proc calClock {w args} {
	geekosphere::tbar::widget::calClock::makeCalClock $w $args

	proc $w {args} {
		geekosphere::tbar::widget::calClock::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

namespace import ::geekosphere::tbar::util*
namespace import ::geekosphere::tbar::util::logger*
namespace eval geekosphere::tbar::widget::calClock {
	initLogger
	
	proc makeCalClock {w arguments} {
		variable sys
		set sys($w,ical) 1
		set sys($w,ical) [string is true -strict [getOption "-ical" $arguments]]
		if {$sys($w,ical)} {
			package require icalCalClock
		}
		
		set sys($w,originalCommand) ${w}_
		set sys($w,timeDateFormat) "%+"
		
		set sys($w,background) "grey"
		set sys($w,foreground) "black"
		set sys($w,calcolor,hover) "yellow"
		set sys($w,calcolor,clicked) "red"
		set sys($w,calcolor,today)  "blue"
		set sys($w,useCommand) 0
		set sys($w,command) -1
		set sys($w,storedMonth) -1
		set sys($w,storedYear) -1
		set sys($w,cacheDate) 0
		set sys($w,withdrawn) 0
		
		frame ${w}
		pack [label ${w}.clock] -side left
		
		# bindings
		bind ${w}.clock <Button-1> [namespace code [list actionHandler $w %W]]
		
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
					"-command" {
						changeCommand $w $value
					}
					"-cachedate" {
						changeCacheDate $w $value
					}
					"-ical" {
						if {[isInitialized $w]} { error "ical cannot be changed after widget initialization" }
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
	# GENERAL PROCEDURES
	#
	
	# gets the time and date according to the specified format
	proc timeDate {w} {
		variable sys
		return [clock format [clock seconds] -format $sys($w,timeDateFormat)]
	}
	
	proc calCallback {args} {
		set year [lindex $args 0]
		set month [lindex $args 1]
		set day [lindex $args 2]
		set dayString [lindex $args 3]
		set column [lindex $args 4]
		set row [lindex $args 5]
		log "DEBUG" "Klicked: year: $year month: $month day: $day - $dayString column: $column row: $row"
	}

	proc actionHandler {w invokerWindow} {
		variable sys
		drawCalendarWindow $w
	}

	# create a calendar window
	proc drawCalendarWindow {w} {
		variable sys
		set sys($w,calWin) ${w}.calendar
		if {[winfo exists $sys($w,calWin)]} {
			destroy $sys($w,calWin)
			return 
		}
		
		# command rendering
		if {$sys($w,useCommand)} { 
			renderWithCommand $w
		
		# standard calendar
		} else {
			renderWithCalendar $w
		}
		
		positionWindowRelativly $sys($w,calWin) $w
	}
	
	
	#
	# CALENDAR RENDERING PROCEDURES
	#
	
	proc renderWithCommand {w} {
		variable sys
		toplevel $sys($w,calWin) -bg $sys($w,background)
		pack [label $sys($w,calWin).display \
			-bg $sys($w,background) \
			-fg $sys($w,foreground) \
			-font [font create -family "nimbus mono"] \
			-justify left \
			-text [string map { " " "  " } [eval $sys($w,command)]]
		] -fill both
	}
	
	proc renderWithCalendar {w} {
		variable sys
		
		set currentYear [clock format [clock seconds ] -format "%Y" ]
		set currentMonth [clock format [clock seconds ] -format "%N" ]
		toplevel $sys($w,calWin) -bg $sys($w,background)
		pack [frame $sys($w,calWin).navigate -bg $sys($w,background)]
		pack [spinbox $sys($w,calWin).navigate.month \
			-background		$sys($w,background)\
			-foreground		$sys($w,foreground) \
			-activebackground	$sys($w,calcolor,hover) \
			-from			1 \
			-to				12 \
			-width			10 \
			-increment		1 \
			-command		[list geekosphere::tbar::widget::calClock::updateWrapper $w]
		] -side left -fill x -expand 1
		
		pack [spinbox $sys($w,calWin).navigate.year \
			-background		$sys($w,background)\
			-foreground		$sys($w,foreground) \
			-activebackground	$sys($w,calcolor,hover) \
			-from			[expr {$currentYear - 100}] \
			-to				[expr {$currentYear + 100}] \
			-width			12 \
			-increment		1 \
			-command		[list geekosphere::tbar::widget::calClock::updateWrapper $w]
			
		] -side right -fill x -expand 1

		if {$sys($w,storedYear) != -1 && $sys($w,storedMonth) != -1 && $sys($w,cacheDate)} {
			$sys($w,calWin).navigate.year set $sys($w,storedYear)
			$sys($w,calWin).navigate.month set $sys($w,storedMonth)
		} else {
			$sys($w,calWin).navigate.year set $currentYear
			$sys($w,calWin).navigate.month set $currentMonth
		}
		
		# render calendar with current date if no month and year have been stored or if caching is disabled
		if {($sys($w,storedYear) == -1 && $sys($w,storedMonth) == -1) || !$sys($w,cacheDate)} {
			drawCalendar $w $currentYear $currentMonth
			setStoredDate $w $currentYear $currentMonth
			
		# otherwise render calendar with stored values
		} else {
			drawCalendar $w $sys($w,storedYear) $sys($w,storedMonth)
		}
		
		if {$sys($w,ical)} {
			pack [button $sys($w,calWin).importIcal  \
				-background		$sys($w,background)\
				-foreground		$sys($w,foreground) \
				-activebackground	$sys($w,background) \
				-activeforeground	$sys($w,foreground) \
				-text				"Import ICalendar" \
				-command		 [list geekosphere::tbar::widget::calClock::importButtonProcedure $w] \
			] -side bottom -fill x
		}
	}
	
	proc drawCalendar {w year month} {
		variable sys
		if {[winfo exists $sys($w,calWin).cal] && !$sys($w,withdrawn)} {
			#destroy $sys($w,calWin).cal
			wm withdraw $sys($w,calWin).cal
			set sys($w,withdrawn) 1
			puts withdraw
			return
		} elseif {$sys($w,withdrawn)} {
			wm iconify $$sys($w,calWin).cal
			set sys($w,withdrawn) 0
			puts iconify
			return
		}
		
		pack [calwid $sys($w,calWin).cal \
			-font				{ helvetica 10 bold } \
			-dayfont			{ Arial 10 bold } \
			-background		$sys($w,background)\
			-foreground		$sys($w,foreground) \
			-activebackground	$sys($w,calcolor,hover) \
			-clickedcolor		$sys($w,calcolor,clicked) \
			-startsunday		0 \
			-delay			10 \
			-daynames		{Su Mo Tu Wed Th Fr Sa} \
			-month			$month \
			-year			$year \
			-relief 			groove \
			-balloon			true \
			-callback			geekosphere::tbar::widget::calClock::calCallback
		]
		
		# TODO: this is _very_slow with loads of appointments, circumvent redrawing!
		# mark calendar appointments
		log "DEBUG" "Calendar loaded in: [time { importCalendarData $w }]"
		puts imported
		
		# mark today
		$sys($w,calWin).cal configure -mark [eval list [clock format [clock seconds ] -format "%e %N %Y 1 $sys($w,calcolor,today) { Today }" ]]
	}
	
	proc renderImportDialog {} {
		return [tk_getOpenFile \
			-title "Choose ICalendar file" \
			-initialdir $::env(HOME) \
			-multiple false \
			-filetypes {
				{{Calendar Data Exchange ical} {.ical}}
				{{Calendar Data Exchange ics} {.ics}}
				{{Calendar Data Exchange ifb} {.ifb}}
				{{Calendar Data Exchange icalendar} {.icalendar}}
				{{All Files} {*}}
			}]
	}
	
	proc updateWrapper {w} {
		variable sys
		set year [$sys($w,calWin).navigate.year get]; set month [$sys($w,calWin).navigate.month get]
		set monthYear -1
		
		if {$year < $sys($w,storedYear)} {
			set monthYear [$sys($w,calWin).cal prevyear]
		} elseif {$year > $sys($w,storedYear)} {
			set monthYear [$sys($w,calWin).cal nextyear]
		}
		if {$month < $sys($w,storedMonth)} {
			set monthYear [$sys($w,calWin).cal prevmonth]
		} elseif {$month > $sys($w,storedMonth)} {
			set monthYear [$sys($w,calWin).cal nextmonth]
		}
		
		if {$monthYear == -1} { return }
		setStoredDate $w [lindex $monthYear 0] [lindex $monthYear 1]
	}
	
	proc setStoredDate {w year month} {
		variable sys
		set sys($w,storedYear) $year
		set sys($w,storedMonth) $month
	}
	
	#
	# APPOINTMENT RELATED PROCEDURES (ICAL / MARKING)
	#
	
	proc importButtonProcedure {w} {
		variable sys
		if {!$sys($w,ical)} { return }
		geekosphere::tbar::widget::calClock::storeCalendarData [geekosphere::tbar::widget::calClock::renderImportDialog]
		geekosphere::tbar::widget::calClock::importCalendarData $w
	}
	
	proc storeCalendarData {icalFile} {
		variable sys
		if {$icalFile eq ""} { log "TRACE" "User cancelled import"; return }
		if {![file exists $icalFile]} { error "ICalfile does not exist, this should not happen" }
		set tbarHome [file join $::env(HOME) .tbar]
		if {![file exists $tbarHome]} { log "WARNING" "You can't import ical data if you don't have a .tbar directory in you homedir"; return }
		if {![file isdirectory $tbarHome]} { error "$tbarHome is a file and not a directory!" }
		geekosphere::tbar::widget::calClock::ical::ical2database $icalFile
	}
	
	proc importCalendarData {w} {
		variable sys
		if {!$sys($w,ical)} { return }
		$sys($w,calWin).cal configure -unmarkall
		if {[set calData [geekosphere::tbar::widget::calClock::ical::getICalEntries]] == -1} { return };# no calendar data to load
		foreach entry $calData {
			markAppointmentInCalendar $w $entry
		}
	}
	
	proc markAppointmentInCalendar {w veventDict} {
		variable sys
		if {!$sys($w,ical)} { return }
		if {![dict exists $veventDict dtstart] || ![dict exists $veventDict dtend] || ![dict exists $veventDict summary]} {
			log "WARNING" "Malformed ICalendar entry, dtstart, dtend and summary required: $veventDict"
			return
		}
		set dtStart [dateTimeParser [dict get $veventDict dtstart]]
		set dtEnd [dateTimeParser [dict get $veventDict dtend]]
		set summary [dict get $veventDict summary]
		
		set format "%e %N %Y 1 green { %H:%M:%S - $summary }"
		set mark [eval list [clock format [dict get $dtStart sinceEpoch] -format $format]]
		$sys($w,calWin).cal configure -mark $mark
		log "DEBUG" "'$mark' has been added to the calendar"
	}
	
	proc dateTimeParser {dateTime} {
		variable sys
		set length [string length $dateTime]
		set retDict [dict create]
		
		# floating: 19980118T230000
		if {$length == 15} {
			dict set retDict type 0
			dict set retDict sinceEpoch [clock scan $dateTime -format "%Y%m%dT%H%M%S"]
			
		# utc: 19980119T070000Z
		} elseif {$length == 16} {
			dict set retDict type 1
			dict set retDict sinceEpoch [clock scan $dateTime -format "%Y%m%dT%H%M%SZ"]
		
		# TODO: implement this datetime format!
		# local: TZID=America/New_York:19980119T020000
		} else {
			error "Time/Date Format not supported yet: $dateTime"
			set splitALL [split $dateTime "=:"]
			if {[llength $splitALL] != 3} { error "LOCAL: Malformed date time: $dateTime" }
			set splitDT [split [lindex $splitDT 2] "T"]
			if {[llength $splitDT] != 2} { error "LOCAL: Malformed date time: $dateTime" }
			
			dict set retDict type 2
			dict set retDict timeZone [lindex $splitALL 1]
			dict set retDict date [lindex $splitDT 0] 
			dict set retDict time [lindex $splitDT 1] 
		}
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
	
	proc changeCommand {w command} {
		variable sys
		set sys($w,useCommand) 1
		set sys($w,command) $command
	}
	
	proc changeCacheDate {w cache} {
		variable sys
		set sys($w,cacheDate) $cache
	}
}


