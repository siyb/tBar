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

# alternativly to using setYposition, setXposition
# and setWidth you may use positionBar top/bottom
# which will position the bar along the top or the
# bottom of the screen, covering the total width.
positionBar top

# widget alignment, might be left or right
alignWidgets right

#
# Widgets
#
# Widgets will be loaded in the order specified here and will
# appear according to alignWidgets in the bar. The first parameter is the widget to load,
# the second parameter is the update interval in seconds. If the interval is > 0, updates
# will be made every $interval seconds. The third parameter is a list of options and
# corresponding values, the options are explained in the comments.
#
# 	addWidget <widgetName> <updateInterval> <optionList>
#
# You might have notices, that not all options of the widgets are supplied
# here by default. This is due to the widget creation code, that will use some
# of the global settings (like setBarColor, setTextColor, setHoverColor and setClickedColor)
# to create the widgets, so that your theme looks consistent. You may still change the colors
# on a per widget basis though.
#

# Displays the time
#
# -fg / -foreground - the text color
# -bg / -background - the background color
# -format - the time format displayed in the widget
# -hovercolor - calendar widget, hovercolor for days 
# -clickedcolor - calendar widget, clickedcolor
# -todaycolor - calendar widget, the color that will mark the current day
#
addWidget clock 1
addText " | " "red"

# Displays network information
#
# -fg / -foreground - the text color
# -bg / -background - the background color
# -device - the device to be monitored
# -updateinterval - the interval in which the 
#		widget receives updates (needs to be the same 
#		as the update interval specified as second parameter, 
#		in order to give correct results)
#
addWidget network 1 -device eth1 -updateinterval 1
addText " | " "red"

# Displays memory and swap information
#
# -fg / -foreground - the text color
# -bg / -background - the backgroundcolor
# -bc - status bar character that represents 10% memory
# -gc / -graphicscolor - the color of the graph
# -showwhat - if showwhat is 0, used memory will be displayed,
#		if showwhat is 1, free memory will be displayed
#
addWidget memory 5 -gc blue -bc | -showwhat 0
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
#
addWidget cpu 1 -loadcolor blue -device 0 -showLoad 1 -showTotalLoad 1

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
#addWidget text 1 -command [list exec uptime]
