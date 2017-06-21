package provide mixer 1.0

# TODO: add support for multiple boolean values, in the form of: values {off off}
# TODO: dep management in widget
package require amixer
package require tbar_logger
if {![info exist geekosphere::tbar::packageloader::available]} {
	package require tbar_logger
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

		frame ${w}

		pack [label ${w}.mixer -text "M"]
		bind ${w}.mixer <Button-1> [namespace code [list drawAllControls $w]]

		uplevel #0 rename $w ${w}_
		set sys($w,card) 0;# card defaults to 0, can be controlled using the -card parameter
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
					"-card" {
						setCard $w $value
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
		log "TRACE" "updating for $w"
		foreach d $sys($w,activatedDevices) {
			set multi [isMultiDevice $d]
			log "TRACE" "updating device(list): $d"
			foreach device $d {
				log "TRACE" "updating device: $device"
				if {![isValidDeviceDeclaration $device]} {
					log "WARNING" "Device declaration illegal, please specify a single or a multidevice (max 2 devices)"
					return
				}
				set infoDict [geekosphere::amixer::getInformationOnDevice $sys($w,card) $device]
				log "TRACE" "Updating: $infoDict"
				if {$multi} {
					set path [getPathByDevice $w $d 1]
				} else {
					set path [getPathByDevice $w $device 0]
				}
				set meta [dict get $infoDict "meta"]
				set type [dict get $meta "type"]
				log "TRACE" "$path | $infoDict | $multi"
				if {$type eq "INTEGER"} {
					setScrollbarValueFromInfoDict $path $infoDict $multi
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
		variable sys
		if {![isValidDeviceDeclaration $deviceList]} {
			log "WARNING" "Illegal device declaration, you may only define two devices for multidisplay and if you do, they mustn't be the same"
			return
		}
		set devicePath [getPathByDevice $w $deviceList $multidevice]

		foreach device $deviceList {
			if {[isDeviceAvailable $w $device]} {
				set deviceInformation [geekosphere::amixer::getInformationOnDevice $sys($w,card) $device]
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

	proc isDeviceAvailable {w numid} {
		variable sys
		foreach device [geekosphere::amixer::getControlDeviceList $sys($w,card)] {
			log "DEBUG" "Checking if $numid exists on card number $sys($w,card) -> current device being checked: $device"
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
		if {$l == 2 || $l == 1} {
			if {[lindex $device 0] == [lindex $device 1]} {
				return 0
			} else {
				return 1
			}
		} else {
			return 0
		}
	}

	proc getPathByDevice {w device multidevice} {
		if {$multidevice} {
			set device [join $device _]
			log "TRACE" "Multidevice path: $device"
		}
		return ${w}.mixerWindow.${device}
	}

	# draws a single volume scrollbar element
	proc drawVolumeControl {w infoDict path multi} {
		variable sys
		drawItemFrame $w $path
		if {$multi} {
			set sbpath [getMultiDeviceScrollbarPath $path $infoDict]
		} else {
			set sbpath ${path}.bar
		}
		log "INFO" "Drawing $infoDict in $sbpath"
		set sb [scrollbar $sbpath -command [list geekosphere::tbar::widget::mixer::changeYView $sbpath $infoDict] -bg $sys($w,background)]
		if {$multi} {
			drawItemHeaderGrid $w $path $infoDict
			insertWidgetIntoNextGridRow $path $sb 1
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
		log "TRACE" "path determined: $p"
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
		if {$multi} {
			set sbpath [getMultiDeviceCheckboxPath $path $infoDict]
		} else {
			set sbpath ${path}.cb
		}
		log "INFO" "Drawing $infoDict in $sbpath"
		set cb [checkbutton $sbpath \
			-bg $sys($w,background) \
			-font $sys($w,font) \
			-fg $sys($w,background) \
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

	proc getMultiDeviceCheckboxPath {containerPath infoDict} {
		set info [dict get $infoDict "info"]
		set p ${containerPath}.cb_[dict get $info "numid"]
		log "INFO" "path determined: $p"
		return $p
	}

	proc amixerOnOffToBool {input} {
		set splitInput [split $input]
		if {[llength $splitInput] != 1} {
			log "INFO" "Input has multiple channels, using the first!"
			set input [lindex $splitInput 0]
		}
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

	proc insertWidgetIntoNextGridRow {containerPath widgetPath {weight 0}} {
		grid $widgetPath
		grid rowconfigure $containerPath $widgetPath -weight $weight
		grid configure $widgetPath -sticky ns
		log "INFO" "Placing $widgetPath using $containerPath with size [grid size $containerPath] and rowspan $weight"
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

	proc setCard {w card} {
		variable sys
		set sys($w,card) $card
	}

	proc setLabel {w label} {
		${w}.mixer configure -text $label
	}
}
