#
# THIS PACKAGE IS OBSOLETE SINCE GOOGLE DISABLED THE WEATHER API!
#
package provide googleweather 1.0

catch { namespace import ::geekopshere::util::logger::* }
namespace eval geekosphere::googleweather {
	initLogger

	variable sys
	set sys(url) "http://www.google.com/ig/api?weather="

	set sys(urlFormat) 0

	set sys(location,country) ""
	set sys(location,state) ""
	set sys(location,city) ""
	set sys(location,zipcode) ""

	proc getCurrentCondition {weatherXmlForLocation} {
		if {$weatherXmlForLocation == -1} { return -1 }
		set currentInformationNode [$weatherXmlForLocation getElementsByTagName "current_conditions"]
		set returnDict [getDataFromNode $currentInformationNode]
		return $returnDict
	}

	proc getWeatherForecasts {weatherXmlForLocation} {
		if {$weatherXmlForLocation == -1} { return -1 }
		set retList [list]
		set forecastNodes [$weatherXmlForLocation getElementsByTagName "forecast_conditions"]
		foreach forecast $forecastNodes {
			set forecastDict [getDataFromNode $forecast]
			lappend retList $forecastDict
		}
		return $retList
	}

	proc getDataFromNode {node} {
		foreach child [$node childNodes] {
			set nodeName [$child nodeName]
			set data [$child getAttribute "data"]
			if {$nodeName eq "icon"} {
				set data "http://www.google.com${data}"
			}
			dict set returnDict $nodeName $data
		}
		return $returnDict
	}

	proc getWeatherXmlForLocation {} {
		variable sys
		set invalidWeather 1

		while {$invalidWeather} {
			set url [getNextUrl]
			if {$url != -1} {
				log "INFO" "Getting weather data from $url"
				set token [::http::geturl $url -timeout 2000]
				set data [::http::data $token]
				log "INFO" "Data: $data"
				::http::cleanup $token

				set doc [dom parse $data]	
				if {[$doc getElementsByTagName "problem_cause"] eq ""} {
					set invalidWeather 0
					set sys(urlFormat) 0
				}
			} else {
				return -1	
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
		set ret ","
		switch $sys(urlFormat) {
			0 { set ret "$sys(location,zipcode),$sys(location,country)" }
			1 { set ret "$sys(location,state),$sys(location,zipcode)" }
			2 { set ret "$sys(location,city),$sys(location,state)" }
			3 { set ret "$sys(location,city),$sys(location,country)" }
			default { return -1 }
		}
		incr sys(urlFormat)
		return $ret
	}

	proc getNextUrl {} {
		variable sys
		set nextFormat [getNextFormat]
		if {$nextFormat == -1} {
			log "ERROR" "The data specified to the weather API does not return any results"	
			return -1
		} else {
			return "$sys(url)${nextFormat}"
		}
	}

	namespace export setLocationData getWeatherXmlForLocation getCurrentCondition getWeatherForecasts
}

