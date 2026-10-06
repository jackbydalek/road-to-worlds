# No-generative-AI asset handoff — September 7, 2026

**The game is not ready to be described as having no generated content.** Updated September 8: nine generated PNGs are registered — eight rivals and the newly authorized seven-person title room. Other supplied assets need origin confirmation. The original September 7 screen audit remains a dated comparison; the title now uses the approved room as generated working art, while the hub still needs its visual overhaul.

This checklist covers the current four-round Locals demo and its public marketing. It does not commission Regionals, Nationals, Worlds, a traversable city, or new gameplay content. It is an audit and handoff specification, not a record that replacements have already been integrated.

## Read these together

- [Illustrated reference/current comparison and complete screen gallery](../outputs/next_fest_asset_audit_2026-09-07/visual-review.html).
- [Screen-by-screen findings](../outputs/next_fest_asset_audit_2026-09-07/visual-findings.md).
- [All 87 collectible cards, paths, missing-art status and origin actions](../outputs/next_fest_asset_audit_2026-09-07/card-art-inventory.csv).
- [Detailed card findings](../outputs/next_fest_asset_audit_2026-09-07/card-findings.md).
- [Asset-family provenance audit, exact paths and legacy cleanup](../outputs/next_fest_asset_audit_2026-09-07/provenance-findings.md).
- [Fill-in source/origin handoff sheet](../outputs/next_fest_asset_audit_2026-09-07/asset-origin-handoff.csv).

## What “no gen AI” means for this handoff

Target: **no generative-AI illustration, animation, music, voice or written content in the shipped demo or its public marketing**. AI-assisted programming remains a separate part of development. Reference concepts under `outputs/` stay outside the release package. The September 8 title edit has an explicitly authorized runtime copy under `assets/generated/title/`; it remains generated working art and is an additional replacement target.

The checklist uses three different actions:

- **Replace or remove:** confirmed generated content that cannot remain in that release.
- **Confirm first:** supplied or licensed content whose origin is incompletely documented. This is not evidence that it is generated. Keep it if its human-made origin is established.
- **Finish for presentation:** missing art or an art-direction mismatch. This work improves completeness; a missing illustration is not itself generated content.

The existing UI uses code and editable SVGs. Those were AI-assisted visual designs, not image-generator PNGs. Ordinary layout, outlines, card movement, masking and standard controls can stay as implementation. For the strict content target, a human designer should supply the retained custom illustration, logo, decorative frame and icon masters or use a documented human-made kit. You do **not** need to draw every button, every size, or 87 separate frames.

## 1. Send existing originals and source information first

This is the highest-value first handoff: it can prevent a large amount of unnecessary redrawing.

- [ ] **Mina:** original drawing/animation project or original GIF, creator name, creation method, and permission to use it. The project already has your supplied GIF and decoded frames; do not resend identical exports just to satisfy this list. Its integration used no image generation, but the source's creation method is not yet recorded.
- [ ] **The 62 existing dedicated card artworks:** identify the creator and source files by the IDs in the inventory CSV. A single truthful statement can cover the whole listed family; we do not need 347 individual declarations for the 342 animation frames and five static portraits.
- [ ] **Three player/starter characters:** Spicy, Hearty and Sweet. Supply source/origin information for the existing poses and portraits, or a replacement set. Their current look also differs from the new simple blue-pen character style.
- [ ] **Shop clerk, counter, bye machine and old displayed card back:** confirm their sources even if they will be replaced for visual consistency. Exact paths are in the provenance audit.
- [ ] **Three reward-pack wrappers:** confirm sources or send the new wrapper master described below.
- [ ] **Audio:** provide the original music/sample download links or files with their creator and license. Resolve the renamed music files and Silverdubloons card sounds in section 6.
- [ ] **Any already commissioned replacement artwork:** send what exists, including incomplete layered work; identify what is final and what is a sketch.

