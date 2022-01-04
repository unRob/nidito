#!/usr/bin/env bash

service="$MILPA_ARG_SERVICE"
exec nomad alloc logs ${MILPA_ARG_LOG_ARGS[*]} a5d54973 #-job "$service" ${MILPA_OPT_FOLLOW:+-tail}
