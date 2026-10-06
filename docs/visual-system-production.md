# See You at Locals — Production Visual System

## Painted Shapes — September 14, 2026

The approved Painted Shapes direction replaces outlined kit surfaces and ruled
notebooks with matte cream/teal shapes. `PaintedUiShapes.gd` supplies cached,
deterministic native geometry and a compatible style resource. Text and input
remain separate; no new bitmap assets or continuous surface animation are used.

Shared buttons, panels, forms and dialogs use the same shape family. Ordinary
surfaces are lineless; keyboard focus, selection and card borders retain explicit
marks. Title/shop/battle layout changes reduce redundant status containers and
keep the supplied scene artwork visible. The left card preview, exact health,
blocked reasons and CHOOSE / USE ABILITY treatments stay functional.

The room and logo use the supplied September 14 PNGs, superseding the older
asset inventories below. UI colors use `GamePalette.gd` PEACH roles, with
Atkinson Hyperlegible Next and the existing text-scale setting. Review and
checks are recorded in `outputs/painted_shapes_2026-09-14/README.md`.

## Tournament kit implementation — September 11, 2026

The approved four-screen refresh uses native Godot composition and current
run data. Generated proposal images remain excluded reference material.

- `TournamentSlip.gd` shares venue/week/round stamps between hub and battle.
- `DeckboxDisplay.gd`, `WeeklyDemoScreen.gd` and `TournamentHubScreen.gd`
  present distinct physical prizes and the inspectable equipped passive.
- `Main.gd` and `RewardTableSurface.gd` present larger cards on a close tabletop.
  Claimed cards travel into the sleeved `RewardDeckStack.gd` beside the live
  count; Add All staggers arrivals. Claims save before travel, collected cards
  leave the cloth, and Reduced Motion updates the deck immediately.
- `Tabletop3DPrototype.gd` keeps inspection on the **left**, uses compact card-action
  icons with names on hover or keyboard focus,
  distinguishes normal Meal allowance from Special Serve, and preserves public
  attack consequences. `BattleSelectionMark.gd` and flat printed SVG frames
  replace the continuous selection glow. Tutorial instructions sit on the right.

Battle paint uses retained room, tabletop and foreground-plant canvases. Camera
impacts transform their Node2D holders without regenerating painted polygons;
viewport resizing can redraw the layers once. Card stock shares its two meshes,
and retiring board nodes remain hidden
until replacements finish their first draw, preserving compiled shader resources.
`BattleRenderingReuseSmokeTest.gd` checks these lifetimes, actual attacks and room
alignment with both headless and native rendering.

Original card art, card backs, character sources and combat/run rules remain
unchanged. Review captures and verification are recorded in
[`ui_implementation_2026-09-11`](../outputs/ui_implementation_2026-09-11/README.md).

## Current native runtime — September 8, 2026

The playable setup and shop now implement the starter-box and three-target
room concepts described in [`ART_DIRECTION.md`](../ART_DIRECTION.md). Earlier
concept-only notes remain historical records, rather than the current runtime
status. The September 7 summary below also predates the authorized generated
room title: the title still uses that explicitly tracked working illustration.

| Screen | Current implementation and editing point |
| --- | --- |
| Starter choice | `SeasonSetupMenu.gd`, `StarterDeckBox.gd`, `StarterTableSurface.gd`: three native windowed boxes and original full card faces; select box, choose difficulty rim, then Start. Package and affiliation colors remain fixed. |
| Shop overview and focus | `TournamentHubScreen.gd` and `scenes/ui/TournamentHubScreen.tscn`: clerk, glass case and vending machine in one room, with native focus travel and controls appearing after arrival. Reuses the supplied Mina animation as clerk. |
| Reward opening | `LocalsRewardPack.gd`: editable paper wrapper, with current card count and encounter tier from the actual reward offer. |
| Reward choice | `RewardTableSurface.gd` and `Main.gd`: stitched teal cloth with quiet edges and balanced card spacing; native card choices and pinned actions remain interactive. |
| Run results | `Main.gd`: actual final-deck signature/showcase cards, copy counts, recorded match outcomes and earnings on shared paper surfaces. |
| Battle trays and tutorial | `Tabletop3DPrototype.gd`: shared sketch-paper discard/search trays and high-contrast selection marks; clearly labeled fixed practice rules without combat changes. |

