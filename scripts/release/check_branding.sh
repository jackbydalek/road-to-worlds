#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
content_legacy_pattern='[Kk]itchen([[:space:]_-]*)[Tt]able|[Rr]oad([[:space:]_-]*)[Tt]o([[:space:]_-]*)[Ww]orlds|[Tt]opdeck[[:space:]]+[Tt]o[[:space:]]+[Ww]orlds|TOPDECK TO WORLDS|Top/Cut:[[:space:]]+Locals[[:space:]]+to[[:space:]]+Worlds'
path_legacy_pattern='[Kk]itchen([[:space:]_-]*)[Tt]able|[Rr]oad([[:space:]_-]*)[Tt]o([[:space:]_-]*)[Ww]orlds'

content_hits="$(git -C "$project_dir" grep -n -I -E -- "$content_legacy_pattern" -- . \
	| grep -v -E '^(project\.godot:.*config/custom_user_dir_name=|scripts/release/check_branding\.sh:)' || true)"
path_hits="$({
	git -C "$project_dir" ls-files --cached --others --exclude-standard
} | while IFS= read -r tracked_path; do
	if [[ -e "$project_dir/$tracked_path" ]] && grep -E -q "$path_legacy_pattern" <<<"$tracked_path"; then
		printf '%s\n' "$tracked_path"
	fi
done)"
archive_hits="$({
	git -C "$project_dir" ls-files --cached --others --exclude-standard '*.xlsx'
} | while IFS= read -r workbook_path; do
	if [[ -f "$project_dir/$workbook_path" ]] && unzip -p "$project_dir/$workbook_path" | grep -E "$content_legacy_pattern" >/dev/null; then
		printf '%s\n' "$workbook_path"
	fi
done)"

if [[ -n "$content_hits" || -n "$path_hits" || -n "$archive_hits" ]]; then
	printf 'Legacy product branding remains in tracked project content or paths.\n' >&2
	if [[ -n "$content_hits" ]]; then
		printf '%s\n' "$content_hits" >&2
	fi
	if [[ -n "$path_hits" ]]; then
		printf '%s\n' "$path_hits" >&2
	fi
	if [[ -n "$archive_hits" ]]; then
		printf '%s\n' "$archive_hits" >&2
	fi
	exit 1
fi

if ! grep -q '^config/name="TOP CUT: Locals to Worlds"$' "$project_dir/project.godot"; then
	printf 'project.godot must identify the game as TOP CUT: Locals to Worlds.\n' >&2
	exit 1
fi

printf 'Branding check passed.\n'
