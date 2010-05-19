package require memory

namespace eval geekosphere::tbar::widget::memory {

	proc init {settingsList} {
		variable sys
		set sys(path) [geekosphere::tbar::util::generateComponentName]
		pack [memory $sys(path) \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			{*}$settingsList
		] -side $geekosphere::tbar::conf(widgets,position)
	}
	
	proc update {} {
		variable sys
		$sys(path) update
	}
}
