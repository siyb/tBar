namespace eval geekosphere::tbar::wrapper::player {

	setNamespace player ::geekosphere::tbar::widget::player
	registerNamespaceImportsFor player \
		::geekosphere::tbar::util::* \

	proc init {path settingsList} {
		pack [player $path \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			-height 10 \
			-bindplay [list puts play] \
			-bindpause [list puts pause] \
			-bindstop [list puts stop] \
			-bindupdate [list puts update] \
			{*}$settingsList
		] -side $geekosphere::tbar::conf(widgets,position) -fill both
		return $path
	}
	proc update {path} {
		$path update
	}
}
