package provide calClock 1.1

package require callib
package require util
package require logger
package require ical

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
		
		frame ${w}
		pack [label ${w}.clock] -side left
		
		# bindings
		bind ${w}.clock <Button-1> [namespace code [list actionHandler $w %W]]
		
		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_
		
		# run configuration
		action $w configure $arguments
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
		drawCalendarWindow $w
	}

	# create a calendar window
	proc drawCalendarWindow {w} {
		variable sys
		set calWin ${w}.calendar
		if {[winfo exists $calWin]} { 
			destroy $calWin
			return 
		}
		
		# command rendering
		if {$sys($w,useCommand)} { 
			rederWithCommand $w $calWin
		
		# standard calendar
		} else {
			renderWithCalendar $w $calWin
		}
		
		positionWindowRelativly $calWin $w
	}

	# TODO 1.2: add possibility to enter appointments (balloon stuff)
	proc renderWithCalendar {w calWin} {
		variable sys
		
		set currentYear [clock format [clock seconds ] -format "%Y" ]
		set currentMonth [clock format [clock seconds ] -format "%N" ]
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
			-width			12 \
			-increment			1 \
			-command			[list geekosphere::tbar::widget::calClock::updateWrapper $w $calWin]
			
		] -side right -fill x -expand 1

		if {$sys($w,storedYear) != -1 && $sys($w,storedMonth) != -1 && $sys($w,cacheDate)} {
			${calWin}.navigate.year set $sys($w,storedYear)
			${calWin}.navigate.month set $sys($w,storedMonth)
		} else {
			${calWin}.navigate.year set $currentYear
			${calWin}.navigate.month set $currentMonth
		}
		
		# render calendar with current date if no month and year have been stored or if caching is disabled
		if {($sys($w,storedYear) == -1 && $sys($w,storedMonth) == -1) || !$sys($w,cacheDate)} {
			drawCalendar $w $calWin $currentYear $currentMonth
			
		# otherwise render calendar with stored values
		} else {
			drawCalendar $w $calWin $sys($w,storedYear) $sys($w,storedMonth)
		}
		
		pack [button ${calWin}.importIcal  \
			-background		$sys($w,background)\
			-foreground		$sys($w,foreground) \
			-activebackground	$sys($w,background) \
			-activeforeground	$sys($w,foreground) \
			-text				"Import ICalendar" \
			-command		{
				geekosphere::tbar::widget::calClock::storeCalendarData [geekosphere::tbar::widget::calClock::drawImportDialog]
				geekosphere::tbar::widget::calClock::importCalendarData $calWin
			}
		] -side bottom -fill x
		

		importCalendarData $calWin
	}
	
	proc setStoredDate {w year month} {
		variable sys
		set sys($w,storedYear) $year
		set sys($w,storedMonth) $month
	}
	
	proc updateWrapper {w calWin} {
		set year [${calWin}.navigate.year get]; set month [${calWin}.navigate.month get]
		drawCalendar $w $calWin $year $month
		setStoredDate $w $year $month
	}
	
	proc drawImportDialog {} {
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
	
	proc storeCalendarData {icalFile} {
		if {$icalFile eq ""} { log "TRACE" "User cancelled import"; return }
		if {![file exists $icalFile]} { error "ICalfile does not exist, this should not happen" }
		set tbarHome [file join $::env(HOME) .tbar]
		if {![file exists $tbarHome]} { log "WARNING" "You can't import ical data if you don't have a .tbar directory in you homedir"; return }
		if {![file isdirectory $tbarHome]} { error "$tbarHome is a file and not a directory!" }
		file copy -force $icalFile [file join $tbarHome calendar.ics];# copy and overwrite old ical imports (only one import can prevail!!!)
	}
	
	proc importCalendarData {calWin} {
		set tbarHome [file join $::env(HOME) .tbar]
		set calendarFile [file join $tbarHome calendar.ics]
		if {![file exists $calendarFile]} { log "INFO" "No calendar data to import ;)"; return }
		set data [read [set fl [open $calendarFile r]]]; close $fl
		set icalTree [ical::cal2tree $data]
		log "DEBUG" "Dumping icalTree:\n [ical::dump $icalTree]"
		
		# loop all children of root node
		foreach node [$icalTree children -all root] {
			set childNodeType [$icalTree get $node @type]
			# looking for vevents
			if {$childNodeType eq "vevent"} {
				set eventDict [dict create]
				foreach veventChildNode [$icalTree children -all $node] {
					set value [$icalTree get $veventChildNode @value]
					# handling items in vevent
					switch [string tolower [$icalTree get $veventChildNode @type]] {
						"uid" { dict set eventDict uid $value }
						"organizer" { dict set eventDict organizer $value }
						"summary" { dict set eventDict summary $value }
						"description" {	dict set eventDict description $value }
						"dtstart" {dict set eventDict dtstart $value }
						"dtend" {	dict set eventDict dtend $value }
						"dtstamp" { dict set eventDict dtstamp $value }
					}
				}
				
				markAppointmentInCalendar $calWin $eventDict
			}
		}
	}
	
	proc markAppointmentInCalendar {calWin veventDict} {
		if {![dict exists $veventDict dtstart] || ![dict exists $veventDict dtend] || ![dict exists $veventDict summary]} {
			log "WARNING" "Malformed ICalendar entry, dtstart, dtend and summary required: $veventDict"
			return
		}
		set dtStart [dateTimeParser [dict get $veventDict dtstart]]
		set dtEnd [dateTimeParser [dict get $veventDict dtend]]
		set summary [dict get $veventDict summary]
		
		set format "%e %N %Y 1 green { %H:%M:%S - $summary }"
		set mark [eval list [clock format [dict get $dtStart sinceEpoch] -format $format]]
		${calWin}.cal configure -mark $mark
		log "DEBUG" "'$mark' has been added to the calendar"
	}
	
	proc dateTimeParser {dateTime} {
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
	
	proc drawCalendar {w calWin year month} {
		variable sys
		if {[winfo exists ${calWin}.cal]} {
			destroy ${calWin}.cal
		}
		pack [calwid ${calWin}.cal \
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
		]
		
		# mark today
		${calWin}.cal configure -mark [eval list [clock format [clock seconds ] -format "%e %N %Y 1 $sys($w,calcolor,today) { Today }" ]]
	}
	
	proc rederWithCommand {w calWin} {
		variable sys
		toplevel $calWin -bg $sys($w,background)
		pack [label ${calWin}.display \
			-bg $sys($w,background) \
			-fg $sys($w,foreground) \
			-font [font create -family "nimbus mono"] \
			-justify left \
			-text [string map { " " "  " } [eval $sys($w,command)]]
		] -fill both
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


