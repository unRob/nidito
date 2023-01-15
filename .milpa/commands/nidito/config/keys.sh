#!/usr/bin/env bash
@milpa.load_util config

file="$(@config.name_to_path "${MILPA_ARG_NAME}")" || exit 0

joao get --output json "$file" . |
  jq -r --arg query "$MILPA_ARG_QUERY" '
    reduce paths(scalars) as $p ([]; . + [$p | map(tostring) | join(".")]) |
    map(
      select(. | startswith($query)) |
      gsub("^(?<m>\($query)[^.]+.?).*"; "\(.m)")
    ) |
    unique[]'
