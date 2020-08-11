#!/usr/bin/env sh
exec 1>/home/icecast/mirror.log 2>&1
source /home/icecast/minio-env.sh
echo "----------------------------"
date
echo "Mirroring files"
ls -lah /recordings

sleep 5
ls -lah /recordings

if mc --config-dir /home/icecast mirror /recordings/ cajon/ruiditos; then
  echo "Mirror complete"
  rm -rfv /recordings/*.mp3
else
  echo "MC crapped its pants"
fi
