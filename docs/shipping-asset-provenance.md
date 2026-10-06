# Shipping asset provenance — See You at Locals

ASSET_POLICY: REGISTERED_GENERATED_ALLOWED

OWNER_ATTESTATION: PENDING

## Current authorization and scope

**September 14 update:** The supplied title animation replaces the generated
room. Its old PNG, import, provenance and manifest entry are archived under
excluded `outputs/supplied_screen_art_2026-09-14/retired_title/`, retaining the
known hash. The current active manifest contains **eight generated rival PNGs**.
The supplied title, layered shop/battle environments and snack art are recorded
separately in `assets/illustrations/supplied_locals_2026_09_14/manifest.json`.
Their original bytes are unchanged; no image generation was used to integrate
them. Supply alone does not certify origin or establish a new license. Earlier
September title inventory and switch descriptions below are historical.

On September 6, 2026, the project owner approved the **Chilling at Locals**
pivot, explicitly allowed generative AI where useful, and requested a record of
where it is used so that those assets can be replaced later. This supersedes the
previous blanket no-generative-AI requirement. It does not confirm the origin
of every existing supplied asset or authorize unrelated historical experiments.

The current build may use **registered generated working art**. Each permitted
asset must live under `assets/generated/`, have an exact path and SHA-256 in
`assets/generated/manifest.json`, and identify its saved prompt and runtime
consumers. Every image in that directory must be registered. A different file,
changed image bytes, or a copy elsewhere is not covered by the registration.

The readable inventory, source, replacement instructions, and consumer details
are in [`generated-art-register.md`](generated-art-register.md). The September 7
battle overhaul registers **eight Peach Soda opponent cutouts**. The follow-up
warm sketch UI migration retires the old generated utility-room bitmap to
`outputs/locals_pivot/superseded/warm-sketch-ui/`; Main.gd now uses the native
Peach Soda room drawing. The previous opaque
Mina scene is archived under excluded
`outputs/locals_pivot/superseded/peach-soda-replaced/` and removed from the active
manifest. Registered illustrations are AI-generated working art, not
owner-supplied originals or certified non-AI illustrations. The manifest is the
exact current list.

On September 8 the owner also explicitly approved using the supplied
seven-person room as the playable title, with white character outlines. That
source is a previous AI-generated concept, not an attested human original.
The cleaned edit was initially registered at
`assets/generated/title/locals_room_white_outline_ai.png`, bringing the
inventory to **nine generated PNGs: eight rivals and one title background**.
All room, human and prop pixels in that title plate remain generated working
art. Its source/output hashes and exact editing prompt are saved in
`assets/generated/title/provenance.json` and `docs/ai-prompts/locals-room-title/`.
Title lettering and buttons remain native. `TitleMenu.use_generated_title_art`
can disable the image load in favor of the native fallback; that switch does
not exclude the PNG from an all-resources export. A zero-generated-art release
still requires its replacement or removal from shipping asset paths.

The September 9 merchandise edit updates this same title file, replacing
book/binder-shaped stock with deck boxes, sleeve packs and rolled playmats.
Its current checksum, exact edit prompt and archived previous revision are in
the title provenance record; the inventory remains nine generated PNGs. The
product-form references remain in excluded development outputs. Native room
prop changes add no generated bitmap files or human-authorship attestation.

On September 11 the owner approved implementing the lineless room/furniture
direction and removing white outlines from people. The current title plate is
`assets/generated/title/locals_room_lineless_ink_people_ai.png`, a built-in
image-generation edit that retains the seven navy-ink people, room composition,
blank noticeboard and native menu aisle. The previous title PNG and import are
archived under excluded `outputs/lineless_art_implementation_2026-09-11/title/`.
The current exact bytes, 1584×993 RGB dimensions, prompt, approved style reference
and full revision chain are registered in the title provenance file. The active
inventory remains nine generated images. This change adds no baked title
lettering or controls, and preserves the optional native title fallback.

The eight RGBA characters preserve the pixels of their original AI concepts;
authorized programmatic background extraction does not change their AI origin.
Exact original prompts, references, hashes and cleanup geometry are retained
under `docs/ai-prompts/peach-soda-opponents/` and in
`assets/generated/peach_soda_opponents/provenance.json`. The shared
`PeachSodaCast.GENERATED_ART_ENABLED` flag disables all eight generated rivals
and provides a native fallback in battle and introductions. Static card backs held by
characters are decorative; live hand counts, targets and gameplay remain code.

This policy permits the recorded working assets in local builds and release
artifacts. It does not publish a build, alter a storefront disclosure, or certify
that the broader project has no generative-AI content. Public materials should
accurately reflect whichever registered assets they contain.

## Historical owner attestation — still pending

