namespace eval geekosphere::tbar::console::command::clear {
	dict set geekosphere::tbar::console::sys(buildinCommand) "clear" "hasSubCommands" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "clear" "info" [list \
		"geekosphere::tbar::console::command::clear::cls" \
		"Console Cleared" \
		"Clears the console"]

	proc cls {} {
		variable sys
		$geekosphere::tbar::console::sys(text) configure -state normal
		$geekosphere::tbar::console::sys(text) delete 0.0 end
		$geekosphere::tbar::console::sys(text) configure -state disabled
	}


}
