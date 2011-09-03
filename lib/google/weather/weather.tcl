package provide googleweather

namespace eval geekosphere::googleweather {
	variable sys
	set sys(url) "http://www.google.com/ig/api?weather="
	
	set sys(urlFormat) 0

	set sys(location,country) ""
	set sys(location,state) ""
	set sys(location,city) ""
	set sys(location,zipcode) ""

	proc setLocationData {country county city zipcode} {
		variable sys
		set sys(location,country) $country
		set sys(location,state) $state
		set sys(location,city) $city
		set sys(location,zipcode) $zipcode
	}

	proc getNextFormat {} {
		variable sys
		switch $sys(urlFormat {
			0 { return "$sys(location,zipcode),$sys(location,country)" }
			1 { return "$sys(location,state),$sys(location,zipcode)" }
			2 { return "$sys(location,city),$sys(location,state)" }
			3 { return "$sys(location,city),$sys(location,country)" }
		}
		incr sys(urlFormat)
	}

	proc getNextUrl {} {
		variable sys
		return "$sys(url)[getNextFormat]"
	}

}

