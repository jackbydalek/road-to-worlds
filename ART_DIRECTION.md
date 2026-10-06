# See You at Locals — Visual Direction

## September 2026 pivot — the current direction


### Painted Shapes UI — September 14 approved implementation

The owner selected **Painted Shapes** from the September 14 UI drafts and
requested implementation. This supersedes the notebook sheets, outlined kit
buttons, paper shadows and status rails described in earlier UI entries.
The supplied logo, environment layers, character animation and card frames
remain authoritative.

- Use matte cream and teal native shapes with gently irregular, stable edges.
  Ordinary panels and buttons have no navy outline or drop shadow. Reserve
  contours for keyboard focus, selection, original cards and character linework.
- Keep Atkinson Hyperlegible Next, generous spacing and dark readable numbers.
  Teal identifies the primary action; cream/mint handles secondary and hover
  states. Disabled actions remain legible; important blockers name their cause.
- Keep the title action group quiet. The shop shows week/round, life, money and
  deck in one compact upper-left group, Save/Settings at upper right, and a large
  Next Round action at bottom center. Mina, the display case and vending machine
  have no permanent overview caption plaques; hovering or focusing their physical
  areas brightens their painted artwork. Preserve character alpha and linework,
  live card readability, descriptive tooltips and service details in close-ups.
  Battle follows the September 15 combat layout below.
- Shop close-ups keep the physical art central: Mina has a short service panel;
  the counter puts Reroll and Talk to shopkeeper above its cards and Back at
  bottom center. The vending focus frames the cabinet on the left. Its original
  packets brighten on hover/focus; selecting one lifts it and reveals only its
  action underneath (Upgrade a card / Heal 5 HP). No duplicate snack-choice panel.
- Preserve the **left bordered card preview**, icon-only actions with hover/focus
  names, strong CHOOSE and USE ABILITY cues, all slots and the left deckbox.
- `PaintedUiShapes.gd` supplies deterministic cached geometry for controls and
  theme styles. No redraw-time image generation, animated surface noise or
  continuous layout movement. Reduced Motion and enlarged text remain supported.
- Generated draft card faces and text are illustrative only. Runtime uses the
  existing card renderer, original artwork, rules and saved game state.


### Foil upgrade reveal — September 15 approved implementation

Upgrading a card is a brief center-screen reveal over the dimmed scene. Lift the
chosen copy out of its picker, show its original artwork and selected border at
a generous size, then reveal the foil with a stronger pearlescent sweep and a
few cream, mint and gold glints. Keep the permanent idle foil restrained and
the printed rules readable. Finish by turning the card into its sleeve and
landing it continuously in a visible deck pile before returning to the shop.
Let the animation carry the reveal without a heading or progress captions.
This returns an upgraded copy to the same deck; it does not add an extra card.
Save the upgrade before the animation and block repeat input until it finishes.
Reduced Motion keeps the centered reveal and dimming, with a short stationary
shine and dissolve into the deck instead of tilting or travelling.

### Combat reference layout — September 15 approved implementation

Keep the live board camera, mats, centered hand, rival artwork and left deckbox.
Use larger corner health panels: the player at lower left and the rival high on
its right, beside the seated character. End Turn stands alone at the right mat
seam. Turn ownership and the normal Meal allowance remain in its hover/focus
help and accessible description; turn banners and action-state labels remain.
The venue/tournament and exact rival-hand plaques appear only with Board Info.
Active restriction notices stay clickable in the right column between rival
health and End Turn, with scrolling for multiple effects and enlarged text.
The bordered card inspector stays on the left, above the player's health.

### Supplied title logo — September 14 approved implementation

Use the owner's supplied `IMG_0477.PNG` as the title brand, preserved unchanged
at `assets/logos/see_you_at_locals_supplied.png`. Retain its authored lettering,
colors, transparency and proportions; fit the complete sign into the room's
blank upper wall. This replaces the earlier native **SEE YOU AT / LOCALS**
lettering on both the illustrated title and native-background fallback.
`LocalsWordmark.gd` positions the supplied sign; menu labels, saved-run state and
keyboard focus remain native. The separate application icon is unchanged.
Source details are recorded in
`assets/logos/see_you_at_locals_supplied.provenance.json`; supply does not assign
new authorship or license terms.

### Supplied screen artwork — September 14 approved implementation

Use the owner's supplied title, shop and battle PNGs in
`assets/illustrations/supplied_locals_2026_09_14/`. This supersedes the native-only
environment instruction below. Preserve the supplied colors, painted edges and
transparency; the manifest records the unchanged original files.

- Loop the three supplied title frames in order, with frame one held in Reduced
  Motion. Use the supplied logo above; keep the menu, saved-run state and
  keyboard focus native.
- Build the shop from its background, counter and vending layers. Place live
  stock and the animated clerk in the room, and use **Heart Bites** and **Foil
  Crunch** for the existing heal and upgrade services. Keep prices, service
  limits, deck inspection and escalating rerolls functional.
- Use the separate battle room and tabletop layers behind the live rival,
  hands, playmats and cards. The table follows the camera horizon without
  rebuilding artwork during attacks. Keep the deckbox and bordered card
  preview on the left.
- The full-screen shop and battle exports guide composition; they do not
  replace interactive cards or controls. Scale registered layers together and
  keep controls readable and reachable across supported window sizes.

### Lineless painted rooms, inked people — September 11 approved implementation

The owner approved implementing the [lineless room concepts](outputs/lineless_background_concepts_2026-09-11/README.md)
and their [people without white outlines](outputs/lineless_background_concepts_2026-09-11/no_white_outline_v2/README.md).
This supersedes the earlier white person silhouettes and outlined furniture
instructions below. Keep the existing Peach Soda palette and scene compositions.

- Background architecture, shelves, furniture, vending cabinets, cases, pots,
  foliage and retail stock use **crisp lineless painted shapes**. Separate forms
  with opaque color/value planes, overlap and small contact shadows. Use gently
  irregular edges and restrained, stable paint texture; no blurry washes,
  heavy grain, full-screen noise or continuous navy furniture contours.
- People retain their authored navy hand-drawn contours, identities, poses,
  colors and existing animation. **Do not add a white or cream exterior rim**
  in the title, shop, rival introduction or battle. Mina's supplied six-frame
  animation remains intact; Reduced Motion still uses its stable first frame.
