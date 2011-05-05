package provide packageloader 1.0

rename package _package
rename unknown _original_unknown
proc package {args} {
	error "Use the geekosphere::tbar::packageloader to load packages!"
}

namespace eval geekosphere::tbar::packageloader {
	variable sys
	proc generallyRequires {command args} {
		foreach package $args {
			_package require $package
		}
	}

	proc parameterRequires {command parameter args} {

	}

	proc registerProcForArgsFiltering {proc} {
		trace add execution $proc enter geekosphere::tbar::packageloader::traceCallback
	}

	proc traceCallback {args} {
		set procCall [lindex $args 0]
		set callArgs [lrange $procCall 1 end]
		set ::procName [lindex $procCall 0]
		set ::procArgs [info args $::procName]
		set ::procBody [info body $::procName]
		rename $::procName ""
	}

	proc filterArguments {arguments} {
		return $arguments
	}
}

proc unknown args {
	set command [lindex $args 0]
	if {$command == $::procName} {
		proc $::procName $::procArgs $::procBody
		$::procName {*}[geekosphere::tbar::packageloader::filterArguments $::procArgs]
		unset ::procName ::procArgs ::procBody
	} else {
		uplevel 1 [list _original_unknown {*}$args]
	}
}

#proc test {a b} {
#        puts "a: $a b: $b"
#}

#geekosphere::tbar::packageloader::registerProcForArgsFiltering test

#test 1 2
