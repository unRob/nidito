#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"

if [[ "${#MILPA_ARG_LOG_ARGS}" -gt 0 ]]; then
  exec nomad alloc logs "${MILPA_ARG_LOG_ARGS[@]}" -job "$service" ${MILPA_OPT_FOLLOW:+-tail}
else
  exec nomad alloc logs-job "$service" ${MILPA_OPT_FOLLOW:+-tail}
fi
