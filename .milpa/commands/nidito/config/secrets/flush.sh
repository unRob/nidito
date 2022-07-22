#!/usr/bin/env bash

# only i can read created files
umask 077

@milpa.load_util config tmp

@milpa.log info "looking up existing vault items"
existing_item_list=""
@tmp.file existing_item_list
op item list --format json --vault nidito-admin | jq -r 'map(.title) | sort[]' > "$existing_item_list" || @milpa.fail "could not get existing item list"

set -o pipefail
while read -r file; do
  name=$(@config.path_to_name "$file")

  @milpa.log info "found $name at $file"
  exists="$(grep -c "^${name}\$" "$existing_item_list" 2>/dev/null)"
  hash="$(openssl dgst -md5 -hex <"$file")"

  if [[ "$exists" == "1" ]] ; then
    # if [[ $hash == "$(@config.remote_hash "$name")" ]]; then
    #   @milpa.log success "$name is up to date with remote"
    #   continue
    # fi
    @config.op_update_args "$name" "$hash" $'\n'
    exit

    @milpa.log info "Updating 1Password item for $name secrets"
    IFS='' read -ra args < <(@config.op_update_args "$name" "$hash" '') #|| @milpa.fail "Could not generate key-value fields for update"
    op item edit --vault nidito-admin "$name" -- "${args[@]}" >/dev/null || @milpa.fail "could not update 1password item"
    @milpa.log success "Updated $name"
  else
    @milpa.log info "Generating 1Password item for $name secrets"
    @config.op_file_as_json "$name" "$hash" | op item create --vault nidito-admin >/dev/null || @milpa.fail "could not create 1password item"
    @milpa.log success "Created $name"
  fi
done < <(echo "config/dc/nyc1.yaml")
# done < <(@config.all_files)

@milpa.log complete "Flushed secrets to 1password"
