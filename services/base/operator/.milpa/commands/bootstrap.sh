#!/usr/bin/env bash

if [[ ! -f ~/.ssh/id_ed25519 ]] && [[ "$OP_CONNECT_TOKEN" ]]; then
  mkdir -pv "$HOME/.ssh"
  @milpa.log info "SSH key not found and op-connect token found, installing key..."
  mkdir -pv /secrets
  milpa op get --field-filter '.label == "ssh-key"' deploy key > /secrets/id_ed25519 || @milpa.fail "could not fetch ssl deploy key"
  chmod 0600 /secrets/id_ed25519
  ln -sfv /secrets/id_ed25519 "/$HOME/.ssh/id_ed25519"
  @milpa.log success "SSH key installed"
fi

if [[ ! -d /nidito ]]; then
  @milpa.log info "Cloning repository /nidito"
  ssh-keyscan -t ed25519 -H github.com >"/$HOME/.ssh/known_hosts"
  git clone --depth 1 --branch "${MILPA_ARG_BRANCH}" "${MILPA_ARG_REPO}" /nidito
  @milpa.log success "Repository cloned to /nidito"
fi

@milpa.log info "Installing global milpa repo"
milpa itself repo install --global /nidito

@milpa.log complete "Container bootstrapped for nidito"
