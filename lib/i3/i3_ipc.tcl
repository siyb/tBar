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
		puts info
		variable sys
		set data [read $sys(info_socket)]
		set sys(info_reply) $data
		return $data
	}
	
	proc readEvent {} {
		variable sys
		set data [read $sys(event_socket)]
		set sys(event_reply) $data
		return $data
	}

	proc sendMessage {socket type message} {
		variable sys
		if {$type < 0 || $type > 3} { error "Message type invalid, must be between 0 and 3" }
		puts $sys($socket) [binary format a*nna* "i3-ipc" [string length $message] $type $message]
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
	
	namespace export \
	connect disconnect addInfoListener addEventListener getEvent getInfo \
	getWorkspaces getOutputs \
	subscribeToWorkspaceFocus subscribeToWorkspaceInit subscribeToWorkspaceEmpty subscribeToWorkspaceUrgent \
	subscribeToOutput
}

proc foo {args} {
	puts "ARGS: $args | Reply Info: [getInfo]"
}

proc bar {args} {
	puts "ARGS: $args | Reply Event: [getEvent]"
}

namespace import geekosphere::tbar::i3::ipc::*
connect
puts 1
addInfoListener foo
puts 2
addEventListener bar
puts 3
subscribeToWorkspaceFocus
puts 4
subscribeToWorkspaceInit
puts 5
subscribeToWorkspaceEmpty
puts 6
subscribeToWorkspaceUrgent
puts 7
getWorkspaces
puts 8
vwait a