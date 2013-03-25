namespace eval geekosphere::tbar::console::command::widget {
	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "hasSubCommands" 1
	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "subCommands" [list "list" "unload"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "list" "hasSubCommands" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "list" "info" [list \
		"geekosphere::tbar::console::command::widget::list" \
		"" \
		"Displays information on loaded widgets"]	
	
	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "unload" "hasSubCommand" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "unload" "info" [list \
		"geekosphere::tbar::console::command::widget::unload" \
		"Module unloaded" \
		"Unloads the given module"]

	proc list {} {
		dict for {name info} $geekosphere::tbar::sys(widget,dict) {
			dict with info {
				geekosphere::tbar::console::printMessage "----------------------------------------"
				geekosphere::tbar::console::printMessage ""
				geekosphere::tbar::console::printMessage "Id: $name"
				geekosphere::tbar::console::printMessage "WidgetProc: $widgetName"
				geekosphere::tbar::console::printMessage "UpdateInterval: $updateInterval"
				geekosphere::tbar::console::printMessage "Arguments: $arguments"
				geekosphere::tbar::console::printMessage "Path: $path"
				geekosphere::tbar::console::printMessage ""
			}
		}
	}

	proc unload {args} {
		if {[llength $args] != 1} {
			geekosphere::tbar::console::printError "Please specify a widget to unload"
			return
		}
		set name [lindex $args 0]
		if {![dict exists $geekosphere::tbar::sys(widget,dict) $name path]} {
			geekosphere::tbar::console::printError "Widget '$name' was not loaded"
			return
		}
		geekosphere::tbar::removeWidgetFromBar $name
	}
}
