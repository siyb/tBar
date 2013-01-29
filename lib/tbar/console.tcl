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
	dict set sys(buildinCommand) "log" "hasSubCommands" 1
	dict set sys(buildinCommand) "log" "subCommands" [list "on" "off" "status"]

	dict set sys(buildinCommand) "log" "on" "hasSubCommands" "0"
	dict set sys(buildinCommand) "log" "on" "info" [list \
		"set geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) geekosphere::tbar::console::logDispatch" \
		"Console logging enabled" \
		"Enables dispatching of tBar logs to the console"]

	dict set sys(buildinCommand) "log" "off" "hasSubCommands" 0
	dict set sys(buildinCommand) "log" "off" "info" [list \
		"set geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) \"\"" \
		"Console logging disabled" \
		"Disables dispatching of tBar logs to the console"]

	dict set sys(buildinCommand) "log" "status" "hasSubCommands" 0
	dict set sys(buildinCommand) "log" "status" "info" [list \
		"logStatus" \
		"" \
		"Displays the dispatching status of tBar logs"]	

	dict set sys(buildinCommand) "clear" "hasSubCommands" 0
	dict set sys(buildinCommand) "clear" "info" [list \
		"cls" \
		"Console Cleared" \
		"Clears the console"]

	dict set sys(buildinCommand) "help" "hasSubCommands" 0
	dict set sys(buildinCommand) "help" "info" [list \
		"help" \
		"" \
		"Displays this help"]
	
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
		$sys(text) yview moveto 1
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
		insertTextIntoConsoleWindow ">> $text" 1 input
	}

	proc printHelp {} {
		variable sys
		dict for {key val} $sys(buildinCommand) {
			set hasSubCommands [dict get $sys(buildinCommand) $key "hasSubCommands"]
			insertTextIntoConsoleWindow "${key}:" 0 success
			if {$hasSubCommands} {
				set subCommandList [dict get $sys(buildinCommand) $key "subCommands"]
				foreach subCommand $subCommandList {
					set info [dict get $sys(buildinCommand) $key $subCommand "info"] 
					insertTextIntoConsoleWindow "\t$subCommand" 0 success
					insertTextIntoConsoleWindow "\t\t[lindex $info 2]" 0 success
				}

			} else {
				set info [dict get $sys(buildinCommand) $key "info"]
				insertTextIntoConsoleWindow "\t[lindex $info 2]" 0 success
			}
		}
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
		return [dict exists $sys(buildinCommand) [lindex $line 0]]
	}

	proc runBuildinCommand {line} {
		variable sys
		set splitLine [split $line]
		set cmd [lindex $splitLine 0]
		set sub [lindex $splitLine 1]
		if {$cmd eq ""} {
			printError "Please specify a command"
			return
		}
		set info [dict get $sys(buildinCommand) $cmd]
		set hasSubCommands [dict get $sys(buildinCommand) $cmd "hasSubCommands"]

		if {$sub eq "" && $hasSubCommands} {
			printError "Command '$cmd' requires a sub command"
			return
		}

		if {$sub ne ""} {
			set command [lindex [dict get $sys(buildinCommand) $cmd $sub "info"] 0]
		} else {
			set command [lindex [dict get $sys(buildinCommand) $cmd "info"] 0]
		}
		{*}$command
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
		$sys(text) configure -state disabled
	}

	proc help {} {
		variable sys
		printHelp
	}

	proc logStatus {} {
		if {$geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) eq "geekosphere::tbar::console::logDispatch"} {
			printMessage "Log dispatching enabled"
		} else {
			printMessage "Log dispatching disabled"
		}
	}
	if {[catch {
		geekosphere::tbar::ipc::registerProc launchConsole
	} err]} {
		log "WARNING" "Problems registering launchConsole IPC, $::errorInfo"
	}
}
