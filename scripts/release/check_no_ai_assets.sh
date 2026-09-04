#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
attestation_file="$project_dir/docs/shipping-asset-provenance.md"
export_presets="$project_dir/export_presets.cfg"
known_hashes_file="$project_dir/scripts/release/known_generated_asset_hashes.sha256"

required_exclusions=(
	"outputs/**"
	"assets/marketing/**"
	"assets/art_direction/**"
	"assets/characters/concepts/**"
	"assets/characters/mascots/**"
	"assets/characters/shopkeeper/clerkidle.glb"
	"assets/characters/shopkeeper/shopkeeper_lofi_v2.png"
	"assets/characters/shopkeeper/singles-counter-proprietor-v1.png"
	"assets/characters/shopkeeper/singles-counter-proprietor-v2.png"
	"assets/cards/card_backs/angular_card_back_concept.svg"
	"assets/finale/**"
	"assets/overworld/buildings/concepts/**"
	"assets/overworld/buildings/shop_concept/**"
	"assets/overworld/source_sheets/**"
	"assets/title/**"
	"clerkidle.tscn"
	"scenes/GreyboxCameraDemo.tscn"
	"scripts/*ConceptCapture.gd"
)

forbidden_runtime_refs=(
	"res://outputs/"
	"res://assets/marketing/"
	"res://assets/characters/concepts/"
	"res://assets/characters/mascots/"
	"res://assets/cards/card_backs/angular_card_back_concept.svg"
	"res://assets/finale/"
	"res://assets/overworld/buildings/concepts/"
	"res://assets/overworld/buildings/shop_concept/"
	"res://assets/title/"
)

known_generated_roots=(
	"$project_dir/outputs/concept_art"
	"$project_dir/outputs/icon_concepts"
	"$project_dir/outputs/lofi_shop_concept"
	"$project_dir/outputs/steam_capsules"
	"$project_dir/outputs/style_tiles"
	"$project_dir/assets/marketing"
	"$project_dir/assets/art_direction"
	"$project_dir/assets/characters/concepts"
	"$project_dir/assets/characters/mascots"
	"$project_dir/assets/finale"
	"$project_dir/assets/overworld/buildings/concepts"
	"$project_dir/assets/overworld/buildings/shop_concept"
	"$project_dir/assets/title"
)

check_export_policy() {
	local exclude_lines
	local exclude_line
	local preset_number=0
	local required

	exclude_lines="$(grep '^exclude_filter=' "$export_presets" || true)"
	if [[ -z "$exclude_lines" ]]; then
		printf 'No export exclude_filter was found in %s.\n' "$export_presets" >&2
		return 1
	fi

	while IFS= read -r exclude_line; do
		preset_number=$((preset_number + 1))
		for required in "${required_exclusions[@]}"; do
			if [[ "$exclude_line" != *"$required"* ]]; then
				printf 'Export preset %s is missing no-AI exclusion: %s\n' "$preset_number" "$required" >&2
				return 1
			fi
		done
	done <<<"$exclude_lines"
}

check_owner_attestation() {
	if [[ ! -f "$attestation_file" ]]; then
		printf 'Missing shipping provenance record: %s\n' "$attestation_file" >&2
		return 1
	fi
	if ! grep -q '^OWNER_ATTESTATION: CONFIRMED$' "$attestation_file"; then
		printf 'No-AI release is blocked: project-owner asset provenance is still pending.\n' >&2
		printf 'Review and confirm the statement in %s before shipping.\n' "$attestation_file" >&2
		return 1
	fi
}

check_runtime_references() {
	local forbidden
	local hits

	for forbidden in "${forbidden_runtime_refs[@]}"; do
		hits="$(rg -n --fixed-strings "$forbidden" \
			"$project_dir/project.godot" "$project_dir/data" "$project_dir/scenes" "$project_dir/scripts" \
			-g '!*.sh' -g '!*Capture.gd' -g '!*SmokeTest.gd' -g '!*Simulation.gd' || true)"
		if [[ -n "$hits" ]]; then
			printf 'A prohibited generated/concept asset is referenced by shipping runtime content:\n%s\n' "$hits" >&2
			return 1
		fi
	done
}

