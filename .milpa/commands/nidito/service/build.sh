#!/usr/bin/env bash
@milpa.load_util service
read -r service service_folder spec < <(@nidito.service.resolve_spec)
cd "$service_folder" || @milpa.fail "could not cd into $service_folder"
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

  build_args=()
  if [[ -f "${service_folder}/build-args.sh" ]]; then
    while read -r arg; do
      build_args+=( --build-arg "$arg" )
    done < <(source "${service_folder}/build-args.sh") || @milpa.fail "Could not run build_args to completion"
  fi

  if [[ -f "${service_folder}/build-secrets.sh" ]]; then
    while read -r id; do
      build_args+=( "--secret" "id=$id,src=$service_folder/BUILD_SECRET_$id" )
    done < <(source "${service_folder}/build-secrets.sh") || @milpa.fail "Could not run build_args to completion"
    trap 'rm -rf "$service_folder"/BUILD_SECRET_*' ERR EXIT
  fi

  while read -r arg; do
    build_args+=( --build-arg "$arg" )
  done < <(milpa nidito service vars --output docker "$service")

  if [[ "$testing" ]]; then
    @milpa.log info "Creating $image:testing"
    docker build --builder default "${build_args[@]}" -t "${image}:testing" --file "$dockerfile" "$service_folder" || @milpa.fail "Could not build image"
  else
    @milpa.log info "Creating $image:latest with buildx ($dateTag / $shaTag)"
    nidito_spec="${spec%%.nomad}.spec.yaml"
    package="$(joao get --output json "$nidito_spec" . | jq -r '(.packages // {}) + (.dependencies // {}) |  to_entries | map(select(.value.source == "./Dockerfile") | .key) | first')" || @milpa.fail "Could not find a package spec in $nidito_spec"
    @milpa.log info "Using dockerfile at $dockerfile (package $package)"
    platforms="${MILPA_ARG_PLATFORMS[*]}"
    docker buildx build \
      --platform "${platforms// /,}" \
      --network="host" \
      --tag "$image:$dateTag" \
      --tag "$image:$shaTag" \
      --tag "$image:latest" \
      --file "$dockerfile" \
      --ssh "default" \
      --cache-from "type=registry,ref=$image:buildcache" \
      --cache-to "type=registry,ref=$image:buildcache,mode=max" \
      "${build_args[@]}" \
      "$service_folder" --push || @milpa.fail "Could not build image"

    joao set "$nidito_spec" "packages.$package.image" <<<"$image"
    joao set "$nidito_spec" "packages.$package.version" <<<"$dateTag"
  fi
elif [[ -f "$NIDITO_ROOT/services/$service/Makefile" ]]; then
  cd "$NIDITO_ROOT/services/$service" && make nidito-build
fi

@milpa.log complete "Build complete"
