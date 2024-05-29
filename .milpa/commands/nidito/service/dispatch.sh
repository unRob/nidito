#!/usr/bin/env bash
@milpa.load_util service
read -r svc service_folder _ < <(@nidito.service.resolve_spec)
cd "$service_folder" || @milpa.fail "could not cd into $service_folder"

ns=$(nomad job run -output "$svc.nomad" | jq -r '.Job.Namespace') || @milpa.fail "Could not find namespace for service $svc, task $MILPA_ARG_TASK"

echo "$MILPA_ARG_PAYLOAD" | nomad job dispatch -namespace "$ns" "$MILPA_ARG_TASK" -

