#!/usr/bin/env bash

export VAULT_ADDR="${VAULT_ADDR/service.consul/service.${MILPA_ARG_DC}.consul}"

@milpa.log info "Renewing SSL for DC: $MILPA_ARG_DC"
main_zone=$(vault kv get -field zone nidito/config/datacenters/nyc1/dns)
@milpa.log info "DC $MILPA_ARG_DC hosted at DNS zone $main_zone"

@milpa.log info "Looking for additional SSL certs to renew..."
additional=()
while read -r zone; do
  additional+=("$zone false")
done < <(vault kv list -format=json nidito/service/ssl/domains | jq -r '.[]')

@milpa.log info "Found ${#additional[*]} zones: ${additional[*]/ /, /}"

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
esac

domains="$(terraform show -json tf-plan | jq -r '
  .planned_values.root_module.resources |
  map(
    select(.type == "acme_certificate") |
    .values.common_name
  ) | join(", ")
')"


@milpa.log info "Renewing SSL certs for $domains..."
terrafom apply --input=false -auto-approve tf-plan || @milpa.fail "Could not apply plan"
@milpa.log complete "SSL certs renewed for $domains"
