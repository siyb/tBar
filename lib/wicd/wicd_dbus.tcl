package provide wicd_dbus 1.0

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

	proc call {path interface method signature a} {
		variable sys
		variable conf
		if {$sys(dbus) == -1} {
			error "Not connected to dbus"
		}
		if {[llength $a] == 0} {
			return [dbus call $sys(dbus) -autostart 1 -dest $conf(interface,daemon) $path $interface $method]
		} else {
			if {$signature eq ""} {
				return [dbus call $sys(dbus) -autostart 1 -dest $conf(interface,daemon) $path $interface $method {*}$a]
			} else {
				return [dbus call $sys(dbus) -signature $signature -autostart 1 -dest $conf(interface,daemon) $path $interface $method {*}$a]
			}
		}
	}

	#
	# Dispatcher procs
	#

	proc callOnDaemon {method signature args} {
		variable conf
		return [call $conf(path,daemon) $conf(interface,daemon) $method $signature $args]
	}

	proc callOnWireless {method signature args} {
		variable conf
		return [call $conf(path,wireless) $conf(interface,wireless) $method $signature $args]
	}

	proc callOnWired {method signature args} {
		variable conf
		return [call $conf(path,wired) $conf(interface,wired) $method $signature $args]
	}

	#
	# Wireless procs
	#

	proc getWireLessInterfaces {} {
		return [callOnWireless GetWirelessInterfaces ""]
	}

	proc isWirelessUp {} {
		return [callOnWireless IsWirelessUp ""]
	}

	proc getNumberOfNetworks {} {
		return [callOnWireless GetNumberOfNetworks ""]
	}

	proc getSSIDFor {networkId} {
		return [callOnWireless GetWirelessProperty "vv" $networkId essid]
	}

	proc getChannelFor {networkId} {
		return [callOnWireless GetWirelessProperty "vv" $networkId channel]
	}

	proc getBSSIDFor {networkId} {
		return [callOnWireless GetWirelessProperty "vv" $networkId bssid]
	}

	proc getEncryptionModeFor {networkId} {
		return [callOnWireless GetWirelessProperty "vv" $networkId encryption_method]
	}

	proc getQualityFor {networkId} {
		return [callOnWireless GetWirelessProperty "vv" $networkId quality]
	}

	proc getModeFor {networkId} {
		return [callOnWireless GetWirelessProperty "vv" $networkId mode]
	}

	proc connectToWireless {networkId} {
		callOnWireless ConnectWireless $networkId
	}

	proc disconnectWireless {} {
		callOnWireless DisconnectWireless
	}

	proc isWirelessConnecting {} {
		return [callOnWireless CheckIfWirelessConnecting]
	}

	proc getwirelessConnectingMessage {} {
		return [callOnWireless CheckWirelessConnectingMessage]
	}

	proc getConnectingStatus {} {
		return [callOnWireless CheckWirelessConnectingStatus	]
	}

	proc collectDataForAllWirelessNetworks {} {
		set ret [list]
		for {set i 0} {$i < [getNumberOfNetworks]} {incr i} {
			dict set a id $i
			dict set a ssid [getSSIDFor $i]
			dict set a bssid [getBSSIDFor $i]
			dict set a channel [getChannelFor $i]
			dict set a encryptionMode [getEncryptionModeFor $i]
			dict set a quality [getQualityFor $i]
			dict set a mode [getModeFor $i]
			lappend ret $a
		}
		return $ret
	}

	namespace export connect disconnect collectDataForAllWirelessNetworks

}
