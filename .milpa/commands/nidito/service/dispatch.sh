#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
service_folder="$NIDITO_ROOT/services/${service%%.*}"
# spec="$service_folder/$service.nomad"

cd "$service_folder" || @milpa.fail "Could not cd into $service_folder"

echo "$MILPA_ARG_PAYLOAD" | nomad job dispatch "$MILPA_ARG_TASK" -
