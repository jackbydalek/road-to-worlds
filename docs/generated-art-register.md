# Generated art and replacement map

The owner authorizes generative AI as documented, replaceable working art and
requested the September 7 battle overhaul using the eight Peach Soda character
concepts. This register distinguishes those raster illustrations from editable
playmat, card-frame and interface code, and the separately recorded supplied room art. It does not certify the
origin of older supplied project assets. Exact active files, hashes, dimensions,
prompts and consumers are in `assets/generated/manifest.json`.

## Supplied screen replacement — September 14

The owner supplied three title frames, the layered shop and battle scenes, and
Heart Bites/Foil Crunch snack illustrations for direct implementation. Their
unchanged originals and supply manifest are in
`assets/illustrations/supplied_locals_2026_09_14/`. This pass uses no image
generation and makes no new authorship or license claim for supplied material.

The owner also supplied the current title logo as `IMG_0477.PNG`. The unchanged
PNG is `assets/logos/see_you_at_locals_supplied.png`, with its source record at
`assets/logos/see_you_at_locals_supplied.provenance.json`. `LocalsWordmark.gd`
displays this supplied sign on both the illustrated title and native-background
fallback; the previous code-drawn title lettering is replaced. The separate
application icon remains unchanged. This logo is supplied material, not a newly
generated asset, and its record assigns no new authorship or license terms.

The generated title is retired from runtime and shipping assets to excluded
`outputs/supplied_screen_art_2026-09-14/retired_title/`, including its PNG,
import record, provenance and former manifest entry. Its known hash remains
recorded. **Eight generated rival PNGs remain active.** Title animation is now
controlled by `TitleMenu.use_supplied_title_art`; disabling it restores native
background geometry while retaining the supplied title logo. The September 8–11
title entries below describe historical revisions.

## Generated raster art currently used by the game

| Asset | Where it appears | Source and replacement point |
| --- | --- | --- |
| `assets/generated/peach_soda_opponents/pip.png` | Pip seated rival and profile crop | `docs/ai-prompts/peach-soda-opponents/pip-original-generation.txt`; centralized `PeachSodaCast.gd` mapping. |
| `assets/generated/peach_soda_opponents/otis.png` | Otis seated rival and profile crop | `docs/ai-prompts/peach-soda-opponents/otis-original-generation.txt`; centralized `PeachSodaCast.gd` mapping. |
| `assets/generated/peach_soda_opponents/ines.png` | Ines seated rival and profile crop | `docs/ai-prompts/peach-soda-opponents/ines-original-generation.txt`; centralized `PeachSodaCast.gd` mapping. |
| `assets/generated/peach_soda_opponents/sana.png` | Sana seated rival and profile crop | `docs/ai-prompts/peach-soda-opponents/sana-original-generation.txt`; centralized `PeachSodaCast.gd` mapping. |
| `assets/generated/peach_soda_opponents/milo.png` | Milo seated rival and profile crop | `docs/ai-prompts/peach-soda-opponents/milo-original-generation.txt`; centralized `PeachSodaCast.gd` mapping. |
| `assets/generated/peach_soda_opponents/bea.png` | Bea seated rival and profile crop | `docs/ai-prompts/peach-soda-opponents/bea-original-generation.txt`; centralized `PeachSodaCast.gd` mapping. |
| `assets/generated/peach_soda_opponents/kit.png` | Kit seated rival and profile crop | `docs/ai-prompts/peach-soda-opponents/kit-original-generation.txt`; centralized `PeachSodaCast.gd` mapping. |
| `assets/generated/peach_soda_opponents/ellis.png` | Ellis seated rival and profile crop | `docs/ai-prompts/peach-soda-opponents/ellis-original-generation.txt`; centralized `PeachSodaCast.gd` mapping. |

### Retired lineless room and navy-ink people — September 11

The owner approved implementing the lineless background/furniture concept and
its follow-up removing white character rims. A built-in image-generation edit
restyles the previous room plate while preserving all seven people, their blue
ink contours, the room arrangement, accessory merchandise and clear menu aisle.
The upper-central board remains blank for the native wordmark, and no menu
controls are baked into the image. The selected output is **1584×993 RGB**, copied
unchanged into the versioned runtime path above. Native layout remains bound to
the room proportions.

