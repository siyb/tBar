#!/bin/sh

# This script can be used to build a tbar starkit. Please check the settings
# section and adjust the settings if required.

#
# SETTINGS
#

# tclkit software
TCLKITURL='http://tclkit.googlecode.com/files/tclkit-8.5.8-linux-ix86.gz'
TCLKITSHA1='477331776ce8b67a7326c554c54f4688161679d7'
SDXURL='http://tclkit.googlecode.com/files/sdx-20100310.kit'
SDXSHA1='be3de2bc770764e269707a97741e3699d61e878d'

# library path, those must include a valid, path independent pkgIndex.tcl
SQLITE='/usr/lib/sqlite3/'
TCLLIB='/usr/share/tcltk/tcllib1.12/'
LIBTKIMG='/usr/lib/tcltk/Img1.3/'

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

if [ ! -d $TCLLIB ]; then
	echo "Sqlite could not be found"
	exit
fi

if [ ! -d $LIBTKIMG ]; then
	echo "Sqlite could not be found"
	exit
fi

pwd=`pwd`

# copy source and library files
cp -r ./ /tmp/tbar.vfs
mv /tmp/tbar.vfs/starkit/main.tcl /tmp/tbar.vfs/
cp -r $SQLITE /tmp/tbar.vfs/sqlite
cp -r $TCLLIB /tmp/tbar.vfs/tcllib
cp -r $LIBTKIMG /tmp/tbar.vfs/libtkimg

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
