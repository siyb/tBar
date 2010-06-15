package provide player 1.0

proc player {w args} {
	geekosphere::tbar::widget::player::makePlayer $w $args

	proc $w {args} {
		geekosphere::tbar::widget::player::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

namespace eval geekosphere::tbar::widget::player {
	
	proc makePlayer {w arguments} {
		variable sys
		set sys($w,originalCommand) ${w}_
		set sys(playerCanvas) ${w}.player
		frame $w
		pack [canvas $sys(playerCanvas)] -fill both
		createButtons $w
		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_
		
		# run configuration
		action $w configure $arguments
		
		# mark the widget as initialized
		set sys($w,initialized) 1
	}
	
	proc createButtons {w} {
		variable sys
		set xy 10
		set offset 10
		createPlayButton $xy 0 0
		createStopButton $xy [expr {$xy + $offset}] 0
		createPauseButton $xy [expr {$xy*2 + $offset*2}] 0
	}
	
	proc createPlayButton {xy startx starty} {
		variable sys
		$sys(playerCanvas) create polygon $startx $starty [expr {$startx +$xy}] [expr {($starty + $xy) / 2}] $startx $xy -fill black
	}
	
	proc createStopButton {xy startx starty} {
		variable sys
		$sys(playerCanvas) create rectangle $startx $starty [expr {$startx + $xy}] [expr {$starty + $xy}] -fill black
	}
	
	proc createPauseButton {xy startx starty} {
		variable sys
		set part [expr {$xy / 3}]; # size of one part of the pause button (black blanc black)
		$sys(playerCanvas) create rectangle $startx $starty [expr {$startx + $part}] [expr {$starty + $xy}] -fill black
		$sys(playerCanvas) create rectangle [expr {($startx + $part *2)}] $starty [expr {$startx + $part * 3}] [expr {$starty + $xy}] -fill black
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
					"-font" {
						changeFont $w $value
					}
					"-height" {
						changeHeight $w $value
					}
					"-width" {
						changeWidth $w $value
					}
				}
			}
		} elseif {$command == "bindplay"} {
		} elseif {$command == "bindpause"} {
		} elseif {$command == "bindstop"} {
		} elseif {$command == "update"} {
			updateWidget $w
		} else {
			error "Command ${command} not supported"
		}
	}
	
	proc updateWidget {w} {
		variable sys

	}
	
	#
	# Widget configuration procs
	#
	
	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
	}
	
	proc changeForegroundColor {w color} {
		variable sys
	}
	
	proc changeFont {w font} {
		variable sys
	}
	
	proc changeHeight {w height} {
		variable sys
		$sys($w,originalCommand) configure -height $height
	}
	
	proc changeWidth {w width} {
		variable sys
		$sys($w,originalCommand) configure -width $width
	}
}