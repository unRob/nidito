#!/usr/bin/env sh
{{- with secret "nidito/config/services/dns" }}
{{- scratch.Set "zone" .Data.zone }}
{{- end }}
{{- with secret "nidito/config/services/minio" }}
export MC_HOST_cajon="https://{{ .Data.key }}:{{ .Data.secret }}@cajon.{{ scratch.Get "zone" }}/"
{{- end }}
{{- with secret "nidito/config/services/cdn" }}
export MC_HOST_cdn="https://{{ .Data.key }}:{{ .Data.secret }}@{{ .Data.endpoint }}/"
{{- end }}
export MC_CONFIG_DIR="/home/icecast/.mc"
