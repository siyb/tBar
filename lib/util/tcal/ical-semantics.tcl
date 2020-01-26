package provide ical-semantics 0.1

namespace eval ical {}

if {![info exists geekosphere::tbar::packageloader::available]} {
	package require struct::list
}

proc ical::components {tree node body} {
    set errs {}
    foreach child [$tree children $node] {
	set type [$tree get $child @type]
	set children($child) $type
	lappend types($type) $child
    }

    # remove the non-standard ones
    foreach x [array names children {[Xx]-*}] {
	unset children($x)
    }

    foreach line [split $body \n] {
	if {$line == ""} {
	    continue
	}
	#puts stderr "$node: component line $line"
	set constraint [lindex $line 0]
	foreach comp [lrange $line 1 end] {
	    #puts stderr "$node: searching $comp"
	    if {[info exists types($comp)]} {
		set found $types($comp)
	    } else {
		set found {}
	    }

	    #puts stderr "$node: found $found"
	    switch $constraint {
		mandatory {
		    if {[llength $found] < 1} {
			lappend errs "missing $comp"
		    }
		}

		optional {}

		mandatory_once {
		    if {[llength $found] < 1} {
			lappend errs "missing $comp"
		    } elseif {[llength $found] > 1} {
			lappend errs "duplicate $comp: $found"
		    }
		}

		optional_once {
		    if {[llength $found] > 1} {
			lappend errs "duplicate $comp: $found"
		    }
		}
	    }

	    # now remove the child
	    foreach child $found {
		catch {unset children($child)}
	    }

	}
    }

    foreach {n v} [array get children] {
	lappend errs "illegal $v: [$tree getall $n]"
    }
    return $errs
}

proc ical::type {tree node value args} {
    if {$args == {}} {
	return
    }

    if {[llength $args] > 1} {
	if {[$tree keyexists $node value]} {
	    set vt [$tree get $node value]
	    set offset [lsearch $args $vt]
	    if {$offset < 0} {
		warning "[$tree getall $node] - Can't find type $vt in $args"
		set args [lindex $args 0]
	    } else {
		set args [lindex $args $offset]
	    }
	} else {
	    set args [lindex $args 0]
	}
    }

    switch -- [string tolower $args] {
	text {
	    set value [string tolower $value]
	}

	ctext {
	    # don't mod the text
	}

	uri {
	}

	binary {
	    # base64 encoded
	}

	floats {
	    # float;float - geo position
	    set val [split $value \;]
	    if {![string is double [lindex $val 0]]
		|| ![string is double [lindex $val 0]]} {
		warning "[$tree getall $node] - geofloat '$value'"
	    } else {
		set value $value
	    }
	}

	integer {
	    if {![string is integer $value]} {
		warning "[$tree getall $node] - integer '$value'"
	    }
	}

	date-time {
	    # tcl clock doesn't understand Z as a timezone
	    set val [string trimright $value Z]
	    if {"$value" != "$val"} {
		set gmt 1
	    } else {
		set val $value
		set gmt 0
	    }

	    # some time-date omit seconds
	    if {[string length $val] == 13} {
		set val ${val}00
	    }

	    if {[catch {clock scan $val -gmt $gmt} result eo]} {
		warning "[$tree getall $node] - date-time '$value/$val' [string length $val]"
	    }
	    #set x [clock scan $val -gmt $gmt]
	    #puts "s/$val/[clock format $x -format %Y%m%dT%H%M%S]/"
	}

	date {
	    if {[catch {clock scan $value} result eo]} {
		warning "[$tree getall $node] - date '$value' - $eo"
	    }		
	}

	duration {
	}

	period {
	}

	utc-offset {
	}

	cal-address {
	}

	recur {
	}

	default {
	    warning "[$tree getall $node] - unknown type $args"
	}
    }

    $tree set $node @value $value
}

proc ical::scope {tree node args} {
    set ptype [$tree get $node @type]
    foreach scope $args {
	if {[string match $scope $ptype]} {
	    return 1
	}
    }

    # not a scope we should be in
    warning "[$tree getall $node] is scope $ptype, not one of $args - [info level -2]"
    return 0
}

