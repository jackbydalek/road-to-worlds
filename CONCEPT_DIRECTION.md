# See You at Locals — Target Game Direction

> **Status:** This document describes the intended redesign and is the source of
> truth for new campaign, progression, overworld, reward, and marketing work.
> The repository still contains the released demo's older shop-and-tournament
> season loop. Do not assume every target rule below is implemented yet.

## Food Prototype — September 22, 2026

An isolated **Food Prototype** entry on the title screen tests an alternative
to choosing an affinity starter. The regular game retains its existing rules.

- Start with 15 neutral cards: six 2/2 Basic Bites, four 1/3 Sturdy Bites,
  three 4/4 Simple Serves (one Ingredient each), Wooden Spoon, and Tongs.
- Choose one of three seeded opening cards, adding it to the starting deck.
- Normal Meal recipes accept any Ingredients for both seats. Preserve recipe
  counts, readiness, Meal limits, and existing card abilities and affinities.
- Shops and rewards use all five affinities from the week-one pool. The weak
  starter-only cards never enter acquisition pools. Special Serve stays off.
- Play one four-round Locals tournament, with existing persistent health,
  rewards, shop economy, and the once-per-floor bye. Finish after its champion;
  there is no second week or deckbox transition in this prototype.
- Prototype revision 2 softens round three to 16 rival life and four deck
  substitutions, and round four to 22 life and five substitutions. Keep Hard
  and Expert combat AI respectively; rounds one and two retain their curve.
- Reward packs reserve two slots for an enabler and payoff from a mechanic
  supported by the current deck: pressure, tokens, discard, durability or
  serving. Remaining slots draw from all five affinities. Preserve the 3/5/8
  offer sizes and the freedom to take any or all cards. Affinity tutors need
  a matching Ingredient in the deck; omit Spice removal in this spice-free run.
- Prototype autosaves and local playtest records are separate from the normal
  run. The opening offer, claimed cards, battle checkpoint, and run ruleset
  persist across reloads. New runs save encounter settings; called rivals save
  their actual deck so resuming cannot change their tuning.

This is an experiment, not a replacement for the main game's direction yet.
The key questions are whether acquisitions become immediately useful, whether
runs develop different strategies, and whether generic recipes create too many
automatic picks. See `docs/food-prototype.md` for implementation and testing.

## Two-week demo revision — September 10, 2026

The owner has expanded the demo to **two weekly Locals tournaments**, each with
four rounds. “Second day” means the second weekly shop visit/tournament. This
supersedes earlier one-floor demo limits below; the compact shop hub remains.

- Week 1 ends after its champion's normal card/cash reward. Choose **one of
  three seeded, saved deckbox offers** from the five-box pool below.
- A deckbox is a run prize, separate from starter packaging and card borders.
  Tip Jar pays **$1 after every match, win or loss**. Big Lunch adds **5 maximum
  life and heals 5 when chosen**. Light Pack removes **3 chosen card copies
  once**. Chef's Edge upgrades **2 chosen card copies once**. Padded Picnic
  reduces **each reshuffle's damage by 2**, to a minimum of zero.
- Resolve removal/upgrade choices before the week-two introduction, confirming
  each copy. Save the remaining choices after every confirmation. Keep at least
  one card in the deck; if no eligible copies remain, finish the prize. These
  are one-time pickup rewards, not recurring services or future-card bonuses.
- Equipped deckboxes keep their saved effect snapshots, including legacy boxes.
  Normalize invalid pending offers into three valid saved choices without
  rerolling an already valid offer.
- Continue into week 2 with the same deck, upgrades and money. At each new
  week, **Black and Blue borders restore full life** to the current maximum;
  **Yellow, Silver and Gold heal 20 life**, capped at that maximum. Include
  maximum-life bonuses from deckboxes. Apply recovery once when advancing the
  week, after resolving the deckbox prize; revisits and reloads do not heal
  again. Life still persists between rounds. The weekly bye and paid shop
  upgrade reset; per-round removal and shop stock reset normally.
- Week 2 introduces **Second Helpings**, a free five-card pack guaranteeing two
  Special Serve Meals and one Spice, within the starter ecosystem. The new
  Meals and Spices join rewards and shop stock in week 2. Week-one rival decks,
  shop offers and rewards exclude them.
- **Special Serve** is an alternate summon condition on a Meal. The normal
  recipe remains available. Special Serves have **no per-turn count limit**
  and neither consume nor reset the normal one-Meal-per-turn allowance. Each
  summon must pay its printed condition and fit an available table slot.
