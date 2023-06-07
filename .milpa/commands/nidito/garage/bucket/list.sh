#!/usr/bin/env bash
@milpa.load_util garage

@garage.curl "bucket" | jq -r --argjson noids "${MILPA_OPT_NAME_ONLY:-false}" 'map(if $noids then (.globalAliases | first) else ([.id, .globalAliases] | flatten | join("\t")) end)[]'
