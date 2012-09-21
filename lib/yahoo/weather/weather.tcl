package provide yahooweather 1.0

package require http
package require tdom

namespace eval geekosphere::yahooweather {
	namespace import ::tcl::mathop::*
	namespace import ::tcl::mathfunc::*

	variable sys
	set sys(url) "http://query.yahooapis.com/v1/public/yql"

	set sys(location,country) ""
	set sys(location,city) ""

	proc getCurrentCondition {weatherXmlForLocation} {
		set currentWeatherNode [$weatherXmlForLocation getElementsByTagName "yweather:condition"]
		set temperatureF [$currentWeatherNode getAttribute "temp"]
		set temperatureC [expr (${temperatureF}.0 - 32.0) * (5.0/9.0)]
		
		dict set ret "temp_c" [round $temperatureC]
		dict set ret "temp_f" $temperatureF
		dict set ret "icon" [getImageUrl $weatherXmlForLocation]
		
		return $ret
	}
	
	proc getImageUrl {weatherXmlForLocation} {
		set discription [$weatherXmlForLocation getElementsByTagName "description"]
		set html [dom parse -html [[lindex $discription 1] asText]]
		set img [$html getElementsByTagName "img"]
		return [$img getAttribute "src"]
	}

	proc getWeatherForecasts {weatherXmlForLocation} {
	}

	proc getWeatherXmlForLocation {} {
		variable sys
		puts [geekosphere::yahooweather::YQL::getWeatherForeCastForLocationQuery $sys(location,country) $sys(location,city)]]]
		set data [::http::data [set token [::http::geturl $sys(url) -query [geekosphere::yahooweather::YQL::getWeatherForeCastForLocationQuery $sys(location,country) $sys(location,city)]]]]
		::http::cleanup $token
		puts $data
		return [dom parse $data]
	}

	proc setLocationData {country state city zipcode} {
		variable sys
		set sys(location,country) $country
		set sys(location,city) $city
	}
	
	namespace eval geekosphere::yahooweather::YQL {
		proc getWeatherForeCastForLocationQuery {country city} {
			return [::http::formatQuery "q" "select * from weather.forecast where location in (select id from weather.search where query=\"${country}, ${city}\")" "format" "xml" "env" "store://datatables.org/alltableswithkeys"]
		 }
		
	}
	namespace export setLocationData getWeatherXmlForLocation getCurrentCondition getWeatherForecasts
}

geekosphere::yahooweather::setLocationData "Austria" "" "Vienna" ""
geekosphere::yahooweather::getCurrentCondition [geekosphere::yahooweather::getWeatherXmlForLocation]