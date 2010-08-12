package provide i3_ipc 1.0

package require logger
package require unix_sockets
package require hex

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
	set sys(magic) i3-ipc
	set sys(magicLen) [string length $sys(magic)]
	
	#
	# System relevant stuff
	#
	proc connect {} {
		variable sys
		if {$sys(info_socket) != -1 || $sys(event_socket) != -1} { error "Connection already established" }
		set sys(info_socket) [unix_sockets::connect $sys(socketFile)]
		set sys(event_socket) [unix_sockets::connect $sys(socketFile)]
		
		chan configure $sys(info_socket) -translation binary -blocking 0 -buffering full
		chan configure $sys(event_socket) -translation binary -blocking 0 -buffering full
		
		fileevent $sys(info_socket) readable [list geekosphere::tbar::i3::ipc::readInfo]
		fileevent $sys(event_socket) readable [list geekosphere::tbar::i3::ipc::readEvent]
	}

	proc disconnect {} {
		variable sys
		if {$sys(info_socket) != -1 || $sys(reply_socket) != -1} { error "Connection has not been established" }
		close $sys(info_socket)
		close $sys(reply_socket)
		set sys(info_socket) -1
		set sys(reply_socket) -1
	}

	proc readInfo {} {
		variable sys
		if {[catch {set data [read $sys(info_socket)]} err]} {
			disconnect
			log "ERROR" "Error reading socket, forcefully disconnected: $::errorInfo"
		}
                ::geekosphere::tbar::util::hex::puthex $data
		foreach message [parseData $data] {
			set sys(info_reply) $message
		}
	}
	
	proc readEvent {} {
		variable sys
		if {[catch {set data [read $sys(event_socket)]} err]} {
			disconnect
			log "ERROR" "Error reading socket, forcefully disconnected: $::errorInfo"
		}
		::geekosphere::tbar::util::hex::puthex $data
		foreach message [parseData $data] {
			set sys(event_reply) $message
		}
	}

	proc sendMessage {socket type message} {
		variable sys
		if {$type < 0 || $type > 3} { error "Message type invalid, must be between 0 and 3" }
		puts -nonewline $sys($socket) [i3queryEncode $type $message]
		flush $sys($socket)
	}
		
	proc addInfoListener {procedure info} {
		variable sys
		trace add variable sys(info_reply) write "$procedure $info"
	}
	
	proc addEventListener {procedure info} {
		variable sys
		trace add variable sys(event_reply) write "$procedure $info"
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
	
	proc subscribeToWorkspace {} {
		sendMessage event_socket 2 {[ "workspace" ]}
	}
	
	proc subscribeToOutput {} {
		sendMessage event_socket 2 {[ "output" ]}
	}
	
	#
	# Util
	#
	
	proc i3queryEncode {type message} {
		variable sys
		set length [string length $message]
		set message [binary format a[string length $sys(magic)]nna* $sys(magic) $length $type "$message"]
		log "DEBUG" "Message bytelength: $length"
		return $message
	}

	proc parseData {data} {
		variable sys
		set retList [list]
		set mark 0
		set dataLength [string length $data]
		while {1} {
			binary scan $data @${mark}a${sys(magicLen)}nn magic length type
			if {$magic != $sys(magic)} { error "Magic string was ${magic}, should have been ${sys(magic)}" }
			if {$type < 0 || $type > 3} { log "ERROR" "Invalid type, was ${type}" }
			set mark [expr {$mark + $sys(magicLen) + 8}]
			binary scan $data @${mark}a${length} message
		
			incr mark $length
			puts "MARK: $mark MAGIC: '$magic' TYPE: $type LENGTH: $length MESSAGE: '$message'\n\n\n"
			lappend retList [list $type $message]
			if {$mark >= $dataLength} { break }
		}
		return $retList
	}

	namespace export connect disconnect addInfoListener addEventListener \
	getEvent getInfo sendCommand getWorkspaces getOutputs \
	subscribeToOutput subscribeToWorkspace
}
