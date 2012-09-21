package provide yahooweather 1.0

package require http
package require tdom

namespace eval geekosphere::yahooweather {
	namespace import ::tcl::mathop::*
	namespace import ::tcl::mathfunc::*

	variable sys
	set sys(url) "http://query.yahooapis.com/v1/public/yql"
	set sys(imageBaseUrl) "http://l.yimg.com/a/i/us/we/52/"

	set sys(location,country) ""
	set sys(location,city) ""

	proc getCurrentCondition {weatherXmlForLocation} {
		set currentWeatherNode [$weatherXmlForLocation getElementsByTagName "yweather:condition"]
		set temperatureF [$currentWeatherNode getAttribute "temp"]
		set temperatureC [expr (${temperatureF}.0 - 32.0) * (5.0/9.0)]
		
		dict set ret "temp_c" [round $temperatureC]
		dict set ret "temp_f" $temperatureF
		dict set ret "icon" [getImageUrlForCurrentWeather $weatherXmlForLocation]
		
		return $ret
	}
	
	proc getImageUrlForCurrentWeather {weatherXmlForLocation} {
		return  [getImageUrlByCode [[$weatherXmlForLocation getElementsByTagName "yweather:condition"] getAttribute "code"]]
	}
	
	proc getImageUrlByCode {code} {
		variable sys
		return $sys(imageBaseUrl)${code}.gif
	}

	proc getWeatherForecasts {weatherXmlForLocation} {
		set ret [list]
		foreach forecast [$weatherXmlForLocation getElementsByTagName "yweather:forecast"] {
			dict set tmp day_of_week [$forecast getAttribute "day"]
			dict set tmp icon [getImageUrlByCode [$forecast getAttribute "code"]]
			dict set tmp high [$forecast getAttribute "high"]
			dict set tmp low [$forecast getAttribute "low"]
			lappend ret $tmp
		}
		return $ret
	}

	proc getWeatherXmlForLocation {} {
		variable sys
		puts [geekosphere::yahooweather::YQL::getCurrentWeatherForLocationQuery $sys(location,country) $sys(location,city)]]]
		set data [::http::data [set token [::http::geturl $sys(url) -query [geekosphere::yahooweather::YQL::getCurrentWeatherForLocationQuery $sys(location,country) $sys(location,city)]]]]
		::http::cleanup $token
		return [dom parse $data]
	}

	proc setLocationData {country state city zipcode} {
		variable sys
		set sys(location,country) $country
		set sys(location,city) $city
	}
	
	namespace eval geekosphere::yahooweather::YQL {
		proc getCurrentWeatherForLocationQuery {country city} {
			return [::http::formatQuery "q" "select * from weather.forecast where location in (select id from weather.search where query=\"${country}, ${city}\")" "format" "xml" "env" "store://datatables.org/alltableswithkeys"]
		 }
		
	}
	namespace export setLocationData getWeatherXmlForLocation getCurrentCondition getWeatherForecasts
}