#!/usr/bin/env bash
@milpa.load_util config

function diffing () {
  if [[ "${#MILPA_ARG_NAME}" -eq 0 ]]; then
    @config.all_files
  fi

  for name in "${MILPA_ARG_NAME[@]}"; do
    @config.name_to_path "$name"
  done | sort
}

set -o pipefail
joao diff $(diffing) | delta || @milpa.fail "Remote and local config differ"

@milpa.log complete "remote and local configs match!"