For each retained family, include creator, source/project or exact product link, license/commission permission, required credit, and an accurate production-method statement. Disclose any generative step. A filename, “CC0” label, or visual resemblance alone cannot establish origin; reviewing generated pixels does not change how they were made.

## 2. Character replacements and additions

### Confirmed generated rivals

Current files: `assets/generated/peach_soda_opponents/<name>.png`.

| Done | Character | Demo use / action |
| --- | --- | --- |
| [ ] | Pip | Regular-rival mapping: replace if retained. |
| [ ] | Otis | Regular rival and visible tutorial opponent: replace if retained. |
| [ ] | Ines | Regular rival; visible in the audited introduction screen. |
| [ ] | Sana | Regular-rival mapping: replace if retained. |
| [ ] | Milo | Regular-rival mapping: replace if retained. |
| [ ] | Kit | Regular-rival mapping: replace if retained. |
| [ ] | Ellis | Champion/final-rival presentation: replace if retained. |
| [ ] | Bea | Registered and export-eligible; not found in the normal regular-rival pool. First choice is to remove unused registration/art rather than commission a replacement solely for this demo. |

Eight generated files need a deliberate disposition; that does not automatically mean eight new full character sheets. Keeping current regular-rival variety requires seven replacement neutrals after cutting Bea. A smaller cast would also require encounter-mapping changes and explicit scope agreement.

**Minimum per retained rival:** one human-drawn seated neutral cutout, a separate front-fingers/hand layer, and a face crop that can be derived from the same drawing. Face toward the player, forearms at the table, plain transparent space for live cards. Do not paint a permanent fan of cards into the hands.

**Matching current import geometry:** 1448 × 1200 RGBA, arm/table baseline y=1000; current portrait crop x=345, y=0, width=758, height=758. Keep every pose aligned. Kit's hand can extend below the baseline. These are runtime anchors, not a requirement to copy generated anatomy.

- [ ] Optional smile face for each retained rival, on a replaceable head/face layer where practical.
- [ ] Optional hurt/disappointed face for each retained rival, on the same canvas and baseline.
- [ ] Optional two or three intentionally redrawn line-boil frames after neutral coverage is complete. Motion is polish, not required to remove AI art.

### Supplied and player characters

- [ ] **Mina:** keep existing artwork if source confirmation succeeds. Current cropped canvas is 701 × 628; arm baseline y=610, face crop 130,90,335,335. Six 70 ms frames contain two distinct poses. More expressions are optional; a new idle is not automatically needed.
- [ ] **Clerk:** one counter-ready pose matching the approved bob haircut/teal cardigan and simple blue-pen face. Reuse the same character design as Mina if intended, with a useful counter pose; do not retain the currently different curly-haired olive-jacket seller by accident. Separate hands from held stock.
- [ ] **Spicy player:** neutral + existing victory equivalent if redrawing; derive the small portrait from the neutral art.
- [ ] **Hearty player:** same two-pose handoff if redrawing.
- [ ] **Sweet player:** neutral is sufficient for current behavior; a separate victory pose is optional.

The current Spicy/Hearty neutral and victory canvases are 592 × 941; Sweet is 764 × 1224. We can adapt imports from a consistent larger master. No walking, running, back-view or combat attack cycles are needed for the present menu-and-table demo.

## 3. One coherent environment pack, reused across the three main screens

Use the [approved room](../outputs/locals_screen_concepts/peach_soda_line_boil_room_v1/shop-room.png) as the composition and drawing authority. Supporting title/shop/battle concepts are comparison targets; their invented card art, rules or numbers do not supersede the real game data.

Keep the warm paper, peach, teal and restrained mint palette, visibly blue irregular pen contours, simple faces and flat fills. Original card pixels and exact affiliation identities remain independent of the environment palette. Strong blue drawing edges do not require turning readable UI text bright blue.

### Layered hub room

