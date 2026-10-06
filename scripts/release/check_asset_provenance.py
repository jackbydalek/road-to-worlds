#!/usr/bin/env python3
"""Audit registered generated working art and keep historical experiments excluded.

The legacy check_no_ai_assets.sh entry point delegates here so existing release
commands retain their API. Passing this audit is not a non-AI attestation.
"""
from __future__ import annotations

import hashlib
import json
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
MEDIA_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".svg", ".glb", ".gif", ".bmp", ".tga", ".exr", ".hdr", ".avif", ".ktx", ".ktx2"}
EXCLUDED_DIRECTORIES = (
    "outputs", "docs/references", "docs/ai-prompts", "assets/marketing", "assets/art_direction", "assets/characters/concepts",
    "assets/characters/mascots", "assets/finale", "assets/overworld/buildings/concepts",
    "assets/overworld/buildings/shop_concept", "assets/overworld/source_sheets", "assets/title",
)
EXCLUDED_FILES = (
    "assets/characters/shopkeeper/clerkidle.glb",
    "assets/characters/shopkeeper/shopkeeper_lofi_v2.png",
    "assets/characters/shopkeeper/singles-counter-proprietor-v1.png",
    "assets/characters/shopkeeper/singles-counter-proprietor-v2.png",
    "assets/cards/card_backs/angular_card_back_concept.svg",
)
REQUIRED_EXCLUSIONS = tuple(path + "/**" for path in EXCLUDED_DIRECTORIES) + EXCLUDED_FILES + (
    "clerkidle.tscn", "scenes/GreyboxCameraDemo.tscn", "scripts/*ConceptCapture.gd",
)
# Source sheets remain usable as provenance for extracted production assets,
# while the original sheets themselves stay out of the game export.
KNOWN_GENERATED_ROOTS = tuple(path for path in EXCLUDED_DIRECTORIES if path not in ("outputs", "docs/references", "assets/overworld/source_sheets")) + (
    "outputs/concept_art", "outputs/icon_concepts", "outputs/lofi_shop_concept",
    "outputs/steam_capsules", "outputs/style_tiles",
)
FORBIDDEN_RUNTIME_REFS = tuple("res://" + path + "/" for path in EXCLUDED_DIRECTORIES if path != "assets/overworld/source_sheets") + tuple("res://" + path for path in EXCLUDED_FILES)


def digest(path: Path) -> str:
    result = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def relative_file(root: Path, value: object, role: str) -> tuple[str, Path]:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{role} must be a nonempty project-relative file path.")
    raw = value.removeprefix("res://")
    relative = Path(raw)
    if relative.is_absolute() or ".." in relative.parts:
        raise ValueError(f"{role} must stay inside the project: {value}")
    resolved = (root / relative).resolve()
    if not resolved.is_relative_to(root.resolve()) or not resolved.is_file():
        raise ValueError(f"{role} does not resolve to an existing project file: {value}")
    return relative.as_posix(), resolved


def registered_assets(root: Path) -> dict[str, str]:
    manifest_path = root / "assets/generated/manifest.json"
    if not manifest_path.is_file():
        raise ValueError("Missing generated-art manifest: assets/generated/manifest.json")
    manifest = json.loads(manifest_path.read_text())
    if not isinstance(manifest, dict) or manifest.get("schema_version") != 1 or not isinstance(manifest.get("assets"), list):
        raise ValueError("Generated-art manifest must have schema_version 1 and an assets array.")
    registered: dict[str, str] = {}
    for entry in manifest["assets"]:
        if not isinstance(entry, dict):
            raise ValueError("Each generated-art manifest entry must be an object.")
        name, path = relative_file(root, entry.get("path"), "Generated asset")
        if not name.startswith("assets/generated/") or path.suffix.lower() not in MEDIA_SUFFIXES:
            raise ValueError(f"Registered generated art must be media under assets/generated/: {name}")
        if name in registered:
            raise ValueError(f"Duplicate generated-art manifest entry: {name}")
        expected = entry.get("sha256", "")
        if not isinstance(expected, str) or not re.fullmatch(r"[0-9a-f]{64}", expected):
            raise ValueError(f"Generated asset has an invalid SHA-256: {name}")
        if digest(path) != expected:
            raise ValueError(f"Generated asset bytes differ from the registered SHA-256: {name}")
        _, prompt = relative_file(root, entry.get("prompt_file"), f"Prompt for {name}")
        if not prompt.read_text().strip():
            raise ValueError(f"Generated asset prompt is empty: {name}")
        consumers = entry.get("consumers")
        if not isinstance(consumers, list) or not consumers:
            raise ValueError(f"Generated asset needs at least one documented consumer: {name}")
        for consumer in consumers:
            relative_file(root, consumer, f"Consumer for {name}")
        registered[name] = expected
    for path in (root / "assets/generated").rglob("*"):
        if path.is_file() and path.suffix.lower() in MEDIA_SUFFIXES:
            name = path.relative_to(root).as_posix()
            if name not in registered:
                raise ValueError(f"Generated media is missing from the manifest: {name}")
    return registered


