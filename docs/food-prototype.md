# Food Prototype

Open **Food Prototype** on the title screen, then **New Prototype**. Resume
through **Continue Prototype** in the same menu. The normal title's Continue
continues the regular game. A completed run offers New Prototype and Review Deck.

This is a four-round experiment in discovering your deck's identity during a
run. It does not replace the regular game's starter selection or card data.

## Rules and content

The starter contains six neutral 2/2 Basic Bites, four neutral 1/3 Sturdy Bites,
three neutral 4/4 Simple Serves costing one Ingredient, one Wooden Spoon and one
Tongs. Choose one of three seeded opening cards to reach 16 cards. The opening
pool demonstrates aggression, draw, token production, recursion and sacrifice
healing. The starter-only units reuse existing art as prototype stand-ins.

Normal Meal recipes require the printed number of **any Ingredients**, on both
sides. Readiness, board space, normal Meal allowances, effects, and affinity
synergies still apply. All five food affinities can appear in shops and rewards.
Week-two cards, Spices and Special Serves are excluded. Starter-only cards do not
appear as purchases or rewards. Existing reward quantities, player life, money,
reshuffle pressure, upgrades, removal and the one-use bye remain in effect.

The run ends after the fourth round's reward. There is no deckbox/week-two
transition. The starting difficulty is Black.

## Revision 2: late rounds and connected rewards

Round three now has **16 life and four deck substitutions**, down from 18 and
seven. Round four has **22 life and five substitutions**, down from 28 and nine.
These substitutions replace weaker starter cards with stronger existing cards;
they are separate from the player's +1/+1 card upgrades. Rivals retain Hard and
Expert AI. The first two rounds keep their existing encounter settings.

Each reward pack reserves two slots for an enabler and payoff from one of five
mechanical groups: pressure, tokens, discard, durability and serving. The group
with the most support in the current deck wins, with seeded ties. Copies count
up to two per card so one repeated card cannot dominate the choice indefinitely.
Missing pieces receive three times the selection weight of owned pieces.

The remaining one, three or six slots keep the normal rarity weights and draw
from all five affinities. Any or all offered cards may still be taken. The new
reward path skips Grater while there are no Spices, and skips affinity Shopping
Lists without a matching Ingredient in the current deck. Shop stock is unchanged.
The package lists are authored in `data/content/food_prototype.json`; card
abilities and printed stats are unchanged in this pass.

New prototype saves snapshot encounter settings, and a called rival's actual
deck persists from its introduction. Existing active battles and already offered
rewards stay intact. Older prototype saves use the new settings for future
encounters and future rewards; start New Prototype for a complete revision-2 run.

On 48 paired seeds, the value-picking AI completed **11/48 runs**, versus **4/48**
with the previous rules. A policy scoring complementary card roles finished
**9/48**: it did better on the first seed set and worse on the second. This is
encouraging for the difficulty curve, but does not establish stronger or more
interesting specialized decks. All 96 runs using the full new tuning resolved
below the 100-turn cap. These are AI diagnostics, not human win-rate estimates.

See the [revision-2 test report](../outputs/food_prototype_tuning_2026-09-22/README.md)
for both seed sets, the encounter-only comparison, raw data and verification.
Next, play several full runs and check whether the offered connections make
purchase and sacrifice decisions more interesting before changing card abilities.

## Implementation

- `data/content/food_prototype.json`: starter definitions, opening pool, encounter
  tuning, reward packages and optional prototype-only card overrides.
- `scripts/FoodPrototype.gd`: private catalog overlay, opening transaction and
  local diagnostic records. Regular `data/cards.json` is not rewritten.
- `scripts/Main.gd`: menu flow, catalog switching, isolated saves and supplying
  the same catalog to live combat, inspection, reward screens and upgrades.
- `scripts/CardFace.gd`: neutral Ingredients and Meals use the existing rendered
  card face, including art, combat stats and recipe display.

The prototype save is `user://food_prototype_run.json`, with the save service's
normal backup handling. The normal save retains its own path. Each prototype
also writes `user://food_prototype_run_playtest_<seed>.json` locally. Records
contain seed/version, opening offer/pick, reward offers/picks, shop stock,
deck/upgrades, round outcomes, money, life and final deck. No data is sent anywhere.
Checkpoint writes omit repeated unchanged data. Each new run has a fresh seed;
the opening offer and current stock persist when reloaded.

## Initial September 22 assessment (revision 1)

**The ruleset is playable; its late-run balance is still rough.** The first
version's 1/2 Basic Bite and 3/4 Simple Serve stalled against existing rival
boards. In six initial diagnostic runs, two died in round one and none finished.
Basic Bite was raised to 2/2 and Simple Serve to 4/4. They remain plain units
below the payoff strength of the existing food cards.

