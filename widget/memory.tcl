catch { namespace import geekosphere::tbar::packageloader::* }
namespace eval geekosphere::tbar::wrapper::memory {

	generallyRequires memory statusBar util
	setNamespace memory ::geekosphere::tbar::widget::memory
	registerNamespaceImportsFor memory \
		::geekosphere::tbar::util::*
		
	proc init {path settingsList} {
		pack [memory $path \
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
