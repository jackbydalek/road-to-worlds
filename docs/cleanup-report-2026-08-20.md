# Cleanup report — 2026-08-20

## Result

The active workspace is about **204 MB smaller**. A total of **463 files** were
moved out of the project into a reversible quarantine at:

`/private/tmp/road-to-worlds-cleanup-2026-08-20`

Tracked files remain recoverable from Git. The ignored release archive and
import sidecars can be regenerated. The quarantine should be treated as
temporary and can be permanently removed after the cleanup is accepted.

## Removed from the active project

- The stale exported web-demo archive in `builds/`.
- Old button, café, glass, sketch-front-door, season-demo, storefront, and
  Nexus screenshot passes that are not loaded by the game.
- The unused Cozy Café UI runtime kit and its dead bridge code.
- Unreferenced hand-painted, cozy-menu, Nexus, painted-button, and UI-concept
  source folders.
- Three unused button component scenes plus the obsolete tint and sketch-button
  implementations they depended on.
- The abandoned `StylizedShopDemo` scene, dresser, smoke test, preview script,
  Neo shopkeeper, low-poly café, and coffee-table assets. The interior-plant
  scene still used by the live shop was retained.
- Unused music alternates, the superseded UI-sound pack, unused impact/card
  sounds, and their obsolete attribution entries. The currently wired Cute &
  Cozy UI sounds were retained.
- Six unused/temporary logo variants. The live storefront logo was retained.
- Old-product-name marketing variants and obsolete Montabi/clean-adventure UI
  concepts. The current Pokémon-inspired UI reference was renamed to the
  current product name.
- Dead `TutorialScreen`, wired-title doodle, Cozy UI helper, and legacy capture
  implementations.
- macOS `.DS_Store` files and orphaned Godot import sidecars.

## Code cleanup

- `SketchUIComponents.make_button()` now creates a normal `Button`; the shared
  global button controller owns presentation.
- Removed dead texture-button constants, reference-style builders, and legacy
  button drawing paths.
- Removed unused reference-button helpers from `SketchTheme`.
- Fixed the UI-sound controller's initial tree traversal so subclasses are
  discovered reliably.
- Renamed `illustrated_cafe_palette.gdshader` to
  `illustrated_palette.gdshader` and updated its live references.
- Simplified credits and export exclusions to match assets that actually ship.

## Probably safe to remove next

These are not runtime dependencies, but they contain subjective or recently
edited work, so they were deliberately left for review:

| Candidate | Size | Recommendation |
|---|---:|---|
| `outputs/concept_art/` | ~120 MB | Keep only approved north-star references; archive the rest outside the game repo. |
| `assets/marketing/` | ~33 MB | Keep approved masters in the repo; archive superseded campaign variants and source experiments. |
| `outputs/style_tiles/` | ~19 MB | Archive after confirming none are still used for art handoff. |
| `assets/characters/mascots/` | ~5.9 MB | Unreferenced, but `PROMPTS.md` has user edits; remove only after review. |
| `outputs/steam_capsules/` | ~4.7 MB | Keep final deliverables in one marketing location and remove duplicate exports. |
| `outputs/lofi_shop_concept/` | ~2.7 MB | Likely obsolete under the current art direction. |
| `outputs/icon_concepts/` | ~2.3 MB | Archive once the active icon family is locked. |
| `assets/characters/concepts/` | ~2.2 MB | Reference-only; move to an art archive if no longer guiding production. |
| Preview/capture scripts not in `check_demo.sh` | 19 scripts | Keep only captures that are still part of the team's visual-QA workflow. |
| `third_party/audacious_glassmorphism/` | ~32 KB | No runtime path reference; retain only if its license/source provenance is still required. |

## Do not remove yet

- The released season/shop shell: it is legacy direction, but still hosts live
  systems while the route campaign is being integrated.
- `KitchenGame` test scenes and combat simulations: they still protect core
  Kitchen Match rules even though the production surface is the tabletop.
- Current card catalog, card art, route/overworld prototype, live shop props,
  active shopkeeper model/texture, UI audio, and button system.

## Structural code debt to tackle next

- `Main.gd` still coordinates the route prototype, released season shell, shop,
  tournament, settings, audio, and screen construction. Extract those screen
  families before deleting the legacy season branch.
- `Tabletop3DPrototype.gd` still combines battle presentation, animation,
  sound, input, and match orchestration. Split presentation/audio controllers
  first; keep the combat service as the rules boundary.
- Once the route campaign is the production entry path, remove the old
  season/draft/tournament shell and its dedicated smoke/capture scripts in one
  migration rather than maintaining two outer loops indefinitely.

## Verification

- Godot headless editor import/parse passed.
- Global button style smoke test passed.
- Nexus season UI smoke test passed.
- Storefront menu smoke test passed.
- Greybox plant/shop shader smoke test passed.
- Music mix smoke test passed.
- Impact-sound routing smoke test passed.
- Product branding check passed.
- The public-UI suite's credits and public-build checks passed, but the suite
  remains red on its pre-existing settings-persistence assertions.
