namespace eval geekosphere::tbar::console::command::uidebug {
	package require uidebug

	dict set geekosphere::tbar::console::sys(buildinCommand) "uidebug" "hasSubCommands" 1
	dict set geekosphere::tbar::console::sys(buildinCommand) "uidebug" "subCommands" [list "on" "off" "status"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "uidebug" "on" "hasSubCommands" "0"
	dict set geekosphere::tbar::console::sys(buildinCommand) "uidebug" "on" "info" [list \
		"geekosphere::tbar::uidebug::enableUiDebug" \
		"UI debugging enabled" \
		"Enables UI debugging"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "uidebug" "off" "hasSubCommands" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "uidebug" "off" "info" [list \
		"geekosphere::tbar::uidebug::disableUiDebug" \
		"UI debugging disabled" \
		"Disables dispatching of tBar uidebugs to the console"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "uidebug" "status" "hasSubCommands" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "uidebug" "status" "info" [list \
		"geekosphere::tbar::uidebug::isUiDebugEnabled" \
		"" \
		"Return the UI debug state (disabled / enabled)"]
}
