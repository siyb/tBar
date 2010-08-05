package provide cpu 1.2

package require barChart
package require util
package require logger

proc cpu {w args} {
	geekosphere::tbar::widget::cpu::makeCpu $w $args

	proc $w {args} {
		geekosphere::tbar::widget::cpu::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

# TODO 1.2: add support for multiple thermal sources
catch { namespace import ::geekosphere::tbar::util::* }
namespace eval geekosphere::tbar::widget::cpu {
	
	
	#
	# For all widgets this information is the same
	#
	# cpu thermal information
	dict set sys(thermal) sys.dir "/sys/class/thermal/" 
	dict set sys(thermal) sys.file "temp" 
	dict set sys(thermal) sys.mod "1000"
	dict set sys(thermal) core.dir "/sys/devices/platform/" 
	dict set sys(thermal) core.file "temp1_input" 
	dict set sys(thermal) core.mod "1000"
	dict set sys(thermal) proc.dir "/proc/acpi/thermal_zone/" 
	dict set sys(thermal) proc.file "temperature" 
	dict set sys(thermal) proc.mod "-1"
	set sys(thermalSource) -1
	set sys(cpu,temperature) "N/A"
	# cpu general info
	set sys(cpuinfo) "/proc/cpuinfo"
	set sys(general) -1
	# stat info
	set sys(stat) "/proc/stat"
	set sys(statData) -1
	
	#
	# cpu speedstepping
	#
	
	# static stuff
	dict set sys(speedstep,files) directory "/sys/devices/system/cpu/%s/cpufreq/"
	dict set sys(speedstep,files) minFreq "cpuinfo_min_freq"
	dict set sys(speedstep,files) maxFreq "cpuinfo_max_freq"
	dict set sys(speedstep,files) driver "scaling_driver"
	dict set sys(speedstep,files) availGovs "scaling_available_governors"
	dict set sys(speedstep,files) availFreqs "scaling_available_frequencies"
	dict set sys(speedstep,files) currGov "scaling_governor"
	dict set sys(speedstep,files) currFreq "scaling_cur_freq"
	
	proc makeCpu {w arguments} {
		variable sys
		
		set sys($w,originalCommand) ${w}_
		
		set sys($w,cpu,temperature) "N/A"
		set sys($w,cpu,load) "N/A"
		
		# cache general cpu information (which is static)
		set sys(general) [geekosphere::tbar::util::parseProcFile $sys(cpuinfo) [list "processor" "cpuMHz" "cachesize"]]
		if {[set device [getOption "-device" $arguments]] eq ""} { error "Specify a device using the -device option." }
		set sys($w,showMhz) [string is true -strict [getOption "-showMhz" $arguments]]
		set sys($w,showCache) [string is true -strict [getOption "-showCache" $arguments]]
		set sys($w,showLoad) [string is true -strict [getOption "-showLoad" $arguments]]
		set sys($w,showTemperature) [string is true -strict [getOption "-showTemperature" $arguments]]
		set sys($w,showTotalLoad) [string is true -strict [getOption "-showTotalLoad" $arguments]]
		set sys($w,useSpeedStep) [string is true -strict [getOption "-useSpeedstep" $arguments]]
		set sys($w,device) $device
		set sys($w,cpu,mhz) 0
		set sys($w,cpu,cache) [getCacheSize $sys($w,device)]
		
		set sys($w,cpu,totalTime) 0
		set sys($w,cpu,activeTime) 0
		set sys($w,cpu,load) 0
		
		frame ${w}
		
		if {$sys($w,showTemperature)} {
			pack [frame ${w}.temperature] -side left -fill both
			pack [label ${w}.temperature.label -text "Temperature:"] -side left -fill both
			pack [label ${w}.temperature.display -textvariable geekosphere::tbar::widget::cpu::sys($w,cpu,temperature)] -side left -fill both
		}
		
		if {$sys($w,showMhz)} {
			pack [frame ${w}.mhz] -side left -fill both
			pack [label ${w}.mhz.label -text "MHz:"] -side left -fill both
			pack [label ${w}.mhz.display -textvariable geekosphere::tbar::widget::cpu::sys($w,cpu,mhz) ] -side left -fill both
		}
		
		if {$sys($w,showCache)} {
			pack [frame ${w}.cache] -side left -fill both
			pack [label ${w}.cache.label -text "Cache:"] -side left -fill both
			pack [label ${w}.cache.display -textvariable geekosphere::tbar::widget::cpu::sys($w,cpu,cache)] -side left -fill both
		}
		
		if {$sys($w,showLoad)} {
			if {$sys($w,showTotalLoad)} {
				set displayText "CPU Total Load:"
			} else {
				set displayText "CPU Load $sys($w,device):"
			}
			pack [frame ${w}.load] -side left -fill both
			pack [label ${w}.load.label -text "$displayText"] -side left -fill both
			pack [barChart ${w}.load.barChart -textvariable geekosphere::tbar::widget::cpu::sys($w,cpu,load) -width 100] -side left -fill both
		}
		
		if {$sys($w,useSpeedStep)} {
			foreach window [returnNestedChildren $w] {
				bind $window <Button-1> [namespace code [list displayFreqInfo $w]]
			}
		}
		
		# rename widgets so that it will not receive commands
		uplevel #0 rename $w ${w}_

		# run configuration
		action $w configure $arguments
		
		# mark the widget as initialized
		set sys($w,initialized) 1
		
		initLogger
	}
	
	proc isInitialized {w} {
		variable sys
		return [info exists sys($w,initialized)]
	}

	proc updateWidget {w} {
		variable sys
		#
		# Gather data
		#
		if {$sys(thermalSource) == -1 && $sys($w,showTemperature)} {
			set sys(thermalSource) [determineThermalsource]
		}
		
		# TODO 1.x: maybe use a timer here to cache information so that the IO requests are reduced
		set sys(statData) [statFileParser $sys(stat)]
		
		#
		# Updating gui
		#
		set sys($w,cpu,temperature) "[getTemperature] C°"
		set sys($w,cpu,mhz) [getMHz $w $sys($w,device)]
		set load [getCpuLoad $w]
		set sys($w,cpu,load) $load
		if {$sys($w,showLoad)} {
			${w}.load.barChart pushValue $load
			${w}.load.barChart update
		}
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
					"-lc" - "-loadcolor" {
						changeLoadColor $w $value
					}
					"-device" {
						if {[isInitialized $w]} { error "Device cannot be changed after widget initialization" }
					}
					"-showTotalLoad" {
						if {[isInitialized $w]} { error "showTotalLoad cannot be changed after widget initialization" }
					}
					"-width" {
						changeWidth $w $value
					}
					"-height" {
						changeHeight $w $value
					}
					"-showMhz" {
						if {[isInitialized $w]} { error "showMhz cannot be changed after widget initialization" }
					}
					"-showCache" {
						if {[isInitialized $w]} { error "showCache cannot be changed after widget initialization" }
					}
					"-showLoad" {
						if {[isInitialized $w]} { error "showLoad cannot be changed after widget initialization" }
					}
					"-showTemperature" {
						if {[isInitialized $w]} { error "showTemperature cannot be changed after widget initialization" }
					}
					"-useSpeedstep" {
						if {[isInitialized $w]} { error "useSpeedstep cannot be changed after widget initialization" }
					}
					"-font" {
						changeFont $w $value
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
	
	# determine which thermal source file to use
	proc determineThermalsource {} {
		variable sys
		dict for {item value} $sys(thermal) {
			if {[string match *.dir $item]} {
				set dirName $value
				continue
			}
			if {[string match *.file $item]} {
				set fileName $value
			}
			if {$fileName eq "" || $dirName eq ""} {
				continue
			}
			set fileName [glob -nocomplain -directory $dirName *[file separator]$fileName]
			set fnl [llength $fileName]
			if {$fnl > 1} { 
				set fileName [lindex $fileName 0]
				puts "There seem to be multiple temperature monitors installed on your system, defaulting to ${fileName}" 
			}
			if {$fnl < 1} { continue }
			
			# return fileName and modifier
			return [list $fileName [dict get $sys(thermal) [lindex [split $item "."] 0].mod]]
		}
		error "thermal source could not be determined, perhaps your system is not configured correctly"
	}
	
	# get mhz of cpu $device
	proc getMHz {w device} {
		variable sys
		# without speedstepping
		if {!$sys($w,useSpeedStep) || ![isCpuFreqAvailable $w]} {
			if {[set mhz [lindex [dict get $sys(general) "cpuMHz"] $device]] eq ""} {
				error "unable to determine cpu MHz, please check if you specified the correct device"
			}
		# with speedstepping
		} else {
			set mhz [expr [getFrequency $w] / 1000];# convert khz in mhz
		}
		return [::tcl::mathfunc::round $mhz]
	}
	
	# get cache of cpu $device
	proc getCacheSize {device} {
		variable sys
		if {[set cache [lindex [dict get $sys(general) "cachesize"] $device]] eq ""} {
			error "unable to determine cpu cache size, please check if you specified the correct device"
		}
		return $cache
	}
	
	# gets the temperature
	proc getTemperature {} {
		variable sys
		if {$sys(thermalSource) <= 0} { return "N/A" }
		set mod [lindex $sys(thermalSource) 1]
		set data [set data [read [set fl [open [lindex $sys(thermalSource) 0] r]]]]
		close $fl
		set data [geekosphere::tbar::util::parseFirstInteger $data]
		if {$mod == -1} {
			return $data
		} else {
			return [expr {$data / $mod}]
		}
	}
	
	# returns the cpu load of the specified cpu device
	proc getCpuLoad {w} {
		variable sys
		# load of all cpus
		if {$sys($w,showTotalLoad)} {
			set deviceData [lsearch -inline -index 0 $sys(statData) "cpu"]
		# load of the cpu specified by -device
		} else {
			set deviceData [lsearch -inline -index 0 $sys(statData) "cpu$sys($w,device)"]
		}
		if {$deviceData eq ""} {
			error "unable to determine cpu load, please check if you specified the correct device"
		}
		set activeTime [expr {[lindex $deviceData 1] + [lindex $deviceData 2] + [lindex $deviceData 3] + [lindex $deviceData 5] + [lindex $deviceData 6] + [lindex $deviceData 7]}]
		set idleTime [lindex $deviceData 4]
		set totalTime [expr {$activeTime + $idleTime}]
		
		set diffTotal [expr {$totalTime - $sys($w,cpu,totalTime)}]
		set diffActive [expr {$activeTime - $sys($w,cpu,activeTime)}]
		if {$diffTotal == 0 || $diffActive == 0} { return 0.0 }
		set usage [::tcl::mathfunc::floor [expr $diffActive. / $diffTotal. * 100.]]
		
		set sys($w,cpu,totalTime) $totalTime
		set sys($w,cpu,activeTime) $activeTime
		return $usage
	}
	
	# returns a list of all cpu entries of the statfile
	proc statFileParser {file} {
		set data [split [read [set fl [open $file r]]] "\n"]
		close $fl
		return [lsearch -all -inline $data "cpu*"]
	}
	
	#
	# CPU Frequency Scaling
	#
	
	proc displayFreqInfo {w} {
		variable sys
		set freqWindow ${w}.freq
		if {[winfo exists $freqWindow]} { 
			destroy $freqWindow
			return 
		}
		
		toplevel $freqWindow
		set displayText ""
		dict for {item value} [cpuSpeedstepInfo $w] {
			append displayText "${item}: ${value}\n"
		}
		pack [label ${freqWindow}.display \
			-text $displayText \
			-fg $sys($w,foreground) \
			-bg $sys($w,background) \
			-font $sys($w,font) \
			-justify left
		]

		positionWindowRelativly $freqWindow $w
	}
	
	proc cpuSpeedstepInfo {w} {
		dict set rdict Available [isCpuFreqAvailable $w]
		dict set rdict CurrentGov [getGovernor $w]
		dict set rdict AvailGov [getAvailableGovernors $w]
		dict set rdict CurrentFreq [getFrequency $w]
		dict set rdict MaxFreq [getMaxFrequency $w]
		dict set rdict MinFreq [getMinFrequency $w]
		dict set rdict SupportedFreq [getSupportedFrequencies $w]
		return $rdict
	}
	
	proc formatSpeedstepPath {w} {
		variable sys
		return [format [dict get $sys(speedstep,files) directory] "cpu$sys($w,device)"]
	}
	
	proc getFreqFile {w type} {
		variable sys
		return [file join [formatSpeedstepPath $w] [dict get $sys(speedstep,files) $type]]
	}
	
	proc isCpuFreqAvailable {w} {
		set check [list minFreq maxFreq driver availGovs availFreqs currGov]
		foreach item $check {
			set file [getFreqFile $w $item]
			if {![file exists $file]} {
				log "ERROR" "CPU Frequency Scaling not possible: ${item} not found -> $file"
				return 0
			}
		}
		return 1
	}
	
	proc getFreqFileData {w type} {
		set freqFile [getFreqFile $w $type] 
		if {![file exists $freqFile]} { log "WARNING" "${freqFile} does not exist and therefore cannot be accessed."; return "N/A" }
		set data [string trim [read [set fl [open $freqFile r]]]]
		close $fl
		return $data
	}
	
	proc getGovernor {w} {
		variable sys
		return [getFreqFileData $w currGov]
	}
	
	proc getAvailableGovernors {w} {
		variable sys
		return [getFreqFileData $w availGovs]
	}

	proc getFrequency {w} {
		variable sys
		return [getFreqFileData $w currFreq]	
	}
	
	proc getMaxFrequency {w} {
		variable sys
		return [getFreqFileData $w maxFreq]	
	}
	
	proc getMinFrequency {w} {
		variable sys
		return [getFreqFileData $w minFreq]	
	}
	
	proc getSupportedFrequencies {w} {
		variable sys
		return [getFreqFileData $w availFreqs]	
	}
	
	#
	# Widget configuration procs
	#
	
	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		
		# temperature
		if {$sys($w,showTemperature)} {
			${w}.temperature configure -bg $color
			${w}.temperature.label configure -bg $color
			${w}.temperature.display configure -bg $color
		}
		# mhz
		if {$sys($w,showMhz)} {
			${w}.mhz configure -bg $color
			${w}.mhz.label configure -bg $color
			${w}.mhz.display configure -bg $color
		}
		# cache
		if {$sys($w,showCache)} {
			${w}.cache configure -bg $color
			${w}.cache.label configure -bg $color
			${w}.cache.display configure -bg $color
		}
		# load
		if {$sys($w,showLoad)} {
			${w}.load configure -bg $color
			${w}.load.label configure -bg $color
			${w}.load.barChart configure -bg $color
		}
		
		# for cpu freq info window
		set sys($w,background) $color
	}
	
	proc changeForegroundColor {w color} {
		variable sys
		# temperature
		if {$sys($w,showTemperature)} {
			${w}.temperature.label configure -fg $color
			${w}.temperature.display configure -fg $color
		}
		
		# mhz
		if {$sys($w,showMhz)} {
			${w}.mhz.label configure -fg $color
			${w}.mhz.display configure -fg $color
		}
		 
		# cache
		if {$sys($w,showCache)} {
			${w}.cache.label configure -fg $color
			${w}.cache.display configure -fg $color
		}
		
		# load
		if {$sys($w,showLoad)} {
			${w}.load.label configure -fg $color
			${w}.load.barChart configure -fg $color
		}
		
		# for cpu freq info window
		set sys($w,foreground) $color
	}
	
	proc changeWidth {w width} {
		variable sys
		$sys($w,originalCommand) configure -width $width
	}
	
	proc changeHeight {w height} {
		variable sys
		$sys($w,originalCommand) configure -height $height
		if {$sys($w,showLoad)} {
			${w}.load.barChart configure -height $height
		}
	}
	
	proc changeLoadColor {w color} {
		variable sys
		if {$sys($w,showLoad)} {
			${w}.load.barChart configure -gc $color
		}
	}
	
	proc changeFont {w font} {
		variable sys
		# temperature
		if {$sys($w,showTemperature)} {
			${w}.temperature.label configure -font $font
			${w}.temperature.display configure -font $font
		}
		
		# mhz
		if {$sys($w,showMhz)} {
			${w}.mhz.label configure -font $font
			${w}.mhz.display configure -font $font
		}
		 
		# cache
		if {$sys($w,showCache)} {
			${w}.cache.label configure -font $font
			${w}.cache.display configure -font $font
		}
		
		# load
		if {$sys($w,showLoad)} {
			${w}.load.label configure -font $font
			${w}.load.barChart configure -font $font
		}
		
		# for cpu freq info window
		set sys($w,font) $font
	}
}