- Playable foreground cards, mats, slot printing, selection marks and paper
  controls retain their clear ink. White borders on cards and floating field
  artwork remain; the no-white-rim change applies to people.
- Card previews retain the selected Black, Blue, Yellow, Silver or Gold rim.
  The chosen color owns the outer silhouette; do not add a second black rim
  or oversized black 3D card body. Inner printed ink remains. The left
  battle preview and expanded inspection must carry the same border as the
  displayed card; lineless environments do not remove card framing.
- The battle inspector and its actions remain on the **left**. Preserve both
  mats, all three Prep/two Plated slots per side, live health, original card
  art and every action. Shop prices, service limits and focus behavior remain
  live controls, separate from the environment drawing.
- Environment implementation is superseded by the September 14 supplied layers
  above. The title uses the supplied logo; menu text and controls remain native.
  Do not ship flattened concept screenshots as interactive screens.

The supplied foliage illustrations guide paint edges and layered shapes only;
their dark forest palettes, density and characters do not redefine this game.

### Battle feedback clarity — September 11

Valid zone switches use the shared selection blue for the dotted targeting
arrow and its arrowhead, including swaps into occupied slots. Invalid switch
destinations remain neutral; valid attacks retain their red arrow.

When Iceberg Skunkuce prevents Prep effect damage, highlight the protecting card
and connect it to a mint-and-cream shield over the protected card. A paper
callout names Iceberg Skunkuce and the blocked damage amount. This cue follows
the effect's existing event order and finishes before the next action. Do not
show a damage number, hit reaction or HP loss for a prevented hit. Reduced
Motion keeps the source mark, connecting line, shield and label stationary.

Usable activated abilities carry a matte teal **USE ABILITY** tab with cream
text, paired with the same broad mint-and-cream perimeter and inward pointers
as **CHOOSE** cards. Keep the action label distinct from attack readiness and
recipe selection. The perimeter gently expands in normal motion and stays fully
visible and steady in Reduced Motion; only currently usable abilities show it.

Buffs finish their visual cue before their increased ATK/HP appears on the
card's printed stats or left inspector. A move or play must not expose the
resolved bonus while placing its card. Consecutive buffs reveal their changes
in order; combat rules still resolve immediately. Reduced Motion uses a short,
stationary buff cue followed by the same stat update.

Summoned cards remain hidden through earlier animation groups until their own
arrival begins. Saladmander enters and finishes its effect cue before its Fresh
tokens appear in Prep. Crisp Capybara finishes its cue before opening the deck
picker; the selected Ingredient travels from the deck, then resolves its own
on-play cue and results. Tokens appear from their destination slots rather than
the player's hand. Preserve this ordering in Reduced Motion.

Cards returned from the board to a hand stay visible in their actual board
pose while the source effect resolves, then travel continuously into the hand.
Keep their destination copies hidden until landing. Rival returns turn to the
supplied sleeve and join the live held fan on arrival; Reduced Motion transfers
them immediately after the source cue. Preserve distinct copies and existing
token evaporation rules.

During a **choose-card prompt**, selectable cards use a prominent perimeter:
a broad mint aura with an opaque cream core, inward pointers and a **CHOOSE**
tab outside the card's printed content. The cue gently expands in normal motion
and remains fully visible and steady in Reduced Motion. Selected cards switch
to a checked teal frame and **SELECTED** tab. Apply this to legal effect/ability
targets, recipe Ingredients and eligible discard-cost cards; remove it when the
prompt ends. Deck/discard choice trays use a broad teal edge and the same labels,
while ordinary browsing stays quiet. This stronger actionable-card treatment
supersedes the earlier restrained candidate outlines below.

Active play restrictions name their source and duration in a compact paper
list above the rival's life meter. The source opens inspection. The selected
card also explains its disabled action without requiring hover; failed plays
use the same explanation. Cinnamon Snail increases **normal** Meal recipes;
Special Serve remains independent. Timed Tool/Chef locks keep their source
attribution after that card leaves play and clear when the affected turn ends.

Every seated portrait that visibly holds cards uses live concealed sleeves:
Mina, Pip, Milo and Bea. Draws, plays and discards change the actual fan, with
zero cards leaving empty hands. Native garment covers and original finger
layers replace the three painted fans without changing the source portraits.

### Your Tournament Kit — September 11 approved implementation

The player's physical deckbox sits on the tabletop beside the left edge of
their battle playmat. Show the saved champion prize's existing shape and motif;
without a champion prize, use a plain teal-and-cream Basic Deckbox with no bonus.
Keep it clear of slots, the hand and health controls. It follows the board camera
and viewport size, stays below the left inspector, and never intercepts input.

The owner approved the battle, shop, reward and deckbox-prize direction in
[`ui_mockup_images_2026-09-11`](outputs/ui_mockup_images_2026-09-11/README.md),
with one explicit correction: **the battle card preview stays on the left**.
This also applies during the guided tutorial; its instruction sheet moves to
the right. The generated screens are composition references, not runtime assets.

Use a compact paper tournament slip with live week/round stamps, quiet status
values and a persistent inspectable deckbox beside the hub's Deck control.
The singles-case closeup includes a native **Reroll · $N** button with the
current price and a short explanation of its per-use increase and post-battle
reset. Keep it available when stock is sold out, explain insufficient funds,
and include it in keyboard focus while disabling it during camera movement or
a card purchase. Replacing stock clears inspection of the previous offers.
Deckbox prizes are distinct native folded objects on cloth, with exact effect
labels, selected lift/check and one confirmation. Keep valid saved prize offers
and equipped effect snapshots. The current pool contains five prizes: Tip Jar,
Big Lunch, Light Pack, Chef's Edge and Padded Picnic. Light Pack and Chef's Edge
then open a mandatory card-copy picker with a clear remaining count and an
explicit confirmation for each removal or upgrade. Preserve progress across
reloads and finish if no eligible copies remain. Use the selected card's actual
frame and upgrade state so duplicate copies remain distinguishable.

Battle selection uses a lifted card, a flat teal check and restrained printed
legal-target cues. Keep both mats, supplied rival art and compact green life
meters. Use compact icon-only actions beneath the left preview, with action names
on hover or keyboard focus and persistent explanations for blocked plays. Show
normal Meal availability beside End Turn, and explain that Special Serve preserves
that allowance.
Replace continuous neon selection halos with matte printed frames.

