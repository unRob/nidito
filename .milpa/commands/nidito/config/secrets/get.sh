#!/usr/bin/env bash

function get_op_item() {
  op item get "$MILPA_ARG_ITEM" --vault "$MILPA_OPT_VAULT" --format json ||
    @milpa.fail "Could not find 1Password item for $MILPA_ARG_ITEM in vault $MILPA_OPT_VAULT"
}

function get_op_item_as_map() {
  get_op_item | jq --arg entry "$1" --argjson tree "${2:-false}" '
    .fields |
    map(
      select(.value) |
      if ($tree | not) then {
        key: "op://nidito-admin/\($entry)/\(.section.label)/\(.label)",
        value: .value
      } else . end
    ) |
    if $tree then
      reduce .[] as $f ({};
        setpath( ([$f.section.label] + ($f.label | split("."))); $f.value )
      )
    else
      from_entries
    end' || @milpa.fail "Could not parse 1password item into map"
}

function get_config_as_json() {
  # shellcheck disable=2016
  yq -o json 'with(...; select(tag == "!!secret") |
    . = (path | .[0] as $section | del(.[0]) |
      "op://nidito-admin/"+strenv(MILPA_ARG_ITEM)+"/"+$section+"/"+(. | join("."))
    )
  )' "$CONFIG_DIR/$MILPA_ARG_ITEM.yaml" || @milpa.fail "Could not get config as json"
}

set -o pipefail
if [[ "$MILPA_OPT_SECRETS_ONLY" ]]; then
  get_op_item_as_map "$MILPA_ARG_ITEM" "true" || exit 2
else
  jq --slurp ' .[0] as $secrets | .[1] | walk(
    if type == "string" and startswith("op://") then
      $secrets[.] // error("Could not find secret at \(.)")
    else . end
  )' <(get_op_item_as_map "$MILPA_ARG_ITEM") <(get_config_as_json) || @milpa.fail "Could not parse config"
fi | if [[ "$MILPA_OPT_FORMAT" == "yaml" ]]; then
  yq -P -
else
  jq .
fi
