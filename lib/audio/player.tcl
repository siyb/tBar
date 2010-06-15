package provide player 1.0

proc player {w args} {
	geekosphere::tbar::widget::player::makePlayer $w $args

	proc $w {args} {
		geekosphere::tbar::widget::player::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

namespace import ::geekosphere::tbar::util::*
namespace eval geekosphere::tbar::widget::player {

	proc makePlayer {w arguments} {
		variable sys
		set sys($w,originalCommand) ${w}_
		set sys($w,playerCanvas) ${w}.player
		set sys($w,time) ${w}.time
		set sys($w,foreground) blue
		
		frame $w
		pack [canvas $sys($w,playerCanvas) -highlightthickness 0] -side left -fill both
		pack [label $sys($w,time) -textvariable geekosphere::tbar::widget::player::displayTime] -side right -fill both
		set geekosphere::tbar::widget::player::displayTime "Not playing"
		
		if {[set height [getOption "-height" $arguments]] eq ""} {
			set sys($w,height) 12
		} else {
			set sys($w,height) $height
		}
		
		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_
		
		# run configuration
		action $w configure $arguments
		
		# create ui, after configuration
		createUiWrapper $w $height
		
		# mark the widget as initialized
		set sys($w,initialized) 1
	}
	
	proc createUiWrapper {w height} {
		variable sys
		resetUi $w
		createUi $w $height [expr {$height / 3}]
	}
	
	proc createUi {w xy offset} {
		variable sys
		# TODO: dirty shit ... clean up here
		set secondEnd [expr {$xy + $offset}]
		set thirdEnd [expr {$xy*2 + $offset*2}]
		createPlayButton $w $xy 0 0
		createStopButton $w $xy $secondEnd 0
		createPauseButton $w $xy $thirdEnd 0
		$sys($w,playerCanvas) configure -width [expr {$secondEnd + $thirdEnd}]
	}
	
	proc resetUi {w} {
		variable sys
		$sys($w,playerCanvas) delete play stop pause pause_fill time
	}
	
	proc createPlayButton {w xy startx starty} {
		variable sys
		$sys($w,playerCanvas) create polygon $startx $starty [expr {$startx +$xy}] [expr {($starty + $xy) / 2}] $startx $xy \
			-fill $sys($w,foreground) \
			-width 0 \
			-tags [list play]
	}
	
	proc createStopButton {w xy startx starty} {
		variable sys
		$sys($w,playerCanvas) create rectangle $startx $starty [expr {$startx + $xy}] [expr {$starty + $xy}] \
			-fill $sys($w,foreground) \
			-width 0 \
			-tags [list stop]
	}
	
	proc createPauseButton {w xy startx starty} {
		variable sys
		set part [expr {$xy / 3}]; # size of one part of the pause button (black blanc black)
		$sys($w,playerCanvas) create rectangle $startx $starty [expr {$startx + $part}] [expr {$starty + $xy}] \
			-fill $sys($w,foreground) \
			-width 0 \
			-tags [list pause]
		$sys($w,playerCanvas) create rectangle [expr {$startx + $part}] $starty [expr {$startx + $part * 2}] [expr {$starty + $xy}] \
			-width 0 \
			-tags [list pause_fill]
		$sys($w,playerCanvas) create rectangle [expr {($startx + $part * 2)}] $starty [expr {$startx + $part * 3}] [expr {$starty + $xy}] \
			-fill $sys($w,foreground) \
			-width 0 \
			-tags [list pause]
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
					"-text" {
						changeText $w $value
					}
					"-bindplay" {
						${w}.player bind play <Button-1> $value
					}
					"-bindpause" {
						${w}.player bind pause <Button-1> $value
						${w}.player bind pause_fill <Button-1> $value
					}
					"-bindstop" {
						${w}.player bind stop <Button-1> $value
					}
				}
			}
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
		$sys($w,playerCanvas) configure -bg $color
		$sys($w,playerCanvas) itemconfigure pause_fill -fill $color
		$sys($w,time) configure -bg $color
	}
	
	proc changeForegroundColor {w color} {
		variable sys
		set sys($w,foreground) $color
		$sys($w,time) configure -fg $color
		$sys($w,playerCanvas) itemconfigure pause -fill $color
		$sys($w,playerCanvas) itemconfigure play -fill $color
		$sys($w,playerCanvas) itemconfigure stop -fill $color
		$sys($w,playerCanvas) itemconfigure time -fill $color
	}
	
	proc changeText {w text} {
		variable sys
		$sys($w,playerCanvas) itemconfigure time -text $text
	}
	
	proc changeFont {w font} {
		variable sys
		$sys($w,time) configure -font $font
		set sys($w,font) $font
	}
	
	proc changeHeight {w height} {
		variable sys
		$sys($w,originalCommand) configure -height $height
		$sys($w,playerCanvas) configure -height $height
		$sys($w,time) configure -height $height
		createUiWrapper $w $height
		set sys($w,height) $height
	}
	
	proc changeWidth {w width} {
		variable sys
		$sys($w,originalCommand) configure -width $width
	}
}