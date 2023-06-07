#!/usr/bin/env bash
@milpa.load_util garage

@garage.curl "key" | jq -r --argjson noids "${MILPA_OPT_NAME_ONLY:-false}" 'map(if $noids then .name else ([.id, .name] | join("\t")) end)[]'
