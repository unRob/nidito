#!/usr/bin/env sh
{{- with secret "cfg/svc/tree/nidi.to:icecast" }}
export MC_HOST_garage="https://{{ .Data.storage.key }}:{{ .Data.storage.secret }}@{{ .Data.storage.endpoint }}/"
export TARGET_BUCKET="{{ .Data.storage.bucket }}"
{{- end }}
export MC_REGION=garage
export MC_CONFIG_DIR="/home/icecast/.mc"

export NOMAD_TOKEN="$(cat "${NOMAD_SECRETS_DIR:-/secrets}/nomad_token")"
