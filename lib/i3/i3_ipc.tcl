package provide i3_ipc 1.0

package require logger
package require unix_sockets

catch { namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::i3::ipc {
	initLogger

	# i3 socket file
	set sys(socketFile) [file join $::env(HOME) .i3 ipc.sock]

	# sockets
	set sys(info_socket) -1
	set sys(event_socket) -1

	# reply variable, stores reply of i3
	set sys(info_reply) ""
	set sys(event_reply) ""
	
	# magic i3 ipc string
	set sys(magic) "i3-ipc"
	
	#
	# System relevant stuff
	#
	proc connect {} {
		variable sys
		if {$sys(info_socket) != -1 || $sys(event_socket) != -1} { error "Connection already established" }
		set sys(info_socket) [unix_sockets::connect $sys(socketFile)]
		set sys(event_socket) [unix_sockets::connect $sys(socketFile)]
		
		chan configure $sys(info_socket) -translation binary -blocking 0
		chan configure $sys(event_socket) -translation binary -blocking 0
		
		fileevent $sys(info_socket) readable [list geekosphere::tbar::i3::ipc::readInfo]
		fileevent $sys(event_socket) readable [list geekosphere::tbar::i3::ipc::readEvent]
	}

	proc disconnect {} {
		variable sys
		if {$sys(info_socket) != -1 $sys(reply_socket) != -1} { error "Connection has not been established" }
		close $sys(info_socket)
		close $sys(reply_socket)
		set sys(info_socket) -1
		set sys(reply_socket) -1
	}

	proc readInfo {} {
		variable sys
		set data [read $sys(info_socket)]
		foreach message [separateData $data] {
			set sys(info_reply) [i3queryDecode $message]
		}
	}
	
	proc readEvent {} {
		variable sys
		set data [read $sys(event_socket)]
		foreach message [separateData $data] {
			set sys(event_reply) [i3queryDecode $message]
		}
	}

	proc sendMessage {socket type message} {
		variable sys
		if {$type < 0 || $type > 3} { error "Message type invalid, must be between 0 and 3" }
		puts $sys($socket) [i3queryEncode $type $message]
		flush $sys($socket)
	}
		
	proc addInfoListener {procedure} {
		variable sys
		trace add variable sys(info_reply) write $procedure
	}
	
	proc addEventListener {procedure} {
		variable sys
		trace add variable sys(event_reply) write $procedure
	}
	
	#
	# Command
	#
	
	proc sendCommand {command} {
		sendMessage info_socket 0 $command
	}
	
	#
	# Information request procs
	#
	
	proc getWorkspaces {} {
		sendMessage info_socket 1 ""
	}

	proc getOutputs {} {
		sendMessage info_socket 3 ""
	}
	
	proc getEvent {} {
		variable sys
		return $sys(event_reply)
	}
	
	proc getInfo {} {
		variable sys
		return $sys(info_reply)
	}
	
	#
	# Subscription procs
	#
	
	proc subscribeToWorkspaceFocus {} {
		sendMessage event_socket 2 {[ "workspace", "focus" ]}
	}
	
	proc subscribeToWorkspaceInit {} {
		sendMessage event_socket 2 {[ "workspace", "init" ]}
	}
	
	proc subscribeToWorkspaceEmpty {} {
		sendMessage event_socket 2 {[ "workspace", "empty" ]}
	}
	
	proc subscribeToWorkspaceUrgent {} {
		sendMessage event_socket 2 {[ "workspace", "urgent" ]}
	}
	
	proc subscribeToOutput {} {
		sendMessage event_socket 2 {["output", "unspecified"]}
	}
	
	#
	# Util
	#
	
	proc i3queryEncode {type message} {
		variable sys
		return [binary format a*nna* $sys(magic) [string length $message] $type $message]
	}
	
	proc i3queryDecode {message} {
		variable sys
		binary scan $message a[string length $sys(magic)]nna* magic length type message
		if {$magic ne $sys(magic)} { error "Magic string mismatch." }
		if {[string length $message] != $length} { error "Message length mismatch, was [string bytelength $message], should have been $length" }
		return [list $type $message]
	}
	
	proc separateData {data} {
		variable sys
		set magic_len [string length $sys(magic)]
		set marker 0
		set starList [list]
		while {1} {
			set start [string first $sys(magic) $data $marker]
			if {$start == -1} { break }
			set marker [expr {$magic_len + $start}]
			log "TRACE" "start: $start"
			lappend startList $start
			log "TRACE" "marker: $marker"
		}
		set slLength [llength $startList]
		set retList [list]
		for {set i 0} {$i < $slLength} {incr i} {
			if {[expr {$i + 1}] < $slLength} {
				set message [string range $data [lindex $startList $i] [expr {[lindex $startList $i+1] - 1}]]
			} else {
				set message [string range $data [lindex $startList $i] end]
			}
			log "TRACE" "MESSAGE: $message"
			lappend retList $message
		}
		return $retList
	}
	
	namespace export \
	connect disconnect addInfoListener addEventListener getEvent getInfo \
	sendCommand \
	getWorkspaces getOutputs \
	subscribeToWorkspaceFocus subscribeToWorkspaceInit subscribeToWorkspaceEmpty subscribeToWorkspaceUrgent \
	subscribeToOutput \
	stripMessage
}
