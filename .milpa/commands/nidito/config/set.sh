#!/usr/bin/env bash

@milpa.load_util config
value=""
if [[ -t 1 ]]; then
  prompt="Please enter the value for ${MILPA_ARG_PATH}: "
  read -re -p "$prompt " value
else
  @milpa.log debug "Reading value from stdin"
  value="$(cat)"
fi

writer=@config.write
if [[ "$MILPA_OPT_SECRET" ]]; then
  writer=@config.write_secret
fi

"$writer" "$MILPA_ARG_NAME" "${MILPA_ARG_PATH}" "$value" || @milpa.fail "Could not update $MILPA_ARG_NAME"
