#!/usr/bin/env bash
@milpa.load_util garage

@garage.curl "bucket?globalAlias=$MILPA_ARG_NAME"
