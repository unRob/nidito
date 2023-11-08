#!/usr/bin/env bash

function find_latest() {
  local name package check source filter prog;
  name="$1"
  package="$2"
  check="$3"
  source="$4"
  prog="jq -r"
  case "$check" in
    hc-releases)
      base="https://releases.hashicorp.com/${package}/index.json"
      filter='.versions | map(.version | select(test("^[\\d.]+$"; "i"))) | sort_by(split(".") | map(tonumber)) | last'
      ;;
    gitea-releases)
      repo="$(ruby -ruri -e 'puts URI.parse("'"$source"'").path')"
      base="${source//$repo/}/api/v1/repos$repo/releases"
      filter='map(select(.prerelease | not) | .tag_name) | first'
      ;;
    gitea-tags)
      repo="$(ruby -ruri -e 'puts URI.parse("'"$source"'").path')"
      base="${source//$repo/}/api/v1/repos$repo/tags"
      filter='map(.name) | first'
      ;;
    github-releases)
      repo="$(ruby -ruri -e 'puts URI.parse("'"$source"'").path')"
      base="https://api.github.com/repos$repo/releases"
      filter='map(select(.prerelease | not) | .tag_name) | first'
      ;;
    github-changelog)
      repo="$(ruby -ruri -e 'puts URI.parse("'"$source"'").path')"
      base="https://raw.githubusercontent.com${repo}/main/CHANGELOG.md"
      # shellcheck disable=2209
      prog=awk
      # shellcheck disable=2016
      filter='/^#{1,3} v?[0-9]+.[0-9]+.[0-9]+/{ print $2; exit;}'
  esac

  latest=$(curl --fail --silent "$base" | $prog "$filter") || return 2
  echo "$latest"
}

while read -r group package version check source comparison; do
  @milpa.log debug "found package $group:$package"
  if ! latest=$(find_latest "$group" "$package" "$check" "$source"); then
    @milpa.log warning "Could not fetch latest version using check: $check for $group:$package"
    continue
  fi

  case "$comparison" in
    strict)
      if [[ "$latest" == "$version" ]]; then
        @milpa.log success "$group:$package is up to date at $latest"
        continue
      fi ;;
    prefix)
      if [[ "$latest" =~ ^"$version".* ]]; then
        @milpa.log success "$package is up to date, want $version, latest is $latest"
        continue
      fi ;;
    suffix)
      if [[ "$latest" =~ .*"$version"$ ]]; then
        @milpa.log success "$package is up to date, want $version, latest is $latest"
        continue
      fi ;;
      *)
        @milpa.fail "unknown comparison type for $group:$package <$comparison>"
  esac

  @milpa.log warning "$group:$package has an update: $version => $latest (${source}/releases)"
done < <(milpa nidito sbom list --upgradeable)
