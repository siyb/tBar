package require api
namespace eval geekosphere::tbar::api::foo {
	proc init {} {
		return [geekosphere::api::autocreateProcList]
	}

	proc lol {a b} {
		puts "A: $a B: $b"
	}

	proc test {} {
		puts "This is a test"
	}

	proc h_thisProcWillNotBeExported {} {
		puts "Will be ignored"
	}

}
geekosphere::api::registerApi foo
geekosphere::api::useApi foo
geekosphere::api::call lol one two
geekosphere::api::call test
puts "EXPLORE: [geekosphere::api::explore]"
puts "EXPLORE APIS: [geekosphere::api::exploreApis]"
