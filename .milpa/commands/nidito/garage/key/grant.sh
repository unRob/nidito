#!/usr/bin/env bash
@milpa.load_util garage

bucket_id="$(milpa nidito garage bucket info "$MILPA_ARG_BUCKET" | jq -r .id)" || @milpa.fail "Could not resolve bucket id for bucket named $MILPA_ARG_BUCKET"
key_id="$(milpa nidito garage key info "$MILPA_ARG_KEY" | jq -r .accessKeyId)" || @milpa.fail "Could not resolve bucket id for bucket named $MILPA_ARG_BUCKET"

@garage.curl "bucket/${MILPA_ARG_OPERATION}" -X POST -d @<(
  jq --null-input \
  --arg "bucket" "$bucket_id" \
  --arg "key" "$key_id" \
  --argjson "owner" "${MILPA_OPT_OWNER:-false}" \
  --argjson "readOnly" "${MILPA_OPT_READ_ONLY:-false}" \
  '{
    bucketId: $bucket,
    accessKeyId: $key,
    permissions: {
      read: true,
      write: ($readOnly | not),
      owner: $owner
    }
  }'
)
