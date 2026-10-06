# Keyword starter trial — Bodyguard and Bagver update

Implemented Bodyguard and Bagver’s heal buff, then tested the proposed starters against the current difficulty curve. **The 15-card proposal substantially improves Spicy and Hearty’s run performance, but the three starters remain uneven. Fresh’s Expert rival is a severe outlier.**

## Implemented changes

- **Bodyguard now prevents all overflow combat damage through that defender**, including Piercing, whether or not it is in a defensive stance. The defender still takes combat damage and can die. Normal retaliation still happens. Blocked overflow produces no Chef-damage event or Chef-hit trigger.
- Stalwart can still attack the opposing Chef directly. Bodyguard does not absorb direct attacks or damage from card effects.
- **Bagver now heals its Chef for 2 when sacrificed.** Its printed text matches. Healing respects maximum life and Cinnamon Snail’s healing reduction. Its production stats remain 1/2; the proposed starter copy is tested at the requested 1/1.
- Added the focused Bodyguard/Bagver regression test to the demo-check script.

The proposed starter lists are **simulation prototypes**, not replacements for the live New Run lists. All changed prototype stats are isolated to their starter copies; existing rewards and rival cards retain their stats. The previous audit remains preserved in its original output folder.

## Exact starter lists tested

| Copies | Spicy | Sweet | Hearty |
|---:|---|---|---|
| 6 | Textless 2/2 Spicy Ingredient | Textless 2/2 Sweet Ingredient | Textless 2/2 Hearty Ingredient |
| 3 | Hot Honey Bee, 1/1; deal 1 on play | Choco Bat, 1/1; draw 1 on play | Bagver, 1/1; heal 2 on sacrifice |
| 2 | Wastabi, 2/1 Stalwart | Soft Serve Crab, 1/2 Bodyguard | French Bread Dog, 1/2 Taunt |
| 2 | Sriracharrow, 5/4 Stalwart | Mothchi, 4/5 Bodyguard | Lasagnama, 5/5 Taunt |
| 2 | Chef Giada: draw 3 | Chef Giada: draw 3 | Chef Giada: draw 3 |

Each Meal costs one Ingredient of its starter’s affinity. Each list has 15 cards and five names. The 12-card comparison uses three textless Ingredients instead of six, with everything else identical.

## Full Locals runs

Both baseline and proposal use the implemented fixes. Each main result contains 200 runs per starter with matching seeds, 40 persistent life, a one-use healing bye, affordable singles purchases, and all reward cards accepted.

| Starter | Existing starter after fixes | Proposed 15-card starter | Proposal wins | Approx. 95% interval |
|---|---:|---:|---:|---:|
| Spicy | 12.5% | **46%** | 92/200 | 39.2–52.9% |
| Hearty | 0.5% | **13%** | 26/200 | 9.0–18.4% |
| Sweet | 40.5% | **36.5%** | 73/200 | 30.1–43.4% |

The new lists sharply improve early survival. Spicy wins 200/200 opening rounds and 199/200 second rounds. Hearty wins 192/200 opening rounds, but only 73/168 semifinals it reaches. Sweet wins 191/200 opening rounds and 127/174 semifinals it reaches.

| Proposed 15-card list: conditional win rate once round is reached | Spicy | Hearty | Sweet |
|---|---:|---:|---:|
| Opening round | 100.0% (200/200) | 96.0% (192/200) | 95.5% (191/200) |
| Second round | 99.5% (199/200) | 87.5% (168/192) | 91.1% (174/191) |
| Semifinal | 83.4% (166/199) | 43.5% (73/168) | 73.0% (127/174) |
| Final | 55.4% (92/166) | 35.6% (26/73) | 57.5% (73/127) |

This is not an isolated Bagver-buff comparison: both columns already have the two production fixes. It measures the new starter package against the existing starters under the same fixed rules.

## Difficulty curve without accumulated damage

These are fresh, **unevolved** starters at 40 life for every battle, with no shop or rewards. Each proposed-starter cell contains 400 battles. Rival health is 12/12/18/28 for Easy/Medium/Hard/Expert, and each rival uses that tier’s real deck and AI. The opponent mix follows the live replacement rule: 50% predator affinity, 25% each of the other two eligible rival affinities. The player acts first with Hard AI.

| Rival tier | Spicy | Hearty | Sweet |
|---|---:|---:|---:|
| Easy | 100.00% | 96.75% | 91.75% |
| Medium | 100.00% | 97.75% | 92.25% |
| Hard | 95.50% | 75.25% | 76.00% |
| Expert | 75.75% | 56.50% | 68.75% |

**Easy is a benchmark only:** the current hub actually uses Medium, Medium, Hard, Expert. These isolated tests measure encounter strength, not the probability of surviving an entire run. The 75.75% Spicy Expert figure does not imply a 75.75% full-run clear rate.

The existing starters, under the same fresh-life test with 200 battles per cell, scored:

| Rival tier | Spicy | Hearty | Sweet |
|---|---:|---:|---:|
| Easy | 94.5% | 76.5% | 95.0% |
| Medium | 98.0% | 75.5% | 91.0% |
| Hard | 79.5% | 34.0% | 73.5% |
| Expert | 65.5% | 23.5% | 74.0% |