check_generated_hash_copies() {
	local audit_tmp
	local source_root
	local matches
	audit_tmp="$(mktemp -d "${TMPDIR:-/tmp}/top-cut-no-ai-audit.XXXXXX")"

	cleanup_hash_audit() {
		rm -rf "$audit_tmp"
	}
	trap cleanup_hash_audit RETURN

	if [[ ! -s "$known_hashes_file" ]]; then
		printf 'Missing known generated-asset hash denylist: %s\n' "$known_hashes_file" >&2
		return 1
	fi
	cp "$known_hashes_file" "$audit_tmp/generated.sha"
	for source_root in "${known_generated_roots[@]}"; do
		if [[ -d "$source_root" ]]; then
			find "$source_root" -type f \
				\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.svg' -o -iname '*.glb' \) \
				-print0 | xargs -0 shasum -a 256 >>"$audit_tmp/generated.sha"
		fi
	done

	find "$project_dir/assets" -type f \
		\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.svg' -o -iname '*.glb' \) \
		! -path "$project_dir/assets/marketing/*" \
		! -path "$project_dir/assets/art_direction/*" \
		! -path "$project_dir/assets/characters/concepts/*" \
		! -path "$project_dir/assets/characters/mascots/*" \
		! -path "$project_dir/assets/finale/*" \
		! -path "$project_dir/assets/overworld/buildings/concepts/*" \
		! -path "$project_dir/assets/overworld/buildings/shop_concept/*" \
		! -path "$project_dir/assets/overworld/source_sheets/*" \
		! -path "$project_dir/assets/title/*" \
		! -path "$project_dir/assets/cards/card_backs/angular_card_back_concept.svg" \
		! -path "$project_dir/assets/characters/shopkeeper/clerkidle.glb" \
		! -path "$project_dir/assets/characters/shopkeeper/shopkeeper_lofi_v2.png" \
		! -path "$project_dir/assets/characters/shopkeeper/singles-counter-proprietor-v1.png" \
		! -path "$project_dir/assets/characters/shopkeeper/singles-counter-proprietor-v2.png" \
		-print0 | xargs -0 shasum -a 256 >"$audit_tmp/shipping-candidates.sha"

	matches="$(awk '
		NR == FNR { generated[$1] = $0; next }
		$1 in generated { print generated[$1]; print $0; print "" }
	' "$audit_tmp/generated.sha" "$audit_tmp/shipping-candidates.sha")"
	if [[ -n "$matches" ]]; then
		printf 'Known generated artwork was copied into a shipping-eligible asset path:\n%s\n' "$matches" >&2
		return 1
	fi
}

check_export_log() {
	local export_log="$1"
	local prohibited_files

	if [[ ! -s "$export_log" ]]; then
		printf 'Cannot inspect missing or empty export log: %s\n' "$export_log" >&2
		return 1
	fi
	prohibited_files="$(rg -n \
		'Storing File: res://(outputs/|assets/marketing/|assets/art_direction/|assets/characters/concepts/|assets/characters/mascots/|assets/finale/|assets/overworld/buildings/concepts/|assets/overworld/buildings/shop_concept/|assets/overworld/source_sheets/|assets/title/|assets/cards/card_backs/angular_card_back_concept\.svg|assets/characters/shopkeeper/(clerkidle\.glb|shopkeeper_lofi_v2\.png|singles-counter-proprietor-v[12]\.png))' \
		"$export_log" || true)"
	if [[ -n "$prohibited_files" ]]; then
		printf 'The exporter stored prohibited generated, concept, or unverified source assets:\n%s\n' "$prohibited_files" >&2
		return 1
	fi
	printf 'Export log contains no prohibited generated-asset files.\n'
}

if [[ "${1:-}" == "--export-log" ]]; then
	if [[ $# -ne 2 ]]; then
		printf 'Usage: %s --export-log path/to/export.log\n' "$0" >&2
		exit 2
	fi
	check_export_log "$2"
	exit 0
fi
if [[ "${1:-}" == "--audit-known" ]]; then
	if [[ $# -ne 1 ]]; then
		printf 'Usage: %s --audit-known\n' "$0" >&2
		exit 2
	fi
	check_export_policy
	check_runtime_references
	check_generated_hash_copies
	printf 'Known generated-asset audit passed; owner attestation was not checked.\n'
	exit 0
fi
if [[ $# -ne 0 ]]; then
	printf 'Usage: %s [--audit-known | --export-log path/to/export.log]\n' "$0" >&2
	exit 2
fi

check_export_policy
check_runtime_references
check_generated_hash_copies
check_owner_attestation
printf 'No-AI asset policy check passed.\n'
