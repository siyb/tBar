package provide barChart 1.1

proc barChart {w args} {
	geekosphere::barChart::makeBarChart $w $args

	proc $w {args} {
		geekosphere::barChart::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

namespace eval geekosphere::barChart {
	variable sys
	
	proc makeBarChart {w args} {
		variable sys

		# vars that can be set by the coder
		set sys($w,foreground) "black";# text in graph color
		set sys($w,graphicColor) "red";# color of graph
		set sys($w,textvariable) -1
		
		# vars that can not be set by the coder		
		set sys($w,originalCommand) ${w}_
		set sys($w,data,tv) -1;# text to diplay
		set sys($w,data) [list];# data to be displayed
		
		set sys($w,font) "Arial 10"
		
		frame $w -class barChart
		pack [canvas ${w}.canvas]
		
		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_

		# run configuration
		action $w configure [join $args]

		return $w
	}
	
	proc drawData {w} {
		variable sys
		set marker 0
		set cWidth [${w}.canvas cget -width]
		set cHeight [${w}.canvas cget -height]
		cleanDataFromWidget $w
		foreach value $sys($w,data) {
			set yStart $cHeight
			set xStart $marker
			set yEnd [expr {$cHeight - [calcPercentage $value $cHeight]}]
			set xEnd [expr {$marker + 1}]
			set sys($w,data,$marker) [${w}.canvas create rectangle $xStart $yStart $xEnd $yEnd \
				-fill $sys($w,graphicColor) \
				-outline $sys($w,graphicColor)
			]
			incr marker
		}
		if {$sys($w,textvariable) != -1} {
			set sys($w,data,tv) [${w}.canvas create text [expr {$cWidth / 2}] [expr {$cHeight / 2}] \
				-text [set $sys($w,textvariable)] \
				-anchor center \
				-fill $sys($w,foreground) \
				-font $sys($w,font)
			]
		}
	}
	
	proc cleanDataFromWidget {w} {
		variable sys
		${w}.canvas delete $sys($w,data,tv)
		foreach {item value} [array get sys $w,data,*] {
			${w}.canvas delete $value
		}
	}
	
	proc calcPercentage {percent of} {
		variable sys
		return [::tcl::mathfunc::round [expr {$percent  / 100 * $of}]]
	}
		
	proc addValue {w value} {
		variable sys
		lappend sys($w,data) $value
	}
	
	proc pushValue {w value} {
		variable sys
		# max length is reached, drop last value
		set length [${w}.canvas cget -width]
		if {[llength $sys($w,data)] == $length} {
			set sys($w,data) [lreplace $sys($w,data) 0 0]
		}
		addValue $w $value
	}
	
	proc setValues {w values} {
		variable sys
		if {[${w}.canvas cget -width] < [llength $values]} {
			error "Input value list exceeds maximum length"
		}
		set sys($w,data) {*}$values
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
						# textcolor for text to be displayed in canvas, will be updated after drawData is called
						set sys($w,foreground) $value
					}
					"-bg" - "-background" {
						changeBackgroundColor $w $value
					}
					"-gc" - "-graphicscolor" {
						# will be updated when drawGraphics is called
						changeGraphicColor $w $value
					}
					"-l" - "-length" - "-width" {
						if {![string is integer $value]} { error "${opt} only accepts integer values" }
						changeWidth $w $value
					}
					"-height" {
						if {![string is integer $value]} { error "${opt} only accepts integer values" }
						changeHeight $w $value
					}
					"-textvariable" {
						set sys($w,textvariable) $value
					}
					"-font" {
						changeFont $w $value
					}
					default {
						error "${opt} not supported"
					}
				}
			}
		} elseif {$command eq "update"} {
			drawData $w
		} elseif {$command eq "addValue"} {
			addValue $w $rest
		} elseif {$command eq "pushValue"} {
			pushValue $w $rest
		} elseif {$command eq "setValues"} {
			setValues $w $rest
		} else {
			error "Command ${command} not supported"
		}
	}
	
	#
	# Widget configuration procs
	#
	
	proc changeWidth {w width} {
		${w}.canvas configure -width $width
	}
	
	proc changeHeight {w height} {
		${w}.canvas configure -height $height
	}
	
	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color;# frame
		${w}.canvas configure -bg $color;# canvas
	}
	
	proc changeGraphicColor {w color} {
		variable sys
		set sys($w,graphicColor) $color
	}
	
	proc changeFont {w font} {
		variable sys
		set sys($w,font) $font
	}
}
