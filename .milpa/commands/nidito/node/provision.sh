#!/usr/bin/env bash
@milpa.load_util config

primaryDC=$(@config.tree "dc" . | jq -r 'with_entries(select(.value.primary)) | keys | first')
primaryDCGW=$(@config.tree "host" . | jq --arg dc "$primaryDC" -r 'with_entries(select(.value.dc == $dc and .value.tags.reachability? == "gateway")) | keys | first')

export NODE_NAME="${MILPA_ARG_NODE_NAME}"
dc="$(@config.get "node:$NODE_NAME" dc)"

nidito ansible run base "$NODE_NAME"

if [[ "$(@config.get "dc:$dc" leaders)" == "$NODE_NAME" ]]; then
  # get wireguard running remotely
  @milpa.log info "Setting up wireguard"
  nidito ansible run wireguard "$NODE_NAME" || @milpa.fail "Could not setup wireguard"
  @milpa.log success "Wireguard ready"

  # boot coredns in remote
  @milpa.log info "Setting up coredns"
  nidito ansible run coredns "$NODE_NAME" || @milpa.fail "Could not setup coredns"
  @milpa.log success "coredns ready"
fi

# add local dns records
@milpa.log info "adding local DNS records"
nidito ansible run coredns "$primaryDCGW" || @milpa.fail "Could not add local dns records"
@milpa.log success "added DNS records for $NODE_NAME to $primaryDCGW"

# create consul token for new node
@milpa.log info "Creating consul token"
@tf "bootstrap" -var "new_host=$NODE_NAME"
terraform output -json server-tokens |
  jq -r --arg node_name "$NODE_NAME" '.["\($node_name)"]' |
  joao set --secret "$(@config.dir)/hosts/$NODE_NAME.yaml" "token.consul"
@milpa.log success "Consul token created and stored in config"

# create CA certs
at_root ""
milpa nidito ca provision || @milpa.fail "failed provisioning certs"

# provision host
at_root "ansible"
nidito ansible run bootstrap "$NODE_NAME"
pipenv run tame -l "$NODE_NAME" --diff --tags "role_$(@config.get "node:$NODE_NAME" tags.role)"

joao flush "$(config.dir)/node/$NODE_NAME.yaml"
