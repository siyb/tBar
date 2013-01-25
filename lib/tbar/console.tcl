package provide tconsole 1.0

package require tipc
package require util
package require logger

catch {
	namespace import ::tcl::mathop::*
}

namespace eval geekosphere::tbar::console {
	initLogger
	
	dict set sys(buildinCommand) "log" { 
		"set geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) geekosphere::tbar::console::logDispatch"
		"Console logging enabled"
	}
	dict set sys(buildinCommand) "nolog" {
		"set geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) \"\""
		"Console logging disabled"
	}

	# window path related variables
	set sys(window) [geekosphere::tbar::util::generateComponentName]
	set sys(frame) $sys(window).frame
	set sys(text) $sys(frame).text
	set sys(entry) $sys(frame).entry

	proc launchConsole {} {
		variable sys
		if {[winfo exists $sys(window)]} {
			return
		}
		toplevel $sys(window)
		pack [frame $sys(frame)] -fill both -expand 1
		pack [text $sys(text)] -fill both -expand 1 -side top -anchor s
		$sys(text) configure -state disabled
		pack [entry $sys(entry)] -fill x -expand 1 -side bottom -anchor s 
		
		set geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) geekosphere::tbar::console::logDispatch

		bind $sys(entry) <Return> {
			geekosphere::tbar::console::evalLine [geekosphere::tbar::console::getTextFromEntryAndClear]
		}
	}

	proc insertTextIntoConsoleWindow {text doLog} {
		variable sys
		if {$doLog} {
			log "DEBUG" "Inserting text $text"
		}
		$sys(text) configure -state normal
		$sys(text) insert end "$text\n"
		$sys(text) configure -state disabled
	}

	proc getTextFromEntryAndClear {} {
		variable sys
		set r [$sys(entry) get]
		$sys(entry) delete 0 end
		return $r
	}

	proc evalLine {line} {
		insertTextIntoConsoleWindow $line 1
		if {[isBuildinCommand $line]} {
			runBuildinCommand $line
		} else {
			if {[catch {
				uplevel #0 {*}$line
			} err]} {
				insertTextIntoConsoleWindow $::errorInfo
			} else {
				insertTextIntoConsoleWindow "OK"
			}
		}
	}

	proc isBuildinCommand {line} {
		variable sys
		return [dict exists $sys(buildinCommand) $line]
	}

	proc runBuildinCommand {line} {
		variable sys
		set commandList [dict get $sys(buildinCommand) $line]
		set command [lindex $commandList 0]
		set message [lindex $commandList 1]
		{*}$command
		insertTextIntoConsoleWindow $message 1
	}

	proc logDispatch {message} {
		insertTextIntoConsoleWindow $message 0
	}

	if {[catch {
		geekosphere::tbar::ipc::registerProc launchConsole
	} err]} {
		log "WARNING" "Problems registering launchConsole IPC, $::errorInfo"
	}
}
