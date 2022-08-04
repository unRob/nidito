#!/usr/bin/env bash

vault_id=$(milpa op vault-id) || @milpa.fail "Could not get vault id"

filter="title co \"${MILPA_ARG_FILTER[@]}\""

@milpa.log info "looking for <$filter> in vault id: $vault_id"

set -o pipefail
item_id="$(curl --silent --fail --show-error \
  --get \
  -H "Authorization: Bearer ${OP_CONNECT_TOKEN}" \
  --data-urlencode "filter=$filter" \
  "${OP_CONNECT_ADDR}/v1/vaults/${vault_id}/items" |
    jq -e -r 'first | .id'
)" || @milpa.fail "Could not find item"

@milpa.log info "Looking up password for item $item_id"

filter='.fields | map(select( '$MILPA_OPT_FIELD_FILTER' )) | first | .value'

curl --silent --fail --show-error -H "Authorization: Bearer ${OP_CONNECT_TOKEN}" \
  "${OP_CONNECT_ADDR}/v1/vaults/${vault_id}/items/${item_id}" |
  jq -e -r "$filter" || @milpa.fail "Could not find item"
