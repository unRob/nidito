#!/usr/bin/env bash

@milpa.log info "Installing config filter in .git/config"
git config filter.op-config.smudge cat
git config filter.op-config.clean "milpa nidito config filter clean %f"
git config filter.op-config.required true
git config diff.op-config.textconv "milpa nidito config filter diff"
git config diff.op-config.binary true
@milpa.log success "Successfully configured\n$(git config --get-regexp '^(filter|diff)\.op-config\..*')"

milpa nidito config fetch || @milpa.fail "Could not fetch config"
