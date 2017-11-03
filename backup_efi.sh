#!/bin/sh

DMD=$(date -u +%y%m%d)
if [ "$(mount | grep ESP)" != "" ]; then
	TARGET_DIR="/Volumes/ESP"
elif [ "$(mount | grep EFI)" != "" ]; then
	TARGET_DIR="/Volumes/EFI"
fi

EXCLUDE_TAR="--exclude .Spotlight-V100 --exclude .Trashes --exclude .fseventsd --exclude .TemporaryItems"

#tar cvzf ~/Documents/Clover/efi_$DMD.tgz --exclude .Spotlight-V100 --exclude .Trashes --exclude .fseventsd -C $TARGET_DIR .
tar cvzf ~/Documents/Clover/efi_$DMD.tgz ${EXCLUDE_TAR} -C $TARGET_DIR .
