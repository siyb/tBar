# a parser for rfc2445 iCalendar files
package provide ical 0.1

package require ical-semantics

namespace eval ical {
    variable debug 5

    #The general property parameters defined by this memo
    # are defined by the following notation:
    variable properties
    array set ical::properties {
	altrep	"Alternate text representation"
	cn	"Common name"
	cutype	"Calendar user type"
	delfrom	"Delegator"
	delto	"Delegatee"
	dir	"Directory entry"
	encoding	"Inline encoding"
	fmttype	"Format type"
	fbtype	"Free/busy time type"
	language	"Language for text"
	member	"Group or list membership"
	partstat	"Participation status"
	range	"Recurrence identifier range"
	trigrel	"Alarm trigger relationship"
	reltype	"Relationship type"
	role	"Participation role"
	rsvp	"RSVP expectation"
	sentby	"Sent by"
	tzid	"Reference to time zone object"
	valuetype	"Property value data type"
	x-*	"A non-standard, experimental parameter"
    }
    # iana	"Some other IANA registered iCalendar parameter."

    variable cutype_vals
    array set cutype_vals {
	individual "an individual"
	group "a group of individuals"
	resource "a physical resource"
	room "a room resource"
	unknown "not known"
	"" individual
    }

    variable encoding_map
    array set encoding_map {
	8bit "8bit text encoding is defined in RFC 2045"
	base64 "binary encoding format is defined in RFC 2045"
	"" 8bit
    }

    variable fbtype_map
    array set fbtype_map {
	free ""
	busy ""
	busy-unavailable ""
	busy-tentative ""
	"" busy
    }

    variable partstat_map
    array set partstat_map {
	needs-action "Event needs action"
	accepted "Event accepted"
	declined "Event declined"
	tentative "Event tentatively accepted"
	delegated "Event delegated"
	completed "To-do completed"
	in-process "To-do in process of being completed"
	"" needs-action
    }

    variable range_map
    array set range_map {
	thisandprior "To specify all instances prior to the recurrence identifier"
	thisandfuture "To specify the instance specified by the recurrence identifier and all subsequent recurrence instances"
    }

    variable related_map
    array set related_map {
	start "Trigger off of start"
	end "Trigger off of end"
	"" start
    }

    variable reltype_map
    array set reltype_map {
	parent "Parent relationship"
	child "Child relationship"
	sibling "Sibling relationship"
	"" parent
    }

    variable role_map
    array set role_map {
	chair "Indicates chair of the calendar entity"
	req-participant "Indicates a participant whose participation is required"
	opt-participant "Indicates a participant whose participation is optional"
	non-participant "Indicates a participant who is copied for information purposes only"
	"" req-participant
    }

    variable rsvp_map
    array set rsvp_map {
	true ""
	false ""
	"" false
    }

    variable value_map
    array set value_map {
	binary ""
	boolean ""
	cal-address ""
	date ""
	date-time ""
	duration ""
	float ""
	integer ""
	period ""
	recur ""
	text ""
	time ""
	uri ""
	utc-offset ""
    }
}

proc ical::method {str} {
    
}

# rfc2445 4.1 -
# The iCalendar object is organized into individual lines of text,
# called content lines.
# Content lines are delimited by a line break, which is a CRLF.
# A long line can be split between any two characters by inserting a CRLF
# immediately followed by a single linear white space character
# (i.e., SPACE, US-ASCII decimal 32 or HTAB, US-ASCII decimal 9).
proc ical::str2lines {str} {
    variable debug
    if {$debug > 5} {
	puts stderr "str2lines 0: '$str'"
    }
    set str [string map [list \r\n \n \n\r \n] $str]	;# clean eol
    if {$debug > 5} {
	puts stderr "str2lines 1: '$str'"
    }
    set str [string map [list "\n " "" "\n\t" " "] $str]	;# unfold continuations
    if {$debug > 5} {
	puts stderr "str2lines 2: '$str'"
    }
    return [split $str \n]
}

proc ical::warning {err} {
    puts stderr "Warning: $err"
}

# nvd
# name value delimited
# nibble off the first element of a string terminated by $delim
proc ical::nvd {str delim} {
    set str [split [join $str] $delim]
    set n [lindex $str 0]
    set v [string trim [join [lrange $str 1 end] $delim] $delim]
    return [list $n $v]
}

