#!/usr/bin/env bash
# data is in the nsupdate format
# requires jq!
#
function _log() {
  echo "$@" | tee -a /config/dyndns.log >&2
}

function find_record_id () {
  local zone; zone="$1"
  # finds the top level A record for zone name
  curl --fail \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    "https://api.digitalocean.com/v2/domains/${zone}/records" |
    jq '.domain_records[] | select(.type=="A" and .name == "@") | .id'
}

function update_ip() {
  local zone record; zone="$1" record="$2"
  curl --fail \
    -H 'Content-type: application/json' \
    -H "Authorization: Bearer $DIGITALOCEAN_TOKEN" \
    -X PUT \
    "https://api.digitalocean.com/v2/domains/${zone}/records/${record}" \
    -d@- <<JSON
{
  "type": "A",
  "data": "$new_ip",
  "name": "@",
  "ttl": 300
}
JSON
}


_log "Starting dns update at $(date -u)"
data=$(cat)
zone="$(awk '/^zone/{sub(/.$/, ""); print $2; exit}' <<<"$data")"
new_ip=$(awk '/^update add/{print $NF; exit}' <<<"$data")
_log "updating to: $zone IN A $new_ip"
# token is supplied as an argument to this script
export DIGITALOCEAN_TOKEN="$2"

_log "looking for record_id for zone $zone"
if record=$(find_record_id "$zone"); then
  _log "found record_id $record for zone $zone"
else
  _log "Could not find record_id for zone $zone!"
  exit 2
fi

_log "Updating record to $new_ip"
if update_ip "$zone" "$record"; then
  _log "update succeeded"
  exit 0
else
  _log "update failed"
  exit 2
fi
