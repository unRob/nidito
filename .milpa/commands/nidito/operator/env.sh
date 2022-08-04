#!/usr/bin/env bash

@milpa.load_util "shell"

@milpa.shell.export NIDITO_ROOT "$NIDITO_ROOT"
@milpa.shell.export CONSUL_HTTP_ADDR "$CONSUL_HTTP_ADDR"
@milpa.shell.export NOMAD_ADDR "$NOMAD_ADDR"
@milpa.shell.export VAULT_ADDR "$VAULT_ADDR"
@milpa.shell.export CONSUL_HTTP_TOKEN "$(milpa nidito config get service:consul token)"
@milpa.shell.export VAULT_TOKEN "$(milpa nidito config get "dc:${NIDITO_DC:-casa}" vault.root_token)"

echo "alias nidito='milpa nidito'"
