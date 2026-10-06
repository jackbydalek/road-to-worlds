#!/usr/bin/env bash
# Native offscreen 4K frames, independent of the user's display resolution.
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
output_dir="${1:?Usage: bash scripts/release/capture_trailer_hq.sh NEW_OUTPUT_DIR CLIP_ID}"
clip_id="${2:?Provide a TrailerClipPreviewCapture clip id}"
godot_bin="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
command -v ffmpeg >/dev/null
command -v ffprobe >/dev/null
# Refuse to overwrite a prior master or frame sequence.
mkdir "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
mkdir "$output_dir/frames"
TOP_CUT_TRAILER_HQ=1 TOP_CUT_TRAILER_FRAMES="$output_dir/frames" \
  "$godot_bin" --path "$project_dir" --fixed-fps 30 --disable-vsync \
  --log-file "$output_dir/capture.log" \
  --write-movie "$output_dir/audio_reference.avi" \
  --script res://scripts/TrailerClipPreviewCapture.gd -- "$clip_id"
rg -q "TRAILER_CLIP_CAPTURED $clip_id" "$output_dir/capture.log"
if rg -q '^SCRIPT ERROR:|^ERROR:' "$output_dir/capture.log"; then
  exit 1
fi
ffmpeg -hide_banner -loglevel error -n \
  -framerate 30 -i "$output_dir/frames/frame_%06d.png" \
  -i "$output_dir/audio_reference.avi" \
  -map 0:v:0 -map '1:a:0?' -c:v libx264 -preset slow -crf 14 \
  -pix_fmt yuv420p -c:a aac -b:a 320k -shortest -movflags +faststart \
  "$output_dir/${clip_id}_4k.mp4"
ffmpeg -hide_banner -loglevel error -n \
  -framerate 30 -i "$output_dir/frames/frame_%06d.png" \
  -i "$output_dir/audio_reference.avi" \
  -map 0:v:0 -map '1:a:0?' -vf scale=1920:1080:flags=lanczos \
  -c:v libx264 -preset slow -crf 14 -pix_fmt yuv420p \
  -c:a aac -b:a 320k -shortest -movflags +faststart \
  "$output_dir/${clip_id}_1080p.mp4"
ffprobe -v error -select_streams v:0 -show_entries stream=width,height,nb_frames \
  "$output_dir/${clip_id}_4k.mp4"
