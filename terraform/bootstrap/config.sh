#!/usr/bin/env bash

config="${CONFIG_FILE:-../config.yml}"

set -o nounset
property="$1"
filter="$2"
if [[ "$#" == 3 ]]; then
  config="$1"
  property="$2"
  filter="$3"
fi

echo "filtering .$property of $config" >/dev/stderr
jq "{ data: ( ($filter) | @json) }" <(gcy get "$config" "$property")
