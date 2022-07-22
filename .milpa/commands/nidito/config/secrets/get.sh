#!/usr/bin/env bash
@milpa.load_util config

function get_op_item_as_map() {
  @config.remote "$1" | jq '
    ( .fields |
      map(select(.section.label == "~annotations")) |
      reduce .[] as $f ({}; setpath([$f.label]; $f.value | rtrimstr("\n")))
    ) as $annotations |
    .fields |
    map(select(.value and .section.label != "~annotations" and .id != "password" and .id != "notesPlain")) |
    reduce .[] as $f ({};
      ($annotations[$f.id] // "secret" | . != "secret") as $needs_cast |
      setpath(
        $f.id | split(".") | map(if test("\d+") then from_json else . end );
        $f.value | if $needs_cast then fromjson else . end )
    )' || @milpa.fail "Could not parse 1password item into map"
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
