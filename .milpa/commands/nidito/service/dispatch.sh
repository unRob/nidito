#!/usr/bin/env bash
@milpa.load_util service
read -r svc service_folder _ kind < <(@nidito.service.resolve_spec)
cd "$service_folder" || @milpa.fail "could not cd into $service_folder"

if [[ "$kind" != "nomad" ]]; then
  @milpa.fail "Cannot exec on a non-nomad service of kind $kind"
fi

ns=$(milpa nidito service info "$svc" '.Job.Namespace') || @milpa.fail "Could not find namespace for service $svc, task $MILPA_ARG_TASK"

echo "$MILPA_ARG_PAYLOAD" | nomad job dispatch -namespace "$ns" "$MILPA_ARG_TASK" -

