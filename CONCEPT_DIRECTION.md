# TOP CUT: Locals to Worlds — Target Game Direction

> **Status:** This document describes the intended redesign and is the source of
> truth for new campaign, progression, overworld, reward, and marketing work.
> The repository still contains the released demo's older shop-and-tournament
> season loop. Do not assume every target rule below is implemented yet.

## One-sentence pitch

**TOP CUT: Locals to Worlds is a cozy roguelike deckbuilder about surviving a
card-game season from neighborhood locals to the world championship.**

Short marketing line: **Start at a folding table. Reach Worlds.**

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
and stakes escalate. For the October 2026 Next Fest demo, the priority is one
polished four-round Locals floor. Regionals may appear as an end-of-demo teaser.

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
- **Bye machine** — once per floor, either heal or upgrade one eligible card.

Enemies are other card-game players, not literal monsters. The bye machine is
the floor's only guaranteed recovery/upgrade stop. After either option is used,
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

Deck handling reinforces those identities on the Living Table. Sweet and
Hearty players always keep their draw pile squared into a neat stack. Spicy,
Fresh, and Funky players allow repeated draws to loosen the pile through small,
controlled card offsets and rotations. This is a personality detail, not dirt,
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

Lead with the progression fantasy and world, then demonstrate the card game:

> A cozy roguelike deckbuilder where you climb from neighborhood card-shop
> locals to a championship in the stars.

Marketing images and trailers should quickly show:

- a clean, centered title presentation where real game cards spiral into the
  supplied TOP CUT logo and Continue/New Game sit directly beneath it,
  immediately establishing the deckbuilder identity without an intermediate
  gateway screen;

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
