package require cpu

namespace eval geekosphere::tbar::widget::cpu {
	
	proc init {settingsList} {
		variable sys
		set sys(path) [geekosphere::tbar::util::generateComponentName]
		pack [cpu $sys(path) \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-height $geekosphere::tbar::conf(geom,height) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			{*}$settingsList
		] -side $geekosphere::tbar::conf(widgets,position)
	}
	
	proc update {} {
		variable sys
		$sys(path) update
	}
}
