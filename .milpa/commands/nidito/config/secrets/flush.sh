#!/usr/bin/env bash

config_dir="$NIDITO_ROOT/config"
template="$(mktemp /tmp/op-item-template.json.XXXXXX)"
trap 'rm -rf $template' ERR EXIT

function find_files () {
  find -s "$config_dir" -not \( -path "$config_dir/_ignored" -prune \) -name '*.yaml'
}

function path_to_op_name () {
  fname="${1#"${config_dir}/"}"
  fname="${fname%.yaml}"
  echo "${fname//\//:}"
}

function get_existing_item () {
  op item get \
    --vault nidito-admin \
    --format json \
    "$1" || printf '%s' "null"
}

function fs_config_as_json () {
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

function tpl_with_password () {
  jq 'setpath(["fields", 0, "value"]; $password)' --arg password "$1" "$template"
}

function op_body () {
  jq -r --slurp --exit-status --arg title "$1" --arg format "$2" '
    .[0] as $fs |
    .[1] as $original |
    ( $fs |
      reduce leaf_paths as $path ({}; . + { ($path | map(tostring) | join(".")): $fs | getpath($path) })
    ) as $flatmap |
    {
    title: $title,
    category: "PASSWORD",
    sections: (
      $fs | keys |
      map(select(
          ($fs[.] | type) == "object" or
          ($fs[.] | type) == "array"
      )) | map({id: ., label: .})
    ),
    fields: ((
      $flatmap |
      to_entries |
      map(
        . as $kv |
        (
          if (.key | contains(".")) then (
            {id: (.key | split(".") | first)}
          ) else null end
        ) as $section |
        (if (.key | contains(".")) then (.key | split(".") | del(.[0]) | join(".") ) else .key end) as $key |

        {
          id: .key,
          label: $key,
          value: .value,
          section: $section,
          type: "STRING",
          purpose: ""
        }
      )
    ))
  } |
  if $format == "json" then
    (. + $original.fields)
  else
    (.fields | map(
      (.section.id // "")+(if .section then  "." else "" end)+
      (.label | gsub("\\."; "\\."))+
      "[text]="+.value
    )) + (
      $original.fields |
      map(.id // .label) - ($flatmap | keys + ["password", "notesPlain"]) // [] |
      map(.+"[delete]")
    ) |
    sort |
    join("")
  end' "$3" "$4"
}

op item template get password --format json > "$template" || @milpa.fail "could not create password template"
@milpa.log info "got template at $template"

IFS=$'\n' read -d '' -ra existing < <(op item list --format json --vault nidito-admin | jq -r 'map(.title)[]')

set -o pipefail
while read -r file; do
  name=$(path_to_op_name "$file")
  fs_config=$(fs_config_as_json "$file") || @milpa.fail "could not load $file as yaml"
  fs_hash=$(openssl dgst -md5 -hex <"$file")

  if [[ " ${existing[*]} " =~ ' '"${name}"' ' ]]; then
    @milpa.log info "Updating 1Password item for $name secrets"

    op_body "$name" "weird" <(echo "$fs_config") <(get_existing_item "$name")
    IFS=$'' read -d '' -ra args < <(op_body "$name" "weird" <(echo "$fs_config") <(get_existing_item "$name"))
    op item edit --vault nidito-admin "$name" -- "${args[@]}" || @milpa.fail "could not create 1password item"
  else
    @milpa.log info "Generating 1Password item for $name secrets"

    op_body "$name" "json" <(echo "$fs_config") <(tpl_with_password "$fs_hash") |
      op item create --vault nidito-admin || @milpa.fail "could not create 1password item"
  fi
done < <(find_files) # <(echo "${NIDITO_ROOT}/config/host/chapultepec.yaml") #
