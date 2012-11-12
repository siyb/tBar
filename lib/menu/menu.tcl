namespace import ::tcl::mathop::*
namespace eval geekosphere::tbar::widget::menu {

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
		}
		if {$key ne "Return" && $key ne "Up" && $key ne "Down"} {
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

	}

	proc handleOtherKey {listBox} {
		after 10 {
			geekosphere::tbar::widget::menu::fillListBoxWithExecutables .box [geekosphere::tbar::widget::menu::filterExecutables [.e get]]
			.box selection set 0
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


