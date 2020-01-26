namespace eval geekosphere::tbar::console::command::help {
	dict set geekosphere::tbar::console::sys(buildinCommand) "help" "hasSubCommands" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "help" "info" [list \
		"geekosphere::tbar::console::command::help::printHelp" \
		"" \
		"Displays this help"]

	proc printHelp {} {
		variable sys
		dict for {key val} $geekosphere::tbar::console::sys(buildinCommand) {
			set hasSubCommands [dict get $geekosphere::tbar::console::sys(buildinCommand) $key "hasSubCommands"]
			geekosphere::tbar::console::insertTextIntoConsoleWindow "${key}:" 0 success
			if {$hasSubCommands} {
				set subCommandList [dict get $geekosphere::tbar::console::sys(buildinCommand) $key "subCommands"]
				foreach subCommand $subCommandList {
					set info [dict get $geekosphere::tbar::console::sys(buildinCommand) $key $subCommand "info"]
					geekosphere::tbar::console::insertTextIntoConsoleWindow "\t$subCommand" 0 success
					geekosphere::tbar::console::insertTextIntoConsoleWindow "\t\t[lindex $info 2]" 0 success
				}

			} else {
				set info [dict get $geekosphere::tbar::console::sys(buildinCommand) $key "info"]
				geekosphere::tbar::console::insertTextIntoConsoleWindow "\t[lindex $info 2]" 0 success
			}
		}
	}



}