The previous PNG, import record and provenance are archived under excluded
`outputs/lineless_art_implementation_2026-09-11/title/`. The source and result
hashes, exact prompt, approved style reference and full previous revision chain
are in `assets/generated/title/provenance.json`. One active title image keeps
the generated inventory at nine images. This remains generated working art;
the lineless treatment does not establish human authorship. Earlier white-rim
records below describe superseded revisions.

### Card-shop merchandise title revision — September 9

The owner requested replacing the book/binder-like stock with deck boxes,
sleeve packs and playmats. A targeted built-in image-generation edit replaces
those shelves and the foreground merchandise display while retaining the
1586×992 composition, seven people, white outlines, blank noticeboard and open
menu aisle. The two supplied product photos are construction references only;
their branding and external card artwork are not used. Native shop/battle prop
changes add no generated bitmap assets.

This revision replaced the then-registered title PNG; the active generated inventory
remains nine images. The prior image and provenance are preserved in excluded
`outputs/card_shop_merchandise_v1/title/`, and both revision hashes remain in the
known-generated list. Its exact prompt and source chain are retained through
the current title provenance's previous revision record.

### White-outline room title — September 8

The owner requested the seven-person card-shop image as the playable title and
white outlines around every person. The supplied source was an earlier
AI-generated concept, retained at
`outputs/locals_room_title_v1/00-user-source.png`; its being supplied by the owner
does not make it human-authored. OpenAI's built-in image-generation tool edited
that source to add the outlines, remove baked HUD/buttons and leave the central
noticeboard blank for the native wordmark. The entire **1586×992 RGB** background,
including all seven people, room, painted cards and props, remains generated
working art. No title lettering or functional buttons are baked into it.

`scripts/ui/TitleMenu.gd` previously loaded the PNG when the exported
**`use_generated_title_art`** setting is enabled (the default). Set it to
**`false`** to use the previous native title fallback without loading this image.
This setting is independent of the rival-portrait flag below. The exact prompt,
source and output hashes are retained in `docs/ai-prompts/locals-room-title/`
and `assets/generated/title/provenance.json`.

For a zero-generated-art build, commission a human-made replacement preserving
the approved room composition, seven people with navy ink and no white rims, clear faces,
blank central noticeboard and open aisle menu area. Keep lettering and controls
native. Deliver editable layered source and a clean background export; put the
replacement outside `assets/generated/`, update the title asset mapping, remove
the retired generated PNG/import from shipping paths and retire its manifest
entry. Retain the old checksum in the known-generated hash list. Disabling the
runtime setting alone does **not** remove the PNG from an all-resources export.

### Eight Peach Soda opponents

All eight character illustrations were made with OpenAI's built-in image
creation tool, then extracted from their original opaque concepts using the
user-authorized programmatic background-removal method. Their exact original
RGB pixels are preserved; extraction does not make the art non-AI. Each final
PNG has real alpha on a **1448×1200 canvas**, with a shared **y=1000 resting-arm
baseline**. Hands may extend lower, especially Kit's hand at y=1101. No Aqua
Studio or other proprietary brush assets were used.

`scripts/ui/PeachSodaCast.gd` dynamically builds these eight asset paths and
supplies full portraits or profile crops. `scripts/Tabletop3DPrototype.gd` uses
them for battle staging and scorecards; `scripts/Main.gd` uses the same mapping
for rival introductions. There is one relaxed expression per character. During
battle, `RivalHandPose.gd` and `RivalHeldCards.gd` cover the painted fans on Pip,
Milo and Bea with native clothing shapes, then place the exact live number of
concealed sleeves beneath the original finger pixels. Source PNGs are unchanged.
Mina retains her supplied animated portrait and live fan. The face-attack region,
card targets and all changing game state remain live code.
Existing authored card-face illustrations and affiliation colors are unchanged.

The retained source PNGs, prompts, source/style references and original image
generation destinations are linked from
`assets/generated/peach_soda_opponents/provenance.json`. The extraction script,
verified background seeds, geometry and replacement notes are in
[`docs/ai-prompts/peach-soda-opponents/README.md`](ai-prompts/peach-soda-opponents/README.md).
The user-supplied drawing reference is visibly credited to **@Blotter_art**; it
is a style reference, not a runtime character asset or game-owned illustration.

### Disable or replace the AI portraits

Set **`GENERATED_ART_ENABLED := false`** in
`scripts/ui/PeachSodaCast.gd` to disable all eight generated rival portraits in
battle and introductions. The runtime uses the editable card-club mark as a
fallback, and missing portrait PNGs also fall back safely. These are eight of the
eight currently registered generated illustrations; the former title background
is archived as described above. The former utility-menu room bitmap was retired during
the warm sketch UI migration; those utility menus use native geometry.

