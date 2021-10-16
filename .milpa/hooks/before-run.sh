#!/usr/bin/env bash

NIDITO_ROOT="$(dirname "$MILPA_COMMAND_REPO")"
export CONSUL_HTTP_ADDR="https://consul.service.consul:5554"
export NOMAD_ADDR="https://nomad.service.consul:5560"
export VAULT_ADDR="${VAULT_ADDR:-https://vault.service.consul:5570}"
export CONFIG_FILE="$NIDITO_ROOT/config.yml"

@milpa.load_util "config"
