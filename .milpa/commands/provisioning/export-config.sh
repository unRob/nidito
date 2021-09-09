#!/usr/bin/env bash

cd "$(dirname "$MILPA_COMMAND_REPO")/ansible" || @milpa.fail "could not cd into ansible dir"

pipenv run python "$MILPA_COMMAND_REPO/commands/provisioning/export-config.py" ../config/*.yaml |
  while read -r line; do
    cpath="${line%% *}"
    json="${line#* }"
    vault kv put "${cpath}" @<(printf '%s' "$json") || @milpa.fail "Could not write $cpath"
  done
