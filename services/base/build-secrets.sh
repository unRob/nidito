#!/usr/bin/env bash

joao get "$NIDITO_ROOT/config/service/ca.yaml" cert > "$service_folder/BUILD_SECRET_CA_PEM"
echo "CA_PEM"
