#!/usr/bin/env bash
#!/usr/bin/env bash

@milpa.load_util config

function fetching () {
  if [[ "${#MILPA_ARG_NAME}" -eq 0 ]]; then
    @config.remote_items
    return
  fi

  for name in "${MILPA_ARG_NAME[@]}"; do
    echo "$name"
  done | sort
}

set -o pipefail
base="$(@config.dir)"
while read -r item; do
  file="$(@config.name_to_path "$item")"
  if [[ ! -f  "$file" ]]; then
    # dump remote config into new file
    @milpa.log info "Detected new item $item. Creating $file"
    new_tree="$(@config.remote_as_tree "$item" "yaml")" || @milpa.fail "Could not create $file"
  else
    # merge remote config with filesystem
    if [[ "$(@config.remote_hash "$item")" == "$(@config.file_hash "$file")" ]]; then
      @milpa.log "success" "$item needs no fetch, is up to date"
      continue
    fi
    @milpa.log info "Merging secrets from $item to $file"
    new_tree="$(@config.merged_secrets "$item" "$file")" || @milpa.fail "Could fetch secrets for $file"

    if diff -q "$file" <(echo "$new_tree") >/dev/null; then
      @milpa.log success "No changes to secrets, skipping"
      continue
    fi
  fi

  if [[ "$MILPA_OPT_DRY_RUN" ]]; then
    @milpa.log success "dry-run: would have updated item $item"
    continue
  fi

  @milpa.log info "Writing $item"
  echo "$new_tree" > "$file" || @milpa.fail "Could not write to $file"
  @milpa.log success "Fetched $item"
done < <(fetching)

@milpa.log complete "Done fetching secrets from 1password"
