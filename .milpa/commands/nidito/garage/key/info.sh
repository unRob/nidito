#!/usr/bin/env bash
@milpa.load_util garage

@garage.curl "key?search=$MILPA_ARG_NAME"
