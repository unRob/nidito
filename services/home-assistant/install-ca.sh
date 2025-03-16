#!/bin/bash
dst=/etc/ssl/certs/nidito.pem
cat >"$dst" <<PEM
{{ with secret "cfg/infra/tree/service:ca" }}{{ .Data.cert }}{{ end }}
PEM

if ! grep -q -f <(grep -v '^-' "$dst") /etc/ssl/certs/ca-certificates.crt; then
  cat "$dst" >> /etc/ssl/certs/ca-certificates.crt
  echo "nidito CA installed to system cert store" >&2
fi
