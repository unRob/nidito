#!/usr/bin/env bash
@milpa.load_util garage tmp

@tmp.file layout

# https://garagehq.deuxfleurs.fr/api/garage-admin-v0.html#tag/Layout/operation/GetLayout
# shellcheck disable=2154
@garage.curl "layout" > "$layout" || @milpa.fail "Could not fetch current layout"

if jq --exit-status "(.stagedRoleChanges | length) == 0" "$layout" >/dev/null; then
  @milpa.fail "No pending modifications in queue, \`nidito garage layout edit\` first"
fi

current="$(jq -r ".version" "$layout")"
proposed=$(( current + 1 ))

@milpa.log info "Proposed changes (version $proposed):"
diff -u -L current <(@garage.role_table roles "$layout") -L staged <(@garage.role_table stagedRoleChanges "$layout") | delta || true
@milpa.load_util user-input
@milpa.confirm "Revert changes?" || @milpa.fail "No changes reverted"

@milpa.log info "Reverting staged layout $current => $proposed..."
@garage.curl layout/revert \
  -H "Content-type: application/json" \
  -d "$(jq --null-input --argjson version "$proposed" '{$version}')" || @milpa.fail "Could not revert changes!"
@milpa.log complete "Changes successfully reverted"
