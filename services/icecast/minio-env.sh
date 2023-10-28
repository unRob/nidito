#!/usr/bin/env sh
{{- with secret "cfg/svc/tree/nidi.to:cajon" }}
export MC_HOST_cajon="https://{{ .Data.key }}:{{ .Data.secret }}@cajon.{{ env "meta.dns_zone" }}/"
{{- end }}
export MC_CONFIG_DIR="/home/icecast/.mc"

export NOMAD_TOKEN="$(cat "${NOMAD_SECRETS_DIR:-/secrets}/nomad_token")"
