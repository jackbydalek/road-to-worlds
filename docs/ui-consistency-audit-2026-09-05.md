# UI consistency audit — September 5, 2026

The next pass should make the game easier to read and operate from screen to screen. The current room, character art, card faces, and cool neutral palette provide the identity. The biggest remaining gains are predictable controls, fewer competing frames, readable decision information, and completing the migration of older menus.

This audit follows `ART_DIRECTION.md` and `CONCEPT_DIRECTION.md`. The active campaign presentation is the four-round Locals hub with persistent health and a locked deck that grows through rewards and services. Retained calendar, draft, and shop scenes are migration considerations; they should not determine the campaign direction.

## Completed in this pass

1. Results show the player's character and three cards actually present in the finished deck, with copy counts. These are deck examples, not invented “most played” cards.
2. The main result heading explains progress, such as **Reached the Locals Final**, with the final rival below it.
3. Recap rows use simple surfaces and separators. Major sections retain the angular silhouette without repeating it around every row.
4. The player and deck sit on the left, the recap scrolls independently on the right, and the action bar stays visible. Finished decks can be reviewed without changing them.
5. Battle, route rewards, the counter shop, deck review, and revealed legacy pack cards share a 320 × 454 inspection face and the same keyword explanations. Hover/focus previews and right-click / I inspection use consistent framing. Escape restores focus. Combat inspection preserves current stats; deck inspection preserves the selected copy's upgrade.

New route match history records the actual rival, round, result, turn, remaining life, and awarded cash. Duplicate result callbacks do not add duplicate history. Older saves without history explain the missing data instead of inventing a record, earnings, or match order.

The inspection pass also corrected upgraded deck copies that previously showed foil with base stats. They now use the upgraded card data. Reduced discard costs are reflected in the rules text, including upgrades that make a card free to play.

## Recommended next changes, in order

| Priority | Change | Concrete implementation and benefit |
|---|---|---|
| 1 | One navigation and modal system | Use the same Back position, Close behavior, Escape handling, focus restoration, scroll area, and pinned action bar across screens. Keep one clear primary action. Start with the starter deck popup, shop service picker, and deck screen. A player should not have to hunt for the exit or lose the action below a long list. |
| 2 | Explain battle actions at the point of use | Add short labels beside Attack, Move, Play, and Defend icons. Show why an action is unavailable and preview the known result when aiming at a legal target: damage, unit survival, Chef overflow, and Bodyguard prevention. Use the combat service's calculations and preserve hidden information. The existing target outlines remain useful; labels and outcomes make them easier to understand. |
| 3 | Make card decisions easier | Add “Owned ×2” and the resulting deck size to rewards and shop inspection. Upgrade inspection should show the current card beside the upgraded version with the exact changes highlighted. Removal should identify the copy and resulting deck count before confirmation. Keep these details near the card and confirm control. |
| 4 | Reduce redundant framing everywhere | Keep one structural outline per major region. Remove the extra tall box around each card in the deck grid, nested outlines in service pickers, and repeated cyan bars on inactive sections. Preserve light content surfaces where useful: consistency does not require making the title and settings entirely dark. |
| 5 | A readable, scalable type system | Consolidate the many local 11–13 px hints into shared typography roles. Aim for 16–18 px decision copy and 14 px secondary text at the 1440 × 900 design size. Apply text-size settings to shared components and reflow the layout instead of shrinking everything. Continue using Oxanium for headings and Atkinson for body copy. |
| 6 | A useful deck browser | Add search, card-type and keyword filters, sorting, and an optional grouped view. Show duplicate counts while keeping upgraded and ordinary copies distinguishable. Keep a clear “locked during the run” explanation and the shop removal route. A bigger deck should be easier to understand, not just a longer grid. |
| 7 | Consistent action and feedback states | Blue for navigation/current selection, cyan for focus, green for a valid confirmation, red for danger, yellow for money/rewards. Pair important colors with text or a symbol. Standardize Selected, Bought, Added, Upgraded, Sold Out, Already Used, and Can't Afford states; put the cost or reason next to the affected control. A brief confirmation should visibly connect the card to the deck count or money change. |
| 8 | Finish the older screens and unify motion | Migrate the starter deck popup first, then any retained draft/finale screens that remain reachable. Use shared short hover/press/selection timings, deliberate scene transitions, and reduced-motion alternatives. Preserve the room-to-counter zoom and the world's illustrated character. Keep save/progress feedback quiet and consistent. |

## Screen-by-screen application

The captures below were rendered from current code with deterministic fixtures at 1440 × 900. They show layout and interaction states, not a claim that the fixture completed a real run. The card-inspection/result checks additionally cover 1280 × 720, 1920 × 1080, and 1728 × 1117.

