#!/usr/bin/env bash
@milpa.load_util terraform

function cert_vars() {
  # shellcheck disable=2016
  @config hosts . |
    jq -rc --argjson dcs "$(@configq datacenters . 'keys')" '
  to_entries |
  map(
    select(.value.tags.role == "leader") |
    {name: .key, address: .value.address, dc: .value.dc}
  ) |
  reduce .[] as $n (
    [];
    . + (
      ["consul", "vault", "nomad"] |
      map(. as $svc | {
        key: "\($n.name)-\($svc)",
        host: $n.name,
        cn: "server.\($n.dc).\($svc)",
        names: (
          [
            "localhost",
            "\($svc).service.consul",
            "\($svc).service.\($n.dc).consul",
            "\($n.name).node.consul",
            "\($n.name).node.\($n.dc).consul"
          ] + (
            if $svc == "consul" then
              (($dcs | map(select(. != $n.dc) | "*.\(.).consul")) // [])
            else [] end
          )
        ),
        ips: ["127.0.0.1", $n.address]
      })
    )
  )
  '
}

@milpa.log info "running terraform to generate certificates"
jq --null-input \
  --argjson certs "$(cert_vars)" \
  --argjson hosts "$(@configq hosts . 'to_entries | map(select(.value.tags.role == "leader") | .key)')" \
  --argjson ca "$(@configq services . '.ca // {key: "", cert: ""}')" \
    '{$certs, $hosts, $ca, create_ca: ($ca.key | length == 0)}' |
    @tf.vars "ca"
terraform output -json | jq 'with_entries({key: .key, value: .value.value})' > output.json || @milpa.fail "Failed writing output to file"
trap 'rm -rf output.json' ERR EXIT TERM

@milpa.log success "Certificates generated"

@milpa.log info "Writing keys to config"
while read -r host; do
  jq -r --arg host "$host" '.keys[$host]' output.json |
    @config.write hosts "$host.tls.key" || @milpa.fail "could not save key for $host"
done < <(jq -r '.keys | keys[]' output.json)
@milpa.log success "All keys stored"

@milpa.log info "Writing certs to config"
while read -r host service; do
  key="$host-$service"
  jq -r --arg key "$key" '.certs[$key]' output.json |
    @config.write hosts "$host.tls.$service" || @milpa.fail "could not save cert for $key"
done < <(jq -r '.certs | keys | map(sub("-"; " ")) [] ' output.json)
@milpa.log success "All certs stored"

@milpa.log info "Writing CA to config"
jq -r '.ca.key' output.json | @config.write services ca.key || @milpa.fail "could not save CA"
jq -r '.ca.cert' output.json | @config.write services ca.cert || @milpa.fail "could not save CA"
@milpa.log complete "All certs stored"

rm -rf output.json
