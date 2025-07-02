#!/bin/sh

# TEST_DATE が設定されていればそれを使用、なければ PROGRAM_START_TIME から生成
if [ -n "${TEST_DATE}" ]; then
    DATE=${TEST_DATE}
else
    DATE=$(date -d "${PROGRAM_START_TIME}" +"%Y%m%d%H%M%S")
fi

echo "Recording date: ${DATE}"
./rec_radiko_ts.sh -u https://radiko.jp/#!/ts/${RADIO_STATION}/${DATE} -o ${FILE_NAME_PREFIX}_${DATE}
if [ $? -ne 0 ]; then
    echo "Recording failed. Please check the URL or network connection."
    exit 1
fi

echo "Recording completed. Now copying to Google Drive..."
rclone copy ${FILE_NAME_PREFIX}_${DATE}.m4a drive:
if [ $? -eq 0 ]; then
    echo "Copy to Google Drive completed successfully."
else
    echo "Failed to copy to Google Drive."
    exit 1
fi