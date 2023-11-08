#!/usr/bin/env bash
@milpa.load_util garage tmp

@tmp.file status
# https://garagehq.deuxfleurs.fr/api/garage-admin-v0.html#tag/Nodes/operation/GetNodes
# shellcheck disable=2154
@garage.curl status > "$status"

function jqs() {
  jq -r "$1" "$status"
}

cat <<EOF
Garage $(jqs '.garageVersion') (rust v$(jqs .rustVersion))
Enabled features: $(jqs '.garageFeatures | join(",")' ))
Nodes for layout version $(jqs .layout.version)

EOF

jq -r '
  .layout.roles as $roles |
  (
    .knownNodes |
    map(
      .id as $id |
      (
        . + ($roles[] | select(.id == $id))
      ) |
      [.id, .hostname, .addr, .isUp, .zone, (.capacity/1024/1024/1024), (.tags | join(","))]
    )
  ) |
  ["id", "hostname", "addr", "up", "zone", "capacity", "tags"],
  (sort_by(.[2]))[] |
  @tsv
  ' "$status" | column -t
