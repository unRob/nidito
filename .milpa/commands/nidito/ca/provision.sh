#!/usr/bin/env bash
@milpa.load_util terraform config

function cert_vars() {
  # shellcheck disable=2016
  @config.tree host . | jq -rc --arg dcs "$(@config.names dc)"  --from-file "${MILPA_COMMAND_PATH%%provision.sh}cert-vars.jq"
}

@milpa.log info "running terraform to generate certificates"
at_root "terraform/ca"
terraform init -upgrade
jq --null-input \
  --argjson certs "$(cert_vars)" \
  --argjson hosts "$(@config.tree host 'to_entries | map(select(.value.tags.role == "leader") | .key)')" \
  --argjson ca "$(@config.get service:ca . || echo '{"key": "", "cert": ""}')" \
    '{$certs, $hosts, $ca, create_ca: ($ca.key | length == 0)}' |
    @tf.vars "ca" -auto-approve || @milpa.fail "Terraform did not apply correctly"
terraform output -json | jq 'with_entries({key: .key, value: .value.value})' > output.json || @milpa.fail "Failed writing output to file"
trap 'rm -rf output.json' ERR EXIT TERM
@milpa.log success "Certificates generated"

@milpa.log info "Writing keys to config"
while read -r host; do
  value="$(jq -r --arg host "$host" '.keys[$host]' output.json)" || @milpa.fail "could not find keys for $host"
  hostConfig="$(@config.dir)/host/$host.yaml"
  joao set --secret "$hostConfig" "tls.key" <<<"$value" || @milpa.fail "could not save key for $host"
  @milpa.log success "Wrote tls key for $host"
done < <(jq -r '.keys | keys[]' output.json || @milpa.fail "could not read keys")
@milpa.log success "All keys stored"

@milpa.log info "Writing certs to config"
while read -r host service; do
  key="$host-$service"
  value="$(jq -r --arg key "$key" '.certs[$key]' output.json)"
  hostConfig="$(@config.dir)/host/$host.yaml"
  joao set --secret "$hostConfig" "tls.$service" <<< "$value" || @milpa.fail "could not save cert for $key"
  @milpa.log success "Wrote $service cert for $host"
done < <(jq -r '.certs | keys | map(sub("-"; " ")) [] ' output.json)
@milpa.log success "All certs stored"

@milpa.log info "Writing CA to config"
caConfig="$(@config.dir)/service/ca.yaml"
joao set --secret "$caConfig" key "$(jq -r '.ca.key' output.json)" || @milpa.fail "could not save CA key"
joao set --secret "$caConfig" cert "$(jq -r '.ca.cert' output.json)" || @milpa.fail "could not save CA cert"
@milpa.log complete "All certs stored"

rm -rf output.json

@milpa.log info "Writing 1Password TLS config to vault"
while read -r file; do
  joao get "$file" tls >/dev/null 2>&1 || continue;
  n="$(basename "$file")";
  vault kv put "nidito/service/op/${n%%.*}" @<(joao get "$file" tls 2>/dev/null | jq '{key: .key, cert: .op}')
done < <(find ../../config/host -name '*.yaml')
