#!/bin/sh

# TEST_DATE が設定されていればそれを使用、なければ PROGRAM_START_TIME から生成
if [ -n "${TEST_DATE}" ]; then
    DATE=${TEST_DATE}
else
    # k8s環境はUTCで動作するので+9時間の補正をかける
    DATE=$(TZ=Asia/Tokyo date -d ${PROGRAM_START_TIME} +"%Y%m%d%H%M%S")
fi

echo "Recording date: ${DATE}"
FILE_NAME_=${FILE_NAME_PREFIX}_${DATE}
./rec_radiko_ts.sh -u https://radiko.jp/#!/ts/${RADIO_STATION}/${DATE} -o ${FILE_NAME}_input
if [ $? -ne 0 ]; then
    echo "Recording failed. Please check the URL or network connection."
    exit 1
fi

#時刻表取得用の文字列を取得
HOURMIN=$(echo "${DATE}" | cut -c9-12)
if [ "${HOURMIN}" = "0000" ]; then
    XMLDATE=$(date -j -f "%Y%m%d%H%M%S" -v-1d "${DATE}" +"%Y%m%d")
else
    XMLDATE=$(echo "${DATE}" | cut -c1-8)
fi

#時刻表の取得 → タイトルと出演者の取得
wget https://radiko.jp/v3/program/station/date/${XMLDATE}/${RADIO_STATION}.xml
TITLE=$(xmllint --xpath "string(//prog[contains(title, \"${PROGRAM_TITLE}\")]/title)" "${RADIO_STATION}.xml")
PERFORMER=$(xmllint --xpath "string(//prog[contains(title, \"${PROGRAM_TITLE}\")]/pfm)" "${RADIO_STATION}.xml")
ffmpeg -i ${FILE_NAME}_input.mp4 \
    -metadata title="${TITLE}" \
    -metadata artist="${PERFORMER}" \
    -metadata date="${XMLDATE}" \
    -codec copy ${FILE_NAME}.m4a

echo "Recording completed. Now copying to Google Drive..."
rclone copy ${FILE_NAME}.m4a drive:
if [ $? -eq 0 ]; then
    echo "Copy to Google Drive completed successfully."
else
    echo "Failed to copy to Google Drive."
    exit 1
fi