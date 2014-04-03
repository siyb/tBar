catch { namespace import geekosphere::tbar::packageloader::* }
namespace eval geekosphere::tbar::wrapper::wicd {

	generallyRequires wicd logger dbus wicd_dbus
	setNamespace wicd ::geekosphere::tbar::widget::wicd
	registerNamespaceImportsFor wicd \
		::geekosphere::tbar::util::logger::* \
		::geekosphere::tbar::wicd::dbus::*

	proc init {path settingsList} {
		pack [wicd $path \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			-height $geekosphere::tbar::conf(geom,height) \
			-width [expr {$geekosphere::tbar::conf(geom,height) * 1.2}] \
			{*}$settingsList] -side $geekosphere::tbar::conf(widgets,position)
		return $path
	}

	proc update {path} {
		$path update
	}
}
