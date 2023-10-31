#!/usr/bin/env bash
@milpa.load_util garage tmp

@tmp.file layout

# https://garagehq.deuxfleurs.fr/api/garage-admin-v0.html#tag/Layout/operation/GetLayout
@garage.curl "layout" > $layout || @milpa.fail "Could not fetch current layout"

if ! jq --exit-status "(.stagedRoleChanges | length) > 0" "$layout" >/dev/null; then
  @milpa.log success "Current layout found for version $(jq -r ".version" "$layout")"
  @garage.role_table roles "$layout"
else
  @milpa.log warning "Staged changes ($(jq -r ".version" "$layout")) pending apply!"
  diff -u -L current <(@garage.role_table roles "$layout") -L staged <(@garage.role_table stagedRoleChanges "$layout") | delta || true
fi
