#!/usr/bin/env python3
"""Weekly telemetry outlier report for the Godot game (FAL-407, plan on FAL-379).

Reads gameplay events exported from the telemetry collector (JSONL, or a CSV of the
collector's `events` table) and writes a Markdown report of the outliers:

  - Too hard or too easy: a view's first-attempt right rate against the other views
    at the same level, flagged past 2.5 standard errors with at least 30 answers.
  - Bad seeds: a seed whose right rate (Fisher's exact test) or answer time
    (Mann-Whitney U) is far off the rest of its view, Holm-adjusted across every
    seed tested.
  - Slow questions: a view's median answer time over 3 times its level's median.
  - Struggle spots: the misconception refs behind the wrong answers on each view,
    flagged when one ref is behind at least half of them.
  - Drop-off: the views where sessions most often end (`question_left`, then
    `session_end`). A ranking, never a flag.
  - Errors: `generator_error` and `client_error` grouped by message and game version,
    flagged when a message is in significantly more sessions of a version than of
    the versions before it.
  - Experiments: per experiment, a two-proportion test between arms. It names a
    winner only once every arm has the minimum sample.

Every flag carries a view id and a seed, linked to the engine explorer so the
question replays exactly as the student saw it.

Standard library only. Usage:

    python3 tools/telemetry/report.py events.jsonl [more.jsonl|.csv ...] -o report.md
    python3 tools/telemetry/report.py --since 2026-10-22 --until 2026-10-29 export.csv

Events
------
Field names follow the plan's event table. A CSV row from the collector holds the
common columns plus a `fields` JSON column with the rest; both shapes are read the
same way. `ALIASES` maps alternative names, so a rename in the collector's
`services/telemetry/schema.json` is a one-line change here.

    every event      event, session_id, game_version, received_at (or ts)
    session_start    arms {experiment: arm}
    question_shown   view_id, seed, cell, mode
    answer_checked   view_id, seed, right, attempt, seconds, misconception, arms
    question_left    view_id, seed, seconds
    generator_error  view_id, seed, error
    client_error     error, script, line
    session_end      minutes, answered

A view id is `<type>/<unknown>/<rep>/<angle>/<format>`. Its level is the unknown's
level in curriculum/question-types.json.

Right rates and answer times use first attempts only (a retry after seeing the
answer was wrong is not a fresh measure of difficulty). Struggle spots count every
wrong answer, because each wrong pick says which misconception was behind it.

The report never prints a session id, and the input carries no personal data
(see the privacy rules in the plan).
"""

import argparse
import csv
import json
import math
import re
import statistics
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
CATALOGUE = ROOT / "curriculum" / "question-types.json"
SITE = "https://rktrobinhood.github.io/wasteland-academy/next/"

Z_FLAG = 2.5            # too hard or too easy: standard errors from the level
MIN_ANSWERS = 30        # first answers a view needs before it can be flagged
MIN_SEED_ANSWERS = 10   # first answers a seed needs before it is tested
SEED_ALPHA = 0.05       # family-wise, Holm-adjusted across every seed test
SLOW_FACTOR = 3.0       # slow: view median over this times the level median
MIN_WRONG = 20          # wrong answers a view needs for a struggle flag
DOMINANT_SHARE = 0.5    # one ref behind at least this share of wrong answers
SPIKE_Z = 2.5           # error spike: one-sided z against earlier versions
MIN_SPIKE_SESSIONS = 5  # sessions with the error in the new version
MIN_ARM_ANSWERS = 200   # first answers per arm before a winner can be named
ARM_ALPHA = 0.05        # Bonferroni-adjusted over the comparisons in an experiment
DROPOFF_ROWS = 10
STRUGGLE_ROWS = 10      # unflagged views listed under struggle spots, most wrong first

QUESTION_EVENTS = {"question_shown", "answer_checked", "question_left"}
ALIASES = {
    "view": "view_id", "correct": "right", "version": "game_version", "v": "game_version",
    "session": "session_id", "message": "error", "text": "error", "ts": "received_at",
    "misconception_ref": "misconception", "experiment_arms": "arms",
}


