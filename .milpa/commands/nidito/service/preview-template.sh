#!/usr/bin/env bash
@milpa.load_util tmp config

@tmp.file rendered

dns_zone="$(@config.get "dc:$MILPA_OPT_DC" dns.zone)"

env \
  "node.unique.name=${MILPA_OPT_NODE:-$(hostname)}" \
  "node.region=$MILPA_OPT_DC" \
  "meta.dns_zone=$dns_zone" \
  'attr.nomad.advertise.address=127.0.0.1' \
  consul-template -vault-renew-token=false -once -template="$MILPA_ARG_FILE:$rendered" || @milpa.fail "Could not render template"

bat --file-name "$MILPA_ARG_FILE" "$rendered"
