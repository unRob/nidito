#!/usr/bin/env bash
@milpa.load_util config

@config.merged_secrets "$(@config.path_to_name "$MILPA_ARG_FILE")" "$MILPA_ARG_FILE"