# ---------------------------------------------------------------- loading


def _bool(v):
    if isinstance(v, bool) or v is None:
        return v
    s = str(v).strip().lower()
    if s in ("1", "true", "yes", "right"):
        return True
    if s in ("0", "false", "no", "wrong"):
        return False
    return None


def _int(v):
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return None


def _float(v):
    try:
        f = float(v)
    except (TypeError, ValueError):
        return None
    return f if math.isfinite(f) else None


def _timestamp(v):
    """ISO 8601 UTC, so timestamps sort and compare with --since as text. Epoch
    seconds (or milliseconds) are converted."""
    f = _float(v) if not isinstance(v, bool) else None
    if f is None:
        return str(v or "")
    if f > 1e11:
        f /= 1000
    return datetime.fromtimestamp(f, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _arms(v):
    if isinstance(v, dict):
        return {str(k): str(a) for k, a in v.items() if a not in (None, "")}
    if isinstance(v, str) and v.strip():
        s = v.strip()
        if s.startswith("{"):
            try:
                return _arms(json.loads(s))
            except json.JSONDecodeError:
                return {}
        # "experiment=arm;other=arm"
        return dict(p.split("=", 1) for p in re.split(r"[;,]", s) if "=" in p)
    return {}


def normalise(raw, order):
    """One event as read from a file, as a flat dict with the report's field names."""
    ev = {}
    extra = raw.get("fields")
    if isinstance(extra, str) and extra.strip():
        try:
            extra = json.loads(extra)
        except json.JSONDecodeError:
            extra = None
    if isinstance(extra, dict):
        for k, v in extra.items():
            ev[ALIASES.get(k, k)] = v
    for k, v in raw.items():
        if k == "fields" or v in (None, ""):
            continue
        ev[ALIASES.get(k, k)] = v
    ev["event"] = str(ev.get("event", ""))
    ev["session_id"] = str(ev.get("session_id", ""))
    ev["game_version"] = str(ev.get("game_version", "") or "?")
    ev["received_at"] = _timestamp(ev.get("received_at", ""))
    ev["view_id"] = str(ev.get("view_id", "") or "")
    ev["seed"] = _int(ev.get("seed"))
    ev["right"] = _bool(ev.get("right"))
    ev["attempt"] = _int(ev.get("attempt")) or 1
    ev["seconds"] = _float(ev.get("seconds"))
    ev["misconception"] = str(ev.get("misconception", "") or "")
    ev["error"] = str(ev.get("error", "") or "")
    ev["arms"] = _arms(ev.get("arms"))
    ev["order"] = order
    return ev


def read_rows(f, fmt):
    """Raw rows from an open file: fmt is "csv" or "jsonl"."""
    if fmt == "csv":
        return list(csv.DictReader(f))
    return [json.loads(line) for line in f if line.strip()]


def read_events(paths):
    """Events from JSONL and CSV files ("-" is JSONL on stdin), in file order."""
    rows = []
    for path in paths:
        if path == "-":
            rows += read_rows(sys.stdin, "jsonl")
            continue
        p = Path(path)
        with p.open(newline="", encoding="utf-8") as f:
            rows += read_rows(f, "csv" if p.suffix.lower() == ".csv" else "jsonl")
    return [normalise(r, i) for i, r in enumerate(rows)]


def levels_from_catalogue(catalogue):
    """{"<type>/<unknown>": level} from curriculum/question-types.json."""
    out = {}
    for t in catalogue.get("types", []):
        for u in t.get("unknowns", []):
            if "level" in u:
                out["%s/%s" % (t["id"], u["id"])] = int(u["level"])
    return out


def level_of(view_id, levels):
    parts = view_id.split("/")
    return levels.get("/".join(parts[:2]), "?") if len(parts) >= 2 else "?"


# ---------------------------------------------------------------- statistics


def norm_sf(z):
    """P(Z > z) for a standard normal."""
    return 0.5 * math.erfc(z / math.sqrt(2))


def two_prop_z(x1, n1, x2, n2):
    """z for p1 - p2 under the pooled null that both rates are equal."""
    p = (x1 + x2) / (n1 + n2)
    se = math.sqrt(p * (1 - p) * (1 / n1 + 1 / n2))
    if se == 0:
        return 0.0
    return (x1 / n1 - x2 / n2) / se


def _log_comb(n, k):
    return math.lgamma(n + 1) - math.lgamma(k + 1) - math.lgamma(n - k + 1)


def fisher_two_sided(a, n1, b, n2):
    """Fisher's exact test: a right of n1 against b right of n2."""
    k, n = a + b, n1 + n2
    lo, hi = max(0, n1 - (n - k)), min(k, n1)
    denom = _log_comb(n, n1)
    logp = {x: _log_comb(k, x) + _log_comb(n - k, n1 - x) - denom for x in range(lo, hi + 1)}
    cut = logp[a] + 1e-7
    return min(1.0, sum(math.exp(v) for v in logp.values() if v <= cut))


def ranks(values):
    """Average ranks (1-based) and the tie term sum(t^3 - t)."""
    order = sorted(range(len(values)), key=values.__getitem__)
    out = [0.0] * len(values)
    ties = 0
    i = 0
    while i < len(order):
        j = i
        while j + 1 < len(order) and values[order[j + 1]] == values[order[i]]:
            j += 1
        for k in range(i, j + 1):
            out[order[k]] = (i + j) / 2 + 1
        t = j - i + 1
        ties += t ** 3 - t
        i = j + 1
    return out, ties


def mann_whitney_p(rank_sum, n1, n2, ties):
    """Two-sided normal-approximation p for a group's rank sum within n1 + n2 values."""
    n = n1 + n2
    u = rank_sum - n1 * (n1 + 1) / 2
    mu = n1 * n2 / 2
    var = n1 * n2 / 12 * ((n + 1) - ties / (n * (n - 1)))
    if var <= 0:
        return 1.0
    z = (abs(u - mu) - 0.5) / math.sqrt(var)
    return min(1.0, 2 * norm_sf(max(z, 0.0)))


def holm(pvalues):
    """Holm-adjusted p values, in input order."""
    m = len(pvalues)
    order = sorted(range(m), key=pvalues.__getitem__)
    out = [1.0] * m
    running = 0.0
    for rank, i in enumerate(order):
        running = max(running, min(1.0, (m - rank) * pvalues[i]))
        out[i] = running
    return out


def version_key(v):
    return (tuple(int(n) for n in re.findall(r"\d+", v)), v)


def error_signature(text):
    """An error message with numbers, quotes and whitespace evened out, for grouping."""
    s = re.sub(r"\d+(\.\d+)?", "#", text)
    return re.sub(r"\s+", " ", s).strip()[:200]


# ---------------------------------------------------------------- analysis


@dataclass
class Flag:
    section: str
    key: tuple
    view_id: str
    seed: object
    text: str


@dataclass
class Report:
    events: int = 0
    sessions: int = 0
    first: str = ""
    last: str = ""
    versions: list = field(default_factory=list)
    flags: list = field(default_factory=list)
    unlevelled: int = 0
    difficulty: list = field(default_factory=list)
    seeds: list = field(default_factory=list)
    slow: list = field(default_factory=list)
    struggle: list = field(default_factory=list)
    dropoff: list = field(default_factory=list)
    errors: list = field(default_factory=list)
    experiments: list = field(default_factory=list)

    def keys(self):
        return {f.key for f in self.flags}


def _example_seed(evs):
    seeds = Counter(e["seed"] for e in evs if e["seed"] is not None)
    return seeds.most_common(1)[0][0] if seeds else None


def analyse(events, levels):
    r = Report(events=len(events))
    events = sorted(events, key=lambda e: (e["received_at"], e["order"]))
    r.sessions = len({e["session_id"] for e in events})
    stamps = [e["received_at"] for e in events if e["received_at"]]
    r.first, r.last = (stamps[0], stamps[-1]) if stamps else ("", "")
    r.versions = sorted({e["game_version"] for e in events}, key=version_key)

    answers = [e for e in events if e["event"] == "answer_checked" and e["view_id"] and e["right"] is not None]
    first = [e for e in answers if e["attempt"] == 1]
    by_view = defaultdict(list)
    for e in first:
        by_view[e["view_id"]].append(e)
    level = {v: level_of(v, levels) for v in by_view}
    # A view with no level in the catalogue has nothing fair to be compared with
    r.unlevelled = sum(1 for v in level.values() if v == "?")
    levelled = {v: evs for v, evs in by_view.items() if level[v] != "?"}

    _difficulty(r, levelled, level)
    _seeds(r, by_view)
    _slow(r, levelled, level)
    _struggle(r, answers)
    _dropoff(r, events)
    _errors(r, events)
    _experiments(r, first)
    return r


def _difficulty(r, by_view, level):
    totals = defaultdict(lambda: [0, 0])
    for v, evs in by_view.items():
        t = totals[level[v]]
        t[0] += sum(e["right"] for e in evs)
        t[1] += len(evs)
    for v, evs in sorted(by_view.items()):
        n = len(evs)
        x = sum(e["right"] for e in evs)
        lx, ln = totals[level[v]]
        ox, on = lx - x, ln - n
        if n < MIN_ANSWERS or on < MIN_ANSWERS:
            continue
        p_other = ox / on
        if 0 < p_other < 1:
            z = (x / n - p_other) / math.sqrt(p_other * (1 - p_other) * (1 / n + 1 / on))
        else:  # every other answer right (or wrong): the pooled test still has a spread
            z = two_prop_z(x, n, ox, on)
        row = {"view": v, "level": level[v], "n": n, "rate": x / n, "other": p_other, "z": z,
               "seed": _example_seed(evs)}
        if abs(z) > Z_FLAG:
            kind = "too_hard" if z < 0 else "too_easy"
            row["flag"] = kind
            r.flags.append(Flag(kind, (kind, v), v, row["seed"],
                                "%s: %.0f%% right against %.0f%% at level %s (z = %.1f, n = %d)"
                                % ("Too hard" if z < 0 else "Too easy", 100 * x / n, 100 * p_other,
                                   level[v], z, n)))
        r.difficulty.append(row)


def _seeds(r, by_view):
    tests = []  # (view, seed, kind, p, row)
    for v, evs in sorted(by_view.items()):
        groups = defaultdict(list)
        for i, e in enumerate(evs):
            if e["seed"] is not None:
                groups[e["seed"]].append(i)
        times = [(i, e["seconds"]) for i, e in enumerate(evs) if e["seconds"] is not None]
        rank_of, ties = {}, 0
        if times:
            rk, ties = ranks([t for _, t in times])
            rank_of = {i: rk[j] for j, (i, _) in enumerate(times)}
        total_right = sum(e["right"] for e in evs)
        for s, idx in sorted(groups.items()):
            n1 = len(idx)
            if n1 < MIN_SEED_ANSWERS or len(evs) - n1 < MIN_SEED_ANSWERS:
                continue
            a = sum(evs[i]["right"] for i in idx)
            n2, b = len(evs) - n1, total_right - a
            row = {"view": v, "seed": s, "n": n1, "rate": a / n1, "rest": b / n2}
            tests.append((v, s, "rate", fisher_two_sided(a, n1, b, n2), row))
            timed = [i for i in idx if i in rank_of]
            t1, t2 = len(timed), len(rank_of) - len(timed)
            if t1 >= MIN_SEED_ANSWERS and t2 >= MIN_SEED_ANSWERS:
                rest_times = [evs[i]["seconds"] for i in rank_of if evs[i]["seed"] != s]
                row["median"] = statistics.median(evs[i]["seconds"] for i in timed)
                row["rest_median"] = statistics.median(rest_times)
                tests.append((v, s, "time", mann_whitney_p(sum(rank_of[i] for i in timed), t1, t2, ties), row))
    adjusted = holm([t[3] for t in tests])
    hits = {}
    for (v, s, kind, _p, row), q in zip(tests, adjusted):
        if q < SEED_ALPHA:
            hits.setdefault((v, s), (row, []))[1].append((kind, q))
    for (v, s), (row, why) in sorted(hits.items()):
        parts = []
        for kind, q in why:
            if kind == "rate":
                parts.append("%.0f%% right against %.0f%% on the rest of the view" % (100 * row["rate"], 100 * row["rest"]))
            else:
                parts.append("median %.0f s against %.0f s" % (row["median"], row["rest_median"]))
        row["q"] = min(q for _, q in why)
        row["why"] = "; ".join(parts)
        r.seeds.append(row)
        r.flags.append(Flag("bad_seed", ("bad_seed", v, s), v, s,
                            "Bad seed: %s (n = %d, Holm p = %.2g)" % (row["why"], row["n"], row["q"])))


def _slow(r, by_view, level):
    times = defaultdict(list)
    for v, evs in by_view.items():
        times[level[v]] += [e["seconds"] for e in evs if e["seconds"] is not None]
    for v, evs in sorted(by_view.items()):
        own = [e["seconds"] for e in evs if e["seconds"] is not None]
        if len(own) < MIN_ANSWERS or not times[level[v]]:
            continue
        med, lmed = statistics.median(own), statistics.median(times[level[v]])
        if lmed > 0 and med > SLOW_FACTOR * lmed:
            seed = _example_seed(evs)
            r.slow.append({"view": v, "level": level[v], "n": len(own), "median": med, "level_median": lmed, "seed": seed})
            r.flags.append(Flag("slow", ("slow", v), v, seed,
                                "Slow: median %.0f s, %.1f times the level %s median of %.0f s"
                                % (med, med / lmed, level[v], lmed)))


def _struggle(r, answers):
    wrong = defaultdict(list)
    for e in answers:
        if not e["right"]:
            wrong[e["view_id"]].append(e)
    for v, evs in sorted(wrong.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        refs = Counter(e["misconception"] for e in evs if e["misconception"])
        if len(evs) < MIN_WRONG or not refs:
            continue
        top = refs.most_common(3)
        row = {"view": v, "wrong": len(evs), "top": [(ref, c, c / len(evs)) for ref, c in top]}
        ref, c = top[0]
        seed = _example_seed([e for e in evs if e["misconception"] == ref])
        row["seed"] = seed
        if c / len(evs) >= DOMINANT_SHARE:
            row["flag"] = ref
            r.flags.append(Flag("struggle", ("struggle", v, ref), v, seed,
                                "Struggle spot: `%s` is behind %.0f%% of %d wrong answers"
                                % (ref, 100 * c / len(evs), len(evs))))
        r.struggle.append(row)


def _dropoff(r, events):
    sessions = defaultdict(list)
    for e in events:
        sessions[e["session_id"]].append(e)
    shown = Counter(e["view_id"] for e in events if e["event"] == "question_shown" and e["view_id"])
    ended = defaultdict(list)
    for evs in sessions.values():
        last = None
        for e in evs:
            if e["event"] in QUESTION_EVENTS:
                last = e
            elif e["event"] == "session_end":
                if last is not None and last["event"] == "question_left" and last["view_id"]:
                    ended[last["view_id"]].append(last)
                last = None
    rows = [{"view": v, "ended": len(evs), "shown": shown.get(v, 0),
             "rate": len(evs) / shown[v] if shown.get(v) else None, "seed": _example_seed(evs)}
            for v, evs in ended.items()]
    rows.sort(key=lambda x: (-x["ended"], x["view"]))
    r.dropoff = rows[:DROPOFF_ROWS]


def _errors(r, events):
    sessions_in = defaultdict(set)
    for e in events:
        sessions_in[e["game_version"]].add(e["session_id"])
    groups = defaultdict(list)
    for e in events:
        if e["event"] in ("generator_error", "client_error"):
            groups[(e["event"], error_signature(e["error"]))].append(e)
    versions = r.versions
    for (kind, msg), evs in sorted(groups.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        by_version = defaultdict(list)
        for e in evs:
            by_version[e["game_version"]].append(e)
        seen = sorted(by_version, key=version_key)
        where = _error_where(kind, evs)
        row = {"kind": kind, "message": msg, "count": len(evs), "first_seen": seen[0], "where": where,
               "versions": [], "view": where[0], "seed": where[1]}
        for v in seen:
            hit = {e["session_id"] for e in by_version[v]}
            row["versions"].append((v, len(by_version[v]), len(hit), len(sessions_in[v])))
        r.errors.append(row)
        # Spike: in more sessions of a version than of all earlier versions together
        for i, v in enumerate(versions):
            earlier = versions[:i]
            if not earlier:
                continue
            hit = {e["session_id"] for e in by_version.get(v, [])}
            n_new = len(sessions_in[v])
            hit_old = {e["session_id"] for x in earlier for e in by_version.get(x, [])}
            n_old = len(set().union(*(sessions_in[x] for x in earlier)))
            if len(hit) < MIN_SPIKE_SESSIONS or not n_new or not n_old:
                continue
            z = two_prop_z(len(hit), n_new, len(hit_old), n_old)
            if z > SPIKE_Z:
                r.flags.append(Flag("error_spike", ("error_spike", kind, msg, v), where[0], where[1],
                                    "Error spike in %s: `%s` (%s) in %.0f%% of sessions, against %.0f%% before (z = %.1f)"
                                    % (v, msg, kind, 100 * len(hit) / n_new, 100 * len(hit_old) / n_old, z)))
                row.setdefault("spikes", []).append(v)


def _error_where(kind, evs):
    """The most common view and seed of an error, or its script and line."""
    if kind == "generator_error":
        views = Counter(e["view_id"] for e in evs if e["view_id"])
        if views:
            v = views.most_common(1)[0][0]
            return v, _example_seed([e for e in evs if e["view_id"] == v])
        return "", None
    places = Counter("%s:%s" % (e.get("script", "?"), e.get("line", "?")) for e in evs)
    return "", places.most_common(1)[0][0]


def _experiments(r, first):
    by_exp = defaultdict(lambda: defaultdict(list))
    for e in first:
        for exp, arm in e["arms"].items():
            by_exp[exp][arm].append(e)
    for exp, arms in sorted(by_exp.items()):
        stats = {a: (sum(e["right"] for e in evs), len(evs)) for a, evs in arms.items()}
        names = sorted(stats)
        control = next((a for a in ("control", "old", "a", "A") if a in stats), names[0])
        others = [a for a in names if a != control]
        row = {"experiment": exp, "control": control, "arms": [(a,) + stats[a] for a in names], "tests": []}
        short = [a for a in names if stats[a][1] < MIN_ARM_ANSWERS]
        views = Counter(e["view_id"] for evs in arms.values() for e in evs)
        view = views.most_common(1)[0][0] if views else ""
        seed = _example_seed([e for evs in arms.values() for e in evs if e["view_id"] == view])
        if not others:
            row["verdict"] = "Only one arm has answers."
        elif short:
            row["verdict"] = "Too early: every arm needs %d first answers (%s short)." % (MIN_ARM_ANSWERS, ", ".join(short))
        else:
            alpha = ARM_ALPHA / len(others)
            for a in others:
                z = two_prop_z(*stats[a], *stats[control])
                row["tests"].append((a, z, 2 * norm_sf(abs(z))))
            if any(p < alpha for _a, _z, p in row["tests"]):
                best = max(names, key=lambda a: stats[a][0] / stats[a][1])
                row["verdict"] = "Winner: `%s` (%.0f%% right)." % (best, 100 * stats[best][0] / stats[best][1])
                row["winner"] = best
                r.flags.append(Flag("experiment", ("experiment", exp, best), view, seed,
                                    "Experiment `%s`: `%s` wins, %s" % (exp, best, ", ".join(
                                        "%s %.0f%% (n = %d)" % (a, 100 * x / n, n) for a, x, n in row["arms"]))))
            else:
                row["verdict"] = "No difference at p < %.2g." % alpha
        r.experiments.append(row)


# ---------------------------------------------------------------- Markdown


def replay(view_id, seed, site):
    if not view_id or seed is None:
        return "–"
    return "[seed %s](%s?explore&view=%s&seed=%s)" % (seed, site, view_id, seed)


def code(text):
    """Untrusted text from a client, safe inside a table cell."""
    s = re.sub(r"[\r\n|`]", " ", str(text))[:160]
    return "`%s`" % s if s else "–"


def render(r, site=SITE):
    out = ["# Telemetry outlier report", ""]
    out.append("%d events from %d sessions, %s to %s. Game versions: %s." % (
        r.events, r.sessions, r.first or "?", r.last or "?", ", ".join(r.versions) or "none"))
    out += ["", "Replay links open the question in the engine explorer with the same view and seed.", ""]
    if r.unlevelled:
        out += ["%d answered views have no level in the catalogue, so they are left out of the difficulty and "
                "slow-question comparisons." % r.unlevelled, ""]

    out += ["## Flags (%d)" % len(r.flags), ""]
    if not r.flags:
        out.append("Nothing flagged.")
    for f in r.flags:
        out.append("- %s %s %s" % (code(f.view_id) if f.view_id else code(f.seed), replay(f.view_id, f.seed, site), f.text))

    out += ["", "## Too hard or too easy", "",
            "First-attempt right rate against the other views at the same level. Flagged past %.1f standard errors, "
            "with at least %d answers." % (Z_FLAG, MIN_ANSWERS), ""]
    rows = sorted((d for d in r.difficulty if "flag" in d), key=lambda d: d["z"])
    if rows:
        out += ["| View | Level | Answers | Right | Level (others) | z | Replay |", "|---|---|---|---|---|---|---|"]
        out += ["| %s | %s | %d | %.0f%% | %.0f%% | %.1f | %s |" % (
            code(d["view"]), d["level"], d["n"], 100 * d["rate"], 100 * d["other"], d["z"],
            replay(d["view"], d["seed"], site)) for d in rows]
    else:
        out.append("None. %d views had enough answers to test." % len(r.difficulty))

    out += ["", "## Bad seeds", "",
            "Seeds with at least %d first answers, tested against the rest of their view: right rate with Fisher's "
            "exact test, time with Mann-Whitney U. Holm-adjusted across every test, flagged below %.2g." % (
                MIN_SEED_ANSWERS, SEED_ALPHA), ""]
    if r.seeds:
        out += ["| View | Seed | Answers | What is off | Holm p | Replay |", "|---|---|---|---|---|---|"]
        out += ["| %s | %s | %d | %s | %.2g | %s |" % (code(s["view"]), s["seed"], s["n"], s["why"], s["q"],
                                                        replay(s["view"], s["seed"], site)) for s in r.seeds]
    else:
        out.append("None.")

    out += ["", "## Slow questions", "", "Median first-answer time over %g times the level median." % SLOW_FACTOR, ""]
    if r.slow:
        out += ["| View | Level | Answers | Median | Level median | Replay |", "|---|---|---|---|---|---|"]
        out += ["| %s | %s | %d | %.0f s | %.0f s | %s |" % (code(s["view"]), s["level"], s["n"], s["median"],
                                                           s["level_median"], replay(s["view"], s["seed"], site))
                for s in r.slow]
    else:
        out.append("None.")

    out += ["", "## Struggle spots", "",
            "The misconception refs behind wrong answers (every attempt), for views with at least %d. Flagged when one "
            "ref is behind %.0f%% or more. Flagged views first, then the %d with the most wrong answers."
            % (MIN_WRONG, 100 * DOMINANT_SHARE, STRUGGLE_ROWS), ""]
    rows = [s for s in r.struggle if "flag" in s] + [s for s in r.struggle if "flag" not in s][:STRUGGLE_ROWS]
    if rows:
        out += ["| View | Wrong | Top refs | Replay |", "|---|---|---|---|"]
        for s in rows:
            refs = ", ".join("%s %.0f%%" % (code(ref), 100 * share) for ref, _c, share in s["top"])
            out.append("| %s%s | %d | %s | %s |" % (code(s["view"]), " **(flag)**" if "flag" in s else "",
                                                     s["wrong"], refs, replay(s["view"], s["seed"], site)))
    else:
        out.append("No view has enough wrong answers with a misconception ref.")

    out += ["", "## Drop-off", "",
            "Where sessions end: the student left this question (`question_left`) and the session ended next. "
            "A ranking, not a flag.", ""]
    if r.dropoff:
        out += ["| View | Sessions ended | Times shown | Rate | Replay |", "|---|---|---|---|---|"]
        out += ["| %s | %d | %d | %s | %s |" % (code(d["view"]), d["ended"], d["shown"],
                                                "%.0f%%" % (100 * d["rate"]) if d["rate"] is not None else "–",
                                                replay(d["view"], d["seed"], site)) for d in r.dropoff]
    else:
        out.append("No session ended on a question.")

    out += ["", "## Errors", "",
            "Grouped by message (numbers shown as #) and game version. Sessions is how many sessions of that version "
            "hit the error. A spike is a version where it is in significantly more sessions than before (z over %g, "
            "at least %d sessions)." % (SPIKE_Z, MIN_SPIKE_SESSIONS), ""]
    if r.errors:
        out += ["| Kind | Message | First seen | Version: count, sessions / all | Where |", "|---|---|---|---|---|"]
        for e in r.errors:
            per = "; ".join("%s%s: %d, %d/%d" % (v, " **spike**" if v in e.get("spikes", []) else "", c, s, n)
                            for v, c, s, n in e["versions"])
            where = replay(e["view"], e["seed"], site) if e["view"] else code(e["seed"])
            if e["view"]:
                where = "%s %s" % (code(e["view"]), where)
            out.append("| %s | %s | %s | %s | %s |" % (e["kind"], code(e["message"]), e["first_seen"], per, where))
    else:
        out.append("No errors.")

    out += ["", "## Experiments", "",
            "First-attempt right rate per arm, each arm against the control with a two-proportion test "
            "(Bonferroni over the arms). No winner below %d answers per arm." % MIN_ARM_ANSWERS, ""]
    if r.experiments:
        for x in r.experiments:
            out.append("- **%s**: %s. %s" % (x["experiment"], ", ".join(
                "%s %d/%d (%.0f%%)" % (a, k, n, 100 * k / n) for a, k, n in x["arms"]), x["verdict"]))
    else:
        out.append("No events carry experiment arms.")
    return "\n".join(out) + "\n"


# ---------------------------------------------------------------- CLI


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("files", nargs="+", help="JSONL or CSV exports ('-' reads JSONL from stdin)")
    ap.add_argument("-o", "--out", help="write the Markdown here (default: stdout)")
    ap.add_argument("--catalogue", default=str(CATALOGUE), help="question-types.json for view levels")
    ap.add_argument("--site", default=SITE, help="base URL of the Godot game, for replay links")
    ap.add_argument("--since", help="keep events received on or after this date (YYYY-MM-DD)")
    ap.add_argument("--until", help="keep events received before this date (YYYY-MM-DD)")
    args = ap.parse_args(argv)

    events = read_events(args.files)
    if args.since:
        events = [e for e in events if e["received_at"] >= args.since]
    if args.until:
        events = [e for e in events if e["received_at"] < args.until]
    levels = levels_from_catalogue(json.loads(Path(args.catalogue).read_text(encoding="utf-8")))
    text = render(analyse(events, levels), args.site)
    if args.out:
        Path(args.out).write_text(text, encoding="utf-8")
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    main()
