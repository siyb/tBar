package provide notify 1.0

proc notify {w args} {
	geekosphere::tbar::widget::notify::makeNotify $w $args

	proc $w {args} {
		geekosphere::tbar::widget::notify::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

catch { namespace import ::geekosphere::tbar::util::* }
namespace eval geekosphere::tbar::widget::notify {

	proc makeNotify {w arguments} {
		variable sys
		set sys($w,originalCommand) ${w}_

		changeNotifyAt $w [getOption "-notifyAt" $arguments]

		# has -image?
		if {[set imgp [getOption "-image" $arguments]] != ""} {
			changeImage $w $imgp

			# should be scaled?
			if {[set imgdim [getOption "-imageDimensions" $arguments]] != ""} {
				changeImageDimensions $w $imgdim
			} else {
				set sys($w,scaledImage) -1
			}
		} else {
			set sys($w,imagePath) -1
			set sys($w,image) -1
			set sys($w,scaledImage) -1
		}

		set sys($w,text) "N/A"

		frame $w
		pack [label ${w}.displayLabel] -side left -fill both

		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_

		# run configuration
		action $w configure $arguments

		# mark the widget as initialized
		set sys($w,initialized) 1
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
					"-notifyAt" {
						changeNotifyAt $w $value
					}
					"-image" {
						if {[info exists sys($w,initialized)]} { error "image cannot be changed after widget initialization" }
					}
					"-text" {
						changeText $w $value
					}
					"-height" {
						changeHeight $w $value
					}
					"-width" {
						changeWidth $w $value
					}
					"-imageDimensions" {
						if {[info exists sys($w,initialized)]} { error "imageDimensions cannot be changed after widget initialization" }
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
		if {[expr $sys($w,notifyAt)]} {
			# attempt rending the image
			if {$sys($w,image) != -1} {
				# no scaled image yet
				if {$sys($w,scaledImage) == -1} {
					${w}.displayLabel configure -image $sys($w,image)
				} else {
					${w}.displayLabel configure -image $sys($w,scaledImage)
				}
			} else {
				${w}.displayLabel configure -text $sys($w,text)
			}
		} else {
			${w}.displayLabel configure -image ""
			${w}.displayLabel configure -text ""
		}
	}

	#
	# Widget configuration procs
	#

	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		${w}.displayLabel configure -bg $color
	}

	proc changeForegroundColor {w color} {
		variable sys
		${w}.displayLabel configure -fg $color
	}

	proc changeFont {w font} {
		variable sys
		${w}.displayLabel configure -font $font
	}

	proc changeHeight {w height} {
		variable sys
		$sys($w,originalCommand) configure -height $height
		${w}.displayLabel configure -height $heigth
	}

	proc changeWidth {w width} {
		variable sys
		$sys($w,originalCommand) configure -width $width
	}

	proc changeImageDimensions {w dimensions} {
		variable sys
		if {$sys($w,image) == -1} { error "No image related with this widget using -image yet." }
		set dimensions [split $dimensions "X"]
		if {[llength $dimensions] != 2} { error "Dimensions must be given in the form \$widthX\$height" }
		# image has not been scaled before
		set sys($w,scaledImage) [imageresize::resize $sys($w,image) [lindex $dimensions 1] [lindex $dimensions 0]]
	}

	proc changeImage {w imagePath} {
		variable sys
		if {![file exists $imagePath]} { error "Image file $imageFile does not exists" }
		set sys($w,imagePath) $imagePath
		set sys($w,image) [image create photo -file $imagePath]
	}

	proc changeText {w text} {
		variable sys
		set sys($w,text) $text
	}

	proc changeNotifyAt {w expression} {
		variable sys
		if {$expression == ""} { error "Expression must not be empty" }

		if {[catch {
			expr $expression
		} err]} {
			error "Invalid expression: $::errorInfo"
		}

		set sys($w,notifyAt) $expression
	}

}
