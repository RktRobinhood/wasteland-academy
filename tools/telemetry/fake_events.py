#!/usr/bin/env python3
"""Fake telemetry events with planted outliers, for testing report.py (FAL-407).

Fifteen ordinary views over three levels plus four special ones, about 330 sessions
over a week, game version 1.0.0 then 1.1.0. Right counts are exact per seed, so the
only differences between views are the planted ones. Times are noisy (log-normal).

Planted, and the flag each one should raise (`PLANTED`):
  - a too-hard view: 33% right where its level gets 67%
  - a bad seed: seed 7 of one view, 15% right where the rest of the view gets 83%
  - a dominant misconception: one ref behind 70% of a view's wrong answers
  - an error spike: a generator error in 15% of 1.1.0 sessions and none of 1.0.0
  - an experiment with a real effect (55% against 75%) and one without (67% both)

Background that must not be flagged: a client error and a generator error at the same
rate in both versions, second attempts, sessions that end on a question.

    python3 tools/telemetry/fake_events.py > fake.jsonl
"""

import json
import math
import random
import sys
from datetime import datetime, timezone

DAY = 86400
START = 1793664000  # 2026-11-03 00:00 UTC

LEVEL_RATE = {1: 10 / 12, 2: 8 / 12, 3: 6 / 12}  # exact on 12 answers a seed
LEVEL_SECONDS = {1: 30, 2: 60, 3: 90}

HARD = "fake-hard/what/equation/any/value"
BAD_SEED_VIEW = "fake-seedy/what/graph/any/mcq"
BAD_SEED = 7
DOMINANT = "fake-trap/what/equation/any/mcq"
DOMINANT_REF = "fake-trap#1"
EXP_REAL = "fake-wording/what/equation/any/value"
EXP_NULL = "fake-colour/what/graph/any/mcq"
SPIKE_MESSAGE = "Root out of clean range: 13 > 7"
SPIKE_VERSION = "1.1.0"

PLANTED = {
    ("too_hard", HARD),
    ("bad_seed", BAD_SEED_VIEW, BAD_SEED),
    ("struggle", DOMINANT, DOMINANT_REF),
    ("error_spike", "generator_error", "Root out of clean range: # > #", SPIKE_VERSION),
    ("experiment", "hint-wording", "new"),
}


def catalogue():
    """A question-types.json shape: the levels of the fake views."""
    types = {}
    for view, level in VIEWS.items():
        t, u = view.split("/")[:2]
        types.setdefault(t, []).append({"id": u, "level": level})
    return {"types": [{"id": t, "unknowns": us} for t, us in types.items()]}


VIEWS = {"fake-l%d-v%d/what/equation/any/value" % (lv, i): lv for lv in (1, 2, 3) for i in range(5)}
VIEWS.update({HARD: 2, BAD_SEED_VIEW: 1, DOMINANT: 3, EXP_REAL: 2, EXP_NULL: 2})


def _plays(rng, view, seeds, rate, arm=None):
    """One play per first answer: seeds is [(seed, answers)], right counts exact per seed."""
    level = VIEWS[view]
    factor = rng.uniform(0.8, 1.3)
    out = []
    for seed, n in seeds:
        r = rate(seed) if callable(rate) else rate
        k = int(r * n + 0.5)
        rights = [True] * k + [False] * (n - k)
        rng.shuffle(rights)
        for right in rights:
            secs = min(600.0, LEVEL_SECONDS[level] * factor * math.exp(rng.gauss(0, 0.35)))
            out.append({"view": view, "seed": seed, "right": right, "seconds": round(secs, 1), "arm": arm})
    return out


def _ref(view, i):
    """The misconception ref of the i-th wrong answer on a view, or ""."""
    t = view.split("/")[0]
    if view == DOMINANT:
        return DOMINANT_REF if i % 10 < 7 else ("%s#%d" % (t, i % 3 + 2) if i % 10 < 9 else "")
    return "%s#%d" % (t, i % 4) if i % 2 == 0 else ""


