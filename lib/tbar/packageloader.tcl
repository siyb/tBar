package provide packageloader 1.0
package require struct::record
package require logger

rename unknown _original_unknown

catch { namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::packageloader {
	variable sys

	# a list containing records for all registered procs
	set sys(widgetRecords) [list]

	# a record storing package information on proc (which "proc" needs which package), including proc
	# parameters and their package dependency
	set sys(procRecord) ""
	
	# a record for widget parameters package dependencies. this record is par of sys(procRecord)
	set sys(parameterRecord) ""
	
	# stores the package loading error of the last package loading attempt
	set sys(errorMessage) ""

	# saves the init state
	set sys(hasBeenInit) 0

	#
	# Accessible from outside
	#

	# define packages that are generally required by your widget
	# 
	# 	proc - the proc used to create and start the widget
	# 	args - a list of packages that need to be present to load the widget	
	proc generallyRequires {proc args} {
		init
		registerProcWithPackageLoader $proc
		addGeneralPackagesToProcRecord $proc $args
	}

	# define packages that are required by the widget on a parameter basis.
	# 
	# 	proc - the proc used to create and start the widget
	# 	parameter - the parameter that requires a certain package to be present
	# 	args - a list of packages the parameter depends on
	proc parameterRequires {proc parameter args} {
		init
		registerProcWithPackageLoader $proc
		addParameterPackagesToProcRecord $proc $parameter $args
	}

	#
	# Namespace internal
	#
	
	# init code moved here to prevent errors on pkgIndex creation
	proc init {} {
		variable sys
		if {!$sys(hasBeenInit)} {
			initLogger
			set sys(procRecord) [::struct::record define procRecord {procName generalPackage parameterPackages}]
			set sys(parameterRecord) [::struct::record define parameterRecord {parameter packageList}]
			set sys(hasBeenInit) 1
		}
	}

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
		log "DEBUG" "Adding trace for '$proc'"
		trace add execution $proc enter traceCallback
	}

	proc argumentProcessor {proc arguments} {
		log "DEBUG" "Processing arguments: '$arguments' for '$proc'"
		set generalPackageDependencies [[getRecordForProc $proc] cget -generalPackage]
		foreach package $generalPackageDependencies {
			if {![checkIfPackageCanBeLoaded $package]} {
				log "WARNING" "The package '$proc' requested '$package' to be loaded, which is not installed on the system. Make sure to install all additional dependencies as well: $generalPackageDependencies"
			}
		}
		foreach parameterRecord [getParameterRecordList $proc] {
			set parameter [$parameterRecord cget -parameter]
			set packageList [$parameterRecord cget -packageList]
			foreach package $packageList {
				if {![checkIfPackageCanBeLoaded $package]} {
					set arguments [removeParameterFromCallList $parameter $arguments]
					log "WARNING" "The parameter '$parameter' of the '$proc' widget required additional packages that are not installed on this system -> '$packageList', error caused by '$package'"
				}
			}
		}
		log "DEBUG" "Argument list after processing for '$proc': '$arguments'"
		return $arguments 
	}

	proc removeParameterFromCallList {parameterToRemove callList} {
		puts "CALLLIST '$callList' '$parameterToRemove'"
		set startPosition [lsearch $callList $parameterToRemove]
		if {$startPosition == -1} { puts "PARAMETER $parameterToRemove not found";return $callList}
		for {set endPosition [expr {$startPosition + 1}]} {$endPosition < [llength $callList]} {incr endPosition} {
			if {[string index [lindex $callList $endPosition] 0] == "-"} {
				set endPosition [expr {$endPosition -1}]
				break;
			}
		}
		return [lreplace $callList $startPosition $endPosition] 
	}

	proc checkIfPackageCanBeLoaded {package} {
		variable sys
		if {[catch {
			package require $package
		} sys(errorMessage)]} {
			set ret 0
		} else {
			set ret 1
		}
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
		log "INFO" "EXEC: $::procName {*}[geekosphere::tbar::packageloader::argumentProcessor $::procName $::callArgs]"
		catch {$::procName {*}[geekosphere::tbar::packageloader::argumentProcessor $::procName $::callArgs]} retval retoptions
		unset ::procName ::procArgs ::procBody
		return {*}$retoptions $retval
		
	} else {
		uplevel 1 [list _original_unknown {*}$args]
	}
}
