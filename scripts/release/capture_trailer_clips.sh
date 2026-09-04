#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
godot_bin="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
output_dir="${1:-$project_dir/builds/trailer-clips-competitive}"
raw_dir="$output_dir/raw"
log_dir="$output_dir/logs"

if [[ ! -x "$godot_bin" ]]; then
	printf 'Godot executable not found: %s\n' "$godot_bin" >&2
	exit 1
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
	printf 'ffmpeg is required to convert Godot Motion JPEG captures.\n' >&2
	exit 1
fi

clips=(
	"01_combat_hook"
	"02_title"
	"03_choose_competitor"
	"04_route_decision"
	"05_rival_challenge"
	"06_control_the_table"
	"07_battle_combo"
	"08_reward_pack"
	"09_shop_deckbuild"
	"10_upgrade_foil"
	"11_city_champion"
	"12_logo_end_card"
	"13_card_trade"
	"14_hand_trap_response"
	"15_saladmander_summon"
	"16_sweet_jellyfish_bounce"
	"17_firecracker_bench_hit"
)
if (( $# > 1 )); then
	clips=("${@:2}")
fi

mkdir -p "$output_dir" "$raw_dir" "$log_dir"
for clip_id in "${clips[@]}"; do
	raw_path="$raw_dir/$clip_id.avi"
	movie_path="$output_dir/$clip_id.mov"
	log_path="$log_dir/$clip_id.log"
	printf '\n[trailer capture] %s\n' "$clip_id"
	rm -f "$raw_path" "$movie_path" "$log_path"
	"$godot_bin" --path "$project_dir" \
		--log-file "$log_path" \
		--write-movie "$raw_path" \
		--fixed-fps 30 \
		--disable-vsync \
		--script res://scripts/TrailerClipPreviewCapture.gd -- "$clip_id"
	if [[ ! -s "$raw_path" ]]; then
		printf 'Godot did not create trailer clip: %s\n' "$raw_path" >&2
		exit 1
	fi
	if ! rg -q "TRAILER_CLIP_CAPTURED $clip_id" "$log_path"; then
		printf 'Trailer clip did not reach its clean endpoint: %s\n' "$clip_id" >&2
		tail -n 100 "$log_path" >&2
		exit 1
	fi
	if rg -q '^(SCRIPT ERROR:|ERROR: Trailer )' "$log_path"; then
		printf 'Trailer clip reported a capture-script error: %s\n' "$clip_id" >&2
		tail -n 100 "$log_path" >&2
		exit 1
	fi
	leading_black_end="$({ ffmpeg -hide_banner -i "$raw_path" \
		-vf 'blackdetect=d=0.1:pix_th=0.12' -an -f null - 2>&1 || true; } \
		| sed -n 's/.*black_start:0 black_end:\([^ ]*\).*/\1/p' \
		| head -n 1)"
	trim_start="0"
	if [[ -n "$leading_black_end" ]]; then
		trim_start="$(awk -v ending="$leading_black_end" 'BEGIN { start = ending - 0.20; if (start < 0) start = 0; printf "%.3f", start }')"
	fi
	ffmpeg -hide_banner -loglevel error -y \
		-ss "$trim_start" -i "$raw_path" \
		-map 0:v:0 -map '0:a:0?' \
		-c:v libx264 -preset medium -crf 14 -pix_fmt yuv420p \
		-c:a aac -b:a 192k \
		-movflags +faststart \
		"$movie_path"
	if [[ ! -s "$movie_path" ]]; then
		printf 'Could not convert trailer clip: %s\n' "$movie_path" >&2
		exit 1
	fi
	if [[ "${KEEP_TRAILER_RAW:-0}" != "1" ]]; then
		rm -f "$raw_path"
	fi
	printf 'Ready: %s\n' "$movie_path"
done

printf '\nTrailer clips ready in %s\n' "$output_dir"
