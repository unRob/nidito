#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
spec="$NIDITO_ROOT/services/$service.nomad"
testing="$MILPA_OPT_LOCAL"

[[ ! -f "$spec" ]] && fail "Unknown service: $service, see available services running: ${0% *} list"


if [[ -f "$NIDITO_ROOT/services/$service/Dockerfile" ]]; then
  tag=$(date -u "+%Y%m%d%H%M")
  if [[ -n "$2" ]]; then
    tag="${2}-$tag"
  fi
  image="registry.nidi.to/${service}:$tag"
  if [[ "$testing" ]]; then
    docker build -t "${image%:*}:testing" "$NIDITO_ROOT/services/$service"
  else
    docker buildx build \
      --platform linux/amd64 \
      -t "$image" \
      "$NIDITO_ROOT/services/$service" --push

    sed -i '' -E 's#^( *image *= *)"[^"]*"#\1"'"$image"'"#' "$NIDITO_ROOT/services/$service.nomad"
  fi
elif [[ -f "$NIDITO_ROOT/services/$service/Makefile" ]]; then
  cd "$NIDITO_ROOT/services/$service" && make nidito-build
fi
