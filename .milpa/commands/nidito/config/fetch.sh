#!/usr/bin/env bash
#!/usr/bin/env bash

@milpa.load_util config

function fetching () {
  if [[ "${#MILPA_ARG_NAME}" -eq 0 ]]; then
    @config.remote_items
    return
  fi

  for name in "${MILPA_ARG_NAME[@]}"; do
    @config.name_to_path "$name"
  done | sort
}

# merge remote config with filesystem
args=()
if [[ "$MILPA_OPT_DRY_RUN" ]]; then
  args+=(--dry-run)
fi
joao fetch "${args[@]}" $(fetching) || @milpa.fail "Could not fetch"

@milpa.log complete "Done fetching secrets from 1password"
