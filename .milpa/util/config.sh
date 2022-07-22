#!/usr/bin/env bash

CONFIG_DIR="${NIDITO_ROOT}/config"
export CONFIG_DIR

function @config.dir () {
  echo "$CONFIG_DIR"
}

function @config.jq_module_dir () {
  echo "${MILPA_COMMAND_REPO}/util/jqlib"
}

function @config.all_files () {
  find -s "$CONFIG_DIR" -not \( -path "$CONFIG_DIR/_ignored" -prune -o -path "$CONFIG_DIR/.diff" -prune \) -name '*.yaml'
}

function @config.names () {
  while read -r file; do
    name="$(@config.path_to_name "$file")"
    if [[ $name =~ "$1:"* ]]; then
      echo "${name#*:}"
    fi
  done < <(@config.all_files)
}

function @config.path_to_name () {
  fname=$(readlink -f "$1" || echo "$1")
  fname="${fname##"${CONFIG_DIR}/"}"
  fname="${fname%.yaml}"
  echo "${fname//\//:}"
}

function @config.name_to_path () {
  echo "${CONFIG_DIR}/${1//://}.yaml"
}

function @config.get () {
  yq -o json '.' "$(@config.name_to_path "$1")" | jq -r "$2"
}

function @config.tree () {
  while read -r file; do
    name="$(@config.path_to_name "$file")"
    if [[ $name =~ "$1:"* ]]; then
      jq --arg name "${name#*:}" '{ ($name): .}' <(yq -o json '.' "$file")
    fi
  done < <(@config.all_files) | jq --slurp 'reduce .[] as $i ({}; . * $i) | '"${2:-.}"
}

function @config.write () {
  yq -o json '.' "$(@config.name_to_path "$1")" | jq "$2"
}


function @config.file_as_json () {
  # shellcheck disable=2016
  yq -o json '. as $tree |
    $tree.["~annotations"] = {} |
    with(...;
      select(
        tag == "!!int" or
        tag == "!!float" or
        tag == "!!bool" or
        tag == "!!secret"
      ) |
      (tag | sub("!!", "")) as $tag |
      . tag = "!!str" |
      (path | join(".")) as $path |
      $tree.["~annotations"][$path] = $tag
    ) |
    del($tree.["~annotations"][""]) |
    $tree |
    with(...; select(tag == "!!int" or
        tag == "!!float" or
        tag == "!!bool" or
        tag == "!!secret") | . tag="!!str")
  ' "$1" || @milpa.fail "Could not get $1 as json"
}

function @config.remote () {
  @milpa.log info "fetching remote config item $1"
  op item get \
    --vault "${NIDITO_CONFIG_VAULT:-nidito-admin}" \
    --format json \
    "$1" || @milpa.log error "Could not fetch remote item"
}

function @config.remote_as_yaml () {
  # shellcheck disable=2016
  yq '.fields as $fields |
  with(.fields[];
    .id ref $id |
    .value tag = ( ($fields[] | select(.section.label == "~annotations" and .label == $id) | "!!" + (.value // "str")) ) |
    .value style = ""
  )
  | .fields | map(select(
    .value != ~
    and .id != "password"
    and .id != "notesPlain"
    and .section.label != "~annotations"
  )) | .[] as $f ireduce ({};
    eval("." + ($f.id | sub(".(\d+)(.?)", "[${1}]${2}"))) = $f.value
  )' <(@config.remote "$1")
}

# returns a kv pair like for an existing config file and its remote source
# section.field\.name[type|delete](=value)
function @config.op_update_args () {
  path="$(@config.name_to_path "$1")"
  jq -L"$(@config.jq_module_dir)" -j -r --exit-status \
    --arg title "$1" \
    --arg sep "$3" \
    --argjson remote "$(@config.remote "$1")" \
    --arg hash "$2" \
    'include "op";
    tree_to_fields($hash) |
    (($remote.fields | field_keys) - field_keys) as $to_delete |
    fields_to_cli($to_delete; $sep)' <(@config.file_as_json "$path")
}

function @config.op_file_as_json () {
  path="$(@config.name_to_path "$1")"
  modules="$(@config.jq_module_dir)"
  jq -L"$modules" --exit-status \
  --arg title "$1" \
  --arg hash "$2" \
  'include "op"; tree_to_fields($hash) | fields_to_item($title)' <(@config.file_as_json "$path")
}

function @config.remote_hash () {
  op item get --vault nidito-admin --fields 'label=password' "$1"
}
