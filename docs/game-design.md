# Road to Worlds Game Design

## High Concept

Road to Worlds is a roguelike deckbuilding game about becoming a competitive trading card game player over one escalating season. The player starts with a small collection and a fragile starter deck, then improves through card shop visits, booster packs, trades, singles purchases, deck tuning, scouting, and tournament performance.

The fantasy is not "being a wizard in a card battle." The fantasy is being the player: reading the metagame, stretching a budget, opening the exact rare that changes a run, sideboarding for a known rival, pivoting when the field changes, and trying to spike Worlds before the season ends.

## Design Pillars

1. **Packs should feel dangerous and thrilling**
   Booster packs create hope, texture, pivots, and heartbreak. They should produce memorable moments even when the optimal line is buying singles.

2. **Deckbuilding is the main combat system**
   The player's most important decisions happen before the match: archetype choice, curve, consistency, card ratios, sideboard slots, tech cards, and when to abandon a plan.

3. **The metagame is alive**
   Opponents do not merely scale upward. Their deck choices, tech cards, and popularity shift in response to simulated tournament results, new sets, and the player's visible success.

4. **Every run tells a season story**
   A run should have rivals, lucky pulls, bad pairings, sudden pivots, shop finds, heartbreaking bubbles, and boss matches that feel earned.

5. **Scope favors strong abstraction over full TCG simulation**
   The MVP should avoid implementing a complete real-world TCG rules engine. It should use a compact duel model where card roles, archetype synergies, curve, and matchup tech create legible outcomes.

## Core Gameplay Loop

### Macro Loop

1. **Start a run**
   Pick a starter archetype, receive a starter deck, starter collection, small budget, and initial local metagame.

2. **Visit the card shop**
   Buy booster packs, inspect singles, trade with NPCs, sell duplicates, scout local players, tune deck, and choose whether to conserve money.

3. **Enter tournament**
   Play a Swiss-style event appropriate to the season tier. Matches use the player's current deck, sideboard, and known matchup prep.

4. **Resolve record**
   Winning records grant prizes, money, ranking points, invitations, better shop access, and story/rival progress. Missing required records ends the run.

5. **Update the world**
   The metagame shifts based on tournament results, counter-strategies, set availability, and player influence.

6. **Advance the season**
   The next shop visit and tournament tier unlock. The player either climbs toward Worlds or starts a new run.

### Moment-to-Moment Loop

At the shop:

1. Check current metagame report.
2. Review upcoming tournament requirements.
3. Inspect deck warnings and matchup projections.
4. Spend limited resources on packs, singles, trades, or entry fees.
5. Modify main deck and sideboard.
6. Lock decklist and enter the event.

During a tournament:

1. Receive opponent pairing and deck archetype.
2. Choose match plan or sideboard strategy if the opponent is known.
3. Play or simulate best-of-three games using the duel engine.
4. Earn record, prizes, and reputation.
5. See metagame and rival consequences.

## Card Collection And Deckbuilding

### Collection Philosophy

The collection should feel like a real binder, not a generic pool of upgrades. The player owns copies of cards, has emotional attachment to lucky pulls, and faces constraints from scarcity.

Recommended deck rule for MVP:

- Main deck: 30 cards
- Sideboard: 6 cards
- Max copies: 3 per card
- Minimum resource cards: optional, depending on duel model
- Tournament deck lock: deck cannot change mid-event except sideboarding

Later full version:

- Main deck: 40 cards
- Sideboard: 10 cards
- Format legality by set or season
- Foils, promos, alt arts, and buylist values

### Card Roles

Each card should primarily belong to one role. The role drives deck heuristics, AI deck construction, and match simulation.

- **Threat**: Applies pressure and converts tempo into wins.
- **Answer**: Removes or neutralizes opposing threats.
- **Engine**: Generates repeatable advantage or consistency.
- **Finisher**: Ends the game after setup or stabilization.
- **Combo Piece**: Contributes to a specific payoff chain.
- **Tutor/Filter**: Finds needed cards and improves consistency.
- **Protection**: Preserves threats, combo pieces, or engines.
- **Tech**: Strong against specific archetypes or tags.
- **Resource**: Enables playing cards if the duel model uses resources.

### Card Attributes

Each card definition should include:

