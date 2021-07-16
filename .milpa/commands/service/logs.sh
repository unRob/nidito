#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
# spec="$(dirname "$MILPA_COMMAND_REPO")/services/$service.nomad"
exec nomad alloc logs $NIDITO_ARG_LOG_ARGS -job "$service"
