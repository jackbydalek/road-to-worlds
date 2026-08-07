#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
godot_bin="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

if [[ ! -x "$godot_bin" ]]; then
	printf 'Godot executable not found: %s\nSet GODOT_BIN to the Godot 4.6 executable.\n' "$godot_bin" >&2
	exit 1
fi

version="$(sed -n 's/^config\/version="\([^"]*\)"/\1/p' "$project_dir/project.godot" | head -n 1)"
if [[ -z "$version" || ! "$version" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]; then
	printf 'Could not read a safe config/version from project.godot.\n' >&2
	exit 1
fi

build_dir="$project_dir/builds"
artifact="$build_dir/kitchen-table-road-to-worlds-${version}-itch-web.zip"
stage_dir="$(mktemp -d "${TMPDIR:-/tmp}/kitchen-table-itch.XXXXXX")"
cleanup() {
	rm -rf "$stage_dir"
}
trap cleanup EXIT

mkdir -p "$build_dir"
printf '[release] Running automated release gate\n'
"$project_dir/scripts/release/check_demo.sh"

printf '\n[release] Exporting version %s\n' "$version"
"$godot_bin" --headless --path "$project_dir" \
	--export-release "Web (itch.io)" "$stage_dir/index.html"

for required_file in index.html index.js index.pck index.wasm; do
	test -s "$stage_dir/$required_file"
done

if ! grep -q "<meta name=\"version\" content=\"$version\">" "$stage_dir/index.html"; then
	printf 'Exported HTML does not identify version %s.\n' "$version" >&2
	exit 1
fi

temp_artifact="$artifact.tmp"
rm -f "$temp_artifact"
(
	cd "$stage_dir"
	zip -9 -q -r "$temp_artifact" .
)
mv -f "$temp_artifact" "$artifact"

if ! unzip -tq "$artifact" >/dev/null; then
	printf 'ZIP integrity check failed: %s\n' "$artifact" >&2
	exit 1
fi
if ! unzip -Z1 "$artifact" | grep -x 'index.html' >/dev/null; then
	printf 'itch ZIP must contain index.html at its root.\n' >&2
	exit 1
fi

artifact_bytes="$(stat -f '%z' "$artifact" 2>/dev/null || stat -c '%s' "$artifact")"
artifact_sha256="$(shasum -a 256 "$artifact" | awk '{print $1}')"
printf '\nRelease artifact ready:\n%s\nbytes: %s\nsha256: %s\n' \
	"$artifact" "$artifact_bytes" "$artifact_sha256"
