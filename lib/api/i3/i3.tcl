package require api
package require i3_ipc
package require i3_workspace

package provide api-i3

namespace eval geekosphere::tbar::api::api-i3 {
	variable sys
	set sys(legacy) 0

	proc init {} {
		return [geekosphere::api::autocreateProcList]
	}

	proc isConnected {} {
		return [geekosphere::tbar::i3::ipc::isConnected]
	}

	proc setCurrentDesktop {number} {
		variable sys
		if {$sys(legacy)} {
			geekosphere::tbar::widget::i3::workspace::changeWorkspaceLegacy	$number
		} else {
			geekosphere::tbar::widget::i3::workspace::changeWorkspaceNew $number
		}
	}

	proc getCurrentDesktop {} {
		return [geekosphere::tbar::widget::i3::workspace::getCurrentWorkspace]
	}

	proc setLegacyMode {legacy} {
		variable sys
		set sys(legacy) $legacy
	}
}
