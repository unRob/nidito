#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
exec nomad alloc logs "${MILPA_ARG_LOG_ARGS[@]}" -job "$service"
