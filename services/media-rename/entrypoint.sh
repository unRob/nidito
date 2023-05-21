#!/usr/bin/env sh

if [ -n "$(ls -A /media/dropbox/tv-series)" ]; then
  echo "renaming tv-series"
  mnamer /media/dropbox/tv-series || exit 2
else
  echo "no tv series to process"
fi

if [ -n "$(ls -A /media/dropbox/movies)" ]; then
  echo "renaming movies"
  mnamer /media/dropbox/movies || exit 2
else
  echo "no movies to process"
fi