def generate(seed=4070):
    rng = random.Random(seed)
    plays = []
    for view in VIEWS:
        if view in (EXP_REAL, EXP_NULL):
            continue
        lv = VIEWS[view]
        if view == BAD_SEED_VIEW:
            # Enough other seeds that seed 7 alone does not make the whole view too hard
            seeds = [(s, 24) for s in range(1, 16) if s != BAD_SEED] + [(BAD_SEED, 20)]
            plays += _plays(rng, view, seeds, lambda s: 0.15 if s == BAD_SEED else LEVEL_RATE[lv])
        else:
            rate = 4 / 12 if view == HARD else LEVEL_RATE[lv]
            plays += _plays(rng, view, [(s, 12) for s in range(1, 11)], rate)
    for arm, rate in (("old", 0.55), ("new", 0.75)):
        plays += _plays(rng, EXP_REAL, [(s, 30) for s in range(1, 11)], rate, ("hint-wording", arm))
    for arm in ("blue", "orange"):
        plays += _plays(rng, EXP_NULL, [(s, 30) for s in range(1, 11)], 2 / 3, ("graph-colour", arm))

    # Sessions: arms by index, so each arm gets half; experiment plays go to a
    # session with their arm, everything else anywhere.
    n_sessions = 330
    arms = [{"hint-wording": ("old", "new")[i % 2], "graph-colour": ("blue", "orange")[(i // 2) % 2]}
            for i in range(n_sessions)]
    by_session = [[] for _ in range(n_sessions)]
    for p in plays:
        if p["arm"]:
            exp, arm = p["arm"]
            choices = [i for i in range(n_sessions) if arms[i][exp] == arm]
            by_session[rng.choice(choices)].append(p)
        else:
            by_session[rng.randrange(n_sessions)].append(p)

    events = []
    wrong_seen = {}
    plain = [v for v in VIEWS if v.startswith("fake-l")]
    for i in range(n_sessions):
        sid = "%016x" % rng.getrandbits(64)
        version = "1.0.0" if i < n_sessions // 2 else SPIKE_VERSION
        t = START + i * (7 * DAY // n_sessions)

        def emit(event, **fields):
            nonlocal t
            t += rng.randint(5, 40)
            ev = {"event": event, "session_id": sid, "game_version": version, "schema": 1, "received_at": datetime.fromtimestamp(t, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")}
            ev.update(fields)
            events.append(ev)

        emit("session_start", platform="web", language="en", screen="phone", arms=arms[i])
        session_plays = by_session[i]
        rng.shuffle(session_plays)
        for n, p in enumerate(session_plays):
            view, seed = p["view"], p["seed"]
            extra = {"arms": {p["arm"][0]: p["arm"][1]}} if p["arm"] else {}
            emit("question_shown", view_id=view, seed=seed, cell=view.replace("/", "|"), mode="practice", **extra)
            ref = ""
            if not p["right"]:
                wrong_seen[view] = wrong_seen.get(view, 0) + 1
                ref = _ref(view, wrong_seen[view])
            emit("answer_checked", view_id=view, seed=seed, right=p["right"], attempt=1, seconds=p["seconds"],
                 misconception=ref, format_errors=0, solution_opened=False, **extra)
            if not p["right"] and n % 3 == 0:
                # A second attempt, never counted as a first answer
                right = n % 2 == 0
                ref = ""
                if not right:
                    wrong_seen[view] += 1
                    ref = _ref(view, wrong_seen[view])
                emit("answer_checked", view_id=view, seed=seed, right=right, attempt=2,
                     seconds=round(p["seconds"] / 2, 1), misconception=ref, **extra)
        # Errors at fixed rates: background in both versions, the spike only in 1.1.0
        if i % 20 == 3:
            emit("client_error", error="Invalid index # in array of size #", script="res://ui/map.gd", line=40)
        if i % 25 == 5:
            emit("generator_error", view_id=plain[i % 5], seed=i % 9 + 1, error="Division by zero in situation quadratic")
        if version == SPIKE_VERSION and i % 20 in (1, 8, 15):
            emit("generator_error", view_id=HARD, seed=7, error=SPIKE_MESSAGE)
        # About a third of sessions end on a question the student left
        if i % 3 == 0:
            view = plain[i % len(plain)]
            seed = i % 10 + 1
            emit("question_shown", view_id=view, seed=seed, cell=view.replace("/", "|"), mode="practice")
            emit("question_left", view_id=view, seed=seed, seconds=rng.randint(5, 120))
        emit("session_end", minutes=round(len(session_plays) * 0.7, 1), answered=len(session_plays))
    return events


def main():
    for ev in generate():
        sys.stdout.write(json.dumps(ev) + "\n")


if __name__ == "__main__":
    main()