`OWNER_ATTESTATION: PENDING` above is retained as a historical provenance fact.
It is **not** silently changed to `CONFIRMED`, and is no longer the release gate
for the current generated-art policy. The former statement requested confirmation
that all custom public visual/audio sources were made without generative AI and
that third-party provenance was documented to the owner's knowledge. That
statement remains unconfirmed and would be incompatible with describing the
current registered generated illustrations as non-AI.

Existing supplied families whose source origin is not independently attested
include the card illustrations, protagonist and rival illustrations, shopkeeper,
old logos, card backs, route icons, custom props, pack art, and promotional
materials. Their preserved supply and license records remain in `CREDITS.md`.
Visual similarity, metadata, and the absence of a known hash do not establish
non-AI provenance.

## Historical experiments remain excluded

The earlier experimental directories and unverified source files remain excluded
from exports. They are not authorized merely because new working art is allowed:

- `outputs/`
- `docs/references/` (supplied visual references, not runtime artwork)
- `docs/ai-prompts/` (prompt history and rejected development images, not runtime artwork)
- `assets/marketing/`
- `assets/art_direction/`
- `assets/characters/concepts/`
- `assets/characters/mascots/`
- `assets/finale/`
- `assets/overworld/buildings/concepts/`
- `assets/overworld/buildings/shop_concept/`
- `assets/overworld/source_sheets/`
- `assets/title/`
- `assets/cards/card_backs/angular_card_back_concept.svg`
- The explicitly excluded legacy shopkeeper models and concept portraits.

The removed-source hashes in
`scripts/release/known_generated_asset_hashes.sha256` are preserved. The audit
also hashes remaining files in the historical experiment directories to detect
byte-identical copies moved into shipping-eligible paths. A future use requires
explicit authorization and an exact registration, not removal of this history.
See `docs/ai-asset-removal-2026-08-27.md` for the earlier removal record.

## Code-native and third-party sources

The native title lettering and fallback, card-club SVG icon, Peach Soda battle room and table,
printed interface geometry, card frames, playmat marks, and shaders are editable
code or vectors, not generated raster illustrations. The title uses the
project's licensed fonts. Existing card-face artwork and affiliation colors
remain unchanged and subject to their existing source records; composing those
illustrations into live cards does not create a new provenance claim for them.

Material Symbols Sharp, Kenney assets, Quaternius buildings, Pandazole assets,
and other third-party packages retain the licenses and source records listed in
`CREDITS.md`. The generated-art authorization does not change those licenses.

The September 9 UI integration and composition pass use eleven unchanged PNGs from the owner's
dobo_ui Cozy UI demo in `assets/ui/dobo_cozy/source/`. Their exact supplied
paths and hashes are recorded in `assets/ui/dobo_cozy/source-manifest.json`.
The additional note and heart support the title action group and shop/battle
life display. The creator describes the pack as handmade without AI; that source statement
is recorded separately from any independent authorship certification. Godot
performs conventional palette mapping and nine-slice drawing; no image
generation or model-based artwork editing was used. These are licensed
third-party UI sources, not entries in the generated-art manifest. The existing
nine generated title/rival images and pending owner-source attestation are
unchanged. The complete demo extraction and review images stay under excluded
`outputs/dobo_cozy_ui_v1/`; usage notes and attribution ship alongside the
selected sources.

## Enforcement and verification

`scripts/release/check_no_ai_assets.sh` retains its filename and command-line
API for existing build scripts. It now runs `check_asset_provenance.py` and
verifies:

1. The current policy marker and every export preset's historical exclusions.
2. Every generated-directory image has one registration, an exact SHA-256,
   a nonempty saved prompt, and existing documented consumers.
3. Shipping runtime files do not reference the excluded historical paths.
4. Known generated bytes appear only at their exact registered shipping paths;
   copies into other shipping-eligible asset directories fail.
5. With `--export-log`, the exporter did not record excluded historical files.

Run `scripts/release/check_no_ai_assets.sh` before export and the same command
with `--export-log path/to/export.log` afterward. `--audit-known` remains an
accepted alias for the current inventory audit. Both the demo gate and final
itch build keep these checks. Passing verifies this inventory and its controls;
it does not certify unknown source art or prove an entire package is non-AI.

For the separate no-generative-AI target, run
`scripts/release/check_no_ai_assets.sh --require-no-generated` (optionally
followed by `--audit-known` or `--export-log path/to/export.log`). This opt-in mode
runs the same provenance audit, then requires an empty active generated-asset
manifest and `OWNER_ATTESTATION: CONFIRMED`. It currently **fails intentionally**
for the eight registered generated files and pending source attestation. Keep
the normal working-art audit unchanged while placeholders are authorized.
Completing the no-AI handoff also requires reviewing custom visual, audio and
written sources in the asset checklist; no hash scan independently proves their
origin. Do not change the attestation marker without actual owner/source evidence.