For final artist replacements, preserve each 1448×1200 RGBA canvas and the
y=1000 arm baseline, including hanging hands below it. Put final artwork outside
`assets/generated/` and update `PeachSodaCast.ART_ROOT` or its asset mapping;
review `profile_texture` if face framing changes. Remove retired entries from
the active manifest, archive the replaced generated files and their `.import`
records under excluded `outputs/`, and retain retired hashes in
`scripts/release/known_generated_asset_hashes.sha256`.

### Retired generated utility-room illustration

The warm sketch UI migration replaced Main.gd's old room bitmap with the native
`PeachSodaBattleBackdrop.gd` drawing. The PNG, import record and retired manifest
entry are archived in `outputs/locals_pivot/superseded/warm-sketch-ui/`. The old
Mina scene is similarly archived in the adjacent `peach-soda-replaced/` folder.
Both are excluded from exports, and their hashes remain in the historical audit.

After replacements, run `scripts/release/check_no_ai_assets.sh --audit-known`.
The old command name is retained: it audits registered generated files and
exclusions, without claiming that a passing build contains no AI art. When the
last generated asset is replaced, retain the manifest schema with an empty
`assets` array. A generated replacement needs its own prompt, exact hash, path
and consumers; it must not be relabeled as final non-AI artwork.

## Supplied Mina animation

The separate-mat/live-hand follow-up adds **no image-generated art**. Both cloth
mats are native meshes and ink paths. `scripts/ui/RivalHeldCards.gd` reuses the
native Peach Soda sleeve and copies only existing supplied finger pixels into
a cached runtime overlay. The GIF and decoded frame files remain unchanged.
Mina's visible backs now track actual combat events, including draws, plays,
discarding and empty hands; other generated portraits' baked cards remain
decorative.

`assets/characters/mina/` contains the owner's supplied `IMG_0450.GIF` and its
losslessly decoded runtime frames. It replaces the interim Bea presentation
of Mina's encounter in the introduction, battle character and profile badge.
The source artwork was not regenerated or recolored. Its six 70 ms frames and
original transparency are retained; Reduced Motion shows the first frame.

This supplied asset is recorded separately in
`assets/characters/mina/provenance.json`, with original-file and frame hashes.
`GENERATED_ART_ENABLED` and battle's `use_generated_opponent_art` affect the
eight registered working portraits above, and deliberately do not hide Mina.
The source file's authorship is not asserted by this preparation record.

## AI-assisted editable implementation

Codex also authored the following code/vector presentation work. These are
editable components, not baked generated illustrations:

