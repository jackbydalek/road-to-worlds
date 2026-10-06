#!/usr/bin/env python3
"""Aggregate the JSONL experiment records, retaining caps and uncertainty."""
from collections import Counter, defaultdict
import argparse
import json
import math
from pathlib import Path
from statistics import mean

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "outputs/balance_audit_2026-09-04"
AFFINITIES = ["spicy", "hearty", "sweet", "fresh"]


def interval(wins, count):
    if not count:
        return [0, 0]
    z = 1.96
    p = wins / count
    denominator = 1 + z * z / count
    midpoint = (p + z * z / (2 * count)) / denominator
    error = z * math.sqrt(p * (1 - p) / count + z * z / (4 * count * count)) / denominator
    return [round((midpoint - error) * 100, 2), round((midpoint + error) * 100, 2)]


def average(values):
    return round(mean(values), 3) if values else 0


def campaign(rows):
    result = {}
    for starter in AFFINITIES[:3]:
        group = [r for r in rows if r["starter"] == starter]
        if not group:
            continue
        wins = [r for r in group if r["won"]]
        battles = [b for r in group for b in r["battles"]]
        rounds = {}
        for round_number in range(1, 5):
            selected = [b for b in battles if b["round"] == round_number]
            rounds[round_number] = {
                "attempts": len(selected), "wins": sum(b["winner"] == "player" for b in selected),
                "start_life": average([b["start_life"] for b in selected]),
                "damage": average([b["damage"] for b in selected]),
                "healing": average([b["healing"] for b in selected]),
                "pressure_damage": average([b["pressure_damage"] for b in selected]),
                "deck_size": average([b["deck_size"] for b in selected]),
            }
        result[starter] = {
            "runs": len(group), "wins": len(wins), "win_percent": round(100 * len(wins) / len(group), 2),
            "wilson_95": interval(len(wins), len(group)), "rounds": rounds,
            "survivor_life": average([r["final_life"] for r in wins]),
            "survivor_final_deck": average([r["final_deck_size"] for r in wins]),
            "all_run_final_deck": average([r["final_deck_size"] for r in group]),
            "bye_healing_per_run": average([r["bye_healing"] for r in group]),
            "purchases_per_run": average([len(r["purchases"]) for r in group]),
            "damage_per_battle": average([b["damage"] for b in battles]),
            "healing_per_battle": average([b["healing"] for b in battles]),
            "pressure_per_battle": average([b["pressure_damage"] for b in battles]),
            "reshuffles_per_battle": average([b["reshuffles"] for b in battles]),
            "turns_per_battle": average([b["turns"] for b in battles]),
            "battle_count": len(battles), "caps": sum(b["capped"] for b in battles),
            "deaths_by_round": dict(Counter(r["battles"][-1]["round"] for r in group if not r["won"])),
            "losses_by_rival": dict(Counter(b["rival_affinity"] for b in battles if b["winner"] != "player")),
        }
    return result


def duels(rows):
    deck_totals = defaultdict(Counter)
    matchups = defaultdict(Counter)
    for r in rows:
        left, right = r["left"], r["right"]
        winner = left if r["winner"] == "player" else right if r["winner"] == "opponent" else "capped"
        for affinity in [left, right]:
            deck_totals[affinity]["games"] += 1
            deck_totals[affinity]["wins"] += winner == affinity
            deck_totals[affinity]["caps"] += r["capped"]
        key = " / ".join(sorted([left, right], key=AFFINITIES.index))
        matchups[key]["games"] += 1
        matchups[key][winner] += 1
    for totals in deck_totals.values():
        totals["win_percent"] = round(100 * totals["wins"] / totals["games"], 2)
        totals["wilson_95"] = interval(totals["wins"], totals["games"])
    return {"games": len(rows), "caps": sum(r["capped"] for r in rows),
            "first_seat_win_percent": round(100 * sum(r["winner"] == "player" for r in rows) / len(rows), 2),
            "decks": dict(deck_totals), "matchups": dict(matchups)}


