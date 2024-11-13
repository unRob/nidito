#!/usr/bin/env bash

if [[ ! -f ~/.ssh/id_ed25519 ]] && [[ "$OP_CONNECT_TOKEN" ]]; then
  mkdir -pv "$HOME/.ssh"
  @milpa.log info "SSH key not found and op-connect token found, installing key..."
  mkdir -pv /secrets
  op item get --fields 'label=ssh-key' "operator-ssh-key" --format json --vault nidito |
    jq -r .value > /secrets/id_ed25519 || @milpa.fail "could not fetch ssl deploy key"
  chmod 0600 /secrets/id_ed25519
  ln -sfv /secrets/id_ed25519 "/$HOME/.ssh/id_ed25519"
  @milpa.log success "SSH key installed"
fi

if [[ ! -d /nidito ]]; then
  @milpa.log info "Cloning repository /nidito at branch ${MILPA_ARG_BRANCH}"
  mkdir -p "$HOME/.ssh"
  touch "$HOME/.ssh/known_hosts" || @milpa.fail "could not create ssh known_hosts"
  ssh-keyscan -t ed25519 -H github.com >"$HOME/.ssh/known_hosts" || @milpa.fail "could not add github key to known_hosts"
  git clone --depth 1 --branch "${MILPA_ARG_BRANCH}" "${MILPA_ARG_REPO}" /nidito || @milpa.fail "Could not clone nidito repo"
  @milpa.log success "Repository cloned to /nidito"
fi

@milpa.log info "Installing global milpa repo"
cd /nidito
milpa itself repo install --global /nidito

cat >/etc/bash_completion.d/nidito <<-'EOF'
source /etc/bash_completion.d/milpa

function _nidito () {
  # props https://blog.brujordet.no/post/bash/proper-autocompletion-for-bash-alias/
  local alias_name alias_definition alias_value
  alias_name=${COMP_WORDS[0]}
  alias_value="milpa nidito"
  [[ -z $alias_value ]] && return 1

  local comp_words=()
  local alias_value_array=( milpa nidito )

  for word in "${COMP_WORDS[@]}"; do
    if [[ $word == "$alias_name" ]]; then
      comp_words+=("${alias_value_array[@]}")
    else
      comp_words+=("$word")
    fi
  done

  COMP_WORDS=("${comp_words[@]}")

  # Update other COMP variables
  COMP_LINE=${COMP_LINE//${alias_name}/${alias_value}}
  COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))
  COMP_POINT=${#COMP_LINE}

  local previous_word current_word
  current_word=${COMP_WORDS[$COMP_CWORD]}
  if [[ ${#COMP_WORDS[@]} -ge 2 ]]; then
    previous_word=${COMP_WORDS[$(( COMP_CWORD - 1 ))]}
  fi
  local cmd=${COMP_WORDS[0]}
  __start_milpa "${cmd}" "${current_word}" "${previous_word}"
}

complete -o default -F _nidito nidito
EOF

@milpa.log complete "Container bootstrapped for nidito"
