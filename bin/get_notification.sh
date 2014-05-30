#!/bin/bash

APP_HOME=~/apps/jeju_early_bird
DATA_DIR=$APP_HOME/data
LOG_DIR=$APP_HOME/log
SCRIPT_DIR=$APP_HOME/bin

NOTI_FILE=notification.txt
CURRENT_NOTI_FILE=current_notification.txt
NEW_NOTI_FILE=new_notification.txt

URL="http://www.jejuair.net/jejuair/ko_KR/storyjejuair/news_notice_list.jsp"
date=$(date "+[%Y-%m-%d %H:%M:%S]")

MAIL_LIST="helloyako@gmail.com"

function send_mail
{
	local body=$1
	local title=$2

	for mail in $MAIL_LIST
	do
		echo -e "${body}" | mail -s "${title}" $mail
	done
}

if [ ! -d ${DATA_DIR} ]; then
mkdir -p ${DATA_DIR}
fi

cd $DATA_DIR

echo -e "\n\n\n${date} crawling jeju air notification...\n"
curl "${URL}" | perl -ne 'if(/<td class=\"title\"><a.+>(.+)<\/a><\/td>/){printf("%s\n", $1);}' > ${CURRENT_NOTI_FILE} 

echo -e "\n\n##### jeju air notify #####\n\n"
cat $CURRENT_NOTI_FILE
echo -e "\n\n##### jeju air notify #####\n\n"

noti_temp_line_num=$(wc -l ${CURRENT_NOTI_FILE} | cut -f1 -d" ")

if [ "$noti_temp_line_num" -ne 10 ]; then
	echo "##### error!! get notification #####"
	body="공지사항 개수가 10개가 아닙니다.\n제주항공 공지사항 변경이 있거나 정규식이 잘못되었습니다."
	title="제주항공 공지 실패"
	send_mail "${body}" "${title}"
	echo "send_mail ${body} ${title}"
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
	    body="제주항공 얼리버드 공지추가.\n\n\n"
		body=${body}${early_noti}
		body=${body}"\n\n${URL}"
    	title="제주항공 얼리버드 공지"
	    send_mail "${body}" "${title}"
	    echo -e "send_mail\n제목 : ${title}\n본문 : ${body}"
	fi
fi

rm -rf $NEW_NOTI_FILE
rm -rf $CURRENT_NOTI_FILE

