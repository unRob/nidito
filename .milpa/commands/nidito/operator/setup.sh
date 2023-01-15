#!/usr/bin/env bash

@milpa.log info "Installing config filter in .git/config"
git config filter.joao.smudge cat
git config filter.joao.clean "joao git-filter clean %f"
git config filter.joao.required true
git config diff.joao.textconv "joao git-filter diff"
@milpa.log success "Successfully configured\n$(git config --get-regexp '^(filter|diff)\.joao\..*')"

milpa nidito config fetch || @milpa.fail "Could not fetch config"
