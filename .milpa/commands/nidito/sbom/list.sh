#!/usr/bin/env bash

root="$(milpa nidito service root)"

function list_upgradeable() {
  ansible="${root%%/services*}/ansible/group_vars/all.yml"
  jq -n -r '[inputs] | add | to_entries |
    reduce .[] as $item ([]; . + (
      $item.value | to_entries | map(
        select(.value.check) |
        [$item.key, .key, .value.version, .value.check, .value.source, .value.comparison // "strict"]
      )
    )) | map(join(" "))[]' \
    <(if [[ -f "$ansible" ]]; then
        joao get "$ansible" --output json . | jq -r '{"infra": .}'
      else
        echo "{}"
      fi
    ) \
    <(while read -r service_spec; do
      name=$(basename "${service_spec//.spec.yaml/}")
      joao get "$service_spec" --output json . | jq -r --arg name "$name" '{
        ($name): ( (.packages // {}) + (.dependencies // {}) )
      }'
    done < <(find "$root" -name "*.spec.yaml" -maxdepth 2 | sort))
}

if [[ "$MILPA_OPT_UPGRADEABLE" ]]; then
  list_upgradeable
  exit $?
fi

while read -r group package version _; do
  echo "$group: $package @ $version"
done < <(list_upgradeable)


