package provide icalCalClock 1.0

if {![info exist geekosphere::tbar::packageloader::available]} {
	package require tbar_logger
	package require sqlite3
	package require ical
}

catch { namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::widget::calClock::ical {
	initLogger
	
	variable sys
	set sys(dbName) "icaldata"
	set sys(databaseFile) [file join $::env(HOME) .tbar icaldata]
	
	# creates the ical database table in the icaldata database in the user's home directory
	proc mkDatabase {} {
		variable sys
		if {[file exists $sys(databaseFile)]} { return }
		sqlite3 $sys(dbName) $sys(databaseFile)
		$sys(dbName) eval {
			CREATE TABLE appointment(uid int unique not null, organizer text, summary text, description text, dtstart text, dtend text, dtstamp text, color string)
		}
		$sys(dbName) close
	}
	
	# get all ical entries
	proc getICalEntries {} {
		variable sys
		if {![file exists $sys(databaseFile)]} {
			return -1
		}
		set retList [list]
		sqlite3 $sys(dbName) $sys(databaseFile)
		$sys(dbName) eval {SELECT * FROM appointment} values {
			dict set valueDict uid $values(uid)
			dict set valueDict summary $values(summary)
			dict set valueDict organizer $values(organizer)
			dict set valueDict dtstart $values(dtstart)
			dict set valueDict dtstamp $values(dtstamp)
			dict set valueDict dtend $values(dtend)
			dict set valueDict description $values(description)
			lappend retList $valueDict
		}
		$sys(dbName) close
		return $retList
	}
	
	# convert a ical file to database entries
	proc ical2database {file} {
		variable sys
		mkDatabase
		
		set data [read [set fl [open $file r]]]; close $fl
		set data [ical::cal2tree $data]; # ical data tree
		set eventList [list]
		# loop all children of root node
		foreach node [$data children -all root] {
			set childNodeType [$data get $node @type]
			# looking for vevents
			if {$childNodeType eq "vevent"} {
				set eventDict [dict create]
				dict set eventDict uid ""
				dict set eventDict organizer ""
				dict set eventDict summary ""
				dict set eventDict description ""
				dict set eventDict dtstart ""
				dict set eventDict dtend ""
				dict set eventDict dtstamp ""
				foreach veventChildNode [$data children -all $node] {
					set value [$data get $veventChildNode @value]
					# handling items in vevent
					switch [string tolower [$data get $veventChildNode @type]] {
						"uid" { dict set eventDict uid $value }
						"organizer" { dict set eventDict organizer $value }
						"summary" { dict set eventDict summary $value }
						"description" {	dict set eventDict description $value }
						"dtstart" {dict set eventDict dtstart $value }
						"dtend" {	dict set eventDict dtend $value }
						"dtstamp" { dict set eventDict dtstamp $value }
					}
				}
				lappend eventList $eventDict
			}
		}
		icalEntry2databaseEntry $eventList; # make database entry
	}
	
	# make an ical entry
	proc icalEntry2databaseEntry {entryList} {
		variable sys
		sqlite3 $sys(dbName) $sys(databaseFile)
		foreach icalEntryDict $entryList {
			# need vars for sqlite escaping ... sucks
			# in addition, combining multiple inserts is impossible -.-
			set uid [dict get $icalEntryDict uid]
			set organizer [dict get $icalEntryDict organizer]
			set summary [dict get $icalEntryDict summary]
			set description [dict get $icalEntryDict description]
			set dtstart [dict get [dateTimeParser [dict get $icalEntryDict dtstart]] sinceEpoch]
			set dtend [dict get [dateTimeParser [dict get $icalEntryDict dtend]] sinceEpoch]
			set dtstamp [dict get $icalEntryDict dtstamp]
			sqlite3 $sys(dbName) $sys(databaseFile)
			$sys(dbName) eval {
				INSERT INTO appointment (`uid`, `organizer`, `summary`, `description`, `dtstart`, `dtend`, `dtstamp`, `color`) VALUES ($uid, $organizer, $summary, $description, $dtstart, $dtend, $dtstamp, 'blue');
			}			
		}
		$sys(dbName) close
	}
	
	# make a single entry, used by gui to make new appointments
	proc icalMakeEntry {uid dtstart dtend summary} {
		variable sys
		mkDatabase
		
		sqlite3 $sys(dbName) $sys(databaseFile)
		$sys(dbName) eval {
				INSERT INTO appointment (`uid`, `organizer`, `summary`, `description`, `dtstart`, `dtend`, `dtstamp`, `color`) VALUES ($uid, "", $summary, "", $dtstart, $dtend, "", 'blue');
		}	
		$sys(dbName) close
	}
	
	# removes appointments that are older than the specified timestamp
	proc removeOldAppointments {timestamp} {
		variable sys
		mkDatabase
		
		sqlite3 $sys(dbName) $sys(databaseFile)
		$sys(dbName) eval {
			DELETE FROM appointment WHERE `dtstart` < $timestamp
		}
		$sys(dbName) close
	}
	
	# date/time parser that will create a consitent format from ical
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
		
		# local: TZID=America/New_York:19980119T020000
		} elseif {[string match tzid* [string toupper $dateTime]]} {
			set splitData [split $dateTime ":"]
			if {[llength $splitData] != 2} { log "ERROR" "dateTime malformatted, != 2";return }
			set dateTime [lindex $splitData 1]
			set timeZone [split [lindex $splitData 0] "="]
			if {[llength $timeZone] != 2} { log "ERROR" "dataTime malformatted, timezone != 2";return }
			set timeZone [lindex $timeZone 1]
			dict set retDict type 2
			dict set retDict sinceEpoch [clock scan $dateTime -format "%Y%m%dT%H%M%SZ" -timezone :$timeZone]
		} else {
			error "Time/Date Format not supported yet: $dateTime"
		}

	}
}