| Element | Main replacement/edit point |
| --- | --- |
| Supplied title logo positioning | `scripts/ui/LocalsWordmark.gd`; the unchanged logo PNG and provenance are recorded above. |
| Application icon | `assets/logos/chilling-at-locals-icon.svg` |
| Native title-background fallback and live menu/logo composition | `scripts/ui/TitleBackgroundPattern.gd`, `scripts/ui/TitleMenu.gd`; the supplied animated background and logo are recorded separately above. |
| Retired interim sleeve designs | `assets/cards/card_backs/peach_soda_sleeve.svg` and `assets/cards/card_backs/locals_sleeve.svg`; live backs now reuse the owner-selected original chef-hat `living_table.png` / `IMG_0398.PNG` (September 9). No new drawing or generation was used. |
| Battle action icons | `assets/ui/peach_soda_actions/{play,ability,attack,move,spice}.svg`; editable native vectors, no image generation |
| Printed card frames | `scripts/ui/RuntimeAngularCard.gd` (legacy class name preserved) |
| Deterministic sketch contours | `scripts/ui/WarmSketch.gd`; code-native ink paths, no generated texture |
| Hand-drawn control marks | `assets/ui/sketch_controls/`; original editable SVG checks, toggles, radio marks, chevron and slider knob, no image generation or copied kit artwork |
| Buttons and paper panels | `scripts/ui/BattleAngularButtonFace.gd`, `scripts/ui/BattleAngularSurface.gd`, `scripts/ui/TopdeckUIComponents.gd` |
| Menu and results paper sheets, existing room reuse | `scripts/Main.gd` |
| Starter selection sheets | `scripts/ui/SeasonSetupMenu.gd`, `scripts/ui/StarterSelectionSurface.gd` |
| Deck browsing, card inspection and dialogs | `scripts/DeckbuilderScreen.gd`, `scripts/ui/CardBrowser.gd`, `scripts/ui/GameModal.gd`, `scripts/ui/CardInspectionContent.gd`, `scripts/ui/CardInspectionOverlay.gd` |
| Supplied battle room/table positioning | `scripts/ui/PeachSodaBattleBackdrop.gd`; September 14 source illustrations recorded above |
| Supplied shop layers and snack positioning | `scripts/ui/PeachSodaShopIllustration.gd`, `scripts/ui/TournamentHubScreen.gd`; September 14 source illustrations recorded above |
| Battle prompts and turn slips | `scripts/Tabletop3DPrototype.gd`, `scripts/ui/TurnChangeGraphic.gd` |
| Battle scorecards | `scripts/ui/BattleMatchHudSurface.gd`, profile methods in `scripts/Tabletop3DPrototype.gd` |
| Hub paper HUD, round board and shop-service labels | `scripts/ui/TournamentHubScreen.gd`, `scenes/ui/TournamentHubScreen.tscn` |
| Counter price and availability tags | `scripts/ui/HubCounterShopView.gd` |
| Rival dialogue and paper transition | `scripts/ui/RouteRivalIntro.gd` |
| Restrained menu press feedback | `scripts/ui/MenuSparkleController.gd` |
| Flat Peach Soda mat and printing | `_build_production_arena` in `scripts/Tabletop3DPrototype.gd`, `scripts/ui/TournamentPlaymatPrint.gd`; the older fabric shader is not used by the battle mat |
| White silhouette outlines on floating card art | `assets/shaders/floating_card_art.gdshader`; `FLOATING_ART_OUTLINE` in `scripts/ui/GamePalette.gd`. Runtime shader, no generated or modified bitmap. |
| Shared colors | `scripts/ui/GamePalette.gd`, `PEACH_*` tokens across public UI; older aliases remain for compatibility |

The eight generated characters and retired title background are disclosed above.
The current title, shop and battle environments use the supplied September 14
illustrations; the title brand uses the separately supplied logo. The mat,
printed card frames, HUD, buttons and card-art outlines
remain editable code. Existing card illustrations, other supplied rival/player illustrations,
fonts, music and sound effects retain their existing source records in
`CREDITS.md` and the shipping provenance record. No new card-face illustrations,
music or sound effects were generated for this overhaul.

## Staged seated-opponent expression pack — not shipped

The five-opponent pack is at
[`outputs/locals_opponents/v3/README.md`](../outputs/locals_opponents/v3/README.md).
It contains 15 transparent 768×1024 PNGs: neutral, hurt and smile for Mina,
the existing `npc1` and `npc2` appearances, and proposed Owen/Priya designs.
The user requested a softer, more cozy/comfy revision and identified the
pink-haired v2 rival as the style reference. That rival is retained unchanged;
the other four characters were regenerated using only that visual reference
and text descriptions of their identities. The cast now shares rounded faces,
simple hair shapes, clean brown outlines and sparse shading. The v1 pack and
non-pink-haired v2 portraits are superseded development records only.

All five illustrations were created with the OpenAI built-in image-generation
tool. Exact prompts, source mappings and final hashes are preserved in the
pack's `prompts.json`, `retained-npc1-prompt.txt` and `manifest.json`.
The user explicitly authorized code-based background removal and splitting.
The cleanup utility, verified matte seeds, actual source regions and alignment
offsets are also included. Programmatic cleanup does not change the AI origin.

This is an artwork deliverable with no runtime consumers. It does not alter
the active generated-asset manifest or encounter identity routing. Artist
replacements should retain the common canvas and y=944 resting-arm baseline
across expressions. Before integrating Mina, replace the baked character scene
with the clean room plus her separate cutout, preserving live attack targets
and hand counts. Register exact consumed PNGs when they enter runtime assets.

## Three-ink title, shop and battle concepts — not shipped

The user's September 7 red/electric-blue/white reference exploration is at
[`outputs/locals_screen_concepts/three_ink_v1/README.md`](../outputs/locals_screen_concepts/three_ink_v1/README.md).
It contains three full-screen AI-generated raster mockups, with exact prompts,
reference paths and final-file hashes in the accompanying records. All six
supplied screenshots were reviewed; the five dedicated artwork screenshots
were supplied to the built-in OpenAI image-generation tool as style references.
The original reference art is credited in the pack as user-supplied work visibly
labelled @Blotter_art, not game-owned or newly generated artwork. Phone and
social-media interfaces were excluded from the design brief.

