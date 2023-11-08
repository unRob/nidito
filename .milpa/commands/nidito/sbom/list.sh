#!/usr/bin/env bash

function list_upgradeable() {
  jq -n -r '[inputs] | add | to_entries |
    reduce .[] as $item ([]; . + (
      $item.value | to_entries | map(
        select(.value.check) |
        [$item.key, .key, .value.version, .value.check, .value.source, .value.comparison // "strict"]
      )
    )) | map(join(" "))[]' \
    <(joao get "$NIDITO_ROOT/ansible/group_vars/all.yml" --output json . | jq -r '{"infra": .}') \
    <(while read -r service_spec; do
      name=$(basename "${service_spec//.spec.yaml/}")
      joao get "$service_spec" --output json . | jq -r --arg name "$name" $'{($name): (.packages // {})}'
    done < <(find "$NIDITO_ROOT"/services -name "*.spec.yaml" -maxdepth 2 | sort))
}

if [[ "$MILPA_OPT_UPGRADEABLE" ]]; then
  list_upgradeable
  exit $?
fi

while read -r group package version _; do
  echo "$group: $package @ $version"
done < <(list_upgradeable)


