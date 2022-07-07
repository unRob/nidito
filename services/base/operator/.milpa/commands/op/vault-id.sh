#!/usr/bin/env bash

set -o pipefail
curl --silent --fail --show-error -H "Authorization: Bearer ${OP_CONNECT_TOKEN}" \
  "$OP_CONNECT_ADDR/v1/vaults" |
  jq -e -r '.[] | select(.name == "nidito") | .id' || @milpa.fail "Could not find vault id"
