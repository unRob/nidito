#!/usr/bin/env bash

export TARGET="${TARGET:-./tmp}"

function fail () {
  >&2 echo "$*"
  exit 2
}

downloaded=0

function downloadMedia() {
  local kind; kind="$1"

  while read -r file; do
    echo "Downloading $file"
    rclone copy "putio:$file" "$kind/" >&2 || fail "Could not download $file"
    downloaded=$(( downloaded + 1 ))
    echo "Deleting $file"
    rclone delete "putio:$file" >&2
    if [[ "$(dirname "${file#*/}")" != "." ]]; then
      dirname "$file" >> tmp/purge.list
    fi
  done < "tmp/$kind.list"
}

cd "$TARGET" || fail "Failed to read $TARGET"
echo "Syncing to $TARGET"

rm -rf tmp
mkdir -p {tmp,tv-series,movies}
touch tmp/purge.list

set -o pipefail
if ! rclone lsjson -R "putio:" |
  jq -r "map(select(.MimeType | contains(\"video\")) | .Path) | .[]" |
  sort -n > tmp/source.list; then
  exit 2
fi
grep -E -i '(S[0-9][0-9]|HDTV)' tmp/source.list > tmp/tv-series.list
grep -E -vi '(S[0-9][0-9]|HDTV)' tmp/source.list > tmp/movies.list

echo "TV Series:"
cat tmp/tv-series.list
echo "----"

echo "Movies:"
cat tmp/movies.list
echo "----"

downloadMedia tv-series || fail "Could not download tv-series"
downloadMedia movies || fail "Could not download movies"
echo "Downloading complete"

if [ -s tmp/purge.list ]; then
  echo "Purging directories:"
  sort -n tmp/purge.list |
    uniq |
    tee |
    while read -r dir; do rclone purge "putio:$dir"; done
fi

rm -rf tmp
echo "Sync complete"

if [[ "$downloaded" -gt 0 ]]; then
  echo "Dispatching tv-renamer"
  set -o xtrace
  curl \
    -XPOST https://nomad.nidi.to/v1/job/tv-renamer/dispatch --data "{}"
fi
