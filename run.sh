#!/bin/sh

echo "Current system date: $(date)"
echo "Show Arguments:"
echo "PROGRAM_START_TIME: ${PROGRAM_START_TIME}"
echo "MANUAL_RUN_DATE: ${MANUAL_RUN_DATE}"
echo "RADIO_STATION: ${RADIO_STATION}"
echo "AREA_ID: ${AREA_ID}"
echo "PROGRAM_TITLE: ${PROGRAM_TITLE}"
echo "PROGRAM_DURATION_MIN: ${PROGRAM_DURATION_MIN}"
echo "GDRIVE_FOLDER_ID: ${GDRIVE_FOLDER_ID}"

# MANUAL_RUN_DATE が設定されていればそれを使用、なければ PROGRAM_START_TIME から生成
if [ -n "${MANUAL_RUN_DATE}" ]; then
    EPOCH=$(TZ=Asia/Tokyo date -d "${MANUAL_RUN_DATE} ${PROGRAM_START_TIME}" +%s)
else
    # k8s環境はUTCで動作するので、JSTの現在日付を基準に時刻を計算する
    JST_DATE=$(TZ=Asia/Tokyo date +"%Y-%m-%d")
    echo "JST date: ${JST_DATE}"
    EPOCH=$(TZ=Asia/Tokyo date -d "${JST_DATE} ${PROGRAM_START_TIME}" +%s)
fi

# 番組の終了時間取得
END_DATE_EPOCH=$((EPOCH + PROGRAM_DURATION_MIN * 60))

DATE=$(TZ=Asia/Tokyo date -d "@${EPOCH}" +"%Y%m%d%H%M%S")
END_DATE=$(TZ=Asia/Tokyo date -d "@${END_DATE_EPOCH}" +"%Y%m%d%H%M%S")
echo "Recording date: ${DATE} to ${END_DATE}"

# radiko-downloader.jsでChunkを取得
node radiko-downloader.js ${RADIO_STATION} ${AREA_ID} ${DATE} ${END_DATE}
if [ $? -ne 0 ]; then
    echo "Recording failed. Please check the URL or network connection."
    exit 1
fi

# ffmpegで結合
ffmpeg -fflags +genpts\
  -protocol_whitelist "file,http,https,tcp,tls" \
  -f concat -safe 0 -i ${RADIO_STATION}_${DATE}_${END_DATE}.txt \
  -c:a copy input.m4a

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
gdrive account import gdrive_secret.tar
gdrive files upload --parent ${GDRIVE_FOLDER_ID} --mime audio/mp3 ${FILE_NAME}.m4a 
if [ $? -eq 0 ]; then
    echo "Copy to Google Drive completed successfully."
else
    echo "Failed to copy to Google Drive."
    exit 1
fi