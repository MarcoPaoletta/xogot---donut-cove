"""Append a usage snapshot of this build to docs/records/USAGE_LOG.md.

What it measures (exact, read from the Claude Code transcripts of this project on disk):
  per agent (each lead session and every subagent) that started at or after --since: assistant messages,
  input tokens, cache writes, cache reads, output tokens, first and last timestamp.
What it cannot measure: the account wide plan percentages (5 hour and weekly windows) belong to the whole account
and include every other session of the user. Pass Marco's /usage readings so each snapshot records them next to the
exact per agent numbers; the difference between two snapshots is an upper bound for this build, not an exact share.

This reads only the transcripts of this project folder (the Donut Cove build). The plan percentages belong to the whole
account and include every other session running at the same time; the token tables here are this build's alone.
Pass --since (your build start) so earlier sessions in this folder (setup, checks) are not counted.

Run: C:\\Python314\\python.exe -E -P tools/usage_snapshot.py "label" --since 2026-11-09T22:00
                                  [--five-hour PCT] [--weekly PCT] [--weekly-resets ISO]
                                  [--api-prices in,cache_write,cache_read,out] [--note "text"]
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJECT_DIR = Path.home() / ".claude" / "projects" / re.sub(r"[^A-Za-z0-9]", "-", str(ROOT))


def parse_since(text: str) -> dt.datetime | None:
    if not text:
        return None
    value = dt.datetime.fromisoformat(text)
    if value.tzinfo is None:
        value = value.astimezone()
    return value.astimezone(dt.timezone.utc)


def parse_ts(text: str | None) -> dt.datetime | None:
    if not text:
        return None
    try:
        return dt.datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError:
        return None


def scan(path: Path) -> dict:
    best: dict[str, dict] = {}
    first = last = None
    with path.open(encoding="utf-8", errors="replace") as f:
        for line in f:
            try:
                o = json.loads(line)
            except Exception:
                continue
            ts = o.get("timestamp")
            if ts:
                first = first or ts
                last = ts
            m = o.get("message")
            if not isinstance(m, dict):
                continue
            u = m.get("usage")
            if not isinstance(u, dict):
                continue
            mid = m.get("id") or f"line{len(best)}"
            cur = best.setdefault(mid, {"in": 0, "cw": 0, "cr": 0, "out": 0})
            cur["in"] = max(cur["in"], int(u.get("input_tokens") or 0))
            cur["cw"] = max(cur["cw"], int(u.get("cache_creation_input_tokens") or 0))
            cur["cr"] = max(cur["cr"], int(u.get("cache_read_input_tokens") or 0))
            cur["out"] = max(cur["out"], int(u.get("output_tokens") or 0))
    total = {"messages": len(best), "in": 0, "cw": 0, "cr": 0, "out": 0, "first": first, "last": last}
    for v in best.values():
        for k in ("in", "cw", "cr", "out"):
            total[k] += v[k]
    return total


def agents() -> list[tuple[str, Path]]:
    out: list[tuple[str, Path]] = []
    mains = sorted(PROJECT_DIR.glob("*.jsonl"), key=lambda p: p.stat().st_mtime)
    for main in mains:
        out.append((f"lead session {main.stem[:8]}", main))
        sub = main.with_suffix("") / "subagents"
        if sub.exists():
            for t in sorted(sub.glob("agent-*.jsonl")):
                label = t.stem.replace("agent-", "")
                meta = t.with_suffix(".meta.json")
                if meta.exists():
                    try:
                        md = json.loads(meta.read_text(encoding="utf-8"))
                        label = f"{md.get('description') or md.get('agentType') or label} ({label[:6]})"
                    except Exception:
                        pass
                out.append((label, t))
    return out


def fmt(n: int) -> str:
    return f"{n:,}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("label")
    ap.add_argument("--since", default="", help="build start of this build, ISO local time; earlier sessions are skipped")
    ap.add_argument("--five-hour", default="")
    ap.add_argument("--weekly", default="")
    ap.add_argument("--weekly-resets", default="")
    ap.add_argument("--note", default="")
    ap.add_argument("--api-prices", default="",
                    help="USD per million tokens as in,cache_write,cache_read,out (official price list of the builder model, read at build time)")
    a = ap.parse_args()
    since = parse_since(a.since)
    log = ROOT / "docs" / "records" / "USAGE_LOG.md"
    now = dt.datetime.now(dt.timezone.utc)
    rows = []
    sums = {"messages": 0, "in": 0, "cw": 0, "cr": 0, "out": 0}
    for label, path in agents():
        t = scan(path)
        start = parse_ts(t["first"])
        if since and (start is None or start < since):
            continue
        rows.append((label, t))
        for k in sums:
            sums[k] += t[k]
    lines = [f"\n## {a.label}", f"Snapshot at {now.strftime('%Y-%m-%d %H:%M')} UTC ({now.astimezone().strftime('%H:%M %z')} local)."
             + (f" Sessions counted from {a.since}." if a.since else " No --since given: every session of the project is counted."), ""]
    plan = []
    if a.five_hour:
        plan.append(f"5 hour window: {a.five_hour}% used")
    if a.weekly:
        plan.append(f"weekly: {a.weekly}% used" + (f", resets {a.weekly_resets}" if a.weekly_resets else ""))
    if plan:
        lines += ["Account plan, shared with every other session of the user: " + "; ".join(plan) + ".", ""]
    lines += ["| Agent | Messages | Input | Cache write | Cache read | Output | First | Last |", "| :-- | --: | --: | --: | --: | --: | :-- | :-- |"]
    for label, t in rows:
        lines.append(f"| {label} | {fmt(t['messages'])} | {fmt(t['in'])} | {fmt(t['cw'])} | {fmt(t['cr'])} | {fmt(t['out'])} | {(t['first'] or '')[:16]} | {(t['last'] or '')[:16]} |")
    lines.append(f"| **All agents** | {fmt(sums['messages'])} | {fmt(sums['in'])} | {fmt(sums['cw'])} | {fmt(sums['cr'])} | {fmt(sums['out'])} | | |")
    if a.api_prices:
        pin, pcw, pcr, pout = (float(x) for x in a.api_prices.split(","))
        usd = (sums["in"] * pin + sums["cw"] * pcw + sums["cr"] * pcr + sums["out"] * pout) / 1_000_000
        lines += ["", f"API pricing equivalent of the tokens above at {a.api_prices} USD per million: {usd:,.2f} USD. "
                  "Not what was paid: the plan is a flat subscription shared by every project of the user."]
    if a.note:
        lines += ["", a.note]
    block = "\n".join(lines) + "\n"
    log.parent.mkdir(parents=True, exist_ok=True)
    if not log.exists():
        log.write_text(
            f"# Usage log\n\nHow much of the plan this build uses, measured, in the order that matters.\n\n"
            "1. Assets: free CC0 Quaternius packs, no generation credits are spent by this build.\n"
            "2. Plan quota: Marco's /usage readings, shared with every other session running at the same time, so a\n"
            "   percentage difference between two snapshots is an upper bound for this build, never an exact share.\n"
            "3. Exact tokens per agent, read from the transcripts by `tools/usage_snapshot.py`: the part attributable to this build.\n\n"
            "The flat plan fee is not a project cost and no API list price is quoted here as one.\n",
            encoding="utf-8",
        )
    with log.open("a", encoding="utf-8") as f:
        f.write(block)
    print(block)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
