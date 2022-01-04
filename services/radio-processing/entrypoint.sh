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

function date_es_mx() {
  LANG=es_MX.UTF-8 LANGUAGE=es_MX.UTF-8 LC_ALL=es_MX.UTF-8 date "${@}"
}

function tz_for_date() {
  if [[ "${1%%-*}" -gt 2020 ]]; then
    echo "America/Mexico_City"
  else
    echo "America/New_York"
  fi
}

function formatted_date() {
  TZ="$(tz_for_date "$1")" date_es_mx --date "$1" "+$2"
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

function track_hash () {
  # openssl sometimes adds a prefix to stuff for reasons
  openssl dgst -sha1 -binary <<<"$1" | xxd -p
}

function hash_matches () {
  local timestamp given_hash current
  timestamp="$1"
  given_hash="$2"
  current=$(db <<<"SELECT COUNT(timestamp) FROM tracks WHERE timestamp='$timestamp' AND track_hash='$given_hash'")
  if [[ "$current" == "1" ]]; then
    return
  fi

  current=$(db -column <<<"SELECT track_hash FROM tracks WHERE timestamp='$timestamp'")
  if [[ "$current" != "" ]]; then
    log "hash didn't match for $timestamp, wanted $given_hash, found $current"
  fi
  return 2
}

function migrate_db () {
  log "Running db migration"
  if !db <<<"SELECT track_hash FROM tracks LIMIT 1;" 2>/dev/null; then
    log "adding track_hash column"
    db <<<"ALTER TABLE tracks ADD COLUMN track_hash VARCHAR(255);"
  fi

  # db -column <<<"SELECT timestamp, track_hash, title || ':-:' || album || ':-:' || artist || ':-:' || genre || ':-:' || channels || ':-:' || duration || ':-:' || bit_rate from tracks;" | while read -r timestamp existing_hash hash_material; do
  #   new_hash="$(track_hash "$hash_material")"
  #   if [[ "$new_hash" == "$existing_hash" ]]; then
  #     continue
  #   fi

  #   log "recording hash for track $timestamp: $new_hash (was $existing_hash) $hash_material"
  #   db <<<"UPDATE tracks SET track_hash='$new_hash' WHERE timestamp='$timestamp';"
  # done
  log "db migration complete"
}

migrate_db

mkdir -p "$DST"
find "$SOURCE" -name '*.mp3' -maxdepth 1 | while read -r mp3; do
  fname="$(basename "${mp3%.*}")"
  time=${fname:11:8}
  date="${fname:0:10}T${time//-/:}+0000"
  timestamp="$(date -u --date="$date" "+%Y-%m-%dT%H:%M:%SZ")"

  if [[ $(already_processed "$timestamp") == "1" ]]; then
    log "Skipping processing for $mp3"
    log "--------------"
    continue
  fi

  log "processing $mp3"

  name="${fname:20}"

  title="$(formatted_date "$date" '%A %d, %I:%M')$(formatted_date "$date" "%P")"
  if [[ "$name" == practicando.* ]]; then
    instrument="${name##practicando.}"
    album=$(formatted_date "$date" '%B %Y')
    artist="Roberto Hidalgo"
    genre="Practicando $instrument"
  elif [[ "$name" == presenta.* ]]; then
    artist="${name##presenta.}"
    if [[ "$artist" == "ruiditos" ]]; then
      artist="Orquesta Filarmónica de Ruidos Improvisados"
      album="Ruiditos $(formatted_date "$date" '%B %Y')"
      genre="Ruiditos"
    else
      album="RN presenta: $artist"
      genre='Radio Nidito'
    fi
  fi

  metadata=(
    ";FFMETADATA1"
    "year=$(formatted_date "$date" '%Y')"
    "track=$(track_number "$album" "$timestamp")"
    "title=$title"
    "album=$album"
    "artist=$artist"
    "genre=$genre"
  )

  channels=0
  duration=0
  bit_rate=0

  while read -r line; do
    value="${line##*=}"
    case "${line%%=*}" in
      channels) channels="$value" ;;
      duration) duration="$value" ;;
      bit_rate) bit_rate="$value" ;;
    esac
  done < <(ffprobe -i "$mp3" -show_streams -loglevel error | grep -E '^(channels|duration|bit_rate)=')

  hash_material="${title}:-:${album}:-:${artist}:-:${genre}:-:${channels}:-:${duration}:-:${bit_rate}"
  current_hash="$(track_hash $hash_material)"

  if hash_matches "$timestamp" "$current_hash"; then
    log "metadata remains the same, no processing needed for $mp3"
    log "$current_hash from $hash_material"
    log "--------------"
    continue
  fi
  log "metadata update needed for $mp3 ($current_hash from $hash_material)"

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
      -f apng channels.png
    if [[ "$channels" -gt 1 ]]; then
      convert -crop 100%x50% +repage channels.png tmp.png &&
      convert tmp-0.png tmp-1.png -compose overlay -composite "$DST/$fname.png"
      rm -rf tmp*.png channels.png
    else
      mv "channels.png" "$DST/${fname}.png"
    fi
  fi

  log "recording metadata"
  db <<SQL
INSERT INTO tracks(
  timestamp, title, album, artist, genre, timezone, channels, duration, bit_rate, path, processing_hash, track_hash
)
VALUES(
  '$timestamp',
  '${title//'/\\'}',
  '$album',
  '$artist',
  '$genre',
  '$(tz_for_date "$date")',
  $channels,
  $duration,
  $bit_rate,
  '$fname.mp3',
  '$PROCESSING_HASH',
  '$current_hash'
)
ON CONFLICT(timestamp, track_hash) DO UPDATE SET
  title=excluded.title,
  album=excluded.album,
  artist=excluded.artist,
  genre=excluded.genre,
  timezone=excluded.timezone,
  path=excluded.path,
  channels=excluded.channels,
  duration=excluded.duration,
  bit_rate=excluded.bit_rate,
  processing_hash=excluded.processing_hash,
  track_hash=excluded.track_hash;
SQL

  log "track processing complete: $mp3"
  log "--------------"
done

function tracks_to_psv () {
  db -cmd ".mode list" -cmd ".headers on" <<SQL
  SELECT timestamp, timezone, title, album, artist, genre, path, channels, duration, bit_rate
  FROM tracks
  ORDER BY timestamp DESC;
SQL
}

log "rendering db into json"
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

log "mirroring to cdn"
mc mirror --overwrite --remove "${DST}" cdn/cdn.rob.mx/ruiditos
mc cp --attr Cache-Control=no-cache "$SOURCE/tracks.json" cdn/cdn.rob.mx/ruiditos/tracks.json
mc policy set download cdn/cdn.rob.mx/ruiditos

log "Completed processing"