Rewards place larger original cards on a snug cloth beside an opened wrapper.
The September 11 follow-up replaces claimed-card stamps with a physical
collection animation: each claimed face leaves the cloth, turns into its sleeve
and lands in the visible deck beside the live count. Add remaining/All uses a
short staggered sequence and continues after the final arrival. Save each claim
before travel; reopening a partial pack shows only its unclaimed cards. Reduced
Motion removes travel and updates the same deck immediately. Preserve individual
Add, Add remaining/All and Skip/Continue. Use native controls, Atkinson text,
shared Peach tokens and clear keyboard focus throughout.

### Compact battle health meters — September 9

The player and rival now use the full supplied Cozy UI pack's continuous
progress-bar track and separate fill. Use `CozyHealthBar.gd` with the shared
palette mapping: cream track, blue contour, subtle leaf-green life
(`PEACH_HEALTH`, `#6B8A60`), and a short peach damage trail. Keep exact native
life totals above the meter so text contrast remains stable at every health
value. Rounded source caps resize independently of the
center; the empty state has no residual fill.

Replace the large enclosing competitor cards with compact portraits and a
quiet name/number strip. Player portrait sits left of its bar; the rival's
portrait sits right, with its bar draining toward that portrait. The rival
readout rests on clear tabletop beside the opposing mat. Clicking portraits
still expands hand/deck/discard details, and direct-attack targets stay live.
Original source PNGs and full-pack provenance are in `assets/ui/dobo_cozy/`.
This change adds no generated art.

### Cozy UI composition pass — September 9

Use the supplied pack as a coordinated family of paper pieces. Primary
actions use its rounded blank button; quieter compact actions may use its
square button. Keep blue ink, pale paper, restrained mint accents and existing
action-state contrast. The title action group sits on the supplied perforated
note, with one dominant action and a compact secondary row. Shop status values
share one quiet rail, while clerk and machine services sit on rounded paper
slips with small mint tabs and explicit prices/limits. Settings uses one sheet,
category tabs and light row dividers instead of nested frames.

Shared menu and battle HUD surfaces use the same sourced panel contour. The
pack's small heart is reused for life in the shop and battle. Text, option
values, card numbers, gameplay state and hit areas remain native and stable.
The title note and heart are unchanged additional source PNGs, conventionally
palette-mapped by `CozyPackAssets.gd`; no generated image assets were added.
Review captures are in `outputs/cozy_cohesion_v2/README.md`.

### Supplied Cozy UI demo adaptation — September 9

The owner supplied dobo_ui's Cozy UI demo for conventional recoloring and
modular resizing. Shared Peach buttons and sketch panels now use selected
blank source shapes with nine-slice borders. Use `CozyPackAssets.gd` with
`GamePalette.gd`: dark blue ink replaces brown, cream paper supplies quiet
surfaces, teal identifies actions and the existing semantic states remain
legible. Keep labels, focus marks and hit areas native. The pack's original
colors and name do not redefine our visual direction.

Checkboxes and popup check marks use the selected source marks. Existing
switches, radios and sliders remain because the demo supplies no equivalents.
Card frames, ribbons, art, affiliation colors and world props retain their
current treatments. The source manifest and credits are in
`assets/ui/dobo_cozy/`; this pass adds no generated bitmap artwork. See
`outputs/dobo_cozy_ui_v1/README.md` for palette and in-game review captures.

### Card-shop merchandise, not book rows — September 9

The owner requested replacing book/binder-like background stock with objects
that unmistakably belong in a card shop. Use chunky deck boxes with folded or
magnetic flap lids, an occasional open sample with sleeved cards/dice tray,
sealed sleeve packs with retail hanger tabs, and rolled cloth playmats with
visible spiral ends, straps or capped carry tubes. Vary their proportions and
arrange them as retail displays rather than identical tall labeled spines.

The supplied deck-box photos guide physical construction only. Do not reproduce
their brand names, logos or third-party card illustrations. Keep Peach Soda
colors, blue sketch contours, the current people and white silhouettes, room
composition, live controls, glass singles case and vending machine.

The title's targeted merchandise edit remains registered generated working art
at `assets/generated/title/locals_room_white_outline_ai.png`. Its prior revision
and the product references are archived under excluded
`outputs/card_shop_merchandise_v1/title/`. Shop and battle merchandise remain
editable native drawing. Artist handoff dimensions are unchanged; final room
art should use these accessory shapes instead of the old book-like stock.

### Restored supplied chef-hat card back — September 9

The owner selected the sketchy chef-hat back from the earlier demo as the final
shared card-back design. Reuse `assets/cards/card_backs/living_table.png`, the
unchanged 1620 × 2160 supplied `IMG_0398.PNG`: charcoal stock, hand-drawn grey
border, colored affiliation arcs and white chef hats on a small fan of cards.
Keep its original drawing and colors. This supersedes the interim Peach Soda
and Locals SVG sleeve designs; a new sleeve illustration is not required.

Battle decks, concealed hands, draw/reveal flights, reward pack backs and the
shop fallback share this supplied texture. Card faces, affiliation ribbons and
the live-hand animation remain unchanged. Existing credits record the owner's
CC0 declaration; that license record is separate from the pending production-
method check in the asset handoff. This restoration adds no generated artwork.

### Authorized name change — September 8

The owner has authorized changing the game and current concept artwork to
**See You at Locals**. Use **SEE YOU AT** as the smaller first line and
**LOCALS** as the dominant second line in the native wordmark and current
title/capsule concepts. Keep the current palette, sketch treatment and character
outline experiment. Short **Locals** venue/prop labels remain appropriate.
Historical source records keep their original wording; existing save/application
identifiers are preserved for compatibility. This rename does not itself
publish a store update.

### Native playable UI integration — September 8

Full seated portraits now share a native white exterior silhouette in the shop,
rival introduction and battle. The edge scales with source canvas height,
retains the existing blue interior linework and respects animation/fades. The
same supplied Mina source is used across those screens; cropped HUD avatars
remain unchanged. This shader adds no generated image assets.

The starter-table and three-target shop concepts below now have **native
playable implementations**. Their dated prototype records remain as design
history; statements there that runtime integration is separate describe the
earlier stage. The game uses editable drawing, real card faces and live state,
not flattened screenshots of those prototypes.

