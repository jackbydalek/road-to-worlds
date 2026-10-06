# Cozy sound pass — September 8, 2026

All eight choices in the owner's `locals-sound-choices.json` export
(`2026-09-08T22:31:48.235Z`) are now applied at their auditioned gains. Seven
mappings changed; the chosen four-recording card-placement pool stays intact.
The original export is preserved at
`assets/audio/cozy_sources/selected_choices_2026-09-08.json`. The applied action,
resource, gain and SHA-256 map is recorded in
`assets/audio/cozy_sources/selection_application_2026-09-08.json`.

The owner supplied Case Portman's full **Cute & Cozy UI Audio Pack**, Kenney
**Casino Audio 1.1** and **Impact Sounds 1.0**, and requested the original shop
bell from an older build. These selected recordings retain their original bytes.
Button clicks, draws, combat hits, abilities, healing and purchases play at their
original pitch to match the audition. The four card-placement variants retain
their existing handling behavior.

Hits play at contact rather than the start of the lunge. Effect/reaction damage
keeps its medium wooden recordings at −6 dB. Picking up an existing card retains
`card-slide-4` (0.459 seconds); drawing now uses the explicitly selected
`card-slide-1` (0.601 seconds). The selected ability recording is 0.831 seconds;
its reusable voice lets it finish without restarting or layering duplicate tails.
Deck-count clicks and generic search events do not trigger a shuffle. The full
shuffle is exclusive to a real reshuffle, with a 3.2-second cooldown.

No audio was generated. Music, gameplay balance and Steam were not changed.
The supplied **Kenney Board Game Icons** folder is not audio and was not imported.

## Sources and provenance

- Case Portman recordings: `assets/audio/ui/cute_cozy_full/`. The included
  `license.txt` permits royalty-free personal/commercial project use and edits,
  with no credit required. It permits distribution within the game, but forbids
  standalone raw-file distribution, resale or repackaging as a sound/asset
  collection, and claiming authorship of the original recordings.
- Kenney recordings: `assets/audio/kenney_casino/` and
  `assets/audio/kenney_impacts/`. Both supplied licenses are CC0 and preserved as
  `assets/audio/cozy_sources/kenney_casino_LICENSE.txt` and
  `assets/audio/cozy_sources/kenney_impacts_LICENSE.txt`.
- `assets/audio/cozy_sources/import_manifest.json` records original owner-supplied
  paths, imported destination paths and SHA-256 hashes. The imported recordings
  were copied byte-for-byte; gain and small pitch variation are runtime settings.
- `assets/audio/shop_door_bell_squeak.wav` is the unchanged original recording
  restored from the older `f999e7d` release. Creator and license provenance remain
  unresolved. The restored file has not acquired a license or authorship claim
  merely because it was present in an earlier release.

The old free UI sample, Silverdubloons card sounds, glass effects, epic summon,
Healing Magic activation, Ground/Thud attacks and Ryusa buff sparkle are legacy
sources replaced in the current shared UI/battle routing. Existing files and
attribution history are retained. “Unused by current routing” does not mean
removed from the repository or excluded from every export.

## Current cue map

Gain values below are per-player runtime attenuation in dB, before the user's
SFX/master settings. They are not measured perceived loudness.

