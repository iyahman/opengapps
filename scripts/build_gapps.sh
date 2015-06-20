#!/bin/sh
#This file is part of The Open GApps script of @mfonville.
#
#    The Open GApps scripts are free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    These scripts are distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#

#Check architecture
if { [ "x$1" != "xarm" ] && [ "x$1" != "xarm64" ] && [ "x$1" != "xx86" ] && [ "x$1" != "x86_64" ]; } || [ "x$2" = "x" ]; then
	echo "Usage: $0 (arm|arm64|x86|x86_64) API_LEVEL"
	exit 1
fi
DATE=$(date +"%Y%m%d")
TOP="$(realpath .)"
ARCH="$1"
API="$2"
BUILD="$TOP/build"
OUT="$TOP/out"
SOURCES="$TOP/sources"
SCRIPTS="$TOP/scripts"
DENSITIES="2 4 6 8" #don't add 0
VARIANTS="stock pico" #keep in order from large to small
if [ "$ARCH" = "arm" ] || [ "$ARCH" = "arm64" ]; then
	AROMAVARIANTS="stock" #add 'stock' to build aroma for ARM platforms
else
	AROMAVARIANTS="" #keep empty to skip building of aroma
fi
if [ "$ARCH" = "arm64" ]; then
	LIBFOLDER="lib64"
	FALLBACKARCH="arm"
elif [ "$ARCH" = "x86_64" ]; then
	LIBFOLDER="lib64"
	FALLBACKARCH="x86"
else
	LIBFOLDER="lib"
	FALLBACKARCH="$ARCH"
fi

STOCK="cameragoogle
keyboardgoogle"

FULL="books
chrome
cloudprint
docs
drive
ears
earth
fitness
keep
messenger
movies
music
newsstand
newswidget
playgames
sheets
slides
talkback
wallet"
if [ "$API" -gt "19" ]; then
	FULL="$FULL
webviewgoogle"
fi

MINI="clockgoogle
googleplus
hangouts
maps
photos
street
youtube"

MICRO="calendargoogle
exchangegoogle
gmail
googlenow
googletts
faceunlock"

NANO="search
speech"

PICO="calsync"

STOCKREMOVE="browser
email
gallery
launcher
mms
picotts"
if [ "$API" -gt "19" ]; then
	STOCKREMOVE="$STOCKREMOVE
webviewstock"
fi

#Calculate platform version
if [ "$API" = "19" ]; then
	PLATFORM="4.4"
elif [ "$API" = "21" ]; then
	PLATFORM="5.0"
elif [ "$API" = "22" ]; then
	PLATFORM="5.1"
else
	echo "ERROR: Unknown API version! Aborting..."
	exit 1
fi

build="$BUILD/$ARCH/$API/"
install -d "$build"

#####---------CHECK FOR EXISTANCE OF SOME BINARIES---------
command -v aapt >/dev/null 2>&1 || { echo "aapt is required but it's not installed.  Aborting." >&2; exit 1; }
command -v install >/dev/null 2>&1 || { echo "coreutils is required but it's not installed.  Aborting." >&2; exit 1; }
#coreutils also contains the basename command
command -v openssl >/dev/null 2>&1 || { echo "openssl is required but it's not installed.  Aborting." >&2; exit 1; }
#necessary to use signapk
command -v unzip >/dev/null 2>&1 || { echo "unzip is required but it's not installed.  Aborting." >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { echo "zip is required but it's not installed.  Aborting." >&2; exit 1; }
command -v zipalign >/dev/null 2>&1 || { echo "zipalign is required but it's not installed.  Aborting." >&2; exit 1; }

. "$SCRIPTS/inc.buildhelper.sh"
. "$SCRIPTS/inc.buildtarget.sh"
. "$SCRIPTS/inc.aromadata.sh"
. "$SCRIPTS/inc.installdata.sh"
. "$SCRIPTS/inc.packagetarget.sh"
. "$SCRIPTS/inc.updatebinary.sh"
buildtarget
alignbuild
commonscripts
#The first variant we build is stock, which supports all smaller variants
SUPPORTEDVARIANTS="$VARIANTS"
for VARIANT in $VARIANTS; do
	variantscripts
	createzip
	#smaller variants can't build larger variants
	SUPPORTEDVARIANTS=$(echo $SUPPORTEDVARIANTS | sed "s/$VARIANT//g")
done

#ONLY BUILD AROMA AFTER NORMAL VARIANTS, the build-tree will be heavily modified
SUPPORTEDVARIANTS="$VARIANTS" #notice that aroma can build all 'normal' variants
for AROMA in $AROMAVARIANTS; do
	VARIANT="$AROMA"
	variantscripts
	aromascripts
	createzip "aroma"
done