Retain native keyboard focus, Back/Escape, nested inspection and Reduced Motion
through these flows. Starter rules read current route values; the tutorial
explicitly distinguishes its 20-life/refill-to-two practice from 40 starting
life/refill-to-three Locals. Keep original card pixels, recipes and exact
affiliation identities in every preview, reward and results showcase.

No generated bitmap was added for this integration. The generated manifest
still contains **nine assets: the title room and eight rival portraits**.
Mina remains supplied art with unchanged provenance, not newly certified
human-authored art. Native paper, packaging, room and cloth drawers remain
editable code; see [`shipping-asset-provenance.md`](shipping-asset-provenance.md)
for the separate requirements of a zero-generated-art build.

## September 7 implementation record

The September 7 warm sketch UI follow-up promotes the Peach Soda `PEACH_*`
palette and shared `WarmSketch.gd` contours across all public screens. Menus,
shop controls, starter selection, card/deck browsing, rewards, settings and
results now use the same paper-and-ink drawing language. Soft Print is the
shared card-frame default, with original card PNGs and affiliation bands intact.
The native room drawing replaces the old generated utility-room bitmap.
See [`warm-sketch-ui.md`](warm-sketch-ui.md) for editing points and screenshots.

This document otherwise implements the current supplied-reference direction in
[`ART_DIRECTION.md`](../ART_DIRECTION.md). The user's
[`locals table reference`](references/locals-table-source-of-truth.jpg) governs
battle composition and materials. Campaign structure and balance remain
owned by [`CONCEPT_DIRECTION.md`](../CONCEPT_DIRECTION.md).

## One continuous card-shop experience

Every public screen should feel connected to the same afternoon at locals:
cream paper, warm ink, thin printed edges, cloth playmats, a wooden table,
readable cards and straightforward teal actions. The interface should sit
naturally within the shop rather than replacing it with a blank dark dashboard.

Stage utility screens, starter choice, collection views, rewards and results
over the existing room, table or cloth treatment. Keep enough of that setting
visible to explain where the player is. A focused sheet can cover busy artwork
behind text; do not solve contrast by turning the whole screen into carbon
panels. Full-screen dimming belongs to a temporary modal or transition, with
the underlying place still recognizable when the overlay is open.

Use the reference's material depth and contact shadows without reproducing its
protected outside-brand symbols. Preserve strong card identity and selection
contrast. Pokémon Black and White remains a reference for clarity and decisive
states; it does not prescribe futuristic framing, cyan edges or angular panels.

## Shared palette roles

The current room treatment is lineless painted furniture and architecture in
the shared Peach Soda colors, with restrained stable texture and value planes.
People keep authored navy contours and animation, without an added white rim.
This also applies to the shop clerk and rival-introduction portrait. Foreground
cards, field artwork, mat printing and paper controls keep their existing ink
and readable borders. The battle card inspector remains on the left. See the
September 11 lineless-room section of `ART_DIRECTION.md` for the approved scope.

Use `scripts/ui/GamePalette.gd`; do not create a separate palette per screen.
The public interface consumes these locals roles:

| Role | Token | Application |
| --- | --- | --- |
| Main paper | `PEACH_PAPER` | Scorecards, menus, modal sheets and readable content |
| Inset paper | `PEACH_PAPER_MUTED` | Input fields, quieter sections and separators |
| Primary ink | `PEACH_INK` | Headings, copy, numbers and ordinary icons |
| Secondary ink | `PEACH_INK_SOFT` | Supporting copy, captions and quiet metadata |
| Printed edge | `PEACH_EDGE` | One thin border or divider |
| Main action | `PEACH_TEAL` | Primary buttons, active tabs and keyboard focus |
| Cloth | `PEACH_MAT` | Tabletop staging and the physical battle playmat |
| Mat ink | `PEACH_PRINT` | Subdued slot outlines, stitching and printed labels |
| Life | `HEALTH_FILL` | Life bars and compact positive-state marks |

