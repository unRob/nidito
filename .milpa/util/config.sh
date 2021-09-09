#!/usr/bin/env bash

CONFIG_DIR="${NIDITO_ROOT}/config"
export CONFIG_DIR

function @config() {
  gcy get "$CONFIG_DIR/$1.yaml" "$2"
}

function @configq () {
  local filter
  filter=.

  if [[ "$2" == "." ]]; then
    filter="del(.crypto)"
  fi

  if [[ "$3" != "" ]]; then
    filter="$filter | $3"
  fi

  @config "$1" "$2" | jq -r "$filter"
}
