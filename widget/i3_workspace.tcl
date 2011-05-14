catch { namespace import ::geekosphere::tbar::utils::* }
namespace eval geekosphere::tbar::wrapper::i3_workspace {

	generallyRequires i3_workspace i3_ipc json unix_sockets hex logger
	setNamespace i3_workspace ::geekosphere::tbar::widget::i3::workspace
	registerNamespaceImportsFor i3_workspace \
		::geekosphere::tbar::util::logger::* \
		::geekosphere::tbar::i3::ipc::* \
		::geekosphere::tbar::util::* \
		::geekosphere::tbar::util::logger::*
	
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
