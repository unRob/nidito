#!/usr/bin/env bash

find "$SOURCE" -name '*.mp3' | while read -r mp3; do
  [[ -f "${mp3//.mp3/.png}" ]] && continue

  ffmpeg -nostdin \
    -i "$mp3" \
    -filter_complex "compand,showwavespic=s=1280x480:split_channels=1:colors=#ff0051|#ae27ecaa" \
    -frames:v 1 \
    -f apng "pipe:1" |
    convert -crop 100%x50% +repage - tmp.png
    convert tmp-0.png tmp-1.png -compose overlay -composite "${mp3//.mp3/.png}"
    rm tmp*.png
done