proc ical::params {tree node given args} {
    array set p $given
    foreach el $args {
	if {[info exists p($el)]} {
	    if {[catch {/$el $p($el)} errs eo]} {
		warning "[$tree getall $node] - error $eo processing $el"
	    } elseif {$errs ne ""} {
		warning "[$tree getall $node] - $errs"
	    }
	    $tree set $node $el $p($el)
	    unset p($el)
	}
    }

    foreach {n v} [array get p {[xX]-*}] {
	$tree set $node $n $v
	unset p($el)
    }

    if {[array size p] != 0} {
	warning "[$tree getall $node] - has extra parameters: [array get p] - [info level -2]"
    }
}

proc ical::add {vtype paccept scope} {
    upvar 1 tree tree
    upvar 1 node parent
    upvar 1 value value
    upvar 1 args params

    set type [string trimleft [lindex [info level -1] 0] /]

    variable debug

    if {$scope != {}} {
	scope $tree $parent {*}$scope
    }

    set n [$tree insert $parent end]
    $tree set $n @type $type
    params $tree $n $params {*}$paccept
    type $tree $n $value {*}$vtype

    if {$debug > 2} {
	puts stderr "adding $n:'[$tree getall $n]' value:$value params:$paccept scopes:$scope to $parent"
    }

    return $n
}

proc ical:://begin {tree node value} {
    set ptype [$tree get $node @type]
    set value [string tolower $value]

    variable debug
    if {$debug > 2} {
	puts stderr "Moving down to $value from $node-$ptype"
    }

    switch -- $value {
	vcalendar {
	    set scope root
	}

	vevent -
	vjournal -
	vfreebusy -
	vtodo {
	    set scope vcalendar ; # may only occur within a vcalendar
	}

	valarm {
	    set scope {vevent vtodo}
	}

	daylight -
	standard {
	    set scope vtimezone
	}

	default {
	    set scope {}
	}
    }
    set args {}
    set n [add {} {} $scope]
    $tree set $n @type $value
    return $n
}

proc ical:://end {tree node value} {
    set parent [$tree parent $node]
    set value [string tolower $value]
    set tval [$tree get $node @type]
    variable debug
    if {$debug > 2} {
	puts stderr "Moving up from $node-$value to $parent-[$tree get $parent @type]"
    }
    if {$value ne $tval} {
	warning "[$tree getall $node] END $value != $tval"
    }

    switch -- $value {
	vcalendar {
	    set errs [components $tree $node {
		mandatory_once prodid version
		optional_once calscale method
		optional vevent vtodo vtimezone vjournal vfreebusy
		optional related-to
	    }]

	    # MUST contain one calendar component
	}

	vevent {
	    set errs [components $tree $node {
		mandatory_once dtstart uid
		optional_once class created description geo last-mod
		optional_once location organizer priority dtstamp sequence
		optional_once status summary transp uid url recurid
		optional dtend duration
		optional attach attendee categories comment contact exdate
		optional exrule rstatus related resources rdate rrule valarm
		optional related-to
	    }]

	    # either 'dtend' or 'duration' may appear in
	    # a 'eventprop', but 'dtend' and 'duration'
	    # MUST NOT occur in the same 'eventprop'
	}

	valarm {
	    set errs [components $tree $node {
		mandatory_once action trigger uid
		optional_once duration repeat
		optional_once attach
	    }]
	    # if one of duration repeat occurs the other must occur
	}
	
	vtodo {
	    set errs [components $tree $node {
		mandatory_once uid
		optional_once class completed created description dtstamp
		optional_once dtstart geo last-mod location organizer percent
		optional_once priority recurid seq status summary uid url due
		optional_once duration
		optional attach attendee categories comment contact exdate
		optional exrule rstatus related resources rdate rrule valarm
		optional related-to
	    }]
	}
	
	vjournal {
	    set errs [components $tree $node {
		mandatory_once uid
		optional_once class created description dtstart dtstamp
		optional_once last-mod organizer recurid seq status 
		optional_once summary uid url
		optional attach attendee categories comment contact exdate
		optional exrule related rdate rrule rstatus
		optional related-to
	    }]
	}
	
	vfreebusy {
	    set errs [components $tree $node {
		mandatory_once uid
		optional_once contact dtstart dtend duration dtstamp
		optional_once organizer uid url
		optional attendee comment freebusy rstatus
	    }]
	}

	vtimezone {
	    set errs [components $tree $node {
		mandatory_once tzid
		optional_once last-mod tzurl
		mandatory standard daylight
	    }]

	    # An individual "VTIMEZONE" calendar component MUST be specified for
	    # each unique "TZID" parameter value specified in the iCalendar object.
	}

	daylight -
	standard {
	    set errs [components $tree $node {
		mandatory_once dtstart tzoffsetto tzoffsetfrom
		optional comment rdate rrule tzname
	    }]
	}

	default {}
    }
    if {$errs != {}} {
	warning "[$tree getall $node]: $errs"
    }
    return $parent
}

