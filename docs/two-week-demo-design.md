# Two-week demo — playable draft

Owner revisions: September 10–11, 2026. The card concepts remain provisional;
the five deckbox prizes below use the owner's September 11 effects.
No new generated bitmap assets were created. The new
Meals use the existing missing-art treatment until illustrations are supplied.

## Flow

Starter → Week 1 (four rounds, existing rewards and hub) → champion reward →
choose one deckbox from three → resolve any card-copy prize → week-two
introduction → open **Second Helpings**
→ Week 2 (four rounds, expanded pools) → demo complete.

Deck, upgraded copies, funds and the deckbox carry over. Starting each new week
fully restores life on Black and Blue borders; Yellow, Silver and Gold heal
20 life, capped at the current maximum, including Big Lunch's bonus. Apply this
once on week advancement, after resolving the deckbox prize. Reloading or
revisiting a screen does not heal again. Life still carries between rounds.
The bye, paid weekly upgrade and shop stock refresh.
The singles case also offers paid rerolls: $5, then $6, $7 and so on in the same
round, resetting to $5 after a battle. Each reroll replaces all four offers,
including refilling partial or sold-out stock, within the starter ecosystem
and current week's unlocks. Stock and escalating cost persist across saves
and shop revisits; rerolling does not refresh other services.
Second-week rivals have +2 life provisionally and gain an affinity-matched new
Meal. The intro pack guarantees two Special Serve Meals and one Spice, plus two
other cards, all inside the player's starter ecosystem. Take any/all or skip,
using the normal reward controls. New cards and Spices then appear in the usual
week-two rewards and singles. Earlier completed demos stay completed; active
hub saves gain week two without removing cards already owned.

## Special Serve concepts

Every card is a Meal with two summon methods. **Normal Serve** pays its normal
recipe and uses the usual Meal allowance. **Special Serve** pays the alternative
condition and has no per-turn limit. Special Serves can happen before or after
the normal summon. The alternate Ingredients need not be recipe ready unless
specified. All slots, sacrifices, attachments, triggers and on-serve effects use
the existing combat rules. Reviving a Meal does not count as serving it.

| Card | Animal + food | Affinity · stats | Special Serve payment | Provisional on-serve effect |
| --- | --- | --- | --- | --- |
| Jalapeñowl | Jalapeño + owl | Spicy · 4/3 | Sacrifice 1 spiced Ingredient. | When served, deal 2 damage to the opposing Chef. |
| Quesadillama | Quesadilla + llama | Spicy · 4/4 | Sacrifice 1 Spicy Ingredient with 3+ Attack. | When served, this gains +1 Attack. |
| Tiramiswan | Tiramisu + swan | Sweet · 3/4 | Sacrifice 1 spiced Ingredient. | When served, draw 1 card. |
| Crêpebara | Crêpe + capybara | Sweet · 3/5 | Sacrifice 1 Sweet Ingredient with Bodyguard. | When served, heal your Chef for 2. |
| Macawroni | Macaroni + macaw | Hearty · 3/5 | Sacrifice 1 Hearty Ingredient with 4+ current Health. | When served, heal your Chef for 2. |
| Wombatato | Wombat + potato | Hearty · 4/5 | Sacrifice 1 damaged Ingredient. | When served, this gains +1 Health. |
| Guacamolemur | Guacamole + lemur | Fresh · 4/4 | Sacrifice 2 Ingredient tokens. | When served, draw 1 card. |
| Kimchilla | Kimchi + chinchilla | Funky · 3/4 | Sacrifice 1 spiced Ingredient. | When served, return an Ingredient from your discard to your hand. |

## Five deckbox prizes

Choose one after the first weekly championship. Offers are seeded and saved,
so reloads cannot reroll them. Selection requires Select → Keep. The equipped
box's effects are snapshotted into the save and do not silently change if its
JSON definition is edited later. Already equipped legacy boxes retain their
saved effects. Invalid pending offers are normalized into three valid choices;
valid saved offers keep their order and selection.

| Deckbox | Effect | Effect key |
| --- | --- | --- |
| Tip Jar Box | Earn $1 after every match, whether you win or lose. | `match_money` |
| Big Lunch Box | Gain 5 maximum life and heal 5 when chosen. | `max_life` |
| Light Pack Box | Choose and remove 3 card copies from your deck once. | `remove_cards` |
| Chef’s Edge Box | Choose and upgrade 2 eligible card copies from your deck once. | `upgrade_cards` |
| Padded Picnic Box | Take 2 less damage on every reshuffle, minimum zero. | `reshuffle_damage_reduction` |