**Fresh is the major Expert outlier.** The proposed Spicy starter beats Expert Hearty 200/200 and Expert Sweet 99/100, but Expert Fresh only 4/100. Hearty beats Expert Fresh 2/100; Sweet wins 0/100. In full evolved runs, players facing the Fresh final won only 5/104 combined: Spicy 4/44, Hearty 0/15, Sweet 1/45. The current Fresh Expert list’s nine Mexican Sweet Corinos and three Yolke Bowls need a separate rival-list tuning pass.

## Starter strength against each other

To separate starter strength from rewards and rival selection, 900 additional duels used 20 life each, Hard AI with the same pressure style on both sides, and equal seating. Each pair played 300 games.

| Pair | First listed deck’s win rate |
|---|---:|
| Spicy vs. Hearty | 76.0% |
| Spicy vs. Sweet | 91.3% |
| Hearty vs. Sweet | 89.7% |

This reverses the old starters’ relative standing: the proposed Sweet list is weak in direct starter duels despite reasonable campaign results. Campaign performance also depends on the opponent pool, rewards, asymmetric health, and piloting style. It cannot establish that the starters themselves are balanced.

The stat breakpoints explain a concrete concern: a 5/5 Hearty Meal survives combat against a 4/5 Sweet Meal and kills it. Bodyguard protects against overflow; it neither changes that unit trade nor prevents Spicy’s Stalwart attacks from bypassing it. **Sweet at 4/6 would be a sensible next experiment**, but it was not applied or tested in this pass.

## Deck size, rewards, and pilot sensitivity

All rows below use the same first 100 seeds per starter. The 15-card comparison subset differs slightly from the larger headline sample.

| Experiment | Spicy | Hearty | Sweet |
|---|---:|---:|---:|
| 15 cards, all rewards, Hard player | 52% | 12% | 33% |
| 12 cards, all rewards, Hard player | 47% | 6% | 34% |
| 15 cards, one highest-scored reward each time | 57% | 17% | 37% |
| 15 cards, all rewards, Expert player | 52% | 11% | 33% |

The 12-card list doubles Hearty’s opening-round pressure damage from 1.39 to 2.50 life on average; Sweet rises from 1.54 to 3.23. Two Giadas are much more comfortable in the 15-card shell. The differences in small sensitivity samples are provisional, but these results give no reason to prefer 12 cards.

Accepting only one statically highest-scored reward performed a little better for all three starters in this sample. Keep optional picks; taking every card is not automatically an upgrade. These are heuristic drafting policies, not optimal deckbuilding.

## Recommendation

Keep the proposed **15-card structure** as the next starter candidate. The opening rounds are far more accessible, and the repeated basic cards leave room for reward growth. Before treating the list as balanced:

1. Bring the Fresh Expert rival closer to the other final rivals.
2. Revisit Sweet’s Meal health and its direct matchups against Stalwart.
3. Help Hearty retain more life through the semifinal; its run performance still trails substantially.
4. Retest the same seeds before altering global starting health or the 8-life bye.

No additional balance changes were made beyond Bodyguard and Bagver’s healing.

## Validation and reproduction

**15,100 simulated battles:** 2,100 run simulations containing 7,000 matches; 7,200 isolated difficulty-curve battles; 900 equal-health starter duels. No accepted battle reached the 100-turn cap. These are automated balance measurements, not predicted human win rates.

The new regression test failed before the changes and passes afterward. It covers both seats, exposed/defending units, Piercing, normal damage and retaliation, Chef-hit triggers, animation events, Stalwart bypass, direct effect damage, sacrifice healing, maximum-life caps, and healing suppression. RebalancedCardPoolSmokeTest, AiPolicySmokeTest, OpeningTurnDrawSmokeTest, EmptyDeckDrawSmokeTest, and RouteRunSmokeTest also passed.

**Known unrelated failure:** KitchenGameSmokeTest fails its rounded-button/hand-inspector UI assertion at line 889. The same failure was reproduced in a temporary project overlay with the original combat service and original card data. That UI was not changed here. The full demo release gate is not claimed to pass.

Files:

- `scripts/cooking/BodyguardBagverSmokeTest.gd` — regression coverage, also registered in `scripts/release/check_demo.sh`.
- `scripts/cooking/KeywordStarterProposal.gd` — exact, isolated starter definitions.
- `outputs/keyword_starter_audit_2026-09-04/summary.json` — aggregates, confidence intervals, per-rival results, and paired comparisons.
- The same output folder contains full JSONL records, logs, and a source-hash manifest.

Run from the project root:

```sh
python3 scripts/cooking/run_balance_audit.py --output-dir outputs/keyword_starter_audit_2026-09-04 --only=current_all_shop,keyword15,keyword12,keyword15_expert,keyword15_one,keyword_curve,current_curve,keyword_duels
python3 scripts/cooking/summarize_balance_audit.py --input-dir outputs/keyword_starter_audit_2026-09-04
```
