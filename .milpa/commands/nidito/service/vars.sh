#!/usr/bin/env bash
@milpa.load_util service
read -r _ _ spec _ < <(@nidito.service.resolve_spec)

config="${spec//.nomad/.spec.yaml}"
[[ -f "$config" ]] || @milpa.fail "Missing spec at $config"

joao get "$config" . --output json | case "$MILPA_OPT_OUTPUT" in
  http)
    jq -r '
    (
      ((.packages // {}) + (.dependencies // {})) |
      to_entries |
      map(
        [ "package_\(.key)_image", .value.image ],
        [ "package_\(.key)_version", .value.version ],
        [ "package_\(.key)_source", .value.source ]
      )
    ) + (
      (.deploy // {}) |
      to_entries |
      reduce .[] as $item ([];
        . + (
          if (($item.value | type) == "object") then
          ($item.value | to_entries | map(["deploy_\($item.key)_\(.key)", .value]))
          else [ [ "deploy_\($item.key)", $item.value ] ] end
        )
      )
    ) |
    map([(.[0] | ascii_upcase), (.[1] // "" | tostring)] | join("="))[]'
  ;;
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
      ((.packages // {}) + (.dependencies // {})) |
      to_entries |
      map(
        [ ("package_\(.key)_image" | ascii_upcase), (.value.image // "" | tostring) ],
        [ ("package_\(.key)_version" | ascii_upcase), (.value.version // "" | tostring) ],
        [ ("package_\(.key)_source" | ascii_upcase), (.value.source // "" | tostring) ]
      ) |
      map(join("="))[]'
  ;;
esac

