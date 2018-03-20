#!/bin/bash

source /usr/local/torrent/download_server_address
[ "$TOR_SERVER_IP" == "" ] && TOR_SERVER_IP="localhost"
[ "$TOR_SERVER_PORT" == "" ] && TOR_SERVER_PORT=9191

TOR_SERVER=$TOR_SERVER_IP:$TOR_SERVER_PORT
TOR_SERVER_IMAC=192.168.0.3
TOR_AUTH=moon:123123212121

URL_SERVER_COR="https://www.tcorea.com"
URL_TYPE_ENT_COR="${URL_SERVER_COR}/bbs/board.php?bo_table=torrent_kortv_ent"
URL_TYPE_DRAMA_COR="${URL_SERVER_COR}/bbs/board.php?bo_table=torrent_kortv_drama"
URL_TYPE_SOCIAL_COR="${URL_SERVER_COR}/bbs/board.php?bo_table=torrent_kortv_social"
COOKIE_TCOREA="/usr/local/torrent/cookie_tcorea"

URL_SERVER_KIM="https://torrentkim12.com"
URL_TYPE_ENT_KIM="${URL_SERVER_KIM}/bbs/s.php?b=torrent_variety"
URL_TYPE_DRAMA_KIM="${URL_SERVER_KIM}/bbs/s.php?b=torrent_tv"
URL_TYPE_SOCIAL_KIM="${URL_SERVER_KIM}/bbs/s.php?b=torrent_docu"

URL_SERVER_PONG="https://torrentpong.com"
URL_TYPE_ENT_PONG="${URL_SERVER_PONG}/bbs/board.php?bo_table=ent"
URL_TYPE_DRAMA_PONG="${URL_SERVER_PONG}/bbs/board.php?bo_table=kordrama"
URL_TYPE_SOCIAL_PONG="${URL_SERVER_PONG}/bbs/board.php?bo_table=dacu"

function download_torrent_help() {
	#download_torrent count page_max_num quality(360 720 1080) search text
	echo "사용법:"
	echo "download cor 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo "download kim 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo "download pong 개수 시작페이지 최대페이지 화질(360 720 1080) 검색어"
	echo
	echo "download cor ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo "download kim ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo "download pong ep 에피소드시작 에피소드끝 화질(360 720 1080) 제목"
	echo
	echo "download ent pagenum"
	echo "download drama pagenum"
	echo "download social pagenum"
	echo
	echo "download 사이트(cor kim pong) ent pagenum"
	echo "download 사이트(cor kim pong) drama pagenum"
	echo "download 사이트(cor kim pong) social pagenum"
	echo
	echo "download 개수 최대페이지 화질(360 720 1080) 검색어"
	echo "download 개수 최대페이지 화질(360 720 1080)"
	echo "download 개수 최대페이지 검색어"
	echo "download 개수 최대페이지"
	echo "download 개수 검색어"
	echo "download 개수"
	echo "download 검색어"
	echo
	echo "예제:"
	echo "download 100 5 720 동상이몽2"
	echo "download 1 1 360 TV소설 꽃피어라 달순아"
	echo "download 1 1 720 황금빛 내 인생"
	echo "download 1 1 720 무한 도전"
	echo "download 100 2 720 아는 형님"
	echo
	echo "download cor ep 1 12 720 개그 콘서트"
	echo "download kim ep 1 12 360 맛있는 녀석들"
	echo "download pong ep 1 12 1080 맛있는 녀석들"
	echo
}

function login_tcorea() {
	curl -s https://www.tcorea.com/bbs/login_check.php -c $COOKIE_TCOREA -d 'mb_id=mcmtor' -d 'mb_password=123123'
	cat $COOKIE_TCOREA
}

function set_server() {
	TOR_SERVER="$@":9191
}

function set_server_local() {
	TOR_SERVER=localhost:$TOR_SERVER_PORT
}

function set_server_config() {
	if [ "$(hostname -s |cut -c 1-4)" == "iMac" ]; then
		[ "$(ps x|grep Transmission|grep App)" == "" ] && set_server "$TOR_SERVER_IMAC" || set_server_local
	fi
}

