#!/bin/bash

for FILE in "/Applications/Android Studio"*; do
	if [ -d "$FILE" ]; then
		cp -va $HOME/bin/studio.vmoptions "$FILE/Contents/bin"
	fi
done