# Purpose: This property defines the calendar scale used for the
# calendar information specified in the iCalendar object.
proc ical:://calscale {tree node value args} {
    add {text} {} vcalendar

    # default GREGORIAN

    return $node
}

# Purpose: This property defines the iCalendar object method associated
# with the calendar object.
proc ical:://method {tree node value args} {
    add {text} {} vcalendar
    return $node
}

# Purpose: This property specifies the identifier for the product that
# created the iCalendar object.
proc ical:://prodid {tree node value args} {
    add {ctext} {} vcalendar
    return $node
}

# Purpose: This property specifies the identifier corresponding to the
# highest version number or the minimum and maximum range of the
# iCalendar specification that is required in order to interpret the
# iCalendar object.
proc ical:://version {tree node value args} {
    add {text} {} vcalendar

    # "2.0"         ;This memo / maxver / (minver ";" maxver)
    return $node
}

# Purpose: The property provides the capability to associate a document
# object with a calendar component.
proc ical:://attach {tree node value args} {
    add {uri binary} {fmttype} {vevent vtodo vjournal valarm}
    return $node
}

# Purpose: This property defines the categories for a calendar component.
proc ical:://categories {tree node value args} {
    add {text} {language} {vevent vtodo vjournal}
    return $node
}

# Purpose: This property defines the access classification for a
# calendar component.
proc ical:://class {tree node value args} {
    set n [add {text} {} {vevent vtodo vjournal}]
    set value [$tree get $n @value]

    switch -glob -- $value {
	public -
	private -
	confidential -
	x-* {}
	default {
	    warning "[$tree getall $n] - unknown class '$value'"
	}
    }
    #default public

    return $node
}

# Purpose: This property specifies non-processing information intended
# to provide a comment to the calendar user.
proc ical:://comment {tree node value args} {
    add {ctext} {altrep language} {vevent vtodo vjournal vtimezone vfreebusy}
    return $node
}

# Purpose: This property provides a more complete description of the
# calendar component, than that provided by the "SUMMARY" property.
proc ical:://description {tree node value args} {
    add {ctext} {altrep language} {vevent vtodo vjournal valarm}
    return $node
}

# Purpose: This property specifies information related to the global
# position for the activity specified by a calendar component.
proc ical:://geo {tree node value args} {
    add {floats} {} {vevent vtodo}
    return $node
}

# Purpose: The property defines the intended venue for the activity
# defined by a calendar component.
proc ical:://location {tree node value args} {
    add {text} {altrep language} {vevent vtodo}
    return $node
}

# Purpose: This property is used by an assignee or delegatee of a to-do
# to convey the percent completion of a to-do to the Organizer.
proc ical:://percent-complete {tree node value args} {
    add {integer} {} {vtodo}
    # range of 0-100
    return $node
}

# Purpose: The property defines the relative priority for a calendar component.
proc ical:://priority {tree node value args} {
    add {integer} {} {vevent vtodo}
    # range of 0-9
    return $node
}

# Purpose: This property defines the equipment or resources anticipated
# for an activity specified by a calendar entity..
proc ical:://resources {tree node value args} {
    add {text} {altrep language} {vevent vtodo}
    # comma sep
    return $node
}