- Current draft conditions sacrifice eligible Ingredients, including spiced,
  damaged, token, keyword or stat requirements. They can use newly played
  Ingredients unless `require_ready` is set. Normal recipes still require
  recipe-ready Ingredients. Both summon methods resolve the Meal's `on_play`.
- Winning the second four-round tournament completes the demo. Losing ends the
  run. Week, deckbox, offers, partial pack claims and match state are saved.

The eight new card names, stats and effects remain **editable prototypes**.
The five deckbox effects above reflect the September 11 owner revision.
Configuration and card data live in
`data/content/demo_progression.json` and `data/content/second_helpings.json`.
See `docs/two-week-demo-design.md` for the concepts and editing contract.

## One-sentence pitch

**See You at Locals is a cozy roguelike deckbuilder about an afternoon at your
neighborhood card shop—and building a deck that can reach Worlds.**

Short marketing line: **Make yourself at home. Make your way to Worlds.**

The title promises a welcoming social setting: familiar rivals, casual table
chatter, paper scorecards, fabric playmats, and time to enjoy the shop between
rounds. Competitive matches and the run structure below remain intact.

The food-themed cards remain an important part of the game's personality and
visual identity, but “food card game” is not the whole pitch. The emotional hook
is the journey from a welcoming local scene to an increasingly magical world
championship.

## High-level pivot

Keep and reuse the existing tactical Kitchen Match card game, card catalog,
affinities, card art, and 3D Living Table. Replace the outer campaign loop with
a run-based tournament climb inspired by games such as *Slay the Spire*.

Between matches, the player returns to a local card-store tournament hub. The
hub is a compact scene rather than a traversable overworld: visit the card
counter, use the floor's one bye-round machine, or report to the next table.
The deck is locked, purchases and rewards enter it directly, and life persists
between rounds.

This is a fresh gameplay loop built around the existing card mechanics—not a
new card game.

## Run fantasy and world progression

A complete run climbs through four tournament floors:

1. **Locals** — a neighborhood card store and small community bracket.
2. **Regionals** — a larger event hall with more formal tournament production.
3. **Nationals** — a high-pressure arena-scale competition.
4. **Worlds** — the aspirational championship stage.

Each floor keeps the same readable hub grammar while its venue, crowd, signage,
and stakes escalate. For the October 2026 Next Fest demo, play two four-round weekly Locals
tournaments with a deckbox and expansion unlock between them. Regionals remains
an end-of-demo teaser.

## Core run loop

1. Choose the **Spicy**, **Hearty**, or **Sweet** starter deck.
2. Enter Starter City with persistent run health and a deliberately weak,
   compact deck.
3. Enter the current tournament hub between matches.
4. Visit the shop, spend the floor's one bye on healing or a card upgrade, or
   choose **Next Round**.
5. Resolve the called match and open its reward.
6. Return to the hub with the evolved locked deck and remaining life.
7. Defeat the floor's top-cut rival and champion.
8. Advance toward the next tournament floor.
9. Losing all life ends the run.

The hub's main strategic decision is when and how to spend the single bye:
short-term survival through healing versus long-term power through an upgrade.

## Core node types

The tournament climb uses these primary stops:

- **Enemy** — a regular rival and normal card-game match.
- **Miniboss** — a stronger named rival with an improved reward.
- **Floor boss** — the city champion and mandatory act endpoint.
- **Shop kiosk** — buy cards or packs; purchases enter the locked run deck.
  Refresh the four displayed cards after every match win. Stock persists between
  visits and reloads until the next win, including when it is sold out.
  **Reroll** replaces the four cards for **$5**, then **$6**, **$7**, and so on
  within that round. Reset the next reroll price to $5 after finishing a battle.
  Paid rerolls refill partial or sold-out stock and keep the starter ecosystem
  and current week's card unlocks. Save the new stock, payment and increasing
  price together; revisits and reloads do not reset the price. Rerolling does
  not restore paid removal, upgrade or bye uses and does not change the deck.
  The shopkeeper can also remove one card copy for **$3, once per round**,
  keeping at least one card. This paid service does not consume the bye.
  Removal refreshes when the next round begins; revisits and reloads preserve its use.
  Clicking the seller zooms into her and reveals **Upgrade Card ($5)** and
  **Remove Card ($3)** beside her. The paid upgrade is once per floor and
  does not consume the bye; the bye machine retains its separate free upgrade.
