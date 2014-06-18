package require logger

catch {
	namespace import ::tcl::mathop::*
	namespace import ::geekosphere::tbar::util::logger::*
}

package provide tipc 1.0

namespace eval geekosphere::tbar::ipc {
	variable sys

	initLogger

	# boolean flag that controls if the ipc server is started	
	set sys(ipc,enabled) 1

	# the port of the ipc server
	set sys(ipc,port) 9999

	# the host / ip the ipc server is bound to
	set sys(ipc,host) 127.0.0.1

	# a list of allowed hostnames / ips that may connect to the ipc server
	set sys(ipc,allowed) [list 127.0.0.1]

	proc allowHost {host} {
		variable sys
		lappend sys(ipc,allowed) $host
	}

	proc isHostAllowed {host} {
		variable sys
		return != [lsearch $sys(ipc,allowed) $host] -1
	}

	proc registerProc {proc} {
		variable sys
		set ns [uplevel 1 { namespace current }]
		if {![info exists sys(ipc,registered,$ns)]} {
			set sys(ipc,registered,$ns) [list]
		}
		log "INFO" "Proc registered: $ns $proc" 
		lappend sys(ipc,registered,$ns) $proc
	}

	proc isProcRegistered {namespace proc} {
		variable sys
		if {![info exists sys(ipc,registered,$namespace)]} {
			log "DEBUG" "Namespace not known"
			return 0
		}
		log "DEBUG" "Namespace IPC procs: $sys(ipc,registered,$namespace)"
		return != [lsearch $sys(ipc,registered,$namespace) $proc] -1
	}

	proc startIPCServer {} {
		variable sys
		if {[catch { socket -server geekosphere::tbar::ipc::server -myaddr $sys(ipc,host) $sys(ipc,port) } err]} {
			log "ERROR" "Could not bind IPC server socket, no IPC requests will work (including the console): $err"
		}
	}

	proc server {chan ip port} {
		if {![isHostAllowed $ip]} {
			log "INFO" "Client $ip tried to connect but wasn't on the allowed client list"
			close $chan
			return
		}
		set command [gets $chan]
		close $chan
		runCommand $command
	}

	proc runCommand {command} {
		log "INFO" "Running '$command'"
		if {![dict exists $command "namespace"] || ![dict exists $command "proc"]} {
			log "ERROR" "Cannot execute command, protocol error"
			return
		}
		if {[catch {
			set ns [dict get $command "namespace"]
			set p [dict get $command "proc"]

			if {$ns eq "::geekosphere::tbar::ipc" && $p eq "listIPC"} {
				listIPC
				# returning here causes an error in tclsh8.6, therefore -> nested ifs
			} else {

				if {[isProcRegistered $ns $p]} {
					${ns}::${p}
				} else {
					log "ERROR" "${ns}::${p} not registered"
				}
			}
		} err]} {
			log "ERROR" "Cannot execute command: $::errorInfo"
		}
	}

	proc sendIPCCommand {namespace proc} {
		variable sys
		set sock [socket $sys(ipc,host) $sys(ipc,port)]
		dict set cmd namespace $namespace
		dict set cmd proc $proc
		puts $sock $cmd
		flush $sock
		close $sock
	}

	proc obtainIPCList {} {
		variable sys
		foreach {key value} [array get sys ipc,registered,*] {
			set ns [lindex [split $key ","] end]
			foreach prc $sys($key) {
				lappend ret ${ns}#${prc}
			}
		}
		return $ret
	}

	proc listIPC {} {
		foreach item [obtainIPCList] {
			puts $item
		}
	}
}
