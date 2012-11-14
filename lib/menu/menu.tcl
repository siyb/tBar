namespace import ::tcl::mathop::*
namespace eval geekosphere::tbar::widget::menu {


	namespace eval autocomplete {
		variable toComplete
		variable completeList
		variable currentPositionInCompleteList
		set toComplete ""
		set completeList [list]
		set currentPositionInCompleteList 0
		proc getNextSuggestion {toCompl completeLi} {
			variable toComplete
			variable completeList
			variable currentPositionInCompleteList
			if {$toComplete ne $toCompl || $completeList ne $completeLi} {
				set currentPositionInCompleteList 0
				set toComplete $toCompl
				set completeList $completeLi
			}

			set filteredList [lsearch -all -inline $completeList $toCompl*]
			
			incr currentPositionInCompleteList
			if {$currentPositionInCompleteList > [llength $filteredList]} {
				set currentPositionInCompleteList 0
			}
			return [lindex $filteredList $currentPositionInCompleteList]
		}
	}

	proc fillListBoxWithExecutables {listBox executables} {
		$listBox delete 0 end
		foreach item $executables {
			$listBox insert end $item
		}
	}

	proc filterExecutables {filterString} {
		set executables [getExecutablesInPath]
		# TODO: make type of matching configurable e.g. filter*, *filter, *filter*, etc
		return [lsearch -all -inline $executables *$filterString*]
	}

	proc getExecutablesInPath {} {
		set ret [list]
		foreach path [split $::env(PATH) ":"] {
			foreach file [glob -nocomplain $path/*] {
				if {![file isdirectory $file] && [file executable $file]} {
					lappend ret [file tail $file]
				}
			}
		
		}
		return [lsort -dictionary $ret]
	}

	proc handleEntryKeyPress {entry listBox key} {
		set curselection [$listBox curselection]
		if {$curselection ne ""} {
			if {$key eq "Return"} {
				handleReturn $entry $listBox $curselection
			} elseif {$key eq "Up"} {
				handleUp $listBox $curselection
			} elseif {$key eq "Down"} {
				handleDown $listBox $curselection
			}
		}
		if {$key eq "Tab"} {
			handleTab $entry $listBox 
		} elseif {$key ne "Return" && $key ne "Up" && $key ne "Down"} {
			handleOtherKey $listBox
		}
	}

	proc handleReturn {entry listBox curselection} {
		set command [$listBox get $curselection $curselection]
		open |$command r
		$entry delete 0 end
		fillListBoxWithExecutables $listBox [filterExecutables ""]
	}

	proc handleUp {listBox curselection} {
		set newSelection [- $curselection 1]
		$listBox selection clear 0 end
		$listBox selection set $newSelection
	}

	proc handleDown {listBox curselection} {
		set newSelection [+ $curselection 1]
		$listBox selection clear 0 end
		$listBox selection set $newSelection
	}

	proc handleTab {entry listBox} {
		$entry delete 0 end
		$entry insert 0 [geekosphere::tbar::widget::menu::autocomplete::getNextSuggestion [$entry get] [$listBox get 0 end]]
		selectListBoxItemByString $listBox [$entry get]
	}

	proc handleOtherKey {listBox} {
		after 10 {
			geekosphere::tbar::widget::menu::fillListBoxWithExecutables .box [geekosphere::tbar::widget::menu::filterExecutables [.e get]]
			.box selection set 0
		}
	}

	proc selectListBoxItemByString {listBox string} {
		set items [$listBox get 0 end]
		set indexOfString [lsearch $items $string]
		if {$indexOfString != -1} {
			$listBox selection clear 0 end
			$listBox selection set $indexOfString $indexOfString
		}
	}

	# testcode
	package require Tk
	pack [listbox .box -selectmode single] -fill both -expand 1
	pack [entry .e] -fill both -side bottom
	geekosphere::tbar::widget::menu::fillListBoxWithExecutables .box [geekosphere::tbar::widget::menu::filterExecutables ""]
	bind .e <Key> {
		puts %K
		geekosphere::tbar::widget::menu::handleEntryKeyPress .e .box %K
	}
}


