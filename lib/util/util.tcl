package provide util 1.1

package require logger

catch { namespace import ::geekosphere::tbar::util::logger* }
namespace eval geekosphere::tbar::util {
	
	::geekosphere::tbar::util::logger::initLogger
	
	set sys(componentCounter) 0

	# parses a procfile formatted like "item : value", spaces between : and strings is irrelevant
	# returns a dict containing all values of lookForList
	proc parseProcFile {file lookForList} {
		set data [split [string map { " " "" "\t" ""} [read [set fl [open $file r]]]] "\n"]
		close $fl
		set returnDict [dict create]
		foreach lookFor $lookForList {
			foreach result [lsearch -all -inline $data ${lookFor}:*] {
				dict lappend returnDict $lookFor [lindex [split $result ":"] 1]
			}
		}
		return $returnDict
	}

	proc positionWindowRelativly {windowToPosition w} {
		# hack to prevent flickering caused by update:
		# 1) window will be handled by the geometry manager to position it first (size doesn't matter
		# 2) updateing window 
		# 3) positioning an resizing again
		# If this is not done, the window will appear in the upper left corner of the screen and jump to its final position -> sucks
		wm geometry $windowToPosition [getNewWindowGeometry [winfo rootx $w]  [winfo rooty $w] 0 0 [winfo height $w] [winfo screenheight $w] [winfo screenwidth $w]]
		wm overrideredirect $windowToPosition 1
		update
		if {[catch {
			wm geometry $windowToPosition [getNewWindowGeometry [winfo rootx $w]  [winfo rooty $w] [winfo reqwidth $windowToPosition] [winfo reqheight $windowToPosition] [winfo height $w] [winfo screenheight $w] [winfo screenwidth $w]]
		}]} {
			log "WARNING" "Unable to render window properly"
			return -1
		}
	}

	# TODO: does not work for the left side of X axis (if window will be broader than left limit)
	proc getNewWindowGeometry {windowRootX windowRootY newWindowWidth newWindowHeight bheight screenHeight screenWidth} {
		set posY [expr {$screenHeight - ($screenHeight - $windowRootY + $newWindowHeight)}]
		# Y is outside the screen (top), display window below the bar
		if {$posY < 0} {
			set posY [expr {$bheight + $windowRootY}]
			# if the new yPos is outside the screen (bottom), the window is to big to be displayed properly
			if {[expr {$posY + $newWindowHeight}] > $screenHeight} { error "problem rendering the window. not enough space on the Y axis" }
		}
		# if the left boarder of the window to be displayed is completly within the screen
		set posX [expr {$windowRootX + $newWindowWidth}]
		if {$posX < $screenWidth} {
			set posX $windowRootX
		} else {
			set posX [expr $screenWidth - $newWindowWidth]
		}
		return "${newWindowWidth}x${newWindowHeight}+${posX}+${posY}"
	}

	# generates component name to be used in widgets to avoid widget name collisions
	proc generateComponentName {} {
		variable sys
		set componentName "${geekosphere::tbar::sys(bar,toplevel)}component${sys(componentCounter)}"
		incr sys(componentCounter)
		return $componentName
	}

	# parses the first stand alone integer of a given string
	# a b c 54 d 64 -> 54
	# a1 b2 3 c 5 -> 3
	proc parseFirstInteger {string} {
		foreach item [split $string] {
			if {$item ne "" && [string is integer $item]} { return $item }
		}
	}
	
	# returns the value of the specified option from the optionlist
	proc getOption {option optionList} {
		foreach {opt value} $optionList {
			if {$opt eq $option} {
				return $value
			}
		}
	}
	
	# gets sys array from all widget libraries
	proc getSysArrays  {} {
		set returnList [list]
		foreach ns [namespace children ::geekosphere::tbar::widget] {
			if {[info exists ${ns}::sys]} {
				lappend returnList ${ns}::sys
			}
		}
		return $returnList
	}
	
	# returns all children of a window recursivly (also nested children)
	proc returnNestedChildren {window {clist ""}} {
		if {$clist eq ""} { set clist [list] }
		foreach child [winfo children $window] {
			lappend clist $child
			set clist [returnNestedChildren $child $clist]
		}
		return $clist
	}
	
	proc createPipe {args} {
		set channel [open |$args r]
		set pid [pid $channel]
		fconfigure $channel -blocking 0
		dict set returnDict channel $channel
		dict set returnDict pid $pid
		return $returnDict
	}
	
	proc closePipe {pipeDict} {
		catch { exec kill [dict get $fifoDict pid] }
		close [dict get $fifoDict channel]
	}
	
	namespace export *
}
