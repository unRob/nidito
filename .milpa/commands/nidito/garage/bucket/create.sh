#!/usr/bin/env bash
@milpa.load_util garage

@garage.curl "bucket" -X POST -d @<(jq --null-input --arg name "$MILPA_ARG_NAME" '{globalAlias: $name}') || @milpa.fail "could not create bucket"
