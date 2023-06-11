#!/usr/bin/env bash
@milpa.load_util garage

bucket_id="$(milpa nidito garage bucket info "$MILPA_ARG_BUCKET" | jq -r .id)" || @milpa.fail "Could not resolve bucket id for bucket named $MILPA_ARG_BUCKET"

doc='{"websiteAccess":{"enabled": false}}'
if [[ "$MILPA_ARG_OPERATION" == "enable" ]]; then
  doc=$(jq --null-input '{websiteAccess:{enabled: true, indexDocument: "index.html", errorDocument: "error.html"}}')
fi

@garage.curl "bucket?id=$bucket_id" -XPUT -d "$doc" || @milpa.fail "Could not enable website access"
