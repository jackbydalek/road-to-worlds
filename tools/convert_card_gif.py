#!/usr/bin/env python3
"""Convert an animated GIF into optimized, Godot-importable PNG frames."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Source animated GIF")
    parser.add_argument("output", type=Path, help="Directory for generated PNG frames")
    parser.add_argument("--width", type=int, default=512, help="Output width in pixels")
    parser.add_argument("--height", type=int, default=384, help="Output height in pixels")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    with Image.open(args.source) as gif:
        durations: list[int] = []
        for index in range(gif.n_frames):
            gif.seek(index)
            frame = gif.convert("RGBA")
            frame.thumbnail((args.width, args.height), Image.Resampling.LANCZOS)

            canvas = Image.new("RGBA", (args.width, args.height), (0, 0, 0, 0))
            offset = ((args.width - frame.width) // 2, (args.height - frame.height) // 2)
            canvas.alpha_composite(frame, offset)
            canvas.save(args.output / f"frame_{index:02d}.png", optimize=True)
            durations.append(int(gif.info.get("duration", 100)))

    print(f"Converted {len(durations)} frames to {args.output}")
    print("Frame durations (ms): " + ", ".join(str(value) for value in durations))


if __name__ == "__main__":
    main()
