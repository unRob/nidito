#!/usr/bin/env bash

set -o nounset
set -o errexit

self="$0"
digest=$(openssl dgst -sha1 "$self")
export PROCESSING_HASH="${digest##* }"
DST="$SOURCE/processed"

log () {
  echo "$(date) - $*"
}


if [[ ! -f "$SOURCE/db.sqlite" ]]; then
  log "Initializing database"
  sqlite3 -batch -cmd '.echo on' -init local/database-init.sql "$SOURCE/db.sqlite" <<<""
fi


log "Started processing with hash $PROCESSING_HASH"

function tz_for_date() {
  if [[ "${1%%-*}" -gt 2020 ]]; then
    echo "America/Mexico_City"
  else
    echo "America/New_York"
  fi
}

function formatted_date() {
  TZ="$(tz_for_date "$1")" LC_ALL="es_MX.UTF-8" date --date "$1" "+$2"
}


function db() {
  sqlite3 -bail "${@}" "$SOURCE/db.sqlite"
}

function already_processed () {
   db <<SQL
select count(timestamp) == 1 from tracks where timestamp="$1" and processing_hash="$PROCESSING_HASH";
SQL
}

function track_number () {
  db <<SQL
  select count(timestamp) + 1 from tracks where album == "$1" and strftime("%s", timestamp) < strftime("%s", "$2");
SQL
}

mkdir -p "$DST"
find "$SOURCE" -name '*.mp3' -maxdepth 1 | while read -r mp3; do
  fname="$(basename "${mp3%.*}")"
  time=${fname:11:8}
  date="${fname:0:10}T${time//-/:}+0000"
  timestamp="$(date -u --date="$date" "+%Y-%m-%dT%H:%M:%SZ")"

  [[ $(already_processed "$timestamp") == "1" ]] && continue

  log "processing $mp3"

  name="${fname:20}"

  title="$(formatted_date "$date" '%A %d, %I:%M')$(date -d "$date" "+%P")"
  metadata=(
    ";FFMETADATA1"
    "year=$(formatted_date "$date" '%Y')"
  )
  if [[ "$name" == practicando.* ]]; then
    instrument="${name##practicando.}"
    album=$(formatted_date "$date" '%B %Y')
    artist="Roberto Hidalgo"
    genre="Practicando $instrument"
  elif [[ "$name" == presenta.* ]]; then
    artist="${name##presenta.}"
    album="RN presenta: $artist"
    genre='Radio Nidito'
  fi

  metadata+=(
    "track=$(track_number "$album" "$timestamp")"
  )

  metadata+=(
    "title=$title"
    "album=$album"
    "artist=$artist"
    "genre=$genre"
  )

  log "writing metadata" "${metadata[@]}"
  ffmpeg -nostdin -nostats -loglevel warning \
    -y \
    -i "$mp3" \
    -i <(printf '%s\n' "${metadata[@]}") \
    -map_metadata 1 \
    -write_id3v2 1 \
    -codec copy \
    "$DST/$fname.mp3"

  if [[ ! -f "$DST/$fname.png" ]]; then
    log "generating waveforms"
    ffmpeg -nostdin -nostats -loglevel warning \
      -i "$DST/$fname.mp3" \
      -filter_complex "compand,showwavespic=s=1280x480:split_channels=1:colors=#ff0051|#ae27ecaa" \
      -frames:v 1 \
      -f apng "pipe:1" |
        convert -crop 100%x50% +repage - tmp.png &&
        convert tmp-0.png tmp-1.png -compose overlay \
          -composite "$DST/$fname.png"
  fi

  log "recording metadata"
  db <<SQL
INSERT INTO tracks(
  timestamp, title, album, artist, genre, timezone, path, processing_hash
)
VALUES(
  '$timestamp',
  '${title//'/\\'}',
  '$album',
  '$artist',
  '$genre',
  '$(tz_for_date "$date")',
  '$fname.mp3',
  '$PROCESSING_HASH'
)
ON CONFLICT(timestamp) DO UPDATE SET
  title=excluded.title,
  album=excluded.album,
  artist=excluded.artist,
  genre=excluded.genre,
  timezone=excluded.timezone,
  path=excluded.path,
  processing_hash=excluded.processing_hash;
SQL

  # rm tmp*.png
done

function tracks_to_psv () {
  db -cmd ".mode list" -cmd ".headers on" <<SQL
  SELECT timestamp, timezone, title, album, artist, genre, path
  FROM tracks
  ORDER BY timestamp DESC;
SQL
}

jq -c --slurp --raw-input '
def objectify(headers):
  def tonumberq: tonumber? // .;
  def trimq: if type == "string" then sub("^ +";"") | sub(" +$";"") else . end;
  def tonullq: if . == "" then null else . end;
  . as $in
  | reduce range(0; headers|length) as $i
      ({}; .[headers[$i]] = ($in[$i] | trimq | tonumberq | tonullq) );

def csv2jsonHelper:
  .[0] as $headers
  | reduce (.[1:][] | select(length > 0) ) as $row
      ([]; . + [ $row|objectify($headers) ]);

sub("\n$";"") | split("\n") | map(split("|")) | csv2jsonHelper' <(tracks_to_psv) > "$SOURCE/tracks.json"

log "Completed processing"
