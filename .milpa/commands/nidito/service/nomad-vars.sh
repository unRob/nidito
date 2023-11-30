#!/usr/bin/env bash
@milpa.load_util service
read -r _ _ spec < <(@nidito.service.resolve_spec)

config="${spec//.nomad/.spec.yaml}"
[[ -f "$config" ]] || @milpa.fail "Missing spec at $config"

joao get "$config" . --output json | jq '{
  package: (
    .packages // {} |
    with_entries(
      select(.value.image, .value.version) |
      {key: .key, value: {image: .value.image, version: .value.version}}
    )
  )
}'