- `id`
- `displayName`
- `setId`
- `rarity`
- `archetypeTags`
- `mechanicTags`
- `role`
- `cost`
- `power`
- `speed`
- `consistency`
- `interaction`
- `resilience`
- `cardAdvantage`
- `matchupTags`
- `deckLimit`
- `marketValue`
- `flavorText`

### Deck Quality Metrics

The deckbuilder should compute readable diagnostics. These help players learn and give the simulation strong inputs.

- **Archetype density**: How many cards support the main strategy.
- **Curve**: Whether the deck can act early, midgame, and late.
- **Consistency**: Draw smoothing, redundancy, tutor access, and ratio health.
- **Pressure**: Ability to close games quickly.
- **Interaction**: Ability to stop opposing threats and combos.
- **Resilience**: Ability to recover from disruption or removal.
- **Inevitability**: Long-game advantage.
- **Tech coverage**: Sideboard and main deck strength against current meta.
- **Clunk risk**: Too many expensive, narrow, or unsupported cards.

### Meaningful Deckbuilding Decisions

Good decisions should not always be "add the highest rarity card."

Examples:

- Add a powerful mythic that weakens consistency.
- Buy two commons that complete an engine instead of one flashy rare.
- Main-deck a narrow tech card because the meta is hostile.
- Sell a valuable off-archetype rare to buy sideboard answers.
- Pivot from Aggro to Tempo after opening a rare engine.
- Stay with a weaker deck because the metagame has moved away from its predators.

## Tournament Progression

### Season Tiers

| Tier | Event | Rounds | Required Record | Primary Pressure |
| --- | --- | ---: | --- | --- |
| 1 | Weekly Locals | 3 | 2-1 | Learn the field, survive budget constraints |
| 2 | Monthly Regionals | 5 | 4-1 | Sideboarding and consistency matter |
| 3 | State Championships | 6 | 5-1 | Strong archetype identity required |
| 4 | Nationals | 8 | 6-2 | Deep metagame adaptation and boss decks |
| 5 | Worlds | 10 plus finals | 8-2, then top cut | Optimized deck, matchup mastery, final bosses |

Failing the required record ends the run. The game should be explicit about this before entry.

### Tournament Structure

For MVP, use a compressed Swiss model:

1. Generate field composition from current metagame.
2. Pair player against opponents appropriate to record bracket.
3. Add one scripted rival or boss pairing for key events.
4. Resolve each match as best-of-three.
5. Award prizes based on final record.

For full version, add:

- Opponent standings
- Intentional draws
- Bubble rounds
- Top cut brackets
- Known grinders who travel between events
- Reputation and scouting consequences

### Boss Encounters

Bosses should be elite competitive players, not monsters. Each boss represents a competitive test.

- **Local Rival**: Knows the player's starter archetype and runs cheap targeted hate.
- **Regional Grinder**: Plays the most popular deck with near-perfect ratios.
- **Rogue Specialist**: Uses an off-meta archetype with unusual matchup spread.
- **State Champion**: Brings a tuned sideboard and punishes linear plans.
- **Testing Team Captain**: Uses the deck the metagame will adopt next.
- **National Champion**: Adapts between games and has premium rares.
- **Worlds Finalist**: Has a high-skill deck with strong matchup knowledge.
- **World Champion**: Plays either the best deck or a precise counter to the player's public history.

Bosses can break normal AI deck construction rules slightly, but should remain readable and beatable.

## Dynamic Metagame

### Metagame State

The metagame is a distribution of archetypes, not a static list of enemies. Each archetype has:

- Popularity
- Average deck quality
- Accessibility
- Skill floor
- Skill ceiling
- Recent results
- Predator archetypes
- Prey archetypes
- Tech adoption
- Hype
- Player visibility impact

### Metagame Update Model

After each event:

1. Simulate archetype results using matchup matrix and field share.
2. Increase popularity for high-performing and accessible decks.
3. Decrease popularity for underperforming decks.
4. Increase counter-deck popularity when one deck becomes dominant.
5. Add tech cards to popular decks against recent winners.
6. Apply volatility so each run diverges.
7. Apply the player's influence if they performed well with an archetype.

This creates a useful pattern:

- Week 1: Aggro is cheap and common.
- Week 2: Midrange and anti-aggro tech rise.
- Regionals: Combo exploits slow midrange fields.
- State: Control adds combo hate.
- Nationals: A rogue deck appears because the field overcorrected.

