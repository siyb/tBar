package require calClock

namespace eval geekosphere::tbar::widget::clock {
	
	proc init {settingsList} {
		variable sys
		set sys(path) [geekosphere::tbar::util::generateComponentName]
		pack [calClock $sys(path) \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-format "%B %d, %H:%M:%S" \
			-hovercolor $geekosphere::tbar::conf(color,hovercolor) \
			-clickedcolor $geekosphere::tbar::conf(color,clickedcolor) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			{*}$settingsList
		] -side $geekosphere::tbar::conf(widgets,position)
	}
	
	proc update {} {
		variable sys
		$sys(path) update
	}
}
