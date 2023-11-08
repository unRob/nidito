#!/usr/bin/env bash
@milpa.load_util config

while read -r dc endpoint; do
  if ! [[ "$endpoint" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    endpoint="$(dig +short "$endpoint" @1.1.1.1)"
  fi
  printf '%s\t%s\n' "$dc" "$endpoint"
done < <(
  @config.tree "dc" |
    jq -r 'to_entries | map([.key, (.value.peering.endpoint | split(":") | first)])[] | @tsv'
  ) |
  jq \
    --raw-input --slurp --raw-output \
    --arg format "$MILPA_OPT_FORMAT" \
    'if $format == "text" then . else (
      split("\n") | map(select(. != "") | split("\t") | {key: .[0], value: .[1]}) | from_entries
    ) end'
