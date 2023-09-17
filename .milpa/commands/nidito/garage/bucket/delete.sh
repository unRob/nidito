#!/usr/bin/env bash
@milpa.load_util garage

bucket_id="$(milpa nidito garage bucket info "$MILPA_ARG_BUCKET" | jq -r .id)" || @milpa.fail "Could not resolve bucket id for bucket named $MILPA_ARG_BUCKET"
@garage.curl "bucket?id=$bucket_id" -XDELETE

@milpa.log complete "Deleted bucket $MILPA_ARG_BUCKET ($bucket_id)"
