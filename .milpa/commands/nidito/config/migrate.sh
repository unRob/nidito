#!/usr/bin/env bash

@milpa.log info "getting template"
op item template get password | jq 'setpath(["fields", 0, "value"]; "unused")' > template.json
@milpa.log success "got template"
mkdir -p config/migrated

for file in datacenters services hosts networks; do
  original="config/$file.yaml"
  migrated="config/migrated/$file.yaml"
  @milpa.log info "finding secret keys of $file"
  yq -o json "$original" |
    jq '[ tostream |
      select(length == 2) |
      select( (.[0] | last == "encrypted") and .[1] == true ) |
      .[0] |
      del(.[length-1])
    ]' > keys

  @milpa.log info "generating 1password item json"
  jq --arg title "$file" --slurp '
    .[0] as $secrets |
    .[1] as $keys |
    .[2] as $tpl |
    {
      title: $title,
      sections: (
        $keys | map(.[0] | {id: ., label: .}) | unique
      ),
      fields: ((
        $keys | map(
          . as $path |
          del(.[0]) as $key |
          ($secrets | getpath($path)) as $secret |
          {
            id: ($path | join(".")),
            label: ($key | join(".")),
            value: $secret,
            section: {id: $path[0]},
            type: "STRING",
            purpose: (
              if ($secret | contains("\n")) then "NOTES"
              else "" end
            )
          }
        )
      ) + $tpl.fields)
    }
  ' <(gcy get "$original" .) keys template.json > "config/migrated/$file.json" || @milpa.fail "could not generate 1password item" #|
  trap 'rm -rf config/migrated/*.json' ERR EXIT

  @milpa.log info "creating 1password item"
  op item create \
    --vault nidito-admin \
    --category password \
    --template="config/migrated/$file.json" || @milpa.fail "could not create 1password item"

  @milpa.log info "creating migrated yaml config"
  cp "$original" "$migrated"
  jq -r 'map(join("."))[]' keys | while read -r key; do
    printf '%s' "!!secret" | gcy set --plain-text "$migrated" "$key"
  done
  yq 'del(.crypto)' "$migrated" | sed "s/'!!secret'/!!secret/g" >"$migrated.clean"
  mv "$migrated.clean" "$migrated"
  @milpa.log complete "$file processed"
done
