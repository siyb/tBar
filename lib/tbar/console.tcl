package provide tconsole 1.0

package require tipc
package require util
package require logger

catch {
	namespace import ::tcl::mathop::*
}

namespace eval geekosphere::tbar::console {
	initLogger

	variable conf
	variable sys
	set sys(buildinCommand) [dict create]
	set sys(history,data) [list]
	set sys(history,pointer) 0

	# pkgIndex error catching \o/
	catch {	
		lappend conf(command,path) [file join / usr lib tbar tbar consolecmd]
		lappend conf(command,path) [file join $geekosphere::tbar::sys(user,home) consolecmd]
	}
	log "INFO" "Command paths: $conf(command,path)"

	foreach dir $conf(command,path) {
		if {![file exists $dir]} {
			log "WARNING" "'$dir' does not exist and will not be searched for console commands"
			continue;
		}
		if {![file isdirectory $dir]} {
			log "WARNING" "'$dir' is no directory and will not be searched for console commands"
		       	continue;
		}
		foreach file [glob [file join $dir *]] {
			log "INFO" "Attempting to source '$file'"
			if {[catch {
				source $file
			}]} {
				log "WARNING" "Error while sourcing command file '$file': $::errorInfo"
			} else {
				log "INFO" "Command file '$file' has been loaded"
			}
		}
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
		pack [text $sys(text) -font $geekosphere::tbar::conf(font,sysFont)] -fill both -expand 1 -side top -anchor s
		$sys(text) configure -state disabled
		configureTags
		pack [entry $sys(entry) -font $geekosphere::tbar::conf(font,sysFont)] -fill x -side bottom -anchor s -after $sys(text) 
		
		set geekosphere::tbar::util::logger::loggerSettings(dispatchCommand) geekosphere::tbar::console::logDispatch

		bind $sys(entry) <Return> {
			geekosphere::tbar::console::evalLine [geekosphere::tbar::console::getTextFromEntryAndClear]
		}
		bind $sys(entry) <Up> {
			$geekosphere::tbar::console::sys(entry) delete 0 end
			$geekosphere::tbar::console::sys(entry) insert 0 [geekosphere::tbar::console::getNextHistEntry]
		}
		bind $sys(entry) <Down> {
			$geekosphere::tbar::console::sys(entry) delete 0 end
			$geekosphere::tbar::console::sys(entry) insert 0 [geekosphere::tbar::console::getPrevHistEntry]
		}
		focus $sys(entry)
	}

	proc getNextHistEntry {} {
		variable sys
		log "DEBUG" "Hist: $sys(history,data)"
		incr sys(history,pointer)
		if {$sys(history,pointer) > [- [llength $sys(history,data)] 1]} {
			set sys(history,pointer) 0
		}
		return [lindex $sys(history,data) $sys(history,pointer)]
	}

	proc getPrevHistEntry {} {
		variable sys
		log "DEBUG" "Hist: $sys(history,data)"
		set sys(history,pointer) [- $sys(history,pointer) 1]
		if {$sys(history,pointer) < 0} {
			set sys(history,pointer) [llength $sys(history,data)]
		}
		return [lindex $sys(history,data) $sys(history,pointer)]
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

	proc getTextFromEntryAndClear {} {
		variable sys
		set r [$sys(entry) get]
		$sys(entry) delete 0 end
		return $r
	}

	proc evalLine {line} {
		variable sys
		lappend sys(history,data) $line
		set sys(history,pointer) [- [llength $sys(history,data)] 1]
		printInput $line
		if {[isBuildinCommand $line]} {
			runBuildinCommand $line
		} else {
			if {[catch {
				set res [uplevel #0 {*}$line]
			} err]} {
				printError $::errorInfo
			} else {
				printSuccess "OK: $res"
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

	if {[catch {
		geekosphere::tbar::ipc::registerProc launchConsole
	} err]} {
		log "WARNING" "Problems registering launchConsole IPC, $::errorInfo"
	}
}
