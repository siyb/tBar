package provide i3_ipc 1.0

package require logger
package require unix_sockets

catch { namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::i3::ipc {
	initLogger

	# i3 socket file
	set sys(socketFile) [file join $::env(HOME) .i3 ipc.sock]

	# socket channel
	set sys(socket) -1
	
	# reply variable, stores reply of i3
	set sys(reply) ""
	
	proc connect {} {
		variable sys
		if {$sys(socket) != -1} { error "Connection already established" }
		set sys(socket) [unix_sockets::connect $sys(socketFile)]
		chan configure $sys(socket) -translation binary -blocking 0
		fileevent $sys(socket) readable geekosphere::tbar::i3::ipc::readSocket
		return $sys(socket)
	}

	proc disconnect {} {
		variable sys
		if {$sys(socket) == 1} { error "Connection has not been established" }
		close $sys(socket)
		set sys(socket) -1
	}

	proc readSocket {} {
		variable sys
		set data [read $sys(socket)]
		set sys(reply) $data
		return $data
	}

	proc sendMessage {type message} {
		variable sys
		if {$type < 0 || $type > 3} { error "Message type invalid, must be between 0 and 3" }
		puts $sys(socket) [binary format a*nna* "i3-ipc" [string length $message] $type $message]
		flush $sys(socket)
	}
	
	proc addListener {procedure} {
		variable sys
		trace add variable sys(reply) write $procedure
	}
	
	#
	# Information request procs
	#
	
	proc getWorkspaces {} {
		sendMessage 1 ""
	}

	proc getOutputs {} {
		sendMessage 3 ""
	}
	
	proc getReply {} {
		variable sys
		return $sys(reply)
	}
	
	#
	# Subscription procs
	#
	
	proc subscribeToWorkspaceFocus {} {
		sendMessage 2 {[ "workspace", "focus" ]}
	}
	
	proc subscribeToWorkspaceInit {} {
		sendMessage 2 {[ "workspace", "init" ]}
	}
	
	proc subscribeToWorkspaceEmpty {} {
		sendMessage 2 {[ "workspace", "empty" ]}
	}
	
	proc subscribeToWorkspaceUrgent {} {
		sendMessage 2 {[ "workspace", "urgent" ]}
	}
	
	proc subscribeToOutput {} {
		sendMessage 2 {["output", "unspecified"]}
	}
	
	namespace export \
	connect disconnect addListener getReply \
	getWorkspaces getOutputs \
	subscribeToWorkspaceFocus subscribeToWorkspaceInit subscribeToWorkspaceEmpty subscribeToWorkspaceUrgent \
	subscribeToOutput
}

#proc foo {args} {
#	variable sys
#	puts "ARGS: $args | Reply: [getReply]"
#}

#namespace import geekosphere::tbar::i3::ipc::*
#connect
#addListener foo
#subscribeToWorkspaceFocus
#getWorkspaces
#vwait a