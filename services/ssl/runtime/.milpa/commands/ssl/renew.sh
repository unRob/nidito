#!/usr/bin/env bash

set -o pipefail
export VAULT_ADDR="https://vault.service.${MILPA_ARG_DC}.consul:5570"

function vault_get () {
  curl --max-time 10 --silent --fail --show-error -H"X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/$1" | jq -r "$2"
}

function vault_list() {
  curl --max-time 10 --silent --fail --show-error --request LIST -H"X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/$1" | jq -r "$2"
}

function dns_provider() {
  dig +short NS "$1" @1.1.1.1 | awk -F. '!/'"$main_zone"'/ {print $(NF-2); exit}'
}

@milpa.log info "Renewing SSL for DC: $MILPA_ARG_DC"
main_zone=$(vault_get "cfg/infra/tree/dc:${MILPA_ARG_DC}" .data.dns.zone) || @milpa.fail "could not find main_zone"
main_provider=$(dns_provider "$main_zone") || @milpa.fail "Could not resolve nameserver for $main_zone"
@milpa.log info "DC $MILPA_ARG_DC hosted at DNS zone $main_zone with provider $main_provider"

jq --null-input \
  --arg zone "$main_zone" \
  --arg ns "$main_provider" \
  '{domains: {($zone): {token: "default", provider: $ns}}}' >terraform.tfvars.json

@milpa.log info "Looking for additional SSL certs to renew..."
while read -r zone; do
  zone_token=$(vault_get "nidito/service/ssl/domains/$zone" '.data.token // "token"') || @milpa.fail "no vault config found for zone $zone at nidito/service/ssl/domains/$zone"
  provider=$(dns_provider "$zone") || @milpa.fail "Could not resolve nameserver for $zone"
  @milpa.log info "Zone $zone is using token $zone_token (NS: $provider)"
  jq \
    --arg zone "$zone" \
    --arg token "$zone_token" \
    --arg ns "$provider" \
    '.domains[$zone] = {token: $token, provider: $ns}' <terraform.tfvars.json > terraform.tfvars.json.tmp || @milpa.fail "could not set token args"
  mv terraform.tfvars.json.tmp terraform.tfvars.json
done < <(vault_list nidito/service/ssl/domains '(.data.keys // [])[]')

jq -r '(.domains | keys) as $keys |
"Renewing " +
($keys | length | tostring) +
" zones: " +
 ($keys | join(", "))' terraform.tfvars.json | @milpa.log info

terraform init || @milpa.fail "Could not initialize tf directory"

terraform workspace select "$MILPA_ARG_DC" || @milpa.fail "Could not select $MILPA_ARG_DC workspace"

terraform plan -detailed-exitcode -input=false -out=tf-plan
code="$?"
trap 'rm -rf tf-plan' ERR EXIT

case "$code" in
  0)
    @milpa.log complete "No changes needed"
    exit 0
    ;;
  1)
    @milpa.fail "Plan errored out"
    ;;
  2)
    if [[ "$MILPA_OPT_DRY_RUN" ]]; then
      @milpa.log success "Plan succeded, exiting due to --dry-run"
      exit
    fi
    @milpa.log success "Plan succeded, applying..."
    ;;
  *)
    @milpa.fail "Unknown exit code: $code"
    ;;
esac

domains="$(terraform show -json tf-plan | jq -r '
  .planned_values.root_module.resources |
  map(
    select(.type == "acme_certificate") |
    .values.common_name
  ) | join(", ")
')"

@milpa.log info "Renewing SSL certs for $domains..."
terraform apply --input=false -auto-approve tf-plan || @milpa.fail "Could not apply plan"
@milpa.log complete "SSL certs renewed for $domains"
