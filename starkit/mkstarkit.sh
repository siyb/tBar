#!/bin/sh

# This script can be used to build a tbar starkit. Please check the settings
# section and adjust the settings if required.

#
# SETTINGS
#

# tclkit software
# TODO: include all platforms here (array) and create a starkit for all available platforms
TCLKITURL='http://tclkit.googlecode.com/files/tclkit-8.5.9-linux-ix86.gz'
TCLKITSHA1='10f89b85befc68f0088f7895873eb45ab301051b'
SDXURL='http://tclkit.googlecode.com/files/sdx-20110317.kit'
SDXSHA1='1a77b0b5bc8cfcf2df2ef051a511e9187103ce0c'

# Paths of libraries which are mandatory for the standard tbar distribution.
# Make sure that each path contains a valid pkgIndex.tcl file.
SQLITE='/usr/lib/sqlite3/'
TCLLIB='/usr/share/tcltk/tcllib1.13/'
LIBTKIMG='/usr/lib/tcltk/Img1.3/'
UNIXSOCKETS='/usr/lib/unix_sockets0.1/'
TDOM='/usr/lib/tcltk/tdom0.8.3/'

#
# CODE
#
if [ -e tbar.kit ]; then
	rm tbar.kit
fi

if [ ! -d $SQLITE ]; then
	echo "Sqlite could not be found"
	exit
fi

if [ ! -d $TDOM ]; then
	echo "tdom could not be found"
	exit
fi

if [ ! -d $TCLLIB ]; then
	echo "Tcllib could not be found"
	exit
fi

if [ ! -d $LIBTKIMG ]; then
	echo "Libtkimg could not be found"
	exit
fi

if [ ! -d $UNIXSOCKETS ]; then
	echo "Unixsockets could not be found"
	exit
fi

pwd=`pwd`

# copy source and library files
cp -r ./ /tmp/tbar.vfs
mv /tmp/tbar.vfs/starkit/main.tcl /tmp/tbar.vfs/
mkdir -p /tmp/tbar.vfs/lib/
cp -r $SQLITE /tmp/tbar.vfs/lib/sqlite
cp -r $TCLLIB /tmp/tbar.vfs/lib/tcllib
cp -r $LIBTKIMG /tmp/tbar.vfs/lib/libtkimg
cp -r $UNIXSOCKETS /tmp/tbar.vfs/lib/unixsockets
cp -r $TDOM /tmp/tbar.vfs/lib/tdom

# getting & unpacking & settings rights for tclkit software
cd /tmp
wget -O tclkit.gz $TCLKITURL
gunzip tclkit
chmod u+x tclkit
wget -O sdx.kit $SDXURL
cp tclkit tclkitcpy

# creating kit
./tclkitcpy sdx.kit wrap tbar.kit -runtime ./tclkit
cd $pwd

# cleaning up
mv /tmp/tbar.kit ./
rm /tmp/tclkit /tmp/tclkitcpy /tmp/sdx.kit
rm -rf /tmp/tbar.vfs
