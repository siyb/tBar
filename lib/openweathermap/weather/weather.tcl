package provide openweathermap 1.0

package require http
package require tdom

namespace eval geekosphere::openweathermap {
	namespace import ::tcl::mathop::*
	namespace import ::tcl::mathfunc::*

	variable sys
	set sys(url) "http://api.openweathermap.org/data/2.5/forecast/"
	set sys(imageBaseUrl) "http://openweathermap.org/img/w/"

	set sys(location,country) ""
	set sys(location,city) ""

	proc getCurrentCondition {weatherXmlForLocation} {
		set condition [lindex [getWeatherForecasts $weatherXmlForLocation] 0]
		set temperatureF [dict get $condition "high"]
		set temperatureC [expr (${temperatureF} - 32.0) * (5.0/9.0)]

		dict set ret "temp_c" [round $temperatureC]
		dict set ret "temp_f" $temperatureF
		dict set ret "icon" [dict get $condition "icon"]
		
		return $ret
	}
	
	proc getImageUrlByCode {code} {
		variable sys
		return $sys(imageBaseUrl)${code}.png
	}

	proc getWeatherForecasts {weatherXmlForLocation} {
		set ret [list]
		set skipDays [list]
		foreach forecast [$weatherXmlForLocation getElementsByTagName "time"] {
			puts [llength $ret]
			if {[llength $ret] > 2} { break }
			set timeInMs [clock scan [$forecast getAttribute "from"] -format {%Y-%m-%dT%H:%M:%S}]
			set dayOfWeek [clock format $timeInMs -format %a]

			if {[lsearch $skipDays $dayOfWeek] != -1} { continue }
			lappend skipDays $dayOfWeek

			dict set tmp day_of_week $dayOfWeek
			foreach childNode [$forecast childNodes] {
				if {[$childNode nodeName] eq "symbol"} {
					dict set tmp icon [getImageUrlByCode [$childNode getAttribute "var"]]
				} elseif {[$childNode nodeName] eq "temperature"} {
					dict set tmp high [$childNode getAttribute "max"]
					dict set tmp low [$childNode getAttribute "min"]
				}

			}
			puts $tmp
			lappend ret $tmp
		}
		return $ret
	}

	proc getWeatherXmlForLocation {} {
		variable sys
		# using -query did not work Oo
		set data [::http::data [set token [::http::geturl $sys(url)?[getWeatherQuery]]]]
		::http::cleanup $token
		puts $data
		return [dom parse $data]
	}

	proc getWeatherQuery {} {
		variable sys
		return [::http::formatQuery q $sys(location,country),$sys(location,city) mode xml units imperial cnt 3]
	}

	proc setLocationData {country state city zipcode} {
		variable sys
		set sys(location,country) $country
		set sys(location,city) $city
	}
	
	namespace export setLocationData getWeatherXmlForLocation getCurrentCondition getWeatherForecasts
}
