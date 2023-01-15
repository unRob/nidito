#!/usr/bin/env bash

case "$MILPA_OPT_SOURCE" in
  vault)
    vault kv list -format json "config/vaults/$NIDITO_OP_VAULT/items" | jq -r 'map(split(" ") | first)[]'
  ;;
  files)
    @milpa.load_util config
    @config.all_files | sed "s|$(@config.dir)/||"
  ;;
  names)
    @milpa.load_util config
    @config.all_names
  ;;
  op)
    @milpa.load_util config
    @config.remote_items
  ;;
  *) @milpa.fail "Unknown source $MILPA_OPT_SOURCE"
esac
