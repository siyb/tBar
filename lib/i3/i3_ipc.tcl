package provide i3_ipc 1.0

if {![info exist geekosphere::tbar::packageloader::available]} {
	package require logger
	package require unix_sockets
	package require hex
}

catch { namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::i3::ipc {
	initLogger

	# i3 socket file
	set sys(socketFile) "" 

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
		if {$sys(socketFile) eq ""} { set sys(socketFile) [determineSocketPath] }
		if {$sys(info_socket) != -1 || $sys(event_socket) != -1} { return }
		set sys(info_socket) [unix_sockets::connect $sys(socketFile)]
		set sys(event_socket) [unix_sockets::connect $sys(socketFile)]

		chan configure $sys(info_socket) -translation binary -blocking 0 -buffering full
		chan configure $sys(event_socket) -translation binary -blocking 0 -buffering full

		fileevent $sys(info_socket) readable [list geekosphere::tbar::i3::ipc::readInfo]
		fileevent $sys(event_socket) readable [list geekosphere::tbar::i3::ipc::readEvent]
		log "INFO" "Connect to unix socket, info: $sys(info_socket) event: $sys(event_socket)"
	}

	proc disconnect {} {
		variable sys
		if {$sys(info_socket) != -1} {
			close $sys(info_socket)
		}
		if {$sys(event_socket) != -1} {
			close $sys(event_socket)
		}
		set sys(info_socket) -1
		set sys(event_socket) -1
		log "INFO" "Diconnected, info: $sys(info_socket) event: $sys(event_socket)"
	}

	proc isConnected {} {
		if {$sys(info_socket) != -1 && $sys(event_socket) != -1} {
			return 1
		} else {
			return 0
		}
	}

	proc readInfo {} {
		variable sys
		if {[catch {
			set data [read -nonewline $sys(info_socket)]
			::geekosphere::tbar::util::hex::puthex $data
			set messages [parseData $data]
			if {$messages == -1} { # TODO: do error handling here }
			foreach message $messages {
				set sys(info_reply) $message
			}
		} err]} {
			disconnect
			log "ERROR" "Error reading socket, forcefully disconnected: $::errorInfo"
			set sys(info_reply) -1
		}
	}

	proc readEvent {} {
		variable sys
		if {[catch {
			set data [read -nonewline $sys(event_socket)]
			flush $sys(event_socket)
			::geekosphere::tbar::util::hex::puthex $data
			set messages [parseData $data]
			if {$messages == -1} { # TODO: do error handling here}
			foreach message $messages {
				set sys(event_reply) $message
			}
		} err]} {
			disconnect
			log "ERROR" "Error reading socket, forcefully disconnected: $::errorInfo"
			set sys(event_reply) -1
		}
	}

	proc sendMessage {socket type message} {
		variable sys
		connect
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
		log "TRACE" "Requesting Workspaces"
		sendMessage info_socket 1 ""
	}

	proc getOutputs {} {
		log "TRACE" "Requesting Outputs"
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

	proc determineSocketPath {} {
		if {[info exists ::env(I3SOCK)]} {
			return $::env(I3SOCK)
		} else {
			return [file join $::env(HOME) .i3 ipc.sock]
		}
	}

	proc i3queryEncode {type message} {
		variable sys
		set length [string length $message]
		set message [binary format a[string length $sys(magic)]nna* $sys(magic) $length $type "$message"]
		log "DEBUG" "Message bytelength: $length"
		return $message
	}

	proc parseData {data} {
		log "DEBUG" "RAW DATA: $data"
		set executionTime [time {
		variable sys
		set retList [list]
		set mark 0
		set dataLength [string length $data]
		while {$mark <= $dataLength} {
			binary scan $data @${mark}a${sys(magicLen)}n1n1 magic length type
			if {![info exists type]} {
				log "ERROR" "Unable to parse message, $magic -> $length"
				return -1
			}
			log "DEBUG" "Message length was ${dataLength}, DATA: $data"
			if {$magic ne $sys(magic)} { log "ERROR" "Magic was $magic and not $sys(magic)"; return -1 }

			# seems that -2147483648 is a valid type .. wtf i3
			if {($type < 0 || $type > 3) && $type != -2147483648} { log "WARNING" "Invalid type, was ${type}" }
			set mark [expr {$mark + $sys(magicLen) + 8}]
			binary scan $data @${mark}a${length} message

			incr mark $length
			log "TRACE" "MARK: $mark MAGIC: '$magic' TYPE: $type LENGTH: $length MESSAGE: '$message'\n\n\n"
			lappend retList [list $type $message]
		}}]
		log "DEBUG" "Parsing message took $executionTime"
		return $retList

	}

	namespace export connect disconnect isConnected addInfoListener addEventListener \
	getEvent getInfo sendCommand getWorkspaces getOutputs \
	subscribeToOutput subscribeToWorkspace
}
