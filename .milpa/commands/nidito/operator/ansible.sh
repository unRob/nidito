#!/usr/bin/env bash

at_root "ansible"

pipenv run tame -l "${MILPA_ARG_HOSTS[@]// /,}" --diff --tags "${MILPA_ARG_ROLE}" ${MILPA_OPT_DRY_RUN:+--check}
