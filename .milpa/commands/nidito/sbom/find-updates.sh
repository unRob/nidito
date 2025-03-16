#!/usr/bin/env bash

export GH_PAT="$(op item get https://github.com --field api.token --reveal)" || @milpa.fail "Could not read github token"

function find_latest() {
  local name package check source filter prog extra_args;
  name="$1"
  package="$2"
  check="$3"
  source="$4"
  prog="jq -r"
  extra_args=()
  case "$check" in
    hc-releases)
      base="https://releases.hashicorp.com/${package}/index.json"
      filter='.versions | map(.version | select(test("^[\\d.]+$"; "i"))) | sort_by(split(".") | map(tonumber)) | last'
      ;;
    gitea-releases)
      repo="$(ruby -ruri -e 'puts URI.parse("'"$source"'").path.split("/").last(2).join("/")')"
      base="${source//$repo}api/v1/repos/$repo/releases"
      filter='map(select(.prerelease | not) | .tag_name) | first'
      ;;
    gitea-tags)
      repo="$(ruby -ruri -e 'puts URI.parse("'"$source"'").path.split("/").last(2).join("/")')"
      base="${source//$repo}api/v1/repos/$repo/tags"
      filter='map(.name) | first'
      ;;
    github-releases*)
      field="tag_name"
      if [[ "$check" != "github-releases" ]]; then
        field="${check##*releases-}"
      fi
      extra_args=( -H "Authorization: bearer $GH_PAT" )
      repo="$(ruby -ruri -e 'puts URI.parse("'"$source"'").path')"
      base="https://api.github.com/repos$repo/releases"
      filter='map(select((.prerelease | not) and ((.'"$field"' | test("(preview|rc|alpha|beta)")) | not)) | .'"$field"') | sort_by(gsub("[^0-9.]"; "") | split(".") | map(tonumber)) | last'
      ;;
    github-tags)
      extra_args=( -H "Authorization: bearer $GH_PAT" )
      repo="$(ruby -ruri -e 'puts URI.parse("'"$source"'").path')"
      base="https://api.github.com/repos$repo/tags"
      filter='map(.name) | sort_by(gsub("[^0-9]+"; ".")) | last'
      ;;
    github-changelog)
      extra_args=( -H "Authorization: bearer $GH_PAT" )
      repo="$(ruby -ruri -e 'puts URI.parse("'"$source"'").path')"
      base="https://raw.githubusercontent.com${repo}/main/CHANGELOG.md"
      # shellcheck disable=2209
      prog=awk
      # shellcheck disable=2016
      filter='/^#{1,3} v?[0-9]+.[0-9]+.[0-9]+/{ print $2; exit;}'
      ;;
    gitlab-commits)
      # removes initial slash and encodes slash as %2F so we don't need to issue two requests
      repo="$(ruby -ruri -e 'puts URI.encode_uri_component(URI.parse("'"$source"'").path.delete_prefix "/")')"
      base="https://gitlab.com/api/v4/projects/$repo/repository/commits"
      filter='map(.id) | first'
      ;;
    *)
      @milpa.fail "unknown check $check for $package $name
      "
  esac

  @milpa.log debug "requesting $base"
  latest=$(curl --fail --silent --show-error "${extra_args[@]}" "$base" | $prog "$filter") || return 2
  echo "$latest"
}

while read -r group package version check source comparison; do
  @milpa.log debug "found package $group:$package"
  if ! latest=$(find_latest "$group" "$package" "$check" "$source"); then
    @milpa.log warning "Could not fetch latest version using check: $check for $group:$package"
    continue
  fi

  word="releases"
  if [[ "$check" = *"-tags" ]]; then
    word="tags"
  fi
  case "$comparison" in
    strict)
      if [[ "$latest" == "$version" ]]; then
        @milpa.log success "$group:$package is up to date at $latest"
        continue
      fi ;;
    prefix)
      if [[ "$latest" =~ ^"$version".* ]]; then
        @milpa.log success "$group:$package is up to date, want $version, latest is $latest"
        continue
      fi ;;
    suffix)
      if [[ "$latest" =~ .*"$version"$ ]]; then
        @milpa.log success "$group:$package is up to date, want $version, latest is $latest"
        continue
      fi ;;
      *)
        @milpa.fail "unknown comparison type for $group:$package <$comparison>"
  esac

  @milpa.log warning "$group:$package has an update: $version => $latest (${source}/${word})"
done < <(milpa nidito sbom list --upgradeable | if [[ "$MILPA_ARG_FILTER" ]]; then grep "$MILPA_ARG_FILTER"; else cat; fi)
