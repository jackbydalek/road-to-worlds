#!/usr/bin/env python3
"""Decode the supplied Mina GIF to stable, lossless runtime PNG frames.

Only format conversion and a shared alpha-bounds crop are performed. No pixels
are painted, recolored, resampled, segmented, or generated.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
DESTINATION = ROOT / "assets/characters/mina"
PADDING = 8


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", nargs="?", type=Path, default=DESTINATION / "source.gif")
    args = parser.parse_args()
    source = args.source.resolve()
    source_hash = digest(source)
    frames: list[Image.Image] = []
    durations: list[int] = []
    bounds: list[tuple[int, int, int, int]] = []
    with Image.open(source) as gif:
        source_size = gif.size
        loop = gif.info.get("loop")
        for index in range(gif.n_frames):
            gif.seek(index)
            frame = gif.convert("RGBA")
            frames.append(frame)
            durations.append(gif.info["duration"])
            bbox = frame.getchannel("A").getbbox()
            if bbox is not None:
                bounds.append(bbox)
    if not bounds:
        raise ValueError("Source contains no visible pixels")
    union = (
        min(box[0] for box in bounds), min(box[1] for box in bounds),
        max(box[2] for box in bounds), max(box[3] for box in bounds),
    )
    crop = (
        union[0] - PADDING, union[1] - PADDING,
        union[2] + PADDING, union[3] + PADDING,
    )
    DESTINATION.mkdir(parents=True, exist_ok=True)
    archive = DESTINATION / "source.gif"
    if archive.exists() and digest(archive) != source_hash:
        raise FileExistsError("Refusing to replace a different preserved source.gif")
    if source != archive.resolve():
        shutil.copy2(source, archive)
    assert digest(archive) == source_hash

    records = []
    unique_pixels: dict[str, int] = {}
    for index, (frame, duration) in enumerate(zip(frames, durations, strict=True)):
        extracted = frame.crop(crop)
        output = DESTINATION / f"idle-{index:02d}.png"
        extracted.save(output, format="PNG", optimize=False)
        with Image.open(output) as reopened:
            assert reopened.mode == "RGBA"
            assert reopened.tobytes() == extracted.tobytes()
            # Cropping loses only transparent space, preserving every source
            # foreground pixel exactly, including its RGB values.
            assert reopened.getchannel("A").histogram()[255] == frame.getchannel("A").histogram()[255]
        pixel_hash = hashlib.sha256(extracted.tobytes()).hexdigest()
        unique_pixels.setdefault(pixel_hash, len(unique_pixels))
        records.append({
            "path": output.relative_to(ROOT).as_posix(),
            "sha256": digest(output),
            "rgba_pixel_sha256": pixel_hash,
            "duration_ms": duration,
            "distinct_frame_index": unique_pixels[pixel_hash],
            "size": list(extracted.size),
            "alpha_bounds_xyxy": list(extracted.getchannel("A").getbbox()),
        })

    provenance = {
        "schema_version": 1,
        "asset_id": "mina-user-supplied-idle",
        "origin": "User-supplied GIF; authorship and upstream production method are not independently attested.",
        "ai_used_in_preparation": False,
        "source": {
            "supplied_filename": "IMG_0450.GIF",
            "preserved_path": archive.relative_to(ROOT).as_posix(),
            "sha256": source_hash,
            "size": list(source_size),
            "frame_count": len(frames),
            "durations_ms": durations,
            "gif_loop": loop,
        },
        "preparation": {
            "script": Path(__file__).relative_to(ROOT).as_posix(),
            "operations": ["Decode GIF disposal/compositing to RGBA", "Apply one shared integer crop", "Save lossless RGBA PNGs"],
            "resampling": False,
            "recoloring": False,
            "background_removal": False,
            "alpha_bounds_union_xyxy": list(union),
            "crop_in_source_xyxy": list(crop),
            "transparent_padding_px": PADDING,
            "verification": "Each reloaded PNG exactly matches its decoded source crop byte-for-byte; all source opaque pixels are retained.",
        },
        "runtime_alignment": {
            "canvas_size": list(frames[0].crop(crop).size),
            "lower_arm_baseline_y": 610,
            "maximum_opaque_bottom_exclusive_y": union[3] - crop[1],
            "face_region_xywh": [130, 90, 335, 335],
            "notes": "Use the same canvas transform for all frames. Forearms sit around y=590-610; the near hand extends to y=619. Face region is a square unscaled AtlasTexture crop centered on the face and supporting hand.",
        },
        "distinct_rgba_frames": len(unique_pixels),
        "total_duration_ms": sum(durations),
        "outputs": records,
    }
    (DESTINATION / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")
    print(json.dumps({"canvas": provenance["runtime_alignment"]["canvas_size"], "crop": crop, "durations_ms": durations, "distinct_frames": len(unique_pixels)}, indent=2))


if __name__ == "__main__":
    main()
