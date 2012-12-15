package provide tconsole 1.0

package require tipc
package require util
package require logger

namespace eval geekosphere::tbar::console {
	initLogger

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
		
		bind $sys(entry) <Return> {
			geekosphere::tbar::console::evalLine [geekosphere::tbar::console::getTextFromEntryAndClear]

		}
	}

	proc insertTextIntoConsoleWindow {text} {
		variable sys
		log "DEBUG" "Inserting text $text"
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
		insertTextIntoConsoleWindow $line
		if {[catch {
			uplevel #0 {*}$line
		} err]} {
			insertTextIntoConsoleWindow $::errorInfo
		} else {
			insertTextIntoConsoleWindow "OK"
		}
	}

	if {[catch {
		geekosphere::tbar::ipc::registerProc launchConsole
	} err]} {
		log "WARNING" "Problems registering launchConsole IPC, $::errorInfo"
	}
}
