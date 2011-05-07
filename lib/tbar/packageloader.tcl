package provide packageloader 1.0
package require struct::record

rename package _package
rename unknown _original_unknown
proc package {args} {
	if {[lindex $args 0] eq "require"} {
		error "Use the geekosphere::tbar::packageloader to load packages!"
	}
}

namespace eval geekosphere::tbar::packageloader {
	variable sys
	set sys(widgetRecords) [list]
	set sys(procRecord) [::struct::record define procRecord {procName generalPackage parameterPackages}]
	set sys(parameterRecord) [::struct::record define parameterRecord {parameter packageList}]
	set sys(errorMessage) ""
	
	#
	# Accessible from outside
	#
	
	proc generallyRequires {proc args} {
		registerProcWithPackageLoader $proc
		addGeneralPackagesToProcRecord $proc $args
	}

	proc parameterRequires {proc parameter args} {
		registerProcWithPackageLoader $proc
		addParameterPackagesToProcRecord $proc $parameter $args
	}

	#
	# Namespace internal
	#

	# print all deps (for debugging)
	proc printAllDeps {} {
		variable sys
		foreach record $sys(widgetRecords) {
			puts "--- [$record cget -procName] ---"
			puts "General Deps: [$record cget -generalPackage]"
			foreach parameterRecord [$record cget -parameterPackages] {
				puts "Parameter: [$parameterRecord cget -parameter] Deps: [$parameterRecord cget -packageList]"
			}
		}
	}

	# registers the filter trace for the given proc	
	proc registerProcWithPackageLoader {proc} {
		variable sys
		if {[isProcRegisteredWithPackageLoader $proc]} { return }
		registerProcForArgsFiltering $proc
		set record [$sys(procRecord) $proc]
		$record configure -procName $proc
		$record configure -generalPackage [list]
		$record configure -parameterPackages [list]
		lappend sys(widgetRecords) $record	
	}

	# check if the given proc is registered with the filter trace
	proc isProcRegisteredWithPackageLoader {proc} {
		if {[getRecordForProc $proc] == -1} {
			return 0
		} else {
			return 1
		}
	}

	# add a general package dependencies to the given proc
	proc addGeneralPackagesToProcRecord {proc packageList} {
		if {[set record [getRecordForProc $proc]] != -1} {
			set generalList [$record cget -generalPackage]
			foreach package $packageList {
				if {[lsearch $generalList $package] == -1} { lappend generalList $package }
			}
			$record configure -generalPackage $generalList
		}
	}

	# add parameter dependencies to the given proc
	proc addParameterPackagesToProcRecord {proc parameter packageList} {
		variable sys
		if {[set record [getRecordForParameter $proc $parameter]] == -1} {
			set record [$sys(parameterRecord) $parameter]
			$record configure -parameter $parameter
			$record configure -packageList [list]
		}
		set parameterPackageList [$record cget -packageList]
		foreach newPackage $packageList {
			lappend parameterPackageList $newPackage
		}
		$record configure -packageList $parameterPackageList
		addParameterRecordToProcRecord $proc $record
	}

	# adds a parameter record to the overall procrecord
	proc addParameterRecordToProcRecord {proc parameterRecord} {
		set procRecord [getRecordForProc $proc]
		set parameterList [$procRecord -parameterPackages]
		if {[lsearch $parameterList $parameterRecord] != -1} { return }
		set parameterRecordList [$procRecord cget -parameterPackages]
		lappend parameterRecordList $parameterRecord
		$procRecord configure -parameterPackages $parameterRecordList
	}

	# return the parameter record for the specified parameter
	proc getRecordForParameter {proc parameter} {
		variable sys
		set parameterRecordList [getParameterRecordList $proc]
		if {$parameterRecordList != -1} {
			foreach record $parameterRecordList {
				set parameterName [$record cget -parameter]
				if {$parameterName eq $parameter} {
					return $record
				}
			}
		}
		return -1
	}

	# returns the complete list of parameter records of the given proc
	proc getParameterRecordList {proc} {
		variable sys 	
		if {[set record [getRecordForProc $proc]] != -1} {
			return [$record cget -parameterPackages]
		}
		return -1
	}
	
	# get the record, which stores general and parameter dependencies for the specified proc
	proc getRecordForProc {proc} {
		variable sys
		foreach record $sys(widgetRecords) {
			if {[$record cget -procName] eq $proc} {
				return $record
			}
		}
		return -1
	}

	proc registerProcForArgsFiltering {proc} {
		trace add execution $proc enter traceCallback
	}

	proc argumentProcessor {proc arguments} {
		foreach parameterRecord [getParameterRecordList $proc] {
			set parameter [$parameterRecord cget -parameter]
			set packageList [$parameterRecord cget -packageList]
			foreach package $packageList {
				if {![checkIfPackageCanBeLoaded $package]} {
					set arguments [removeParameterFromCallList $parameter $arguments]
				}
			}
		}
		return $arguments 
	}

	proc removeParameterFromCallList {parameterToRemove callList} {
		set position [lsearch $callList $parameterToRemove]
		if {$position != -1} { set callList [lreplace $callList $position $position] }
		return $callList
	}

	proc checkIfPackageCanBeLoaded {package} {
		variable sys
		rename package package_tmp
		rename _package package
		if {[catch {
			_package require $package
		} sys(errorMessage)]} {
			set ret 0
		} else {
			set ret 1
		}
		rename package _package
		rename package_tmp package
		return $ret
	}

	namespace export generallyRequires parameterRequires
}

proc traceCallback {args} {
	set procCall [lindex $args 0]
	set ::callArgs [lrange $procCall 1 end]
	set ::procName [lindex $procCall 0]
	set ::procArgs [info args $::procName]
	set ::procBody [info body $::procName]
	rename $::procName ""
}

proc unknown args {
	set command [lindex $args 0]
	if {[info exists ::procName] && $command == $::procName} {
		proc $::procName $::procArgs $::procBody
		$::procName {*}[geekosphere::tbar::packageloader::argumentProcessor $::procName $::callArgs]
		unset ::procName ::procArgs ::procBody
	} else {
		uplevel 1 [list _original_unknown {*}$args]
	}
}
# testing
proc aTestProc {args} {
	puts "aTestProc args: $args"
}

proc bTestProc {args} {
	puts "bTestProc args: $args"
}
geekosphere::tbar::packageloader::generallyRequires aTestProc gen1 gen2 gen3
geekosphere::tbar::packageloader::generallyRequires aTestProc gen4 gen5 gen6
geekosphere::tbar::packageloader::parameterRequires aTestProc -aTestParameter para1 para2 para3
geekosphere::tbar::packageloader::parameterRequires aTestProc -aTestParameter para4 para5 para6
geekosphere::tbar::packageloader::parameterRequires aTestProc -bTestParameter para7 para8 para9

geekosphere::tbar::packageloader::generallyRequires bTestProc gen7 gen8 gen9
geekosphere::tbar::packageloader::generallyRequires bTestProc gen10 gen11 gen12
geekosphere::tbar::packageloader::parameterRequires bTestProc -cTestParameter para10 para11 para12

puts \n\n
geekosphere::tbar::packageloader::printAllDeps
aTestProc -aTestParameter -cTestParameter -dTestParameter -xTestParameter 
bTestProc -yTestParameter -cTestParameter
