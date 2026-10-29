"""Tests for the telemetry outlier report (FAL-407).

    python3 -m unittest discover -s tools/telemetry
"""

import csv
import io
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import fake_events  # noqa: E402
import report  # noqa: E402

LEVELS = report.levels_from_catalogue(fake_events.catalogue())


def analyse(raw, levels=LEVELS):
    return report.analyse([report.normalise(e, i) for i, e in enumerate(raw)], levels)


def level_one(raw):
    """Analyse with every view at level 1."""
    return analyse(raw, {"/".join(e["view_id"].split("/")[:2]): 1 for e in raw})


class PlantedOutliers(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = fake_events.generate()
        cls.report = analyse(cls.raw)

    def test_every_planted_outlier_is_flagged_and_nothing_else(self):
        self.assertEqual(self.report.keys(), fake_events.PLANTED)

    def test_planted_outliers_are_found_whatever_the_noise(self):
        # The fixed generator seed is not what makes them show
        for seed in range(1, 6):
            with self.subTest(seed=seed):
                self.assertLessEqual(fake_events.PLANTED, analyse(fake_events.generate(seed)).keys())

    def test_every_flag_has_a_replay_link(self):
        text = report.render(self.report)
        for f in self.report.flags:
            with self.subTest(flag=f.key):
                self.assertIsNotNone(f.seed)
                self.assertTrue(f.view_id)
                self.assertIn("?explore&view=%s&seed=%s)" % (f.view_id, f.seed), text)

    def test_the_report_prints_no_session_id(self):
        text = report.render(self.report)
        for sid in {e["session_id"] for e in self.raw}:
            self.assertNotIn(sid, text)

    def test_the_null_experiment_is_tested_and_has_no_winner(self):
        null = [x for x in self.report.experiments if x["experiment"] == "graph-colour"]
        self.assertEqual(len(null), 1)
        self.assertTrue(null[0]["verdict"].startswith("No difference"))

    def test_the_error_table_has_first_seen_versions(self):
        firsts = {e["message"]: e["first_seen"] for e in self.report.errors}
        self.assertEqual(firsts["Root out of clean range: # > #"], "1.1.0")
        self.assertEqual(firsts["Division by zero in situation quadratic"], "1.0.0")

    def test_dropoff_ranks_the_views_where_sessions_end(self):
        self.assertTrue(self.report.dropoff)
        self.assertTrue(all(d["view"].startswith("fake-l") for d in self.report.dropoff))
        ended = [d["ended"] for d in self.report.dropoff]
        self.assertEqual(ended, sorted(ended, reverse=True))

    def test_collector_csv_reads_the_same_as_jsonl(self):
        # The collector's events table: common columns, the rest in a JSON `fields` column
        common = ["received_at", "session_id", "event", "view_id", "seed", "game_version", "arms"]
        buf = io.StringIO()
        w = csv.DictWriter(buf, fieldnames=common + ["fields"])
        w.writeheader()
        for e in self.raw:
            row = {k: e.get(k, "") for k in common}
            row["arms"] = json.dumps(e["arms"]) if "arms" in e else ""
            row["fields"] = json.dumps({k: v for k, v in e.items() if k not in common})
            w.writerow(row)
        buf.seek(0)
        rows = report.read_rows(buf, "csv")
        r = report.analyse([report.normalise(e, i) for i, e in enumerate(rows)], LEVELS)
        self.assertEqual(r.keys(), fake_events.PLANTED)


class SmallCases(unittest.TestCase):
    def test_no_winner_below_the_minimum_sample(self):
        raw = []
        for arm, rights in (("old", 10), ("new", 45)):
            for i in range(50):
                raw.append({"event": "answer_checked", "session_id": arm, "view_id": "t/u/r/a/f", "seed": 1,
                            "right": i < rights, "attempt": 1, "arms": {"exp": arm}})
        r = analyse(raw)
        self.assertEqual(r.flags, [])
        self.assertTrue(r.experiments[0]["verdict"].startswith("Too early"))

    def test_too_easy_is_flagged_as_well(self):
        raw = []
        views = [("a/x/r/a/f", 0.95)] + [("%s/x/r/a/f" % c, 0.5) for c in "bcdefgh"]
        for v, rate in views:
            for i in range(100):
                raw.append({"event": "answer_checked", "session_id": "s", "view_id": v, "seed": i % 3 + 1,
                            "right": i < rate * 100, "attempt": 1})
        r = level_one(raw)
        self.assertEqual(r.keys(), {("too_easy", "a/x/r/a/f")})

    def test_a_level_where_every_other_answer_is_right(self):
        raw = [{"event": "answer_checked", "session_id": "s", "view_id": "%s/x/r/a/f" % v, "seed": i % 3 + 1,
                "right": v != "a" or i % 2 == 0, "attempt": 1}
               for v in "abcdefgh" for i in range(60)]
        r = level_one(raw)
        self.assertEqual(r.keys(), {("too_hard", "a/x/r/a/f")})

    def test_second_attempts_do_not_count_toward_the_right_rate(self):
        raw = [{"event": "answer_checked", "session_id": "s", "view_id": "a/x/r/a/f", "seed": 1,
                "right": False, "attempt": 1} for _ in range(40)]
        raw += [{"event": "answer_checked", "session_id": "s", "view_id": "a/x/r/a/f", "seed": 1,
                 "right": True, "attempt": 2} for _ in range(40)]
        raw += [{"event": "answer_checked", "session_id": "s", "view_id": "b/x/r/a/f", "seed": 1,
                 "right": i % 2 == 0, "attempt": 1} for i in range(40)]
        r = level_one(raw)
        self.assertIn(("too_hard", "a/x/r/a/f"), r.keys())

    def test_slow_view_is_flagged(self):
        raw = []
        for v, secs in (("a/x/r/a/f", 400), ("b/x/r/a/f", 40), ("c/x/r/a/f", 50), ("d/x/r/a/f", 45)):
            raw += [{"event": "answer_checked", "session_id": "s", "view_id": v, "seed": i % 4 + 1,
                     "right": i // 4 % 2 == 0, "attempt": 1, "seconds": secs + i % 7} for i in range(40)]
        r = level_one(raw)
        self.assertEqual(r.keys(), {("slow", "a/x/r/a/f")})

    def test_views_without_a_level_are_not_compared(self):
        raw = [{"event": "answer_checked", "session_id": "s", "view_id": v, "seed": 1,
                "right": v == "a/x/r/a/f", "attempt": 1} for v in ("a/x/r/a/f", "b/x/r/a/f") for _ in range(40)]
        r = analyse(raw, {})
        self.assertEqual((r.keys(), r.unlevelled), (set(), 2))
        self.assertIn("2 answered views have no level", report.render(r))

    def test_level_comes_from_the_catalogue(self):
        cat = {"types": [{"id": "fn-q", "unknowns": [{"id": "vertex", "level": 3}]}]}
        levels = report.levels_from_catalogue(cat)
        self.assertEqual(report.level_of("fn-q/vertex/equation/any/value", levels), 3)
        self.assertEqual(report.level_of("fn-q/other/equation/any/value", levels), "?")

    def test_field_aliases_and_d1_strings(self):
        e = report.normalise({"event": "answer_checked", "view": "a/b/c/d/e", "seed": "3", "correct": "1",
                              "version": "1.2.0", "ts": 1793664000, "arms": "exp=new"}, 0)
        self.assertEqual((e["view_id"], e["seed"], e["right"], e["game_version"]), ("a/b/c/d/e", 3, True, "1.2.0"))
        self.assertEqual(e["received_at"], "2026-11-03T00:00:00Z")
        self.assertEqual(e["arms"], {"exp": "new"})


class Statistics(unittest.TestCase):
    def test_fisher_matches_known_values(self):
        # [[3, 1], [1, 3]]: two-sided p = 34/70
        self.assertAlmostEqual(report.fisher_two_sided(3, 4, 1, 4), 34 / 70, places=9)
        self.assertAlmostEqual(report.fisher_two_sided(5, 10, 5, 10), 1.0, places=9)

    def test_mann_whitney_separates_and_does_not(self):
        same, ties = report.ranks([1, 2, 3, 4, 1, 2, 3, 4])
        self.assertGreater(report.mann_whitney_p(sum(same[:4]), 4, 4, ties), 0.5)
        apart, ties = report.ranks(list(range(40)))
        self.assertLess(report.mann_whitney_p(sum(apart[:20]), 20, 20, ties), 1e-6)

    def test_holm(self):
        self.assertEqual(report.holm([0.01, 0.04, 0.03]), [0.03, 0.06, 0.06])

    def test_versions_sort_by_number(self):
        self.assertEqual(sorted(["1.10.0", "1.9.0", "1.2.0"], key=report.version_key), ["1.2.0", "1.9.0", "1.10.0"])

    def test_error_messages_group_without_numbers(self):
        self.assertEqual(report.error_signature("Index 12 out of  size 3"), "Index # out of size #")

    def test_untrusted_text_cannot_break_a_table(self):
        self.assertEqual(report.code("a|b`c\nd"), "`a b c d`")


if __name__ == "__main__":
    unittest.main()
