#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
version="$(sed -n 's/^config\/version="\([^"]*\)"/\1/p' "$project_dir/project.godot" | head -n 1)"
web_dir="${1:-$project_dir/builds/top-cut-locals-to-worlds-$version}"
port="${PORT:-8060}"

if [[ ! -s "$web_dir/index.html" ]]; then
	printf 'No Web export found at %s\n' "$web_dir" >&2
	printf 'Export the Web preset there or unpack the itch ZIP before serving.\n' >&2
	exit 1
fi

printf 'Serving %s at http://127.0.0.1:%s\n' "$web_dir" "$port"
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$web_dir"
