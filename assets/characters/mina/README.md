# Supplied Mina animation

`source.gif` is the user's `IMG_0450.GIF`, preserved byte-for-byte. The six
`idle-00.png` through `idle-05.png` files are lossless runtime frame conversions
of that supplied art. No AI generation, repainting, recoloring, resampling or
background removal was used in preparing them. The GIF already has transparency.
The source's upstream authorship/production method is not independently attested.

All frames use one **701 × 628** canvas and a shared source crop
`Rect2(1743, 27, 701, 628)`. The union of the source's visible pixels is
`[1751, 35, 2436, 647)`; the crop adds 8 transparent pixels around it.
Every decoded opaque pixel and its RGB color is retained exactly. The import
source PNGs remain lossless; avoid nearest-neighbor downscaling or palette
conversion in asset preparation.

- Timing: six frames, **70 ms each**, looping forever, 420 ms per complete cycle.
- There are **two distinct drawings**: frames 0–2 are identical, as are frames
  3–5. Keep all six or use two 210 ms frames; do not alter the timing.
- Keep a common transform across frames. The resting forearms are around
  cropped y=590–610; y=610 is a useful table contact anchor. The near hand reaches
  y=619 (exclusive bottom bound y=620).
- Suggested square face `AtlasTexture.region`: `Rect2(130, 90, 335, 335)`.
  This centers the face and supporting hand without modifying the supplied art.

`provenance.json` records the original hash, exact crop, frame durations,
individual PNG/pixel hashes and the preparation script. This supplied asset is
separate from `assets/generated/`; preparing it introduced no AI-generated art.

To reproduce from the archived GIF with Pillow installed:

```sh
python3 scripts/art/prepare_mina_gif.py
```
