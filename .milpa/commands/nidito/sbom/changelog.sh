#!/usr/bin/env bash

curl --silent --show-error --fail --no-buffer "https://raw.githubusercontent.com/hashicorp/${MILPA_ARG_PRODUCT}/main/CHANGELOG.md" 2>/dev/null |
  cat |
  awk '1;/^## .*/{if (NR>1) exit}'|
  sed \$d |
  glow -

