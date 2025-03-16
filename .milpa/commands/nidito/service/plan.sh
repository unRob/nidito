#!/usr/bin/env bash
@milpa.load_util service
read -r service service_folder spec kind < <(@nidito.service.resolve_spec)
cd "$service_folder" || @milpa.fail "could not cd into $service_folder"

export NOMAD_ADDR="${NOMAD_ADDR/.service.consul/.service.${MILPA_OPT_DC}.consul}"

if [[ "$kind" == "http" ]]; then
  set +a
  source <(milpa nidito service vars "$service" --output http)
  set -a

  creds="$(vault kv get -format json -field=data "${DEPLOY_CREDENTIALS##vault://}")" || @milpa.fail "Failed to fetch credentials from $DEPLOY_CREDENTIALS"

  function creds() {
    jq -r ".$1" <<<"$creds"
  }

  hkind="$(creds 'type')"
  # cd "${service_folder%%/services*}" || @milpa.fail "Could not cd into project root"
  case "$hkind" in
    s3)
      @milpa.log info "Planning with rclone"
      export RCLONE_CONFIG_REMOTE_TYPE="s3"
      export RCLONE_CONFIG_REMOTE_PROVIDER="Other"
      export RCLONE_CONFIG_REMOTE_ENV_AUTH="false"
      export RCLONE_CONFIG_REMOTE_ACCESS_KEY_ID="$(creds 'key')"
      export RCLONE_CONFIG_REMOTE_SECRET_ACCESS_KEY="$(creds 'secret')"
      export RCLONE_CONFIG_REMOTE_ENDPOINT="$(creds 'endpoint')"
      export RCLONE_CONFIG_REMOTE_FORCE_PATH_STYLE="true"
      @milpa.log debug "rclone config:"
      env | grep 'RCLONE' | @milpa.log debug

      @milpa.log info "Starting rclone diff"
      rclone sync \
        --s3-acl public-read \
        --verbose \
        --metadata \
        --dry-run \
        "$DEPLOY_SRC" "remote:$(creds 'bucket')" || @milpa.fail "Diff failed"
      ;;
    ssh)
      @milpa.log info "Planning with rsync"
      rsync -avz --delete --dry-run --itemize-changes \
        "${DEPLOY_SRC}/"* \
        "$(creds 'host'):/nidito/http-proxy/$(creds 'domain')" || @milpa.fail "Plan failed"
      ;;
    *) @milpa.fail "Unknown static content deployment type: $hkind"
  esac
  exit
fi

@nidito.service.nomad.plan "$spec" "$service"
