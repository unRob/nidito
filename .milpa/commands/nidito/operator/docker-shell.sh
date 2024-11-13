#!/usr/bin/env bash

case "$MILPA_OPT_MODE" in
  node)
    exec docker run \
      --rm -it \
      -e OP_CONNECT_HOST=https://op.nidi.to \
      -e OP_CONNECT_TOKEN="$(milpa creds "op connect nidito-admin")" \
    registry.nidi.to/base-operator:latest
    ;;
  dev)
    exec docker run --pull always --rm -it \
      -v /run/host-services/ssh-auth.sock:/ssh-auth.sock \
      -e SSH_AUTH_SOCK="/ssh-auth.sock" \
      -v "$NIDITO_ROOT:/nidito" \
      -v "$NIDITO_ROOT/services/base/operator/bootstrap.sh:/etc/profile.d/bash-bootstrap.sh" \
      -v "$NIDITO_ROOT/services/base/operator/.milpa:/usr/local/lib/milpa/repos/operator" \
      registry.nidi.to/base-operator:latest
  ;;
esac