### Player-Facing Meta Reports

Do not show exact hidden math by default. Show partial, flavorful, actionable reports:

- "Aggro made up nearly a third of last weekend's top tables."
- "Control players are moving two copies of Null Charm into the main deck."
- "Several grinders are testing Graveyard Combo for Regionals."
- "Shop owner says Token Swarm pieces are drying up."

Scouting should cost time, money, or opportunity and increase report accuracy.

## Booster Pack Reward Systems

### Pack Opening Goals

Pack opening should create suspense, anticipation, and decision pressure. It is both reward and temptation.

Recommended MVP pack:

- 8 cards total
- 4 commons
- 2 uncommons
- 1 rare or mythic
- 1 wildcard slot that can be foil, extra uncommon, rare upgrade, or promo

### Pack Reveal Flow

1. Show sealed pack art and set identity.
2. Reveal commons quickly.
3. Slow down at uncommons.
4. Build anticipation before the rare slot.
5. Highlight collection upgrades and deck relevance.
6. Offer quick actions: add to deck, wishlist, sell duplicate, inspect synergies.

The reveal should celebrate useful commons too. A common that completes a deck should get a "needed copy" treatment.

### Pack Types

- **Standard Pack**: Normal set distribution.
- **Archetype Pack**: Higher chance of cards for a tagged strategy.
- **Prize Pack**: Smaller but higher rare upgrade chance.
- **Draft Leftovers**: Cheap random commons/uncommons with occasional gems.
- **Shop Owner's Pick**: Weighted toward current deck gaps.
- **Speculative Box**: Expensive, volatile, high ceiling.
- **Meta Breaker Pack**: Contains cards strong against top meta decks.

### Duplicate Handling

Duplicates are important because real collections have friction, but they should not feel dead.

Use:

- Buylist value
- Trade value
- Foil/collector variants
- Crafting dust only as a fallback
- NPC trade wants
- Deck copy thresholds

Avoid:

- Pure duplicate protection everywhere
- Making every card instantly convertible into a perfect wildcard

## Starter Deck Archetypes

Each starter should be playable, incomplete, and pointed toward multiple upgrade paths.

### Redline Aggro

- Fantasy: Win before expensive decks stabilize.
- Strengths: Cheap, consistent, strong at locals.
- Weaknesses: Vulnerable to lifegain, sweepers, and efficient blockers.
- Key decisions: Threat density versus reach, all-in speed versus resilience.
- Upgrade paths: Burn Aggro, Prowess Tempo, Low-Curve Midrange.

### Lantern Control

- Fantasy: Answer everything, win with inevitability.
- Strengths: Strong late game, flexible sideboard, good into midrange.
- Weaknesses: Needs rares, can lose to fast starts or uncounterable threats.
- Key decisions: Answer mix, win condition count, card draw versus survival.
- Upgrade paths: Hard Control, Tapout Control, Anti-Combo Control.

### Gearworks Combo

- Fantasy: Assemble pieces and win in one explosive turn.
- Strengths: High ceiling, ignores some fair interaction.
- Weaknesses: Inconsistent early, vulnerable to disruption and hate.
- Key decisions: Tutors versus protection, speed versus redundancy.
- Upgrade paths: Glass Cannon Combo, Protected Combo, Hybrid Midrange Combo.

### Verdant Midrange

- Fantasy: Play individually strong cards and win every fair exchange.
- Strengths: Good baseline matchups, flexible upgrades, forgiving.
- Weaknesses: Can be too slow for combo and too fair for control.
- Key decisions: Curve, threat-answer ratio, sideboard tuning.
- Upgrade paths: Value Midrange, Ramp Midrange, Anti-Aggro Midrange.

### Neon Tempo

- Fantasy: Deploy one threat, protect it, and keep the opponent off balance.
- Strengths: Skill-expressive, strong against clunky decks.
- Weaknesses: Bad topdecks, weak if it falls behind.
- Key decisions: Threat count, cheap interaction, draw filtering.
- Upgrade paths: Spell Tempo, Evasive Tempo, Counter-Burn.

### Boneyard Recursion

