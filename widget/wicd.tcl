catch { namespace import geekosphere::tbar::packageloader::* }
namespace eval geekosphere::tbar::wrapper::wicd {

	generallyRequires networkmanager logger dbus BWidget
	setNamespace networkmanager ::geekosphere::tbar::widget::networkmanager
	registerNamespaceImportsFor networkmanager \
		::geekosphere::tbar::util::logger::* \
		::geekosphere::tbar::wicd::dbus::*

	proc init {path settingsList} {
		pack [networkmanager $path \
			-fg $geekosphere::tbar::conf(color,text) \
			-bg $geekosphere::tbar::conf(color,background) \
			-font $geekosphere::tbar::conf(font,sysFont) \
			-height $geekosphere::tbar::conf(geom,height) \
			-width [expr {$geekosphere::tbar::conf(geom,height) * 1.2}] \
			-driverPackage wicd_dbus \
			-driverNameSpace ::geekosphere::tbar::wicd::dbus \
			{*}$settingsList] -side $geekosphere::tbar::conf(widgets,position)
		return $path
	}

	proc update {path} {
		$path update
	}
}
