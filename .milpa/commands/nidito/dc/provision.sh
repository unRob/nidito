#!/usr/bin/env bash
@milpa.load_util config

dc="${MILPA_ARG_DC}"

# after vault boots, i should initialize stuff
@milpa.log info "Checking for vault initialization status"
if ! @config.get "dc:$dc" vault.unseal_key >/dev/null; then
  @milpa.load_util tmp
  @tmp.file vaultRoot

  @milpa.log info "Initializating Vault cluster for $dc"
  # shellcheck disable=2154
  VAULT_ADDR=https://vault.service.$dc.consul:5570 vault operator init \
    -key-shares=1 \
    -t=1 -format json > "${vaultRoot}" || @milpa.fail "Could not initialize cluster"
  @milpa.log success "Initialized vault cluster. Storing credentials."

  jq -r '.unseal_keys_hex | first' "$vaultRoot" | joao set "config/dc/$dc.yaml" unseal_key
  jq -r '.root_token | first' "$vaultRoot" | joao set "config/dc/$dc.yaml" root_token
  nidito dc unseal --dc "$dc" || @milpa.fail "Could not unseal DC after initialization"
else
  @milpa.log success "Vault cluster for $dc is already initialized and has stored credentials."
  nidito dc unseal --dc "$dc" || exit $?
fi
@milpa.log sucess "Vault initialized and unsealed"

# after nomad boots for the first time in a DC, we should join
@milpa.log info "Joining local cluster to remote cluster"
nomad server join "nomad.service.$dc.consul:$(@config.get get service:nomad ports.serf)" || @milpa.fail "could not join local => remote nomad clusters"
@milpa.log info "Joining remote cluster to local cluster, for good measure"

remote_cluster="https://nomad.service.$dc.consul:$(@config.get service:nomad ports.http)"
local_dc=$(basename "$(grep -l 'primary: true' ~/src/nidito/config/dc/*.yaml)")
NOMAD_ADDR="$remote_cluster" nomad server join \
  "nomad.service.${local_dc%%.yaml}.consul:$(@config.get get service:nomad ports.serf)" || @milpa.fail "could not join remote => local nomad clusters"
@milpa.log success "Nomad clusters joined"

@milpa.log info "Enabling Nomad memory oversubscription"
# [OPTIONAL] enable memory oversubscription
# https://developer.hashicorp.com/nomad/docs/job-specification/resources#memory-oversubscription
NOMAD_ADDR="$remote_cluster" nomad operator scheduler set-config -memory-oversubscription=true || @milpa.fail "could not enable memory oversubscription"
@milpa.log success "Enabled Nomad memory oversubscription"