The older `SURFACE_ROOT`, `SURFACE_RAISED`, `TEXT_PRIMARY`, `FOCUS_EDGE` and
similar aliases still describe the previous dark UI in some code. Their names
are not permission to reintroduce that treatment. Migrate their public uses
explicitly to the locals roles or a shared component that applies those roles.
Retain older aliases only where compatibility requires them.

Keep semantic color local and purposeful. Use red for damage, danger and
insufficient resources; green for life and successful resolution; a restrained
gold mark for a reward. Ordinary buttons and utility sections do not need a
different color for every category. Ensure colored text remains readable on
paper, using a darker variant where needed. Affinity colors belong on card
bands, symbols and small identity marks, not entire surrounding screens.

## Typography and layout

- Use **Atkinson Hyperlegible Next** for all interface headings, labels,
  counters, buttons, settings, instructions and body copy. Establish hierarchy
  through size, weight, spacing and layout. Do not use Oxanium or a futuristic
  display face for interface headings.
- The existing wordmark is separate, editable brand artwork. Its lettering is
  not a second font system for menu controls.
- Use one thin warm edge, small friendly corners and a short contact shadow.
  Paper panels usually need a 1–2 px outline at 1440×900, not layered bevels,
  clipped armor, metallic highlights or a glowing perimeter.
- Keep comfortable internal margins and a clear order: title, relevant state,
  content, then the action. Avoid dense all-caps eyebrow text competing with
  the actual heading or several nested backings around the same information.
- Preserve existing minimum interaction targets and responsive behavior.
  Primary controls should remain at least 46 px tall at the design resolution.
  Scale or reflow content before shrinking readable text.
- Keep titles and action rows outside scrollable lists. Long content scrolls;
  navigation and the current decision remain visible at compact window sizes.

## Controls and interaction states

Primary actions use a simple teal fill with light text; secondary actions use
paper with dark ink. Hover can slightly deepen the fill or strengthen the edge.
Pressed state should feel like a small physical press. Selected options have a
clear fill/value change and, where useful, a checkmark or other explicit mark.
Keyboard focus stays visible through a teal outline or marker. Disabled states
must remain recognizable and provide a reason when the player needs one.

Do not add a universal cyan corner flash, white perimeter flash or decorative
sparkle to every menu action. Short movement, a restrained edge change and the
existing sound are sufficient. Use stronger effects for meaningful gameplay
moments. Reduced-motion mode removes travel, parallax and nonessential effects
without hiding state or blocking an action.

Preserve the current data and input contracts while changing appearance:

- Values remain live: life, money, hand and deck counts, remaining services,
  selected copies, prices, upgrades and unavailable-action reasons.
- Keep keyboard navigation, Enter/Space activation, Escape behavior, focus
  restoration, text scaling, high-contrast options and pointer hit targets.
- Do not change card rules, copy identity, economy or progression while styling
  a screen. Read the current run state; do not turn a screenshot value into a
  label that only looks correct.

## Shared implementation

Use `scripts/ui/TopdeckUIComponents.gd` for shared paper surfaces, typography,
status chips and action composition. `BattleAngularButtonFace.gd` and
`BattleAngularSurface.gd` retain legacy filenames for compatibility; their
public appearance is simple printed controls. The Sketch, Nexus and Workspace
libraries remain legacy implementation shims, not visual authorities for new
screens.

`GameModal.gd` owns the Back control, Escape handling, focus restoration and Tab
cycling. Keep its actions outside the scrolling body. Nested card inspection
closes before the parent dialog. Use the shared modal on the existing scene
instead of opening a new full-screen dashboard for each utility action.

