catch { namespace import geekosphere::tbar::packageloader::* }
namespace eval geekosphere::tbar::wrapper::network {

	generallyRequires network statusBar util
	setNamespace network ::geekosphere::tbar::widget::network
	registerNamespaceImportsFor network \
		::geekosphere::tbar::util::*
		
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