# Purpose: This property defines the overall status or confirmation for
# the calendar component.
proc ical:://status {tree node value args} {
    add {text} {} {vevent vtodo vjournal}

    # vevent: tentative confirmed cancelled
    # vtodo: needs-action completed in-process cancelled
    # vjournal: draft final cancelled

    return $node
}

# Purpose: This property defines a short summary or subject for the
# calendar component.
proc ical:://summary {tree node value args} {
    add {ctext} {altrep language} {vevent vtodo vjournal valarm}
    return $node
}

# Purpose: This property defines the date and time that a to-do was
# actually completed.
proc ical:://completed {tree node value args} {
    add {date-time} {} {vtodo}
    # must be in utc format
    return $node
}

# Purpose: This property specifies the date and time that a calendar
# component ends.
proc ical:://dtend {tree node value args} {
    add {date-time date} {value tzid} {vevent vfreebusy}
    return $node
}

# Purpose: This property defines the date and time that a to-do is
# expected to be completed.
proc ical:://due {tree node value args} {
    add {date-time date} {value tzid} {vtodo}
    return $node
}

# Purpose: This property specifies when the calendar component begins.
proc ical:://dtstart {tree node value args} {
    add {date-time date} {value tzid} {vevent vtodo vfreebusy vtimezone standard daylight}
    # utc time in vfreebusy
    return $node
}

# Purpose: The property specifies a positive duration of time.
proc ical:://duration {tree node value args} {
    add {duration} {} {vevent vtodo vfreebusy valarm}
    return $node
}

# Purpose: The property defines one or more free or busy time intervals.
proc ical:://freebusy {tree node value args} {
    add {period} {fbtype value} {vfreebusy}
    # must be UTC time
    # should sort in ascending order
    return $node
}

# Purpose: This property defines whether an event is transparent or not
# to busy time searches.
proc ical:://transp {tree node value args} {
    add {text} {} {vevent}
    # opaque or transparent - default opaque
    return $node
}

# Purpose: This property specifies the text value that uniquely
# identifies the "VTIMEZONE" calendar component.
proc ical:://tzid {tree node value args} {
    add {text} {} {vtimezone}
    return $node
}

# Purpose: This property specifies the customary designation for a time
# zone description.
proc ical:://tzname {tree node value args} {
    add {text} {language} {vtimezone standard daylight}
    return $node
}

# Purpose: This property specifies the offset which is in use prior to
# this time zone observance.
proc ical:://tzoffsetfrom {tree node value args} {
    add {utc-offset} {} {vtimezone standard daylight}
    return $node
}

# Purpose: This property specifies the offset which is in use in this
# time zone observance.
proc ical:://tzoffsetto {tree node value args} {
    add {utc-offset} {} {vtimezone standard daylight}
    return $node
}

# Purpose: The TZURL provides a means for a VTIMEZONE component to
# point to a network location that can be used to retrieve an up-to-
# date version of itself.
proc ical:://tzurl {tree node value args} {
    add {uri} {} {vtimezone standard daylight}
    return $node
}

# 4.8.4 Relationship Component Properties

# Purpose: The property defines an "Attendee" within a calendar component.
proc ical:://attendee {tree node value args} {
    add {cal-address} {cutype member role partstat rsvp delto delfrom sentby cn dir language} {}
    # scope is complex
    return $node
}

# Purpose: The property is used to represent contact information or
# alternately a reference to contact information associated with the
# calendar component.
proc ical:://contact {tree node value args} {
    add {text} {altrep language} {vevent vtodo vjournal vfreebusy}
    return $node
}

# Purpose: The property defines the organizer for a calendar component.
proc ical:://organizer {tree node value args} {
    add {cal-address} {cn dir sentbyparam language role} {vevent vtodo vjournal vfreebusy}
    return $node
}

# Purpose: This property is used in conjunction with the "UID" and
# "SEQUENCE" property to identify a specific instance of a recurring
# "VEVENT", "VTODO" or "VJOURNAL" calendar component. The property
# value is the effective value of the "DTSTART" property of the
# recurrence instance.
proc ical:://recurrence-id {tree node value args} {
    add {date-time date} {value tzid range} {}
    # scope is complex
    return $node
}

