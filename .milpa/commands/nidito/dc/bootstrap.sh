#!/usr/bin/env bash
@milpa.load_util config user-input

dc="${MILPA_ARG_DC}"

[[ -f "$(config.dir)/dc/$dc/yaml" ]] && @milpa.fail "$dc already exists!"

read -r next_subnet next_peering < <(@config.tree "dc" . | jq -r '
  to_entries |
  map(select(.value.primary | not) | .value.subnet) |
  sort |
  last |
  split(".") |
  .[2] |= (tonumber|.+8) |
  [(. | map(tostring)), (.[2] |= (.+1|tostring) | .[3] |= "1/24")] |
  map(join(".")) | join(" ")')

leaders="$(@milpa.ask "Enter the leader dns entry for $dc")"
dns_zone="$(@milpa.ask "Enter the dns zone for $dc services")"
public_ip="$(@milpa.ask "Enter the public ip for $dc")"
private_key=$(wg genkey)
public_key=$(wg pubkey <<<"$private_key")

function has_acl_token() {
  nomad acl token list -json |
    jq -r --exit-status 'map(select(.Type == "management" and .Global and (.Name | match("^aqro0"))) | .AccessorID) | first'
}

# create tokens for ACL replication
# https://developer.hashicorp.com/nomad/tutorials/access-control/access-control-bootstrap
@milpa.log info "ensuring nomad ACL replication token exists..."

if ! replication_accessor=$(has_acl_token "$dc"); then
  @milpa.log info "Creating ACL token for $dc"
  nomad acl token create -json -type="management" -global=true -name="$dc Replication Token" >"$dc-token.json"
  replication_accessor=$(jq -r .AccessorID "$dc-token.json")
  replication_secret=$(jq -r .SecretID "$dc-token.json")
  rm "$dc-token.json"
  @milpa.log success "Stored ACL token for $dc in $(config.dir)/dc/$dc.yaml"
else
  @milpa.log success "token for $dc already created, fetching..."
  replication_secret=$(nomad acl token info "$replication_accessor" | awk '/^Secret ID/ {print $4}')
fi


cat > "$(config.dir)/dc/$dc.yaml" <<EOF
dns:
  authority: external
  leaders: $leaders
  zone: $dns_zone
peering:
  address: $next_peering
  endpoint: !!secret $public_ip:$(@config.get "service:wireguard" port)
  peers:
    anahuac:
      dc: casa
      resolve_dns: true
  key:
    private: !!secret $private_key
    public: !!secret $public_key
primary: false
subnet: $next_subnet
vault:
  nomad_token: !!secret tbd-terraform-node-bootstrap
  unseal_key: !!secret tbd-nidito-dc-bootstrap
  root_token: !!secret tbd-nidito-dc-bootstrap
nomad:
  replication:
    accessor: !!secret $replication_accessor
    secret: !!secret $replication_secret
EOF

@milpa.log complete "DC configuration created at $(config.dir)/dc/$dc.yaml"
@milpa.log info <<EOF
@milpa.log info 'Next steps are:

# bootstrap the leader node with
nidito node bootstrap "$leaders" "$dc" --address "${next_subnet%%0/*}/${next_subnet##*/}"

# provision the leader node
nidito node provision "$NODE_NAME"
EOF
