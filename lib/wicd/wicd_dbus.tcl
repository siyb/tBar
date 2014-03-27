package require dbus

namespace eval geekosphere::tbar::wicd::dbus {
	variable sys

	# wicd config setting
	set conf(path,daemon) "/org/wicd/daemon"
	set conf(interface,daemon) "org.wicd.daemon"

	set conf(path,wired) "/org/wicd/daemon/wired"
	set conf(interface,wired) "org.wicd.daemon.wired"

	set conf(path,wireless) "/org/wicd/daemon/wireless"
	set conf(interface,wireless) "org.wicd.daemon.wireless"

	# state variables
	set sys(dbus) -1

	proc connect {} {
		variable sys
		set sys(dbus) [dbus connect system]
	}

	proc disconnect {} {
		variable sys
		if {$sys(dbus) != -1} {
			dbus disconnect $sys(dbus)
			set sys(dbus) -1
		}
	}

	proc call {path interface method a} {
		variable sys
		variable conf
		if {$sys(dbus) == -1} {
			error "Not connected to dbus"
		}
		if {[llength $a] == 0} {
			return [dbus call $sys(dbus) -autostart 1 -dest $conf(interface,daemon) $path $interface $method]
		} else {
			return [dbus call $sys(dbus) -autostart 1 -dest $conf(interface,daemon) $path $interface $method $a]
		}
	}

	#
	# Dispatcher procs
	#	
	
	proc callOnDaemon {method args} {
		variable conf
		return [call $conf(path,daemon) $conf(interface,daemon) $method $args]
	}

	proc callOnWireless {method args} {
		variable conf
		return [call $conf(path,wireless) $conf(interface,wireless) $method $args]
	}

	proc callOnWired {method args} {
		variable conf
		return [call $conf(path,wired) $conf(interface,wired) $method $args]
	}

	#
	# Wireless procs
	#

	proc getWireLessInterfaces {} {
		return [callOnWireless GetWirelessInterfaces]
	}

	proc isWirelessUp {} {
		return [callOnWireless IsWirelessUp]
	}

	proc scanWireless {} {
		return [callOnWireless Scan]
	}

	proc getWirelessProperty {id property} {
		return [callOnWireless GetWirelessProperty $id $property]
	}

	connect
	puts [getWireLessInterfaces]
	puts [scanWireless]
	puts [isWirelessUp]
}
