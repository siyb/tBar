package provide weather 1.0

proc weather {w args} {
	geekosphere::tbar::widget::weather::makeWeather $w $args

	proc $w {args} {
		geekosphere::tbar::widget::weather::action [string trim [dict get [info frame 0] proc] ::] $args
	}
	return $w
}

catch { namespace import ::geekosphere::googleweather::* }
catch { namespace import ::geekosphere::tbar::util::* }
namespace eval geekosphere::tbar::widget::weather {

	proc makeWeather {w arguments} {
		variable sys
		set sys($w,originalCommand) ${w}_
		set sys($w,imagepath) ""

		set sys($w,location,country) ""
		set sys($w,location,state) ""
		set sys($w,location,city) ""
		set sys($w,location,zipcode) ""

		set sys($w,height) 1
		set sys($w,imagedata) ""

		set sys($w,stopPolling) 0
		set sys($w,currentWeatherInformation) ""

		set sys($w,unit) "c"

		frame $w
		pack [label ${w}.displayLabel]

		# rename widget so that it will not receive commands
		uplevel #0 rename $w ${w}_

		# run configuration
		action $w configure $arguments

		# mark the widget as initialized
		set sys($w,initialized) 1

		bind ${w}.displayLabel <Button-1> [namespace code [list showWeatherDialog $w %W]]
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
					"-font" {
						changeFont $w $value
					}
					"-height" {
						changeHeight $w $value
					}
					"-width" {
						changeWidth $w $value
					}
					"-imagepath" {
						setImagePath $w $value
					}
					"-unit"	{
						setUnit $w $value
					}
					"-country"	{ set sys($w,location,country) $value }
					"-state"	{ set sys($w,location,state) $value }
					"-city"		{ set sys($w,location,city) $value }
					"-zipcode"	{ set sys($w,location,zipcode) $value }
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
		if {!$sys($w,stopPolling)} {
		# setting location data for google weather foo
			setLocationData $sys($w,location,country) $sys($w,location,state) $sys($w,location,city) $sys($w,location,zipcode)
			set xml [getWeatherXmlForLocation]
			set currentCondition [getCurrentCondition $xml]

			if {$currentCondition != -1} {
				set iconUrl [dict get $currentCondition icon]

				# only attempt image rendering if the current weather condition differs from the last cached condiion
				if {$sys($w,currentWeatherInformation) eq "" || ([dict exists $sys($w,currentWeatherInformation) icon] && [dict get $sys($w,currentWeatherInformation) icon] ne $iconUrl)} {
					if {$sys($w,imagedata) ne ""} {
						image delete $sys($w,imagedata)
					}
					set sys($w,imagedata) [getImageDataFromUrl $w $iconUrl $sys($w,height)]
					${w}.displayLabel configure -image $sys($w,imagedata)
				}
				set sys($w,currentWeatherInformation) $currentCondition
			} else {
				set sys($w,stopPolling) 1
			}
		}
	}

	proc getImageDataFromUrl {w url height} {
		variable sys
		set imageData [image create photo -file [downloadImage $w $url]]
		if {$height != -1} {
			set imageData [imageresize::resize $imageData $height $height]
		}
		return $imageData
	}

	# download the image located at $url (if it hasn't been downloaded already) and returns the local path to the file
	proc downloadImage {w url} {
		variable sys
		set file [file join $sys($w,imagepath) [lindex [file split $url] end]]
		if {![file exists $file]} {
			set token [::http::geturl $url]
			set data [::http::data $token]
			::http::cleanup $token
			set fl [open $file w+]
			fconfigure $fl -translation binary
			puts $fl $data
			close $fl
		}
		return $file
	}

	proc showWeatherDialog {w window} {
		variable sys 
		set windowName ${w}.weatherInfo
		if {[winfo exists $windowName]} {
			destroy $windowName
		} else {
			toplevel $windowName -bg $sys($w,background)
			positionWindowRelativly $windowName $w
			
			pack [label ${windowName}.location -text "[string toupper $sys($w,location,city) 0 0], [string toupper $sys($w,location,country) 0 0]" -bg $sys($w,background) -fg $sys($w,foreground) -font $sys($w,font)]
			set xml [getWeatherXmlForLocation]
			foreach weatherForecast [getWeatherForecasts $xml] {
				renderForecastInformationRow $w [dict get $weatherForecast day_of_week] [dict get $weatherForecast icon] [dict get $weatherForecast high] [dict get $weatherForecast low]
			}
		}
	}

	proc toCelsius {fahrenheit} {
		return [expr {round((${fahrenheit} - 32.0) * (5.0/9.0))}]
	}

	proc renderForecastInformationRow {w dayOfWeek imageUrl maxTempFahrenheit minTempFahrenheit} {
		variable sys
		set dayOfWeekF [string tolower $dayOfWeek]
		if {$sys($w,unit) eq "c"} {
			set maxTempFahrenheit "[toCelsius $maxTempFahrenheit] C"
			set minTempFahrenheit "[toCelsius $minTempFahrenheit] C"
		} else {
			set maxTempFahrenheit "$maxTempFahrenheit F"
			set minTempFahrenheit "$minTempFahrenheit F"
		}
		pack [frame ${w}.weatherInfo.${dayOfWeekF} -bg $sys($w,background)]
		pack [label ${w}.weatherInfo.${dayOfWeekF}.image -image [getImageDataFromUrl $w $imageUrl -1] -bg $sys($w,background) -fg $sys($w,foreground) -font $sys($w,font)] -side left
		pack [label ${w}.weatherInfo.${dayOfWeekF}.dayOfWeek -text $dayOfWeek -bg $sys($w,background) -fg $sys($w,foreground) -font $sys($w,font)] -side left 
		pack [label ${w}.weatherInfo.${dayOfWeekF}.temperature -text "$minTempFahrenheit - $maxTempFahrenheit" -bg $sys($w,background) -fg $sys($w,foreground) -font $sys($w,font)] -side right
	}

	#
	# Widget configuration procs
	#

	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		set sys($w,background) $color
		${w}.displayLabel configure -bg $color
	}

	proc changeForegroundColor {w color} {
		variable sys
		set sys($w,foreground) $color
		${w}.displayLabel configure -fg $color
	}

	proc changeFont {w font} {
		variable sys
		set sys($w,font) $font
		${w}.displayLabel configure -font $font
	}

	proc changeHeight {w height} {
		variable sys
		set sys($w,height) $height
		$sys($w,originalCommand) configure -height $height
	}

	proc changeWidth {w width} {
		variable sys
		$sys($w,originalCommand) configure -width $width
	}

	proc setImagePath {w path} {
		variable sys
		if {![file exists $path]} {
			file mkdir $path
		}
		set sys($w,imagepath) $path
	}

	proc setUnit {w unit} {
		variable sys
		if {$unit eq "f" || $unit eq "c"} {
			set sys($w,unit) $unit
		} else {
			error "Unit '$unit' not supported"
		}
	}
}
