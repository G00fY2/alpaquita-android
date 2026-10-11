#!/usr/bin/env bash
set -euo pipefail

version_base_prefix=$1
commit_scopes=$2
minor_commit_types=$3
patch_commit_types=$4

# Helper function to convert list into pipe-delimited regex format
prepare_regex_list() {
    tr '[:space:],\n' '\n' <<<"$1" | grep -v '^$' | paste -sd '|' -
}

scope_regex=$(prepare_regex_list "$commit_scopes")
minor_regex=$(prepare_regex_list "$minor_commit_types")
patch_regex=$(prepare_regex_list "$patch_commit_types")

current_year=$(date +%Y)
version_prefix="${version_base_prefix}${current_year}."

# Find the latest version tag, fallback to empty string if none exist
latest_tag=$(git tag --list "${version_base_prefix}*" --sort=v:refname | tail -n 1 || true)
is_new_year=false
if [[ ! "$latest_tag" == "${version_base_prefix}${current_year}".* ]]; then
    is_new_year=true
fi

# Define the Conventional Commit structure for the subject line
conv_pattern="(\(($scope_regex\))?(!)?: "
minor_bump_pattern="^($minor_regex)$conv_pattern"
patch_bump_pattern="^($patch_regex)$conv_pattern"

# Get commit subjects from the range
commit_range="${latest_tag:-HEAD~1}..HEAD"
commits=$(git log "$commit_range" --format=%s 2>/dev/null || echo "")

# Analyze commits for bump triggers
has_minor_bump=false
if grep -qE "$minor_bump_pattern" <<<"$commits"; then
    has_minor_bump=true
fi

has_patch_bump=false
if grep -qE "$patch_bump_pattern" <<<"$commits"; then
    has_patch_bump=true
fi

# Determine the new version
bumped=false
if [[ "$is_new_year" == "true" && ("$has_minor_bump" == "true" || "$has_patch_bump" == "true") ]]; then
    version="${version_prefix}1.0"
    reason="new-year-reset"
    bumped=true
elif [[ "$has_minor_bump" == "true" ]]; then
    version_num=${latest_tag#"$version_prefix"}
    minor=$(echo "$version_num" | cut -d. -f1)
    version="${version_prefix}$((minor + 1)).0"
    reason="minor-bump"
    bumped=true
elif [[ "$has_patch_bump" == "true" ]]; then
    version_num=${latest_tag#"$version_prefix"}
    minor=$(echo "$version_num" | cut -d. -f1)
    patch=$(echo "$version_num" | cut -d. -f2)
    version="${version_prefix}${minor}.$((patch + 1))"
    reason="patch-bump"
    bumped=true
elif [[ -z "$latest_tag" ]]; then
    version="${version_prefix}1.0"
    reason="initial-release"
    bumped=true
else
    version="$latest_tag"
    reason="none"
    bumped=false
fi

# Validate the generated version format (vYYYY.M.P)
if [[ ! "$version" =~ ^v[0-9]{4}\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Calculated version '$version' does not match the required 'vYYYY.M.P' format." >&2
    exit 1
fi

# Output result as JSON
printf '{"version": "%s", "reason": "%s", "bumped": %s}\n' "$version" "$reason" "$bumped"
