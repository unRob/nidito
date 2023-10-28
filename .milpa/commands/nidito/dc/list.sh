#!/usr/bin/env bash

@milpa.load_util config

@milpa.log info "Listing datacenters from ${MILPA_OPT_SOURCE}"
case "${MILPA_OPT_SOURCE}" in
  local) @config.names dc ;;
  consul) curl --silent --show-error --fail "$CONSUL_HTTP_ADDR/v1/catalog/datacenters" | jq -r '.[]' ;;
esac |
  sort -n | # wrap output in {dcs: []} if asking for json because of terraform. see terraform/tepetl/main.yaml
  jq -r \
    --arg format "$MILPA_OPT_FORMAT" \
    --raw-input --slurp \
    'split("\n") | map(select(. != "")) | if $format == "text" then .[] else {dcs: .} end'
