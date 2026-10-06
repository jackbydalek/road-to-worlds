#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
output_dir="$project_dir/outputs/steam_screenshots_hq"
mkdir "$output_dir"
mkdir -p "$output_dir/4k" "$output_dir/1080p" "$output_dir/alternates/4k" "$output_dir/alternates/1080p"
shots=(
  '16_sweet_jellyfish_bounce|165|01_tactical_card_battle|main'
  '18_tournament_hub|100|02_between_rounds_at_locals|main'
  '14_hand_trap_response|145|03_counter_with_a_hand_trap|main'
  '08_reward_pack|105|04_choose_your_rewards|main'
  '09_shop_deckbuild|75|05_build_your_deck_at_the_counter|main'
  '03_choose_competitor|65|06_choose_your_competitor|main'
  '07_battle_combo|165|07_buff_your_team_ART_REVIEW|alternate'
  '15_saladmander_summon|210|08_summon_your_board_ART_REVIEW|alternate'
)
for shot in "${shots[@]}"; do
  IFS='|' read -r clip frame name category <<< "$shot"
  printf -v frame_file 'frame_%06d.png' "$frame"
  source_path="$project_dir/outputs/trailer_hq_all/$clip/frames/$frame_file"
  destination="$output_dir"
  if [[ "$category" == 'alternate' ]]; then destination="$output_dir/alternates"; fi
  cp "$source_path" "$destination/4k/$name.png"
  ffmpeg -v error -n -i "$source_path" -vf scale=1920:1080:flags=lanczos \
    -frames:v 1 -update 1 "$destination/1080p/$name.png"
  dimensions="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$destination/4k/$name.png")"
  [[ "$dimensions" == '3840,2160' ]]
  printf 'Verified %s: native 4K PNG and 1080p PNG\n' "$name"
done