| Interaction | Recording / family | Gain / behavior |
| --- | --- | --- |
| Hover and keyboard navigation | Cute & Cozy `Highlight_02` | −27 dB; throttled and deduplicated; automatic/restored focus is silent |
| Buttons | `Clicked_In_01` | −15 dB; exact selected clip, fixed pitch |
| Toggles and sliders | `Clicked_In_02`, `Clicked_Out_03` | −15 dB; slider ticks −23 dB |
| Screen transitions | `Transition_03/04` | −20 dB; 180 ms cooldown |
| Popups, confirm, cancel | `Menu_Open_02`, `Menu_Close_02`, `Confirm_01`, `Cancel_02/03` | −17 to −19 dB |
| Purchase / remove card | `Purchase_01` / `Sell_04` | −16 / −17 dB; successful committed action only |
| Upgrade / heal | `Level_Up_04` / `Dialogue_Expression_Positive_01` | −17 / −14 dB; successful committed action only |
| Win / loss | `Success_04` / `Failure_08` | −15 dB |
| Shop focus | `Menu_Open_02`; clerk uses `Dialogue_Expression_Neutral_02` | One quiet cue at −21 dB |
| Shop entry | Original `shop_door_bell_squeak.wav` | −14 dB; unchanged full recording and pitch; entry only, eight-second retrigger guard |
| Card handling | Kenney place and slide recordings; pickup uses `card-slide-4` | −18 dB; single-card handling |
| Drawing a card | Kenney `card-slide-1` | −20 dB; only when a visible card transfer starts |
| Deck reshuffle | Kenney `card-shuffle` | −18 dB; real reshuffle only; 3.2-second cooldown |
| Ordinary combat hit | Kenney `impactPunch_medium_000` | −5 dB; plays at contact, including Stalwart bypass attacks |
| Meal attacking Chef | Kenney `impactPunch_heavy_000` | −3 dB; plays at contact |
| Effect damage / reaction impact | Kenney medium wooden taps | −6 dB; effect hits throttled within clustered events |
| Meal served | `Confirm_02` | −14 dB; existing 0.44-second landing synchronization preserved |
| Ability activation | `Confirm_05` | −18 dB; 220 ms cooldown plus single-voice tail protection |
| Battle healing | `Dialogue_Expression_Positive_01` | −14 dB; 350 ms cooldown |
| Battle buffs | `Unlock_02` | −14 dB; separate 350 ms cooldown so a buff does not suppress healing |
| Unit removal / turn change | `Cancel_03` / quiet `Menu_Open` cue | Short feedback; grouped effects avoid stacking |
| Pack opening | Kenney `cards-pack-open` recordings | −12 dB; separate cosmetic RNG |

`UiSoundController.gd` skips disabled/hidden controls and caps simultaneous
interface voices at six. Hover and slider cues cannot steal another voice; busy
interface actions do not cut off the original shop bell. Disabling UI sound
stops its current voices. All interface cues use the SFX bus. UI, battle and pack
variation use separate cosmetic random generators so sound playback does not
advance the game's random sequence.

`Main.gd` connects the shared APIs to committed purchases, removal, upgrades,
healing, match results, shop focus and entry-only bell playback. This document
records those integrations separately from their validation status below.

## Validation

The five audio checks below were rerun after applying the owner's choices:

- `UiCozyAudioSmokeTest.gd` — 42 checks covering existing/new control binding,
  hover/keyboard deduplication, hidden/disabled silence, toggle direction,
  cooldowns, separate RNG, committed-action cue mappings, original bell
  preservation, SFX routing/mute and bounded voices.
- `ImpactSoundRoutingSmokeTest.gd` — audible combat/effect/reaction cues with
  exact selected normal and Meal-to-Chef sounds synchronized to contact, no
  duplicate hit and fixed audition pitch. Meal-summon cue remains unchanged.
- `PositiveEffectSoundSmokeTest.gd` — actual heal event uses the selected
  recording; buffs retain their original cue, with independent cooldowns.
- `BattleCozyAudioSmokeTest.gd` — single-card draw cues and real-shuffle-only
  routing, including silent redraws, deck clicks, generic searches and missing
  transfer targets; exact selected draw, unchanged pickup/place pools, selected
  ability voice/tail protection, existing cooldown and RNG safeguards.
- `CozyAudioFlowSmokeTest.gd` — real Main actions with a cue spy: one entry bell;
  redraw, settings, shop focus and reward backdrops do not ring it again;
  successful purchase, removal, paid upgrade and healing emit their cue once;
  rejected actions and cancelled choices do not emit success; match results
  respect the existing completion guard. It exited 0 with no assertion failures;
  the fixture emitted an ObjectDB teardown warning.

Earlier integration checks, unchanged by these cue selections:

- `GameStartFlowSmokeTest.gd -- --public`, `HubMachineFocusSmokeTest.gd`,
  `HubSellerSmokeTest.gd` and `MusicMixSmokeTest.gd` — existing start/continue,
  shop service and music behavior passed. The seller fixture also emitted a
  teardown ObjectDB warning; it reported zero assertion failures and exited 0.

Asset verification after applying the choices:

- All 130 imported file hashes match both their original supplied source and
  the import manifest. All eight applied choice records match their file hashes;
  the preserved selection JSON is byte-identical to the supplied export. The
  bell's bytes match the `f999e7d` release exactly. Imported files total 3.27 MiB.

These automated routing checks do not replace an in-game listening pass.
