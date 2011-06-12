package provide api 1.0

package require logger

catch { namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::api {
	initLogger
        variable sys

	set sys(registeredAPIs) [dict create]

	set sys(currentApi) ""

	# The API used in successive calls to "call"
	#
	#	api - the API all successive calls are redirected to
	#
	proc useApi {api} {
		variable sys
		if {![isApiRegistered $api]} {
			error "The API '$api' is not registered."
		}
		set sys(currentApi) $api
	}

	# Registers an API with the API manager. The criteria for a valid API, with the name "Foo", are:
	#
	# 1) The API must provide package Foo
	# 2) The API namespace must be geekosphere::tbar::api::Foo
	# 3) The API must contain the proc Foo::init {}, the proc needs to return a list containing
	#    all procs that should be accessible from the API interface as well as possible parameters:
	#    {proc1 {parameter1 parameter2 parameter3} proc2 {parameter1 parameter2 parameter3}}
	#
	#	api - the api to register.
	#
	proc registerApi {api} {
		package require $api
		if {[catch {
			if {![isApiRegistered $api]} {
				registerApiInStruct $api [::geekosphere::tbar::api::${api}::init]
				log "INFO" "API '$api' registered"
			}
		} err]} {
			log "WARNING" "API $api could not be loaded: $::errorInfo"
		}
	}

	# Will auto create a list of available functions to be returned by the init proc.
	# All procs starting with h_*, will be ignored by this proc.
	#
	proc autocreateProcList {} {
		uplevel 1 {
			set r [list]
			foreach p [info procs] {
				if {![string match h_* $p] && $p ne "init"} {
					lappend r $p [info args $p]
				}
			}
			return $r
		}
	}

	# Make an API call
	#
	#	command - the command (proc) to call in the API
	#	args - the command arguments
	#
	proc call {command args} {
		variable sys
		if {![isCommandRegisteredForApi $sys(currentApi) $command]} {
			error "The proc '$command' has not been registered for API '$sys(currentApi)'"
		}
		if {[set parameterCount [getArgumentCountForProcInApi $sys(currentApi) $command]] != [set actualCount [llength $args]]} {
			error "The parameter count of the proc '$command' for API '$sys(currentApi)' should be '$parameterCount' but was '$actualCount'"
		}
		::geekosphere::tbar::api::$sys(currentApi)::${command} {*}$args
	}

	# Returns a list of all exported API procs of the currently
	# selected API.
	#
	proc explore {} {
		variable sys
		set r [list]
		dict for {api proc} $sys(registeredAPIs) {
			lappend r $proc
		}
		return $r
	}

	# Returns a list of all registered APIs
	#
	proc exploreApis {} {
		variable sys
		return [dict keys $sys(registeredAPIs) *]
	}

	#
	# Namespace internal
	#

	proc getArgumentCountForProcInApi {api proc} {
		variable sys
		return [llength [dict get $sys(registeredAPIs) $api $proc]]
	}

	proc isCommandRegisteredForApi {api proc} {
		variable sys
		return [dict exists $sys(registeredAPIs) $api $proc]
	}

	proc isApiRegistered {api} {
		variable sys
		return [dict exists $sys(registeredAPIs) $api]
	}

	proc registerApiInStruct {api procList} {
		variable sys
		foreach {proc parameters} $procList {
			dict set sys(registeredAPIs) $api $proc $parameters
		}
	}
	
	namespace export registerApi useApi autocreateProcList call explore exploreApis
}