- [ ] **Room shell:** rear/side walls, warm floor and open central aisle.
- [ ] **Windows/outside foliage:** separable window frame, exterior shapes and interior edge so parallax does not expose holes.
- [ ] **Left merchandise shelves:** binder rows, card/product silhouettes and sparse shelf detail. Real display-card contents remain live game cards.
- [ ] **Left counter and glass singles case:** separate counter/base, dark teal case interior, transparent glass/front highlights and foreground lip. Leave clear locations for the real four offers and price labels.
- [ ] **Central bracket board:** frame, blank bracket paper and pins. Names/progress remain live text and marks.
- [ ] **Central teal bye machine:** shell and separate screen/status area. We supply Heal, Upgrade and OUT OF ORDER overlays; do not bake those words into the painting.
- [ ] **Window tables, chairs and foreground table:** separated foreground edges so seated characters can sit behind them.
- [ ] **Plant/lighting/prop kit:** a few reusable potted/trailing plants, hanging lamp, deck boxes, cup, scorepad, backpack and foreground binders. Deliver only the variants actually visible in the approved views.
- [ ] **Room people:** six background/customer figures plus the clerk to achieve the approved occupied-shop composition: standing backpack customer, two window-table players, three foreground-table players. Reuse approved cast designs and body layers where useful; these are six placements, not a demand for six additional rival identities.

Minimum is still layered art. Character line-boil, plant sway and drifting dust can wait. Avoid a flattened painted screen with UI and cards already embedded in it.

### Title composition

- [ ] **Replace the generated title room:** human-made layered version of the approved seven-person shop composition, matching `outputs/lineless_art_implementation_2026-09-11/title/01-lineless-room-ai.png`. Current runtime replacement target: `assets/generated/title/locals_room_lineless_ink_people_ai.png` (1584 × 993 RGB), consumed by `scripts/ui/TitleMenu.gd`. Preserve navy ink on the seven people and held cards, lineless furniture/backgrounds, Peach Soda fills, visible faces, the blank upper-central board for the native wordmark and open aisle for live menu controls. People have no white exterior rim. Room, people and prop pixels all require human-made replacement; a contour edit does not remove the AI origin.
- [ ] **Separate hero/foreground props:** use the same character, sleeve, cup and room kit where possible.
- [ ] **Human-authored wordmark:** “See You at Locals” (the name selected September 8), with the friendly blue-pen lettering; transparent export plus editable original.
- [ ] **Square identity mark:** can be derived from the same human-made logo system.

This needs one coherent title composition, not a separately painted bitmap for Continue, New Run, Settings and every hover.

Setting `TitleMenu.use_generated_title_art=false` restores the native fallback,
but a no-AI package must also retire/exclude the generated PNG and its import,
update the active manifest and preserve its old hash. The optional
`scripts/release/check_no_ai_assets.sh --require-no-generated` gate must fail
until all nine registered generated assets are replaced/removed and retained
source provenance is confirmed.

### Shop close-up and battle view

- [ ] **Shop counter close-up layout/art:** enough resolution and full counter edges to frame the clerk above a real glass case containing four live cards. Reuse the hub case materials and clerk. A crop is fine only if it preserves those elements at the actual camera angle.
- [ ] **Battle background plate/layers:** the same shop seen across the table; shelf/window/board context leaves space for the seated rival and side scorecards.
- [ ] **Peach tabletop surface and edges:** clear separation between the two playmats.
- [ ] **One human-made mat print master:** three Prep, two Plated, deck, discard and environment areas. The second mat is a separately positioned reuse. Keep functional labels as stable live text when possible.

**Production format:** layered PSD, Procreate, Krita or equivalent; sRGB; transparent PNG exports for isolated layers; shared canvas/origin for environment layers. Suggested working master 3200 × 2000 (16:10), composed to also survive a centered 16:9 crop. This is a production recommendation, not an existing engine constraint. I still need to supply final camera overlays, UI safe areas and named layer templates before you commit to finished full-scene exports.

## 4. Card artwork: 25 missing collectibles + one shared token

