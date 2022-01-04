#!/bin/sh
{{ range secrets "nidito/tls/" }}
{{ $hostname := . }}
{{ if not (in $hostname "/") }}
mkdir -p /ssl/{{ $hostname }}
{{ with secret (printf "nidito/tls/%s" . ) }}
cat >/ssl/{{ $hostname }}/key.pem <<PEM
{{ .Data.private_key }}
PEM

cat >/ssl/{{ $hostname }}/cert.pem <<PEM
{{ .Data.cert }}
PEM
{{ end }}
{{ end }}
{{ end }}