- **Bye machine** — once per floor, either heal **5 HP** (capped at maximum life)
  or upgrade one eligible card. Selecting a snack only previews it; the button
  beneath it confirms the action. Cancelling an upgrade preserves the shared use.

The September 7 shop-concept revision groups the clerk, glass case and an actual
retail-style vending machine in one overview. Clicking a target zooms to its
location before revealing its actions; Back/Escape returns to the overview.
This is the target presentation, not a change to prices, service limits or the
shared bye rule. The proposed three-target focus flow is illustrated in
`outputs/locals_shop_focus_v2/`; production integration is still separate.

Enemies are other card-game players, not literal monsters. The bye machine is
the floor's free recovery/upgrade stop. After either option is used,
it visibly becomes **OUT OF ORDER** for the remainder of that floor.

## Deck construction and rewards

The current target rules are:

- Start with **15 cards**, intentionally below the long-term power curve.
- Legal run decks contain **at least 1 card with no maximum size**.
- There is **no per-card copy limit**. If the player acquires another copy, it may be added to the deck.
- Opening hand is **5 cards**.
- At the start of later turns, draw one card, then refill to **3 cards** if the
  hand is below three. Exact draw tuning remains subject to playtesting.
- Regular enemy reward: reveal **3**; the player may take any or all of them.
- Miniboss reward: reveal **5** with improved rarity; the player may take any or all of them.
- Floor-boss reward: reveal **8** with rare/high-impact options; the player may take any or all of them.
- Reward offers, shop singles, and opened packs are restricted to the run's
  starter ecosystem (plus neutral cards). **Spicy** runs can discover Spicy,
  Fresh, and Funky cards; **Sweet** runs can discover Sweet, Hearty, and Funky;
  **Hearty** runs can discover Hearty, Sweet, and Fresh. Cards carrying an
  affinity outside that set must never be offered to the player, including on
  multi-affinity cards. Rivals are not restricted by the player's ecosystem
  and may use any affinity normally.

Card rewards should feel like opening a pack. The reveal animation and the
decision about what enters the deck are important reward moments.

The numbers above are balance targets, not immutable constants. Preserve the
structure—small starter, controlled deck growth, choice-based rewards—even if
testing changes the exact counts.

## Persistent health and reshuffle pressure

Player health persists between encounters. Matches are not isolated fresh-life
games.

Current balance target:

- Player starts a run at approximately **40 life**.
- Regular rivals are tuned around **10–14 life**.
- Minibosses are tuned around **16–20 life**.
- Floor bosses are tuned around **24–30 life**.
- Shop/event healing is approximately **8–10 life**.
- New weekly tournaments fully restore life on **Black and Blue** borders, or
  heal **20 life** on **Yellow, Silver and Gold**, capped at current maximum.
- Advancing to a new city may restore approximately **10 life**.

Small decks are powerful because they repeat their best cards. Reshuffling is
therefore intended to create escalating run pressure. The preferred prototype
is **3 damage on the first reshuffle, 5 on the second, and 7 on later
reshuffles**, resetting at the start of each match. This is preferable to an
unexplained flat five damage every time, but it must be playtested.

Do not conflate this target reshuffle rule with the current combat service's
ordinary empty-deck behavior; the target system still needs explicit campaign
integration and UX explaining the damage before it occurs.

## Tournament-hub direction

The intended between-round presentation is a bright, front-on illustrated card
store with restrained parallax. It should read as a designed scene, not a map:

- Rear layer: windows, wall graphics, bracket board, posters, venue signage.
- Mid layer: the interactive card-shop kiosk and one-use bye machine.
- Front layer: nearby players, match table, cards, chairs, and foreground props.
- Fixed interface layer: round, persistent life, funds, locked-deck status, and
  the dominant **Next Round** action.

The first implementation uses labelled basic shapes so scale, hierarchy, and
interaction can be validated before final environment illustration. Pointer
movement may shift the three scene layers slightly; reduced-motion mode removes
that motion. Do not turn the hub into an isometric navigation game.

Save the current floor and round, remaining life, deck, currency, rewards,
one-use bye state, and persistent shop inventory. Reloading must restore the
same hub state and must never refresh an already-used bye machine.

## Legacy Starter City route-map prototype

`scenes/StarterCityOverworld.tscn` and its route-graph contract remain in the
repository as an evaluated prototype. They are not the active campaign
presentation after the tournament-hub pivot.

