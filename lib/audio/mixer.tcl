package provide mixer 1.0

# TODO: dep management in widget
package require amixer
package require logger
if {![info exist geekosphere::tbar::packageloader::available]} {
	package require logger
	package require amixer
}

proc mixer {w args} {
	if {[geekosphere::tbar::widget::mixer::makeMixer $w $args] == -1} {
		return -1
	}

	proc $w {args} {
		geekosphere::tbar::widget::mixer::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}
catch {namespace import ::geekosphere::tbar::util::logger::* }
namespace eval geekosphere::tbar::widget::mixer {

	proc makeMixer {w arguments} {
		variable sys
		set sys($w,originalCommand) ${w}_
		set sys($w,activatedDevices) [list] 
		# create an array containing all controldevices
		# listed by amixer
		geekosphere::amixer::updateControlList

		frame ${w}

		pack [label ${w}.mixer -text "M"]
		bind ${w}.mixer <Button-1> [namespace code [list drawAllControls $w]]

		uplevel #0 rename $w ${w}_
		action $w configure $arguments
		initLogger
	}

	proc action {w args} {
		variable sys
		set args [join $args]
		set command [lindex $args 0]
		set rest [lrange $args 1 end]
		if {$command eq "configure"} {
			foreach {opt value} $rest {
				switch $opt {
					"-fg" - "-foreground" {
						changeForegroundColor $w $value
					}
					"-bg" - "-background" {
						changeBackgroundColor $w $value
					}
					"-width" {
						changeWidth $w $value
					}
					"-height" {
						changeHeight $w $value
					}
					"-font" {
						changeFont $w $value
					}
					"-devices" {
						setDevices $w $value
					}
					"-label" {
						setLabel $w $value
					}
					default {
						error "${opt} not supported"
					}
				}
			}
		} elseif {$command == "update"} {
			updateWidget $w
		} else {
			error "Command ${command} not supported"
		}

	}

	proc updateWidget {w} {
		variable sys
		foreach d $sys($w,activatedDevices) {
			foreach device $d { 
				if {![isValidDeviceDeclaration $device]} {
					log "WARN" "Device declaration illegal, please specify a single or a multidevice (max 2 devices)"
					return
				}
				set infoDict [geekosphere::amixer::getInformationOnDevice $device]
				if {[isMultiDevice $device]} {
					set path [getPathByDevice $w $device 1]
				} else {
					set path [getPathByDevice $w $device 0]
				}
				set meta [dict get $infoDict "meta"]
				set type [dict get $meta "type"]
				if {$type eq "INTEGER"} {
					setScrollbarValueFromInfoDict $path $infoDict
				}
				if {$type eq "BOOLEAN"} {
					setCheckboxAccordingToDevice $infoDict
				}
				if {$type eq "ENUMERATED"} {
					setComboboxAccordingToEnum $path $infoDict
				}
			}
		}
	}

	proc drawAllControls {w} {
		variable sys
		if {[llength $sys($w,activatedDevices)] == 0} {
			log "WARNING" "Nothing to draw, specify at least one device"
			return
		}
		if {[winfo exists ${w}.mixerWindow]} {
			destroy ${w}.mixerWindow
			return
		} else {
			toplevel ${w}.mixerWindow -bg $sys($w,background) -height 400 
		}
		foreach device $sys($w,activatedDevices) {
			set deviceCountInItem [llength $device]
			if {$deviceCountInItem == 1} {
				renderDeviceAccordingToType $w $device
			} elseif {$deviceCountInItem == 2} {
				renderDeviceAccordingToType $w $device 1 
			} else {
				log "WARNING" "Can't bundle more than two devices: $device"
			}
		}
		pack [label ${w}.mixerWindow.l -text "\n\n\n\n\n\n\n\n" -bg $sys($w,background)] -expand 1 -fill y
		positionWindowRelativly ${w}.mixerWindow $w
	}

	proc renderDeviceAccordingToType {w deviceList {multidevice 0}} {
		if {![isValidDeviceDeclaration $deviceList]} {
			log "WARN" "Illegal device declaration"
			return
		}
		set devicePath [getPathByDevice $w $deviceList $multidevice]
		
		foreach device $deviceList {
			if {[isDeviceAvailable $device]} {
				set deviceInformation [geekosphere::amixer::getInformationOnDevice $device]
				log "INFO" "deviceInformation: $deviceInformation" 
				set meta [dict get $deviceInformation "meta"]
				set info [dict get $deviceInformation "info"]

				set name [dict get $info "name"]
				set type [dict get $meta "type"]
				if {$type eq "BOOLEAN"} {
					drawSwitch $w $deviceInformation $devicePath $multidevice
				} elseif {$type eq "INTEGER"} {
					drawVolumeControl $w $deviceInformation $devicePath $multidevice
				} elseif {$type eq "ENUMERATED"} {
					drawEnumerated $w $deviceInformation $devicePath $multidevice
				}
			} else {
				log "WARNING" "Device does not exist: $deviceList"
			}
		}
	}

	proc isDeviceAvailable {numid} {
		foreach device [geekosphere::amixer::getControlDeviceList] {
			if  {$device == $numid} {
				return 1
			}
		}
		return 0
	}

	proc isMultiDevice {device} {
		return [expr {[llength $device] == 2}]
	}

	proc isValidDeviceDeclaration {device} {
		set l [llength $device]
		return [expr {$l == 2 || $l == 1}]
	}

	proc getPathByDevice {w device multidevice} {
		if {$multidevice} {
			set device [join $device _]
			log "INFO" "Multidevice path: $device"
		}
		return ${w}.mixerWindow.${device}
	}

	# draws a single volume scrollbar element
	proc drawVolumeControl {w infoDict path multi} {
		variable sys
		drawItemFrame $w $path
		set sbpath [getMultiDeviceScrollbarPath $path $infoDict]
		set sb [scrollbar $sbpath -command [list geekosphere::tbar::widget::mixer::changeYView $sbpath $infoDict] -bg $sys($w,background)]
		if {$multi} {
			drawItemHeaderGrid $w $path $infoDict
			insertWidgetIntoNextGridRow $path $sb
		} else {
			drawItemHeader $w $path $infoDict
			pack $sb -expand 1 -fill y 
		}
		setScrollbarValueFromInfoDict $path $infoDict $multi
	}

	proc setScrollbarValueFromInfoDict {path infoDict multi} {
		if {$multi} {
			set barPath [getMultiDeviceScrollbarPath $path $infoDict] 
		} else {
			set barPath ${path}.bar
		}
		if {[winfo exists $barPath]} {
			set setBarTo [getScrollbarValueFromDevice $infoDict]
			$barPath set $setBarTo $setBarTo
		}
	}

	proc getMultiDeviceScrollbarPath {containerPath infoDict} {
		set info [dict get $infoDict "info"]
		set p ${containerPath}.bar_[dict get $info "numid"]
		log "INFO" "path determined: $p"
		return $p
	}

	proc getScrollbarValueFromDevice {infoDict} {
		return [expr {1.0 - [getPercentageFromDevice $infoDict] / 100.0}]
	}

	proc getPercentageFromDevice {infoDict} {
		set meta [dict get $infoDict "meta"]
		set max [dict get $meta "max"]
		set values [dict get $infoDict values]
		# since we do not support multi channels, we are using the max value of all chans to display the device
		if {[llength $values] == 2} {
			set current [expr {max([lindex $values 0],[lindex $values 1])}]
		} else {
			set current $values
		}
		return [expr {round($current / ($max / 100.0))}]
	}

	# draws a switch control element
	proc drawSwitch {w infoDict path multi} {
		variable sys
		set info [dict get $infoDict "info"]
		set device [dict get $info "numid"]
		drawItemFrame $w $path
		set cb [checkbutton ${path}.cb \
			-bg $sys($w,background) \
			-font $sys($w,font) \
			-fg $sys($w,foreground) \
			-highlightbackground $sys($w,background) \
			-activebackground $sys($w,background) \
			-variable geekosphere::tbar::widget::mixer::sys(checkboxes,$device) \
			-command [list geekosphere::tbar::widget::mixer::setBooleanAccordingToCheckbox $infoDict]]
		if {$multi} {
			drawItemHeaderGrid $w $path $infoDict
			insertWidgetIntoNextGridRow $path $cb
		} else {
			drawItemHeader $w $path $infoDict
			pack $cb
		}
		setCheckboxAccordingToDevice $infoDict
	}

	proc setBooleanAccordingToCheckbox {infoDict} {
		variable sys
		set info [dict get $infoDict "info"]
		geekosphere::amixer::setDeviceBoolean $infoDict $sys(checkboxes,[dict get $info "numid"])
	}

	proc setCheckboxAccordingToDevice {infoDict} {
		variable sys
		set info [dict get $infoDict "info"]
		set sys(checkboxes,[dict get $info "numid"]) [amixerOnOffToBool [dict get $infoDict "values"]]
	}

	proc amixerOnOffToBool {input} {
		if {$input eq "on"} {
			return 1
		} else {
			return 0
		}
	}

	proc drawEnumerated {w infoDict path multi} {
		variable sys
		drawItemFrame $w $path
		set cb [ttk::combobox ${path}.cb -values [dict get $infoDict "items"] -state readonly]
		if {$multi} {
			drawItemHeaderGrid $w $path $infoDict
			insertWidgetIntoNextGridRow $path $cb
		} else {
			drawItemHeader $w $path $infoDict
			pack $cb
		}
		setComboboxAccordingToEnum $path $infoDict
		bind ${path}.cb <<ComboboxSelected>> [list geekosphere::tbar::widget::mixer::setEnumAccordingToCombobox $path $infoDict]
	}

	proc setEnumAccordingToCombobox {path infoDict} {
		set values [${path}.cb cget -values]
		set enum [lindex $values [${path}.cb current]]
		geekosphere::amixer::setDeviceEnum $infoDict $enum
	}

	proc setComboboxAccordingToEnum {path infoDict} {
		if {[winfo exists ${path}.cb]} {
			set currentValue [dict get $infoDict "values"]
			${path}.cb current $currentValue
		}
	}

	proc drawItemHeader {w path infoDict} {
		variable sys
		set info [dict get $infoDict "info"]
                pack [label ${path}.label -text [dict get $info "name"] -bg $sys($w,background) -font $sys($w,font) -fg $sys($w,foreground)] -side top
	}

	proc drawItemHeaderGrid {w containerPath infoDict} {
		variable sys
		set info [dict get $infoDict "info"]
		set label [label [getMultiDeviceLabelPath $containerPath $infoDict] -text [dict get $info "name"] -bg $sys($w,background) -font $sys($w,font) -fg $sys($w,foreground)]
		insertWidgetIntoNextGridRow $containerPath $label
	}

	proc insertWidgetIntoNextGridRow {containerPath widgetPath} {
		set nextFreeRow [lindex [grid size $containerPath] 1]
		grid $widgetPath -row $nextFreeRow
		log "INFO" "Placing $widgetPath in $nextFreeRow using $containerPath with size [grid size $containerPath]"
	}

	proc getMultiDeviceLabelPath {containerPath infoDict} {
		set info [dict get $infoDict "info"]
		return ${containerPath}.label_[dict get $info "numid"]
	}

	proc drawItemFrame {w path} {
		variable sys
		if {![winfo exists $path]} {
			pack [frame $path -bg $sys($w,background)] -fill y -expand 1 -side right
		}
	}

	# the action handler for the volume scrollbars
	proc changeYView {args} {
		set path [lindex $args 0]
		set infoDict [lindex $args 1]
		set command [lindex $args 2]
		set number [lindex $args 3]
		set postfix ""
		if {[llength $args] == 5} {
			set postfix [lindex $args 4]
		}
		switch $command {
			"moveto" {
				$path set $number $number
			}
			"scroll" {
				set pos [lindex [${path} get] 0]
				if {$postfix eq "pages"} {
					set factor 0.1
				} elseif {$postfix eq "units"} {
					set factor 0.01
				}

				set newVal [expr {$pos + ($number * $factor)}]
				$path set $newVal $newVal
			}
		}
		setVolumeAccordingToScrollBar $infoDict [$path get]
	}

	proc setVolumeAccordingToScrollBar {infoDict scrollbarLevel} {
		set level [expr {round(100 - ([lindex $scrollbarLevel 0] * 100))}]
		log "TRACE" "Bar moved to $level"
		geekosphere::amixer::setDevicePercent $infoDict $level
	}
	
	proc shouldDeviceBeShown {w numid} {
		variable sys
		if {![info exists sys($w,activatedDevices)] || [lsearch $sys($w,activatedDevices) $numid] != -1} { return 1 } else { return 0 }
	}

	#
	# Widget configuration procs
	#

	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		${w}.mixer configure -bg $color
		set sys($w,background) $color
	}

	proc changeForegroundColor {w color} {
		variable sys
		${w}.mixer configure -fg $color
		set sys($w,foreground) $color
	}

	proc changeFont {w font} {
		variable sys
		${w}.mixer configure -font $font
		set sys($w,font) $font
	}

	proc changeWidth {w width} {
		variable sys
		set sys($w,width) $width
		$sys($w,originalCommand) configure -width $width
	}

	proc changeHeight {w height} {
		variable sys
		set sys($w,height) $height
		$sys($w,originalCommand) configure -height $height
	}

	proc setDevices {w devices} {
		variable sys
		set sys($w,activatedDevices) $devices
	}

	proc setLabel {w label} {
		${w}.mixer configure -text $label
	}
}
