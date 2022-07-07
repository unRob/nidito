#!/usr/bin/env bash


case "$MILPA_OPT_MODE" in
  node)
    exec docker run \
      --rm -it \
      -e OP_CONNECT_ADDR=https://op.rob.mx \
      -e OP_CONNECT_TOKEN=$(milpa creds "op connect nidito-ci") \
    registry.nidi.to/base-operator:latest
    ;;
  dev)
    exec docker run --rm -it \
      -v /run/host-services/ssh-auth.sock:/ssh-auth.sock \
      -e SSH_AUTH_SOCK="/ssh-auth.sock" \
      -v "$NIDITO_ROOT:/nidito" \
      registry.nidi.to/base-operator:testing
  ;;
esac
