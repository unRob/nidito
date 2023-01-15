#!/usr/bin/env sh
{{- with secret "cfg/infra/tree/service:dns" }}
{{- scratch.Set "zone" .Data.zone }}
{{- end }}
{{- with secret "cfg/svc/tree/nidi.to:cajon" }}
export MC_HOST_cajon="https://{{ .Data.key }}:{{ .Data.secret }}@cajon.{{ scratch.Get "zone" }}/"
{{- end }}
export MC_CONFIG_DIR="/home/icecast/.mc"
