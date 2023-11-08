#!/usr/bin/env bash
@milpa.load_util garage tmp

@tmp.file layout

# https://garagehq.deuxfleurs.fr/api/garage-admin-v0.html#tag/Layout/operation/GetLayout
# shellcheck disable=2154
@garage.curl "layout" > "$layout" || @milpa.fail "Could not fetch current layout"

if jq --exit-status "(.stagedRoleChanges | length) != 0" "$layout" >/dev/null; then
  @milpa.fail "Pending modifications in queue, apply or revert first"
fi

@milpa.log info "opening editor with current layout"
jq '.roles' "$layout" > "$layout.staged.json"
cp "$layout.staged.json" "$layout.orig"
trap 'rm "$layout.staged.json" "$layout.orig"' ERR EXIT
vim -f "$layout.staged.json"

if diff -q "$layout.staged.json" "$layout.orig" >/dev/null; then
  @milpa.fail "Stopping: proposing no changes to current layout"
fi

@milpa.log info "Proposed changes:"
diff -u -L current.json "$layout.orig" -L proposed.json "$layout.staged.json" | delta || true
@milpa.load_util user-input

@milpa.confirm "Stage these changes?" || @milpa.fail "No changes staged"

#https://garagehq.deuxfleurs.fr/api/garage-admin-v0.html#tag/Layout/operation/AddLayout
@garage.curl "layout" -H "Content-type: application/json" -d @"$layout.staged.json" || @milpa.fail "Failed proposing layout changes"

@milpa.log complete "Successfully proposed changes"
