package provide uidebug 1.0
if {![info exist geekosphere::tbar::packageloader::available]} {
		package require logger
		package require util
		catch { namespace import ::geekosphere::tbar::util::logger::* }
}
initLogger
namespace eval geekosphere::tbar::uidebug {
	variable oldValues
	variable allWindows
	variable infoBox

	set infoBox ""
	initLogger

	proc enableUiDebug {} {
		variable oldValues
		variable allWindows

		set allWindows [getChildWidgetsRecursivly .]
		foreach window $allWindows {
			log "DEBUG" "Binding window $window"	
			set oldValues($window,relief) [$window configure -relief]
			set oldValues($window,borderwidth) [$window configure -borderwidth]
			bind $window <Enter> {
				log "DEBUG" "Enter %W"
				geekosphere::tbar::uidebug::unhighlightAllBut %W
				geekosphere::tbar::uidebug::highlight %W
			}
			bind $window <Leave> {

				log "DEBUG" "Leave %W"
				set parent [winfo parent %W]
				if {$parent ne ""} {
					geekosphere::tbar::uidebug::highlight $parent
				}
				geekosphere::tbar::uidebug::unhighlight %W
			}
		}
	}

	proc disableUiDebug {} {
		variable allWindows
		variable infoBox
	       	if {[winfo exists $infoBox]} {
			destroy $infoBox
		}	
		unhighlightAll
		foreach window $allWindows {
			bind $window <Leave> ""
			bind $window <Enter> ""
		}
	}

	proc highlight {window} {
		$window configure -relief solid
		$window configure -borderwidth 1
		showInfoBox $window	
	}

	proc unhighlight {window} {
		variable oldValues
		log "INFO" "Old Values: $geekosphere::tbar::uidebug::oldValues($window,relief) | $geekosphere::tbar::uidebug::oldValues($window,relief)"  
		$window configure -relief [lindex $geekosphere::tbar::uidebug::oldValues($window,relief) end-1]
		$window configure -borderwidth [lindex $geekosphere::tbar::uidebug::oldValues($window,borderwidth) end-1]
	}

	proc showInfoBox {window} {
		variable infoBox
		variable ignoreEvent
		if {![winfo exists $infoBox]} {
			set infoBox [toplevel .uiutilbox]
			pack [label $infoBox.info -text $window]
		}
		$infoBox.info configure -text $window
	}

	proc unhighlightAll {} {
		unhighlightAllBut -1
	}
	proc unhighlightAllBut {window} {
		variable allWindows
		foreach w $allWindows {
			if {$w eq $window} { continue }
			unhighlight $w	
		}
	}

	proc getChildWidgetsRecursivly {window} {
		set childList [list]
		lappend childList $window
		foreach child [winfo children $window] {
			set childsChildren [winfo children $child]
			if {[llength $childsChildren] != 0} {
				set childList [concat $childList [getChildWidgetsRecursivly $child]]
			} 
			lappend childList $child
		}
		return $childList

	}

	proc hasOption {window opt} {
		set options [$window configure]
		foreach option $options {
			if {[lindex $option 1] eq $opt} {
				return 1
			}
		}
		return 0
	}

	namespace export enableUiDebug disableUiDebug
}
