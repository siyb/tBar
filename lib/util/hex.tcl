package provide hex 1.0

package require logger

catch {namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::util::hex {
	initLogger
	proc Int2Hex {data} {
		if {![string is digit -strict $data]} {return -1}
		set str "0123456789abcdefghijklmnopqrstuvwxyz"; set text ""
		set i [expr {$data & 15}]; set r [expr {$data / 16}]
		set text [string index $str $i]
		while {$r>0} {
			set i [expr {$r & 15}]; set r [expr {$r / 16}]
			set text "[string index $str $i]$text"
		}
		return $text
	}

	proc conv {text} {
		foreach ch [split $text ""] {
			if {[scan $ch %c]<27} {
				set text [string map [list $ch [format %c [expr {[scan $ch %c]+64}]]] $text]
			}
		}
		return $text
	}

	proc puthex {data {saddr 0}} {
		if {[::geekosphere::tbar::util::logger::getLogLevel] ne "TRACE"} {
			return
		}
		set pos 0; set sw 0; set hex(0) ""; set hex(1) ""; set text(0) ""; set text(1) "";
		while {[string length $data]>0} {
			set spos [string range "0000[Int2Hex $pos]" end-3 end]
			if {$saddr!=0} {
				set stpos [string range "0000[Int2Hex [expr {$pos+$saddr}]]" end-3 end]
			} {set stpos ""}
			if {[string length $data]<8} {
				set text($sw) $data
				incr pos [string length $data]
				binary scan $data H* hex($sw)
				set data ""
			} {
				incr pos 8
				binary scan $data H16 hex($sw)
				set text($sw) [string range $data 0 7]
				set data [string range $data 8 end]
			}
			set sw [expr {$sw^1}]
			if {[string length $data]<8} {
				set text($sw) $data
				incr pos [string length $data]
				binary scan $data H* hex($sw)
				set data ""
			} {
				incr pos 8
				binary scan $data H16 hex($sw)
				set text($sw) [string range $data 0 7]
				set data [string range $data 8 end]
			}
			set sw [expr {$sw^1}]
			set txt(0) ""; foreach {ch0 ch1} [split $hex(0) ""] {append txt(0) "$ch0$ch1 "}; append txt(0) "                        "; set txt(0) [string range $txt(0) 0 22]
			set txt(1) ""; foreach {ch0 ch1} [split $hex(1) ""] {append txt(1) "$ch0$ch1 "}; append txt(1) "                        "; set txt(1) [string range $txt(1) 0 22]
			set text(0) [string range "[conv $text(0)]        " 0 7]
			set text(1) [string range "[conv $text(1)]        " 0 7]
			if {$stpos!=""} {
				log "TRACE" "0x$stpos | 0x$spos | $txt(0) | $txt(1) | $text(0) | $text(1)"
			} {
				log "TRACE" "0x$spos | $txt(0) | $txt(1) | $text(0) | $text(1)"
			}
			set hex(0) ""; set hex(1) ""; set text(0) ""; set text(1) "";
		}
	}

}
