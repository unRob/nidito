#!/usr/bin/env bash

function latest() {
  curl --fail --silent "https://releases.hashicorp.com/${product}/index.json" |
    jq -r '.versions | map(.version | select(test("^[\\d.]+$"; "i"))) | sort_by(split(".") | map(tonumber)) | last'
}

for product in consul vault nomad; do
  latest="$(latest "$product")"
  current=$(joao get "$NIDITO_ROOT/config/service/$product.yaml" version)

  if [[ "$latest" == "$current" ]]; then
    @milpa.log success "$product is up to date at v$latest"
    continue
  fi

  @milpa.log warning "$product has an update: $current => $latest"
  curl --fail --silent "https://raw.githubusercontent.com/hashicorp/${product}/main/CHANGELOG.md" |
    awk '1;/^## .*/{if (NR>1) exit}' |
    sed \$d |
    glow -
done