**62 of the 87 cards have dedicated art.** Keep confirmed original art. Switchblade already has an animation. Pudding Puma points to `art_pending.png` and is still missing. All 25 below are eligible in at least one current starter ecosystem, so none can be assumed unreachable.

These are completion requests, not 25 confirmed generated-art replacements. A deliberately human-made placeholder can meet the origin target; finished artwork is the stronger Next Fest presentation. Cutting a card requires pool/deck checks by me first.

| Done | Card | ID | Kind |
| --- | --- | --- | --- |
| [ ] | Feta Ferret | `funky_fondue_ferret` | Ingredient |
| [ ] | Arrabbeta | `spicy_funky_arrabbeta` | Ingredient |
| [ ] | Jambaye-aye | `spicy_funky_jambaye_aye` | Meal |
| [ ] | Relishoon | `spicy_funky_relishoon` | Meal |
| [ ] | Pika-le | `funky_sweet_pika_le` | Meal |
| [ ] | Pudding Puma | `sweet_pudding_puma` | Meal |
| [ ] | Yolke Bowl | `fresh_spicy_yolke_bowl` | Meal |
| [ ] | Hot Sauchuar | `spicy_hot_sauchuar` | Meal |
| [ ] | Chef Gusteau | `chef_gusteau` | Chef |
| [ ] | Chef Brown | `chef_brown` | Chef |
| [ ] | Chef Duff | `chef_duff` | Chef |
| [ ] | Chef Emril | `chef_emril` | Chef |
| [ ] | Fresh Shopping List | `item_fresh_shopping_list` | Tool |
| [ ] | Funky Shopping List | `item_funky_shopping_list` | Tool |
| [ ] | Blow Torch | `item_blow_torch` | Tool |
| [ ] | spicy taquería | `environment_spicy_taqueria` | Environment |
| [ ] | hearty diner | `environment_hearty_diner` | Environment |
| [ ] | sweet bakery | `environment_sweet_bakery` | Environment |
| [ ] | Funky Pickle Stand | `environment_funky_pickle_stand` | Environment |
| [ ] | fresh greensweet | `environment_fresh_greensweet` | Environment |
| [ ] | Cayenne Crunch | `spice_cayenne_crunch` | Spice |
| [ ] | Savory Gravy | `spice_savory_gravy` | Spice |
| [ ] | Sugar Glaze | `spice_sugar_glaze` | Spice |
| [ ] | Funky Brine | `spice_funky_brine` | Spice |
| [ ] | Fresh Balsamic | `spice_fresh_balsamic` | Spice |
| [ ] | Fresh Ingredient Token | `token_fresh_ingredient` | Shared internal 1/1 token; outside the 87 |

The token is used by several cards; one illustration covers it. Current environment text calls it “Leafy Hampster,” so resolve that name before drawing.

**Per card:** one 4:3 sRGB PNG, at least 512 × 384, editable source, no baked frame/name/rules/stats/badge. Transparent background for creatures, chefs and isolated objects; environment cards may have a complete illustration plate. Keep the subject comfortably inside the canvas. Existing animations are six 70 ms frames, but static art is sufficient for this handoff. I will adapt static art to floating table cutouts; you do not need to manufacture six duplicate files.

## 5. Reusable frames, sleeves, UI and packs

One small human-authored design kit can cover the game's custom decorative graphics. Keep licensed symbols/fonts where their source is documented. Standard controls, live typography, rendering and layout remain my work.

