#!/usr/bin/env bash
@milpa.load_util service
read -r _ _ spec < <(@nidito.service.resolve_spec)

config="${spec//.nomad/.spec.yaml}"
[[ -f "$config" ]] || @milpa.fail "Missing spec at $config"

joao get "$config" . --output json | case "$MILPA_OPT_OUTPUT" in
  nomad)
     jq '{
      package: (
        .packages // {} |
        with_entries(
          select(.value.image, .value.version) |
          {key: .key, value: {image: .value.image, version: .value.version}}
        )
      )
    }'
  ;;
  docker)
    jq -r '
      .packages // {} |
      to_entries |
      map(
        [ ("package_\(.key)_image" | ascii_upcase), (.value.image // "" | tostring) ],
        [ ("package_\(.key)_version" | ascii_upcase), (.value.version // "" | tostring) ],
        [ ("package_\(.key)_source" | ascii_upcase), (.value.source // "" | tostring) ]
      ) |
      map(join("="))[]'
  ;;
esac

