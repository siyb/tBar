# Taken from: http://wiki.tcl.tk/15778
package provide closure 1.0

namespace eval closure {
	proc closure {script} {
		set valuemap {}
		foreach v [uplevel 1 {info vars}] {
			if {![uplevel 1 [list array exists $v]]} {
				lappend valuemap [list $v [uplevel 1 [list set $v]]]
			}
		}
		set body [list $valuemap $script [uplevel 1 {namespace current}]]
		return [list apply [list {} [list tailcall apply $body]]]
	}
}
