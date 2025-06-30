#!/bin/sh
if [ "$(date +%u)" -eq 1 ]; then
  # 今日が月曜（曜日=1）なら、今日の00:00
  DATE=$(date -d "00:00" +"%Y%m%d%H%M%S")
else
  # それ以外は直近の月曜00:00
  DATE=$(date -d "last monday 00:00" +"%Y%m%d%H%M%S")
fi

echo "Recording date: ${DATE}"
./rec_radiko_ts.sh -u https://radiko.jp/#!/ts/JORF/${DATE} -o as1422_${DATE}
if [ $? -ne 0 ]; then
    echo "Recording failed. Please check the URL or network connection."
    exit 1
fi

echo "Recording completed. Now copying to Google Drive..."
rclone copy as1422*.m4a drive:
if [ $? -eq 0 ]; then
    echo "Copy to Google Drive completed successfully."
else
    echo "Failed to copy to Google Drive."
    exit 1
fi