namespace eval geekosphere::tbar::console::command::ipc {

	dict set geekosphere::tbar::console::sys(buildinCommand) "ipc" "hasSubCommands" 1
	dict set geekosphere::tbar::console::sys(buildinCommand) "ipc" "subCommands" [list "show"]

	dict set geekosphere::tbar::console::sys(buildinCommand) "ipc" "show" "hasSubCommands" "0"
	dict set geekosphere::tbar::console::sys(buildinCommand) "ipc" "show" "info" [list \
		"geekosphere::tbar::console::command::ipc::show" \
		"" \
		"Lists all available IPC actions"]

	proc show {} {
		set ipcList [geekosphere::tbar::ipc::obtainIPCList]
		foreach item $ipcList {
			geekosphere::tbar::console::printMessage $item
		}	
	}

}
