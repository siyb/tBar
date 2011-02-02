# 
# General settings
#

# the color of the bar
setBarColor black

# the color of the text displayed in the bar
setTextColor white

# the font to be used in all widgets, use "font families"
# to get a list of valid font
setFontName "DejaVu Sans Mono"

# the fontsize
setFontSize 10

# should the font be bold? Valid options: bold / normal
setFontBold bold

# color when hovering over certain objects
setHoverColor blue

# color for clicked (marked) widgets
setClickedColor red

# the width of the bar in pixels
setWidth 1400

# the height of the bar in pixels
setHeight 20

# the X position of the bar on the screen
setXposition 470

# the Y position of the bar on the screen
setYposition 1030

# write a bugreport if an error is encountered, 1 to turn this feature on
# 0 to disable it. 1 is recommended
writeBugreport 1

# kill tbar if an error is encounterd, 1 to turn this feature on
# 0 to disable it. 0 is recommended for productive use
setKillOnError 0

# alternativly to using setYposition, setXposition
# and setWidth you may use positionBar top/bottom
# which will position the bar along the top or the
# bottom of the screen, covering the total width.
positionBar top

# widget alignment, might be left or right
alignWidgets right


# set loglevel for application, from sorted from least to most verbose.
# defaults to "DEBUG" if not specified
# "FATAL" 
# "ERROR" 
# "WARNING" 
# "INFO" 
# "DEBUG" 
# "TRACE" 
setLogLevel "DEBUG"

#
# Widgets
#
# Widgets will be loaded in the order specified here and will
# appear according to alignWidgets in the bar. The first parameter is the widget to load,
# The second parameter is the name you want to identify this certain widget by. 
# You can use this identifier to add events to the widgets, which can be used to execute commands.
# The third parameter is the update interval in seconds. If the interval is > 0, updates
# will be made every $interval seconds. The fourth parameter is a list of options and
# corresponding values, the options are explained in the comments.
#
# 	addWidgetToBar <widgetName> <name> <updateInterval> <optionList>
#
# You might have notices, that not all options of the widgets are supplied
# here by default. This is due to the widget creation code, that will use some
# of the global settings (like setBarColor, setTextColor, setHoverColor and setClickedColor)
# to create the widgets, so that your theme looks consistent. You may still change the colors
# on a per widget basis though.
#
# If you wish to add custom events to your widgets, you may use addEventTo:
#
#	addEventTo <widgetName> <event> <command>
#
# widgetName is the name of the widget as specified in your addWidgetToBar line, event is
# the event that triggers the command. The command is the potion that will be executed.
# Command can be any valid tcl command. If you use exec to spawn a new process, please
# remember to move the process to the background, if you don't tbar will be non responsive
# for the time the new process is running!
#
# The following event will open urxvt containing running htop when cpu1 widget is leftclicked:
#
#	addEventTo cpu1 <Button-1> exec /usr/bin/urxvt -e htop &
#

# Notification on customizable events
#
# -fg / -foreground - the text color
# -bg / -background - the background color
# -notifyAt - the expression which will be evaluated in order to
#		determine if a notification should be send. If the expression
#		is not true any more, image and text will be removed from the
#		notification area
# -image - the image to be displayed in the widget once an event occurs
# -imageDimensions - the dimension of the image, will be resized
#		must be given in the form heightXwidth, eg 10X10
# -text - the text to be displayed in the widget once an event occurs
#		will be overridden by the -image option
# -width - the width of the widget (use with caution)
# -height - the height of the widget (use with caution)
#
#addWidgetToBar notify notify1 1 -image "/home/user/someimage" -imageDimensions 10X10 -notifyAt {[file exists "/home/user/somefile"]}
#addText " | " "red"

# Displays the battery status.
#
# -fg / -foreground - the text color
# -bg / -background - the background color
# -warnAt - will warn the user if N percent battery charge is reached
# -battery - specify the battery, e.g. BAT0, only use this parameter if automatic determination fails!
# -lc / -lowColor - the color to be used when battery is low
# -mc / -mediumColor - the color to be used when battery is neither low nor high
# -hc / -highColor - the color to be used when battery is high
# -notifyFullyCharged - must be 0 or 1, if set to 1, the widget will notify the user when the battery is fully charged
# -showChargeStatus - must be 0 or 1, if set to 1, the widget will display a + or a - depending on the charge status of the battery
# -batteryChargeSymbolColor - the color of the charge symbol, will only take effect if -showChargeStatus is 1
# -height - height of the widget
# -width - width of the widget
#addWidgetToBar battery battery1 1 -warnAt 5 -lc "red" -hc "green" -mc "yellow" -notifyFullyCharged 1
#addText " | " "red"

