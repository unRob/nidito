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

set -o pipefail
while read -r file; do
  @config.upsert "$file" "${MILPA_OPT_DRY_RUN:+dry-run}"
done < <(flushing)

@milpa.log complete "Flushed secrets to 1password"
