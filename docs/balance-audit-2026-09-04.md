# Current balance audit — September 4, 2026

> Historical snapshot before the Bodyguard/Bagver changes. See the [keyword starter follow-up](keyword-starter-audit-2026-09-04.md) for the newer tests.

**Finding:** the current deck families are substantially uneven. Sweet is the strongest selectable starter, Hearty is severely behind, and the upgraded Fresh rival deck creates a large late-run difficulty spike. A simpler starter is a good direction, but simplifying every deck without also tuning rivals and Hearty will not solve the imbalance.

This audit added diagnostic scripts and experimental starter definitions only. No production cards, starter lists, health values, rewards, or existing hub/UI work were changed.

## Scope and method

- **4,200 complete or failed Locals runs**, containing **12,124 battles**; **7,800 equal-health duels**; **45,000 reward offers** containing **240,000 cards**. No accepted battle reached the 100-turn cap.
- Tested the live four-round hub: two regular rivals, a semifinal, and a final; 40 persistent life; opponents at 12/12/18/28 life and Medium/Medium/Hard/Expert AI; opening hand five; later draw/refill to three; reshuffle damage 3/5/7.
- Campaigns call the production combat, rival-deck, reward, shop, upgrade, and healing services. The shop is persistent with four singles; starts with $8; battle cash is $2/$2/$5/$8. The shopping policy buys affordable cards with supported recipes, ordered by a static value-per-price heuristic. It does not buy packs. Shop randomness is seeded directly for reproducible comparisons, rather than replaying the UI’s global RNG history.
- The automated player uses Hard AI by default; the opponent uses its actual encounter tier. The live table constructs blank deck archetypes: its fallback profiles are **defensive for the player proxy and pressure for every rival**. Equal-health duels use pressure for both seats, swapping deck seating equally, with 20 life each and the current draw/reshuffle rules.
- Primary baseline: 200 runs per selectable starter. Sensitivity experiments: 100 per starter with the same first 100 seeds. Base 20-card duels: 150 per seating, 300 per pair. Other duels: 100 per seating, 200 per pair.
- Reward policy is take all unless specified. The healing policy spends the one-use bye once at least eight life is missing, or before the final if still unused and wounded. Upgrade policy uses one highest-scored eligible existing card before round one.
- **These are automated balance measurements, not estimates of human win rates.** Deck piloting, shopping, and drafting heuristics have limitations. Expert-player and pressure-player sensitivity runs are included below. Small differences in 100-run samples are provisional; the large Hearty deficit and Fresh rival spike recur across tests.
- The previous RouteCampaignSimulation still traverses the legacy overworld. The previous StarterBalanceSimulation excludes Fresh and uses legacy draw/health rules and affinity-specific AI styles. Their results were not used for the current balance conclusions.

## Current selectable starters in full Locals runs

| Starter | Clears | Clear rate | Approx. 95% Wilson interval | Life after a successful final |
|---|---:|---:|---:|---:|
| Spicy | 28/200 | 14% | 9.9–19.5% | 19.2 |
| Hearty | 1/200 | 0.5% | 0.1–2.8% | 4.0 |
| Sweet | 75/200 | 37.5% | 31.1–44.4% | 15.8 |

Hearty’s survivor-life figure comes from its single win. The intervals describe simulation sampling uncertainty, not AI-model error.

| Starter | Win opening round | Win second round, if reached | Win semifinal, if reached | Win final, if reached |
|---|---:|---:|---:|---:|
| Spicy | 191/200 (95.5%) | 158/191 (82.7%) | 93/158 (58.9%) | 28/93 (30.1%) |
| Hearty | 144/200 (72.0%) | 64/144 (44.4%) | 11/64 (17.2%) | 1/11 (9.1%) |
| Sweet | 187/200 (93.5%) | 173/187 (92.5%) | 126/173 (72.8%) | 75/126 (59.5%) |

Hearty loses 28% of opening matches even with 40 life against a 12-life rival. Its survival problem begins before the boss. In the combined baseline, the Fresh champion won **55 of 59** matches against players who reached it. Those are conditional survivor samples, but the equal-health results independently confirm the Fresh expert list’s strength.

## All authored deck families at equal health

Numbers are win percentages against the other three families, with equal seating. The 15-card Fresh list is a diagnostic compact version; Fresh is not a selectable hub starter. There is currently no authored Funky deck to rank.

| Deck list | Spicy | Hearty | Sweet | Fresh |
|---|---:|---:|---:|---:|
| Current compact 15 | 39.5% | 23.7% | 74.0% | 62.8% |
| Authored base 20 | 66.9% | 11.0% | 76.1% | 46.0% |
| Easy rival 20 | 72.2% | 9.8% | 75.2% | 42.8% |
| Medium rival 20 | 49.2% | 16.7% | 82.3% | 51.8% |
| Hard rival 20 | 25.2% | 16.3% | 68.7% | 89.8% |
| Expert rival 20 | 14.5% | 23.5% | 67.8% | 94.2% |