The revised version was tested on seeds 920100–920123:

| Configuration | Runs | Won round 1 | Won round 2 | Won round 3 | Completed |
| --- | ---: | ---: | ---: | ---: | ---: |
| Prototype, value picks | 24 | 24 | 19 | 8 | 1 |
| Prototype, affinity-biased picks | 24 | 24 | 19 | 8 | 2 |
| Standard typed starters, value picks | 24 | 22 | 16 | 11 | 3 |

These are **AI diagnostics, not human win-rate estimates**. Both seats use the
production combat AI; the player uses Hard, rivals use the normal round tiers.
The harness uses the actual hub encounter seeds, rival deck builder, week-one
filters and card catalogs. Its simple acquisition policy takes the two highest
scored rewards, buys up to two affordable singles, and uses one bye for healing
or an upgrade. It does not use paid removals, paid upgrades or rerolls. The
standard comparison ends after the same four rounds and rotates Spicy, Hearty
and Sweet starters. Its rival affinity can differ because normal runs avoid
matching the starter. It is a rough comparison, not a controlled causal test.

All 48 prototype runs resolved without reaching the 100-turn cap. One standard
run hit the cap. Value-policy prototype battles averaged 7.2 turns versus 8.9
for the standard sample; this alone does not establish better pacing.

The two prototype acquisition policies produced identical final decks on 19/24
paired seeds. The affinity policy simply adds a score bonus for the opening
card's affinity; it does not search for mechanical combos. This is weak evidence
for specialization as currently expressed, and a useful reason to inspect
payoffs and reward composition next. It is not proof that players cannot build
effective specialized decks.

Recommended next iteration: human playtests of the opening and early purchases,
then tune the round-three/four rival curve and the availability of useful build
payoffs. Keep generic sacrifice rules while testing this. Avoid broadly nerfing
the catalog based only on the heuristic's selections.

The late-round and reward iteration above supersedes this initial recommendation.

Raw runs and reviewed 1280×720 and 1440×900 (125% text) screenshots are in
`outputs/food_prototype_2026-09-22/`. The functional test's result-screen wins are
injected solely to verify transitions; balance results come from the separate
combat simulation.

## Verification

`FoodPrototypeTuningSmokeTest.gd` covers 600 seeded reward configurations,
deterministic offers, complementary pairs, exclusions, all-affinity wildcards,
deck pivots, tutor targets, normal reward isolation, live round-three/four life
and AI, rival-deck snapshots, old active battles and reward/save roundtrips.
The prototype flow, tuning, route, campaign flow, weekly demo (714 checks) and
autosave tests pass. `OpponentDeckTierSmokeTest` still fails its existing
three-Cinnamon-Snails assertion; running it with the original committed
`TournamentService.gd` produces the same failure.

`FoodPrototypeSmokeTest.gd` covers title entry, independent save files, fixed
neutral starter, opening choice resume and duplicate prevention, all-affinity
week-one rewards, generic printed and live recipes, neutral rendering, upgrades,
recipe readiness/count/selection, serving and the normal Meal limit, battle
checkpoint restoration, reward claims and the four-round ending. It also runs
with a native renderer at both sizes and captures the actual screens.

Regression checks: GameStartFlowSmokeTest, TitleMenuPaletteSmokeTest,
AutosaveSmokeTest, RuntimeCardFaceIntegrationSmokeTest, RouteRunSmokeTest and
CanonicalCatalogSmokeTest pass. The older CardFaceSmokeTest still reports its
17 legacy frame/trim/classification assertions; a temporary baseline renderer
without this change reports the exact same failures. The current runtime
renderer test passes. Headless macOS emits a certificate-store warning; the
native prototype test has no script errors. The prototype test and simulation
also emit Godot's object-leak warning on teardown.

Example commands (replace the Godot executable path as needed):

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /private/tmp/food-smoke-engine.log --script scripts/FoodPrototypeSmokeTest.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /private/tmp/food-tuning-engine.log --script scripts/FoodPrototypeTuningSmokeTest.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /private/tmp/food-sim-engine.log --script scripts/cooking/FoodPrototypeSimulation.gd -- --runs=24 --output=outputs/food_prototype_2026-09-22/value-simulation.json
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --log-file /private/tmp/food-affinity-engine.log --script scripts/cooking/FoodPrototypeSimulation.gd -- --runs=24 --mode=prototype --policy=affinity --output=outputs/food_prototype_2026-09-22/affinity-simulation.json
```
