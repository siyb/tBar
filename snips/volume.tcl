namespace eval volume {
	variable sys
	set sys(char) "|"
	set sys(item) "Master"
	set sys(devices) [list]
	set sys(counter) 0

	proc run {} {
		variable sys
		foreach device [getVolumeData] {
			addWidgetToBar text volumewidget$sys(counter) 1 -command [list geekosphere::tbar::snippets::volume::update $sys(counter)] 
			incr sys(counter)
		}
	}

	proc update {item} {
		variable sys
		set data [lindex [getVolumeData] $item]
		set data [string trim $data "%"]
		set current [expr {round($data / 10)}]
		return [string repeat $sys(char) $current]
	}

	proc getVolumeData {} {
		return [regexp -all -inline "\[0-9]{1,}%" [exec amixer sget Master]]
	}
}
