#!/bin/bash
# torrent.sh <changmin811@gmail.com>

defaultQuality=720
defaultCount=100

magnetListFile="/usr/local/torrent/magnet_list"
whiteListFile="/usr/local/torrent/torrent_whitelist.txt"
torrentFile="/usr/local/torrent/torrent.sh"
downloadFile="/usr/local/torrent/torrent_download.sh"
disposeFile="/usr/local/torrent/torrent_dispose.sh"
removeFile="/usr/local/torrent/torrent_remove.sh"
backupFile="$HOME/bin/backup_rsync.sh"

source $downloadFile
programName=$(basename $0)
if [ "$(echo $programName | cut -d_ -f 1)" == "local" ]; then
	setServerLocal
else
	setServerConfig
fi

function runHelp() {
	#torrentSearch count page_max_num quality(360 720 1080) search text
	echo "사용법:"
	echo "$programName cor 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo "$programName kim 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo "$programName pon 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo
	echo "$programName cor ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo "$programName kim ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo "$programName pon ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo
	echo "$programName ent pagenum"
	echo "$programName drama pagenum"
	echo "$programName social pagenum"
	echo
	echo "$programName 사이트(cor kim pong) ent pagenum"
	echo "$programName 사이트(cor kim pong) drama pagenum"
	echo "$programName 사이트(cor kim pong) social pagenum"
	echo
	echo "$programName 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo "$programName 개수 시작페이지 최대페이지 화질(360 720 1080)"
	echo "$programName 개수 시작페이지 최대페이지 검색어"
	echo "$programName 개수 시작페이지 검색어"
	echo "$programName 개수 검색어"
	echo "$programName 검색어"
	echo
	echo "예제:"
	echo "$programName 100 5 720 동상이몽2"
	echo "$programName 1 1 360 TV소설 꽃피어라 달순아"
	echo "$programName 1 1 720 황금빛 내 인생"
	echo "$programName 1 1 720 무한 도전"
	echo "$programName 100 2 720 아는 형님"
	echo
	echo "$programName cor ep 1 12 720 개그 콘서트"
	echo "$programName kim ep 1 12 360 맛있는 녀석들"
	echo "$programName pong ep 1 12 1080 맛있는 녀석들"
	echo
}

function runSync() {
	echo rsync rasPi

	local optVerbose="-v"
	srcPath="$HOME/Google Drive/ShellScript.localized/TorrentBin"
	trgPath="/usr/local/torrent"

	# convert text format from UTF8-MAC to UTF8
	local srcWhiteListFile="$srcPath/$(basename $whiteListFile)"
	if [ -f "$srcWhiteListFile" ]; then
		local tempFile="$(mktemp -q -t $(basename $0).XXX)"
		iconv -f UTF8-MAC -t UTF8 "$srcWhiteListFile" > "$tempFile"
		mv -f "$tempFile" "$srcWhiteListFile"
	fi

	#backup rasPi1 /etc
	rsync -aCz --no-g --no-o -e ssh\
		root@r1:/etc/samba/smb.conf $HOME/Archives.localized/raspberryPi/etc/samba/smb.conf
	rsync -aCz --no-g --no-o -e ssh\
		root@r1:/etc/transmission-daemon/settings.json\
		$HOME/Archives.localized/raspberryPi/etc/transmission-daemon/settings.json

	# /etc/cron.d/torrent_cron_ras
	rsync -auz --no-g --no-o -e ssh\
		--exclude-from="/usr/local/torrent/rsync_exclude_pattern.txt"\
		"$srcPath/torrent_cron_"* "root@r1:/etc/cron.d/"
	rsync -auz --no-g --no-o -e ssh\
		--exclude-from="/usr/local/torrent/rsync_exclude_pattern.txt"\
		"root@r1:/etc/cron.d/torrent_cron_"* "$srcPath/"

	# /usr/local/torrent
	rsync -aCz --no-g --no-o -e ssh\
		--exclude-from="/usr/local/torrent/rsync_exclude_pattern.txt"\
		"$srcPath/" "pi@r1:$trgPath"
	rsync -aCz --no-g --no-o --delete -e ssh\
		--exclude-from="/usr/local/torrent/rsync_exclude_pattern.txt"\
		"$srcPath/" "pi@r1:tor"

	rsync -aCz --no-g --no-o --delete\
		--exclude-from="/usr/local/torrent/rsync_exclude_pattern.txt"\
		"$srcPath/" "$trgPath"
	rsync -aCz --no-g --no-o --delete\
		--exclude-from="/usr/local/torrent/rsync_exclude_pattern.txt"\
		"$srcPath/" "$HOME/bin/torrent"

	# /usr/local/torrent/magnet_list
	rsync -aCz --no-g --no-o -e ssh\
		--exclude-from="/usr/local/torrent/rsync_exclude_pattern.txt"\
		"pi@r1:$trgPath/magnet_list_"* "$trgPath/"
}

