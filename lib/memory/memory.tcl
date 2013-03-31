package provide memory 1.2
if {![info exist geekosphere::tbar::packageloader::available]} {
	package require statusBar
	package require util

	package require struct
}
# TODO: use package manager
package require struct
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

		foreach window [returnNestedChildren $w] {
			bind $window <Button-1> [namespace code [list displayHistory $w]]
		}

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
			${w}.swapstatus update $swap
		}
		updateHistory $w
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

	proc displayHistory {w} {
		variable sys
		set sys($w,hiscolor) blue
		set sys($w,memHistory) ${w}.history
		if {[winfo exists $sys($w,memHistory)]} {
			destroy $sys($w,memHistory)
			unset sys($w,memHistory)
			return
		}
		toplevel $sys($w,memHistory) -bg $sys($w,background)
		foreach t [list mem swap] {
			pack [frame $sys($w,memHistory).${t} -height 30] -fill x
			pack [label $sys($w,memHistory).${t}.l -text $t -fg $sys($w,foreground) -bg $sys($w,background) -font $sys($w,font)] -side left -fill x -expand 1 
			pack [barChart $sys($w,memHistory).${t}.chart \
				-fg $sys($w,foreground) \
				-bg $sys($w,background) \
				-font $sys($w,font) \
				-gc $sys($w,hiscolor) \
				-font $sys($w,font) \
				-width 100 \
				-height 20] -side right
		}
		positionWindowRelativly $sys($w,memHistory) $w
	}
	proc updateHistory {w} {
		variable sys

		if {![info exists sys($w,hist,mem)]} {
			set sys($w,hist,mem) [::struct::stack]
		}
		if {![info exists sys($w,hist,swp)]} {
			set sys($w,hist,swp) [::struct::stack]
		}


		$sys($w,hist,mem) push [set percMem [expr {([usedMem] / [totalMem]) * 100.0}]]
		$sys($w,hist,swp) push [set percSwap [expr {([usedSwap] / [totalSwap]) * 100.0}]]

		if {[$sys($w,hist,mem) size] >= 100} {
			foreach {k v} [array get sys $w,hist,*] {
				set tmp [$sys($k) getr]
				$sys($k) clear
				$sys($k) push {*}$tmp	
			}
		}
		
		if {![info exists sys($w,memHistory)]} {
			return
		}
		
		$sys($w,memHistory).mem.chart setValues [$sys($w,hist,mem) getr]
		$sys($w,memHistory).mem.chart update 

		$sys($w,memHistory).swap.chart setValues [$sys($w,hist,swp) getr]
		$sys($w,memHistory).swap.chart update 
	}

	# used = used - (buffers + cached)
	proc usedMem {} {
		variable sys
		set free [string trimright [dict get $sys(memData) "MemFree"] "kB"]
		set total [string trimright [dict get $sys(memData) "MemTotal"] "kB"]
		set cached [string trimright [dict get $sys(memData) "Cached"] "kB"]
		set buffers [string trimright [dict get $sys(memData) "Buffers"] "kB"]
		return [expr {$total - $free - ($buffers + $cached)}].0
	}
	
	proc totalMem {} {
		variable sys
		return [string trimright [dict get $sys(memData) "MemTotal"] "kB"].0
	}
	
	# get free memory
	# free = free + bufferes + cached
	proc freeMem {} {
		variable sys
		set free [string trimright [dict get $sys(memData) "MemFree"] "kB"]
		set cached [string trimright [dict get $sys(memData) "Cached"] "kB"]
		set buffers [string trimright [dict get $sys(memData) "Buffers"] "kB"]
		return [expr {$free + ($buffers + $cached)}].0
	}

	proc usedSwap {} {
		variable sys
		set free [string trimright [dict get $sys(memData) "SwapFree"] "kB"]
		set total [string trimright [dict get $sys(memData) "SwapTotal"] "kB"]
		return [expr {$total - $free}].0
	}

	proc totalSwap {} {
		variable sys
		return [string trimright [dict get $sys(memData) "SwapTotal"] "kB"].0
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
		set sys($w,foreground) $color
		${w}.memory configure -fg $color
		${w}.memorystatus configure -fg $color
		if {$sys($w,useSwap)} {
			${w}.swap configure -fg $color
			${w}.swapstatus configure -fg $color
		}
	}
	
	proc changeBackgroundColor {w color} {
		variable sys
		set sys($w,background) $color
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
		set sys($w,font) $font
		${w}.memory configure -font $font
		${w}.memorystatus configure -font $font
		if {$sys($w,useSwap)} {
			${w}.swap configure -font $font
			${w}.swapstatus configure -font $font
		}
	}
}
