# Title room — generated working art

The current September 11 revision uses the built-in image-generation edit in
[`04-lineless-room-no-white-rims.txt`](04-lineless-room-no-white-rims.txt).
It preserves the previous room composition and all seven people while painting
the furniture/background without navy outlines and removing white character
rims. People and held cards keep their navy ink. The source plate is the prior
registered room; the approved no-white-outline title concept supplies style only.
The central noticeboard and menu aisle remain clear, with no baked lettering or
controls.

Runtime: `assets/generated/title/locals_room_lineless_ink_people_ai.png`
(1584×993 RGB). The result was copied unchanged from the built-in tool output,
without pixel cleanup, recoloring or resizing. Exact source/output hashes,
generation destination, style-reference hash and full revision chain are in
`assets/generated/title/provenance.json`; active registration is in
`assets/generated/manifest.json`. The replaced room and its import record are
archived under excluded `outputs/lineless_art_implementation_2026-09-11/title/`.

The following notes document the superseded September 8 white-outline revision.

The exact built-in image-generation prompt is preserved byte-for-byte in
[`02-title-background.txt`](02-title-background.txt). It edits the owner's
supplied previous AI-generated seven-person room concept. Owner supply does
not certify human authorship. The edit adds white person silhouettes, removes
baked interface controls, clears the noticeboard for native lettering and
keeps the cabinet as background shop scenery.

Former runtime: `assets/generated/title/locals_room_white_outline_ai.png` (1586×992 RGB).
The complete bitmap, including room, people, products and white borders, is
AI-generated working art. The title wordmark and buttons are drawn separately
by the game. Exact source/output hashes and the generation destination are
recorded in `assets/generated/title/provenance.json`; active permission is in
`assets/generated/manifest.json`. This prompt directory is excluded from exports.

Disable the optional image using `TitleMenu.use_generated_title_art=false`.
That setting only avoids the load; remove/exclude the bitmap and import from
shipping paths and retire its manifest entry before a zero-generated-art build.
Use a human-made layered replacement with the same room/people arrangement,
blank noticeboard and open aisle, placed outside `assets/generated/`. Retain
retired generated hashes. No image-tool content is relabeled as human-made.
