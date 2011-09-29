#	This file is part of OWA For TCL.
#
#	Microsoft Exchange Outlook Web Access (OWA) procedures 
#	See http://www.cobb.uk.net/OWA
#
#  Copyright (C) 2005,2006  Graham R. Cobb
#
#  OWA For TCL is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  OWA For TCL is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#  This OWA library is dependent upon and inspired by Jean-Claude 
#  Wippler's webdav library. Thanks to Jean-Claude for his help.
#
 
#
#	Edit History
#
#	Graham R. Cobb	14 May 2005
#	New file
#
#	Graham R. Cobb	13 June 2005
#	Add features for mail access, used by IMAP2OWA 
#
#	Graham R. Cobb	6 November 2005
#	Fix return of mailDate
#
#	Graham R. Cobb	1 May 2006
#	Add fetch-xml
#
#	Graham R. Cobb	16 May 2006
#	Change keywords used when saving and restoring collection state
#	Previous keywords will be supported for one release
#
#	Graham R. Cobb	22 May 2006
#	Handle folder names with spaces
#
#	Graham R. Cobb	28 June 2006
#	Reset parser after use (issue for Windows support)
#

package require webdav
package require xml
if {[catch {package require dbgprint}]} {
    namespace eval dbgprint {
	proc print {dbgpt args} {}
    }
}

# The ::owa routines provide access to Microsoft Exchange servers
# using Outlook Web Access.  
# This is built on webdav access but OWA uses webdav in some 
# unusual ways.
namespace eval owa {
    namespace export connect fetch list stat fetch-no-headers fetch-xml urlEncode urlDecode

    # connect is just a wrapper for ::webdav::connect
    proc connect {args} {
	return [eval [linsert $args 0 ::webdav::connect]]
    }

    # fetch an OWA item
    # Note: name must already be URL encoded
    # (this is convenient because the client will often be getting it from 
    # some other response already in URL encoded form)
    proc fetch {dav name} {
	# note $dav can be either a webdav name or an object -- we need it just as a name
	set dav [regsub {.*::} $dav ""]
	return [::webdav::get $dav $name {Translate F}]
    }

    # fetch an OWA item without mail headers
    # Note: name must already be URL encoded
    proc fetch-no-headers {dav name} {
	set content [fetch $dav $name]
	set i [string first "\n\r\n" $content]
	if {$i >= 0} {
	    set content [string range $content [expr $i + 3] end]
	}
	return $content
    }

    # fetch an OWA item in complete XML form
    # Note: name must already be URL encoded
    proc fetch-xml {dav name} {
	# note $dav can be either a webdav name or an object -- we need it just as a name
	set dav [regsub {.*::} $dav ""]
	return [::webdav::getXML $dav $name 0]
    }

    # list an OWA folder
    # Note: name must already be URL encoded
    # And responses will be URL encoded
    proc list {dav folder} {
	# note $dav can be either a webdav name or an object -- we need it just as a name
	set dav [regsub {.*::} $dav ""]
	return [::webdav::getlist $dav $folder]
    }

    # get full details of an OWA message
    # Note: name must already be URL encoded
    proc stat {dav name} {
	# note $dav can be either a webdav name or an object -- we need it just as a name
	set dav [regsub {.*::} $dav ""]
	return [::webdav::getstat $dav $name]
    }

    # Convert string to URL form
    # Code taken from Tcl Wiki http://wiki.tcl.tk/14144
    # But special handling for space and newline removed
    proc _urlInit {} {
	variable map 
	variable alphanumeric a-zA-Z0-9
	
	for {set i 0} {$i <= 256} {incr i} {
	    set c [format %c $i]
	    if {![string match \[$alphanumeric\] $c]} {
		set map($c) %[format %.2x $i]
	    }
	}
    }
    _urlInit
    
