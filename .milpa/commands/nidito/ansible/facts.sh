#!/usr/bin/env bash

at_root "ansible"

pipenv run ansible -m setup "$MILPA_ARG_HOST"
