#!/usr/bin/env bash
dir="$(pwd)"

svcfolder="${dir%%/services*}/services"
if [[ -d "$svcfolder" ]]; then
  echo "$svcfolder"
  exit
fi

curr="$dir"
while [[ "$curr" != "/" ]]; do
  curr="$(dirname "$curr")"
  if [[ -d "$curr/services" ]]; then
    echo "$curr/services"
    exit
  fi
done

echo "$dir"
