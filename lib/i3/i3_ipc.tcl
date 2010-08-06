package provide i3_ipc 1.0

package require logger

catch { namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::i3::ipc {
	initLogger
	
	# i3 socket file
	set sys(socketFile) [file join $::env(HOME) mock]
	
	# socket channel
	set sys(socket) -1
	
	proc connect {} {
		variable sys
		if {$sys(socket) != -1} { error "Connection already established" }
		set sys(socket) [open $sys(socketFile) a+]
		chan configure $sys(socket) -translation binary -blocking 1
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
		if {$data == ""} { return }
		puts "READ: '$data'"
	}
	
	proc sendMessage {type message} {
		if {$type < 0 || $type > 3} { error "Message type invalid, must be between 0 and 3" }
		
	}
}