# Purpose: The property is used to represent a relationship or
# reference between one calendar component and another.
proc ical:://related-to {tree node value args} {
    add {text} {reltype} {vevent vtodo vjournal}
    return $node
}

# Purpose: This property defines a Uniform Resource Locator (URL)
# associated with the iCalendar object.
proc ical:://url {tree node value args} {
    add {uri} {} {vevent vtodo vjournal vfreebusy}
    return $node
}

# Purpose: This property defines the persistent, globally unique
# identifier for the calendar component.
proc ical:://uid {tree node value args} {
    set n [add {ctext} {} {vevent vtodo vjournal vfreebusy}]

    # The identifier is RECOMMENDED to be the identical syntax to the [RFC 822] addr-spec. A good method to assure uniqueness is to put the domain name or a domain literal IP address of the host on which the identifier was created on the right hand side of the "@", and on the left hand side, put a combination of the current calendar date and time of day (i.e., formatted in as a DATE-TIME value) along with some other currently unique (perhaps sequential) identifier available on the system (for example, a process id number)

    variable uids
    if {[info exists uids($value)]} {
	warning "[$tree getall $n] - Duplicate uid $value"
    } else {
	set uids($value) $n
    }
    return $node
}

# 4.8.5 Recurrence Component Properties

# Purpose: This property defines the list of date/time exceptions for a
# recurring calendar component.
proc ical:://exdate {tree node value args} {
    add {date-time date} {value tzid} {}

    # scope $tree $node complex - anything_with_recurring

    return $node
}

# Purpose: This property defines a rule or repeating pattern for an
# exception to a recurrence set.
proc ical:://exrule {tree node value args} {
    add {recur} {} {vevent vtodo vjournal}
    return $node
}

# Purpose: This property defines the list of date/times for a
# recurrence set.
proc ical:://rdate {tree node value args} {
    add {date-time date period} {value txid} {vevent vtodo vjournal vtimezone standard daylight}
    return $node
}

# Purpose: This property defines a rule or repeating pattern for
# recurring events, to-dos, or time zone definitions.
proc ical:://rrule {tree node value args} {
    add {recur} {} {vevent vtodo vjournal vtimezone standard daylight}
    return $node
}

# 4.8.6 Alarm Component Properties


# Purpose: This property defines the action to be invoked when an alarm
# is triggered.
proc ical:://action {tree node value args} {
    add {text} {} {valarm}

    # audio / display / email / procedure / iana-token / x-name
    return $node
}

# Purpose: This property defines the number of time the alarm should be
# repeated, after the initial trigger.
proc ical:://repeat {tree node value args} {
    add {integer} {} {valarm}

    # default 0
    # must have duration

    return $node
}

# Purpose: This property specifies when an alarm will trigger.
proc ical:://trigger {tree node value args} {
    add {duration date-time} {value tzid trigrel} {valarm}
    return $node
}

# 4.8.7 Change Management Component Properties

# Purpose: This property specifies the date and time that the calendar
# information was created by the calendar user agent in the calendar
# store.
proc ical:://created {tree node value args} {
    add {date-time} {} {vevent vtodo vjournal}
    return $node
}

# Purpose: The property indicates the date/time that the instance of
# the iCalendar object was created.
proc ical:://dtstamp {tree node value args} {
    add {date-time} {} {vevent vtodo vjournal vfreebusy}
    return $node
}

# Purpose: The property specifies the date and time that the
# information associated with the calendar component was last revised
# in the calendar store.
proc ical:://last-modified {tree node value args} {
    add {date-time} {} {vevent vtodo vjournal vtimezone}
    return $node
}

# Purpose: This property defines the revision sequence number of the
# calendar component within a sequence of revisions.
proc ical:://sequence {tree node value args} {
    add {integer} {} {vevent vtodo vjournal}
    return $node
}

# 4.8.8 Miscellaneous Component Properties

# Purpose: This property defines the status code returned for a
# scheduling request.
proc ical:://request-status {tree node value args} {
    add {text} {language} {vevent vtodo vjournal vfreebusy}
    return $node
}
