package require i3_workspace

namespace eval geekosphere::tbar::wrapper::i3_workspace {
	
	proc init {path settingsList} {
		pack [i3_workspace $path \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			{*}$settingsList
		] -side $geekosphere::tbar::conf(widgets,position)
		return $path
	}
	
	proc update {path} {
		$path update
	}
}
