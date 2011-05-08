package require notify
package require util
catch { namespace import geekosphere::tbar::packageloader::* }
namespace eval geekosphere::tbar::wrapper::notify {

	# let tbar know about package dependencies
	parameterRequires notify -imageDimensions Img imageresize
	parameterRequires notify -image Img imageresize

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