function list_magnet_tail() {
	transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --list | tail -n 1
}

function list_magnet() {
	# transmission-remote 192.168.0.3:9191 --auth moon:123123212121 --list
	transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --list
}

function remove_magnet() {
	transmission-remote ${TOR_SERVER} --auth ${TOR_AUTH} --torrent $TORRENT_ID_LIST --remove
}

function purge_torrent() {
	local PURGE_TOR_SERVER=$TOR_SERVER
	[ "$1" != "" ] && PURGE_TOR_SERVER=$1

	tempfoo=`basename $0`
	echo $tempfoo
	TOR_LIST_TEMP=`mktemp -q -t ${tempfoo}.XXX`
	if [ $? -ne 0 ]; then
		echo "$0: Can't create temp file, exiting..."
		return 1
	fi

	list_magnet >& ${TOR_LIST_TEMP}
	cat ${TOR_LIST_TEMP}

	TORRENT_ID_LIST=`cat ${TOR_LIST_TEMP} | grep "Stopped\|Seeding\|Finished\|Idle" | grep "100%" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | cut -d ' ' -f 1`
	TORRENT_ID_LIST=`echo ${TORRENT_ID_LIST} | sed -e 's/ /,/g'`

	if [ "$TORRENT_ID_LIST" != "" ]; then
		echo "transmission-remote ${PURGE_TOR_SERVER} --auth ${TOR_AUTH} --torrent $TORRENT_ID_LIST --remove"
		transmission-remote ${PURGE_TOR_SERVER} --auth ${TOR_AUTH} --torrent $TORRENT_ID_LIST --remove
	fi

	# 다운로드 항목이 없을때만 폴더 정리
	source /usr/local/torrent/download_rebuild_torrent.sh
	TLT=$(cat ${TOR_LIST_TEMP}|tail -n 1)
	if [ "$(echo $TLT)" == "Sum: None 0.0 0.0" ]; then
		cleanup_raspi_dropbox
		rebuild_raspi_dropbox
	fi

	rm -f ${TOR_LIST_TEMP}
}