The production scene currently provides:

- A fixed authored branching route graph matching the agreed three-street town sketch
- A large grassy lower town district feeding into a paved upper-right city district
- Two route branches that climb through northbound connectors and reconverge at the locals championship
- Two optional miniboss encounters distributed across different lanes
- Enemy, shop, event, miniboss, and final-boss node types
- One production-default authored town layout; seven procedural variants retained but disabled for later integration
- Free player movement constrained to the currently available forward streets
- Physical rival NPCs using seeded affinities and personalities, plus distinct event-gate squares
- NPC sightline, overhead reaction mark, stationary pose, and portrait/dialogue handoff
- Walk-in card-store placeholders for shop route nodes
- Labeled collision-enabled block placeholders for unfinished building exteriors
- A fitted modular street network with hidden route-graph governance
- A close follow camera, optional town overview, and an illustrated billboard player
- Idle, walk, and victory poses
- Saved-route restoration through the existing campaign state and encounter flow

Relevant overworld scripts:

- `scripts/overworld/OverworldRouteGraph.gd`
- `scripts/overworld/OverworldPlayer.gd`

Reuse its battle, reward, shop, and save contracts where useful. Do not silently
restore the traversable route map as the active campaign shell.

## Starter identities

- **Spicy** — pressure, direct damage, aggressive Plated units, fast tempo.
- **Hearty** — durable units, healing, protection, resilient Meals.
- **Sweet** — draw, disruption, Prep support, clever sequencing/combo play.

Deck handling adds personality on the Living Table. Every human player's draw
pile loosens through repeated draws, regardless of starter affinity. Only Sweet
and Hearty rivals keep a squared, tidy draw pile; other rivals also use small,
controlled offsets and rotations. This is a personality detail, not dirt,
damage, or a gameplay modifier; card identities and counts must stay readable.

Their overworld characters should communicate those personalities while still
feeling like ordinary young card-game competitors. They are players, not chefs
wearing literal food costumes.

## Visual direction

`ART_DIRECTION.md` remains authoritative for visual work, and
`scripts/ui/GamePalette.gd` remains the code palette source of truth.

The current hub environment emphasizes:

- Bright illustrated card-game adventure identity
- Cool-white walls and graphite fixtures warmed by wood tables and daylight
- Clear silhouettes and broad labelled interaction zones
- Restrained semantic cyan, green, yellow, red, and violet accents
- Warm brown or navy outlines depending on asset scale
- Simple baked lighting, readable silhouettes, and minimal shading
- Contemporary small-city architecture that becomes more magical by act

Do not make the full game dark, gothic, neon, or generically medieval. Do not
let affinity colors cover entire environments.

## Marketing position

Lead with the welcoming neighborhood card-shop fantasy, then demonstrate the
deckbuilding and competitive climb:

> A cozy roguelike deckbuilder. Pull up a chair at your neighborhood card shop.
> Meet your rivals. Build a deck that can reach Worlds.

Marketing images and trailers should quickly show:

- a clean, centered See You at Locals wordmark on a paper open-play sheet,
  with real game cards fanned on the surrounding mat and Continue/New Game
  directly beneath the title;

1. Choosing how to prepare between rounds in a lively tournament venue
2. Battling an expressive rival with the existing card game
3. Opening a reward pack and choosing a card
4. Visiting a shop or event
5. Facing the city champion
6. Seeing the next magical city waiting ahead

Do not market the redesign as an apology for the previous demo. Present it as a
clearer realization of the game's strongest fantasy.

## Legacy versus target behavior

The following files primarily document or implement the released demo's old
loop and should not override this target-direction document for new campaign
work:

- `README.md` sections describing the current Season Loop
- `docs/season-loop.md`
- Existing card-store hub and three-round tournament flow

Those systems remain useful implementation references and may continue to run
until the pivot is integrated. Reuse working card combat, collection, shop,
pack-opening, deckbuilder, save, and content systems where practical; replace
only the outer gameplay loop deliberately.

## Still provisional

Do not silently treat these as permanently locked:

- Exact health and healing values
- Exact reshuffle-damage curve
- Turn-refill threshold
- Exact number of columns/nodes per city
- Currency prices and shop inventory
- Whether city transitions heal automatically
- Exact ratio of affinity-weighted to off-affinity rewards
- Which authored town-layout profiles and decoration variants ship in later acts

When changing one of these, preserve the intent in this document and update the
document with the newly agreed decision.