# Displays the time
#
# -fg / -foreground - the text color
# -bg / -background - the background color
# -format - the time format displayed in the widget
# -hovercolor - calendar widget, hovercolor for days 
# -clickedcolor - calendar widget, clickedcolor
# -todaycolor - calendar widget, the color that will mark the current day
# -cachedate - if set to 1, the calendar will remember month and year you
#		navigated to.
# -command - when the calendar is opened, the output of -command will be
#		used instead of the native widget, e.g:
#
#			addWidgetToBar clock 1 -command [list exec cal]
# -ical - enable ical support (1)
#
addWidgetToBar clock clock1 1 -cachedate 1 -ical 1
addText " | " "red"


# An interface to music players, need to be console controllable
#
# -fg / -foreground - the textcolor
# -bg / -background - the background color
# -height - adjust the height of the widget (buttons)
# -width - adjust the width of the widgets
# -bindplay - a list of tcl commands executed when Button-1 (mouse1) is invoked on play
# -bindpause - a list of tcl commands executed when Button-1 (mouse1) is invoked on pause
# -bindstop - a list of tcl commands executed when Button-1 (mouse1) is invoked on stop
# -bindupdate - a list of tcl commands executed when an update is made, the output of the command
#		will be displayed in the widget
#addWidgetToBar player player1 1
#addText " | " "red"

# Displays network information
#
# -fg / -foreground - the text color
# -bg / -background - the background color
# -device - the device to be monitored
# -updateinterval - the interval in which the 
#		widget receives updates (needs to be the same 
#		as the update interval specified as second parameter, 
#		in order to give correct results)
# -additionalDevices - accepts a tcl list in the form {device1 device2 etc} or [list device1 device2 etc].
# 		May contain the device specified by -device. If this parameter is specified and the list
# 		is not empty, clicking on the network widget will cause a window to appear, which contains
# 		stats of the devices specified. 
addWidgetToBar network network1 1 -device eth0 -updateinterval 1 -additionalDevices [list eth0 eth1]
addText " | " "red"

# Displays memory and swap information
#
# -fg / -foreground - the text color
# -bg / -background - the backgroundcolor
# -bc - status bar character that represents 10% memory
# -gc / -graphicscolor - the color of the graph
# -showwhat - if showwhat is 0, used memory will be displayed,
#		if showwhat is 1, free memory will be displayed
# -noswap - will prevent the swappart of the widget to be diplayed (memory only)
#		setting this to 1 will disable swap
#
addWidgetToBar memory memory1 5 -gc blue -bc | -showwhat 0
addText " | " "red"

# Cpu information
#
# Use an interval >= 1 for this widget!
#
# -fg / -foreground - the text color
# -bg / -background - the background color
# -lc / -loadcolor - the color of the graph displaying the current load
# -device - the device to be monitored by the widget
# -width - the width of the widget (use with caution)
# -height - the height of the widget (use with caution)
#
# The following options can be left out (meaning that the wigdets will not
# be drawn (same as setting them to 0) or they can be set to 1 in which case
# they will be drawn.
#
# -showTemperature - shows temperature
# -showMhz - show cpu mhz
# -showCache - show cpu cache
# -showLoad - show cpu load
# -showTotalLoad - if this option is enabled, the load displayed by the widget
# 		represents the load of the complete system (all cpus), rather than
#		the load of the device specified by the -device option.
# -useSpeedstep - if this option is enabled and your kernel configuration / hw
#		allows speedstepping, the cup widget will utilize speedstepping to
#		obtain realtime cpu statistics and display you to them on demand
#
addWidgetToBar cpu cpu1 1 -loadcolor blue -device 0 -showLoad 1 -showTotalLoad 1 -useSpeedstep 1
#addEventTo cpu1 <Button-1> exec /usr/bin/urxvt -e htop &

# Display any text in a widget, for simple stuff use the addText convenience
# procedure, which creates a pre defined text widget.
#
# -fg / -foreground - the textcolor
# -bg / -background - the background color
# -text - the text to be displayed
# -width - the width of the widget in pixels
# -textvariable - a variable whose text will be displayed in the widget,
#		if the variable gets changed, the text will be updated
# -command - a command whose output will be directed to the widget
#		every $interval seconds
#
#addWidgetToBar text text1 1 -command [list exec uptime]

# If you are using i3, you can use this widget to manage your workspaces
#
# -fg / -foreground - the textcolor
# -bg / -background - the background color
# -focuscolor - the color to be used to mark a focussed workspace
# -urgentcolor - the color to be used to mark a workspace with an urgent event waiting
# -rolloverfontcolor - color to be displayed when the mouse cursor enters a workspace's box
# -rolloverbackgroundcolor - color font color to be used when mouse cursor enters a workspace's box
# -side use this parameter to position the bar on a certain side, may be "left" or "right"
#addWidgetToBar i3_workspace i3_workspace1 0
