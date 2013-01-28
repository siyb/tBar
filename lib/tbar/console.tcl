package provide tconsole 1.0

package require tipc
package require util
package require logger

catch {
	namespace import ::tcl::mathop::*
}

namespace eval geekosphere::tbar::console {
	initLogger

	#
	# Build-In Command Definitions
	#
	dict set sys(buildinCommand) "log" { 
		"set geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) geekosphere::tbar::console::logDispatch"
		"Console logging enabled"
		"Enables dispatching of tBar logs to the console"
	}
	dict set sys(buildinCommand) "nolog" {
		"set geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) \"\""
		"Console logging disabled"
		"Disables dispatching of tBar logs to the console"
	}
	dict set sys(buildinCommand) "clear" {
		"cls"
		"Cleared"
		"Clears the console"
	}
	dict set sys(buildinCommand) "help" {
		"help"
		""
		"Displays this help"
	}

	#
	# Console Color Settings
	#
	set sys(font,message) #7373FF
	set sys(font,error) #AD0000
	set sys(font,success) #008A09
	set sys(font,input) #000000

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
		wm resizable $sys(window) 0 0
		pack [frame $sys(frame)] -fill both -expand 1
		pack [text $sys(text)] -fill both -expand 1 -side top -anchor s
		$sys(text) configure -state disabled
		configureTags
		pack [entry $sys(entry)] -fill x -side bottom -anchor s -after $sys(text) 
		
		set geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) geekosphere::tbar::console::logDispatch

		bind $sys(entry) <Return> {
			geekosphere::tbar::console::evalLine [geekosphere::tbar::console::getTextFromEntryAndClear]
		}
	}

	proc configureTags {} {
		variable sys
		$sys(text) tag configure message -foreground $sys(font,message)
		$sys(text) tag configure error -foreground $sys(font,error)
		$sys(text) tag configure success -foreground $sys(font,success)
		$sys(text) tag configure input -foreground $sys(font,input)
	}

	proc insertTextIntoConsoleWindow {text doLog tag} {
		variable sys
		if {![winfo exists $sys(text)]} {
			return
		}
		if {$doLog} {
			log "DEBUG" "Inserting text $text"
		}
		set text "$text\n"
		$sys(text) configure -state normal
		$sys(text) insert end "$text" $tag
		$sys(text) configure -state disabled
	}

	proc printMessage {text} {
		variable sys
		insertTextIntoConsoleWindow $text 1 message
	}

	proc printError {text} {
		variable sys
		insertTextIntoConsoleWindow $text 1 error
	}

	proc printSuccess {text} {
		variable sys
		insertTextIntoConsoleWindow $text 1 success
	}

	proc printInput {text} {
		variable sys
		insertTextIntoConsoleWindow $text 1 input
	}

	proc printHelp {command helpText} {
		insertTextIntoConsoleWindow "-> ${command}:" 0 success
		insertTextIntoConsoleWindow "\t\t$helpText" 0 success
	}

	proc getTextFromEntryAndClear {} {
		variable sys
		set r [$sys(entry) get]
		$sys(entry) delete 0 end
		return $r
	}

	proc evalLine {line} {
		printInput $line
		if {[isBuildinCommand $line]} {
			runBuildinCommand $line
		} else {
			if {[catch {
				uplevel #0 {*}$line
			} err]} {
				printError $::errorInfo
			} else {
				printSuccess "OK"
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
		printMessage $message
	}

	proc logDispatch {message} {
		insertTextIntoConsoleWindow $message 0 #000000
	}

	#
	# Built In Command Helper Procs
	#

	proc cls {} {
		variable sys
		$sys(text) configure -state normal
		$sys(text) delete 0.0 end
		$sys(text) configure -state normal
	}

	proc help {} {
		variable sys
		dict for {key val} $sys(buildinCommand) {
			printHelp $key [lindex $val 2]
		}
	}

	if {[catch {
		geekosphere::tbar::ipc::registerProc launchConsole
	} err]} {
		log "WARNING" "Problems registering launchConsole IPC, $::errorInfo"
	}
}
