#!/usr/bin/env bash
@milpa.fail "deprecated"

cd "$(dirname "$MILPA_COMMAND_REPO")/ansible" || @milpa.fail "could not cd into ansible dir"

@milpa.log info "Writing config to vault"
set -o errexit
pipenv run python \
  "$MILPA_COMMAND_REPO/commands/nidito/config/backup.vault.py" \
  "$CONFIG_DIR"/config/*.yaml |
  while read -r line; do
    cpath="${line%% *}"
    json="${line#* }"
    vault kv put "${cpath}" @<(printf '%s' "$json") || @milpa.fail "Could not write $cpath"
  done
set +o errexit
