#!/usr/bin/env bash

CONFIG_DIR="${NIDITO_ROOT}/config"
export CONFIG_DIR
shopt -s expand_aliases
alias op_v='op --vault "$NIDITO_OP_VAULT"'

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

function @config.get_raw () {
  @config.get "$1" "$2" 'json' 'raw'
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
  printf -v value "%s\n" "$3"
  # shellcheck disable=2016
  query="$2" value="$value" yq -i \
    '"." + (env(query) | sub(".(\d+)(.?)", "[${1}]${2}")) as $key |
    with(eval($key); . = strenv(value) | . tag = "!!secret" | . style = "")
    ' "$(@config.name_to_path "$1")"
}

function @config.write () {
  # shellcheck disable=2016
  query="$2" value="$3" yq -i \
    '"." + (env(query) | sub(".(\d+)(.?)", "[${1}]${2}")) as $key |
    with(eval($key); . = strenv(value))
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
  op_v item get --format json "$1" || @milpa.log error "Could not fetch remote item"
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
        eval("." + ($f.id | sub("\.(\d+)(\.?)", "[${1}]${2}"))) = $f.value
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
    'include "op"; tree_to_fields($hash) |
    (($remote.fields | field_keys) - field_keys) as $to_delete |
    fields_to_cli($to_delete)' <(@config.file_as_json "$path")
}

function @config.op_file_as_json () {
  path="$(@config.name_to_path "$1")"
  jq -L"$(@config.jq_module_dir)" --exit-status \
  --arg title "$1" \
  --arg hash "$2" \
  'include "op"; tree_to_fields($hash) | fields_to_item($title)' <(@config.file_as_json "$path")
}

function @config.remote_hash () {
  op_v item get --fields 'label=password' "$1"
}

function @config.remote_items () {
  op_v item list --format json | jq -r 'map(.title) | sort[]'
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

    {
      @config.op_file_as_update "$name" "$hash" || @milpa.fail "Could not generate key-value fields for update"
    }| xargs -0 -r op --vault "$NIDITO_OP_VAULT" item edit "$name" --  || @milpa.fail "could not update 1password item"
    @milpa.log success "Updated $name"
  else
    @milpa.log info "Generating 1Password item for $name secrets"
    [[ "$dry_run" ]] && { @milpa.log warning "dry-run, no changes made"; return; }
    @config.op_file_as_json "$name" "$hash" | op_v item create >/dev/null || @milpa.fail "could not create 1password item"
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
}
