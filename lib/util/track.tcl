
package provide track 1.0

package require http
package require tbar_logger
catch { namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::util::track {
	variable sys

	set sys(url) "http://tbar.mount.at/track.cgi"

	initLogger

	# generates a somewhat "unique" id, should be enough for tracking 
	proc generateUid {} {
		return [string range [string map {"." ""} [expr {[clock clicks] * rand()}]] 0 8]
	}

	# gets the user's uid
	proc getUid {} {
		set userDir [file join $::env(HOME) .tbar]
		if {![file exists $userDir] || ![file isdirectory $userDir]} {
			log "WARNING" "No userdir, usage module disabled -> $userDir"
			return -1
		}
		set uidFile [file join $userDir uid]
		if {![file exists $uidFile]} {
			set uid [generateUid]
			set fl [open $uidFile w+];puts $fl $uid;close $fl
		} else {
			set uid [gets [set fl [open $uidFile]]]; close $fl
		}
		return $uid
	}

	proc trackWidgets {} {
		set uid [getUid]
		if {$uid == -1} {
			log "INFO" "Could not obtain UID, userdir does not exist"
			return
		}
		set query [::http::formatQuery \
			id $uid \
			version $::geekosphere::tbar::sys(bar,version) \
			widgets $::geekosphere::tbar::sys(widget,dict)]
		sendTrackingRequest $query
		log "INFO" "Widgets tracked"
	}

	proc trackBug {bugreport} {
		set uid [getUid]
		if {$uid == -1} {
			log "INFO" "Could not obtain UID, userdir does not exist"
			return
		}
		set query [::http::formatQuery \
			id [getUid] \
			version $::geekosphere::tbar::sys(bar,version) \
			report $bugreport]
		sendTrackingRequest $query
		log "INFO" "Bugreport sent"
	}

	proc sendTrackingRequest {query} {
		variable sys
		if {[catch {
			set token [::http::geturl $sys(url) -query $query]
			set data [::http::data $token]
			log "INFO" "Data returned by tracking server (data that has been sent): $data"
			::http::cleanup $token
		}]} {
			log "WARNING" "Tracking not possible, connection could not be established"
		}
	}
}

