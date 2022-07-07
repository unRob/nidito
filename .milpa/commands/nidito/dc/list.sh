#!/usr/bin/env bash

@milpa.log info "Listing datacenters from ${MILPA_OPT_SOURCE}"
case "${MILPA_OPT_SOURCE}" in
  config) @configq datacenters '.' 'keys[]' ;;
  consul) curl --silent --show-error --fail "$CONSUL_HTTP_ADDR/v1/catalog/datacenters" |
    jq -r '.[]' ;;
esac | sort -n
