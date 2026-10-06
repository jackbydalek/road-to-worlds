# UI refresh implementation

## Native consistency integration — September 8, 2026

- [x] Playable starter table uses three native retail boxes with original card
  faces in their windows. Box selection precedes the difficulty panel; Start
  requires an explicit border choice. Difficulty changes the card rim while
  package and affiliation colors stay fixed.
- [x] Playable shop overview shows clerk, glass case and vending machine.
  Focusing a target moves within the same room before its service controls
  appear. Back/Escape, focus restoration and Reduced Motion remain native.
  Supplied Mina replaces the earlier clerk presentation without changing her
  source pixels or provenance.
- [x] The reward opening uses an editable paper pack with the live offer count.
  Reward choices sit on a balanced stitched mat. Purchases, reward choices,
  prices, paid service limits and the shared one-use bye retain their rules.
- [x] Run results show real final-deck cards, copy counts and recorded outcomes,
  using the shared paper UI instead of an unrelated character showcase.
- [x] Battle discard/search trays use Peach paper, blue ink and readable
  selection states. Tutorial text identifies the fixed 20-life/refill-to-two
  practice and the separate 40-life/refill-to-three Locals rules. Chef remains
  the actual card type; opponents are described as rivals. The combat and
  compact stat-clearance implementation is preserved.
- [x] This integration adds no generated bitmap assets. Existing generated
  working art remains the title room plus eight rival portraits. Supplied Mina
  and existing card art retain their origin records; this is not a zero-AI
  release certification.

Editing points and presentation requirements are recorded in
[`visual-system-production.md`](visual-system-production.md) and
[`ART_DIRECTION.md`](../ART_DIRECTION.md). Native starter coverage lives in
`StarterSelectionFlowSmokeTest.gd`; related focused checks include
`TournamentHubSmokeTest.gd`, `RouteRewardLayoutSmokeTest.gd`,
`TournamentResultUiSmokeTest.gd` and `GuidedTutorialSmokeTest.gd`.
The shared seated-portrait shader now adds the same white exterior outline in
shop, rival introduction and battle, preserving source RGB, animation and fades.
HUD avatar crops remain unchanged. Tutorial panels also use native paper with
readable ink/teal text.

18 focused test scripts pass, including the 248-check starter suite and six
supplied-Mina cases. The final review contains 19 native screen/state captures
at both 1440×900 and 1280×720. See the
[current review and test list](../outputs/playable_consistency_2026-09-08/README.md).
These checks are separate from the historical September 5 totals below and do
not claim a full release gate or export. Steam was not edited.

## September 5, 2026 implementation record

User direction: implement the UI recommendations, send screenshots during the work, and reduce visible text. The loss banner contains only **DEFEATED**.

- [x] Shared Back/Escape navigation, modal focus restoration and focus cycling; pinned actions outside scrolling content.
- [x] Labeled battle actions, useful disabled reasons, and public-board attack previews using the same damage calculation as combat. Unresolved attack effects do not promise a kill.
- [x] Owned counts and resulting deck sizes in rewards/shop; before/after upgrade comparison; copy-specific removal and upgrade confirmation.
- [x] Fewer container outlines, shorter reward headers, neutral starter panels, and simpler settings rows.
- [x] Shared typography, 100%/125% menu text coverage, shorter copy and optional keyword detail through inspection.
- [x] Search/type/keyword filters, name/attack/health/copy/type sorting, grouped or individual deck copies; upgraded copies remain separate.
- [x] Starter popup, retained draft and finale use the common components. Brighter starter art, three representative starter cards, and a concise Continue round label.
- [x] Shared short transitions, reduced-motion support and brief Added/Bought/Upgraded/Removed/Restocked feedback.
- [x] Rendered screenshots and interaction/regression checks.

## Verification

48 of 49 release-check scripts passed across the broad sweep and targeted reruns. All UI checks pass. An existing opponent-composition check still expects three Cinnamon Snails in Expert Sweet; the current generic rival generator does not produce that list. This was already documented by the earlier balance audit. This UI pass leaves rival construction unchanged and does not claim a clean full release gate or export.

New checks exercise browser filtering/grouping/upgrade separation, physical-copy removal, before/after upgrade stats, successful and cancelled services, keyboard focus and inspection, attack damage/retaliation/overflow/Bodyguard/Piercing/defending/legality, hidden-information and RNG non-mutation, actual native pointer hover, and disabled action explanations. Supported small/large layouts and 125% text are covered. The result and reward tests include long recaps and crowded packs with pinned actions.

The broad checks also exposed an existing empty-pile refill loop. Both turn refills and draw-to-hand-size effects now stop when drawing makes no progress, including lethal reshuffle pressure. The Fresh/Funky and Card Effect Lab checks now complete; a dedicated refill test covers the fix.

Some short-lived scene tests still report Godot ObjectDB cleanup warnings. No remaining UI assertion failures or UI runtime errors were observed. Test save/settings fixtures use `/tmp` rather than requiring access to the player's save directory.

`outputs/ui_refresh/verification.json` records the final per-check status. `scripts/UiRefreshPreviewCapture.gd -- --public` recreates the standard screenshots; add `--small` for 1280×720 at 125% menu/battle text. Screenshots use deterministic fixtures, not a claim that a complete run was played manually.

## Shop interaction follow-up

Restored the requested shop selection: hover grows the card in place, click lifts it and reveals Buy above it, and Buy reuses the original burst, collection flight, funds animation and deck confirmation. Right-click / I still opens the shared keyword guide. Purchase input is locked until the animation finishes, and the deck count changes on arrival. The wordless shop sign and counter zoom remain in use. The updated trailer in `outputs/shop_trailer` exercises actual pointer hover/click and asserts that the animation runs and blocks a second purchase.

The current hub, counter zoom/selection, shop-refresh and shared-inspection checks pass. The separate legacy `RouteShopEventSmokeTest.gd` passes its purchase assertions but still fails its old removal/upgrade picker assertions: it expects a removed six-column grid, then passes an empty card ID. That obsolete picker check is outside this interaction change; no claim of a fully clean release gate is made here.
