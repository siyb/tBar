package provide i3_workspace 1.0

if {![info exist geekosphere::tbar::packageloader::available]} {
	package require logger
	package require i3_ipc
	package require json
}

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
		set sys($w,workspace) [list]
		set sys($w,focusColor) "blue"
		set sys($w,urgentColor) "red"
		set sys($w,rolloverFontColor) [getOption "-fg" $arguments]
		set sys($w,rolloverBackgroundColor) [getOption "-bg" $arguments]
		set sys($w,legacyMode) 0
		pack [frame ${w}]

		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_

		set sys($w,lastWorkspaceStatus) [dict create]

		# run configuration
		action $w configure $arguments

		initIpc $w
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
		variable sys
		set event [getEvent]
		set type [lindex $event 0]
		set message [lindex $event 1]
		if {$event == -1} {
			log "WARNING" "A connection error occured, resetting system!"
			resetWorkspaceSystem $w
			return
		}
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
				"create" {
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
		if {$event == -1} {
			log "WARNING" "A connection error occured, resetting system!"
			resetWorkspaceSystem $w
			return
		}
		set eventDict [::json::json2dict $message]
		if {$sys($w,lastWorkspaceStatus) == $eventDict} {
			return
		}
		set sys($w,lastWorkspaceStatus) $eventDict
		if {$type == 1} {
			foreach workspace $eventDict {
				set workspaceId [dict get $workspace num]
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

	proc resetWorkspaceSystem {w} {
		variable sys
		after 500
		removeAllWorkspaceLabels $w
		set sys($w,workspace) [list]
		set sys($w,lastWorkspaceStatus) [dict create]
		connect	
		subscribeToWorkspace
		getWorkspaces
		updateDisplay $w
	}

	proc removeAllWorkspaceLabels {w} {
		variable sys
		foreach workspace $sys($w,workspace) {
			set currentWorkspaceNumber [lindex $workspace 0]
			destroy ${w}.workspace${currentWorkspaceNumber}
		}
	}

	proc flagWorkspace {w workspace kind} {
		variable sys
		set number [dict get $workspace num]
		switch $kind {
			"+urgent" {
				setUrgentStatus $w $number 1
			}
			"-urgent" {
				setUrgentStatus $w $number 0
			}
			"+focus" {
				setActiveStatus $w $number 1
			}
			"-focus" {
				setActiveStatus $w $number 0
			}
			default {
				error "Flag unknown: $kind"
			}
		}
	}

	proc setUrgentStatus {w workspaceId status} {
		variable sys
		set position [getWorkspacePositionInList $w $workspaceId]
		set workspace [lindex $sys($w,workspace) $position]
		set newWorkspace [lreplace $workspace 1 1 $status]
		set sys($w,workspace) [lreplace $sys($w,workspace) $position $position $newWorkspace]
	}

	proc setActiveStatus {w workspaceId status} {
		variable sys
		set position [getWorkspacePositionInList $w $workspaceId]
		set workspace [lindex $sys($w,workspace) $position]
		set newWorkspace [lreplace $workspace 2 2 $status]
		set sys($w,workspace) [lreplace $sys($w,workspace) $position $position $newWorkspace]
	}

	proc getUrgentStatus {w workspaceId} {
		variable sys
		set position [getWorkspacePositionInList $w $workspaceId]
		if {$position == -1} { error "Position could not be determined, was -1" }
		return [lindex $sys($w,workspace) $position 1]
	}

	proc getActiveStatus {w workspaceId} {
		variable sys
		set position [getWorkspacePositionInList $w $workspaceId]
		if {$position == -1} { error "Position could not be determined, was -1" }
		return [lindex $sys($w,workspace) $position 2]
	}

	proc removeNonopenWorkspaces {w workspaces} {
		variable sys
		set activeWorkSpaces [list]
		foreach activews $workspaces {
			lappend activeWorkSpaces [dict get $activews num]
		}
		foreach workspace $sys($w,workspace) {
			set currentWorkspaceNumber [lindex $workspace 0]
			if {[lsearch $activeWorkSpaces $currentWorkspaceNumber] == -1} {
				set position [getWorkspacePositionInList $w $currentWorkspaceNumber]
				set sys($w,workspace) [lreplace $sys($w,workspace) $position $position]
				destroy ${w}.workspace${currentWorkspaceNumber}
			}
		}
	}

	proc addWorkspace {w workspace} {
		variable sys
		set number [dict get $workspace num]
		if {![workspacePresent $w $number]} {
			lappend sys($w,workspace) [list $number 0 0]
		}
	}

	proc getWorkspacePositionInList {w workspaceId} {
		variable sys
		return [lsearch -index 0 $sys($w,workspace) $workspaceId]
	}

	proc workspacePresent {w workspaceId} {
		variable sys
		if {[getWorkspacePositionInList $w $workspaceId] == -1} { return 0 }
		return 1
	}

	proc updateDisplay {w} {
		variable sys
		set sortedWorkspaces [lsort -index 0 -integer $sys($w,workspace)]
		foreach wspace $sortedWorkspaces {
			set workspace [lindex $wspace 0]
			# TODO: destroy is a dirty and slow hack, increase speed by only destroying "unsorted" windows
			destroy ${w}.workspace${workspace}
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
				bind ${w}.workspace${workspace} <Button-1> [list geekosphere::tbar::widget::i3::workspace::changeWorkspace $w $workspace]
			}
			if {[getActiveStatus $w $workspace] == 1} {
				${w}.workspace${workspace} configure -bg $sys($w,focusColor)
			} elseif {[getUrgentStatus $w $workspace] == 1} {
				${w}.workspace${workspace} configure -bg $sys($w,urgentColor)
			} else {
				${w}.workspace${workspace} configure -bg $sys($w,background)
			}
		}
	}

	proc changeWorkspace {w workspace} {
		variable sys
		log "DEBUG" "Changing to workspace $workspace"
		if {$sys($w,legacyMode)} {
			changeWorkspaceLegacy $workspace
		} else {
			changeWorkspaceNew $workspace
		}
		wm focusmodel . passive
	}

	proc changeWorkspaceLegacy {workspace} {
		log "DEBUG" "Using i3 legacy mode: $workspace"
		sendCommand $workspace
	}

	proc changeWorkspaceNew {workspace} {
		log "DEBUG" "Using i3 new mode: $workspace"
		sendCommand [list workspace $workspace]
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
					"-setipcpath" {
						setIpcPath $value
					}
					"-legacymode" {
						setLegacyMode $w $value
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

	proc setLegacyMode {w legacyMode} {
		variable sys
		set sys($w,legacyMode) $legacyMode
	}

	proc setIpcPath {path} {
		if {![file exists $path] || [file isfile $path] || [file isdirectory $path]} {
			log "WARNING" "The i3 ipc path specified using the -setipcpath option does not exist, is a regular file or a directory. Using '~/.i3/ipc.sock' as fallback"
			return
		}
		set geekosphere::tbar::i3::ipc::sys(socketFile) $path
	}

	proc setForAllWorkspaces {w args} {
		variable sys
		foreach wspace $sys($w,workspace) {
			set workspace [lindex $wspace 0]
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
