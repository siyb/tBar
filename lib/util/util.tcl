package provide util 1.1

namespace eval geekosphere::tbar::util {
	namespace export *
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
	
       # logger variables for global namespace
	set logger(log,dolog) 1
	set logger(log,level) "DEBUG"
	set logger(gen,version) "-"
	set logger(log,log2file) 1
	set logger(log,logfile) ""

	# a simple logging proc. any namespace that wishes to use this proc
	# needs the following namespace variable array:
	#
	#       - logger(log,dolog), must be boolean, determines if logging is enabled or not
	#       - logger(log,level), the loglevel
	#       - logger(gen,version), the version of the script
	#
	proc geekosphere::tbar::util::log {level message} {
		set namespace [uplevel 1 { namespace current }];# the namespace in which the logger proc was called
		namespace upvar $namespace logger logger;# get the namespace specific vars (namespace that called the proc)

		set mloglevel [getNumericLoglevel $level];# the level of the message
		set gloglevel [getNumericLoglevel $logger(log,level)];# the global log level
		if {$mloglevel == -1 || $gloglevel == -1} { return };# if one of the loglevels is unknow
		if {$mloglevel < $gloglevel} { return };# check if message should be logged
		if {$logger(log,dolog)} {
			set message "[clock format [clock seconds] -format "%+"] | $level | ${namespace} ${logger(gen,version)}: ${message}"
			puts $message
			if {$logger(log,log2file)} {
				set fl [open $logger(log,logfile) a+]; puts $fl $message; close $fl
			}
		}
	}
 
	# returns numeric loglevel
	#
	proc geekosphere::tbar::util::getNumericLoglevel {level} {
		variable tools
		set sl [lsearch -index 0 $logger(log,levels) $level]; # search the level in the level list
		if {$sl == -1} { putlog "WARNING | Loglevel invalid! (${level})"; return -1}
		return [lindex [split [lindex $logger(log,levels) $sl]] 1];# get the numeric value
	}

}
