#!/usr/bin/env bash
@milpa.load_util garage

@garage.curl "key?showSecretKey=${MILPA_OPT_SHOW_SECRET}&search=${MILPA_ARG_NAME// /+}"
