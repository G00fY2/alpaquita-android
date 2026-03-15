#!/usr/bin/env bash
set -euo pipefail

prepare_regex_list() {
    echo "$1" | tr '[:space:],\n' '\n' | grep -v '^$' | paste -sd '|' -
}

minor_regex=$(prepare_regex_list "$1")
patch_regex=$(prepare_regex_list "$2")

current_year=$(date +%Y)
version_prefix="v$current_year."

latest_tag=$(git tag --list "v*" | tail -n 1 || true)
is_new_year=false
if [[ ! "$latest_tag" == v"$current_year".* ]]; then
    is_new_year=true
fi

conv_pattern="[a-z]+(\(.+\))?(!)?: "
full_minor_regex="^($minor_regex)$conv_pattern|\* ($minor_regex)$conv_pattern"
full_patch_regex="^($patch_regex)$conv_pattern|\* ($patch_regex)$conv_pattern"

commit_range="${latest_tag:-HEAD~1}..HEAD"
commits=$(git log "$commit_range" --format=%B 2>/dev/null || echo "")

has_minor_bump=$(echo "$commits" | grep -qE "$full_minor_regex" && echo true || echo false)
has_patch_bump=$(echo "$commits" | grep -qE "$full_patch_regex" && echo true || echo false)

bumped=false
if [ "$is_new_year" = true ]; then
    version="${version_prefix}1.0"
    reason="new-year-reset"
    bumped=true
elif [ "$has_minor_bump" = true ]; then
    version_num=${latest_tag#"$version_prefix"}
    minor=$(echo "$version_num" | cut -d. -f1)
    version="${version_prefix}$((minor + 1)).0"
    reason="minor-bump"
    bumped=true
elif [ "$has_patch_bump" = true ]; then
    version_num=${latest_tag#"$version_prefix"}
    minor=$(echo "$version_num" | cut -d. -f1)
    patch=$(echo "$version_num" | cut -d. -f2)
    version="${version_prefix}${minor}.$((patch + 1))"
    reason="patch-bump"
    bumped=true
else
    version="$latest_tag"
    reason="none"
    bumped=false
fi

printf '{"version": "%s", "reason": "%s", "bumped": %s}\n' "$version" "$reason" "$bumped"
