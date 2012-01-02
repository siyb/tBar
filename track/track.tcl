#!/usr/bin/env tclsh
package require ncgi
::ncgi::parse
puts [::ncgi::nvlist]