- Fantasy: Turn the discard pile into a second hand.
- Strengths: Resilient, grindy, strong against removal.
- Weaknesses: Graveyard hate, awkward opening hands.
- Key decisions: Enablers versus payoffs, self-mill density, backup plan.
- Upgrade paths: Reanimator, Sacrifice Value, Recursive Aggro.

### Signal Tokens

- Fantasy: Go wide and make every small card matter.
- Strengths: Synergy-driven, strong with anthem effects, many useful commons.
- Weaknesses: Sweepers, poor individual card quality.
- Key decisions: Token makers versus payoffs, protection, reach.
- Upgrade paths: Swarm Aggro, Aristocrats, Board-Control Tokens.

### Prism Ramp

- Fantasy: Survive early, then cast cards bigger than everyone else's.
- Strengths: Huge late-game power, exciting rares, natural pivot deck.
- Weaknesses: Inconsistent, expensive, punished by tempo.
- Key decisions: Ramp count, stabilization tools, payoff diversity.
- Upgrade paths: Big Ramp, Multi-Color Goodstuff, Ramp Combo.

## Progression And Difficulty Scaling

### Progression Axes

- Collection size
- Deck quality
- Shop access
- Scouting accuracy
- Entry into bigger events
- Rival recognition
- Format knowledge
- Player skill expression through deck tuning

### Difficulty Scaling

Difficulty should scale across several dimensions:

- Opponent deck quality rises.
- Opponent sideboards become more targeted.
- Bad matchups become more common if the player dominates.
- Required records become stricter.
- Entry fees increase.
- Shop inventories improve but become more expensive.
- Bosses punish narrow or greedy decks.

Avoid only increasing opponent stats. Stronger opponents should look like better deckbuilders.

### Run Loss Conditions

Primary loss:

- Fail required tournament record.

Optional additional pressure:

- Cannot afford entry fee.
- Lose sponsor after repeated poor results.
- Miss qualification threshold.

Do not overuse bankruptcy as a loss condition. It can feel bureaucratic rather than dramatic.

### Long-Term Unlocks

Use unlocks to add variety, not raw power.

Good unlocks:

- New starter archetypes
- New card sets
- New shop events
- New rival pools
- Alternate season modifiers
- Cosmetic sleeves, binders, playmats

Risky unlocks:

- Permanent stat bonuses
- Permanent rare cards
- Anything that makes early runs feel invalid

## MVP Design

The MVP should prove four things:

1. Opening packs is exciting.
2. Deckbuilding choices matter.
3. The metagame changes runs.
4. Tournament failure creates tension.

### MVP Feature Set

Content:

- 4 starter archetypes
- 80 to 120 cards
- 1 set
- 5 tournament tiers
- 8 to 12 opponent profiles
- 5 bosses
- 12 to 20 shop events or trade offers

Systems:

- Collection with copy counts
- Deckbuilder with validation and deck metrics
- Booster opening
- Shop singles and pack buying
- Abstract duel/match simulator
- Tournament progression
- Dynamic metagame updates
- Save/load for current run

Recommended starter archetypes for MVP:

- Redline Aggro
- Lantern Control
- Gearworks Combo
- Verdant Midrange

### MVP Duel Model

A practical duel model can be abstract but still feel card-driven.

Each game:

1. Shuffle deck.
2. Draw opening hand.
3. Evaluate early, mid, and late phases.
4. Cards contribute role effects if drawn and playable.
5. Archetype synergies modify phase scores.
6. Tech cards modify scores against matching opponent tags.
7. Variance, pilot skill, and sideboarding affect final outcome.

Example phase weights:

- Aggro: early 50%, mid 35%, late 15%
- Control: early 20%, mid 35%, late 45%
- Combo: setup 40%, protection 25%, payoff 35%
- Midrange: early 25%, mid 45%, late 30%

This can later evolve into a more visual turn-based game without throwing away the data model.

## Engagement Hooks

### Short-Term Hooks

- Pack reveal suspense
- "One card away" deck goals
- Shop singles refresh
- Rival scouting
- Bubble rounds
- Sideboard decisions

### Medium-Term Hooks

- Pivot moments after rare pulls
- Metagame overcorrection
- Boss rematches
- Budget tension
- Archetype mastery

### Long-Term Hooks

- Unlocking new starter decks
- Discovering rare archetype variants
- Learning how different metas evolve
- Chasing Worlds wins with every archetype
- Seed sharing and daily/weekly challenge seasons

