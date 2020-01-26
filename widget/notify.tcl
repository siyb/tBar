catch { namespace import geekosphere::tbar::packageloader::* }
namespace eval geekosphere::tbar::wrapper::notify {

	generallyRequires notify util
	parameterRequires notify -imageDimensions Img imageresize
	parameterRequires notify -image Img imageresize
	setNamespace notify ::geekosphere::tbar::widget::notify
	registerNamespaceImportsFor notify \
		::geekosphere::tbar::util::*

	proc init {path settingsList} {
		pack [notify $path \
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
