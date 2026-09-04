# TOP CUT: Locals to Worlds — Target Game Direction

> **Status:** This document describes the intended redesign and is the source of
> truth for new campaign, progression, overworld, reward, and marketing work.
> The repository still contains the released demo's older shop-and-tournament
> season loop. Do not assume every target rule below is implemented yet.

## One-sentence pitch

**TOP CUT: Locals to Worlds is a cozy roguelike deckbuilder about starting at tiny
neighborhood card-game locals and choosing a path toward a championship in the
stars.**

Short marketing line: **Start at a folding table. Reach Worlds.**

The food-themed cards remain an important part of the game's personality and
visual identity, but “food card game” is not the whole pitch. The emotional hook
is the journey from a welcoming local scene to an increasingly magical world
championship.

## High-level pivot

Keep and reuse the existing tactical Kitchen Match card game, card catalog,
affinities, card art, and 3D Living Table. Replace the outer campaign loop with
a run-based, branching progression structure inspired by games such as *Slay
the Spire*.

The player should no longer return to the same card shop after every round.
Instead, they move through a city along a visible branching route, choose the
next stop, resolve that encounter, improve the deck, and continue toward the
city champion.

This is a fresh gameplay loop built around the existing card mechanics—not a
new card game.

## Run fantasy and world progression

A complete run climbs through three acts/cities:

1. **Starter City** — grounded small-town locals: game shops, flower shops,
   townhouses, parks, markets, and a community tournament venue.
2. **Cloud City** — a more magical city above the clouds, still cozy and
   inhabited but less bound by real-world architecture.
3. **Celestial City** — the aspirational championship destination in the stars.

Each city is an act with branching encounters, a miniboss/local champion, and
a floor boss. The environmental progression should visibly transform the
ordinary dream of attending locals into something magical and enormous.

For the October 2026 Next Fest demo, the priority is one polished Starter City
run. Cloud City may appear as an end-of-demo teaser; it does not need to be a
complete playable act for the festival build.

## Core run loop

1. Choose the **Spicy**, **Hearty**, or **Sweet** starter deck.
2. Enter Starter City with persistent run health and a deliberately weak,
   compact deck.
3. View the branching route and choose a connected destination.
4. Resolve a battle, shop, or event.
5. Gain cards, healing, currency, removal, or another run upgrade.
6. Continue along the chosen route; do not freely return to prior stops.
7. Defeat the miniboss and city boss.
8. Advance toward the next city, carrying the evolved deck and remaining life.
9. Losing all life ends the run.

The map must create meaningful route decisions: safety versus rewards, shops
versus fights, and short-term survival versus long-term deck strength.

## Core node types

The board uses five primary node types:

- **Enemy** — a regular rival and normal card-game match.
- **Miniboss** — a stronger named rival with an improved reward.
- **Floor boss** — the city champion and mandatory act endpoint.
- **Shop** — buy cards/packs, heal, remove a weak card, or use other services.
- **Event** — a short authored choice, character moment, risk, or reward.

Enemies are primarily other card-game players, not literal monsters. Rest or
healing can be offered through shops and events; a separate rest node is not
required for the Starter City vertical slice.

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

## Overworld and procedural-map direction

The intended presentation is a cozy **2.5D illustrated diorama**:

- Simple 3D ground, roads, buildings, stairs, and bridges.
- Illustrated textures and baked lighting rather than a dark realistic 3D city.
- A fixed camera angle with pan/limited zoom; no need for free camera rotation.
- A 2D illustrated character sprite/billboard moving through the 3D scene.
- Board-node icons and connections layered clearly over the environment.

Starter City presents that route structure as an explorable town rather than a
click-to-travel board. The player walks freely along the currently available
streets with a close follow camera. Rival and event nodes are embodied by town
NPCs: entering an active NPC's sightline produces a reaction beat, the NPC
shows an exclamation mark above their head while remaining in place, and the
opening portrait/dialogue screen begins. Shop nodes are entered through a
physical storefront doorway. The starting local card shop is also a persistent,
revisitable storefront; entering or leaving it does not consume a route choice.
The player's movement center remains inside the visible path footprint; grass,
city paving outside the streets, and decorative parcels are not walkable. The
route graph remains authoritative underneath the town, restricting exploration
to the current forward choices and committing the first branch the player enters.

The current production priority is one authored default town map based on the
agreed three-street route sketch: a broad grassy small-town district feeds into
a denser paved city district; three long eastbound streets are joined by
northbound connectors; event gates mark major transitions; rivals watch the
streets from fixed sightline positions; and the heal/upgrade center, card shop,
and locals championship occupy fixed service landmarks. Tune and validate this
map before enabling procedural variants.

Keep constrained procedural generation as a later extension, not active
default behavior:

1. Generate or choose a valid branching route graph from a saved seed.
2. Fit it to authored street or district modules with matching connection
   sockets.
3. Reserve fixed landmark locations and footprints.
4. Place ordinary buildings only into compatible roadside/building sockets.
5. Scatter flowers, lamps, benches, trees, and other props inside authored
   decoration zones.
6. Validate that all offered nodes are reachable and the boss can always be
   reached.

Starter City should feel handcrafted even when its encounter contents change.
Seven authored town-layout profiles may remain available as deferred design
material, but saved-run seeds must not select between them until the fixed
default has been playtested. Seeds may still vary rival affinities,
personalities, and other encounter content without changing the street plan.

Keep these landmarks fixed or tightly constrained:

- Starting local card shop
- Miniboss/tournament venue
- Floor-boss championship venue
- Exit/bridge toward Cloud City

Save the generation seed, generated graph, current node, visited nodes, player
life, deck, currency, and rewards. Reloading a save must restore the same run,
not generate a new city.

## Current Starter City overworld

`scenes/StarterCityOverworld.tscn` is the production route-map scene used by
the run campaign shell. It promotes the constrained procedural city work that
was developed in `scenes/StarterCityProceduralPrototype.tscn`; the older
`scenes/OverworldStageTest.tscn` remains its low-level inherited base.

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

Do not build a second unrelated map framework without first evaluating this
production scene and its route-graph contract.
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

The current environment/overworld exploration emphasizes:

- Bright illustrated card-game adventure identity
- Cream walls and paving
- Dusty purplish-grey/lavender roofs, roads, and masonry
- Restrained sage greenery and flower boxes
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

1. Choosing a path through a cute city
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
