#!/usr/bin/tclsh8.5
package require ncgi
package require sqlite3
puts "Content-type: text/html\n\n";

namespace eval geekosphere::web::tbar::track {
	variable conf
	set conf(database) "/var/www/tbar/data.db"
 
	variable sys
	set sys(id) -1
	set sys(type) -1
	set sys(payload) -1
	set sys(version) -1

	proc getData {} {
		variable sys

		::ncgi::parse
		set data [::ncgi::nvlist]
		set sys(id) [::ncgi::value "id"]
		set sys(version) [::ncgi::value "version"]

		if {[lsearch $data widgets] != -1} {
			set sys(type) widgets
		} elseif {[lsearch $data report] != -1} {
			set sys(type) report
		} else {
			error "unknown type"
		}

		set sys(payload) [::ncgi::value $sys(type)]

		puts "id: $sys(id)\ntBar version: $sys(version)\ntype: $sys(type)\npayload: $sys(payload)"
	}

	proc saveData {} {
		variable sys
		if {$sys(id) == -1 || $sys(type) == -1 || $sys(version) == -1} {
			error "data has not been parsed"
		}
		if {$sys(type) eq "widgets"} {
			saveWidgets
		} elseif {$sys(type) eq "report"} {
			saveReport
		}
	}

	proc saveWidgets {} {
		variable sys
		foreach {name info} $sys(payload) {
			set type [dict get $info widgetName]
			set updateInterval [dict get $info updateInterval]
			set arguments [dict get $info arguments]

			saveWidget $type
			foreach {key value} $arguments {
				saveWidgetArgument $key
				saveUserWidget $updateInterval $type $key $value
			}
		}
	}

	proc saveWidget {widget} {
		variable conf
		sqlite3 db $conf(database)
		db eval {
			INSERT OR IGNORE INTO widget ('type') VALUES ($widget);
		}
		db close
	}

	proc saveWidgetArgument {argument} {
		variable conf
		sqlite3 db $conf(database)
		db eval {
			INSERT OR IGNORE INTO widgetargument ('argument') VALUES ($argument);
		}
		db close
	}

	proc saveUserWidget {updateInterval widget argument value} {
		variable conf
		variable sys
		set timestamp [clock seconds]
		sqlite3 db $conf(database)
		db eval {
			INSERT OR REPLACE INTO userwidget ('uid', 'timestamp', 'updateinterval', 'widgetId', 'widgetArgumentId', 'value') 
			VALUES ($sys(id), $timestamp, $updateInterval ,(SELECT id FROM widget WHERE type = $widget), (SELECT id FROM widgetargument WHERE argument = $argument), $value)
		}
		db close
	}
}
geekosphere::web::tbar::track::getData
geekosphere::web::tbar::track::saveData
