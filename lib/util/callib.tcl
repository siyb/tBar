# Taken from: http://wiki.tcl.tk/13497
 package provide callib 0.3

 package require util

 proc calwid {args} {
 ##############################################
 # provides api for creating calendar widgets #
 ##############################################
   # creation of the widget
   set newWidget [ eval callib::MakecalendarWid $args]

   # create body for the new widget proc
   set newCmd [format {return [namespace eval %s %s %s $args]} \
                                             callib     \
                                             calproc    \
                                             $newWidget ]
   # declare new proc to be called when the widget is accessed
   proc $newWidget {args} $newCmd

   return $newWidget
 } ;# END calwid

 namespace eval callib {
    # config data for every calwid widget
    variable calState

    set calState(unique) 0

    proc MakecalendarWid {args} {
    ##################################
    # procedure to create a calendar #
    ##################################
        variable calState

        #make unique name per default
        set holder .calwid_$calState(unique)
        incr calState(unique)
        #if a window name was given on the command line then use it
        #overwriting the already computed name
        if {[string first "." [lindex $args 0]] == 0} {
            # put the wanted name in holder
            set holder [lindex $args 0] 
            # remove the name from args
            set args [lreplace $args 0 0]
          };# END window path given

        #make defaults for the command line args
        #year
        set calState($holder.year) [clock format [clock scan now] -format "%Y"]
        #month
        set mon_num [clock format [clock scan now] -format "%m"]
        #month starts with 0, can be interpreted as octal ->remove leading 0
        set mon_num [string trimleft $mon_num "0"]
        set calState($holder.month) $mon_num 
        #week starts on sunday in the us and on monday in germany
        set calState($holder.startsunday) 0
        #font defaults
        set calState($holder.font) [list Lucidatypewriter 12 normal]
        #day names, change the defaults to the language needed
        set calState($holder.daynames) [list "So" "Mo" "Di" "Mi" "Do" "Fr" "Sa"]
        #day font
        set calState($holder.dayfont) [list Lucidatypewriter 12 bold]
        #command registered as callback
        set calState($holder.callback) ""
        # marking list for days, a mark is a list containing a date
        # a mark priority and a mark color, if one day has multiple marks
        # the color of the highest priority is shown, if balloons are enabled
        # then all the marks texts in descending prio order are shown.
        # the list is {day month year prio color label}
        set calState($holder.mark) {}
        # this list contains the marks for the shown month
        set calState($holder.shownmarks) {}
        # last clicked gets row col address of the last clicked button
        set calState($holder.clicked) {}
        # last clicked gets the color of clicked
        set calState($holder.clickedcolor) "yellow"
        # default background goes here, as a default rootwindows background
        # is used
        set calState($holder.background) [. cget -background]
        # the default active background goes here, white
        set calState($holder.activebackground) "white"
        # progcallback: if set to 1, setting clicked will invoke callback
        #               if set to 0, setting clicked will not invoke callback
        # defaults to 1
        set calState($holder.progcallback) 1
        # balloons containing the mark texts, 1 enabled, 0 disables
        set calState($holder.balloon)      1
        # set the delay for the balloon here
        set calState($holder.delay)     1000
        # set the relief 
        set calState($holder.relief)    groove
        # set the relief 
        set calState($holder.foreground)    black

        # check whether options are valid
        foreach {opt val} $args {
            # get rid of leading -
            set option [string range $opt 1 end] 
            if {![info exists calState($holder.$option)]} {
                # create oklist containing the possible commands
                regsub -all "$holder." [array names calState $holder.*] \
                            ""         oklist

                error "Bad Option, '$option'\n Valid options are $oklist"
              };# END: if option not in the calendar state array
            set calState($holder.$option) $val  
          };# END: foreach option value pair

        # make a frame to hold it all. Declare the class as being Calendar
        frame $holder -class Calendar 
        # make the frames innards
        Draw $holder
        # rename the frame to give the widget the name $holder
        uplevel #0 rename $holder $holder.fr
        #call the update procedure to use configuration options given at start
        update_cal  $holder
        # clean up after destruction of the widget
        # TODO unset the associated array elements 
        # TODO implement a cleanup proc to take care of cleaning up
        bind $holder <Destroy> "+ rename $holder {}"
        # return the name of the new widget
        return $holder
      };# END MakecalendarWid
    
    proc Draw {parent} {
    ###########################################################
    # this proc takes care of drawing and packing the widgets #      
    ###########################################################
        variable calState

        # make the weekday list
        set weekdays $calState($parent.daynames)
        if {$calState($parent.startsunday) != 1} {
            set weekdays [roll_left $weekdays]
          };# END if not start on sunday -> start on monday 
        # make labels for the days header
        set colcount 0
        foreach day $weekdays {
            set daylabel $parent.$colcount
            label $daylabel 
            grid  $daylabel  -row 1 -column $colcount -ipadx 0 -ipady 0
            incr colcount
          };#END: foreach day in weekday 
        # get monthlist according to startsunday variable
        set month $calState($parent.month)
        set year  $calState($parent.year)
        set monthlist [cal_list_month $month \
                                      $year  \
                                      $calState($parent.startsunday) ]
        # make the buttons for the calendar, buttons needed 
        # as there will be commands associated with them
        # was button, switched to labels bacause buttons look 
        # ugly under Aqua, callbacks & activebackground implemented 
        # via bind
        for {set row 0} {$row<6} {incr row} {
          for {set col 0} {$col<7} {incr col} {
              label $parent.$col$row -highlightthickness 2  
              grid $parent.$col$row -padx 0 -pady 0 -ipadx 0 -ipady 0 \
                                    -row [expr {$row+2}] -column $col 
            };#END: col
          };#END: row
      };# END: draw the widgets

    proc callback {parent col row} {
    ###############################################################
    # this procedure gets called whenever a day button is pressed #
    ###############################################################
        variable calState

        # cleanup previously clicked
        set old_col [lindex $calState($parent.clicked) 0]  
        set old_row [lindex $calState($parent.clicked) 1]  

        if {$old_row != ""} {
            set button_name $parent.$old_col$old_row
            $button_name configure -background $calState($parent.background)
          };# END: there was a clicked button
        # change the clicked button appropriately
        set calState($parent.clicked) [list $col $row]
        set button_name $parent.$col$row
        $button_name configure -background $calState($parent.clickedcolor)
        $button_name configure -background $calState($parent.clickedcolor)
        # get the daynames from the state array
        set namelist $calState($parent.daynames)
        # if start on monday roll the list 
        if {$calState($parent.startsunday) != 1} {
            set namelist [roll_left $namelist]
          }
        # make the arguments for the user defined callback procedure  
        set callargs [list $calState($parent.year)                         \
                           $calState($parent.month)                        \
                           [string trimleft [$parent.$col$row cget -text]] \
                           [lrange $namelist $col $col]                    \
                           $col                                            \
                           $row]
                           
        # procedure name                   
        set procname $calState($parent.callback)
        # if there is something registered as callback, call it
        if {$procname != ""} {
            eval $procname $callargs
          }
      }

    proc update_cal {parent} {
    ##################################################################
    # this proc updates the calendar shown according to the contents #
    # of the calState array                                          #
    ##################################################################
        variable calState

        # set the frame color to the background
        $parent.fr configure -background $calState($parent.background)
        # make the weekday list
        set weekdays $calState($parent.daynames)
        if {$calState($parent.startsunday) != 1} {
            set weekdays [roll_left $weekdays]
          };# END if not start on sunday -> start on monday 
        # update labels for the days header
        set colcount 0
        foreach day $weekdays {
            set daylabel $parent.$colcount
            set day [string range $day 0 1]
            $daylabel configure -text $day -width 2                       \
                                -font $calState($parent.dayfont)          \
                                -foreground $calState($parent.foreground) \
                                -background $calState($parent.background)
            incr colcount
          };#END: foreach day in weekday 

        # get monthlist according to startsunday variable
        set month $calState($parent.month)
        set year  $calState($parent.year)
        set monthlist [cal_list_month $month \
                                      $year  \
                                      $calState($parent.startsunday)]
        # make an array with the day as index and the buttons coords as value
        # will be used while processing the marked days
        # first delete the array
        catch {unset index_arr}
        # fill buttons with the stuff
        for {set row 0} {$row<6} {incr row} {
          for {set col 0} {$col<7} {incr col} {
              set text  [lindex $monthlist [expr {7*$row+$col}] ]
              set index_arr($text) $col$row
              # set default values, change them if day field is empty
              set reliefval $calState($parent.relief)
              set stateval  normal
              bind $parent.$col$row <Any-Enter> [list callib::enter_proc %W] 
              bind $parent.$col$row <Any-Leave> [list callib::leave_proc %W] 
              bind $parent.$col$row <Button-1>  [list callib::callback \
                                                       $parent         \
                                                       $col            \
                                                       $row]
              if {$text == ""} {
                  set reliefval flat
                  set stateval  disabled
                  bind $parent.$col$row <Any-Enter> {}
                  bind $parent.$col$row <Any-Leave> {}
                  bind $parent.$col$row <Button-1>  {}
                };# END: if dayfield is empty
              # reconfigure the button 
              $parent.$col$row configure -relief $reliefval -state $stateval \
                                         -borderwidth 2                      \
                                         -width 2                            \
                                         -background                         \
                                           $calState($parent.background)     \
                                         -highlightbackground                \
                                           $calState($parent.background)     \
                                         -font $calState($parent.font)       \
                                         -text [format "%2s" $text]          \
                                         -justify center                     \
                                         -foreground                         \
                                           $calState($parent.foreground)
            };#END: col
          };#END: row
        # check if there is a clicked day & update the color according to 
        # calstate array
        set col [lindex $calState($parent.clicked) 0]  
        set row [lindex $calState($parent.clicked) 1]  
        if {($row != "") && ($col != "")} {
            $parent.$col$row configure -background \
                                         $calState($parent.clickedcolor)
          }
        # check if there are days in the marked list that are displayed
        # right now and mark them
        # put the needed part of mark list into the shownmarks list
        set calState($parent.shownmarks) {}
        foreach Mlist $calState($parent.mark) {
            foreach {Mday Mmonth Myear Mpri Mcol Mlabel} $Mlist {}
            if {$Myear == $calState($parent.year)} {
                if {$Mmonth == $calState($parent.month)} {
                    lappend calState($parent.shownmarks) $Mlist
                  }
              }
          }
        # sort the array in ascending order of prio
        # so that highest prio is at the end
        set calState($parent.shownmarks) \
          [lsort -index 3 -integer $calState($parent.shownmarks)] 
        # start @ beginnig of array and reconfigure the buttons the 
        # last marks will be of highest prio & will determine the marking color
        # automatically. Not blazingly fast, might tune later
        foreach Mlist $calState($parent.shownmarks) {
            # month & year are matching the shown ones, get the day
            foreach {Mday Mmonth Myear Mpri Mcol Mlabel} $Mlist {}
            $parent.$index_arr($Mday) configure -highlightbackground $Mcol 
          }
        # delete the array  
        catch {unset index_arr}
        # return used here to avoid returning the value of the catch
        return 
      };# END update_cal

    proc enter_proc {wname} {
    ###################################
    # gets called at each enter event #
    ###################################
        variable calState

        # get parents name
        set parent [winfo parent $wname]
        # set active color
        $wname configure -background $calState($parent.activebackground)
        # trigger the balloon
	after $calState($parent.delay) [list callib::balloon_show $wname] 
      }

    proc leave_proc {wname} {
    ###################################
    # gets called at each leave event #
    ###################################
        variable calState

        # get parents name
        set parent [winfo parent $wname]
        # set inactive color
        $wname configure -background $calState($parent.background)
        # check if the label was "clicked" and set the color to clickedcolor
        set col [lindex $calState($parent.clicked) 0]  
        set row [lindex $calState($parent.clicked) 1]  
        if {$row != ""} {
            set label_name $parent.$col$row
            $label_name configure -background $calState($parent.clickedcolor)
          };# END: there was a clicked button
        # close the balloon
        balloon_dn $wname 
      }

    proc balloon_show {wname} {
    #######################################
    # triggers a balloon help like window #
    #######################################
        variable calState

        # get parents name
        set parent [winfo parent $wname]
        # in case the balloons  are disabled do nothing
        if {$calState($parent.balloon) == 0} return
        # in case we already left the widget do nothing
        set currentwin [eval winfo containing [winfo pointerxy .]]
        if {![string match $currentwin $wname]} return
        # make a string with the marks of the date shown by the requester
        set day [string trim [$wname cget -text]]
        set message_str ""
        foreach Mlist $calState($parent.shownmarks) {
            foreach {Mday Mmonth Myear Mpri Mcol Mlabel} $Mlist {}
            if {($Mday == $day)} {append message_str "$Mpri $Mlabel\n"}
          }
        set message_str [string trim $message_str]
        # if there are no marks for requesters widget return
        if {![string length $message_str]} return
        # create a top level window
        set top $parent.balloon
        catch {destroy $top}
        toplevel $top -borderwidth 1 -background black -relief flat
	
        wm overrideredirect $top 1
        # create the message widget
        message $top.msg -text $message_str  -width 3i\
                         -font $calState($parent.font)
	# TODO: allow different color scheme (yellow is just damn ugly)
                        # -background yellow -foreground darkblue
        pack $top.msg
        # get the geometry data of the requester
        set wmx [expr [winfo rootx $wname]+[winfo width  $wname]]
        set wmy [expr [winfo rooty $wname]+[winfo height $wname]]
        wm geometry $top \
          [winfo reqwidth $top.msg]x[winfo reqheight $top.msg]+$wmx+$wmy
        # raise so that win is really on top
        raise $top
		# position window relative to window
	positionWindowRelativly $top $wname
      };# end balloon_show 

    proc balloon_dn {wname} {
    ###############################
    # makes the balloon disappear #
    ###############################
        variable calState

        # get parents name
        set parent [winfo parent $wname]
        # in case the balloons  are disabled do nothing
        if {$calState($parent.balloon) == 0} return
        # destroy the help balloon
        catch {destroy $parent.balloon}
      };# end balloon_dn

    proc calproc {parent args} {
    ################################################################
    # This proc takes care of all the configuration subcommands of #
    # the calendar widget                                          #
    ################################################################
        variable calState

        # make a list of allowed commands
        # new commands should be dropped here & processed in the switch 
        # statement along with the possible subcommands
        set commList [list "nextmonth" "prevmonth" \
                           "nextyear"  "prevyear"  \
                           "configure"]
        # extract the first word in args, this must be in the commList
        set command [lindex $args 0]
        if {[lsearch -exact $commList $command] == -1} {
            error "unknown command for $parent, possible command(s):\n\
                   $commList"
          };# END: check whether command is known to widget

        # remove the parent name from the args list
        set  args [lreplace $args 0 0]

        switch -- $command {
            "configure" {
                # if there are no arguments to configure
                # then return a list with all the configuration
                if {$args == ""} {
                    set optlist [array get calState "$parent.*"]
                    set returnlist ""
                    foreach {opt val} $optlist {
                        regsub "$parent." $opt "" opt
                        # shownmarks is a private field, so leave it out
                        if {$opt != "shownmarks"} {
                            lappend returnlist [list $opt $val]
                          }  
                      }
                    return $returnlist  
                  };# END: if no args for configure
                foreach {opt val} $args {
                    switch -- $opt {
                        "-font" {
                            if {$val == ""} {
                                return $calState($parent.font)
                              };# END: if no font specified
                            # might want to check whether font is available  
                            set calState($parent.font) $val
                          }
                        "-background" {
                            if {$val == ""} {
                                return $calState($parent.background)
                              };# END: if no color specified
                            set er [catch {label .tmp -background $val} result]
                            destroy .tmp   
                            if {$er} {
                                error "Problem with the color value\n\
                                      color is \"$val\""
                                return
                              }
                            set calState($parent.background) $val
                          }
                        "-foreground" {
                            if {$val == ""} {
                                return $calState($parent.foreground)
                              };# END: if no color specified
                            set er [catch {label .tmp -foreground $val} result]
                            destroy .tmp   
                            if {$er} {
                                error "Problem with the color value\n\
                                      color is \"$val\""
                                return
                              }
                            set calState($parent.foreground) $val
                          }
                        "-activebackground" {
                            if {$val == ""} {
                                return $calState($parent.activebackground)
                              };# END: if no color specified
                            set er [catch {label .tmp -background $val} result]
                            destroy .tmp   
                            if {$er} {
                                error "Problem with the color value\n\
                                      color is \"$val\""
                                return
                              }
                            set calState($parent.activebackground) $val
                          }
                        "-dayfont" {
                            if {$val == ""} {
                                return $calState($parent.dayfont)
                              };# END: if no dayfont specified
                            set calState($parent.dayfont) $val
                          }
                        "-clickedcolor" {
                            if {$val == ""} {
                                return $calState($parent.clickedcolor)
                              };# END: if no clicked color specified
                            set er [catch {label .tmp -background $val} result]
                            destroy .tmp   
                            if {$er} {
                                error "Problem with the color value\n\
                                      color is \"$val\""
                                return
                              }
                            set calState($parent.clickedcolor) $val
                          }
                        "-relief" {
                            if {$val == ""} {
                                return $calState($parent.relief)
                              };# END: if no relief specified
                            set er [catch {label .tmp -relief $val} result]
                            destroy .tmp   
                            if {$er} {
                                error "Problem with the relief value\n\
                                      relief is \"$val\""
                                return
                              }
                            set calState($parent.relief) $val
                          }
                        "-startsunday" {
                            if {$val == ""} {
                                return $calState($parent.startsunday)
                              };# END:  if no value for start sunday
                            set calState($parent.startsunday) 0  
                            if {$val == "1"} {
                                set calState($parent.startsunday) 1
                              } 
                            # get rid of clicked state as calendar is going
                            # to change layout
                            set calState($parent.clicked) {}  
                          }
                        "-balloon" {
                            if {$val == ""} {
                                return $calState($parent.balloon)
                              };# END:  if no value for balloon
                            set calState($parent.balloon) 0  
                            if {$val == "1"} {
                                set calState($parent.balloon) 1
                              } 
                          }
                        "-delay" {
                            if {$val == ""} {
                                return $calState($parent.delay)
                              };# END:  if no value for balloon delay
                            # delay check: must be integer
                            set er [catch {incr val 0}]
                            if {$er} {
                                error "Problem with the delay value\n\
                                      most likely a non integer value \n\
                                      given delay is \"$val\""
                                return
                              }
                            if {$val < 0} {
                                error "Problem with negative delay value\n\
                                      given delay is \"$val\""
                                return
                              }
                            set calState($parent.delay) $val 
                          }
                        "-progcallback" {
                            if {$val == ""} {
                                return $calState($parent.progcallback)
                              };# END:  if no value for progcallback
                            set calState($parent.progcallback) 0  
                            if {$val == "1"} {
                                set calState($parent.progcallback) 1
                              } 
                          }
                        "-mark" {
                            if {$val == ""} {
                                return $calState($parent.mark)
                              };# END: if no marking list given
                            if {[llength $val] != 6} {
                                error "The mark list must have 6 elements\n\
                                       a mark list should be like this:  \n\
                                       {day month year prio color label}"
                              };# END: if mark list not properly constructed
                            
                            # assign temp_vars  
                            foreach {Mday Mmonth Myear Mpri Mcol Mlabel} $val {}
                            
                            # check the list fields for consistency  
                            # check the month
                            if {($Mmonth < 1) || ($Mmonth > 12)} {
                                error "Month out of range"
                                return
                              }
                            # check year and month, compute the number of days
                            # of the given month
                            set er [catch {cal_month_length $Mmonth $Myear} Ml]
                            if {$er} {
                                error "Problem computing month length,\n\
                                      year out of clock's range or erroneous\n\
                                      month value"
                                return
                              }
                            # day check
                            if {($Mday < 1) || ($Mday > $Ml)} {
                                error "Day of month out of range"
                                return
                              }
                            # prio check: must be integer
                            set er [catch {incr Mpri 0}]
                            if {$er} {
                                error "Problem with the priority value\n\
                                      most likely a non integer value \n\
                                      prio is \"$Mpri\""
				return
                              }
			    # TODO 1.x: this check takes a long time, disabled.
			    # Will need to find another way to do that
			    #
                            # check that color is acceptable
                            #set er [catch {label .tmp -background $Mcol} result]
                            #destroy .tmp   
                            #if {$er} {
                            #    error "Problem with the color value\n\
                            #          color is \"$Mcol\""
			    #   return
                            # }
                            # all consistency checks went OK
                            # append mark to mark list
                            lappend calState($parent.mark) $val
                          }
                        "-daynames" {
                            if {$val == ""} {
                                return $calState($parent.daynames)
                              };# END: if no list with daynames specified
                            if {[llength $val] != 7} {
                                error "The list given to -daynames must have\n\
                                       7  elements, [llength $val] elements \n\
                                       were specified in $val"
                              };# END: if list didn't have 7 elements
                            set calState($parent.daynames) $val  
                          }
                        "-clicked" {
                            if {$val == ""} {
                                return $calState($parent.clicked)
                              };# END: if no list with  calendar coordinates 
                            if {[llength $val] != 2} {
                                error "The list given to -clicked must have\n\
                                       2  elements, [llength $val] elements \n\
                                       were specified in $val"
                              };# END: if list didn't have 2 elements
                            set tmp_col [lindex $val 0]
                            set tmp_row [lindex $val 1]
                            if { ($tmp_col < 0) || ($tmp_col > 6)} {
                                error "column value for clicked cell invalid\n\
                                       0<= col < 7 allowed, given: $tmp_col"
                              };# END: if coord isn't in right range
                            if { ($tmp_row < 0) || ($tmp_row > 5)} {
                                error "row value for clicked cell invalid\n\
                                       0<= col < 5 allowed, given: $tmp_col"
                              };# END: if coord isn't in right range
                            set Cstate [$parent.$tmp_col$tmp_row cget -state]
                            if {$Cstate == "normal"} {              
                                set calState($parent.clicked) $val  
                                # call the callback as if the appropriate button
                                # was clicked. 
                                if {$calState($parent.progcallback)=="1"} {
                                    callback $parent $tmp_col $tmp_row   
                                  };# end: if programm callback enabled  
                              };# END: if cell is not disabled
                          }    
                        "-month" {
                            if {$val == ""} {
                                return $calState($parent.month)
                              };# END: if no month specified
                            if {($val > 0) && ($val < 13)} {
                                set calState($parent.month) $val
                              } else {
                                error "Month value must be between 1 and 12"
                              }
                            set calState($parent.clicked) {}  
                          }
                        "-year" {
                            if {$val == ""} {
                                return $calState($parent.year)
                              };# END: if no year specified
                            set calState($parent.year) $val
                            set calState($parent.clicked) {}  
                          }     
                        "-callback" {
                            if {$val == ""} {
                                return $calState($parent.callback)
                              };# END: if no year specified
                            set calState($parent.callback) $val
                          }     
                        default {
                            error "Bad option: $opt\n\
                                   allowed option(s) for configure are:    \n\
                                   -font -startsunday -daynames -month     \n\
                                   -year -dayfont -callback -clickedcolor  \n\
                                   -background -clicked -mark -balloon     \n\
                                   -progcallback -activebackground -delay  \n\
                                   -foreground" 
                          }
                      }
                  }
                update_cal $parent  
              }
            "nextmonth" {
                if {[llength $args]} {
                    error "nextmonth not allowed to have arguments"
                  };# END: check number of arguments error if != 0
                incr calState($parent.month)
                if {$calState($parent.month) == 13} {
                    set calState($parent.month) 1
                    incr calState($parent.year)
                  };# END: if month crossed year boundary to next year
                set calState($parent.clicked) {}  
                update_cal $parent  
                return [list $calState($parent.year) $calState($parent.month)]
              }
            "prevmonth" {
                if {[llength $args]} {
                    error "prevmonth not allowed to have arguments"
                  };# END: check number of arguments error if != 0
                incr calState($parent.month) -1
                if {$calState($parent.month) == 0} {
                    set calState($parent.month) 12
                    incr calState($parent.year) -1
                  };# END: if month crossed year boundary to previous year
                set calState($parent.clicked) {}  
                update_cal $parent  
                return [list $calState($parent.year) $calState($parent.month)]
              }
            "nextyear" {
                if {[llength $args]} {
                    error "nextyear not allowed to have arguments"
                  };# END: check number of arguments error if != 0
                incr calState($parent.year)
                set calState($parent.clicked) {}  
                update_cal $parent  
                return [list $calState($parent.year) $calState($parent.month)]
              }
            "prevyear" {
                if {[llength $args]} {
                    error "prevyear not allowed to have arguments"
                  };# END: check number of arguments error if != 0
                incr calState($parent.year) -1
                set calState($parent.clicked) {}  
                update_cal $parent  
                return [list $calState($parent.year) $calState($parent.month)]
              }   
            default {
                error "You should never have reached this point\n\
                       The state of the widget might be mangled\n\
                       Bailing out, bye\n"
              }
          };# END: switch -- $command
      };# END: calproc

 # utilities start here
 # anything needing calState does not belong below
    proc roll_left {listvar {rollby 1}} {
    ##############################################
    # helper function to roll a list to the left #
    ##############################################
        set newlist $listvar
        for {set counter 0} {$counter < $rollby} {incr counter} {
            set firstelem [lindex $newlist 0]
            set newlist   [lreplace $newlist 0 0]
            set newlist   [lappend newlist $firstelem]
          }
        return $newlist
      };# END roll_left

    proc cal_start_weekday { month year } {
    ############################################
    # returns the weekday as an ordinal number #
    # sunday is 0                              #
    ############################################
        # obvious, needed as a wrapper for future 
        # sophistication of the proc
        set startday [clock scan "$month/1/$year"]
        return [clock format $startday -format "%w"]
      };# END: cal_start_weekday

    proc cal_month_length { monthvar yearvar } {
    #################################
    # returns the length of a month #
    #################################
        # get clock ticks
        # make sure to stay in same month to stay in same year
        set startdate    [clock scan "$monthvar/1/$yearvar"]
        set enddate      [clock scan "+1 month" -base $startdate]
        set lastmonthday [clock scan "yesterday"  -base $enddate]

        # get day numbers from ticks
        set lastday      [clock format $lastmonthday -format "%d"]

        # get rid of leading zeroes as tcl interpret them as octal
        set lastday  [ string trimleft $lastday  "0"]

        # actually not needed (clock ... %d returns min. 01)
        # but keep sane state for the variables
        if {$lastday  == ""} {set lastday  "0"}
        # return
        return   $lastday 
      };# END: cal_month_length

    proc cal_build_month { month year } {
    ######################################################
    # returns a list of 35 elements containing the month #
    # start day of week is sunday by default             #
    ######################################################
        set startday [cal_start_weekday $month $year]
        set numdays  [cal_month_length  $month $year]

        # put month there
        for {set counter 1} {$counter <= $numdays} {incr counter} {
            set monthlist [lappend monthlist $counter]
          }
        # make empty preceeding days if needed
        if {$startday != 0} {
            for {set counter 0} {$counter < $startday} {incr counter} {
                set prelist [lappend prelist ""]
              }
            return [concat $prelist $monthlist]
          }

        return $monthlist
      };# END: cal_build_month

    #############################################################
    # return the monthlist with start either mondays or sundays #
    #############################################################
    proc cal_list_month { month year {startsunday 1}} {
        # get the default (start sunday) list
        set monthlist [cal_build_month $month $year ]

        if {$startsunday != 1} {
        # start week as in Europe
            set firstday [cal_start_weekday $month $year]
            if {$firstday == 0} {
                set monthlist [linsert $monthlist 0 {} {} {} {} {} {}]
              } else {
                set monthlist [roll_left $monthlist]
              }
          }

        return $monthlist
      };# END: cal_list_month

  };# END namespace callib