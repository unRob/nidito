#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
service_folder="$NIDITO_ROOT/services/$service"

cd "$service_folder" || @milpa.fail "Could not cd into $service_folder"

if [[ -f "$service.tf" ]]; then
  @milpa.log info "Provisioning with terraform"
  pwd
  terraform init || @milpa.fail "could not init terraform module"
  if [[ "$MILPA_OPT_DC" != "" ]]; then
    terraform workspace select "$MILPA_OPT_DC" || @milpa.fail "Could not select dc $MILPA_OPT_DC"
  fi
  terraform apply || @milpa.fail "Could not apply terraform module"
  @milpa.log success "Service provisioned"
fi
