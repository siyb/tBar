namespace eval geekosphere::tbar::console::command::log {
	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "hasSubCommands" 1
	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "subCommands" [list "on" "off" "status" "ns" "info" "level"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "on" "hasSubCommands" "0"
	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "on" "info" [list \
		"set geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) geekosphere::tbar::console::logDispatch" \
		"Console logging enabled" \
		"Enables dispatching of tBar logs to the console"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "off" "hasSubCommands" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "off" "info" [list \
		"set geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) \"\"" \
		"Console logging disabled" \
		"Disables dispatching of tBar logs to the console"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "status" "hasSubCommands" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "status" "info" [list \
		"geekosphere::tbar::console::command::log::logStatus" \
		"" \
		"Displays the dispatching status of tBar logs"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "ns" "hasSubCommands" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "ns" "info" [list \
		"geekosphere::tbar::console::command::log::listLoggedNamespaces" \
		"" \
		"Lists all logged  namespaces"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "info" "hasSubCommands" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "info" "info" [list \
		"geekosphere::tbar::console::command::log::listLoggedNamespacesAndLogLevels" \
		"" \
		"Show all logged namespaces and their log levels"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "level" "hasSubCommands" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "level" "info" [list \
		"geekosphere::tbar::console::command::log::setLogLevelFor" \
		"Level set!" \
		"Sets the level for the given namespace"]

	proc logStatus {} {
		if {$geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) eq "geekosphere::tbar::console::logDispatch"} {
			geekosphere::tbar::console::printMessage "Log dispatching enabled"
		} else {
			geekosphere::tbar::console::printMessage "Log dispatching disabled"
		}
	}

	proc setLogLevelFor {args} {
		set validLevels [list "FATAL" "ERROR" "WARNING" "INFO" "DEBUG" "TRACE"]
		if {[llength $args] != 2} {
			geekosphere::tbar::console::printError "Please specify a namespace an a log level"
			return
		}
		set ns [lindex $args 0]
		set level [lindex $args 1]

		if  {[lsearch $validLevels $level] == -1} {
			geekosphere::tbar::console::printError "Invalid log level ($level): $validLevels"
			return
		}
		if  {[lsearch [getLoggedNamespaces ::geekosphere::tbar] $ns] == -1} {
			geekosphere::tbar::console::printError "Namespace '$ns' is not configured for logging"
			return
		}
		set ${ns}::logger(level) $level
	}

	proc listLoggedNamespacesAndLogLevels {} {
		foreach ns [getLoggedNamespaces ::geekosphere::tbar] {
			geekosphere::tbar::console::printMessage "${ns}: [set ${ns}::logger(level)]"
		}
	}

	proc listLoggedNamespaces {} {
		foreach ns [getLoggedNamespaces ::geekosphere::tbar] {
			geekosphere::tbar::console::printMessage $ns
		}
	}

	proc getLoggedNamespaces {ns} {
		getNestedChildNameSpaces $ns stack
		foreach ns_ $stack {
			if {[info exists ${ns_}::logger(init)]} {
				lappend ret $ns_
			}
		}
		return $ret
	}

	proc getNestedChildNameSpaces {ns result} {
		upvar 1 $result stack
		set children [namespace children $ns]
		lappend stack {*}$children
		foreach c $children {
			getNestedChildNameSpaces $c $result
		}
	}
}
