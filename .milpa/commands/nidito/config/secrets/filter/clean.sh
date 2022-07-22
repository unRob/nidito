#!/usr/bin/env bash

# shellcheck disable=2016
yq 'with(...; select(tag == "!!secret") | . = "" | . tag = "!!secret")' "$MILPA_ARG_FILE"