| Screen | Current observation | Next improvement |
|---|---|---|
| Title | Strong logo, cool-white background, clear three-action stack. | Keep the composition. Show a concise saved-run summary with Continue when applicable; use the same focus language and settings placement as the rest of the shell. |
| Starter selection | Strong character silhouettes; small playstyle captions; characters are very dark before selection. | Keep faces brighter, enlarge the playstyle explanation, and show three representative starter cards in the selected detail area. Remove the doubled Back frame. |
| Starter deck popup | Cream/lavender rounded panels, emoji classification, a separate older hover preview, and a subtle scroll boundary. | Reuse the current deck-list and inspection components; provide a visible scroll affordance, common Close control, and keyboard navigation. |
| Locals hub | Room interactions, persistent status, and Next Round are readable. Round progress also appears on the tournament board. | Keep this as the campaign anchor. Make the top bar the status reference; let the board carry rival and round details. Use a brief “Shop restocked” confirmation after wins and concise previews of bye consequences. |
| Counter shop | Same-room zoom and inspection preserve context. | Put affordability, owned count, and purchase result beside the selected card. Apply the same inspector to removal and upgrade choices. |
| Rewards | The repaired footer stays visible, with the card area scrolling when needed. | Add deck context beside a selected card and show the remaining count near the footer. Prefer fewer instructions above the cards. Keep Add All / Skip easy to reach. |
| Upgrade/removal | Pinned confirmation works; many small cards show textual upgrade deltas. There are nested structural outlines. | Show a selected card's before/after comparison at reading size, simplify framing, and name the affected copy on confirmation. |
| Deck | Every physical copy is visible and inspectable, but each card sits inside another large framed tile. | Remove redundant tile frames, offer grouped copies/search/filtering, and keep total count and locked status in a compact header. |
| Battle | Enlarged card and keyword guide now agree with menus; live stats are preserved. Action buttons are mostly pictograms. | Add action labels, immediate explanations for unavailable actions, and accurate target-result previews. Keep board zones and health readable while inspection is open. |
| Tutorial | Uses the battle inspector and passes the small-window action visibility check. | Teach one action with a label and direct visual target; make the same hint available later without replaying the tutorial. |
| Settings | Cool-white content and dark controls fit the direction. Many nested frames and a prominent red Abandon Run button compete with routine settings. | Simplify rows, use a clear On/Off state for toggles, preserve the selected category, and move Abandon Run into a quieter run-management area while retaining its confirmation. |
| Season ended | Progress, personal deck, real record, and fixed actions now form a clear hierarchy. | Reuse this composition for campaign wins and future floors; add run highlights only when the game actually records them. |
| Current route victory | Uses production colors and the winning pose, but the character is small inside a large empty frame; community action dominates. | Lead with the championship and winning deck, enlarge the victory pose, and put Play Again / Review Deck ahead of community links. Keep progress terminology consistent with the hub. |
| Retained draft / old finale / old pack shop | Draft and the old finale still have visibly pastel layouts and older typography. Legacy packs now share inspection but retain their older shell. | Confirm which entries remain reachable, then migrate those complete flows. Do not restore the legacy calendar or progression just to reuse its UI. |

## Implementation starting points

- Shared primitives and tokens: `scripts/ui/TopdeckUIComponents.gd`, `scripts/ui/GamePalette.gd`.
- Shared reading interaction: `scripts/ui/CardInspectionContent.gd`, `scripts/ui/CardInspectionOverlay.gd`, `scripts/ui/CardHoverPreview.gd`.
- Navigation, results, starter popup, service overlays, and retained finale: `scripts/Main.gd`.
- Current room and shop: `scripts/ui/TournamentHubScreen.gd`, `scripts/ui/HubCounterShopView.gd`.
- Starter selection, deck, and battle: `scripts/ui/SeasonSetupMenu.gd`, `scripts/DeckbuilderScreen.gd`, `scripts/Tabletop3DPrototype.gd`.

The highest-return implementation sequence is shared navigation/type/state primitives, battle action clarity, deck and shop decision tools, then the remaining reachable legacy screens. Validate the complete journey after each group so individual screens stay consistent.

## Verification and references

Passed targeted checks: shared card inspection (rendered and headless), result layout and actions, deckbuilder layout, responsive layout at 100%/125% text settings, battle pacing/keyword guide, route campaign flow, counter zoom/purchase/removal, shop restock/history persistence, and pack reward generation. The new inspection check is included in the demo release gate. This pass did not run a full export or the entire release gate. Godot reported exit-time ObjectDB leak warnings in some scene tests; no failed assertions remained.

- Results: `outputs/ui_consistency_route_results.png`
- Final deck: `outputs/ui_consistency_final_deck.png`
- Battle actions/guide: `outputs/inspection_battle_actions.png`
- Card inspection: `outputs/inspection_reward_1280x720.png`, `outputs/inspection_shop.png`, `outputs/inspection_deck.png`
- Screen reference set: `outputs/ui_audit_*.png`
- Reproduce references: `scripts/UiConsistencyPreviewCapture.gd -- --public`
- Reproduce interactive inspection checks: `scripts/SharedCardInspectionSmokeTest.gd -- --public`
