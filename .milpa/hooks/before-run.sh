#!/usr/bin/env bash

NIDITO_ROOT="$(dirname "$MILPA_COMMAND_REPO")"
export CONSUL_HTTP_ADDR="http://consul.service.consul:5555"
export NOMAD_ADDR="http://nomad.service.consul:5560"
export VAULT_ADDR="http://vault.service.consul:5570"
export CONFIG_FILE="$NIDITO_ROOT/config.yml"

@milpa.load_util "config"
