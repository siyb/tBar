# Info:
# you may adjust the look of the "widget" by setting the following variables:
#
# - set geekosphere::tbar::snippets::volume::sys(currentColor) COLOR
# - set geekosphere::tbar::snippets::volume::sys(remainderColor) COLOR
# - set geekosphere::tbar::snippets::volume::sys(char) CHAR
# - set geekosphere::tbar::snippets::volume::sys(item) DEVICE (like master)
#
#
namespace eval volume {
	variable sys
	set sys(char) "|"
	set sys(item) "Master"
	set sys(devices) [list]
	set sys(counter) 0
	set sys(currentColor) #6D91BE
	set sys(remainderColor) red

	proc run {} {
		variable sys
		foreach device [getVolumeData] {
			addWidgetToBar text volumecurrent$sys(counter) 1 -fg $sys(currentColor) -command [list geekosphere::tbar::snippets::volume::updateCurrent $sys(counter)]
			addWidgetToBar text volumeremainder$sys(counter) 1 -fg $sys(remainderColor) -command  [list geekosphere::tbar::snippets::volume::updateRemainder $sys(counter)]
			incr sys(counter)
		}
	}

	proc updateRemainder {item} {
		variable sys
		set currentVolume [getCurrent $item]
		return [string repeat $sys(char) [expr {10 - $currentVolume}]]
	}

	proc updateCurrent {item} {
		variable sys
		set currentVolume [getCurrent $item]
		return [string repeat $sys(char) $currentVolume]
	}

	proc getCurrent {item} {
		set data [lindex [getVolumeData] $item]
		set data [string trim $data "%"]
		return [expr {round($data / 10)}]
	}

	proc getVolumeData {} {
		return [regexp -all -inline "\[0-9]{1,}%" [exec amixer sget Master]]
	}
}
