#!/usr/bin/env bash
@milpa.load_util config

if [[ "$MILPA_OPT_LIST" ]]; then
  @milpa.log info "Listing inventory"
elif [[ "$MILPA_OPT_HOST" ]]; then
  echo "{}"
  exit 0
else
  @milpa.fail "Unknown ansible-inventory command <$*>"
fi


jq '{
  _meta: {
    hostvars: $hosts | with_entries({
      key: .key,
      value: ({node: (.value + {name: .key})} + .value._ansible)
    })
  },
  all: {
    hosts: $hosts | keys,
    vars: {
      config: {
        datacenters: $datacenters,
        networks: $networks,
        nodes: $hosts,
        services: $services,
      }
    }
  }
} * (
  $hosts |
  to_entries |
  map(
    .key as $node_name |
    (.value.tags + .value.hardware + { dc: .value.dc } | del(.model)) |
    with_entries({
      key: ("\(.key)_\(.value)" | gsub("\\W"; "_")),
      value: [$node_name]
    })
  ) | reduce .[] as $n ({}; . as $cur | . * (
    $n | with_entries({
      key: .key,
      value: (.value + ($cur[.key] // []))
    })
  ))
)
' \
  --argjson hosts "$(@config.tree host '.')" \
  --argjson networks "$(@config.tree net '.')" \
  --argjson services "$(@config.tree service '.')" \
  --argjson datacenters "$(@config.tree dc '.')" \
  --null-input