package require cpu

namespace eval geekosphere::tbar::wrapper::cpu {
	
	proc init {path settingsList} {
		pack [cpu $path \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-height $geekosphere::tbar::conf(geom,height) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			{*}$settingsList
		] -side $geekosphere::tbar::conf(widgets,position)
		return $path
	}
	
	proc update {path} {
		$path update
	}
}
