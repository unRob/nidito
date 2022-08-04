#!/usr/bin/env bash

@milpa.log info "Listing nodes from ${MILPA_OPT_SOURCE}"
case "${MILPA_OPT_SOURCE}" in
  config)
    @milpa.load_util config
    @config.names host ;;
  consul) curl --silent --show-error --fail "$CONSUL_HTTP_ADDR/v1/agent/members?wan=1" |
    jq -r 'map(.Name | split(".") | first)[]' ;;
  pool|available)
    [[ "${MILPA_OPT_SOURCE}" == "pool" ]] && filter='\*\*'
    awk -F':'\
     '/^- '"$filter"'`/ {
       gsub("[`\*]", "", $1); sub("- ", "", $1); print $1
      }' \
     "$NIDITO_ROOT/.milpa/docs/naming-pool.md" ;;
esac | sort -n
