#!/usr/bin/env bash
@milpa.load_util terraform config

export NODE_NAME="${MILPA_ARG_NODE_NAME}"
dc="$MILPA_ARG_DC"
dns_zone=$(@config.get "dc:$dc" ".dns.zone") || @milpa.fail "Could not find datacenter $dc"
dns_authority=$(@config.get "dc:$dc" ".dns.authority") || @milpa.fail "Could not find dns authority for dc $dc"

# shellcheck disable=2016
next_addr="$(@config.tree host | jq -r --arg dc "$dc" '
  map(select(.address and .dc == $dc) | .address)
  | sort | last | split(".")
  | map(tonumber)
  | .[(. | length) - 1] += 1
  | join(".")
')"

@milpa.log info "Provisioning node $NODE_NAME.$dns_zone IN A $next_addr"

@milpa.log info "Storing node metadata"
@config.write "host:${NODE_NAME}" ".address" <<<"$next_addr"
@config.write "host:${NODE_NAME}" ".dc" <<<"$dc"
@config.write "host:${NODE_NAME}" ".hardware.arch"
@config.write "host:${NODE_NAME}" ".hardware.model"
@config.write "host:${NODE_NAME}" ".hardware.os"
@config.write "host:${NODE_NAME}" ".hardware.mac"
@milpa.log success "Node metadata stored in $CONFIG_DIR/hosts.yaml"

@milpa.log info "Adding host config to ssh"
cat >>~/.ssh/config.d/nidito.conf <<SSHD

Host $NODE_NAME
  Hostname $NODE_NAME.$dns_zone
  IdentityFile ~/.ssh/rob@unRob
  Port 22

SSHD
@milpa.log success "Node ready for ssh"

# add dns records
at_root "ansible"
pipenv run tame -l "role_router" --diff -v --tags coredns --ask-become-pass

if [[ "$dns_authority" == "external" ]]; then
  @milpa.log info "Creating external dns records"
  vault kv patch "nidito/config/hosts/$NODE_NAME" dc="$dc" || @milpa.fail "Could not flush node config to vault"
  @tf.dc "external-dns" "$dc"
  @milpa.log success "external DNS records created"
fi

# create consul token
@milpa.log info "Creating consul token"
@tf.dc "bootstrap" "$dc" --var new_host "$NODE_NAME"
terraform output server-tokens |
  jq --arg node "$NODE_NAME" '.["\($node_name)"]' |
  @config.write hosts "$NODE_NAME.token.consul.node"
@milpa.log success "Consul token created and stored in config"

# create CA certs
at_root ""
milpa nidito ca provision || @milpa.fail "failed provisioning certs"

# provision host
at_root "ansible"
pipenv run tame -l "$NODE_NAME"

at_root ""
milpa nidito config secrets flush
