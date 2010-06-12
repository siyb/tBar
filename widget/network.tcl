package require network

namespace eval geekosphere::tbar::wrapper::network {
	
	proc init {path settingsList} {
		pack [network $path \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			{*}$settingsList
		] -side $geekosphere::tbar::conf(widgets,position) -fill both
		return $path
	}
	
	proc update {path} {
		$path update
	}
}
