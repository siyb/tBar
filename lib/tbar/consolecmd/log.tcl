namespace eval geekosphere::tbar::console::command::log {
	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "hasSubCommands" 1
	dict set geekosphere::tbar::console::sys(buildinCommand) "log" "subCommands" [list "on" "off" "status"]

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

	proc logStatus {} {
		if {$geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) eq "geekosphere::tbar::console::logDispatch"} {
			geekosphere::tbar::console::printMessage "Log dispatching enabled"
		} else {
			geekosphere::tbar::console::printMessage "Log dispatching disabled"
		}
	}


}
