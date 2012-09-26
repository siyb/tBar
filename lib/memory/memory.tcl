package provide memory 1.2

if {![info exist geekosphere::tbar::packageloader::available]} {
	package require statusBar
	package require util
}

proc memory {w args} {
	geekosphere::tbar::widget::memory::makeMemory $w $args

	proc $w {args} {
		geekosphere::tbar::widget::memory::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

catch { namespace import ::geekosphere::tbar::util::* }
namespace eval geekosphere::tbar::widget::memory {
	
	if {$::tcl_platform(os) eq "Linux"} {
		set sys(memFile) [file join / proc meminfo]
	} else {
		error "Memory widget does not support your OS ($::tcl_platform(os)) yet. Please report this issue to help improove the software."
	}
	
	proc makeMemory {w arguments} {
		variable sys
		if {[set sys($w,showWhat) [getOption "-showwhat" $arguments]] eq ""} { error "Specify showwhat using the -showwhat option" }
		set sys($w,originalCommand) ${w}_
		set sys(memData) [parseMemfile $sys(memFile)]
		set sys($w,useSwap) [string is false [getOption "-noswap" $arguments]]
		set renderStatusBar [string is true [getOption "-renderstatusbar" $arguments]] 
		frame $w
		
		#
		# Memory
		#
		pack [label ${w}.memory] -side left

		pack [statusBar ${w}.memorystatus \
			-ta [string trimright [dict get $sys(memData) "MemTotal"] "kB"] \
			-bc "|" \
			-renderstatusbar $renderStatusBar \
			] -side left


		#	
		# Swap
		#
		if {$sys($w,useSwap)} {
			pack [label ${w}.swap] -side left

			pack [statusBar ${w}.swapstatus \
				-ta [string trimright [dict get $sys(memData) "SwapTotal"] "kB"] \
				-bc "|" \
				-renderstatusbar $renderStatusBar \
				] -side left
		}
		if {[getOption "-notext" $arguments] == 1} {
			set memtext ""
			set swaptext ""
		} elseif {$sys($w,showWhat)} {
			set memtext "FreeMem: "
			set swaptext "FreeSwap: "
		} else {
			set memtext "UsedMem: "
			set swaptext "UsedSwap: "
		}

		${w}.memory configure -text $memtext
		if {$sys($w,useSwap)} { ${w}.swap configure -text $swaptext }
		
		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_

		# run configuration
		action $w configure $arguments
		
		# mark the widget as initialized
		set sys($w,initialized) 1
	}
	
	proc isInitialized {w} {
		variable sys
		return [info exists sys($w,initialized)]
	}

	proc updateWidget {w} {
		variable sys
		set sys(memData) [parseMemfile $sys(memFile)]
		
		# MEMORY
		# free
		if {$sys($w,showWhat)} {
			set swap [string trimright [dict get $sys(memData) "SwapFree"] "kB"]
			set memory [freeMem]
		# used
		} else {
			set swap [usedSwap]
			set memory [usedMem]
		}
		${w}.memorystatus update $memory
		
		# SWAP
		if {$sys($w,useSwap)} {
			# free
			if {$sys($w,showWhat)} {
				set swap [string trimright [dict get $sys(memData) "SwapFree"] "kB"]
			# used
			} else {
				set swap [usedSwap]
			}
			${w}.swapstatus update $swap
		}
		
		
	}
	
	proc action {w args} {
		variable sys
		set args [join $args]
		set command [lindex $args 0]
		set rest [lrange $args 1 end]
		if {$command eq "configure"} {
			foreach {opt value} $rest {
				switch $opt {
					"-fg" - "-foreground" {
						changeForegroundColor $w $value
					}
					"-bg" - "-background" {
						changeBackgroundColor $w $value
					}
					"-bc" {
						changeBarcharacter $w $value
					}
					"-gc" - "-graphicscolor" {
						changeGraphicColor $w $value
					}
					"-showwhat" {
						if {[isInitialized $w]} { error "Showwhat cannot be modified after widget has been initialized" }
					}
					"-noswap" {
						if {[isInitialized $w]} { error "Noswap cannot be modified after widget has been initialized" }
					}
					"-renderstatusbar" {
						if {[isInitialized $w]} { error "Renderstatusbar cannot be modified after widget has been initialized" }
					}
					"-font" {
						changeFont $w $value
					}
					"-notext" {
					}
					default {
						error "${opt} not supported"
					}
				}
			}
		} elseif {$command == "update"} {
			updateWidget $w
		} else {
			error "Command ${command} not supported"
		}
	}

	# get used memory in percent
	# used = used - (buffers + cached)
	proc usedMem {} {
		variable sys
		set free [string trimright [dict get $sys(memData) "MemFree"] "kB"]
		set total [string trimright [dict get $sys(memData) "MemTotal"] "kB"]
		set cached [string trimright [dict get $sys(memData) "Cached"] "kB"]
		set buffers [string trimright [dict get $sys(memData) "Buffers"] "kB"]
		return [expr {$total - $free - ($buffers + $cached)}]
	}
	
	# get free memory
	# free = free + bufferes + cached
	proc freeMem {} {
		variable sys
		set free [string trimright [dict get $sys(memData) "MemFree"] "kB"]
		set cached [string trimright [dict get $sys(memData) "Cached"] "kB"]
		set buffers [string trimright [dict get $sys(memData) "Buffers"] "kB"]
		return [expr {$free + ($buffers + $cached)}]
	}

	# get used swap in percent
	proc usedSwap {} {
		variable sys
		set free [string trimright [dict get $sys(memData) "SwapFree"] "kB"]
		set total [string trimright [dict get $sys(memData) "SwapTotal"] "kB"]
		return [expr {$total - $free}]
	}
	
	# gets all required information from memfile
	proc parseMemfile {file} {
		return  [geekosphere::tbar::util::parseProcFile $file [list "MemTotal" "MemFree" "SwapTotal" "SwapFree" "Buffers" "Cached"]]
	}
	
	#
	# Widget configuration procs
	#
	
	proc changeForegroundColor {w color} {
		variable sys
		${w}.memory configure -fg $color
		${w}.memorystatus configure -fg $color
		if {$sys($w,useSwap)} {
			${w}.swap configure -fg $color
			${w}.swapstatus configure -fg $color
		}
	}
	
	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		${w}.memory configure -bg $color
		${w}.memorystatus configure -bg $color
		if {$sys($w,useSwap)} {
			${w}.swap configure -bg $color
			${w}.swapstatus configure -bg $color
		}
	}
	
	proc changeGraphicColor {w color} {
		variable sys
		${w}.memorystatus configure -gc $color
		if {$sys($w,useSwap)} { ${w}.swapstatus configure -gc $color }
	}
 	
	proc changeBarcharacter {w character} {
		variable sys
		${w}.memorystatus configure -bc $character
		if {$sys($w,useSwap)} { ${w}.swapstatus configure -bc $character }
	}
	
	proc changeFont {w font} {
		variable sys
		${w}.memory configure -font $font
		${w}.memorystatus configure -font $font
		if {$sys($w,useSwap)} {
			${w}.swap configure -font $font
			${w}.swapstatus configure -font $font
		}
	}
}
