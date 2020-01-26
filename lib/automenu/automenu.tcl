package provide automenu 1.0

package require menulib
package require closure
package require tipc

proc automenu {w args} {
	geekosphere::tbar::widget::automenu::makeMenu $w $args

	proc $w {args} {
		geekosphere::tbar::widget::automenu::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

namespace eval geekosphere::tbar::widget::automenu {
	variable sys

	proc makeMenu {w arguments} {
		variable sys
		set sys($w,originalCommand) ${w}_
		set sys($w,entry) .e
		set sys($w,toplevel) .tl
		set sys($w,listBox) $sys($w,toplevel).lb

		frame $w
		pack [entry ${w}$sys($w,entry)] -side right
		setEntryKeyCallback callBack $w
		configureEntry $sys($w,listBox) ${w}$sys($w,entry)

		bind ${w}$sys($w,entry) <Button-1> {
			focus -force %W
		}

		proc ipc_focus {} [closure::closure {
			variable sys
			if {![winfo exists $sys($w,toplevel)]} {
				focus -force ${w}$sys($w,entry)
			} else {
				${w}$sys($w,entry) delete 0 end
				destroy $sys($w,toplevel)
				focus -force .
			}
		}]

		if {![geekosphere::tbar::ipc::isProcRegistered ::geekosphere::tbar::widget::automenu ipc_focus]} {
			geekosphere::tbar::ipc::registerProc ipc_focus
		}

		uplevel #0 rename $w ${w}_
		action $w configure $arguments
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
		} elseif {$command == "update"} {
			updateWidget $w
		} else {
			error "Command ${command} not supported"
		}
	}

	proc callBack {w eventProcessed key} {
		variable sys
		if {![winfo exists $sys($w,toplevel)]} {
			toplevel $sys($w,toplevel)
			pack [listbox $sys($w,listBox) -bg $sys($w,background) -fg $sys($w,foreground) -font $sys($w,font)]
			configureListBox $sys($w,listBox) ${w}$sys($w,entry)
			positionWindowRelativly $sys($w,toplevel) ${w}$sys($w,entry)
		}
		if {$eventProcessed && $key eq "Return" && [winfo exists $sys($w,toplevel)]} {
			destroy $sys($w,toplevel)
		}
	}

	proc updateWidget {w} {
	}

	#
	# Widget configuration procs
	#
	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		set sys($w,background) $color
		${w}$sys($w,entry) configure -bg $color

		if {[winfo exists $sys($w,toplevel)]} {
			$sys($w,toplevel) configure -bg $color
			$sys($w,listBox) configure -bg $color
		}
	}

	proc changeForegroundColor {w color} {
		variable sys
		set sys($w,foreground) $color
		${w}$sys($w,entry) configure -fg $color

		if {[winfo exists $sys($w,toplevel)]} {
			$sys($w,toplevel) configure -fg $color
			$sys($w,listBox) configure -fg $color
		}
	}

	proc changeFont {w font} {
		variable sys
		set sys($w,font) $font
		${w}$sys($w,entry) configure -font $font
		if {[winfo exists $sys($w,toplevel)]} {
			$sys($w,listBox) configure -font $font
		}
	}

	proc changeHeight {w height} {
		variable sys
		set sys($w,height) $height
		$sys($w,originalCommand) configure -height $height
	}

	proc changeWidth {w width} {
		variable sys
		$sys($w,originalCommand) configure -width $width
	}

}
