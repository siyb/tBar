package provide logger 1.0

namespace eval geekosphere::tbar::util::logger {

	#
	# LOGGER
	#

	# log levels
	dict append loggerSettings(levels) "FATAL" 5
	dict append loggerSettings(levels) "ERROR" 4
	dict append loggerSettings(levels) "WARNING" 3
	dict append loggerSettings(levels) "INFO" 2
	dict append loggerSettings(levels) "DEBUG" 1
	dict append loggerSettings(levels) "TRACE" 0

	# global loglevel
	set loggerSettings(globalLevel) "TRACE"

	# the global loglevel to be used
	proc setGlobalLogLevel {level} {
		variable loggerSettings
		set loggerSettings(globalLevel) $level
	}

	# Has to be called before the logger can be used in a namespace
	proc initLogger {} {
		variable loggerSettings
		set namespace [uplevel 1 { namespace current }];# the namespace in which the logger proc was called
		namespace upvar $namespace logger logger;# get the namespace specific vars (namespace that called the proc)
		if {![info exists logger(dolog)]} { set logger(dolog) 1 }
		if {![info exists logger(level)]} { set logger(level) $loggerSettings(globalLevel) }
		set userDir [file join $::env(HOME) .tbar]
		if {[file exists $userDir] && [file isdirectory $userDir]} {
			if {![info exists logger(log2file)]} { set logger(log2file) 1 }
			if {![info exists logger(logfile)]} { set logger(logfile) [file join $userDir "log"] }
		} else {
			set logger(log2file) 0
		}
		set logger(init) 1
	}

	# a simple logging proc. any namespace that wishes to use this proc
	# needs to call initLogger.
	proc log {level message} {
		set namespace [uplevel 1 { namespace current }];# the namespace in which the logger proc was called
		namespace upvar $namespace logger logger;# get the namespace specific vars (namespace that called the proc)

		if {![info exists logger(init)]} { error "Logger has not been initialized for namespace $namespace" }

		set mloglevel [getNumericLoglevel $level];# the level of the message
		set gloglevel [getNumericLoglevel $logger(level)];# the global log level
		if {$mloglevel < $gloglevel} { return };# check if message should be logged
		if {$logger(dolog)} {
			set uLevel [uplevel {info level}]
			if {$uLevel == 0} { set proc "" } else { set proc ::[lindex [info level $uLevel] 0] }
			set message "[clock format [clock seconds] -format "%+"] | $level | ${namespace}${proc}: ${message}"
			puts $message
			if {$logger(log2file)} {
				set fl [open $logger(logfile) a+]; puts $fl $message; close $fl
			}
		}
	}

	# returns numeric loglevel
	proc getNumericLoglevel {level} {
		variable loggerSettings
		if {![dict exists $loggerSettings(levels) $level]} { error "WARNING | Loglevel invalid! (${level})" }
		return [dict get $loggerSettings(levels) $level]
	}
	
	proc getLogLevel {} {
		variable loggerSettings
		return $loggerSettings(globalLevel)
	}

	namespace export log initLogger setGlobalLogLevel getLogLevel
}
