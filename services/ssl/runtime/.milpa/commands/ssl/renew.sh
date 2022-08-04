#!/usr/bin/env bash

export VAULT_ADDR="${VAULT_ADDR/service.consul/service.${MILPA_ARG_DC}.consul}"

function vault_get () {
  curl --silent --fail --show-error -H"X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/$1" | jq -r "$2"
}

function vault_list() {
  curl --silent --fail --show-error --request LIST -H"X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/$1" | jq -r "$2"
}

@milpa.log info "Renewing SSL for DC: $MILPA_ARG_DC"
main_zone=$(vault_get "nidito/config/datacenters/${MILPA_ARG_DC}/dns" .data.zone) || @milpa.fail "could not find main_zone"
@milpa.log info "DC $MILPA_ARG_DC hosted at DNS zone $main_zone"

@milpa.log info "Looking for additional SSL certs to renew..."
additional=()
while read -r zone; do
  additional+=("$zone")
done < <(vault_list nidito/service/ssl/domains '(.data.keys // [])[]')

@milpa.log info "Found ${#additional[*]} zones: ${additional[*]// /, }"
terraform init || @milpa.fail "Could not initialize tf directory"

terraform workspace select "$MILPA_ARG_DC" || @milpa.fail "Could not select $MILPA_ARG_DC workspace"

plan_args=()
if [[ "${#additional[*]}" -eq 0 ]]; then
  plan_args=("-var" "lookup_domains=false")
fi

terraform plan -detailed-exitcode -input=false -out=tf-plan "${plan_args[@]}"
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
