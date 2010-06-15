package require player

namespace eval geekosphere::tbar::wrapper::mpd {

	proc init {path settingsList} {
		pack [player $path \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			-height $geekosphere::tbar::conf(geom,height) \
			{*}$settingsList
		] -side $geekosphere::tbar::conf(widgets,position) -fill both
		return $path
	}
	
	proc update {path} {
		$path update
	}
}
