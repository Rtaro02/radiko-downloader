#!/bin/sh
DATE=$(date -d ${PROGRAM_START_TIME} +"%Y%m%d%H%M%S")

echo "Recording date: ${DATE}"
./rec_radiko_ts.sh -u https://radiko.jp/#!/ts/${RADIO_STATION}/${DATE} -o as1422_${DATE}
if [ $? -ne 0 ]; then
    echo "Recording failed. Please check the URL or network connection."
    exit 1
fi

echo "Recording completed. Now copying to Google Drive..."
rclone copy as1422*.m4a drive:
f [ $? -eq 0 ]; then
    echo "Copy to Google Drive completed successfully."
else
    echo "Failed to copy to Google Drive."
    exit 1
fi