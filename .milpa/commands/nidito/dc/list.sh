#!/usr/bin/env bash

@milpa.load_util config

@milpa.log info "Listing datacenters from ${MILPA_OPT_SOURCE}"
case "${MILPA_OPT_SOURCE}" in
  local) @milpa.load_util config; @config.names dc ;;
  consul) curl --silent --show-error --fail "$CONSUL_HTTP_ADDR/v1/catalog/datacenters" |
    jq -r '.[]' ;;
esac | sort -n
