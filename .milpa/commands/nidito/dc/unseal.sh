#!/usr/bin/env bash

@milpa.load_util config
consul_addr="${CONSUL_HTTP_ADDR/service.consul/service.${MILPA_OPT_DC}.consul}"

@milpa.log info "Getting unseal key from config"
unseal_key="$(@config.get "dc:$MILPA_OPT_DC" vault.unseal_key)" || @milpa.fail "Could not get unseal key from config"

set -o pipefail
curl --silent --show-error --fail \
   -H "Authorization: bearer $CONSUL_HTTP_TOKEN" \
  "${consul_addr}/v1/catalog/service/vault" |
  jq -r 'map([.Address, (.ServiceTags | index("initialized")) == null] | join(" ")) | sort | .[]' |
  while read -r node isSealed; do
    if [[ "$isSealed" == "true" ]]; then
      @milpa.log warn "Unsealing $node"
      VAULT_ADDR="https://$node:5570" vault operator unseal "$unseal_key" || @milpa.fail "Could not unseal $node"
    fi

    @milpa.log success "$node is unsealed"
    echo "-----------"
  done || @milpa.fail "Failed querying consul for vault instances"
