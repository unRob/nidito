#!/usr/bin/env bash

@milpa.load_util service
read -r service service_folder spec kind < <(@nidito.service.resolve_spec)
cd "$service_folder" || @milpa.fail "could not cd into $service_folder"
http_spec="$service_folder/$service.http-service"

@milpa.log info "deploying $service"

export NOMAD_ADDR="${NOMAD_ADDR/.service.consul/.service.${MILPA_OPT_DC}.consul}"

if [[ ! -f "$spec" ]]; then
  @milpa.fail "Could not find spec at $spec"
fi

case "$kind" in
  nomad)
    @milpa.log info "deploying with nomad"
    # export NOMAD_ADDR="https://nomad.service.$MILPA_OPT_DC.consul:5560"
    @milpa.log info "Writing temporary variables for nomad job"
    varFile="${spec%%nomad}vars"
    nomad_vars "$service" "$spec" >"$varFile" || @milpa.fail "Could not get vars for $service"

    if [[ ! "$MILPA_OPT_SKIP_PLAN" ]]; then
      @nidito.service.nomad.plan "$spec" "$service"
    fi

    trap 'rm $varFile' ERR EXIT
    @nidito.service.nomad.deploy "$spec" "$service" || @milpa.fail "Deploy failed"
    ;;
  http)
    @milpa.log info "deploying static http content for $MILPA_ARG_SERVICE"
    set +a
    source <(milpa nidito service vars "$service" --output http)
    set -a
    creds="$(vault kv get -format json -field=data "${DEPLOY_CREDENTIALS##vault://}")" || @milpa.fail "Failed to fetch credentials from $DEPLOY_CREDENTIALS"

    function creds() {
      jq -r ".$1" <<<"$creds"
    }

    hkind="$(creds 'type')"
    case "$hkind" in
      s3)
        @milpa.log info "Configuring rclone"
        export RCLONE_CONFIG_REMOTE_TYPE="s3"
        export RCLONE_CONFIG_REMOTE_PROVIDER="Other"
        export RCLONE_CONFIG_REMOTE_ENV_AUTH="false"
        export RCLONE_CONFIG_REMOTE_ACCESS_KEY_ID="$(creds 'key')"
        export RCLONE_CONFIG_REMOTE_SECRET_ACCESS_KEY="$(creds 'secret')"
        export RCLONE_CONFIG_REMOTE_ENDPOINT="$(creds 'endpoint')"
        export RCLONE_CONFIG_REMOTE_FORCE_PATH_STYLE="true"
        @milpa.log debug "rclone config:"
        env | grep 'RCLONE' | @milpa.log debug

        @milpa.log info "Starting deploy"
        rclone sync \
          --s3-acl public-read \
          --progress \
          --metadata \
          "$DEPLOY_SRC" "remote:$(creds 'bucket')" || @milpa.fail "Deploy failed"
        ;;
      ssh)
        @milpa.log info "Deploying with rsync"
        rsync -avz --delete \
          "$DEPLOY_SRC/"* \
          "$(creds 'host'):/nidito/http-proxy/$(creds 'domain')" || @milpa.fail "Deploy failed"
        ;;
      *) @milpa.fail "Unknown static content deployment type: $hkind"
    esac
    ;;
  *)
    if [[ -f "${http_spec}" ]]; then
      exec bash "$http_spec"
    fi
    @milpa.fail "unknown service deployment type: $kind"
esac

@milpa.log complete "Deployed $service"