The scenes, characters, card illustrations, sample values and interface text
within these mockups are generated proposals. Battle received a targeted slot
layout correction and a separate hovering-art refinement. This exploration
does not change production art direction, shared palette tokens, encounter
routing or game rules. The mockups have no runtime consumers. Implementation
requires separate scene art and live interface controls, with authored card
data retained; these flattened screens must not be used as interactive UI.

## Peach Soda title, shop and battle concepts — not shipped

The user selected Peach Soda to remake the three-ink concept screens. The pack
is at [`outputs/locals_screen_concepts/peach_soda_v1/README.md`](../outputs/locals_screen_concepts/peach_soda_v1/README.md).
The built-in OpenAI image-generation tool edits the prior composition/style
references using warm white, peach, dark ink, deep teal and restrained mint.
Original game card PNGs are supplied as separate art inputs, with existing
affinity and Ingredient-band values specified independently of the room palette.

All flattened output screens are AI concept renders. Their card depictions
are conditioned on the originals, not guaranteed byte-identical copies. The
original source files remain untouched and authoritative for any implementation;
do not extract the generated depictions as replacement card art. Exact prompts,
input paths and final hashes are retained in the pack. There are no runtime
consumers, and no production palette or card data migration accompanies this
concept request.

## Peach Soda ink-and-flat-color Mina study — not shipped

The single Mina-at-the-table art-direction concept is at
[`outputs/locals_screen_concepts/peach_soda_ink_v1/README.md`](../outputs/locals_screen_concepts/peach_soda_ink_v1/README.md).
It was generated with OpenAI's built-in image-generation tool to explore
simple ink contours, flat colors, restrained painted texture and the Peach
Soda palette. No Aqua Studio brushes or other third-party brush assets were
used; this is an AI interpretation of the proposed drawing approach.

The pack retains the exact prompt, input reference path, output dimensions
and SHA-256 hash. Cards are shown from the back; existing face artwork is not
regenerated. The image has no runtime consumers and does not replace existing
card art, character art or interface assets. Its card slots are illustrative
placeholders rather than a gameplay layout specification.

## Peach Soda ink-and-wash game screens — not shipped

**Rejected by the user as "AI slop" after delivery. Do not use as an accepted
style reference.** Retained for provenance, not for production adoption.

The three camera/layout revisions are at
[`outputs/locals_screen_concepts/peach_soda_ink_screens_v1/README.md`](../outputs/locals_screen_concepts/peach_soda_ink_screens_v1/README.md).
The current battle, counter and title screenshots were supplied as composition
references, alongside the Mina ink study and a native reference sheet containing
original card art and live data. The battle restores the actual downward player
view and ten combat slots; the shop encloses four cards in a glass display case;
the title retains the actual overhead tabletop and centered menu.

All three final screens are AI-generated mockups made with the built-in OpenAI
image-generation tool. No Aqua Studio brushes or other third-party brush assets
were used. Prompts, a targeted battle correction, input hashes, final hashes and
known limitations are retained in the pack. Generated card depictions are not
replacement card art; the title Sriracharrow omits its recipe row. Original art
and card data remain authoritative, and these concepts have no runtime consumers.

## Peach Soda simpler drawing correction — not approved or shipped

The corrective three-screen exploration is at
[`outputs/locals_screen_concepts/peach_soda_flat_v2/README.md`](../outputs/locals_screen_concepts/peach_soda_flat_v2/README.md).
It uses the user's original flat drawing screenshots (visibly credited to
@Blotter_art), code-native gray layout diagrams and an original-card reference
sheet. The rejected painted screenshots were excluded from generation inputs.
OpenAI's built-in image-generation tool produced all three final scene mockups;
no Aqua Studio brushes or other third-party brush assets were used.

The pack retains exact prompts, geometry-guide source, input/output hashes and
a battle slot correction. It has no runtime consumers and no user approval at
the time of creation. Original card art remains authoritative; generated card
depictions and printed field miniatures are conceptual approximations.

## Peach Soda title composition v3 — not approved or shipped

