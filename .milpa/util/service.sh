#!/usr/bin/env bash

function @nidito.service.parse () {
  local service service_folder spec kind
  spec="$MILPA_ARG_SERVICE"
  if [[ -d "$spec" ]]; then
    spec="$spec/$spec.spec.yaml"
  fi

  if [[ ! -f "$spec" ]]; then
    @milpa.fail "Could not find a service spec at $spec"
  fi
  spec="$(readlink -f "$spec")"

  service_folder="$(dirname "$spec")"
  service="$(basename "$service_folder")"

  if [[ -f "${spec%%.spec.yaml}.nomad" ]]; then
    kind="nomad"
  elif grep -c -m1 '^deploy:' "$spec" >/dev/null; then
    kind="http"
  fi

  echo "$service" "$service_folder" "$spec" "$kind"
}

function @nidito.service.resolve_spec () {
  local service service_folder spec root kind
  root="$(milpa nidito service root)"
  service="$MILPA_ARG_SERVICE"
  if [[ -d "$root/$service" ]]; then
    root="$root/$service"
  fi
  spec="$root/$service.spec.yaml"
  if [[ ! -f "$spec" ]]; then
    @milpa.fail "no spec found for service $service at $spec"
  fi

  if [[ -f "${spec%%.spec.yaml}.nomad" ]]; then
    kind="nomad"
  elif grep -c -m1 '^deploy:' "$spec" >/dev/null; then
    kind="http"
  fi
  echo "$service" "$root" "$spec" "$kind"
}

function nomad_vars () {
  local service spec varFile
  service="$1"
  spec="$2"
  varFile="${spec%%spec}vars"
  if [[ "$MILPA_OPT_SPEC" ]]; then
    milpa nidito service vars --output nomad --spec "$spec" >"$varFile" || @milpa.fail "Could not get vars for $service"
  else
    milpa nidito service vars --output nomad "$service" >"$varFile" || @milpa.fail "Could not get vars for $service"
  fi
  echo "$varFile"
}

function @nidito.service.nomad.plan () {
  local varFile spec service
  spec="$1"
  service="$2"
  varFile="$(nomad_vars "$service" "$spec")" || @milpa.fail "Stopping plan, could not create temporary variables file"
  trap 'rm -rf "$varFile"' ERR EXIT
  @milpa.log info "planning nomad job for $service in $MILPA_OPT_DC"
  #  Plan will return one of the following exit codes:
  #    * 0: No allocations created or destroyed.
  #    * 1: Allocations created or destroyed.
  #    * 255: Error determining plan results.
  nomad plan \
    -region "$MILPA_OPT_DC" \
    -force-color \
    -verbose \
    -var-file "$varFile" \
    "${spec%%.spec.yaml}.nomad" >plan.out

  case "$?" in
    0) @milpa.log success "No changes to nomad allocations"; rm plan.out; return 0;;
    255) cat plan.out; @milpa.fail "could not plan nomad job" ;;
    *) @milpa.log warning "Nomad will update allocations:" ;;
  esac

  trap 'rm -rf plan.out' ERR EXIT
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
  rm plan.out
}

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

function @nidito.service.nomad.deploy () {
  local varFile spec service
  spec="$1"
  service="$2"
  varFile="$(nomad_vars "$service" "$spec")" || @milpa.fail "Could not create temporary variables file"
  trap 'rm $varFile' ERR EXIT
  nomad run -verbose \
    -consul-token "$CONSUL_HTTP_TOKEN" \
    -var-file "$(nomad_vars "$service" "$spec")" \
    -region="$MILPA_OPT_DC" \
    "${spec%%.spec.yaml}.nomad"
}
