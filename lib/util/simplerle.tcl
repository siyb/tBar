package provide simplerle 1.0

namespace eval geekosphere::tbar::simplerle {
	oo::class create simplerle {
		constructor {} {
			my variable container
			set container [list]
		}

		method setContainer {_container} {
			my variable container
			set container $_container
		}

		method add {value} {
			my variable container
			set item [lindex $container end]
			set val [lindex $item 0]
			set count [lindex $item 1]
			if {$val == $value} {
				incr count
				set container [lreplace $container end end [list $val $count]]
			} else {
				lappend container [list $value 1]
			}
		}

		method decompress {} {
			my variable container
			set ret [list]
			foreach item $container {
				lappend ret {*}[lrepeat [lindex $item 1] [lindex $item 0]]
			}
			return $ret
		}

		method get {} {
			my variable container
			return $container
		}
	}
}