function add_magnet() {
	transmission-remote ${TOR_SERVER} --auth moon:123123212121 $(echo "$@" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
}

MAGNET_LIST_FILE="/usr/local/torrent/magnet_list"
function get_magnet_list() {
	MAGNET_LIST=""
	MAGNET_COUNT=0
	MAGNET_LIST_DATE_FILE="${MAGNET_LIST_FILE}_$(date +%m)"
	echo $MAGNET_LIST_DATE_FILE
	for MAGNET in $@; do
		if [ "$MAGNET" != "" ]; then
			MAGNET=$(echo ${MAGNET}|tr '[:upper:]' '[:lower:]')
			MAGNET_EXIST=$MAGNET
			grep --ignore-case $MAGNET ${MAGNET_LIST_FILE}_* > /dev/null && MAGNET=""
			if [ "$MAGNET" != "" ]; then
				echo "$MAGNET $(date +"%Y.%m.%d %T")" >> $MAGNET_LIST_DATE_FILE;
				tail -n 1 $MAGNET_LIST_DATE_FILE
				let MAGNET_COUNT=MAGNET_COUNT+1
				MAGNET_LIST="$MAGNET_LIST -a $MAGNET"
				echo +[$MAGNET]
			else
				echo @[$MAGNET_EXIST]
			fi
		fi
	done
	echo "검색 결과: 마그넷 ${MAGNET_COUNT}개 발견"
	[ "$MAGNET_LIST" != "" ] && add_magnet "${MAGNET_LIST}"
}

##################
## torrent corea
##
function print_magnet_cor() {
	local QUALITY="$1"
	shift
	local COUNT="$1"
	shift
	local URL="$*"
	local MAGNET_RET="$(curl -s "$URL" -b "$COOKIE_TCOREA"|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep magnet:|grep "$QUALITY"|head -n $COUNT|sed -e 's/.*href=.//' -e 's/\" id=.*//' -e 's/.>.*//')"
	echo $MAGNET_RET
}

function download_torrent_cor() {
	# download_torrent_cor count start_page end_page quality search
	local COUNT=1
	local PAGE_NUM_START=1
	local PAGE_NUM_END=1
	local QUALITY="720p-"
	local SEARCH=""
	local VAR=$1

	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_NUM_START=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				PAGE_NUM_END=$1
				shift
				VAR=$1
				if ((VAR > 0)) 2> /dev/null; then
					QUALITY="${1}p-"
					shift
				fi
			fi
		fi
	fi

	SEARCH="$(echo "$*" | sed -e 's/ /+/g')"
	echo "검색 [$SEARCH]"

	# grep -v 제외 문자열
	URL_LIST=""
	for PAGE_NUM in $(eval echo {$PAGE_NUM_START..$PAGE_NUM_END}); do
		URL="${URL_TYPE_ENT_COR}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_cor $QUALITY $COUNT $URL)
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"

		URL="${URL_TYPE_DRAMA_COR}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_cor $QUALITY $COUNT $URL)
		if [ "${URL_RET}" != "" ]; then
			URL_LIST="$URL_LIST $URL_RET"
			continue
		fi

		URL="${URL_TYPE_SOCIAL_COR}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_cor $QUALITY $COUNT $URL)
		if [ "${URL_RET}" != "" ]; then
			URL_LIST="$URL_LIST $URL_RET"
			continue
		fi
	done

	get_magnet_list ${URL_LIST}
}

function download_torrent() {
	# download_torrent count page quality search
	local COUNT=1
	local PAGE_MAX_NUM=1
	local QUALITY="720p-"
	local SEARCH=""
	local VAR=$1

	if ((VAR > 0)) 2> /dev/null; then
		#COUNT=$((${1}+1))
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				QUALITY="${1}p-"
				shift
			fi
		fi
	fi

	SEARCH="$(echo "$*" | sed -e 's/ /+/g')"
	echo "검색 [$SEARCH]"

	# grep -v 제외 문자열
	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_ENT_COR}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_cor $QUALITY $COUNT $URL)
		if [ "${URL_RET}" != "" ]; then
			URL_LIST="$URL_LIST $URL_RET"
		fi

		URL="${URL_TYPE_DRAMA_COR}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_cor $QUALITY $COUNT $URL)
		if [ "${URL_RET}" != "" ]; then
			URL_LIST="$URL_LIST $URL_RET"
			continue
		fi

		URL="${URL_TYPE_SOCIAL_COR}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_cor $QUALITY $COUNT $URL)
		if [ "${URL_RET}" != "" ]; then
			URL_LIST="$URL_LIST $URL_RET"
			continue
		fi
	done

	get_magnet_list ${URL_LIST}
}

function download_ent_cor() {
	# download_ent count page_num quality
	local COUNT=1
	local PAGE_MAX_NUM=2
	local QUALITY="720p-NEXT"
	local SEARCH="720p-NEXT"
	local VAR=$1

	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_ENT_COR}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_cor $QUALITY $COUNT $URL)
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"
	done
	get_magnet_list ${URL_LIST}
}

function download_drama_cor() {
	# download_drama count page_num quality
	local COUNT=1
	local PAGE_MAX_NUM=2
	local QUALITY="720p-NEXT"
	local SEARCH="720p-NEXT"
	local VAR=$1

	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_DRAMA_COR}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_cor $QUALITY $COUNT $URL)
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"
	done
	get_magnet_list ${URL_LIST}
}

function download_social_cor() {
	# download_social count page_num quality
	local COUNT=1
	local PAGE_MAX_NUM=2
	local QUALITY="720p-NEXT"
	local SEARCH="720p-NEXT"
	local VAR=$1
	
	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_SOCIAL_COR}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_cor $QUALITY $COUNT $URL)
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"
	done
	get_magnet_list ${URL_LIST}
}

