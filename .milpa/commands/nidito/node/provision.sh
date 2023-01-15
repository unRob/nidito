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
node_password=$(@milpa.ask "Enter the password for ${node_username}@$NODE_NAME")
using_key=$(ssh-add -L | head -n 1 | awk '{print $1,$2}')

@milpa.log info "Connecting over ssh to setup auth, enter ssh password"
function ensure_ssh_key() {
  # shellcheck disable=2087
  ssh "$node_username@$next_addr" <<SH
mkdir -p ~/.ssh
if grep "$using_key" ~/.ssh/authorized_keys >/dev/null; then
  echo "Key already present in ~/.ssh/authorized_keys"
else
  echo "Adding key to ~/.ssh/authorized_keys"
  echo "$using_key" >> ~/.ssh/authorized_keys
fi
SH
}
ensure_ssh_key || @milpa.fail "Could not ensure ssh key got added to host"

if ! grep -c "^Host.*$NODE_NAME" ~/.ssh/config.d/nidito.conf >/dev/null; then
  @milpa.log info "Adding host config to ssh"
  cat >>~/.ssh/config.d/nidito.conf <<SSHD

Host $NODE_NAME $next_addr $NODE_NAME $NODE_NAME.$dns_zone
  Hostname $next_addr
  User $node_username
  Port 22
  IdentityFile $our_ssh_key

SSHD

  @milpa.log success "Node ready for paswordless ssh"
fi

exit

function remote() {
  ssh -q "$NODE_NAME" 'bash -s' 2>/dev/null <<SH
${@}
SH
}

@milpa.log info "Gathering information on $NODE_NAME"
os=$(remote uname -s)
arch=$(remote uname -m)

if [[ "$os" == "Linux" ]]; then
  # todo: finish this shit
  distro=$(remote cat /etc/issue)
  os="linux/$distro"
  model=$(remote cat /sys/devices/virtual/dmi/id/product_name) || model=$(remote cat /proc/device-tree/model)
else
  # hw.model: MacBookPro18,4
  model="$(remote 'sysctl hw.model' | awk '{print tolower($2)}')"
  # 16.1
  version="$(remote 'sw_vers -productVersion | cut -d. -f1,2')"
  os="macos/$version"
  iface=$(remote route -n get default | awk '/interface/ {print $2}')
  mac_address=$(remote networksetup -getmacaddress "$iface" | awk '{print $3}')
  @milpa.log success "Detected $model ($os) at $mac_address"
fi

@milpa.log info "Storing node metadata"
cat >"config/host/${NODE_NAME}.yaml" <<YAML
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
YAML
@milpa.log success "Node metadata stored in $CONFIG_DIR/hosts.yaml"
yq . "config/host/${NODE_NAME}.yaml"

# add dns records
at_root "ansible"
pipenv run tame -l "role_router" --diff -v --tags coredns --ask-become-pass

if [[ $(@config.get "dc:$dc" dns.authority) == "external" ]]; then
  @milpa.log info "Creating external dns records"
  vault kv patch "nidito/config/hosts/$NODE_NAME" dc="$dc" || @milpa.fail "Could not flush node config to vault"
  @tf.dc "external-dns" "$dc"
  @milpa.log success "external DNS records created"
fi

# create consul token
@milpa.log info "Creating consul token"
@tf.dc "bootstrap" "$dc" --var new_host "$NODE_NAME"
terraform output -json server-tokens |
  jq -r --arg node_name "$NODE_NAME" '.["\($node_name)"]' |
  @config.write hosts "$NODE_NAME.token.consul"
@milpa.log success "Consul token created and stored in config"

# create CA certs
at_root ""
milpa nidito ca provision || @milpa.fail "failed provisioning certs"

# provision host
at_root "ansible"
pipenv run tame -l "$NODE_NAME"

at_root ""
milpa nidito config flush
