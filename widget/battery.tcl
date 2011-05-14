catch { namespace import geekosphere::tbar::packageloader::* }
namespace eval geekosphere::tbar::wrapper::battery {

	generallyRequires battery logger
	setNamespace memory ::geekosphere::tbar::widget::battery
	registerNamespaceImportsFor battery \
		::geekosphere::tbar::util::logger::*
		
	proc init {path settingsList} {
		pack [battery $path \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			-height $geekosphere::tbar::conf(geom,height) \
			-width [expr {$geekosphere::tbar::conf(geom,height) * 2}] \
			{*}$settingsList] -side $geekosphere::tbar::conf(widgets,position)
		return $path
	}

	proc update {path} {
		$path update
	}
}
