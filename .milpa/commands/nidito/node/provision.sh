#!/usr/bin/env bash
@milpa.load_util terraform config user-input

export NODE_NAME="${MILPA_ARG_NODE_NAME}"
dc="$MILPA_ARG_DC"
dns_zone=$(@config.get "dc:$dc" dns.zone) || @milpa.fail "Could not find datacenter $dc"

if [[ "$MILPA_OPT_ADDRESS" == "" ]]; then
  # shellcheck disable=2016
  next_addr="$(@config.tree host | jq -r --arg dc "$dc" '
    map(select(.address and .dc == $dc) | .address)
    | sort | last | split(".")
    | map(tonumber)
    | .[(. | length) - 1] += 1
    | join(".")
  ')"
else
  next_addr="$MILPA_OPT_ADDRESS"
fi

if [[ "$MILPA_OPT_SSH_KEY" == "" ]]; then
  # shellcheck disable=2016
  our_ssh_key="$(ssh-add -L | head -n 1 | awk '{print $3}')" || @milpa.fail "Could not resolve local ssh key to use, set with --ssh-key"
  @milpa.log warning "MILPA_OPT_SSH_KEY unset, using first available at $our_ssh_key"
else
  our_ssh_key="$MILPA_OPT_SSH_KEY"
fi

@milpa.log info "Provisioning node $NODE_NAME.$dns_zone IN A $next_addr"
node_username=$(@milpa.ask "Enter the username of $NODE_NAME")
echo -n "Enter the password for ${node_username}@$NODE_NAME: "
read -rs node_password || @milpa.fail "Could not read password"
echo

if ! grep -c "^Host.*$NODE_NAME" ~/.ssh/config.d/nidito.conf >/dev/null; then
  @milpa.log info "Adding host config to ssh"
  cat >>~/.ssh/config.d/nidito.conf <<SSHD

Host $NODE_NAME $next_addr $NODE_NAME.$dns_zone
  Hostname $next_addr
  User $node_username
  Port 2222
  IdentityFile $our_ssh_key
  ControlMaster     auto
  ControlPath       ~/.ssh/control-%C
  ControlPersist    yes
SSHD

  @milpa.log success "Node ready for paswordless ssh"
fi


@milpa.log info "Gathering information on $NODE_NAME"
scp "$MILPA_COMMAND_REPO/remote/gather-info.sh" "$NODE_NAME:gather-info.sh"
IFS='|' read -r model os arch mac_address < <(ssh -q "$NODE_NAME" ./gather-info.sh)

@milpa.log info "Storing node metadata"
cfg="$(@config.dir)/host/${NODE_NAME}.yaml"
cat >"$cfg" <<YAML
address: $next_addr
auth:
  username: !!secret $node_username
  password: !!secret $node_password
dc: $dc
hardware:
  arch: $arch
  model: $model
  os: $os
mac: !!secret $mac_address
tags:
  # can be leader or router
  role: leader
  # one of: primary, secondary, none
  storage: none
  provisioning: true
YAML
@milpa.log success "Node metadata stored in $$cfg"

# add dns records
@milpa.log info "adding DNS records"
nidito operator ansible coredns || @milpa.fail "Could not add dns records"
@milpa.log success "added DNS records for $NODE_NAME"

# create consul token
@milpa.log info "Creating consul token"
@tf.dc "bootstrap" "$dc" -var "new_host=$NODE_NAME"
terraform output -json server-tokens |
  jq -r --arg node_name "$NODE_NAME" '.["\($node_name)"]' |
  joao set --secret "$(@config.dir)/hosts/$NODE_NAME.yaml" "token.consul"
@milpa.log success "Consul token created and stored in config"

# create CA certs
at_root ""
milpa nidito ca provision || @milpa.fail "failed provisioning certs"

# provision host
at_root "ansible"
pipenv run tame -l "$NODE_NAME"

at_root ""
milpa nidito config flush