Light Pack retains the existing ID `loyal_regular`; its displayed name and new
effect change only for newly equipped prizes. The other IDs remain `tip_jar`,
`big_lunch`, `chefs_edge` and `padded_picnic`.

Removal and upgrade prizes open a mandatory picker before the week-two intro.
Choose a specific copy, inspect its current upgrade state, then confirm each
operation. Removal must leave at least one card in the deck; upgrades use the
normal eligibility rules. Persist `deckbox_reward` (`kind`, `remaining`) with
`week_transition = "deckbox_reward"`, saving each completed choice so a reload
resumes the remainder. If there are fewer eligible copies than the prize asks
for, finish when none remain. These rewards happen once when picked up and do
not apply to future cards or refresh in week two.

Big Lunch awards its capacity and healing once on selection. Tip Jar pays once
per completed match, including a loss; duplicate result callbacks do not award
it again. Padded Picnic affects only the player's reshuffle pressure: the
default 3/5/7 curve becomes 1/3/5. Previously equipped snapshots continue to use
their original effects, without granting a newly defined pickup reward.

## Editing the prototype

- **Cards:** `data/content/second_helpings.json`. Change `name`, `attack`, `health`,
  `recipe`, `on_play` and `text`. Text must agree with the effect data. The cards
  are loaded by both the campaign catalog and the combat service.
- **Special payment:** `special_serve.recipe` uses the existing affinity syntax
  (`spicy`, `any`, `sweet|hearty`). `ingredient_filter` supports `spiced`,
  `min_attack`, `min_health` (current Health), `damaged`, `token`, and `keyword`.
  All selected Ingredients must match the filters. `require_ready` defaults to
  false; set it to true and say so in the text to require the normal wait.
  Recipe payment must contain at least one Ingredient. A different kind of
  special condition, such as discarding from hand or checking turn events,
  needs a new resolver; this prototype does not pretend every future rule can
  be expressed with the existing fields.
- **Effects:** `on_play` uses the existing combat effect vocabulary. For example
  `{"type":"draw","amount":2}`, `{"type":"heal_player","amount":3}` or
  `{"type":"buff_self","attack":1,"health":1}`. Both summon methods run it.
- **Deckboxes:** `data/content/demo_progression.json`, under `deckboxes`.
  Keep IDs stable. Each definition has a name, description and numeric `effects`.
  The five keys above define the current offer pool. Keep the legacy effect
  hooks for equipped snapshots; novel effect kinds need a small hook.
- **Pacing:** that same file holds week count, rounds per week, offer count,
  `between_week_heal` (20) and `between_week_full_heal_difficulties` (`white`,
  `blue`; `white` is the saved ID for Black), rival life bonus and introduction
  pack counts.
  The authored/demo UI currently assumes two weeks and four rounds each; those
  values describe the implemented slice, not arbitrary campaign generation.
- **New art:** add normal `art` or `art_frames` fields to the card definitions.
  Existing card-face, inspection and combat drawing handle them automatically.

The locked catalog test now explicitly includes the eight owner-requested draft
Meals (95 collectibles plus the token). Update its manifest when adding/removing
cards rather than weakening the catalog check.

## Verification

`SpecialServeSmokeTest.gd` covers repeat special summons on both seats, normal
allowance preservation, every draft condition and normal recipe, saved payment
selection, cancellation, failed costs, duplicate sacrifice IDs, locked week-one
rules, board capacity and AI use. `WeeklyDemoSmokeTest.gd` covers the two-week
flow, actual deckbox buttons, pool unlocks for all starters, the five-prize pool,
win/loss cash, repeated callbacks, partial-pack saves, weekly service resets and
final resume. Focused prize checks cover individual copy selection and partial
removal/upgrade saves.
Native review captures are in `outputs/weekly_demo_2026-09-10/`.

September 11 five-prize revision: the updated `WeeklyDemoSmokeTest.gd` passed
702 headless checks, including Tip Jar payouts after wins and losses, duplicate
result guards, Big Lunch pickup, reduction carried into resumed battles, and
both weekly tournament transitions.

Historical September 10 prototype validation: 743 progression checks and 61
combat checks passed.
`WeeklySpecialServeUiSmokeTest.gd` also passed using the live buttons, destination
selection and payment confirmation. Native captures of the deckbox, introduction,
pack, week-two hub and finale were reviewed. Targeted autosave, campaign, tutorial,
inspection and shop regressions passed. The existing Bodyguard hover-preview
failure in `BattleActionPreviewUiSmokeTest.gd` was reproduced against the
pre-change code; that historical run did not claim a passing full release gate.
The new card concepts still await final art and balance playtesting.
