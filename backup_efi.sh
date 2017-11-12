#!/bin/sh

TARGET_PATH="$HOME/drv/컴퓨터/Clover"

DMD_UTC=$(date -u +%y%m%d-%H)
DMD=$(date +%y%m%d-%H)
if [ "$(mount | grep ESP)" != "" ]; then
	SOURCE_DIR="/Volumes/ESP"
elif [ "$(mount | grep EFI)" != "" ]; then
	SOURCE_DIR="/Volumes/EFI"
fi

EXCLUDE_TAR="--exclude .Spotlight-V100 --exclude .Trashes --exclude .fseventsd --exclude .TemporaryItems --exclude .svn"

EFI_DEV=disk0s1
diskutil umount $EFI_DEV
sudo dd if=/dev/$EFI_DEV bs=64k | gzip -c > "${TARGET_PATH}"/efi_${DMD}.img.gz
diskutil mount $EFI_DEV
tar cvzf "${TARGET_PATH}"/efi_${DMD}.tgz ${EXCLUDE_TAR} -C ${SOURCE_DIR} .
ls -lh "${TARGET_PATH}"
