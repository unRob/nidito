#!/usr/bin/env bash
@milpa.load_util tmp config

dst=""
if [[ "$MILPA_OPT_CACHE" ]]; then
  dst="$(@config.dir)/.diff"
else
  @tmp.dir dst
fi

function diffing () {
  if [[ "${#MILPA_ARG_NAME}" -eq 0 ]]; then
    @config.all_files
  fi

  for name in "${MILPA_ARG_NAME[@]}"; do
    @config.name_to_path "$name"
  done | sort
}

while read -r file; do
  name="$(@config.path_to_name "$file")"
  remote="$dst/remote/${name//://}.yaml"
  fs="$dst/local/${name//://}.yaml"

  if [[ ! -f "$remote" ]]; then
    mkdir -p "$(dirname "$remote")"
    @config.remote_as_tree "$name" yaml | yq 'sort_keys(..)' > "$remote"
  fi
  mkdir -p "$(dirname "$fs")"
  yq '... comments="" | sort_keys(..)' "$file" > "$fs"
done < <(diffing)

set -o pipefail
diff --exclude='_ignored/*' --unified --recursive "$dst/remote" "$dst/local" | delta || @milpa.fail "Remote and local config differ"

@milpa.log complete "remote and local configs match!"
