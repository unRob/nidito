#!/usr/bin/env bash
@milpa.load_util config user-input

export NODE_NAME="${MILPA_ARG_NODE_NAME}"
dc="$MILPA_ARG_DC"
dns_zone=$(@config.get "dc:$dc" dns.zone) || @milpa.fail "Could not find datacenter $dc"
mainZone="$(@config.get service:dns zone)"

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

conf="nidito"
ssh_address="$next_addr"
if [[ "$DC" != "casa" ]]; then
  conf="cloud"
  ssh_address="$dc.$mainZone"
fi

if [[ "$MILPA_OPT_SSH_KEY" == "" ]]; then
  # shellcheck disable=2016
  our_ssh_key="$(ssh-add -L | head -n 1 | awk '{print $3}')" || @milpa.fail "Could not resolve local ssh key to use, set with --ssh-key"
  @milpa.log warning "MILPA_OPT_SSH_KEY unset, using first available at $our_ssh_key"
else
  our_ssh_key="${MILPA_OPT_SSH_KEY%.pub}"
fi

@milpa.log info "Provisioning node $NODE_NAME.$dc.$mainZone ($next_addr)"
node_username=$(@milpa.ask "Enter the username of $NODE_NAME")

if ! grep -c "^Host.*$NODE_NAME" ~/.ssh/config.d/$conf.conf >/dev/null; then
  @milpa.log info "Adding host config to ssh"

  cat >>~/.ssh/config.d/$conf.conf <<SSHD

Host $NODE_NAME $next_addr $NODE_NAME.$dc.$mainZone $NODE_NAME.$dns_zone
  Hostname $ssh_address
  User $node_username
  Port 2222
  IdentityFile $our_ssh_key
  ControlMaster     auto
  ControlPath       ~/.ssh/control-%C
  ControlPersist    yes
SSHD

  @milpa.log success "Local SSH configuration successful"
fi

echo -n "Enter the password for ${node_username}@$NODE_NAME: "
read -rs node_password || @milpa.fail "Could not read password"
echo

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
@milpa.log complete "Node metadata stored in $$cfg"
