# Trailer interaction clips — 2026-09-02

The `*_review_1080p.mp4` files are trimmed, H.264 delivery copies at 1920×1080, 30 fps, with stereo game audio. The narrow side padding preserves the game's native 16:10 framing without cropping UI.

The `*_master.avi` files are the untouched Godot Movie Maker captures at the project's native 1440×900, 30 fps, with extra editing handles.

| Clip | Delivery duration | Suggested trailer use |
| --- | ---: | --- |
| `13_card_trade_review_1080p.mp4` | 3.23s | Event choice, card exchange, and the received-card payoff. |
| `14_hand_trap_response_review_1080p.mp4` | 5.77s | Rival plays into a reaction window; Chutney Chinchilla springs the hand trap. |
| `14_hand_trap_dynamic_review_1080p.mp4` | 6.90s | Styled reaction prompt plus the hand-trap cut-in, named counter target, impact beat, and discard follow-through. |
| `01_combat_hook_review_1080p.mp4` | 4.73s | Short Spicy direct-attack hit for an early combat hook. |
| `07_battle_combo_review_1080p.mp4` | 11.27s | Longer Hearty sequence showing a buff, board development, and direct damage. |

Reusable deterministic capture IDs are defined in `scripts/TrailerClipPreviewCapture.gd`: `13_card_trade`, `14_hand_trap_response`, `01_combat_hook`, and `07_battle_combo`.