    proc urlEncode {string} {
	variable map
	variable alphanumeric
	
	# The spec says: "non-alphanumeric characters are replaced by '%HH'"
	# 1 leave alphanumerics characters alone
	# 2 Convert every other character to an array lookup
	# 3 Escape constructs that are "special" to the tcl parser
	# 4 "subst" the result, doing all the array substitutions
	
	regsub -all \[^$alphanumeric\] $string {$map(&)} string
	# This quotes cases like $map([) or $map($) => $map(\[) ...
	regsub -all {[][{})\\]\)} $string {\\&} string
        return [subst -nocommand $string]
    }

    proc urlDecode {str} {
	# rewrite "+" back to space (+ is not created by urlEncode but may be seen)
	# protect \ from quoting another '\'
	set str [string map [list + { } "\\" "\\\\"] $str]
	
	# prepare to process all %-escapes
	regsub -all -- {%([A-Fa-f0-9][A-Fa-f0-9])} $str {\\u00\1} str
	
	# process \u unicode mapped chars
	return [subst -novar -nocommand $str]
    }

    # ::owa::sync contains the code for managing "collections"
    # which are the components of replication
    namespace eval sync {
	namespace export create recreate kill
	namespace export manifest reset serial

	variable seq 0     	;# generate unique collection ID
	variable davs      	;# webdav objects for each collection
	variable paths     	;# folder paths for each collection
	variable wheres	;# SQL WHERE clauses for each collection
	variable collblobs	;# collblobs for each collection

	# set up an XML parser command object once, to be re-used each time
	variable parser [xml::parser -elementstartcommand  ::owa::sync::_xmlStart \
				 -elementendcommand    ::owa::sync::_xmlEnd \
				 -characterdatacommand ::owa::sync::_xmlItem \
				 -ignorewhitespace     1]

	namespace eval obj { }

	# Define an OWAsync collection
	# Note: path is not URL encoded and may contain spaces
	proc create {dav path {sql_where ""} {collblob ""}} {
	    variable seq
	    variable davs
	    variable paths
	    variable wheres
	    variable collblobs

	    set coll ::owa::sync::obj::coll[incr seq]
	    # note $dav can be either a webdav name or an object -- we need it just as a name
	    set davs($coll) [regsub {.*::} $dav ""]
	    set paths($coll) $path
	    set wheres($coll) $sql_where
	    set collblobs($coll) $collblob
	    
	    interp alias {} $coll {} ::owa::sync::_call $coll
	    return $coll
	}

	# Create a collection from serialised data (see the serial proc)
	proc recreate {dav data} {
	    foreach {x y} $data {
::dbgprint::print ::owa::sync::recreate x-$x+y-$y
		switch $x {
		    path -
		    ::owa::path {set path $y}
		    where -
		    ::owa::where {set where $y}
		    collblob -
		    ::owa::collblob {set collblob $y}
		    default {}
		}
	    }
	    return [create $dav $path $where $collblob]
	}

	proc kill {coll} {
	    variable davs
	    variable paths
	    variable wheres
	    variable collblobs

	    if {![info exists davs($coll)]} {
		return -code error "$coll: no such OWAsync collection"
	    }
	    unset davs($coll) paths($coll) wheres($coll) collblobs($coll)
	    interp alias {} $coll {}
	}

	# Get the manifest of changes to an OWAsync collection
	# This procedure keeps track of the "collblob" so that subsequent calls
	# just return changes.  To retrieve the whole colection again, use the "reset" procedure.
	#
	# The return value is a list of quintuplets. 
	# Each quintuplet represents a changed element in the collection.
	# The quintuplets are <href> <resourceid> <change> <repl-uid> <displayname>.
	# The <change> is new, change or delete.
	# The <href> and <displayname> will be empty if the change is "delete".
	# Note that the href will be URL encoded.
	# The <repl-uid> should be used to determine which element this replaces:
	# note that the href of an element can change and should not be used to uniquely identify the element
	# See http://msdn.microsoft.com/library/default.asp?url=/library/en-us/wss/wss/_esdk_davrepl_resourcetag.asp for usage of the resource id
	proc manifest {coll} {
	    variable davs
	    variable paths
	    variable wheres
	    variable collblobs
	    variable parser
	    variable xml_result
	    variable xml_collblob
	    variable xml_base

	    set xml_base [::webdav::base $davs($coll)]
	    set xml_base [regsub {^(.*://)?[^/]+} $xml_base {}]
	    set folder "\"${xml_base}$paths($coll)\""
	    # Note: deep traversals are not permitted in the main exchange datastore so this is always shallow
	    set scope "SCOPE('shallow traversal of $folder')"

	    if {[set sql_where $wheres($coll)] ne ""} {set sql_where [concat {WHERE } $sql_where]}

	    if {$collblobs($coll) ne ""} {
		set collblob_xml "<R:repl><R:collblob>$collblobs($coll)</R:collblob></R:repl>"
	    } else {
		set collblob_xml "<R:repl><R:collblob/></R:repl>"
#		set collblob_xml ""
	    }

	    # Create the XML query
	    set query [concat {
<?xml version="1.0"?>
<D:searchrequest xmlns:D="DAV:" xmlns:R="http://schemas.microsoft.com/repl/"
                 xmlns:M="urn:schemas:httpmail:">
	} $collblob_xml {
   <D:sql>
	SELECT "http://schemas.microsoft.com/repl/resourcetag",
	    "http://schemas.microsoft.com/repl/repl-uid", 
	    "DAV:displayname"
	FROM } $scope {
	} $sql_where {
   </D:sql>
</D:searchrequest>
	}]
::dbgprint::print ::owa::sync::manifest::query "XML query: $query"

	    set result [::webdav::search $davs($coll) [::owa::urlEncode $paths($coll)] $query]
::dbgprint::print ::owa::sync::manifest::response "::webdav::search result: $result"

	    # Parse the response
	    set xml_result {}
	    set xml_collblob ""
	    $parser parse $result
::dbgprint::print ::owa::sync::manifest::result "Collblob: $xml_collblob result: $xml_result"
	    $parser reset

	    set collblobs($coll) $xml_collblob

	    return $xml_result
	}

	proc _xmlStart {name args} {
	    variable lastelem $name
	    if {[string match *response $name]} {
		variable response
		array unset response
	    }
	}

	proc _xmlEnd {name args} {
	    variable lastelem ""
	    if {[string match *response $name]} {
		variable response
		variable xml_result
		if {![info exists response(resourcetag)]} {set response(resourcetag) ""}
		if {![info exists response(path)]} {set response(path) ""}
		if {![info exists response(changetype)]} {set response(changetype) change}
		if {![info exists response(displayname)]} {set response(displayname) ""}
		lappend xml_result [list $response(path) $response(resourcetag) $response(changetype) $response(repluid) $response(displayname)]
	    }
	}

	proc _xmlItem {data} {
	    variable lastelem
	    variable response
	    switch -glob $lastelem {
		*href {
		    # Remove the base of the URL, if present
		    variable xml_base
		    # First remove the host name portion, if present
		    set data [regsub {^(.*://)?[^/]+} $data {}]
		    # Then remove the base of the filespec
		    set n [string length $xml_base]
		    if {[string first $xml_base $data] == 0} {
			set data [string range $data $n end]
		    }
		    set response(path) $data
		}
		*changetype {
		    set response(changetype) $data
		}
		*resourcetag {
		    set response(resourcetag) $data
		}
		*repl-uid {
		    set response(repluid) $data
		}
		*displayname {
		    set response(displayname) $data
		}
		*collblob {
		    variable xml_collblob
		    set xml_collblob $data
		}
	    }
	}

	# Reset the collection state so that the next call to "manifest"
	# will return the whole collection.
	proc reset {coll} {
	    variable collblobs
	    set collblobs($coll) ""
	}

	# Serialise the collection data so it can be saved and restored at a later time
	proc serial {coll} {
	    variable paths
	    variable wheres
	    variable collblobs

	    return [list ::owa::path $paths($coll) ::owa::where $wheres($coll) ::owa::collblob $collblobs($coll)]
	}

	proc _call {coll cmd args} {
	    uplevel 1 [linsert $args 0 ::owa::sync::$cmd $coll]
	}
    }

}

package provide owa 0.6

# vim: set sw=4 sts=4 :
