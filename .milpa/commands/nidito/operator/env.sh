#!/usr/bin/env bash

@milpa.load_util "shell"
eval "$(op signin --account boveda --session "${OP_SESSION_boveda:-}")"

@milpa.shell.export NIDITO_ROOT "$NIDITO_ROOT"
@milpa.shell.export CONSUL_HTTP_ADDR "$CONSUL_HTTP_ADDR"
@milpa.shell.export NOMAD_ADDR "$NOMAD_ADDR"
@milpa.shell.export VAULT_ADDR "$VAULT_ADDR"
@milpa.shell.export CONSUL_HTTP_TOKEN "$(milpa creds consul.nidi.to)"
@milpa.shell.export VAULT_TOKEN "$(milpa creds "vault root")"
