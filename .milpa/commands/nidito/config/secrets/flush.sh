#!/usr/bin/env bash

@milpa.load_util config tmp

set -o pipefail
while read -r file; do
  name=$(@config.path_to_name "$file")
  @milpa.log info "Processing $(@milpa.fmt bold "$name") @ $file"
  @milpa.log debug "config file for $name at $file"
  hash="$(openssl dgst -md5 -hex <"$file")"

  if remote_hash=$(@config.remote_hash "$name") 2>/dev/null ; then
    if [[ $hash == "$remote_hash" ]]; then
      @milpa.log success "$name is up to date with remote"
      continue
    fi

    @milpa.log info "Updating 1Password item for $name secrets"
    @config.op_file_as_update "$name" "$hash" | op item edit --vault nidito-admin "$name"  || @milpa.fail "could not update 1password item"
    @milpa.log success "Updated $name"
  else
    @milpa.log info "Generating 1Password item for $name secrets"
    @config.op_file_as_json "$name" "$hash" | op item create --vault nidito-admin >/dev/null || @milpa.fail "could not create 1password item"
    @milpa.log success "Created $name"
  fi
# done < <(echo "config/host/bedstuy.yaml")
done < <(@config.all_files)

@milpa.log complete "Flushed secrets to 1password"
