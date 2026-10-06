#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
godot_bin="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"

if [[ ! -x "$godot_bin" ]]; then
	printf 'Godot executable not found: %s\nSet GODOT_BIN to the Godot 4.6 executable.\n' "$godot_bin" >&2
	exit 1
fi

release_tmp="$(mktemp -d "${TMPDIR:-/tmp}/see-you-at-locals-release.XXXXXX")"
cleanup() {
	rm -rf "$release_tmp"
}
trap cleanup EXIT

run_test() {
	local script_path="$1"
	printf '\n[demo gate] %s\n' "$script_path"
	if [[ "$script_path" == "scripts/PublicUiSmokeTest.gd" ]]; then
		"$godot_bin" --headless --path "$project_dir" --script "res://$script_path" -- --public
	else
		"$godot_bin" --headless --path "$project_dir" --script "res://$script_path"
	fi
}

printf '[demo gate] Verify product branding\n'
"$project_dir/scripts/release/check_branding.sh"

printf '[demo gate] Verify asset provenance and registered generated working art\n'
"$project_dir/scripts/release/check_no_ai_assets.sh"

printf '[demo gate] Import and parse project\n'
"$godot_bin" --headless --editor --path "$project_dir" --quit

tests=(
	"scripts/cooking/CanonicalCatalogSmokeTest.gd"
	"scripts/cooking/SpecialServeSmokeTest.gd"
	"scripts/WeeklyDemoSmokeTest.gd"
	"scripts/WeeklySpecialServeUiSmokeTest.gd"
	"scripts/cooking/BodyguardBagverSmokeTest.gd"
	"scripts/cooking/AttackPreviewSmokeTest.gd"
	"scripts/cooking/DrawRefillSmokeTest.gd"
	"scripts/cooking/KitchenGameSmokeTest.gd"
	"scripts/cooking/RebalancedCardPoolSmokeTest.gd"
	"scripts/cooking/FreshFunkyEffectsSmokeTest.gd"
	"scripts/cooking/MovementSwapSmokeTest.gd"
	"scripts/cooking/TongsSmokeTest.gd"
	"scripts/cooking/TokenEvaporationSmokeTest.gd"
	"scripts/cooking/ChefCarmySmokeTest.gd"
	"scripts/OpponentHandFaceAttackSmokeTest.gd"
	"scripts/TabletopPacingSmokeTest.gd"
	"scripts/BattleActionPreviewUiSmokeTest.gd"
	"scripts/PeachSodaBattleSmokeTest.gd"
	"scripts/ReshuffleBannerSmokeTest.gd"
	"scripts/SelectionClaritySmokeTest.gd"
	"scripts/CombatLayoutSmokeTest.gd"
	"scripts/ResponsiveLayoutSmokeTest.gd"
	"scripts/NexusSeasonUiSmokeTest.gd"
	"scripts/RuntimeCardFaceIntegrationSmokeTest.gd"
	"scripts/CardEffectLabSmokeTest.gd"
	"scripts/ThreeDCardInterfaceAudit.gd"
	"scripts/RouteRunSmokeTest.gd"
	"scripts/TournamentHubSmokeTest.gd"
	"scripts/HubCounterZoomSmokeTest.gd"
	"scripts/HubSellerSmokeTest.gd"
	"scripts/HubShopRefreshSmokeTest.gd"
	"scripts/RouteCampaignFlowSmokeTest.gd"
	"scripts/RouteRewardLayoutSmokeTest.gd"
	"scripts/overworld/OverworldRouteGraphSmokeTest.gd"
	"scripts/OpponentDeckTierSmokeTest.gd"
	"scripts/RoundCashRewardSmokeTest.gd"
	"scripts/GuidedTutorialSmokeTest.gd"
	"scripts/DraftModeSmokeTest.gd"
	"scripts/DeckbuilderLayoutSmokeTest.gd"
	"scripts/UiRefreshDecisionSmokeTest.gd"
	"scripts/StarterSelectionFlowSmokeTest.gd"
	"scripts/PackRewardSmokeTest.gd"
	"scripts/SinglesSelectionSmokeTest.gd"
	"scripts/StorefrontMenuSmokeTest.gd"
	"scripts/PositiveEffectSoundSmokeTest.gd"
	"scripts/MenuSparkleSmokeTest.gd"
	"scripts/MusicMixSmokeTest.gd"
	"scripts/BattleSettingsSmokeTest.gd"
	"scripts/GlobalButtonStyleSmokeTest.gd"
	"scripts/TitleMenuPaletteSmokeTest.gd"
	"scripts/TournamentResultUiSmokeTest.gd"
	"scripts/SharedCardInspectionSmokeTest.gd"
	"scripts/PublicUiSmokeTest.gd"
	"scripts/AutosaveSmokeTest.gd"
)

for test_script in "${tests[@]}"; do
	run_test "$test_script"
done

printf '\n[demo gate] Export Web release\n'
export_log="$release_tmp/export.log"
if ! "$godot_bin" --headless --path "$project_dir" --export-release "Web (itch.io)" "$release_tmp/index.html" >"$export_log" 2>&1; then
	tail -n 200 "$export_log" >&2
	exit 1
fi
tail -n 4 "$export_log"
"$project_dir/scripts/release/check_no_ai_assets.sh" --export-log "$export_log"
: >"$export_log"
test -s "$release_tmp/index.html"
test -s "$release_tmp/index.pck"
test -s "$release_tmp/index.js"
test -s "$release_tmp/index.wasm"

if ! grep -q '<meta name="version" content="0.1.0-demo.1">' "$release_tmp/index.html"; then
	printf 'Exported HTML is missing the expected demo version metadata.\n' >&2
	exit 1
fi

if ! grep -Fq '<meta name="description" content="See You at Locals — playable browser demo">' "$release_tmp/index.html"; then
	printf 'Exported HTML is missing the expected See You at Locals branding.\n' >&2
	exit 1
fi

bundle_bytes="$(du -sk "$release_tmp" | awk '{print $1 * 1024}')"
max_bundle_bytes=$((145 * 1024 * 1024))
if (( bundle_bytes > max_bundle_bytes )); then
	printf 'Web bundle is %s bytes; release budget is %s bytes.\n' "$bundle_bytes" "$max_bundle_bytes" >&2
	exit 1
fi
printf '\nDemo release gate passed. Web bundle: %s bytes.\n' "$bundle_bytes"