- [ ] **One folded-ribbon card-frame system:** outer stock, title/rules panels, ribbon with swallowtail ends and folds, circular affiliation seal, stat tabs, and the two-row Meal recipe variant. Supply editable masters or a precise human-made design sheet; I implement reusable geometry and size/state variants.
- [ ] Preserve the current warm-gray art backing so white floating-art outlines remain visible. Keep exact affiliation colors on badges/recipe symbols and softer affiliation tints on broad ribbons. No repainting existing card art.
- [ ] **One final card-back/sleeve master** to replace the different battle and hub-stock backs; derive deck stacks and held cards from it.
- [ ] **One paper panel/button visual family** or a documented licensed kit: normal, hover, pressed, selected/focused and disabled specifications. Include a modal/panel edge and small paper tab. You do not draw each screen's buttons.
- [ ] **Five control families:** checkbox, radio, toggle, slider knob and dropdown chevron. On/off for the first three gives eight basic marks; disabled/focus variants can be derived in code.
- [ ] **Five battle symbols** if retaining custom marks: play, ability, attack, move and spice. Documented licensed replacements are also fine.
- [ ] **Small combat decoration set:** heart/life mark, stat badge, ready marker/sparkles, play/meal/taunt markers. Existing custom SVGs are listed in the provenance report. A few master shapes can cover these roles; the white outline and target highlighting can remain ordinary rendering.
- [ ] **One hand-drawn pack-wrapper master + three stamps/variants:** regular reward, miniboss reward and champion reward. Current files are 1086 × 1448. Avoid the current glossy gradient pouch; use the flat blue-pen/paper treatment. No separate painting for every reveal card.

A new “no AI” icon is not needed. The provenance record and final package should support the claim.

## 6. Audio and visible writing

- [ ] **Map three music files:** `intro.mp3`, `shop.mp3`, `combat.mp3` to their actual creator/source. Credits currently name two PWLPL tracks; the three renamed files need a clear mapping. If those sources cannot meet the target, obtain human-made menu, shop and battle cues. These may share a composition and need not be three expensive unrelated tracks.
- [ ] **Card handling sounds:** source/license/method for the 20 Silverdubloons WAVs, or real recordings covering pickup, drop, slide and shuffle. A few good variations per action are enough; copying today's exact 20-file count is unnecessary.
- [ ] **Five standalone combat/magic cues:** verify the DRAGON-STUDIO summon, Yodguard ability, Universfield/Virtual_Vibes impacts and supplied Ryusa sparkle file. Keep documented human-made recordings; replace only unresolved or generated material.
- [ ] **Retain licensed UI/pack sounds** from Case Portman and Kenney with their source records. These already have local license evidence; do not rerecord everything merely because it is third-party.
- [ ] **Final authored text:** identify original human-written card names/rules/flavor and rival dialogue; supply a human-written final version wherever prose was generated. Cover tutorials, room signs, menu descriptions, store copy and trailer captions too. Review must preserve actual mechanics; simply approving generated prose does not make its origin human.

No voice-over files or localization catalog were found in this audit, so neither is a required new deliverable. I will extract the displayed-copy review sheet during implementation; you should not search through game scripts yourself.

## 7. Steam/public presentation