def curve(rows):
    result = {}
    for starter in AFFINITIES[:3]:
        result[starter] = {}
        for tier in ["easy", "medium", "hard", "expert"]:
            group = [r for r in rows if r["starter"] == starter and r["tier"] == tier]
            wins = sum(r["winner"] == "player" for r in group)
            rivals = {}
            for affinity in AFFINITIES:
                subset = [r for r in group if r["rival_affinity"] == affinity]
                if subset:
                    rivals[affinity] = {"games": len(subset), "wins": sum(r["winner"] == "player" for r in subset)}
            result[starter][tier] = {
                "games": len(group), "wins": wins, "win_percent": round(100 * wins / len(group), 2),
                "wilson_95": interval(wins, len(group)), "rivals": rivals,
                "damage": average([r["damage"] for r in group]),
                "healing": average([r["healing"] for r in group]),
                "pressure": average([r["pressure_damage"] for r in group]),
                "turns": average([r["turns"] for r in group]), "caps": sum(r["capped"] for r in group),
            }
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", type=Path, default=OUT)
    args = parser.parse_args()
    output_dir = args.input_dir.resolve()
    summary = {"campaigns": {}, "duels": {}, "offers": [], "curves": {}}
    raw_campaigns = {}
    for path in sorted(output_dir.glob("*.jsonl")):
        if path.stem in ["pilot", "inventory"]:
            continue
        rows = [json.loads(line) for line in path.read_text().splitlines()]
        if not rows:
            raise ValueError(f"Empty experiment {path.name}")
        options = rows[0]["options"]
        mode = options["mode"]
        deck_count = 4 if options["variant"] in ["current", "full20"] else 3
        expected = 9 if mode == "offers" else int(options["runs"]) * (
            deck_count * (deck_count - 1) if mode == "duel" else 48 if mode == "curve" else 3
        )
        if len(rows) != expected:
            raise ValueError(f"Incomplete {path.name}: {len(rows)} != {expected}")
        log = output_dir / f"{path.stem}.log"
        if log.exists() and "SCRIPT ERROR" in log.read_text():
            raise ValueError(f"Rejected experiment with script errors: {path.stem}")
        if mode == "duel":
            summary["duels"][path.stem] = duels(rows)
        elif mode == "offers":
            summary["offers"] = rows
        elif mode == "campaign":
            summary["campaigns"][path.stem] = campaign(rows)
            raw_campaigns[path.stem] = rows
        elif mode == "curve":
            summary["curves"][path.stem] = curve(rows)
    baseline = {(r["starter"], r["seed"]): r for r in raw_campaigns["current_all_shop"]}
    paired = {}
    for scenario, rows in raw_campaigns.items():
        if scenario == "current_all_shop":
            continue
        counts = {a: Counter() for a in AFFINITIES[:3]}
        for row in rows:
            base = baseline[(row["starter"], row["seed"])]
            c = counts[row["starter"]]
            c["runs"] += 1
            c["baseline_wins"] += base["won"]
            c["variant_wins"] += row["won"]
            c["gained_wins"] += row["won"] and not base["won"]
            c["lost_wins"] += base["won"] and not row["won"]
        paired[scenario] = counts
    summary["paired_vs_current_all_shop"] = paired
    (output_dir / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    for name, starters in summary["campaigns"].items():
        print(name, "/".join(f"{starters[a]['win_percent']:g}%" for a in AFFINITIES[:3]))
    for name, values in summary["duels"].items():
        print(name, {a: d["win_percent"] for a, d in values["decks"].items()}, "caps", values["caps"])
    print("Total campaign runs:", sum(v["runs"] for s in summary["campaigns"].values() for v in s.values()))
    print("Total campaign battles:", sum(v["battle_count"] for s in summary["campaigns"].values() for v in s.values()))
    print("Total duels:", sum(s["games"] for s in summary["duels"].values()))
    for name, starters in summary["curves"].items():
        for starter, tiers in starters.items():
            print(name, starter, {tier: v["win_percent"] for tier, v in tiers.items()})


if __name__ == "__main__":
    main()
