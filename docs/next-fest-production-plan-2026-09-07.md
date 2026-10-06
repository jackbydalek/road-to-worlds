# Next Fest production plan — September 7, 2026

Planning basis: the owner selected the latest blue-pen shop room as the visual
source of truth. Target one polished four-round Locals demo with three starters,
as defined in `CONCEPT_DIRECTION.md`. The owner confirmed on September 7 that
the game is already registered for October Next Fest. Demo setup and review
status still need confirmation.
This is a proposed production schedule, not a claim that the build is ready or
an instruction to publish. No game code, uploads or store settings changed in
this planning pass.

## Calendar and participation gate

Steam's edition-specific schedule lists registration on August 31, review
submission for Press Preview on September 14, all required review submissions
on September 28, Press Preview on October 8, and the festival October 19–26
(opening at 10am PDT). The base game must remain unreleased through the event,
have a public store page and playable demo, and each title gets one Next Fest.
These are Valve's dates, not our internal estimates. Use the edition page where
it differs from the generic workback example. [Official October documentation](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/2026october).

- October registration: confirmed by the owner on September 7.
- Confirm demo App ID, base-game link, review status and public store URL.
- Only target the September 14 press submission if a representative build can
  be ready. Keep September 28 as the October submission planning deadline.
- Target October with a representative review submission by September 28;
  reassess production feasibility after the first integrated scene and Windows build.

## What exists, and what still needs work

This audit inspected code/docs; it did not run the full release suite or install
a Steam build. Existing legacy checklist claims are not current validation.

| Area | Evidence and remaining work |
| --- | --- |
| Run loop | Implemented: three starters, 15-card decks, four rounds, persistent life, 3/5/7 reshuffle pressure, reward choices, saved shop stock/services/bye, victory and loss endings. Validate interrupted runs in an exported build. |
| Battle presentation | Existing two mats, original Mina animation, event-driven held backs, pastel ribbons and original card art are the foundation. The new environment rendering still needs integration. |
| Art | Approved room is a flattened generated image under excluded `outputs/`; it is not yet a layered playable scene. |
| Teaching | Guided tutorial exists separately from New Run. Add a first-session invitation/skip flow and teach persistent health, reward choice and the bye within the run. |
| Balance | `docs/keyword-starter-audit-2026-09-04.md` flags uneven production starters and a Fresh Expert spike. Prototype starter simulations have not replaced production lists. Recheck current tuning and observe human players. |
| Distribution | `export_presets.cfg` and CI only target the itch Web build. Create and validate a Windows desktop export and Steam depot/upload setup. Other advertised platforms need their own tests. |
| Release tests | `OpponentDeckTierSmokeTest.gd` was rerun September 7 and failed: “Expert Sweet did not finish with 3 Cinnamon Snails.” Investigate generator versus expected deck; do not silence the assertion without deciding intended behavior. Full gate remains unverified. |
| Conversion | `scripts/Main.gd` has an empty `STEAM_STORE_URL`; wire the confirmed public URL into the demo ending. |
| Provenance | The provenance audit passed with eight registered generated working portraits. It certifies the registry/exclusions, not AI-free authorship. The new room is separate concept art. |

## Production order

### 1. Turn the approved room into an asset brief

Use [the approved room](../outputs/locals_screen_concepts/peach_soda_line_boil_room_v1/shop-room.png)
for contours, palette, character simplicity and room composition. Reuse its
visual language across title, shop and battle. Stop commissioning alternate
styles during this milestone.

Prepare a named layer list and an in-engine camera/blockout before final art:

- Rear room: walls, shelves, windows, bracket and outside foliage.
- Midground: counter, glass case, bye machine and background seated groups.
- Foreground: near players, binders, plants, table edges and chairs.
- Interactables: separate case contents, prices, machine states and interaction
  regions. Singles must be the actual offered game cards inside the case.
- Characters: prioritize the demo's selected rival roster, with seated neutral,
  smile and hurt poses plus stable arm/hand anchors. Keep supplied Mina intact.
- Battle: a matching background from the actual across-table camera, with room
  for both mats and readable cards. Do not force the wide hub image behind it.

Artist deliverables: layered source file, named transparent exports, common
canvas/registration, and replacement mapping. Proposed line-boil scope is two
or three alternating drawings on selected characters/foliage only; preserve
stable UI text, numbers and hit areas, and honor Reduced Motion. Static art is
acceptable if animation would compromise the submission.

Keep the existing card illustrations and exact affiliation colors. Reuse the
native ribbon and sketch-control components; no need to draw every button.
Audit actual reachable missing card art before budgeting work—the old 61/87
count is not a verified current inventory.

### 2. Prove one finished playable route

Build title → starter choice → hub → shop → battle → reward → hub using the
final drawing language. Review captures at 1280×720, 1440×900 and 1920×1080,
including long card text, hover outlines, disabled controls and keyboard focus.
Use this as the visual acceptance example for remaining screens.

