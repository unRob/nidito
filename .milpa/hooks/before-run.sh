#!/usr/bin/env bash

NIDITO_ROOT="$(dirname "$(readlink "$MILPA_COMMAND_REPO")")"
export CONSUL_HTTP_ADDR="https://consul.service.consul:5554"
export NOMAD_ADDR="https://nomad.service.consul:5560"
export VAULT_ADDR="${VAULT_ADDR:-https://vault.service.consul:5570}"
export CONFIG_DIR="$NIDITO_ROOT/config"

@milpa.load_util "config"
