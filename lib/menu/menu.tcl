package require menulib

proc menu {w args} {
	geekosphere::tbar::widget::menu::makeMenu $w $args

	proc $w {args} {
		geekosphere::tbar::widget::menu::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

namespace eval geekosphere::tbar::widget::menu {
	variable sys

	proc makeMenu {w arguments} {
		variable sys
		set sys($w,originalCommand) ${w}_
		set sys($w,entry) .e
		set sys($w,toplevel) .tl
		set sys($w,listBox) $sys($w,toplevel).lb
		pack [entry ${w}$sys($w,entry)]
		setEntryKeyCallback callBack
		configureEntry $sys($w,listBox) $sys($w,entry)
	}

	proc action {w args} {
	}

	proc callBack {} {
		if {![winfo exists $sys($w,toplevel)} {
			toplevel $sys($w,toplevel)
			pack [listbox $sys($w,listBox)]
			configureListBox $sys($w,listBox) $sys($w,entry)
		}
	}
}
