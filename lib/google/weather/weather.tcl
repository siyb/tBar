package provide googleweather 1.0

package require tdom
package require http

namespace eval geekosphere::googleweather {
	variable sys
	set sys(url) "http://www.google.com/ig/api?weather="
	
	set sys(urlFormat) 0

	set sys(location,country) ""
	set sys(location,state) ""
	set sys(location,city) ""
	set sys(location,zipcode) ""

	proc getCurrentCondition {weatherXmlForLocation} {
		set currentInformationNode [$weatherXmlForLocation getElementsByTagName "current_conditions"]
		foreach child [$currentInformationNode childNodes] {
			dict set returnDict [$child nodeName] [$child getAttribute "data"]	
		}
		puts $returnDict
	}

	proc getWeatherXmlForLocation {} {
		set invalidWeather 1

		while {$invalidWeather} {
			set url [getNextUrl]
			set token [::http::geturl $url]
			set data [::http::data $token]
			::http::cleanup $token

			set doc [dom parse $data]	
			if {[$doc getElementsByTagName "problem_cause"] eq ""} {
				set invalidWeather 0
			}
		}

		return $doc
	}

	proc setLocationData {country state city zipcode} {
		variable sys
		set sys(location,country) $country
		set sys(location,state) $state
		set sys(location,city) $city
		set sys(location,zipcode) $zipcode
	}

	proc getNextFormat {} {
		variable sys
		set ret ""
		switch $sys(urlFormat) {
			0 { set ret "$sys(location,zipcode),$sys(location,country)" }
			1 { set ret "$sys(location,state),$sys(location,zipcode)" }
			2 { set ret "$sys(location,city),$sys(location,state)" }
			3 { set ret "$sys(location,city),$sys(location,country)" }
		}
		incr sys(urlFormat)
		return $ret
	}

	proc getNextUrl {} {
		variable sys
		return "$sys(url)[getNextFormat]"
	}
}

