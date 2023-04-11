#!/usr/bin/env bash
@milpa.load_util config

case "$MILPA_OPT_SOURCE" in
  vault)
    p="${MILPA_ARG_PATH%.}"
    q=".data${p:+.}${p}"
    vault kv get -format json "cfg/infra/tree/$MILPA_ARG_FILE" | jq "$q"
  ;;
  op)
    file="$(@config.name_to_path "${MILPA_ARG_FILE}")" || exit 0
    joao get "$file" --remote "${MILPA_ARG_PATH}" --output "${MILPA_OPT_FORMAT}"
    ;;
  names)
    file="$(@config.name_to_path "${MILPA_ARG_FILE}")" || exit 0
    joao get "$file" "${MILPA_ARG_PATH}" --output "${MILPA_OPT_FORMAT}"
    ;;
  *) @milpa.fail "Unknown source $MILPA_OPT_SOURCE"
esac
