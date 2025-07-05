#!/bin/sh

# TEST_DATE が設定されていればそれを使用、なければ PROGRAM_START_TIME から生成
if [ -n "${TEST_DATE}" ]; then
    EPOCH=$(date -u -d "${TEST_DATE} ${PROGRAM_START_TIME}" +%s)
else
    # k8s環境はUTCで動作するので+9時間の補正をかける
    EPOCH=$(date -u -d ${PROGRAM_START_TIME} +"%s")
fi

DATE=$(TZ=Asia/Tokyo date -d "@${EPOCH}" +"%Y%m%d%H%M%S")
echo "Recording date: ${DATE}"
./rec_radiko_ts.sh -u https://radiko.jp/#!/ts/${RADIO_STATION}/${DATE} -o input
if [ $? -ne 0 ]; then
    echo "Recording failed. Please check the URL or network connection."
    exit 1
fi

#時刻表取得用の文字列を取得
HOURMIN=$(echo "${DATE}" | cut -c9-12)
echo "Hour and minute: ${HOURMIN}"
#00:00開始の番組は前日の番組表に含まれる
if [ "${HOURMIN}" = "0000" ]; then
    XMLDATE=$(TZ=Asia/Tokyo date -d "@$((EPOCH - 86400))" +"%Y%m%d")
else
    XMLDATE=$(TZ=Asia/Tokyo date -d "@${EPOCH}" +"%Y%m%d")
fi
echo "XML date for timetable: ${XMLDATE}"

#時刻表の取得 → タイトルと出演者の取得
wget https://radiko.jp/v3/program/station/date/${XMLDATE}/${RADIO_STATION}.xml
TITLE=$(xmllint --xpath "string(//prog[contains(title, \"${PROGRAM_TITLE}\")]/title)" "${RADIO_STATION}.xml")
PERFORMER=$(xmllint --xpath "string(//prog[contains(title, \"${PROGRAM_TITLE}\")]/pfm)" "${RADIO_STATION}.xml")
echo "Title: ${TITLE}"
echo "Performer: ${PERFORMER}"

FILE_NAME="${FILE_NAME_PREFIX}_$(TZ=Asia/Tokyo date -d "@${EPOCH}" +"%Y%m%d_%H%M")"
echo "File name: ${FILE_NAME}"
echo "Converting to m4a format..."
ffmpeg -i input.m4a \
    -metadata title="$(TZ=Asia/Tokyo date -d "@${EPOCH}" +"%Y-%m-%d") ${PERFORMER}" \
    -metadata artist="${PERFORMER}" \
    -metadata album="${PROGRAM_TITLE}" \
    -metadata date="${XMLDATE}" \
    -codec copy ${FILE_NAME}.m4a
if [ $? -eq 0 ]; then
    echo "Conversion to m4a format completed successfully."
else
    echo "Failed to convert to m4a format."
    exit 1
fi

echo "Recording completed. Now copying to Google Drive..."
rclone copy ${FILE_NAME}.m4a drive:
if [ $? -eq 0 ]; then
    echo "Copy to Google Drive completed successfully."
else
    echo "Failed to copy to Google Drive."
    exit 1
fi