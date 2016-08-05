namespace eval geekosphere::tbar::console::command::widget {
	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "hasSubCommands" 1
	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "subCommands" [list "list" "unload" "ns" "sys"]

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
	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "ns" "hasSubCommand" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "ns" "info" [list \
		"geekosphere::tbar::console::command::widget::widgetNsList" \
		"" \
		"Lists all available widget namespaces"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "sys" "hasSubCommand" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "sys" "info" [list \
		"geekosphere::tbar::console::command::widget::widgetNsSysList" \
		"" \
		"Lists the content of the sys array of the given namespace"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "rehash" "hasSubCommand" 0
	dict set geekosphere::tbar::console::sys(buildinCommand) "widget" "rehash" "info" [list \
		"geekosphere::tbar::console::command::widget::rehash" \
		"Widgets Rehashed!" \
		"Rehashes (unloads and reloads) widgets from the config, clearing all in memory data"]

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

	proc rehash {} {
		geekosphere::tbar::unloadWidgets
		geekosphere::tbar::loadWidgets
	}

	proc widgetNsList {} {
		foreach ns [namespace children ::geekosphere::tbar::widget] {
			geekosphere::tbar::console::printMessage $ns
		}	       
	}

	proc widgetNsSysList {args} {
		if {[llength $args] != 1} {
			geekosphere::tbar::console::printError "Please specify a namespace"
			return
		}
		set ns [lindex $args 0]
		set fqns ::geekosphere::tbar::widget::${ns}
		geekosphere::tbar::console::printMessage "sys array for $fqns"
		foreach {key val} [array get ${fqns}::sys] {
			geekosphere::tbar::console::printMessage "sys($key): [set ${fqns}::sys($key)]"
		} 
	}
}
