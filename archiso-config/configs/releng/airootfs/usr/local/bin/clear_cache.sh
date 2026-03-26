#!/bin/bash
# تنظيف ذاكرة الكاش تلقائياً عند زيادة الحمل

MAX_RAM_USAGE=85

while true; do
  RAM_USAGE=$(free | awk '/Mem/{printf("%.0f"), $3/$2*100}')
  if [ "$RAM_USAGE" -ge "$MAX_RAM_USAGE" ]; then
    sync
    echo 3 > /proc/sys/vm/drop_caches
  fi
  sleep 60
done
