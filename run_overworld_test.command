#!/bin/zsh

set -e

project_dir="${0:A:h}"
godot_app="/Applications/Godot.app/Contents/MacOS/Godot"

if [[ ! -x "$godot_app" ]]; then
	echo "Godot was not found at /Applications/Godot.app"
	echo "Install Godot there or open scenes/OverworldStageTest.tscn manually."
	read -r "?Press Return to close..."
	exit 1
fi

exec "$godot_app" --path "$project_dir" res://scenes/OverworldStageTest.tscn