################
## torrent kim
##
function download_torrent_kim() {
	# download_torrent_kim count start_page end_page quality search
	local COUNT=1
	local PAGE_NUM_START=1
	local PAGE_NUM_END=1
	local QUALITY="720p-"
	local SEARCH=""
	local VAR=$1

	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_NUM_START=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				PAGE_NUM_END=$1
				shift
				VAR=$1
				if ((VAR > 0)) 2> /dev/null; then
					QUALITY="${1}p-"
					shift
				fi
			fi
		fi
	fi

	SEARCH="$(echo "$*" | sed -e 's/ /+/g')"
	echo "검색 [$SEARCH]"

	# declare -a magnet_array=($(curl -s "https://torrentkim12.com/bbs/s.php?k=720p-NEXT&b=torrent_variety&page=1"|grep Mag_dn|grep href|sed -e 's/.*(./magnet:?xt=urn:btih:/' -e 's/.).*//'))
	# IFS=$'\n';declare -a name_array=($(curl -s "https://torrentkim12.com/bbs/s.php?k=720p-NEXT&b=torrent_variety&page=1"|grep '\t</a>'|sed -e 's/^...//' -e 's/...<.a>//'));IFS=$' \t\n'

	URL_LIST=""
	for PAGE_NUM in $(eval echo {$PAGE_NUM_START..$PAGE_NUM_END}); do
		URL="${URL_SERVER_KIM}/bbs/s.php?page=${PAGE_NUM}&k=${SEARCH}"
		echo SEARCH: $URL
		set -f; IFS=$'\n';
		declare -a magnet_array=($(curl -s "${URL}"|grep Mag_dn|grep href|head -n $COUNT|sed -e 's/.*(./magnet:?xt=urn:btih:/' -e 's/.).*//'))
		declare -a name_array=($(curl -s "${URL}"|grep '	</a>'|head -n $COUNT|sed -e 's/^...//' -e 's/...<.a>//'))
		set +f; IFS=$' \t\n'
		for n in ${!magnet_array[@]}; do
			URL_RET=$(echo ${name_array[n]}|grep -veE01.E.*END -veE..-.. -ve전편 -ve완결|grep "$QUALITY")
			if [ "${URL_RET}" != "" ]; then
				URL_LIST="$URL_LIST ${magnet_array[n]}"
				echo [${name_array[n]}] ${magnet_array[n]}
			fi
		done
		unset -v magnet_array name_array
	done

	get_magnet_list ${URL_LIST}
}

function print_magnet_kim() {
	local QUALITY="$1"
	shift
	local COUNT="$1"
	shift
	local URL="$*"
	local MAGNET_RET="$(curl -s "$URL"|grep Mag_dn|grep href|head -n "$COUNT"|sed -e 's/.*(./magnet:?xt=urn:btih:/' -e 's/.).*//')"
	echo $MAGNET_RET
}

function download_ent_kim() {
	# download_ent count page_num quality
	local COUNT=100
	local PAGE_MAX_NUM=2
	local QUALITY="720p-NEXT"
	local SEARCH="720p-NEXT"
	local VAR=$1
	
	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_ENT_KIM}&page=${PAGE_NUM}&k=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_kim $QUALITY $COUNT $URL)
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"
	done
	get_magnet_list ${URL_LIST}
}

function download_drama_kim() {
	# download_drama count page_num quality
	local COUNT=100
	local PAGE_MAX_NUM=2
	local QUALITY="720p-NEXT"
	local SEARCH="720p-NEXT"
	local VAR=$1
	
	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_DRAMA_KIM}&page=${PAGE_NUM}&k=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_kim $QUALITY $COUNT $URL)
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"
	done
	get_magnet_list ${URL_LIST}
}

function download_social_kim() {
	# download_social count page_num quality
	local COUNT=100
	local PAGE_MAX_NUM=2
	local QUALITY="720p-NEXT"
	local SEARCH="720p-NEXT"
	local VAR=$1
	
	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_SOCIAL_KIM}&page=${PAGE_NUM}&k=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_kim $QUALITY $COUNT $URL)
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"
	done
	get_magnet_list ${URL_LIST}
}

