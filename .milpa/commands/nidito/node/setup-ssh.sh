#!/usr/bin/env bash

@milpa.load_util tmp
@tmp.file keys


if [[ "$MILPA_ARG_KEY" ]]; then
  grep -q '^ssh-' "$MILPA_ARG_KEY" >/dev/null || @milpa.fail "provided key ($MILPA_ARG_KEY) does not look like a public ssh key"
  key="$(< "$MILPA_ARG_KEY")"
else
  @milpa.load_util user-input
  @milpa.log info "Querying local ssh-agent for available keys..."
  set -o errexit
  set -o pipefail
  # shellcheck disable=2154
  ssh-add -L | awk '{print $1"¬"$2"¬"$3}' > "$keys" || @milpa.fail "could not query agent for keys!"
  set +o errexit
  set +o pipefail
  cat "$keys"
  if [[ "$(grep -c . "$keys")" -gt 1 ]]; then
    @milpa.log info "multiple ssh keys detected, which one should we use?"

    keyNames=$(while IFS="¬" read -r proto key name; do
      if [[ "$name" == "" ]]; then
        @milpa.log warning "skipping commentless key: $proto $key"
        continue
      fi
      echo "$name"
    done < "$keys")

    keyName=$(@milpa.select "$keyNames")
    key=$(awk -F"¬" '$3=="'"$keyName"'" {print $1,$2}' "$keys")
  else
    keyName=$(awk -F"¬" '{print $3}' "$keys")
    key=$(awk -F"¬" '{print $1,$2}' "$keys")
    @milpa.info "Found key: ${keyName:-<unknown>} ($key)"
    @milpa.confirm "Proceed?"
  fi
  @milpa.log info "Using local key named $keyName"
fi


@milpa.log info "Adding local key via SSH, enter password if prompted"
function ensure_ssh_key() {
  # shellcheck disable=2087
  ssh -T -p "$MILPA_OPT_PORT" "$MILPA_ARG_NODE" <<SH
mkdir -p ~/.ssh
if grep "$key" ~/.ssh/authorized_keys >/dev/null; then
  echo "Key already present in ~/.ssh/authorized_keys" >&2
else
  echo "Adding key to ~/.ssh/authorized_keys" >&2
  echo "$key" ">>" ~/.ssh/authorized_keys
fi
SH
}
ensure_ssh_key || @milpa.fail "Could not ensure ssh key got added to host"

@milpa.log success "SSH keys present in host"
