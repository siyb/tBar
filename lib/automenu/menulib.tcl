package provide menulib 1.0
package require tbar_logger
package require Thread
catch {
	namespace import ::geekosphere::tbar::util::logger::*
	namespace import ::tcl::mathop::*
}
namespace eval geekosphere::tbar::widget::automenu {
	
	initLogger

	variable sys
	set sys(entryKeyPressCallback) ""
	set sys(window) .

	namespace eval autocomplete {
		variable toComplete
		variable completeList
		variable currentPositionInCompleteList

		proc getNextSuggestion {toCompl completeLi} {
			variable toComplete
			variable completeList
			variable currentPositionInCompleteList
			if {$toComplete ne $toCompl || $completeList ne $completeLi} {
				set currentPositionInCompleteList 0
				set toComplete $toCompl
				set completeList $completeLi
			}

			set filteredList [lsearch -all -inline $completeList $toCompl*]

			incr currentPositionInCompleteList
			if {$currentPositionInCompleteList > [llength $filteredList]} {
				set currentPositionInCompleteList 0
			}
			return [lindex $filteredList $currentPositionInCompleteList]
		}

		proc reset {} {
			variable toComplete
			variable completeList
			variable currentPositionInCompleteList
			set toComplete ""
			set completeList [list]
			set currentPositionInCompleteList 0
		}

		proc initialize {} {
			reset
		}

		initialize
	}

	proc fillListBoxWithExecutables {listBox executables} {
		$listBox delete 0 end
		foreach item $executables {
			$listBox insert end $item
		}
	}

	proc filterExecutables {filterString} {
		set executables [getExecutablesInPath]
		return [lsearch -all -inline $executables $filterString*]
	}

	proc getExecutablesInPath {} {
		set ret [list]
		foreach path [split $::env(PATH) ":"] {
			foreach file [glob -nocomplain $path/*] {
				set fileName [file tail $file]
				if {![file isdirectory $file] && [file executable $file] && [lsearch $ret $fileName] == -1} {
					lappend ret $fileName
				}
			}

		}
		return [lsort -dictionary $ret]
	}

	proc handleEntryKeyPress {entry listBox key} {
		variable sys		
		if {$sys(entryKeyPressCallback) ne ""} {
			$sys(entryKeyPressCallback) $sys(window) 0 $key
		}
		set curselection [$listBox curselection]
		if {$key eq "Return"} {
			handleReturn $entry $listBox $curselection
		} elseif {$key eq "Up"} {
			handleUp $entry $listBox $curselection
		} elseif {$key eq "Down"} {
			handleDown $entry $listBox $curselection
		}
		if {$key eq "Tab"} {
			handleTab $entry $listBox 
		} elseif {$key ne "Return" && $key ne "Up" && $key ne "Down"} {
			handleOtherKey $entry $listBox
		}
		if {$sys(entryKeyPressCallback) ne ""} {
			$sys(entryKeyPressCallback) $sys(window) 1 $key
		}

	}

	proc handleReturn {entry listBox curselection} {
		set command [$entry get]
		if {![isCommandInPath $command] && $curselection ne ""} {
			log "DEBUG" "'$command' from entry was not in path, trying '[$listBox get $curselection $curselection]'"
			set command [$listBox get $curselection $curselection]
		}

		log "INFO" "Executing $command -> Mainthread [thread::id]"
		set thread [thread::create { 

			proc execCommand {command} {
				if {[catch {
					package require tbar_logger
					namespace import ::geekosphere::tbar::util::logger::*
					initLogger
					set chan [open |$command a+]
					proc poll {chan} {
						log "INFO" "Thread id: [thread::id]"
						set data [read $chan]
						log "INFO" "$data"
						if {[chan eof $chan]} {
							log "INFO" "Channel $chan cannot be read any more, killing"
							if {[catch { close $chan } err]} {
								log "INFO" "Problem closing chan: $err"
							}
							log "INFO" "Stopping thread: [thread::id] -> [thread::names]"
							thread::exit
						} else {
							after 500 [list poll $chan]
						}
					}

					after 500 [list poll $chan]
				} err]} {
					log "WARNING" "Command: $command could not be executed. $::errorInfo"
				}
			}
			thread::wait 
		}]
		thread::send $thread [list execCommand $command]

		$entry delete 0 end
		focus .
		fillListBoxWithExecutables $listBox [filterExecutables ""]

	}
	proc isCommandInPath {command} {
		set commands [getExecutablesInPath]
		return [!= [lsearch $commands $command] -1]
	}

	proc handleUp {entry listBox curselection} {
		if {$curselection eq ""} {
			set newSelection 0
		} else {
			set newSelection [- $curselection 1]
		}
		$listBox selection clear 0 end
		$listBox selection set $newSelection
		$listBox see $newSelection
		$entry delete 0 end
		$entry insert 0 [$listBox get $newSelection]
	}

	proc handleDown {entry listBox curselection} {
		if {$curselection eq ""} {
			set newSelection 0
		} else {
			set newSelection [+ $curselection 1]
		}
		$listBox selection clear 0 end
		$listBox selection set $newSelection
		$listBox see $newSelection
		$entry delete 0 end
		$entry insert 0 [$listBox get $newSelection]
	}

	proc handleTab {entry listBox} {
		$entry delete 0 end
		$entry insert 0 [geekosphere::tbar::widget::automenu::autocomplete::getNextSuggestion [$entry get] [$listBox get 0 end]]
		selectListBoxItemByString $listBox [$entry get]
	}

	proc handleOtherKey {entry listBox} {
		geekosphere::tbar::widget::automenu::fillListBoxWithExecutables $listBox [geekosphere::tbar::widget::automenu::filterExecutables [$entry get]]
		geekosphere::tbar::widget::automenu::autocomplete::reset
		$listBox selection set 0
	}

	proc selectListBoxItemByString {listBox string} {
		set items [$listBox get 0 end]
		set indexOfString [lsearch $items $string]
		if {$indexOfString != -1} {
			$listBox selection clear 0 end
			$listBox selection set $indexOfString $indexOfString
			$listBox see $indexOfString
		}
	}

	proc configureListBox {listBox entry} {
		bind $listBox <ButtonRelease-1> [list geekosphere::tbar::widget::automenu::updateEntry $listBox $entry]
		$listBox configure -takefocus 0 -exportselection 0
	}

	proc configureEntry {listBox entry} {
		bind $entry <KeyRelease> [list geekosphere::tbar::widget::automenu::handleEntryKeyPress $entry $listBox %K]		
	}

	proc updateEntry {listBox entry} {
		$entry delete 0 end
		$entry insert 0 [$listBox get [$listBox curselection]]
	}

	proc setEntryKeyCallback {callBack window} {
		variable sys
		if {[info procs $callBack] eq ""} {
			error "Invalid proc $callBack"
		}
		set sys(entryKeyPressCallback) $callBack
		set sys(window) $window
	}
}


