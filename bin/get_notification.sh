#!/bin/bash

APP_HOME=~/apps/jeju_early_bird
DATA_DIR=$APP_HOME/data
LOG_DIR=$APP_HOME/log
SCRIPT_DIR=$APP_HOME/bin

NOTI_FILE=notification.txt
CURRENT_NOTI_FILE=current_notification.txt
NEW_NOTI_FILE=new_notification.txt

URL="http://www.jejuair.net/jejuair/com/jeju/ibe/news/event/event_list.do"
date=$(date "+[%Y-%m-%d %H:%M:%S]")
year_month=$(date "+%Y-%m")

NOTI_MAIL_LIST="helloyako@gmail.com"
ADMIN_MAIL_LIST="helloyako@gmail.com"

function send_mail
{
	local body=$1
	local title=$2
	local mail_list=$3
	for mail in $mail_list
	do
		echo -e "${body}" | mail -s "${title}" $mail
	done
}

if [ ! -d ${DATA_DIR} ]; then
mkdir -p ${DATA_DIR}
fi

cd $DATA_DIR


echo -e "\n\n\n${date} crawling jeju air notification...\n"

if [ -a ${year_month} ]; then
	echo -e "${year_month} exist!\n"
	exit -1
fi

curl "${URL}" > temp.txt
curl_return_code=$?

if [ "$curl_return_code" != 0 ]; then
	echo "##### error!! curl fail! #####"
	body="curl 호출 실패.\n에러코드 $curl_return_code"
    title="curl 호출 실패"
    send_mail "${body}" "${title}" "${ADMIN_MAIL_LIST}"
    echo "send_mail ${body} ${title} ${ADMIN_MAIL_LIST}"
    exit -1
fi

cat temp.txt | perl -ne 'if(/<td class=\"subj\"><a.+>(.+)<\/a><\/td>/){printf("%s\n", $1);}' > ${CURRENT_NOTI_FILE} 
rm -rf temp.txt

echo -e "\n\n##### jeju air notify #####\n\n"
cat $CURRENT_NOTI_FILE
echo -e "\n\n##### jeju air notify #####\n\n"

noti_temp_line_num=$(wc -l ${CURRENT_NOTI_FILE} | cut -f1 -d" ")

if [ "$noti_temp_line_num" -lt 5 ]; then
	echo "##### error!! get notification #####"
	body="공지사항 개수가 5개보다 작습니다. \n제주항공 진행중 페이지 변경이 있거나 정규식이 잘못되었습니다."
	title="제주항공 공지 실패"
	send_mail "${body}" "${title}" "${ADMIN_MAIL_LIST}"
	echo "send_mail ${body} ${title} ${ADMIN_MAIL_LIST}"
	exit -1
fi

if [ -f $NOTI_FILE ]; then
	noti_line_num=$(wc -l ${NOTI_FILE} | cut -f1 -d" ")
	temp_line_count=0;	
	while read temp_line; do
		unmatched_count=0;	
		while read line; do
			if [ "$temp_line" = "$line" ]; then
				break
			else
				unmatched_count=$(($unmatched_count + 1));	
			fi
		done < $NOTI_FILE
		if [ "$noti_line_num" -eq "$unmatched_count" ]; then
			echo $temp_line >> $NEW_NOTI_FILE
		fi
	done < $CURRENT_NOTI_FILE
else
	cat $CURRENT_NOTI_FILE > $NOTI_FILE
	cat $CURRENT_NOTI_FILE > $NEW_NOTI_FILE
fi

if [ -f $NEW_NOTI_FILE ]; then
	echo "##### exist new notification ####"
	cat $CURRENT_NOTI_FILE > $NOTI_FILE
	early_noti=$(cat $NEW_NOTI_FILE | perl -pe 's/ //g' | grep -Ei "(얼리버드|early)")
	if [ "$?" == 0 ]; then
		echo "##### exist early bird notification!!! #####"
		touch ${year_month}
	    body="제주항공 얼리버드 공지추가.\n\n\n"
		body=${body}${early_noti}
		body=${body}"\n\n${URL}"
    	title="제주항공 얼리버드 공지"
	    send_mail "${body}" "${title}" "${NOTI_MAIL_LIST}"
	    echo -e "send_mail\n제목 : ${title}\n본문 : ${body}"
	fi
fi

rm -rf $NEW_NOTI_FILE
rm -rf $CURRENT_NOTI_FILE

