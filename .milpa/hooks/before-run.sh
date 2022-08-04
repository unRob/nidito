#!/usr/bin/env bash

if [[ "$NIDITO_ROOT" == "" ]]; then
  NIDITO_ROOT="$(dirname "$(readlink -f "$MILPA_COMMAND_REPO")")"
  export NIDITO_ROOT
fi

if [[ "$NIDITO_OP_VAULT" == "" ]]; then
  NIDITO_OP_VAULT="nidito-admin"
  export NIDITO_OP_VAULT
fi

export CONFIG_DIR="$NIDITO_ROOT/config"
export CONSUL_HTTP_ADDR="https://consul.service.consul:5554"
export NOMAD_ADDR="https://nomad.service.consul:5560"
export VAULT_ADDR="${VAULT_ADDR:-https://vault.service.consul:5570}"

function at_root () {
  cd "$NIDITO_ROOT/$1" || @milpa.fail "Could not cd into $1"
}
