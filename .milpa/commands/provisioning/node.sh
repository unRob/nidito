#!/usr/bin/env bash

export NODE_NAME="${MILPA_ARG_NODE_NAME}"

next_addr="$(configq local hosts '
  map(select(.address) | .address)
  | sort | last | split(".")
  | map(tonumber)
  | .[(. | length) - 1] += 1
  | join(".")
')"

# create the node config
gcy set --plain-text config/hosts.yaml "${NODE_NAME}.address" "$next_addr"
gcy set --plain-text config/hosts.yaml "${NODE_NAME}.dc" "$MILPA_ARG_DC"
gcy set --plain-text config/hosts.yaml "${NODE_NAME}.hardware.arch"
gcy set --plain-text config/hosts.yaml "${NODE_NAME}.hardware.model"
gcy set --plain-text config/hosts.yaml "${NODE_NAME}.hardware.os"
gcy set config/hosts.yaml "${NODE_NAME}.hardware.mac"

# add dns records
cd ansible
pipenv run tame -l tehuantepec --diff -v --tags coredns --ask-become-pass

# create consul token
cd ../terraform/bootstrap
terraform apply --var new_host "$NODE_NAME"
gcy set ../../config/hosts.yaml "$NODE_NAME.token.consul.node" "$(terraform output server-tokens | jq ".[\"$NODE_NAME\"]")"

# create CA certs
cd ../../
milpa provisioning certs

# add host to ssh config
cat >>~/.ssh/config.d/nidito.conf <<SSHD

Host $NODE_NAME
  Hostname $NODE_NAME.nidi.to
  IdentityFile ~/.ssh/rob@unRob
  Port 22

SSHD


# provision host
cd ansible
pipenv run tame -l "$NODE_NAME"
