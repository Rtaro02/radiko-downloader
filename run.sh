#!/bin/sh
DATE=$(date -d "last monday 00:00" +"%Y%m%d%H%M%S")
./rec_radiko_ts.sh -u https://radiko.jp/#!/ts/JORF/${DATE} -o as1422_${DATE}
rclone copy as1422*.m4a drive: