package provide weather 1.0

package require googleweather
package require http
package require imageresize
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

		frame $w
		pack [label ${w}.displayLabel]

		# rename widget so that it will not receive commands
		uplevel #0 rename $w ${w}_

		# run configuration
		action $w configure $arguments

		# mark the widget as initialized
		set sys($w,initialized) 1
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
		# setting location data for google weather foo
		setLocationData $sys($w,location,country) $sys($w,location,state) $sys($w,location,city) $sys($w,location,zipcode)
		set xml [getWeatherXmlForLocation]
		set currentCondition [getCurrentCondition $xml]
		
		if {$sys($w,imagedata) ne ""} {
			image delete $sys($w,imagedata)
		}
		set sys($w,imagedata) [image create photo -file [downloadImage $w [dict get $currentCondition icon]]]
		set sys($w,imagedata) [imageresize::resize $sys($w,imagedata) $sys($w,height) $sys($w,height)]
		${w}.displayLabel configure -image $sys($w,imagedata) 
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

	#
	# Widget configuration procs
	#

	proc changeBackgroundColor {w color} {
		variable sys
		$sys($w,originalCommand) configure -bg $color
		${w}.displayLabel configure -bg $color
	}

	proc changeForegroundColor {w color} {
		variable sys
		${w}.displayLabel configure -fg $color
	}

	proc changeFont {w font} {
		variable sys
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
}