- **Starter table:** `SeasonSetupMenu.gd`, `StarterDeckBox.gd` and
  `StarterTableSurface.gd` stage three windowed paperboard boxes on a warm
  table. The windows show original Sriracharrow, Gravy Gazelle and Strawberry
  Sharkcake faces. Selecting a box brings it forward before the border panel
  appears. Black, Blue, Yellow, Silver and Gold change the card rim only;
  package colors and exact affiliation symbols stay fixed. Start requires a
  border choice; deck inspection, Back/Escape, keyboard focus and Reduced
  Motion use the live setup flow.
- **Shop:** `TournamentHubScreen.gd` and its scene present the clerk, glass
  singles case and vending machine together. Each focus moves within the same
  room and reveals its own controls after arrival. Back/Escape returns to the
  overview; Reduced Motion skips travel. The clerk reuses supplied bob-haired
  Mina with a native pale silhouette edge. Card prices, paid services and the
  machine's shared heal-or-upgrade bye remain run data, including OUT OF ORDER
  after that bye is spent.
- **Rewards and results:** `LocalsRewardPack.gd` supplies a native paper wrapper
  with live reward count and round/top-cut/champion labeling. The card-choice
  area rests on `RewardTableSurface.gd`, a quiet stitched cloth mat with
  balanced space around the cards. Results show actual final-deck cards,
  copy counts and recorded run outcomes through `Main.gd`, replacing the
  unrelated character presentation.
- **Battle utilities:** discard and search trays use the shared Peach paper,
  blue ink and explicit mint/teal selection marks. The guided tutorial now
  labels its fixed 20-life, refill-to-two practice rules separately from a
  Locals run's 40 starting life and refill-to-three rule. Original card art,
  affiliation, combat rules and the compact stat-clearance fix remain intact.

This pass adds **no generated bitmap assets**. The existing title background
and eight rival illustrations remain registered generated working art in
`assets/generated/manifest.json`. Supplied Mina's origin record is unchanged;
reuse and native outlines do not establish human authorship. Editable UI code
and unchanged supplied card art are not a certification of a zero-AI build.

### Integrated starter-table arrangement — September 8 concept revision

The owner requested the windowed boxes integrated into the scene with a cuter
table layout. See the [revised scene concept](outputs/locals_starter_boxes_v2/README.md).
Arrange three paperboard boxes naturally on the cloth: side boxes tilt gently
and the middle box sits slightly farther back. Ground them with shallow folded
sides and contact shadows. Keep complete card faces visible in their windows.

Use small physical welcome notes and paper deck tags in place of a large
floating banner and repeated tile labels. Keep the table's plant, drink and
scorepad near the edges, with only a few small cloth or sticker details.
The packages remain the focal point. Preserve readable native text, exact
affiliation symbols, the separate difficulty-border choice and reduced-motion
behavior. The integrated illustration remains flagged generated concept art;
the standalone clickable revision uses separate editable packages and original
card images. This scene exploration does not itself replace the runtime setup.

### Windowed retail starter boxes — September 8 concept revision

The owner requested retail starter-deck packaging with a window revealing a
card, using a supplied package atlas as a construction reference. See the
[windowed-box concept](outputs/locals_starter_boxes_v1/README.md). This revises
the tabletop selection exploration below; it is not a runtime replacement.

Use three matching slim paperboard boxes with hanger tabs, punched slots,
visible folded sides and large inset front windows. Muted coral, mint and
powder blue identify Spicy, Hearty and Sweet; retain their exact affiliation
seals. Show existing Sriracharrow, Gravy Gazelle and Strawberry Sharkcake art
through the windows. Keep the card face, package, text and controls separate.
Difficulty changes the visible card's border, while package and affiliation
colors remain fixed. Preserve the select-box, choose-border, Start sequence.

Keep blue sketch contours and the Peach Soda room palette. The atlas supplies
packaging form only; its franchise characters, branding and text are not used.
The generated packaging illustration is a flagged concept, separate from the
editable boxes and untouched existing card images in the clickable preview.

### Starter decks on the table — September 8 concept

The owner requested a starter-selection concept built around three physical
decks resting on a table, replacing the visual character-roster metaphor.
See the [clickable concept](outputs/locals_starter_table_v1/index.html).
This is a presentation prototype; it does not replace the playable setup yet.

Spicy, Hearty and Sweet use existing card art and native pastel-ribbon faces.
Selecting a deck brings its stack forward before revealing a paper difficulty
panel. Black, Blue, Yellow, Silver and Gold choices update the outer frame;
affiliation ribbons and symbols keep their existing colors. Pair every border
swatch with a name and selected mark. Start follows an explicit border choice.
Back returns to the same table; Reduced Motion uses the same stable states.

Keep the warm wood, teal cloth and blue-pen treatment consistent with the title
room. The new table illustration is generated concept art under excluded
`outputs/`; card faces and controls remain separate editable layers.

### White-outline card-shop title screen — September 8

The owner selected the supplied seven-person card-shop illustration as the
playable title screen and explicitly requested white outlines on every person.
The preserved source and edited versions are in
[`locals_room_title_v1`](outputs/locals_room_title_v1/README.md).
This approves the white silhouette treatment for this title illustration;
shop and battle comparisons below remain separate references.

Keep the supplied room composition, Peach Soda fills, blue pen contours,
character designs and all seven people. The title background removes the old
shop HUD and interaction labels. Its upper-central noticeboard holds the
editable **SEE YOU AT / LOCALS** wordmark; live menu controls sit in the open
aisle, clear of faces. Illustration remains static; button text, hit areas,
keyboard navigation and saved-run availability are native UI.

`assets/generated/title/locals_room_white_outline_ai.png` is explicitly
**generated working art**, recorded in `assets/generated/manifest.json` and
`docs/generated-art-register.md`. It is one flattened replacement target;
white outlines do not make its origin human-authored. Keep an optional native
title fallback and preserve the existing save directory. Replace this bitmap
with final artist-made room/character artwork before a zero-generated-art build.

### White character outlines — September 8 comparison set

The owner requested comparison concepts with a white silhouette border around
all people, using the supplied poster as an edge-treatment reference. See
[`locals_white_outline_v1`](outputs/locals_white_outline_v1/index.html) for
title, shop and battle variants, including the shop close-ups.

