#!/usr/bin/env bash

CONFIG_DIR="${NIDITO_ROOT}/config"
export CONFIG_DIR
shopt -s expand_aliases
alias op_v='op --vault "$NIDITO_OP_VAULT"'

function @config.dir () {
  echo "$CONFIG_DIR"
}


function @config.all_files () {
  find -s "$CONFIG_DIR" -not \( \
    -path "$CONFIG_DIR/_ignored" -prune \
    -o -path "$CONFIG_DIR/.diff" -prune \
    -o -name ".joao.yaml" -prune \
  \) -name '*.yaml'
}

function @config.all_names () {
  @config.all_files | while read -r file; do
    @config.path_to_name "$file"
  done
}

function @config.names () {
  @config.all_files | while read -r file; do
    name="$(@config.path_to_name "$file")"
    if [[ $name =~ "$1:"* ]]; then
      echo "${name#*:}"
    fi
  done
}

function @config.path_to_name () {
  fname=$"$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
  fname="${fname##"${CONFIG_DIR}/"}"
  fname="${fname%.yaml}"
  echo "${fname//\//:}"
}

function @config.name_to_path () {
  echo "${CONFIG_DIR}/${1//://}.yaml"
}

function @config.get () {
  joao get --output "${3:-json}" "$(@config.name_to_path "$1")" "$2"
}

function @config.tree () {
  while read -r file; do
    name="$(@config.path_to_name "$file")"
    if [[ $name =~ "$1:"* ]]; then
      jq --arg name "${name#*:}" '{ ($name): .}' <(joao get --output json "$file")
    fi
  done < <(@config.all_files) | jq --slurp 'reduce .[] as $i ({}; . * $i) | '"${2:-.}"
}

function @config.remote_items () {
  op_v item list --format json | jq -r 'map(.title) | sort[]'
}