In parallel, produce the first Windows release build immediately. Discover
native export, import and launch problems before spending the entire schedule
on art. Validate installation and launch through Steam once the demo app is
configured.

### 3. Make a first run understandable and worth replaying

Use the existing guided tutorial for a short, skippable introduction. Teach Prep,
Plated, recipes and End Turn through actions. Explain persistent life before a
player spends the bye; make reward skipping/taking and locked-deck growth clear.
Balance the actual three starter lists and four-round rival pool. Use current
hub simulations as diagnostics, then watch 5–10 unfamiliar players play without
coaching. Record confusion, run completion, run time and whether they want a
second run. These are internal playtest targets, not Steam requirements.

Add restrained shop ambience, card handling sounds and clear draw/attack/damage
feedback. A complete, readable first session takes priority over more opponents,
new cards, Regionals or extra cosmetic systems.

### 4. Finish the assets that will actually ship

Maintain `docs/generated-art-register.md` and per-file provenance. Choose the
replacement scope now: room, featured characters and capsule art have the most
visibility. Supplied art must retain its own recorded origin. Renaming or cutting
up a generated image does not make it non-generated. Any generated room layers
added to runtime need their own manifest paths, hashes and consumers.

If generated content remains in the shipping build, complete Steam's AI content
survey accurately. Its guidance covers player-consumed generated content such
as artwork, sound and narrative. [Steam Content Survey](https://partner.steamgames.com/doc/gettingstarted/contentsurvey).

### 5. Package the same experience for the store

Use See You at Locals, the name selected by the owner on September 8. Lead
with the cozy roguelike card-shop run and reaching Worlds. Produce a legible
capsule family, a short gameplay-led trailer and at least five actual gameplay
screenshots from the integrated build. Steam's screenshot section requires
gameplay images rather than concept art; capture at 1920×1080 or above.
[Steam graphical asset requirements](https://partner.steamgames.com/doc/store/assets/standard).

Refresh the description, tags, controls, supported platforms and demo ending
to match the build. Prepare a concise feedback form and wishlist action. Upload,
publishing and outreach are separate actions requiring the owner's authorization;
this plan does not send messages or change the store.

## Proposed internal milestones

The [September 7–13 handoff](next-fest-week-one-2026-09-07.md) assigns the first
week's owner inputs, implementation deliverables and acceptance criteria.

| Target | Deliverable |
| --- | --- |
| September 7–13 | Registration confirmed; verify demo setup; freeze art brief and demo scope; playable hub blockout; first Windows build; investigate failing release test. |
| September 14–20 | Finish the representative title/shop/battle route; first-session teaching; first external playtest round; decide which AI assets are replaced before submission. |
| September 21–27 | Resolve balance/readability issues; finish submission art; capture real screenshots/trailer; validate the complete four-round exported demo and prepare review submission. |
| September 28 | Submit all required items for Steam review under the October schedule. |
| September 29–October 11 | Resolve review feedback, run a second outside playtest, test updated builds, and complete final polish. October 8 Press Preview only if opted in and the public demo is ready. |
| October 12–18 | Freeze features; verify clean Steam installation, save compatibility, links, audio and display modes; retain a known-good build and hotfix procedure. |
| October 19–26 | Demo live before opening; monitor player feedback and technical reports; ship validated fixes and record post-Fest priorities. |

This is a constrained proposal, not a guarantee. Review feasibility after the
first integrated scene and Windows build. Steam permits demo updates after build
approval, but the developer must test those updates. [Steam demo preparation](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest#5).

## Exit criteria before public release

- All three starters complete a four-round run; loss and victory lead to clear
  endings; no known crash, softlock or duplicate reward/purchase path.
- Save/resume tested at the hub, mid-match, partially collected rewards, after
  purchases and spent bye/services, and after victory/loss.
- First-time players can start, learn and finish without developer coaching.
- Final art and actual store footage agree; original card information and
  affiliation colors remain readable.
- Appropriate automated gameplay/UI/save tests and provenance checks pass on
  the release candidate, with desktop smoke testing added to the Web gate.
- Steam installation/launch, window/fullscreen changes, audio, text scaling,
  Reduced Motion and advertised input/platform support are manually verified.
- Review approvals, public demo availability, wishlist/feedback links and a
  known-good rollback build are confirmed.

Implementation references: `Main.gd`, `GamePalette.gd`, `PeachSodaCast.gd`,
`HubShopRefreshSmokeTest.gd`, `GuidedTutorialSmokeTest.gd`,
`HubBalanceSimulation.gd`, `scripts/release/check_demo.sh`, and
`docs/shipping-asset-provenance.md`. The old demo release checklist still contains
browser/legacy-season assumptions and needs updating when desktop packaging is
implemented.
