#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
service_folder="$NIDITO_ROOT/services/${service%%.*}"
spec="$service_folder/$service.nomad"
testing="$MILPA_OPT_LOCAL"

[[ ! -f "$spec" ]] && @milpa.fail "Unknown service: $service, see available services running: ${0% *} list"

@milpa.log info "Building $service for ${MILPA_ARG_PLATFORMS[*]}"

dockerfile="$service_folder/Dockerfile"
if [[ "$MILPA_OPT_TASK" ]]; then
  dockerfile="$service_folder/${MILPA_OPT_TASK}.Dockerfile"
  [[ -f "$dockerfile" ]] || @milpa.fail "Could not find a dockerfile at $dockerfile"
fi

if [[ -f "$dockerfile" ]]; then
  dateTag=$(date -u "+%Y%m%d%H%M")
  shaTag=$(cd "$NIDITO_ROOT" && git describe --match="" --always --abbrev=12 --dirty)
  image="registry.nidi.to/${service}"
  if [[ "$MILPA_OPT_TASK" ]]; then
    image="${image}-$MILPA_OPT_TASK"
  fi

  if [[ "$testing" ]]; then
    @milpa.log info "Creating $image:testing"
    docker build -t "${image}:testing" --file "$dockerfile" "$service_folder" || @milpa.fail "Could not build image"
  else
    @milpa.log info "Creating $image:latest with buildx ($dateTag / $shaTag)"
    @milpa.log info "Using dockerfile at $dockerfile"
    platforms="${MILPA_ARG_PLATFORMS[*]}"
    docker buildx build \
      --platform "${platforms// /,}" \
      --network="host" \
      --tag "$image:$dateTag" \
      --tag "$image:$shaTag" \
      --tag "$image:latest" \
      --file "$dockerfile" \
      --cache-from "type=registry,src=$image:buildcache" \
      --cache-to "type=registry,src=$image:buildcache" \
      "$service_folder" --push || @milpa.fail "Could not build image"

    sed -i '' -E 's#^( *image *= *)"[^"]*"#\1"'"$image:$dateTag"'"#' "$spec"
  fi
elif [[ -f "$NIDITO_ROOT/services/$service/Makefile" ]]; then
  cd "$NIDITO_ROOT/services/$service" && make nidito-build
fi

@milpa.log complete "Build complete"