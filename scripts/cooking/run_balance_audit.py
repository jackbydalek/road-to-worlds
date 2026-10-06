#!/usr/bin/env python3
"""Run reproducible balance experiments without opening UI or touching saves."""
import argparse
import concurrent.futures
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "outputs/balance_audit_2026-09-04"
SCENARIOS = {
    "current_all_shop": {"runs": 200, "shop": "singles"},
    "duel_full20": {"mode": "duel", "runs": 150, "variant": "full20"},
    "duel_current15": {"mode": "duel", "runs": 100},
    "duel_easy_decks": {"mode": "duel", "runs": 100, "tier": "easy"},
    "duel_medium_decks": {"mode": "duel", "runs": 100, "tier": "medium"},
    "duel_hard_decks": {"mode": "duel", "runs": 100, "tier": "hard"},
    "duel_expert_decks": {"mode": "duel", "runs": 100, "tier": "expert"},
    "current_all_noshop": {},
    "current_one_shop": {"rewards": "one", "shop": "singles"},
    "current_none_shop": {"rewards": "none", "shop": "singles"},
    "current_compatible_shop": {"rewards": "compatible", "shop": "singles"},
    "current_no_bye_shop": {"bye": "none", "shop": "singles"},
    "current_upgrade_shop": {"bye": "upgrade", "shop": "singles"},
    "current_life32": {"life": 32, "shop": "singles"},
    "current_life48": {"life": 48, "shop": "singles"},
    "simple_all_shop": {"variant": "simple", "shop": "singles"},
    "fundamentals_all_shop": {"variant": "fundamentals", "shop": "singles"},
    "current_expert_shop": {"player-ai": "expert", "shop": "singles"},
    "current_pressure_shop": {"player-style": "pressure", "shop": "singles"},
    "offers": {"mode": "offers", "runs": 5000},
    "keyword15": {"variant": "keyword15", "runs": 200, "shop": "singles"},
    "keyword12": {"variant": "keyword12", "shop": "singles"},
    "keyword15_expert": {"variant": "keyword15", "player-ai": "expert", "shop": "singles"},
    "keyword15_one": {"variant": "keyword15", "rewards": "one", "shop": "singles"},
    "keyword_curve": {"variant": "keyword15", "mode": "curve", "runs": 100},
    "current_curve": {"mode": "curve", "runs": 50},
    "keyword_duels": {"variant": "keyword15", "mode": "duel", "runs": 150},
}


def run_scenario(name, godot, output_dir):
    settings = SCENARIOS[name]
    destination = output_dir / f"{name}.jsonl"
    command = [godot, "--headless", "--log-file", f"/tmp/rtw-audit-{name}-engine.log",
               "--path", str(ROOT), "--script", "scripts/cooking/HubBalanceSimulation.gd", "--",
               *[f"--{key}={value}" for key, value in settings.items()],
               f"--output={destination}"]
    start = time.monotonic()
    with (output_dir / f"{name}.log").open("w") as log:
        log.write("Command: " + json.dumps(command) + "\n")
        log.flush()
        proc = subprocess.run(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
    log_text = (output_dir / f"{name}.log").read_text()
    if proc.returncode or "HUB_AUDIT_COMPLETE" not in log_text or "SCRIPT ERROR" in log_text:
        raise RuntimeError(f"{name} failed; inspect {name}.log")
    print(f"Completed {name} in {time.monotonic() - start:.1f}s", flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", help="Comma-separated scenario names; default all")
    parser.add_argument("--workers", type=int, default=2)
    parser.add_argument("--output-dir", type=Path, default=OUT)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "/Applications/Godot.app/Contents/MacOS/Godot"))
    args = parser.parse_args()
    names = args.only.split(",") if args.only else list(SCENARIOS)
    for name in names:
        if name not in SCENARIOS:
            parser.error(f"Unknown scenario {name}")
    args.output_dir = args.output_dir.resolve()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        for future in concurrent.futures.as_completed([pool.submit(run_scenario, name, args.godot, args.output_dir) for name in names]):
            future.result()


if __name__ == "__main__":
    main()
