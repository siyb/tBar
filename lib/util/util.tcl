package provide util 1.1

namespace eval geekosphere::tbar::util {
	namespace export parseProcFile getNewWindowGeometry generateComponentName
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

	# calculate position to a window
	proc getNewWindowGeometry {windowRootX windowRootY newWindowWidth newWindowHeight} {
		return [getNewWindowGeometry_ $windowRootX $windowRootY $newWindowWidth $newWindowHeight $geekosphere::tbar::conf(geom,height) $geekosphere::tbar::sys(screen,height) $geekosphere::tbar::sys(screen,width)]
	}

	# TODO: does not work for the left side of X axis (if window will be broader than left limit)
	proc getNewWindowGeometry_ {windowRootX windowRootY newWindowWidth newWindowHeight bheight screenHeight screenWidth} {
		set posY [expr {$screenHeight - ($screenHeight - $windowRootY + $newWindowHeight)}]
		# Y is outside the screen (top), display window below
		if {$posY < 0} {
			set posY [expr {$bheight + $windowRootY}]
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
}
