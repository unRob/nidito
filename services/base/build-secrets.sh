#!/usr/bin/env bash

printf '%s\x00' "CA_PEM$(joao get "$NIDITO_ROOT/config/service/ca.yaml" cert)"