Rival tiers in this table describe deck composition. Both pilots remain Hard AI so decision strength is held constant. Each row compares lists within that row; it is not a direct test of an upgraded list against its own base list.

For the actual compact starters, Spicy went 50/50 against Hearty, but won only 30.5% against Sweet. Hearty won 10.5% against Sweet. Sweet won 63% against compact Fresh. In the base-20 duel batch, first-seat wins were 51.2%, so its large family gaps were not explained by seating.

**Rival construction issue:** the difficulty routine makes 1/4/7/9 swaps by generic rarity/stat score and permits repeated additions. Current Expert lists contain nine Ghost Pepythons (Spicy), nine Lemon Herb Chickens (Hearty), nine Sweet Pugtatos (Sweet), or nine Mexican Sweet Corinos plus three Yolke Bowls (Fresh). This produces very different power and play patterns. Author rival lists with deliberate bodies, finishers, answers, and internal copy counts; keep the intended unlimited-copy rule for player runs.

## Health and recovery

Each row below uses the same 100 seeds per starter. The comparable baseline is therefore 13% / 0% / 39%, rather than the larger baseline above.

| Experiment | Spicy | Hearty | Sweet |
|---|---:|---:|---:|---:|
| Current: 40 life, heal bye, all rewards, singles | 13% | 0% | 39% |
| 32 starting/max life | 12% | 0% | 28% |
| 48 starting/max life | 21% | 0% | 44% |
| No bye | 12% | 0% | 28% |
| One card upgrade instead of heal | 14% | 0% | 37% |
| Expert player proxy | 13% | 0% | 39% |
| Pressure-style Hard player proxy | 1% | 0% | 33% |

| Baseline, per attempted match | Spicy | Hearty | Sweet |
|---|---:|---:|---:|
| Gross life damage, including pressure | 14.03 | 24.00 | 12.31 |
| Actual card-based life healing | 0.00 | 1.88 | 0.01 |
| Reshuffle pressure damage | 0.30 | 0.91 | 1.78 |

**Recommendation:** keep 40 life and the 8-life bye as the working baseline while repairing deck balance. Giving everyone another eight life does not rescue Hearty in this sample. Hearty’s healing identity currently supplies only 1.9 actual life per match against 24 gross damage; Ramen heals units, and Bagver heals only one life on sacrifice. Improve its ability to stabilize and finish a game before deciding whether to change global health.

The 3/5/7 reshuffle rule is not the main survival problem in take-all runs. Sweet takes more pressure early because it draws more, but by the final the average pressure per match is under 0.2 life for every starter. Reward/shop growth largely switches that pressure off. Keep it as small-deck counterpressure; do not expect it to balance late-run decks by itself.

The pressure-style sensitivity test changes Spicy dramatically. That is a warning against interpreting any one bot’s completion percentage as the human difficulty target. Hearty remains weak with both styles and with Expert decision-making.

## Cards received and deck growth

| Same 100-seed comparison | Spicy | Hearty | Sweet |
|---|---:|---:|---:|---:|
| All rewards + singles | 13% | 0% | 39% |
| One statically highest-scored card per reward | 20% | 1% | 31% |
| Up to two cards, filtering unsupported recipes | 19% | 1% | 35% |
| Skip rewards; still buy singles | 20% | 0% | 25% |
| All rewards; skip shop | 21% | 0% | 33% |

Taking more cards is not uniformly beneficial. The current policy helps Sweet more consistently than Spicy. These drafting policies are simple, so the smaller gaps are directional evidence, not proof of optimal pick counts. Preserve the ability to skip or take several cards.

- A starter has 15 cards. Taking every reward gives **18 → 21 → 26 before the final → 34 after the final**, before purchases. Four singles can raise those last sizes to 30 and 38. Successful baseline decks averaged about 38 cards after rewards.
- Eight of the floor’s nineteen reward cards arrive after the demo’s final fight. They cannot affect Locals difficulty; treat them as a next-floor payoff. A large final reward does not compensate for weak early progression.
- The affinity ecosystem filter worked in all **240,000 sampled reward cards**, with no illegal offers. Offers contained the requested 3/5/8 unique cards.
- Roughly **23–25% of regular-reward Meals** had recipes unsupported by an untouched mono-affinity starter. This means the deck lacks the required Ingredients, not that the card is illegal. The miniboss figure is about 33–36%. These figures use the untouched starter as a reference; evolved decks may support more recipes.
- Improved rarity weighting works, but a miniboss offer contained no rare/mythic in 6.5% of Spicy samples, 7.7% of Hearty samples, and 10.2% of Sweet samples. If a rare is meant to be guaranteed, the generator needs an explicit slot.
- **Shop stock issue:** inventory generation starts common/common/uncommon/uncommon/rare, but the hub retains only the first four cards. Its singles case therefore has no rare slot. Show the fifth card or explicitly select a mixed four-card inventory.

