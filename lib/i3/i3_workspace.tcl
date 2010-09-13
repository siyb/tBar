package provide i3_workspace 1.0

package require logger
package require i3_ipc
package require json

proc i3_workspace {w args} {
	geekosphere::tbar::widget::i3::workspace::makeI3Workspace $w $args

	proc $w {args} {
		geekosphere::tbar::widget::i3::workspace::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

catch {
	namespace import ::geekosphere::tbar::util::logger::*
	namespace import ::geekosphere::tbar::i3::ipc::*
	namespace import ::geekosphere::tbar::util::*
}
namespace eval geekosphere::tbar::widget::i3::workspace {
	initLogger
	
	proc makeI3Workspace {w arguments} {
		variable sys
		
		set sys($w,originalCommand) ${w}_
		set sys($w,workspace) [dict create]
		set sys($w,focusColor) "blue"
		set sys($w,urgentColor) "red"
		set sys($w,rolloverFontColor) [getOption "-fg" $arguments]
		set sys($w,rolloverBackgroundColor) [getOption "-bg" $arguments]
		
		pack [frame ${w}]
		
		
		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_
		
		initIpc $w
	
		# run configuration
		action $w configure $arguments
		
	}
	
	# initialize i3 ipc stuff
	proc initIpc {w} {
		connect
		addInfoListener geekosphere::tbar::widget::i3::workspace::infoCallback $w
		addEventListener geekosphere::tbar::widget::i3::workspace::eventCallback $w
		subscribeToWorkspace
		getWorkspaces
	}
	
	proc eventCallback {w args} {
		set event [getEvent]
		set type [lindex $event 0]
		set message [lindex $event 1]
		set eventDict [::json::json2dict $message]
		# command reply / subscribe reply
		# TODO: dict exists is an ugly workaround for bug in i3_ipc, read comment above i3queryDecode
		if {$type == 0 || $type == 2 || [dict exists $eventDict success]} {
			if {[dict get $eventDict "success"] eq "false"} {
				log "ERROR" "An unknow i3-ipc error has occured"
			}
		}
		
		# workspace / output events
		# TODO: dict exists is an ugly workaround for bug in i3_ipc, read comment above i3queryDecode
		if {$type == 1 || $type == 3 || [dict exists $eventDict change]} {
			set state [dict get $eventDict "change"]
			switch $state {
				"focus" {
					getWorkspaces
				}
				"init" {
					getWorkspaces
				}
				"empty" {
					getWorkspaces
				}
				"urgent" {
					getWorkspaces
				}
				"unspecified" {
					return
				}
				default {
					error "Unsupported state: $state"
				}
			}
		}
	}
	
	proc infoCallback {w args} {
		variable sys
		set event [getInfo]
		set type [lindex $event 0]
		set message [lindex $event 1]
		set eventDict [::json::json2dict $message]
		
		if {$type == 1} {
			foreach workspace $eventDict {
				addWorkspace $w $workspace
				
				if {[dict get $workspace focused] eq "true"} {
					flagWorkspace $w $workspace +focus
				} else {
					flagWorkspace $w $workspace -focus
				}
				
				if {[dict get $workspace urgent] eq "true"} {
					flagWorkspace $w $workspace +urgent
				} else {
					flagWorkspace $w $workspace -urgent
				}
			}
			updateDisplay $w
			removeNonopenWorkspaces $w $eventDict
		}
	}
	
	#
	# Workspace datastructure modificiation
	#

	proc flagWorkspace {w workspace kind} {
		variable sys
		set number [dict get $workspace num]
		switch $kind {
			"+urgent" {
				dict set sys($w,workspace) $number urgent 1
			}
			"-urgent" {
				dict set sys($w,workspace) $number urgent 0
			}
			"+focus" {
				dict set sys($w,workspace) $number focus 1
			}
			"-focus" {
				dict set sys($w,workspace) $number focus 0
			}
			default {
				error "Flag unknown: $kind"
			}
		}
	}
	
	proc removeNonopenWorkspaces {w workspaces} {
		variable sys
		dict for {workspace data} $sys($w,workspace) {
			foreach activews $workspaces {
				if {[dict get $activews num] == $workspace} {
					set active 1
					break
				}
			}
			if {![info exists active]} {
				dict remove $sys($w,workspace) $workspace
				destroy ${w}.workspace${workspace}
			} else {
				unset active
			}
		}
	}
	
	proc addWorkspace {w workspace} {
		variable sys
		set number [dict get $workspace num]
		if {![dict exists $sys($w,workspace) $number]} {
			dict set sys($w,workspace) $number focus 0
			dict set sys($w,workspace) $number urgent 0
		}
	}

	proc updateDisplay {w} {
		variable sys
		dict for {workspace flag} [::geekosphere::tbar::util::dictsort $sys($w,workspace)] {
			if {![winfo exists ${w}.workspace${workspace}]} {
				pack [label ${w}.workspace${workspace} \
					-text $workspace \
					-bg $sys($w,background) \
					-fg $sys($w,foreground) \
					-font $sys($w,font) \
					-activeforeground $sys($w,rolloverFontColor)  \
					-activebackground $sys($w,rolloverBackgroundColor) \
					-highlightthickness 0 \
					-width 2
				] -side left
				bind ${w}.workspace${workspace} <Button-1> [list sendCommand $workspace]
			}
			if {[dict get $sys($w,workspace) $workspace focus] == 1} {
				${w}.workspace${workspace} configure -bg $sys($w,focusColor)
			} elseif {[dict get $sys($w,workspace) $workspace urgent] == 1} {
				${w}.workspace${workspace} configure -bg $sys($w,urgentColor)
			} else {
				${w}.workspace${workspace} configure -bg $sys($w,background)
			}
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
					"-font" {
						changeFont $w $value
					}
					"-focuscolor" {
						changeFocuscolor $w $value
					}
					"-urgentcolor" {
						changeUrgentcolor $w $value
					}
					"-rolloverfontcolor" {
						changeRolloverFontColor $w $value
					}
					"-rolloverbackgroundcolor" {
						changeRolloverBackground $w $value
					}
					"-side" {
						# do nothing, -side parameter was meant for widget wrapper
						# dirty hack
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

	proc updateWidget {w} {
		variable sys
	}
	
	#
	# Widget configuration procs
	#
	
	proc setForAllWorkspaces {w args} {
		variable sys
		dict for {workspace flag} $sys($w,workspace) {
			${w}.workspace${workspace} configure {*}$args
		}
	}
	
	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		setForAllWorkspaces $w -bg $color
		set sys($w,background) $color
	}
	
	proc changeForegroundColor {w color} {
		variable sys
		setForAllWorkspaces $w -fg $color
		set sys($w,foreground) $color
	}
	
	proc changeFont {w font} {
		variable sys
		setForAllWorkspaces $w -font $font
		set sys($w,font) $font
	}
	
	proc changeFocuscolor {w color} {
		variable sys
		set sys($w,focusColor) $color
	}
	
	proc changeUrgentcolor {w color} {
		variable sys
		set sys($w,urgentColor) $color
	}
	
	proc changeRolloverBackground {w color} {
		variable sys
		setForAllWorkspaces $w -activebackground $color
		set sys($w,rolloverBackgroundColor) $color
	}
	
	proc changeRolloverFontColor {w color} {
		variable sys
		setForAllWorkspaces $w -activeforeground $color
		set sys($w,rolloverFontColor) $color
	}
}
