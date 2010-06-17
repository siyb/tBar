#!/bin/sh

TCLKITURL='http://tclkit.googlecode.com/files/tclkit-8.5.8-linux-ix86.gz'
TCLKITSHA1='477331776ce8b67a7326c554c54f4688161679d7'

SDXURL='http://tclkit.googlecode.com/files/sdx-20100310.kit'
SDXSHA1='be3de2bc770764e269707a97741e3699d61e878d'

if [ -e tbar.kit ]; then
  rm tbar.kit
fi

pwd=`pwd`
cp -R ./ /tmp/tbar.vfs

cd /tmp
wget -O tclkit.gz $TCLKITURL
gunzip tclkit
chmod u+x tclkit
wget -O sdx.kit $SDXURL
mv tbar.vfs/tbar.tcl tbar.vfs/main.tcl
cp tclkit tclkitcpy
./tclkitcpy sdx.kit wrap tbar.kit -runtime ./tclkit
cd $pwd
mv /tmp/tbar.kit ./
rm /tmp/tclkit
rm /tmp/tclkitcpy
rm /tmp/sdx.kit
rm -rf /tmp/tbar.vfs
echo "Use ./tbar.kit to execute"
