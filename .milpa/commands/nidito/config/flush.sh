#!/usr/bin/env bash

@milpa.load_util config

function flushing () {
  if [[ "${#MILPA_ARG_NAME}" -eq 0 ]]; then
    @config.all_files
  fi

  for name in "${MILPA_ARG_NAME[@]}"; do
    @config.name_to_path "$name"
  done | sort
}

args=()
if [[ "$MILPA_OPT_DRY_RUN" ]]; then
  args+=(--dry-run)
fi
joao flush "${args[@]}" "$(flushing)"

@milpa.log complete "Flushed secrets to 1password"