`CardBrowser.gd` owns grouping, sorting, search and type/keyword filtering.
Upgraded and normal copies must never merge. Removal passes the selected
physical-copy index to `RouteRunService`. `CardInspectionContent.gd`,
`CardHoverPreview.gd` and `CardInspectionOverlay.gd` provide the same readable
card and keyword guide across screens, preserving live stats and upgrades.

Use the curated Material Symbols Sharp subset through
`MaterialSymbolsSharp.gd` for ordinary navigation and actions. Pair unfamiliar
symbols with text. Keep the game's authored affinity marks, card classifications,
recipe symbols and character emblems; do not substitute generic icons for them.

## Battle presentation

Match the supplied table composition: a broad charcoal fabric mat surrounded by
visible honey-colored wood, the seated rival above it, large printed hand cards
in the foreground, and compact paper scorecards anchored at the sides. See Art
Direction for the reference's proportions and camera anchors. Preserve the
required three Prep and two Plated slots per side and all live targets, even
where the visual reference abbreviates the rules layout.

Empty slots have complete, subdued rounded ink outlines and small printed
labels. Selection and valid destinations become clear when the action requires
it. Keep the center divider quiet and auxiliary symbols simple. Avoid a giant
mat logo or permanent bright brackets competing with the cards.

Card frames should read as printed trading cards in sleeves: clear artwork,
flat affinity bands, readable rule paper, concise statistics and restrained
edges. Floating field illustrations retain a thin white silhouette outline
that follows the art and fades with it. Preserve existing contact shadows and
short coordinated card movement without tinting the entire scene.

Attack previews use `CookingCombatService.attack_preview` and shared
`combat_exchange` math. Never inspect hidden opposing cards or sample random
outcomes to imply certainty. Keep visible follow-up effects identified when
they can change the resulting board. Battle action icons stay in one compact
row, with names on hover or keyboard focus and unavailability reasons in the
appropriate tooltip.

Generated room or Mina illustration remains replaceable working art. Its
current use, limitations, exact sources and replacement steps are recorded in
[`generated-art-register.md`](generated-art-register.md). Do not bake live UI
or rules into new illustration assets.

## Migration journey and hub behavior

The active journey is:

**Title → starter selection → tournament hub → Next Round / rival introduction
→ battle → reward reveal and card choice → tournament hub.**

Shop browsing, seller services, the floor's bye choice, deck inspection and
settings branch from the hub or current scene and return to it. Completing a
floor advances to the next available floor or the demo's intended endpoint.
Run defeat returns through the result flow. The old route-map and season-calendar
implementations are compatibility references; they are not the current public
journey and must not be reinstated by a visual migration.

Preserve the existing hub contracts from Concept Direction:

- Purchases and selected rewards enter the locked run deck, and life persists
  between rounds. Save and reload preserve those values and consumed services.
- The card counter keeps real cards in the room. Hover enlarges a card;
  selection lifts it and reveals one Buy action. Keep full inspection on
  right-click / I. Escape lowers a selection before leaving the counter.
- Clicking the seller zooms to her in the same room. Paid upgrade and removal
  remain separate from the floor's free bye choice. Preserve their existing
  prices, limits, return destination and disabled states.
- A spent bye becomes visibly unavailable for the rest of the floor. Do not
  reset it, refresh inventory or alter balances as a side effect of navigation.
- Use `Node2D` transforms for animated hub camera/parallax movement; Godot GUI
  snapping can round moving `Control` positions. Keep static UI on Controls and
  verify actual motion with `HubParallaxRenderCheck.gd`.

Migrate and verify complete journeys, including empty, disabled, selected,
post-purchase, post-reward and return states. Results use one clear outcome
heading; statistics and actions belong on the paper beneath it. Keep the room
or cloth visible so results and rewards still feel like part of locals.

## Verification

Use existing focused layout/input checks for the changed screens and inspect
real renders at supported window sizes. Check the smallest supported window,
large text, keyboard focus, nested-modal closure and reduced motion where the
changed component affects those paths. Preserve existing gameplay and save
checks; a visual migration is not a reason to adjust their target rules.
