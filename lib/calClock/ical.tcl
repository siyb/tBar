package provide icalCalClock 1.0

package require logger
package require sqlite3
package require ical
namespace eval geekosphere::tbar::widget::calClock::ical {
	namespace import ::geekosphere::tbar::util::logger*
	::geekosphere::tbar::util::logger::initLogger
	
	variable sys
	set sys(dbName) "icaldata"
	set sys(databaseFile) [file join $::env(HOME) .tbar icaldata]
	
	# creates the ical database table in the icaldata database in the user's home directory
	proc mkDatabase {} {
		variable sys
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
		if {![file exists $sys(databaseFile)]} {;# create database if file is not present, TODO: perhaps make a better check here
			mkDatabase
		}
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
			set dtstart [dict get $icalEntryDict dtstart]
			set dtend [dict get $icalEntryDict dtend]
			set dtstamp [dict get $icalEntryDict dtstamp]
			sqlite3 $sys(dbName) $sys(databaseFile)
			$sys(dbName) eval {
				INSERT INTO appointment (`uid`, `organizer`, `summary`, `description`, `dtstart`, `dtend`, `dtstamp`, `color`) VALUES ($uid, $organizer, $summary, $description, $dtstart, $dtend, $dtstamp, 'blue');
			}			
		}
		$sys(dbName) close
	}
}
