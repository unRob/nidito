#!/usr/bin/env bash

case "$MILPA_OPT_SOURCE" in
  vault)
    vault kv list -format json nidito/config | jq -r 'map(sub("/"; ""))[]'
  ;;
  files)
    @milpa.load_util config
    @config.all_files | sed "s|$(@config.dir)/||"
  ;;
  names)
    @milpa.load_util config
    @config.all_names
  ;;
  *) @milpa.fail "Unknown source $MILPA_OPT_SOURCE"
esac
