#!/usr/bin/env bash

@milpa.load_util config
args=()

if [[ "$MILPA_OPT_SECRET" ]]; then
  args+=("--secret")
fi

if [[ "$MILPA_OPT_FLUSH" ]]; then
  args+=("--flush")
fi

file="$(@config.name_to_path "${MILPA_ARG_NAME}")" || exit 0
joao set "${args[@]}" "$file" "$MILPA_ARG_PATH" || @milpa.fail "Could not update $MILPA_ARG_NAME"
