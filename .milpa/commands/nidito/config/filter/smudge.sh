#!/usr/bin/env bash
@milpa.load_util config

@config.remote_as_yaml "$(@config.path_to_name "$MILPA_ARG_FILE")"