# Property parameter values that are not in quoted strings are case insensitive.
proc ical::pval {str} {
    variable debug
    if {$debug > 3} {
	puts stderr "pval start: '$str'"
    }

    set pval {}
    while {$str ne ""} {
	set c [string index $str 0]
	switch -- $c {
	    "\"" {
		# leading quote - get quoteval
		if {$debug > 4} {
		    puts stderr "pval: string at '$str'"
		}
		if {[info exists prev]} {
		    # this is a parameter of the form: ...xyz"... 
		    # it's illegal, but we'll try to parse it anyway
		    warning "Parse - stray quote in parameter value"
		    set str [string range $str 1 end]
		    continue
		}

		foreach {pv str} [nvd [string range $str 1 end] "\""]
		if {$debug > 3} {
		    puts stderr "Adding1 property $pv"
		}
		lappend pval $pv
	    }

	    , {
		# next in a list of pvals
		if {$debug > 4} {
		    puts stderr "pval: comma at '$str'"
		}
		if {[info exists prev]} {
		    if {$debug > 3} {
			puts stderr "Adding2 property $prev"
		    }
		    lappend pval $prev
		    unset prev
		} else {
		    warning "Parse - double comma in parameter value"
		    set str [string range $str 1 end]
		    continue
		}
	    }

	    {;} -
	    : {
		# end of this parameter
		if {$debug > 4} {
		    puts stderr "pval: Break on '$str'"
		}
		break;
	    }

	    default {
		# check for validity
		if {![string is space $c] && [string is control $c]} {
		    binary scan $c H2 c
		    warning "Control character $c in parameter value"
		} else {
		    if {$c eq "\\"} {
			# handle backslash escapes
			append prev $c
			set str [string range $str 1 end]
			set c [string index $str 0]
		    }
		    append prev $c
		}
		set str [string range $str 1 end]
	    }
	}
    }

    if {[info exists prev]} {
	if {$debug > 3} {
	    puts stderr "Adding3 property $prev"
	}
	lappend pval $prev
    }

    return [list $pval $str]
}

