namespace eval geekosphere::tbar::console::command::ipc {

	dict set geekosphere::tbar::console::sys(buildinCommand) "ipc" "hasSubCommands" 1
	dict set geekosphere::tbar::console::sys(buildinCommand) "ipc" "subCommands" [list "show" "run"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "ipc" "show" "hasSubCommands" "0"
	dict set geekosphere::tbar::console::sys(buildinCommand) "ipc" "show" "info" [list \
		"geekosphere::tbar::console::command::ipc::show" \
		"" \
		"Lists all available IPC actions"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "ipc" "run" "hasSubCommands" "0"
	dict set geekosphere::tbar::console::sys(buildinCommand) "ipc" "run" "info" [list \
		"geekosphere::tbar::console::command::ipc::run" \
		"" \
		"Run IPC command"]


	proc show {} {
		set ipcList [geekosphere::tbar::ipc::obtainIPCList]
		foreach item $ipcList {
			geekosphere::tbar::console::printMessage $item
		}	
	}

	proc run {args} {
		if {[llength $args] != 1} {
			geekosphere::tbar::console::printError "Please specify the ipc command to run"
			return
		}
		geekosphere::tbar::ipc::sendIPCCommand {*}[split [lindex $args 0] "#"]
	}

}