**Recommendation:** retain the 3/5/8 reveal structure initially, add a check that an early reward has at least one immediately useful choice, and make the shop’s rarity mix deliberate. Reward eligibility should allow building toward a second affinity; it should also avoid repeated offers with no short-term help.

## A much simpler starter

The current 15-card lists are not purpose-built weak starters. They are trimmed 20-card decks, still containing **nine distinct names, seven Ingredients, three Meals, three Tools, and two Chef Giadas**. Each selectable starter retains two mythics and one rare, as assigned by the catalog. Trimming the largest stacks leaves the same card vocabulary and strong one-ofs, while reducing basic-card consistency.

I would replace that process with explicit 15-card starter definitions and around **five distinct names**. Move Chef Giada, Recipe Prep, search chains, and the bigger lock/engine cards into rewards.

Two unshipped experiments were tested against the unchanged live rivals:

| Starter experiment, same 100 seeds | Distinct names | Spicy clears | Hearty clears | Sweet clears |
|---|---:|---:|---:|---:|
| Current | 9 | 13% | 0% | 39% |
| Simplified, existing cards only | 4 | 28% | 2% | 24% |
| Basic cards + one signature card | 5 | 22% | 3% | 31% |

The four-name lists were:

- **Spicy:** 5 Jakapeno, 4 Wastabi, 3 Sriracharrow, 3 Wooden Spoon.
- **Hearty:** 5 French Bread Dog, 4 Macaronatee, 3 Gravy Gazelle, 3 Wooden Spoon.
- **Sweet:** 5 Soft Serve Crab, 4 Choco Bat, 3 Mothchi, 3 Wooden Spoon.

These demonstrate simplicity, not equal power. In particular, three Sriracharrows make Spicy more consistent and stronger despite the reduced complexity.

The five-name fundamentals prototype was identical in structure across affinities:

| Count | Card role | Prototype rules |
|---:|---|---|
| 6 | Basic Ingredient attacker | 2/2, no ability |
| 4 | Basic Ingredient defender | 1/3, no ability |
| 2 | Basic Meal | 4/4, one matching Ingredient, no ability |
| 1 | Identity Meal | Sriracharrow / Gravy Gazelle / Strawberry Sharkcake |
| 2 | Wooden Spoon | Draw one card |

Basic prototype cards existed only in simulator memory and were excluded from reward/shop pools. Four of the five card names have no ability beyond drawing one card; the signature Meal introduces one identity mechanic. This is the direction I recommend for readability and a larger feeling of improvement through rewards. **The exact stats and signature choices are not ready to ship:** Hearty still needs substantial help and the Fresh champion still needs a separate review.

## Suggested next tuning pass

1. Replace automatic rival upgrades with authored lists, prioritizing the Fresh semifinal/final power spike.
2. Build explicit simple starters. Give Hearty reliable early combat stats, meaningful chef-health recovery, and a finisher that can actually close games.
3. Keep 40 life, the one-use 8-life bye, and the current reward reveal counts while retesting those deck changes. Change one global lever at a time.
4. Repair the shop rarity mix; validate immediate usefulness of early rewards; keep optional picks.
5. Compare all three starters under the same automated policies, then watch human first runs before setting a completion-rate target.

## Files and reproduction

- `scripts/cooking/HubBalanceSimulation.gd`: current-hub simulator, equal-seat duels, reward sampling, and isolated starter prototypes.
- `scripts/cooking/run_balance_audit.py`: experiment matrix with independent Godot processes and error rejection.
- `scripts/cooking/summarize_balance_audit.py`: validated aggregates and paired-seed comparisons.
- `outputs/balance_audit_2026-09-04/summary.json`: full aggregate numbers, matchup matrices, and health breakdowns.
- `outputs/balance_audit_2026-09-04/*.jsonl`: individual run/battle records, options, sampled rewards, inventories, and starter lists.
- `outputs/balance_audit_2026-09-04/manifest.json`: source hashes, engine version, checkout revision, and validation notes.

From the project root:

```sh
python3 scripts/cooking/run_balance_audit.py
python3 scripts/cooking/summarize_balance_audit.py
```

Run a smaller selection:

```sh
python3 scripts/cooking/run_balance_audit.py --only=current_all_shop,simple_all_shop,fundamentals_all_shop
```

Validation: RouteRunSmokeTest, RebalancedCardPoolSmokeTest, AiPolicySmokeTest, OpeningTurnDrawSmokeTest, EmptyDeckDrawSmokeTest, and PackRewardSmokeTest all passed. Nine repeated seeded runs matched their original battle, health, reward, and shop records exactly. An initial typing error in the new one-card reward policy was rejected, corrected, and that experiment rerun; only the corrected data is included. Accepted logs contain no script errors or assertion failures.
