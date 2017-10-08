#!/bin/sh
#sudo vi /System/Library/CoreServices/SystemVersion.plist

OSVERSION=$(sysctl kern.osversion | awk '{ print $2 }')
FAKEVERSION=$1

echo "$OSVERSION -> $FAKEVERSION"

sudo sed -e "s/$OSVERSION/$FAKEVERSION/" -i '' /System/Library/CoreServices/SystemVersion.plist
grep $FAKEVERSION /System/Library/CoreServices/SystemVersion.plist

read

sudo sed -e "s/$FAKEVERSION/$OSVERSION/" -i '' /System/Library/CoreServices/SystemVersion.plist
grep $OSVERSION /System/Library/CoreServices/SystemVersion.plist