####################
## torrentpong.com
##
# curl -s "https://torrentpong.com/bbs/board.php?bo_table=ent&page=1&stx=720p-NEXT"|grep magnet|grep 720p-NEXT
function print_magnet_pong() {
	local QUALITY="$1"
	shift
	local COUNT="$1"
	shift
	local URL="$*"
	local MAGNET_RET="$(curl -s "$URL"|grep magnet|grep href|grep "$QUALITY"|head -n "$COUNT"|sed -e 's/.*href=.//' -e 's/..title=.*//')"
	echo $MAGNET_RET
}

function download_torrent_pong() {
	# download_torrent_pong count start_page end_page quality search
	local COUNT=1
	local PAGE_NUM_START=1
	local PAGE_NUM_END=1
	local QUALITY="720p-"
	local SEARCH=""
	local VAR=$1

	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_NUM_START=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				PAGE_NUM_END=$1
				shift
				VAR=$1
				if ((VAR > 0)) 2> /dev/null; then
					QUALITY="${1}p-"
					shift
				fi
			fi
		fi
	fi

	SEARCH="$(echo "$*" | sed -e 's/ /+/g')"
	echo "검색 [$SEARCH]"

	# grep -v 제외 문자열
	URL_LIST=""
	for PAGE_NUM in $(eval echo {$PAGE_NUM_START..$PAGE_NUM_END}); do
		URL="${URL_TYPE_ENT_PONG}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_pong $QUALITY $COUNT $URL)
		if [ "${URL_RET}" != "" ]; then
			URL_LIST="$URL_LIST $URL_RET"
		fi

		URL="${URL_TYPE_DRAMA_PONG}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_pong $QUALITY $COUNT $URL)
		if [ "${URL_RET}" != "" ]; then
			URL_LIST="$URL_LIST $URL_RET"
			continue
		fi

		URL="${URL_TYPE_SOCIAL_PONG}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_pong $QUALITY $COUNT $URL)
		if [ "${URL_RET}" != "" ]; then
			URL_LIST="$URL_LIST $URL_RET"
			continue
		fi
	done

	get_magnet_list ${URL_LIST}
}

function download_ent_pong() {
	# download_ent count page_num quality
	local COUNT=100
	local PAGE_MAX_NUM=2
	local QUALITY="720p-NEXT"
	local SEARCH="720p-NEXT"
	local VAR=$1
	
	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_ENT_PONG}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_pong $QUALITY $COUNT $URL)
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"
	done
	get_magnet_list ${URL_LIST}
}

function download_drama_pong() {
	# download_drama count page_num quality
	local COUNT=100
	local PAGE_MAX_NUM=2
	local QUALITY="720p-NEXT"
	local SEARCH="720p-NEXT"
	local VAR=$1
	
	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_DRAMA_PONG}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_pong $QUALITY $COUNT $URL)
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"
	done
	get_magnet_list ${URL_LIST}
}

function download_social_pong() {
	# download_social count page_num quality
	local COUNT=100
	local PAGE_MAX_NUM=2
	local QUALITY="720p-NEXT"
	local SEARCH="720p-NEXT"
	local VAR=$1
	
	if ((VAR > 0)) 2> /dev/null; then
		COUNT=$1
		shift
		VAR=$1
		if ((VAR > 0)) 2> /dev/null; then
			PAGE_MAX_NUM=$1
			shift
			VAR=$1
			if ((VAR > 0)) 2> /dev/null; then
				SEARCH="${1}p-NEXT"
				shift
			fi
		fi
	fi

	URL_LIST=""
	for PAGE_NUM in $(eval echo {1..$PAGE_MAX_NUM}); do
		URL="${URL_TYPE_SOCIAL_PONG}&page=${PAGE_NUM}&stx=${SEARCH}"
		echo SEARCH: $URL
		URL_RET=$(print_magnet_pong $QUALITY $COUNT $URL)
		[ "${URL_RET}" != "" ] && URL_LIST="$URL_LIST $URL_RET"
	done
	get_magnet_list ${URL_LIST}
}
