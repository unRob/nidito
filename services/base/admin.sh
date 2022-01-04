#!/bin/env bash

curl --silent --show-error -L https://cajon.nidi.to/tls/casa.pem >> /etc/ssl/certs/ca-certificates.crt

export CONSUL_HTTP_ADDR="https://consul.service.consul:5554"
export NIDITO_DC="${NIDITO_DC:-casa}"
export NOMAD_ADDR="https://nomad.service.$NIDITO_DC.consul:5560"
export VAULT_ADDR="https://vault.service.$NIDITO_DC.consul:5570"

function switch_dc () {
  NIDITO_DC="$1"
  NOMAD_ADDR="https://nomad.service.$NIDITO_DC.consul:5560"
  VAULT_ADDR="https://vault.service.$NIDITO_DC.consul:5570"
}

function nomad () {
  endpoint="$1"; shift
  headers=()
  if [[ $NOMAD_TOKEN ]]; then
    headers+=( "-H" "X-Nomad-Token: $NOMAD_TOKEN" )
  fi
  curl "${headers[@]}" "$NOMAD_ADDR/v1/$endpoint" ${*}
}