function linkFile() {
	for file in $(ls -1 /usr/local/torrent/t*.sh); do
		file=${file//local_//}
		sudo ln -sfv $file /usr/local/bin/$(basename $file)
	done
}

function torrentSite() {
	local pageNumber=1
	local site=$1
	shift
	case $1 in
		login)
			torrentLogin_$site
		;;
		ent|drama|social)
			[ $# -eq 2 ] && pageNumber=$2
			torrentCategory_$site $1 $defaultCount $pageNumber $DEFAULT_QUALITY
		;;
		ep)
			shift
			local epStart=$1
			shift
			local epEnd=$1
			shift
			local epQuality=$1
			shift
			local epName="$*"
			for epNumber in $(seq $epStart $epEnd); do
				torrentSearch_$site 1 1 1 "${epQuality}" "${epName}.E${epNumber}."
				torrentSearch_$site 1 1 1 "${epQuality}" "${epName}.E0${epNumber}."
			done
		;;
		*)
			torrentSearch_$site "$@"
		;;
	esac
}

function runCommand() {
	case $1 in
		runSync)
			shift
			runSync $@
		;;
		sync)
			shift
			if [ "$(hostname -s)" == "rasPi" ]; then
				ssh changmin@192.168.0.8 $torrentFile runSync
			else
				runSync $@
				source $backupFile
			fi
		;;
		backup)
			source $backupFile
		;;
		link)
			linkFile
		;;
		clean)
			find . \( -name ".DS_Store" -or -name ".AppleDouble" -or -name "._*" \) -exec rm -rfv {} \;
		;;
		synclink)
			linkFile
			ssh root@r1 $torrentFile link
		;;
		localized)
			for file in *; do
				[ -d "$file" ] && rsync -az ~changmin/Documents/.localized ./"$file"/
			done
		;;
		purge|clear|pur*)
			shift
			torrentPurge $@
		;;
		cleanup|cle*)
			source $disposeFile
			cleanupRaspiDropbox
		;;
		dispose|rebuild|install|dis*)
			shift
			source $disposeFile
			disposeTorrent $@
			return 0
		;;
		magnet*|mag*)
			addMagnet -a $@
			torrentPurge
		;;
		*)
			return 1;
		;;
	esac
}

function run() {
	case $1 in
		rmold|old*)
			shift
			source $removeFile
			source $disposeFile
			[ "$#" -le 1 ] && removeFileOlderThanDate "$whiteListFile" "$RASPI_torrentTargetPath" $@
			[ "$#" -eq 2 ] && removeFileOlderThanDate "$RASPI_torrentTargetPath" $@
			[ "$#" -ge 3 ] && removeFileOlderThanDate $@
		;;
		trans*|-t)
			shift
			transDefault $@
		;;
		list|-l)
			transDefault -l|grep -ve'ID.*Name' -ve'Sum:.*'
		;;
		ls*|ma*|ta*)
			if [ "$(hostname -s)" == "rasPi" ]; then
				tail ${magnetListFile}_* | tail
			else
				ssh pi@r1 "tail ${magnetListFile}_* | tail"
			fi
		;;
		kim|cor|pon)
			torrentSite $@
			torrentPurge
		;;
		drama|ent|social|ep)
			torrentSite cor $@
			torrentSite pon $@
			torrentSite kim $@
			torrentPurge
		;;
		login)
			torrentLogin_cor
			torrentLogin_pon
			torrentLogin_kim
		;;
		-h)
			runHelp
		;;
		*)
			if [ $# -eq 0 ]; then
				runHelp
				return $?
			fi
			if runCommand $@; then
				return $?
			fi
			if torrentSearch $@; then
				torrentPurge
				return $?
			fi
		;;
	esac
}

run $@