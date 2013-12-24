namespace eval geekosphere::tbar::console::command::history {
	dict set geekosphere::tbar::console::sys(buildinCommand) "history" "hasSubCommands" 1
	dict set geekosphere::tbar::console::sys(buildinCommand) "history" "subCommands" [list "show" "clear"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "history" "show" "hasSubCommands" "0"
	dict set geekosphere::tbar::console::sys(buildinCommand) "history" "show" "info" [list \
		"geekosphere::tbar::console::command::history::showHistory" \
		"" \
		"Shows the console history"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "history" "clear" "hasSubCommands" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "history" "clear" "info" [list \
		"geekosphere::tbar::console::command::history::clearHistory" \
		"History cleared!" \
		"Clear the console history"]

	proc showHistory {} {
		foreach item $geekosphere::tbar::console::sys(history,data) {
			geekosphere::tbar::console::printMessage $item
		}
	}

	proc clearHistory {} {
		set geekosphere::tbar::console::sys(history,data) [list]
	}


}
