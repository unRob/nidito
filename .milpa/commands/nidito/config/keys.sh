#!/usr/bin/env bash
@milpa.load_util config

file="$(@config.name_to_path "${MILPA_ARG_NAME}")"

yq -o json '.' "$file" |
  jq -L"$(@config.jq_module_dir)" --arg query "$MILPA_ARG_QUERY" -r 'include "op"; autocomplete($query)'