# line2content -
# returns {name properties value}
#
# rfc2445 4.1:
# The following notation defines the lines of content in an iCalendar object:
# contentline        = name *(";" param ) ":" value CRLF
proc ical::line2content {line} {
    variable debug

    foreach {name value} [pval $line] break
    if {$debug > 2} {
	puts stderr "Name split: name:$name value:$value"
    }

    set name [string tolower $name]
    set props {}
    if {[string index $value 0] eq ":"} {
	set value [string range $value 1 end]
    } else {
	while {$value ne ""} {
	    foreach {pexpr value} [pval $value] break

	    if {$debug > 4} {
		puts "Got property expr:'$pexpr' value:'$value'"
	    }
	    if {$pexpr != {}} {
		foreach {pname pvalue} [nvd $pexpr =] break
		if {$debug > 3} {
		    puts "Got property name:'$pname' value:'$pvalue'"
		}
		lappend props [string tolower $pname] $pvalue
	    }

	    switch -- [string index $value 0] {
		{;} {
		    # end of property - skip and continue
		    set value [string range $value 1 end]
		}
		
		"" {
		    # end of properties - but no value!
		    break
		}
		
		: {
		    # end of properties - $value must be true value
		    set value [string range $value 1 end]
		    break
		}
		
		default {
		    error "Error in value pval parse - terminated at '$value'"
		}
	    }
	}
    }
    set value [string trim $value \"]
    if {$debug > 0} {
	puts stderr "name:$name value:$value props:$props"
    }
    return [list $name $value {*}$props]
}

proc ical::parammap {mapv val} {
    variable $mapv
    upvar 0 $mapv map
    variable debug
    if {$debug > 5} {
	puts stderr "parammap: $mapv $val - [array get map]"
    }
    set errs ""
    foreach v $val {
	if {![string match {[Xx]-*} $val] && ![info exists map($val)]} {
	    append errs "$mapv ($val) not known."
	}
    }
    return $errs
}

proc ical::is_uri {uri} {
    return ""
}

proc ical::is_mailto {mail} {
    # The value MUST be a MAILTO URI as defined in [RFC 1738].
    return ""
}

# Purpose: To specify an alternate text representation for the property value.
proc ical::/altrep {uri} {
    # must be a URI
    return [is_uri $uri]
}

# Purpose: To specify the common name to be associated
# with the calendar user specified by the property.
proc ical::/cn {args} {
    return ""
}

# Purpose: To specify the type of calendar user specified by the property.
proc ical::/cutype {args} {
    return [parammap cutype_vals $args]

    # This parameter can be specified on properties with a CAL-ADDRESS value type.
}

# Purpose: To specify the calendar users that have delegated
# their participation to the calendar user specified by the property.
proc ical::/delegated-from {args} {
    # The value MUST be a MAILTO URI as defined in [RFC 1738].
    return [is_mailto $args]
}

# Purpose: To specify the calendar users to whom the calendar user
# specified by the property has delegated participation.
proc ical::/delegated-to {args} {
    # The value MUST be a MAILTO URI as defined in [RFC 1738].
    return [is_mailto $args]
}

# Purpose: To specify reference to a directory entry associated with
# the calendar user specified by the property.
proc ical::/dir {args} {
    # URI
    return [is_uri $args]
}

# Purpose: To specify an alternate inline encoding for the property value.
proc ical::/encoding {args} {
    return [parammap encoding_map $args]
}

# Purpose: To specify the content type of a referenced object.
proc ical::/fmttype {args} {
    # iana-token | x-name
    return ""
}

# Purpose: To specify the free or busy time type.
proc ical::/fbtype {args} {
    return [parammap fbtype_map $args]
}

# Purpose: To specify the language for text values in a property
# or property parameter.
proc ical::/language {args} {
    # Text identifying a language, as defined in RFC 1766
    return ""
}

# Purpose: To specify the group or list membership of the calendar user
# specified by the property.
proc ical::/member {args} {
    # calendar addresses
    return ""
}

# Purpose: To specify the participation status for the calendar user
# specified by the property.
proc ical::/partstat {args} {
    return [parammap partstat_map $args]
    # completed property has date/time completed
}

# Purpose: To specify the effective range of recurrence instances from
# the instance specified by the recurrence identifier specified by the
# property.
proc ical::/range {args} {
    return [parammap range_map $args]
}

# Purpose: To specify the relationship of the alarm trigger with
# respect to the start or end of the calendar component.
proc ical::/related {args} {
    return [parammap related_map $args]
}

# Purpose: To specify the type of hierarchical relationship associated
# with the calendar component specified by the property.
proc ical::/reltype {args} {
    return [parammap reltype_map $args]
}

# Purpose: To specify the participation role for the calendar user
# specified by the property.
proc ical::/role {args} {
    return [parammap role_map $args]
}

# Purpose: To specify whether there is an expectation of a favor of a
# reply from the calendar user specified by the property value.
proc ical::/rsvp {bool} {
    return [parammap rsvp_map $bool]
}

# Purpose: To specify the calendar user that is acting on behalf of the
# calendar user specified by the property.
proc ical::/sent-by {args} {
    # value MUST be a MAILTO URI as defined in [RFC 1738]
    return [is_mailto $args]
}

# Purpose: To specify the identifier for the time zone definition for a
# time component in the property value.
proc ical::/tzid {args} {
    return ""
}

# Purpose: To explicitly specify the data type format for a property value.
proc ical::/value {args} {
    return [parammap value_map $args]
    # If the value type parameter is "VALUE=BINARY", then the inline
    # encoding parameter MUST be specified with the value
    # ENCODING=BASE64
}


proc ical::check_param {name val args} {
    set msg {}
    foreach {n v} $args {
	set errors 0
	if {[string match {[xX]-*} $n]} {
	    # skip
	} else {
	    if {[catch {/$n {*}$v} errors eo]} {
		puts "check param $n: $eo"
		lappend msg [list error $eo]
		set errors 1
	    }
	}
	if {$errors != ""} {
	    lappend msg $errors
	}
    }
    return $msg
}

proc ical::parse {str} {
    variable debug
    set methods {}
    foreach line [str2lines $str] {
	if {$line ne ""} {
	    set method [line2content $line]
	    if {[catch {
		set errs [check_param {*}$method]
		if {$errs ne ""} {
		    puts "Param Err: $method - $errs"
		}
	    } result eo]} {
		warning "Parse - Param Check Error: $method $eo"
	    }
	    lappend methods $method
	}
    }
    return $methods
}

proc ical::dump {tree} {
    set result ""
    $tree walk root n {
	append result [string repeat "    " [$tree depth $n]]
	append result [$tree getall $n]
	append result \n
    }
    return $result
}

proc ical::cal2tree {str} {
    package require struct::tree
    set tree [::struct::tree]
    set node root
    $tree set root @type root
    variable debug
    foreach el [ical::parse $str] {
	if {$debug > 2} {
	    puts stderr "[$tree get $node @type]: $el"
	}
	set cmd [lindex $el 0]
	if {[llength [info proc //$cmd]] > 0} {
	    set node [//$cmd $tree $node {*}[lrange $el 1 end]]
	}
    }
    return $tree
}

if {[info exists argv0] && ($argv0 == [info script])} {
    set obj [list \
		 "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//hacksw/handcal//NONSGML v1.0//EN\nBEGIN:VEVENT\nDTSTART:19970714T170000Z\nDTEND:19970715T035959Z\nSUMMARY:Bastille Day Party\nEND:VEVENT\nEND:VCALENDAR" \
		 "BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:19970901T130000Z-123401@host.com\nDTSTAMP:19970901T1300Z\nDTSTART:19970903T163000Z\nDTEND:19970903T190000Z\nSUMMARY:Annual Employee Review\nCLASS:PRIVATE\nCATEGORIES:BUSINESS,HUMAN RESOURCES\nEND:VEVENT\nEND:VCALENDAR\n" \
		 "BEGIN:VCALENDAR\nBEGIN:VFREEBUSY\nORGANIZER:MAILTO:jane_doe@host1.com\nATTENDEE:MAILTO:john_public@host2.com\nDTSTAMP:19970901T100000Z\nFREEBUSY;VALUE=PERIOD:19971015T050000Z/PT8H30M,\n 19971015T160000Z/PT5H30M,19971015T223000Z/PT6H30M\nURL:http://host2.com/pub/busy/jpublic-01.ifb\nCOMMENT:This iCalendar file contains busy time information for\n the next three months.\nEND:VFREEBUSY\nEND:VCALENDAR" \
		 "BEGIN:VCALENDAR\nMETHOD:xyz\nVERSION:2.0\nPRODID:-//ABC Corporation//NONSGML My Product//EN\nBEGIN:VEVENT\nDTSTAMP:19970324T1200Z\nSEQUENCE:0\nUID:uid3@host1.com\nORGANIZER:MAILTO:jdoe@host1.com\nATTENDEE;RSVP=TRUE:MAILTO:jsmith@host1.com\nDTSTART:19970324T123000Z\nDTEND:19970324T210000Z\nCATEGORIES:MEETING,PROJECT\nCLASS:PUBLIC\nSUMMARY:Calendaring Interoperability Planning Meeting\nDESCRIPTION:Discuss how we can test c&s interoperability\n using iCalendar and other IETF standards.\nLOCATION:LDB Lobby\nATTACH;FMTTYPE=application/postscript:ftp://xyzCorp.com/pub/\n conf/bkgrnd.ps\nEND:VEVENT\nEND:VCALENDAR\n" \
		 "BEGIN:VCALENDAR\nPRODID:-//RDU Software//NONSGML HandCal//EN\nVERSION:2.0\nBEGIN:VTIMEZONE\nTZID:US-Eastern\nBEGIN:STANDARD\nDTSTART:19981025T020000\nRDATE:19981025T020000\nTZOFFSETFROM:-0400\nTZOFFSETTO:-0500\nTZNAME:EST\nEND:STANDARD\nBEGIN:DAYLIGHT\nDTSTART:19990404T020000\nRDATE:19990404T020000\nTZOFFSETFROM:-0500\nTZOFFSETTO:-0400\nTZNAME:EDT\nEND:DAYLIGHT\nEND:VTIMEZONE\nBEGIN:VEVENT\nDTSTAMP:19980309T231000Z\nUID:guid-1.host1.com\nORGANIZER;ROLE=CHAIR:MAILTO:mrbig@host.com\nATTENDEE;RSVP=TRUE;ROLE=REQ-PARTICIPANT;CUTYPE=GROUP:\n MAILTO:employee-A@host.com\nDESCRIPTION:Project XYZ Review Meeting\nCATEGORIES:MEETING\nCLASS:PUBLIC\nCREATED:19980309T130000Z\nSUMMARY:XYZ Project Review\nDTSTART;TZID=US-Eastern:19980312T083000\nDTEND;TZID=US-Eastern:19980312T093000\nLOCATION:1CP Conference Room 4350\nEND:VEVENT\nEND:VCALENDAR\n" ]
    set fd [open conference-example.ics]
    lappend obj [read $fd]
    close $fd

    unset obj
    set fd [open schedule.ics]
    lappend obj [read $fd]
    close $fd
    unset obj

    set fd [open test.ics]
    lappend obj [read $fd]
    close $fd
    unset obj

    set fd [open freebusy1.ifb]
    lappend obj [read $fd]
    close $fd
    unset obj

    set fd [open evolution.ics]
    lappend obj [read $fd]
    close $fd

    foreach o $obj {
	#puts "In: $o"
	puts "Out: [ical::dump [ical::cal2tree $o]]"
    }
}

return
