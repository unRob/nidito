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

function templateAfter() {
  awk -F"EmbeddedTmpl: " <<<"$1" '{print $2}' |
    jq -r --raw-input '. | split("\" => {1,2}\""; "") | ("\"" + last) | fromjson'
}

function templateBefore() {
  awk -F"EmbeddedTmpl: " <<<"$1" '{print $2}' |
    jq -r --raw-input '. | split("\" => +\""; "") | first + "\"" | fromjson'
}

function prettydiff() {
  diff -u -L "before" "$1" -L "after" "$2" |
    delta --syntax-theme=GitHub \
      --paging=never \
      --features="$(defaults read -globalDomain AppleInterfaceStyle >/dev/null 2>&1 && echo dark-mode || echo light-mode)"
}

while IFS='' read -r line; do
  if ! [[ "$line" =~ ^( *).*\+(/-)?.*( *)EmbeddedTmpl:( *).*$ ]]; then
    echo "$line"
    continue
  fi

  awk -F":" '{print $1 ":"}' <<<"$line"
  if [[ "$line" =~ ^( *).*\+/-.*( *)EmbeddedTmpl:( *).*$ ]]; then
    prettydiff <(templateBefore "$line") <(templateAfter "$line")
  elif [[ "$line" =~ ^( *).*\+.*( *)EmbeddedTmpl:( *).*$ ]]; then
    prettydiff <(echo "") <(awk -F"EmbeddedTmpl:" '{print $2}' <<<"$line" | jq -r --raw-input "fromjson")
  fi
done < plan.out
