#!/usr/bin/env bash

if [[ "$MILPA_OPT_SPEC" ]]; then
  service="$(basename "${MILPA_ARG_SERVICE%%.nomad}")"
  service_folder="$(dirname "$MILPA_ARG_SERVICE")"
  spec="$MILPA_ARG_SERVICE"
  @milpa.log warning "Reading local nomad file: $spec"
else
  service="$MILPA_ARG_SERVICE"
  service_folder="$NIDITO_ROOT/services/$service"
  spec="$service_folder/$service.nomad"
  cd "$service_folder" || @milpa.fail "services folder not found"
fi

export NOMAD_ADDR="${NOMAD_ADDR/.service.consul/.service.${MILPA_OPT_DC}.consul}"

if [[ ! -f "$spec" ]]; then
  @milpa.fail "Nothing to plan for $service: not a nomad job"
fi

@milpa.log info "planning nomad job for $service in $MILPA_OPT_DC"

#  Plan will return one of the following exit codes:
#    * 0: No allocations created or destroyed.
#    * 1: Allocations created or destroyed.
#    * 255: Error determining plan results.
nomad plan -region "$MILPA_OPT_DC" -force-color -verbose "$spec" >plan.out
sc="$?"
case "$sc" in
  0) @milpa.log success "No changes to nomad allocations"; rm plan.out; exit ;;
  255) cat plan.out; @milpa.fail "could not plan nomad job" ;;
esac

trap 'rm -rf plan.out' ERR EXIT
@milpa.log warning "Nomad will update allocations:"

function templatesBefore() {
  while IFS= read -r line; do
    jq -r --raw-input '. | split("\" => \"") | first + "\"" | fromjson' <<<"$line"
  done < <(awk -F"EmbeddedTmpl:" '/EmbeddedTmpl:/ {print $2}' plan.out)
}

function templatesAfter() {
  while IFS= read -r line; do
    jq -r --raw-input '. | split("\" => \"") | ("\"" + last) | fromjson' <<<"$line"
  done < <(awk -F"EmbeddedTmpl:" '/EmbeddedTmpl:/ {print $2}' plan.out)
}

cat plan.out
diff -u <(templatesBefore) <(templatesAfter) |
  delta --syntax-theme=GitHub --features="$(defaults read -globalDomain AppleInterfaceStyle >/dev/null 2>&1 && echo dark-mode || echo light-mode)"
