#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
spec="$NIDITO_ROOT/services/$service.nomad"
exec nomad alloc logs $NIDITO_ARG_LOG_ARGS -job "$service"
