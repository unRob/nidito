#!/usr/bin/env bash
data=$(cat)

token="$2"
record="$(awk '/^server/{print $2; exit}' <<<"$data")"
zone="$(awk '/^zone/{print $2; exit}' <<<"$data")"
new_ip=$(awk '/^update add/{print $NF; exit}' <<<"$data")
echo "Updating record to $new_ip" >> /config/dyndns.log

function update_ip() {
  curl --fail \
    -H 'Content-type: application/json' \
    -H "Authorization: Bearer $token" \
    -X PUT \
    "https://api.digitalocean.com/v2/domains/${zone%.}/records/${record%.*}" \
    -d@- <<JSON
{
  "type": "A",
  "data": "$new_ip",
  "name": "@",
  "ttl": 300
}
JSON
}

if update_ip; then
  echo "okay!"
  exit 0
else
  exit 2
fi