def check_policy(root: Path) -> None:
    policy = root / "docs/shipping-asset-provenance.md"
    if not policy.is_file() or "ASSET_POLICY: REGISTERED_GENERATED_ALLOWED" not in policy.read_text().splitlines():
        raise ValueError("Asset provenance record must declare ASSET_POLICY: REGISTERED_GENERATED_ALLOWED.")
    text = (root / "export_presets.cfg").read_text()
    presets = re.split(r"(?m)^\[preset\.\d+\]\s*$", text)[1:]
    if not presets:
        raise ValueError("No export presets were found.")
    for index, preset in enumerate(presets):
        match = re.search(r'^exclude_filter="(.*)"$', preset, re.MULTILINE)
        exclusions = set(match.group(1).split(",")) if match else set()
        missing = set(REQUIRED_EXCLUSIONS) - exclusions
        if missing:
            raise ValueError(f"Export preset {index} lacks historical-experiment exclusions: {', '.join(sorted(missing))}")


def check_runtime_references(root: Path) -> None:
    sources = [root / "project.godot"]
    for directory in ("data", "scenes", "scripts"):
        sources.extend(path for path in (root / directory).rglob("*") if path.is_file())
    for path in sources:
        if path.suffix not in {".godot", ".gd", ".tscn", ".tres", ".json"} or path.name.endswith(("Capture.gd", "SmokeTest.gd", "Simulation.gd", "RenderCheck.gd")):
            continue
        for number, line in enumerate(path.read_text().splitlines(), 1):
            if any(reference in line for reference in FORBIDDEN_RUNTIME_REFS):
                raise ValueError(f"Excluded reference or experiment referenced by shipping runtime: {path.relative_to(root)}:{number}: {line.strip()}")


def excluded_candidate(name: str) -> bool:
    return any(name == path or name.startswith(path + ".") for path in EXCLUDED_FILES) or any(name.startswith(path + "/") for path in EXCLUDED_DIRECTORIES)


def check_hash_copies(root: Path, registered: dict[str, str]) -> None:
    known_file = root / "scripts/release/known_generated_asset_hashes.sha256"
    if not known_file.is_file() or not known_file.stat().st_size:
        raise ValueError("Missing known generated-asset hash denylist.")
    generated_hashes = {line.split()[0] for line in known_file.read_text().splitlines() if line.strip() and not line.startswith("#")}
    generated_hashes.update(registered.values())
    for directory in KNOWN_GENERATED_ROOTS:
        source = root / directory
        if source.is_dir():
            generated_hashes.update(digest(path) for path in source.rglob("*") if path.is_file() and path.suffix.lower() in MEDIA_SUFFIXES)
    for path in (root / "assets").rglob("*"):
        if not path.is_file() or path.suffix.lower() not in MEDIA_SUFFIXES:
            continue
        name = path.relative_to(root).as_posix()
        if excluded_candidate(name):
            continue
        checksum = digest(path)
        if checksum in generated_hashes and registered.get(name) != checksum:
            raise ValueError(f"Known generated artwork appears at an unregistered shipping path: {name}")


def check_export_log(log: Path) -> None:
    if not log.is_file() or not log.stat().st_size:
        raise ValueError(f"Cannot inspect missing or empty export log: {log}")
    for number, line in enumerate(log.read_text().splitlines(), 1):
        if "Storing File: res://" not in line:
            continue
        name = line.split("Storing File: res://", 1)[1].strip()
        if excluded_candidate(name):
            raise ValueError(f"Exporter stored an excluded reference or historical experiment at {log}:{number}: {name}")


def main(arguments: list[str]) -> int:
    if arguments and not (arguments == ["--audit-known"] or len(arguments) == 2 and arguments[0] == "--export-log"):
        print("Usage: check_no_ai_assets.sh [--audit-known | --export-log path/to/export.log]", file=sys.stderr)
        return 2
    try:
        check_policy(PROJECT_ROOT)
        registered = registered_assets(PROJECT_ROOT)
        check_runtime_references(PROJECT_ROOT)
        check_hash_copies(PROJECT_ROOT, registered)
        if arguments and arguments[0] == "--export-log":
            check_export_log(Path(arguments[1]))
    except (ValueError, OSError, json.JSONDecodeError) as error:
        print(f"Asset provenance audit failed: {error}", file=sys.stderr)
        return 1
    print(f"Asset provenance audit passed: {len(registered)} registered generated working-art asset(s); historical experiments excluded.")
    print("This verifies the recorded inventory and exclusions; it is not a non-AI provenance attestation.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