The proposed edge is crisp and opaque, outside the existing blue pen contour,
following visible hair, clothes and limbs. Keep internal lines blue, preserve
table occlusion, and scale the edge down on small human portraits. It is a flat
paper-cut outline without glow; do not extend it to room props or interface
panels. Retain the Peach Soda palette and original card identities.

These three earlier screens remain generated comparison concepts, not blanket
runtime replacements. The title-specific approval above uses the subsequently
supplied seven-person room. The prior references remain available.

### Shop overview and three focus targets — September 7 concept revision

The owner supplied a notebook flow sketch and requested a shop concept whose
first view shows the **shopkeeper, glass card case and vending machine together**.
The current concept revision is
[`shop-overview.png`](outputs/locals_shop_focus_v2/shop-overview.png), with a
[clickable focus prototype](outputs/locals_shop_focus_v2/index.html).
These are reference/prototype work, not a statement that the game has already
implemented the revised flow.

The overview presents three scene targets. Clicking one pans/zooms to that
same location; its relevant controls appear **after** the camera arrives.
Shopkeeper focus reveals paid Upgrade Card and Remove Card, case focus reveals
stock/prices/purchase controls, and machine focus reveals the shared free bye
choice. Back or Escape returns to the overview. Keep stable HUD text and hide
unrelated service panels. Reduced Motion uses the same states without travel.

Make the machine recognizably a retail vending machine: a tall cabinet, glass
product rows with visible cans/packs and coils, physical keypad/payment column,
and a lower pickup hatch. Machine status and choices stay live UI. The bye is
still one shared heal-or-upgrade use, with OUT OF ORDER after it is consumed.

This request brings the initial shop camera closer to the counter and moves
the machine beside it for three clear targets. It supersedes the earlier wide
hub concept's always-visible machine choices for this shop flow, while retaining
the approved blue-pen Peach Soda rendering and supplied bob-haired clerk design.
Reuse a common room/counter/machine layer set for the zooms. Generated concept
pixels stay under excluded outputs; final human-made layers remain the art goal.

### Approved blue-pen room reference — September 7

The owner designated the latest generated shop-room image as the visual source
of truth for Next Fest planning:
[`shop-room.png`](outputs/locals_screen_concepts/peach_soda_line_boil_room_v1/shop-room.png).
Its rough blue pen contours, flat Peach Soda fills, simplified friendly faces
and lived-in card-shop composition guide the next production pass. Preserve the
counter and glass singles case, central bracket and bye machine, window tables,
foreground players and open aisle. This supersedes earlier room-rendering
explorations; it does not change the four-round Locals scope.

Translate the illustration into separate environment, character and interactive
layers. The reference is a flattened AI-generated concept, not a layered or
animated production asset. Keep its prompt and provenance, and track every
generated asset that enters runtime in `docs/generated-art-register.md`.
Visual approval does not change the recorded origin of the image.

Carry the drawing language into the title, shop and battle while preserving the
existing across-table battle camera, separate mats, supplied Mina animation,
original card art, exact affiliation identities and restored pastel ribbons.
Use blue contours for illustration; retain readable UI text, semantic action
colors and shared `GamePalette.gd` roles. Any line-boil animation belongs to
select illustration layers, with Reduced Motion support. Text, card numbers,
buttons and hit areas remain stable. The owner need not hand-draw each button:
the shared native sketch controls remain the implementation foundation.

### Restored pastel ribbon cards — September 7

The owner requested the earlier cozy **folded ribbon** card design again,
recolored for the current Peach Soda direction. The historical reference is
`outputs/card_ribbon_prototype.png`. Use the native `CardRibbon.gd` silhouette:
swallowtail ends, small darker folds, a rounded center plaque and a two-row
Meal/recipe treatment. Pair it with the circular affiliation seal, rounded
paper header/rules panels and soft stat tabs. Compact field cards use the
ribbon behind their live combat numbers.

Live field numbers fit inside the ribbon's central plaque, with smaller type
and a width cap for buffed values. Defending cards retain horizontal numbers
on a native copy of their affiliation ribbon at the near edge; turning the
card sideways must not leave the numbers hanging off a vertical ribbon.

Normal gameplay and captures share the same sharp card rendering: a 320×455
logical layout rasterized at 960×1365, with cached faces redrawn only when
their content changes. The battle render follows actual output pixel density
through window resizing and fullscreen/Retina scaling; the logical UI and
targeting coordinates stay fixed. Do not reserve clear card textures for
trailer captures or enlarge a low-resolution battle underneath sharp UI.

`RuntimeAngularCard.gd` owns this shared presentation. Broad ribbon colors mix
the existing affiliation ink with `PEACH_PAPER` using
`PEACH_CARD_RIBBON_PAPER_MIX`; identity colors remain exact on the seal. Per the
September 15 update, recipe symbols print in black directly on the ribbon,
without separate colored tile backgrounds. Keep `PEACH_CARD_FRAME` as the midtone artwork backing, with a restrained
affiliation tint, so white cutout outlines stay visible. Preserve original art,
rules, recipes, stats and all input behavior. This supersedes the flat bands
described below. The change uses native drawing and adds no generated imagery.

### Card frame contrast — September 7

Use `PEACH_CARD_FRAME` warm gray stock behind card artwork so its white cutout
outline stays visible on the table. Keep title, rules and stat regions on light
`PEACH_PAPER`, with the existing card art, white outline and affiliation bands
unchanged. The shared frame applies to both held cards and compact field faces.

### Separate playmats and Mina's live hand — September 7

Each player now has a separate native cloth mat, with its own binding and a
peach tabletop gap between them. Preserve the existing camera, card positions,
three Prep and two Plated slots per side, and original card/affiliation colors.

The visible native tabletop's far edge follows the projected table geometry,
with wood behind the opponent's full mat and beneath the seated arm anchor.
Do not use a fixed screen-height horizon: the room drawing and live 3D board
must remain aligned during resizing and camera movement. Keep the plant pot
above the tabletop drawing so extending the surface does not clip the prop.

Mina's free hand holds native, concealed card backs driven by real combat draw,
play and discard events. `RivalHeldCards.gd` places them behind a runtime cutout
of her original fingers, synchronized with her supplied animation. The source
GIF and decoded frames remain unchanged; this adds no generated image assets.
Reduced Motion holds her pose and snaps hand updates. Generated portraits with
baked cards retain their separate static-art limitation and numeric counters.

