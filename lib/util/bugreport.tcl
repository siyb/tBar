package provide bugreport

package require util

catch { namespace import ::geekosphere::tbar::util::* }
namespace eval geekosphere::tbar::bugreport {

	proc getBugReportData {message} {
		variable sys
		variable conf

		dict set data timeStamp [clock format [clock seconds] -format %+]
		dict set data version $sys(bar,version)
		dict set data executable [info nameofexecutable
		dict set data script [info script]
		dict set data tcl [info patchlevel]
		dict set data os $::tcl_platform(os)
		dict set data osversion $::tcl_platform(osVersion)
		dict set data threaded $::tcl_platform(threaded)
		dict set data machine $::tcl_platform(machine)
		dict set data errorInfo [split $::errorInfo "\n"]
		dict set data errorCode $::errorCode
		
		foreach item [info loaded] {
			set sitem [split $item]
			lappend packages [Package new [lindex $sitem 1] [lindex $sitem 2]]
		}
		dict set packages $packages

		foreach {key value} [array get geekosphere::tbar::conf] {
			lappend config [Config new $key $value]
		}
		dict set data config $config
		
		set sysArrays [list]
		getSysArrays ::geekosphere sysArrays	
		foreach sysArray [getSysArrays ::geekosphere] {
			foreach {item value} [array get $sysArray] {
				lappend pairs [new SysArrayPair $item $value]
			}
			lappend sysArrays [SysArray new $sysArray $pairs] 
		}
		dict set data sysArrays $sysArrays
	}

	oo::class create Package {
	
		constructor {packageName_ packagePath_} {
			my variable packageName; set packageName $packageName_
			my variable packagePath; set packagePath $packagePath_
		}
		
		method packageName {} {
			my variable packageName
			return $packageName
		}

		method packagePath {} {
			my variable packagePath
			return $packagePath
		}
	}

	oo::class create Pair {

		constructor {key_ value_} {
			my variable key; set key $key_
			my variable value; set value $value_
		}

		method key {} {
			my variable key
			return $key
		}

		method value {} {
			my variable value
			return $value
		}
	}

	oo::class create Config {
		superclass Pair
	}

	oo::class create SysArray {
		
		constructor {name_ pairs_} {
			my variable name; set name $name_
			my variable pairs; set pairs $pairs_
		}

		method name {} {
			my variable name
			return $name
		}

		method pairs {} {
			my variable pairs
			return $pairs
		}
	}

	oo::class create SysArrayPair {
		superclass Pair
	}
}
