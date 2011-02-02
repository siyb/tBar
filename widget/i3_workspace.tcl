package require i3_workspace

catch { namespace import ::geekosphere::tbar::utils::* }
namespace eval geekosphere::tbar::wrapper::i3_workspace {

	proc init {path settingsList} {
		if {[set side [getOption "-side" $settingsList]] eq ""} {
			set side $geekosphere::tbar::conf(widgets,position)
		}
		pack [i3_workspace $path \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			{*}$settingsList
		] -side $side
		return $path
	}

	proc update {path} {
		$path update
	}
}
