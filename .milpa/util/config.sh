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
  fname=$(readlink -f "$1" || echo "$1")
  fname="${fname##"${CONFIG_DIR}/"}"
  fname="${fname%.yaml}"
  echo "${fname//\//:}"
}

function @config.name_to_path () {
  echo "${CONFIG_DIR}/${1//://}.yaml"
}

function @config.get () {
  local name query fmt raw file;
  name="$1"
  query="$2"
  fmt="${3:-json}"
  raw="${4:-tree}"
  file="$(@config.name_to_path "$name")"
  if [[ "$fmt" == "yaml" ]]; then
    yq '.' "$file"
  else
    jq '.' <(@config.file_as_json "$file")
  fi | @config.query "$query" "$fmt" "$raw"
}

function @config.get_remote () {
  local name query fmt raw;
  name="$1"
  query="$2"
  fmt="$3"
  raw="${4:-tree}"
  set -o pipefail
  @config.remote_as_tree "$name" "$fmt" | @config.query "$query" "$fmt" "$raw"
}

function @config.query () {
  local query fmt raw;
  query="$1"
  fmt="$2"
  raw="${3:-tree}"
  case "$fmt-${raw}" in
    json-tree) jq --arg q "${query#.}" 'if $q == "" then . else getpath($q | split(".") | map(if test("^\\d+$") then tonumber else . end)) end' ;;
    json-raw) jq -r --arg q "${query#.}" 'if $q == "" then . else getpath($q | split(".") | map(if test("^\\d+$") then tonumber else . end)) end | if (type == "array") then .[] else . end' ;;
    yaml-tree) yq ".${query#.}" ;;
    yaml-raw) yq -r ".${query#.} | with(select(. type = \"!!seq\"); . = .[])" ;;
    *)
  esac
}


function @config.tree () {
  while read -r file; do
    name="$(@config.path_to_name "$file")"
    if [[ $name =~ "$1:"* ]]; then
      jq --arg name "${name#*:}" '{ ($name): .}' <(yq -o json '.' "$file")
    fi
  done < <(@config.all_files) | jq --slurp 'reduce .[] as $i ({}; . * $i) | '"${2:-.}"
}

function @config.write_secret () {
  # shellcheck disable=2016
  query="$2" value="$3" yq \
    '"." + (env(query) | sub(".(\d+)(.?)", "[${1}]${2}")) as $key |
    with(eval($key); . = env(value) | . tag = "!!secret" | . style = "double")
    ' "$(@config.name_to_path "$1")"
}

function @config.write () {
  # shellcheck disable=2016
  query="$2" value="$3" yq \
    '"." + (env(query) | sub(".(\d+)(.?)", "[${1}]${2}")) as $key |
    with(eval($key); . = env(value))
    ' "$(@config.name_to_path "$1")"
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

function @config.remote_as_tree () {
  # shellcheck disable=2016
  case "${2:-yaml}" in
    yaml)
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
      ;;
    json)
      jq  -L"$(@config.jq_module_dir)" -r --argjson withAnnotations "${3:-false}" 'include "op"; .fields | fields_to_tree($withAnnotations)' <(@config.remote "$1")
      ;;
    *) @milpa.fail "Unknown tree format <$2>"
  esac
}

function @config.op_file_as_update () {
  path="$(@config.name_to_path "$1")"
  jq -L"$(@config.jq_module_dir)" -j -r --exit-status \
    --arg title "$1" \
    --argjson remote "$(@config.remote "$1")" \
    --arg hash "$2" \
    'include "op"; tree_to_fields($hash) | fields_to_item($title; $remote)' <(@config.file_as_json "$path")
}

function @config.op_file_as_json () {
  path="$(@config.name_to_path "$1")"
  jq -L"$(@config.jq_module_dir)" --exit-status \
  --arg title "$1" \
  --arg hash "$2" \
  'include "op"; tree_to_fields($hash) | fields_to_item($title)' <(@config.file_as_json "$path")
}

function @config.remote_hash () {
  op item get --vault nidito-admin --fields 'label=password' "$1"
}

function @config.remote_items () {
  op item list --vault nidito-admin --format json | jq -r 'map(.title) | sort[]'
}

function @config.file_hash () {
  openssl dgst -md5 -hex <"$1"
}

function @config.upsert () {
  local file="$1" dry_run="${2:-}"
  name=$(@config.path_to_name "$file") || @milpa.fail "could not find name for $file"
  @milpa.log info "Writing $(@milpa.fmt bold "$name") @ $file"
  @milpa.log debug "config file for $name at $file"
  hash="$(@config.file_hash "$file")"

  if remote_hash=$(@config.remote_hash "$name" 2>/dev/null) ; then
    if [[ $hash == "$remote_hash" ]]; then
      @milpa.log success "$name is up to date with remote"
      return
    fi

    @milpa.log info "Updating 1Password item for $name secrets"
    [[ "$dry_run" ]] && { @milpa.log warning "dry-run, no changes made"; return; }
    @config.op_file_as_update "$name" "$hash" | op item edit --dry-run --vault nidito-admin "$name" || @milpa.fail "could not update 1password item"
    @milpa.log success "Updated $name"
  else
    @milpa.log info "Generating 1Password item for $name secrets"
    [[ "$dry_run" ]] && { @milpa.log warning "dry-run, no changes made"; return; }
    @config.op_file_as_json "$name" "$hash" | op item create --vault nidito-admin >/dev/null || @milpa.fail "could not create 1password item"
    @milpa.log success "Created $name"
  fi
}


function @config.remote_secrets() {
  jq '(.["~annotations"] // {}) as $annotations |
    del(.["~annotations"]) |
    . as $tree |
    $annotations |
    to_entries | map(
      select(.value == "secret") |
      (
        .key |
        split(".") |
        map(if test("^\\d+$") then tonumber else . end)
      ) as $path |
      .value = ($tree | getpath($path))
    ) |
    from_entries
  ' <(@config.remote_as_tree "$1" "json" "true")
}

function @config.merged_secrets () {
  fs="$2" yq 'load(strenv(fs)) * .' <(@config.remote_as_tree "$1" "yaml")
  # yq ea '. as $item ireduce ({}; . * $item )' $2 <(@config.remote_as_tree "$1" "yaml")
  # secrets="$(@config.remote_secrets "$1")" yq '
  #   . as $data |
  #   (env(secrets) | to_entries) as $secrets |
  #   with($secrets[];
  #     (.key | sub(".(\d+)(.?)", "[${1}]${2}")) as $key |
  #     .value as $value |
  #     with(eval("$data." + $key);
  #       . = $value | . tag = "!!secret" | . style = ""
  #     )
  #   ) | $data
  # ' "$2"
}
