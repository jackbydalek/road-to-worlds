# Tournament-room production pass

The main room now presents a complete local card club: a street-facing window,
wall panelling, product shelves, pendant lights, a branded sign, a live tournament
board, an empty card table, plants, and grounded furniture shadows. The two players
behind the right-hand table have been removed.
The existing shopkeeper, counter, and vending machine remain in use. New scenery is code-drawn SVG, with source notes beside the assets.

The cool HUD and match-action footer stay at the window edges. Taller 16:10
windows reveal more foreground floor. Browse Cards moves the camera into the actual glass display over 0.72 seconds,
with prices and purchase controls aligned to its cards. Returning pulls back
into the same room. Critically damped pointer motion gives consistent settling
at different frame rates and smooth direction changes. Reduced motion skips
the zoom and clears parallax. Empty stock, full health, and used-bye states
have deliberate presentation. Saves produce a visible receipt in the hub.

Interaction fixes made while testing:

- Decorative layers no longer intercept clicks on the room.
- Rapid shop returns cannot rename the live hub accidentally while its previous
  instance is queued for deletion.
- Consuming a focused bye action moves keyboard focus to Next Round.
- Re-enabled buttons regain their normal text/icon contrast.
- Reduced motion immediately clears all parallax offsets.

The shopkeeper also offers **Remove Card · $3**. The picker previews one copy
and requires selection and confirmation; cancellation costs nothing. Removal
is once per floor, preserves at least one card, and does not consume the bye.
Deck, funds, stock, and the used service persist in the save. An empty display
retains a Visit Counter action so the shopkeeper remains accessible.
The four card offers now refresh after every win, including sold-out stock.
The victory autosave stores those offers; revisiting, buying, finishing rewards,
and reloading do not reroll them. Restocking preserves the used removal and bye.

## Verification

Passed on Godot 4.6.3:

- `TournamentHubSmokeTest.gd`, headless and rendered. Checks real display clicks,
  saved stock and purchases, empty inventory, healing exactly eight once,
  upgrade/cancel behavior, save/load feedback, Settings return, next-round entry,
  focus traversal, full-life/re-enabled button states, and reduced motion.
- Rendered layout checks at 1280×720, 1440×900, and 1920×1080. Interactive controls
  remain in bounds and at least 44 physical pixels high; HUD/footer stay pinned.
- `HubCounterZoomSmokeTest.gd`, headless and rendered: intermediate zoom frames,
  same-room identity, frame-rate-independent parallax, reversal, reduced-motion
  changes during a transition, real click inspection/purchase/removal, cancel
  and keyboard focus, $3/once-per-floor/minimum-deck guards, save contents,
  Settings return, empty stock, and counter bounds at all three resolutions.
- `HubShopRefreshSmokeTest.gd`: all four Locals wins restock, sold-out/partial
  stock refills, purchases and reloads preserve stock, victory autosaves include
  the offers, duplicate results and losses do not restock, starter restrictions
  remain valid, and the used removal/bye stay consumed.
- `RouteCampaignFlowSmokeTest.gd`, including hub → shop → rival → battle and the
  existing campaign completion flow.
- `TournamentHubVisualCapture.gd`: seven inspected captures covering three
  resolutions, display hover, keyboard focus, full health, and used bye/sold out.
- `check_no_ai_assets.sh --audit-known` and `git diff --check`.

The hub and counter smoke tests are now included in the demo gate. The full demo-release gate
was not run as part of this room pass; the project's existing owner-provenance
attestation and unrelated full-game release checks remain separate.

## Review files

- `outputs/room_polish_1280x720.png`
- `outputs/room_polish_1440x900.png`
- `outputs/room_polish_1920x1080.png`
- `outputs/room_polish_display_hover.png`
- `outputs/room_polish_keyboard_focus.png`
- `outputs/room_polish_full_health.png`
- `outputs/room_polish_used_bye.png`

Current counter review captures (inspected after the zoom/removal pass):

- `outputs/hub_counter_room.png`
- `outputs/hub_counter_mid_zoom.png`
- `outputs/hub_counter_1280x720.png`
- `outputs/hub_counter_1440x900.png`
- `outputs/hub_counter_1920x1080.png`
- `outputs/hub_counter_inspect.png`
- `outputs/hub_counter_purchased.png`
- `outputs/hub_counter_removal.png`
- `outputs/hub_counter_sold_out.png`
