catch { namespace import geekosphere::tbar::packageloader::* }
namespace eval geekosphere::tbar::wrapper::cpu {

	generallyRequires cpu barChart util logger
	setNamespace cpu ::geekosphere::tbar::widget::cpu
	registerNamespaceImportsFor cpu \
		::geekosphere::tbar::util::*
	
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