- [ ] **One human-made high-resolution key-art composition**, ideally layered, with room to rearrange/crop the characters and lettering. Reuse the approved final cast and environment art. It can supply multiple capsule formats; these are exports, not eight unrelated new paintings.
- [ ] **Separate transparent wordmark/logo**, reused from the game identity.
- [ ] **Store capsules:** header 920 × 430; small 462 × 174; main 1232 × 706; vertical 748 × 896. Keep the title legible at small size. [Valve store-asset specifications](https://partner.steamgames.com/doc/store/assets/standard).
- [ ] **Library assets:** capsule 600 × 900; hero 3840 × 1240 without text; transparent logo up to 1280 wide and/or 720 tall while retaining its aspect ratio; library header 920 × 430 can reuse the store header. [Valve library specifications](https://partner.steamgames.com/doc/store/assets/libraryassets).
- [ ] **App/icon source:** square master for app icon 184 × 184 JPG and shortcut 256 × 256 or 512 × 512 PNG/ICO. [Valve icon specifications](https://partner.steamgames.com/doc/store/assets/community).
- [ ] **Human-authored store text and any trailer captions/music** with origins documented.

I capture the actual final gameplay screenshots and trailer footage after integration. You do not need to paint screenshots. Steam asks for at least five gameplay screenshots at least 1920 × 1080; this audit's smaller fixture captures are review evidence, not the final store gallery. [Valve screenshot requirements](https://partner.steamgames.com/doc/store/assets/standard). Generated concept art must not be presented as a gameplay screenshot or retained in the final capsule by cropping it.

## 8. What I own after the handoff

- [ ] Provide camera guides, layer names, safe areas and import templates before finished scene art is commissioned.
- [ ] Rebuild hub composition: counter left, bracket/machine center, occupied window/foreground tables, open aisle.
- [ ] Build the character-led title and reframe the case so the seller remains visible above the cards.
- [ ] Integrate authored layers, character poses, portrait crops and live hand/finger masking; preserve the actual draw/play events.
- [ ] Bring illustration contours to the approved blue pen and improve slot/stat readability at 1280 × 720; preserve readable text and semantic UI colors.
- [ ] Keep two mats, original card art, affiliation identities, restored ribbons, gray art backing and white cutout outlines.
- [ ] Integrate the 25 card artworks and shared token, including the static-art adapter; verify every starter ecosystem's reward/shop pools.
- [ ] Reuse the human-made UI kit across settings, starter selection, deck, shop, rewards, results and tutorial; keep hit areas and text stable.
- [ ] Fix tutorial copy/style against the intended current run rules; its welcome still says 20 life and refill to two.
- [ ] Remove or replace the eight generated registrations and files; exclude retired AI artwork and imports from every export. Keep historical provenance in excluded development records.
- [ ] Prove unused legacy content is unreachable and exclude it. That includes old concepts, town walk sprites, older shop/battle assets, unused packs/frames/route icons and spare card animation files. You are not being asked to redraw retired screens.
- [ ] Map licenses and creator evidence, update credits and the manifest honestly, then require the opt-in `--require-no-generated` gate for the no-AI release. The default working-art audit explicitly permits the nine registered assets; a passing default audit is not a no-AI certificate. Confirm the owner/source attestation only after the retained-source handoff is complete.
- [ ] Inspect the final exported package, including unused resources and audio; run the release checks and a complete playthrough. Hash checks alone cannot detect cropped or re-encoded generated art.
- [ ] Capture final gameplay/store media and replace old public visuals only when authorized to publish.

## 9. What to send this week, in order

1. **First:** source/origin information for Mina, existing cards, players and audio, plus any layered art already available. Name the artist and realistic drawing capacity.
2. **Next:** one finished blue-pen room sample (counter corner plus one plant/prop) and one seated rival neutral with separated hand. These establish line thickness, flat fills, face style and import behavior before multiplying the work.
3. **Then:** first layered hub/case pass and the remaining retained rival neutrals. Reuse that room kit for battle and title as soon as the camera guides are agreed.
4. **Alongside that:** fill the missing cards according to actual deck/reward priority, and provide one frame/sleeve/pack master for reuse.
5. **After in-game review:** expressions, line-boil, extra room gestures and Steam key-art adaptations.

This is the full remaining asset checklist, not a claim that all drawings fit into one week. The shortest route is to confirm existing human work, reuse one coherent kit, and remove unused content deliberately.

## Completion evidence

- [ ] Every shipping content family has creator/source/process/rights information; no pending origin is silently marked human-made.
- [ ] No generated file or derivative remains in the exported demo or final public media.
- [ ] Actual title, hub/case and battle visibly match the approved composition and blue-pen treatment.
- [ ] Every obtainable card has final art or an explicitly accepted human-made placeholder; the internal token renders correctly.
- [ ] Current controls, card information and 720p readability survive the art replacement.

Audit coverage: 43 native Godot captures, comprising 21 screen/state views at 1440 × 900 and 1280 × 720 plus a six-card frame sheet. These use controlled run/battle fixtures and Reduced Motion. This was not a Steam install, full release-gate run, final export inspection, complete gameplay regression, or animation review. See the capture manifest for exact files and methods.
