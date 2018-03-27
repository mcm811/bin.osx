#!/bin/bash
# torrent_remove.sh <changmin811@gmail.com>

function removeFileOlderThanDate() {
	local cmd=$1
	local whiteList=$2
	local srcFolder=$3
	local cutDate=$4

	if [ "$cutDate" == "" ]; then
		# 삭제 기준일이 없으면 3개월 이전 파일을 삭제한다
		local current=$(date +%s)
		local before3month=$(($current - 3 * 2629743))
		if [ "$(uname)" == "Darwin" ]; then
			cutDaet=$(date -r$before3month +%y%m%d)
		else
			cutDate=$(date -d@$before3month +%y%m%d)
		fi
		echo cut date: $cutDate
	fi

	IFS=$'\n'
	cd "$srcFolder"
	for folder in $(ls $srcFolder); do
		if [ ! -d "$folder" ]; then
			continue;
		fi

		if grep "${folder// in */}" "$whiteList" &> /dev/null; then
			echo '#'[$folder]
			continue
		fi

		echo +[$folder]
		for file in $(ls $folder); do
			fileDate=$(echo $file | cut -d. -f3)
			if ((fileDate > 170100)) && ((fileDate < cutDate)); then
				echo "[$fileDate] rm $srcFolder/$folder/$file"
				${cmd} -vf "$srcFolder/$folder/$file"
			fi
		done
	done
	IFS=$' \t\n'
}
