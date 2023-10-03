#!/usr/bin/env bash

svc="${MILPA_ARG_SERVICE}"
listen="${MILPA_OPT_LISTEN}"
zone="$(joao get "config/dc/${MILPA_OPT_DC}.yaml" dns.zone)" || @milpa.fail "could not fetch dns zone for dc $MILPA_OPT_DC"
dns="${MILPA_OPT_SUBDOMAIN:-debug-$svc}.$zone"
loglevel="INFO"
if [[ "$MILPA_VERBOSE" ]]; then
  loglevel="DEBUG"
fi

function local_addresses() {
  set -o pipefail
  ips="$(networksetup -listnetworkserviceorder |
    awk '/Device: /{gsub(")", "", $NF); print $NF}' |
    xargs ipconfig getifaddr)" || @milpa.fail "could not fetch local ipv4 addresses"
  jq --raw-input -s -c 'split("\n") | map(select(. != ""))' <<<"$ips" || @milpa.fail "Could not format local ipv4 addresses"
}

function create_dns() {
  set -o pipefail
  ips="$(local_addresses)" || return 2
  jq --arg acl "$MILPA_OPT_ACL" --argjson addresses "$ips" --null-input '{acl: ($acl | split(";")), $addresses}' |
    consul kv put "$1" - || @milpa.fail "Could create consul key at $1"
}

consul_entry="dns/dynamic/debug-$svc"
@milpa.log info "Creating temporary dns record for $dns"
create_dns "$consul_entry" || @milpa.fail "Could not setup dynamic dns records with consul"
@milpa.log success "DNS record for $dns created"

trap 'consul kv delete "$consul_entry"' ERR EXIT

pkey="$(vault kv get -field private_key "nidito/tls/$zone")" || @milpa.fail "could not fetch tls info"
cert="$(vault kv get -field cert "nidito/tls/$zone")" || @milpa.fail "could not fetch tls info"
caddyfile="$(jq -c --null-input \
  --arg cert "$cert" \
  --arg pkey "$pkey" \
  --arg svc "$svc" \
  --arg listen "$listen" \
  --arg port "$MILPA_ARG_PORT" \
  --arg loglevel "$loglevel" \
  '{
  "apps": {
    "http": {
      "servers": {
        "debug-\($svc)": {
          "listen": [":\($listen)"],
          "routes": [{
            "handle": [{
              "handler": "reverse_proxy",
              "upstreams": [{
                "dial": "localhost:\($port)"
              }]
            }]
          }],
          "tls_connection_policies": [{
            "certificate_selection": {
              "any_tag": ["default"]
            }
          }]
        }
      }
    },
    "tls": {
      "certificates": {
        "load_pem": [{
          "certificate": $cert,
          "key": $pkey,
          "tags": ["default"]
        }]
      }
    }
  },
  "logging": {
    "logs": {
      "default": {
        "level": $loglevel
      }
    }
  }
}')" || @milpa.fail "could not generate caddyfile"

@milpa.log info "$(@milpa.fmt inverted "Starting server for https://$dns:$listen")"
caddy run -c <(echo "$caddyfile") || @milpa.fail "Could not start caddy"

@milpa.log info "Cleaning up dns records"
