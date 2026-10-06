#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
gallery_dir="$project_dir/outputs/steam_gallery_refresh"
mkdir -p "$gallery_dir/1080p"
for screenshot in "$gallery_dir"/4k/*.png; do
  name="$(basename "$screenshot")"
  [[ "$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$screenshot")" == '3840,2160' ]]
  ffmpeg -v error -y -i "$screenshot" -vf scale=1920:1080:flags=lanczos -frames:v 1 -update 1 "$gallery_dir/1080p/$name"
  [[ "$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$gallery_dir/1080p/$name")" == '1920,1080' ]]
  printf 'Verified %s\n' "$name"
done
