#!/usr/bin/env bash
@milpa.load_util garage

@garage.curl "key" -X POST -d @<(jq --null-input --arg name "$MILPA_ARG_NAME" '{name: $name}') || @milpa.fail "could not create bucket"
