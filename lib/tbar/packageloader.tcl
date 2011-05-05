package provide packageloader 1.0
package provide struct::record

rename package _package
rename unknown _original_unknown
proc package {args} {
	error "Use the geekosphere::tbar::packageloader to load packages!"
}

namespace eval geekosphere::tbar::packageloader {
	variable sys
	set sys(widgetRecords) [list]
	set sys(procRecord) [::struct::record define {procName generalPackage parameterPackages}]
	set sys(parameterRecord) [::struct::record define {parameter packageList}]

	#
	# Accessible from outside
	#
	
	proc generallyRequires {proc args} {
	}

	proc parameterRequires {proc parameter args} {
	}

	#
	# Namespace internal
	#
	
	proc registerProcWithPackageLoader {proc} {
		variable sys
		if {[isProcRegisteredWithPackageLoader $proc]} { return }
		set record [$sys(procRecord) $proc]
		$record configure -procName $proc
		$record configure -generalPackage [list]
		$record configure -parameterPackages [list]
		lappend sys(widgetRecords) $record	
	}

	proc isProcRegisteredWithPackageLoader {proc} {
		if {[getRecordForProc $proc] == -1} {
			return 0
		} else {
			return 1
		}
	}

	proc addGeneralPackagesToProcRecord {proc packageList} {
		if {[set record [getRecordForProc $proc]] != -1} {
			set generalList [$record cget -generalPackages]
			foreach package $packageList {
				lappend generalList $package
			}
			$record configure -generalPackage $generalList
		}
	}

	proc getRecordForProc {proc} {
		variable sys
		foreach record $sys(widgetRecords) {
			if {[$record -cget procName] eq $proc]} {
				return $record
			}
		}
		return -1
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

	namespace export generallyRequires parameterRequires
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