### Supplied Mina animation — September 7

The owner explicitly requested that the character in `IMG_0450.GIF` replace
Mina **in the playable game**, including the encounter introduction, seated
battle layer and profile portrait. Mina's existing encounter/save identity is
preserved; the interim presentation mapping to Bea is superseded for Mina.

Use the original supplied colors, bob haircut, cardigan and chin-in-hand pose.
The source GIF and six losslessly decoded frames live in
`assets/characters/mina/`. Every frame keeps its 70 ms duration, original RGB
and alpha, with a shared crop that removes empty padding. No image generation,
repainting or recoloring is part of this integration. This is supplied art,
separate from the registered generated working portraits. Disabling generated
portraits must leave Mina visible; Reduced Motion holds her first frame.
`SeatedRivalPortrait.gd` handles playback and `PeachSodaCast.gd` records the
canvas, arm anchor and profile crop. The two-color battle/capsule images remain
concept explorations and do not override these supplied runtime pixels.

### Hand-drawn control refinement — September 7

The owner supplied the [Hand Drawn Vector UI Kit on Behance](https://www.behance.net/gallery/25367489/Hand-Drawn-Vector-UI-Kit)
as a closer reference for controls, explicitly asking to avoid drawing every
button by hand. Use its soft, slightly bowed outlines, rounded pen corners,
simple checked/radio marks and sparing pencil hatching as drawing guidance.
Keep the selected Peach Soda palette, Atkinson labels, exact card identities
and native input behavior. The kit itself is a reference; no kit assets are
downloaded, traced or shipped.

The shared Godot drawers generate scalable contours for each control's bounds.
Geometry is stable across redraws and state changes; it does not consume game
randomness. Hatching belongs in short shadows or progress marks, away from text.
Original SVG control glyphs are in `assets/ui/sketch_controls/`. This work adds
no image-generated art and does not require the owner to supply button drawings.

### Warm sketch UI throughout the game — September 7 follow-up

The owner explicitly requested that the **whole UI now follow the warm,
sketchy Peach Soda battle style**. This promotes `PEACH_*` roles to all public
menus, starter selection, shop controls, deck/card browsing, rewards, results,
settings and dialogs, superseding the battle-only opt-in restriction below.
Original card artwork, affiliation bands, rules, layout information and live
input/state behavior remain authoritative.

Use cream paper, deep teal actions, peach tabletop accents, restrained mint and
dark ink. Shared `WarmSketch.gd` supplies small, deterministic contour variation:
one ink edge and a short contact shadow, with stable text and hit areas. No
animated line jitter, dense scratch texture, heavy repeated frames or sepia
wash. Atkinson Hyperlegible Next remains the UI font. Keep keyboard focus,
disabled labels, selection marks and semantic danger/life colors readable.

Utility menus now reuse the native Peach Soda room drawing. The former generated
room bitmap is retired under excluded development outputs. No new raster art
is needed for this UI pass; the eight flagged rival portraits remain separately
replaceable. See `docs/generated-art-register.md` for the active inventory.

### Peach Soda playable battle overhaul — September 7

The user has now requested a **full overhaul of the playable battle scene using
the latest Peach Soda title and eight-character elements**. This promotes that
specific palette/drawing approach into the battle implementation and supersedes
the older painted room/Mina rendering instructions below for battle. It does not
promote unrelated rejected concepts or change the tournament rules.

Use `PEACH_*` roles in `scripts/ui/GamePalette.gd`: clean warm white paper,
dark ink contours, teal actions and playmat, peach table and restrained mint.
The room, table, mat printing, sleeves, card frames and interface are native
editable drawing. Keep the existing across-table camera, three Prep and two
Plated slots per side, original card artwork and exact affiliation colors.
Battle cards opt into `peach_soda_frame`; other card surfaces retain their
current styling unless explicitly migrated.

Eight generated working character cutouts live in
`assets/generated/peach_soda_opponents/`. `scripts/ui/PeachSodaCast.gd` owns their
mapping, portrait crops and a single `GENERATED_ART_ENABLED` removal switch;
missing art safely falls back to the native card-club mark. Battle also has an
editor `use_generated_opponent_art` switch. Keep rival art separate from native
controls and register each consumed PNG. The unchanged concept RGB is extracted
to true alpha, with a shared 1448×1200 canvas and arm baseline at y=1000; Kit's
hand extends below that baseline. The live hand counter owns the actual count;
any cards held in the portrait remain static illustration.

The existing saved encounter IDs, names and combat data stay intact. Intro and
battle derive consistent presentation names/art through cast metadata. See
`docs/generated-art-register.md` and `docs/ai-prompts/peach-soda-opponents/README.md`
for AI provenance and replacement instructions.

### Palette exploration — September 7 clarification

The red/blue/white screen concepts are a drawing-style exploration, not a
requirement to limit the game's palette to those colors. The user explicitly
wants alternate fun scene palettes while retaining the existing card artwork
and color affiliations. Carry the reference's economical contours, flat color
shapes and expressive faces into the world and general UI; preserve authored
card illustrations in their original colors. Do not tint, regenerate or
quantize those illustrations to match a scene palette. Keep the current
affinity/tag colors and the quieter Ingredient bands from GamePalette.gd.
The user selected **Peach Soda for the revised screen concepts**: warm white
`#FFF4DF`, dark ink `#293047`, deep teal `#126866`, peach `#F2B398`, and restrained
mint `#C7DFD5`. This palette applies to scene art and general UI; original card
art, affinity colors and Ingredient bands remain independent. Production token
migration is separate from this concept request.

The user subsequently rejected
`outputs/locals_screen_concepts/peach_soda_ink_screens_v1/` as "AI slop".
Do not use that rejected pack as an accepted rendering reference. Its camera
and interface measurements remain separate from its illustration treatment.
The corrective exploration in
`outputs/locals_screen_concepts/peach_soda_flat_v2/` uses the original supplied
flat drawing references and plain geometry guides; it is **not yet approved**.
Do not silently promote a generated proposal into the production style guide.

### Supplied table reference — authoritative visual target

The user's supplied table image is preserved unchanged at
[`docs/references/locals-table-source-of-truth.jpg`](docs/references/locals-table-source-of-truth.jpg).
It is the authoritative reference for battle composition, camera perspective,
table and playmat proportions, rival staging, card scale, material depth,
lighting, and the placement and treatment of the match interface. Match this
specific scene closely; a generally cozy card shop is not sufficient.

This supplied image supersedes the prior airy, flat Locals implementation and
its screenshots wherever they differ. The target has a broad charcoal fabric
playmat ending above the foreground hand, generous visible wood around its
edges, a brown-haired Mina leaning across the table, and large printed cards
in the foreground. The rival, playmat, hand, and compact paper scorecards form
one composition. Preserve the warm illustrated depth, afternoon light,
contact shadows, and tactile printed details shown in the image rather than
flattening them into uniform gray surfaces or sparse floating controls.

At the reference's 16:10 aspect ratio, the playmat's far edge is approximately
29% down the screen and its near edge approximately 81% down. Its width grows
from roughly 54% at the far edge to 81% at the near edge. The four-card hand
spans roughly 49% of the screen width and occupies the bottom 28%. These are
composition anchors for visual review, with responsive fitting and the
existing gameplay's required zones remaining functional.

Keep cards, text, scores, controls and changing gameplay state as live,
functional elements; the reference image is not a single background to ship as
gameplay. Use its visible Mina identity for the reference encounter, not the
unrelated pink-haired default rival. The registered Mina scene illustration
and derived portrait are replaceable working art; their current limitations
and interactive target mapping are documented in the generated-art register.
Follow that register for any replacement derived from the supplied reference.

The game is now **See You at Locals**. The player fantasy is spending an
afternoon at a welcoming neighborhood card shop, getting to know rivals and
building a deck that can eventually reach Worlds. The competitive roguelike
rules remain; the presentation is relaxed, social, and tangible.

The approved locals concept replaces the former armored UI treatment:

- Contemporary card-shop interiors, afternoon daylight, wood match tables,
  fabric playmats, sleeves, deck boxes, tournament slips, and nearby players.
- Printed paper scorecards with charcoal ink, clear portraits and life totals.
  Small friendly corners, one outline, and a short contact shadow.
- Simple blue action tabs and strong readable selection states. No stacked
  bevels, metal frames, luminous cyan perimeter, or console-like dashboards.
- Card frames feel like printed trading cards in sleeves: large illustrations,
  flat affinity bands, readable rules panels, and restrained borders.
- Illustrations floating above field cards have a thin white silhouette outline.
  It follows the animated artwork and fades with it when the card leaves play.
- Warmth comes from people, materials, and lighting. Keep neutral readable UI
  and vivid individual card identities; avoid an overall sepia or pastel wash.
- Generated illustration is replaceable working art. Record its source,
  generation prompt, current file, consumers, and replacement instructions in
  `docs/generated-art-register.md`. Do not bake interface text or game rules
  into generated background images.

Pokémon Black and White remains an explicit reference for UI color logic,
clarity, contrast, hierarchy and decisive state language. Carry those qualities
into the supplied locals reference using paper and dark ink. It does not
require angular panels, carbon backings, cyan perimeter light, futuristic
fonts or copied assets and layouts.

This document owns visual direction. The implementation contract for shared
typography, spacing, controls and complete screen journeys is
[`docs/visual-system-production.md`](docs/visual-system-production.md).
Campaign structure and balance remain owned by
[`CONCEPT_DIRECTION.md`](CONCEPT_DIRECTION.md). A visual update must preserve
the live game rules, data and input behavior.

## Color and material roles

Use shared tokens from `scripts/ui/GamePalette.gd`. Do not create isolated
screen palettes or infer identity from legacy shop assets, licensed pack names
or old generic token aliases.

| Role | Token / current color | Use |
| --- | --- | --- |
| Main paper | `LOCALS_PAPER` · `#F4EFE3` | Scorecards, menu sheets, dialogs and readable card rules |
| Inset paper | `LOCALS_PAPER_MUTED` · `#E6DFD0` | Quiet sections, inputs and secondary controls |
| Main ink | `LOCALS_INK` · `#282C31` | Headings, copy, numbers and ordinary icons |
| Supporting ink | `LOCALS_INK_SOFT` · `#61666B` | Captions and secondary information |
| Printed edge | `LOCALS_EDGE` · `#8B8A82` | One thin warm border or divider |
| Action blue | `LOCALS_BLUE` · `#3279AA` | Primary action, active selection and keyboard focus |
| Charcoal cloth | `LOCALS_MAT` · `#24262D` | Physical playmat and restrained cloth staging |
| Cloth print | `LOCALS_PRINT` · `#A89E88` | Quiet slot outlines, labels, stitching and emblems |

Keep strong value contrast: dark ink on paper, light lettering on blue, and
warm subdued printing on the charcoal mat. Contrast should come from clear
surfaces and intentional hierarchy rather than many nested frames. Check the
actual text size and background before using a semantic accent as text.

Use red locally for damage, danger and insufficient resources; green for life
and successful resolution; restrained gold for a reward. Color must not be the
only way to identify selected, disabled, invalid or actionable states. Ordinary
utility controls should not each introduce a new category color.

The room supplies warm wood, sunlight and material variety. Keep the paper
readable and card illustrations vivid. Avoid an overall sepia tint, a blanket
pastel wash, or large competing affinity-colored UI surfaces.

## Affinity and tag colors

| Identity | Color |
| --- | --- |
| Spicy | `#EF3D56` |
| Hearty | `#45B96B` |
| Sweet | `#4E8FE8` |
| Fresh | `#F2D33D` |
| Funky | `#A85ED5` |
| Neutral / utility | `#89929F` |
| Spices tag | `#E36B3E` |
| Environments tag | `#24AFA7` |

Affinity colors identify card bands, symbols and small identity marks. They
remain distinct and saturated without becoming the background of every menu.
Preserve existing authored card identity and artwork; recolor individual assets
only when a deliberate change requires it.

## Typography, paper and controls

Use **Atkinson Hyperlegible Next** for all interface headings, body copy,
buttons, counters, settings and instructions. Create hierarchy with size,
weight, spacing and alignment. The supplied title logo is separate brand
artwork, not a reason to introduce another display font across menus.

Paper panels have small friendly corners, one thin warm edge and a short
contact shadow. At the design resolution, a 1–2 px boundary is usually enough.
Keep comfortable margins and familiar printed labels. Avoid stacked bevels,
clipped armor, metallic highlights, diagonal chassis pieces, glowing keylines,
glass panels or dense all-caps telemetry.

Use a straightforward blue primary action with light copy, and paper secondary
actions with dark copy. Hover slightly changes the fill or edge; pressing feels
like a small physical press. Selection changes value and fill clearly, with a
checkmark or explicit marker where useful. Keyboard focus has a visible blue
outline or marker. Disabled and invalid controls remain legible and explain
why an action is unavailable when that information matters.

Retain readable text, comfortable pointer targets, keyboard traversal,
Enter/Space activation, Escape behavior, focus restoration, large-text support
and high-contrast options. Long content scrolls inside the sheet while its
navigation and decision remain reachable. Do not shrink text to fit an
otherwise unchanged crowded panel.

## Continuous scene and screen composition

Menus, starter selection, deck inspection, rewards, settings and results belong
to the same afternoon at locals. Stage them over the existing room, table or
cloth treatment. Keep a recognizable part of that setting visible, using an
opaque paper sheet behind dense copy and a warm dimmer when focus requires it.
Do not replace the shop with a blank dark dashboard for routine utility flows.

The hub remains the place between matches: card counter, seller services, bye
machine and Next Round. Styling must preserve those live services, stock,
prices, consumed uses, return paths and saved state. Do not restore the legacy
route map or season calendar as part of a visual migration.

Battle follows the supplied reference's composition and camera anchors above.
Preserve the game's required **three Prep and two Plated slots per side** and
all valid drop, selection and attack targets. Empty slots use complete,
subdued rounded printed outlines. Labels, central divider, stitching and
auxiliary emblems stay quiet. Avoid giant center lettering or permanent bright
corner brackets that compete with the actual cards.

The hand contains large readable printed cards, with a clear selected card and
natural overlap. Compact paper scorecards keep rival identity, life and live
match state readable without enclosing the whole scene in HUD panels.

## Cards, characters and environment

Card frames should feel printed and sleeved: generous illustration, flat
affinity bands, readable rule paper and concise statistics. Floating field
illustrations have a **thin white silhouette outline** that follows their
animated shape and fades with the art when a card leaves play. Preserve
physical contact shadows and clear targeting cues without washing the board
in colored light.

Characters should be expressive, approachable and readable at gameplay scale.
Preserve recognizable faces, poses and local color. Use the supplied seated
brown-haired Mina for its matching encounter, while keeping other configured
opponents distinct. Character lighting should belong to the room; avoid
colored spotlights and generic neon rims.

### Opponent refinement — cozy and comfy

The latest opponent rendering reference is the **pink-haired rival's v2
expression sheet** at
`outputs/locals_opponents/v2/npc1-expressions.png` (also retained in the v3
pack). The user explicitly identified Mina's different rendering as a problem
and asked that the whole cast match this soft, cozy, chill style. This supersedes
the more detailed/painterly rendering of earlier opponent portraits. The table
reference still owns the setting, seated viewpoint and Mina's identity.

Use one shared drawing language across every opponent: clean dark-brown
contours, rounded faces, simple eyes/noses/mouths, broad hair shapes, flat local
colors with very little soft shading, and roomy clothes with sparse folds.
Preserve identity through hair, skin tone, outfit, glasses, posture and props;
do not vary the level of rendering between people. Avoid scratchy textures,
dense hair detail or realistic shading on only some members of the cast.
Use the pink-haired sheet as the sole visual style-conditioning reference for
new generations; describe other identities in text so older detailed portraits
do not pull the style away from the shared reference.

The user's follow-up rejects the first opponent batch's overly polished,
generic appearance. Keep the supplied table scene as the world reference,
but give opponents softer hand-drawn linework, simpler shading, more varied
facial proportions and comfortable, lightly rumpled everyday clothing. Avoid
glossy doll-like faces, dense shiny hair rendering and giving every person the
same card-holding posture. Texture alone does not make the art feel personal.

Each opponent should have a distinct relaxed seated posture across from the
player. Within that opponent's neutral, hurt and smile states, keep the camera,
body, scale and resting-arm baseline consistent so facial changes do not jump.
Hurt is a brief card-game reaction; smiling should feel natural and warm.
Expression sheets are source records. Final compositing assets need real alpha,
complete hair and elbow silhouettes, and no painted checkerboard background.

The environment supplies illustrated depth: honey-colored wood, cloth grain,
sleeves, deck boxes, score slips, plants, shelves and nearby players. Afternoon
light and short contact shadows should ground objects without swallowing
silhouettes or flattening the scene into uniform surfaces. Later venues may
grow in scale and spectacle while keeping the same readable paper/ink UI.

## Motion and feedback

Use short, coordinated movement that suggests cards and paper being handled.
Resting menus do not need decorative sparks, scans, pulsing edges or parallax
on every object. A subtle warm press highlight and existing sound are enough
for an ordinary action; stronger effects belong to meaningful game events.

Reduced-motion mode removes nonessential travel, parallax and effects while
preserving visible state, useful feedback and every action. Card movement,
portrait transitions and menu animations must not block input after completion
or delay straightforward navigation unnecessarily.

## Generated art and source tracking

The user authorized generative AI as replaceable working art. Register every
runtime generated bitmap in `assets/generated/manifest.json` with its exact
path and hash, retained prompt, consumers and replacement metadata. Keep the
human-readable disclosure and replacement instructions in
[`docs/generated-art-register.md`](docs/generated-art-register.md), with
attribution status in `CREDITS.md` and
[`docs/shipping-asset-provenance.md`](docs/shipping-asset-provenance.md).

Keep the editable interface, text, game rules and changing state outside
illustration bitmaps. Document any static visual approximation, such as the
registered Mina scene's painted held cards, and keep the actual counts and
interaction targets live. Reusing a registered room image in another screen
requires recording its consumer; it does not create a new generated asset.

Prompts, references, discarded experiments and superseded art are development
records, not automatic shipping assets. Preserve their provenance and export
exclusions. Use the asset provenance gate to check the registered inventory;
its success is not an assertion that all assets are non-AI or owner-attested.

Do not copy protected outside-brand symbols, proprietary card art, interfaces
or fonts from reference images. Use the supplied reference for this game's
approved composition and material direction, retain original game identities,
and use original or appropriately licensed assets for other content.