The title-only refinement is at
[`outputs/locals_screen_concepts/peach_soda_title_v3/README.md`](../outputs/locals_screen_concepts/peach_soda_title_v3/README.md).
It replaces the concept's dominant central paper sheet with a large wordmark
on the teal mat, a compact menu and one asymmetric card arrangement. The
built-in OpenAI image-generation tool produced the complete flattened mockup;
no Aqua Studio or other proprietary brush assets were used. The pack retains
the exact prompt, input/output hashes, reference roles and replacement notes.

This is a proposal with no runtime consumers. The original user drawing
reference is visibly credited to @Blotter_art. Generated card depictions remain
approximations; authored card sprites, affiliations and live data are unchanged
and authoritative. This revision does not alter the shop or battle concepts.

## Eight Peach Soda character source concepts — sources not shipped

The user's request for eight characters in the latest title concept's style is
at [`outputs/locals_opponents/peach_soda_cast_v1/README.md`](../outputs/locals_opponents/peach_soda_cast_v1/README.md).
Pip, Otis, Ines, Sana, Milo, Bea, Kit and Ellis began as temporary concept names.
The later user request integrated their extracted illustrations into the battle
presentation through the centralized cast mapping; the opaque source concepts
themselves are still excluded from exports. Each has one seated pose
and relaxed expression. All eight complete PNGs were generated with OpenAI's
built-in image-generation tool. No Aqua Studio or other proprietary brushes
were used.

The latest Peach Soda title, flat battle concept and original user drawing
reference (visibly credited to @Blotter_art) condition the set. Pip's portrait
is an additional shared rendering reference for the remaining seven. The pack
contains eight individual PNGs, a local gallery, exact per-character prompts,
input/output hashes and a verified ZIP. They have opaque backgrounds and table
strips and slight framing variation, and are not consumed directly at runtime.
The extracted RGBA working assets now registered above use a shared canvas and
arm baseline. Additional expression variants remain future work. Original card
art, affiliation colors and game data remain independent of this art preparation.

## Superseded and unsuccessful experiments — not shipped

- **Retired Mina scene v2:** moved unchanged, with its `.import` record, to
  [`outputs/locals_pivot/superseded/peach-soda-replaced/locals-mina-scene-v2.png`](../outputs/locals_pivot/superseded/peach-soda-replaced/locals-mina-scene-v2.png).
  It was the 1585×992 opaque room-and-Mina illustration, formerly selected by
  `LOCALS_MINA_SCENE` and cropped for Mina's HUD portrait. It has no current
  runtime consumer. Original generation: `exec-dce655af-4fc4-4d3a-b1b4-54c434bababb.png`.
  Prompt: `docs/ai-prompts/locals-mina-scene-v2.txt`.
  SHA-256: `8d0649a5269304ad58cd04c3474ac0de97dae96e477b426fb33199a48efe8322`.
  Its checksum remains in the historical generated-asset hash list.
- **Rejected Pip alpha edits:** two new built-in extraction attempts returned
  RGB files with painted checkerboards. They are retained only as
  `docs/ai-prompts/peach-soda-opponents/pip-rejected-background-extraction.png`
  and `pip-rejected-alpha-retry.png`, with their exact prompts and source paths
  in the character provenance record. Neither was copied into runtime assets;
  the runtime working cutout instead preserves pixels from the original concept.
- **Initial room v1:** archived at
  `outputs/locals_pivot/superseded/locals-room-ai-v1.png` with its `.import` file.
  It is no longer referenced by runtime code. Original dimensions: 1672×941 opaque RGB.
  SHA-256: `63a811fee0ed8e50d5b3f61ff5e952c21644477e350b89f707d53774d3dab29d`.
  Prompt: `docs/ai-prompts/locals-room-v1.txt`. Its hash remains in the historical
  generated-asset denylist.
- **Attempted Mina transparency:**
  `exec-807ae8dd-6f96-4286-a8ae-869f68f39941.png` returned an opaque checkerboard
  rather than a usable transparent cutout. It is not used or copied under
  `assets/`; the original stays in the task's Codex generated-images directory.
- **Earlier full-screen concepts:**
  `exec-b4623124-42a4-4275-815a-01afa9df9744.png` and
  `exec-4c130328-250a-49ea-b969-bdb985ab6623.png` were generated with the same
  built-in tool earlier in the conversation. Their originals remain in the
  task's Codex generated-images directory. They are not runtime assets, and
  the later supplied table reference supersedes their differing layouts.

`outputs/**` and `docs/references/**` stay excluded from exports. Historical
concepts and failed attempts are not covered by active generated-art
registration merely because a current working illustration is authorized.
