#!/usr/bin/env python3
"""Independent answer checker for the Godot question engine (FAL-322).

Reads the questions game/tools/export_questions.gd generated (fixed seeds) and, for
each one, solves it again with SymPy from the given quantities only. It shares no code
with the GDScript engine. It checks that:

  - the engine's answer is right
  - the numbers are inside the situation's clean limits
  - every multiple-choice distractor is wrong, and different from the others and
    from the answer
  - every worked solution's last step equals the answer
  - the equations shown, the answer and every option parse (with SymPy) to the
    values the engine says they have

It also counts the catalogue's coverage cells straight from
curriculum/question-types.json and fails if any cell has fewer than 50 questions or
any type fewer than 1,000. An export of one shard can't meet those on its own, so it
writes summary.json beside the export instead, and --merge runs them on all the shards
together (FAL-722). A shard that is missing or there twice is a failure.

    tools/check-answers            (exports, then runs this)
    python3 tools/check_answers.py questions.json
    python3 tools/check_answers.py --merge dir   (every summary.json under dir)
"""

import json
import math
import re
import sys
from collections import defaultdict
from decimal import ROUND_HALF_UP, Decimal
from functools import lru_cache
from pathlib import Path

import mpmath
import sympy as sp
from sympy.parsing.sympy_parser import (implicit_multiplication_application, parse_expr,
                                        standard_transformations)

ROOT = Path(__file__).resolve().parent.parent
X = sp.Symbol("x")
LETTERS = {n: sp.Symbol(n) for n in ["a", "b", "c", "k", "u"]}
TRANSFORMS = standard_transformations + (implicit_multiplication_application,)

MIN_PER_CELL = 50
MIN_PER_TYPE = 1000

# The clean limits for the `quadratic` situation (curriculum/question-types.json,
# situations.quadratic.clean and quantities), written out as numbers. This is the
# checker's own copy: the engine's is in game/engine/situations/quadratic.gd.
A_ALLOWED = {sp.Rational(v) for v in ["1", "-1", "2", "-2", "1/2", "-1/2", "3", "-3"]}
ROOT_MAX = 7
H_MAX = 5
SURDS = {2, 3, 5, 6, 7}
K_MAX, B_MAX, C_MAX = 20, 24, 24
GRAPH_Y_MAX = 16
POINT_X_MAX, POINT_Y_MAX = 6, 24
TABLE_Y_MAX = 40
# Unknowns where the axis or the vertex is asked or given, so p + q must be even.
NO_AXIS = {"roots-from-factorised", "y-intercept-from-factorised", "factorised-from-general",
           "a-from-roots-and-point", "coefficients-from-roots"}

FORM_KINDS = {"vertex_form", "vertex_form_a", "general", "general_a", "factorised", "deriv", "line"}
# Answer slots that hold a picked word, not a number.
WORD_SLOTS = ("var", "rel", "kind", "k1", "k2")


class Fail(Exception):
    pass


def R(s):
    return sp.Rational(str(s))


def need(cond, msg):
    if not cond:
        raise Fail(msg)


def parse(text, letters=()):
    """Parses an equation side the way the game writes it."""
    s = text.replace("−", "-").replace("²", "**2").replace("³", "**3").replace("⁴", "**4").replace("½", "(1/2)").replace("×", "*").replace("kx", "k*x")
    local = {"x": X}
    for n in letters:
        local[n] = LETTERS[n]
    return sp.expand(parse_expr(s, local_dict=local, transformations=TRANSFORMS))


def rhs(line):
    need("=" in line, f"no '=' in {line!r}")
    return line.split("=", 1)[1].strip()


# ── Polynomials from the givens ──────────────────────────────

def poly_of_form(g):
    if g["form"] == "general":
        return sp.expand(R(g["a"]) * X**2 + R(g["b"]) * X + R(g["c"]))
    if g["form"] == "factorised":
        return sp.expand(R(g["a"]) * (X - R(g["p"])) * (X - R(g["q"])))
    return sp.expand(R(g["a"]) * (X - R(g["h"]))**2 + R(g["k"]))


def fit(points):
    """The quadratic through the points (least three), checked against all of them."""
    A, B, C = sp.symbols("A B C")
    eqs = [sp.Eq(A * R(px)**2 + B * R(px) + C, R(py)) for px, py in points]
    sol = sp.solve(eqs[:3], [A, B, C], dict=True)
    need(len(sol) == 1, "points don't fix one quadratic")
    f = sp.expand(sol[0][A] * X**2 + sol[0][B] * X + sol[0][C])
    for px, py in points:
        need(f.subs(X, R(px)) == R(py), f"point ({px}, {py}) is not on the fitted curve")
    return f


def table_points(t):
    return list(zip(t["xs"], t["ys"]))


def with_a_through(shape, point):
    """shape(A) is a family of curves; returns the one through point."""
    A = sp.Symbol("A")
    sol = sp.solve(sp.Eq(shape(A).subs(X, R(point[0])), R(point[1])), A)
    need(len(sol) == 1 and sol[0] != 0, "the point doesn't fix a")
    return sp.expand(shape(sol[0]))


def coeffs(f):
    p = sp.Poly(f, X)
    need(p.degree() == 2, f"not a quadratic: {f}")
    a, b, c = (p.coeff_monomial(X**2), p.coeff_monomial(X), p.coeff_monomial(1))
    return a, b, c


def vertex(f):
    xs = sp.solve(sp.diff(f, X), X)
    need(len(xs) == 1, "no single turning point")
    return xs[0], sp.simplify(f.subs(X, xs[0]))


def real_roots(f):
    rs = sorted(sp.solve(f, X), key=lambda r: float(r))
    need(len(rs) == 2 and all(r.is_real for r in rs), "not two real roots")
    return rs


# ── The answer, solved again from the givens ─────────────────

def solve(q):
    """Returns (expected values, the curve f or None)."""
    u = q["view"]["unknown"]
    g = q["given"]
    kind = q["answer"]["kind"]
    f = None

    def curve_from_given():
        if "form" in g:
            return poly_of_form(g)
        if "table" in g:
            return fit(table_points(g["table"]))
        raise Fail("no curve in the givens")

    if u in ("roots-from-factorised",):
        f = poly_of_form(g)
        r = real_roots(f)
        return {"r1": r[0], "r2": r[1]}, f
    if u.startswith("y-intercept-from"):
        f = poly_of_form(g)
        return {"y": f.subs(X, 0)}, f
    if u == "axis-from-roots":
        p, r = (R(v) for v in g["roots"])
        if "form" in g:
            need(set(real_roots(poly_of_form(g))) == {p, r}, "shown form has other roots")
        return {"var": "x", "h": (p + r) / 2}, None
    if u == "axis-from-vertex":
        if "form" in g:
            need(list(vertex(poly_of_form(g))) == [R(v) for v in g["vertex"]], "shown form has another vertex")
        return {"var": "x", "h": R(g["vertex"][0])}, None
    if u == "axis-from-general":
        f = poly_of_form(g)
        return {"var": "x", "h": vertex(f)[0]}, f
    if u == "axis-from-equal-outputs":
        if "table" in g:
            f = fit(table_points(g["table"]))
            return {"var": "x", "h": vertex(f)[0]}, f
        (x1, y1), (x2, y2) = g["points"]
        need(R(y1) == R(y2), "the two points are not at the same height")
        return {"var": "x", "h": (R(x1) + R(x2)) / 2}, None
    if u == "second-root-from-axis":
        t = sp.Symbol("t")
        return {"v": sp.solve(sp.Eq((R(g["root"]) + t) / 2, R(g["axis"])), t)[0]}, None
    if u in ("b-from-axis", "coefficient-from-axis"):
        b = sp.Symbol("b")
        return {"v": sp.solve(sp.Eq(-b / (2 * R(g["a"])), R(g["axis"])), b)[0]}, None
    if u == "vertex-from-vertex-form" or u == "vertex-from-general":
        f = poly_of_form(g)
        v = vertex(f)
        return {"x": v[0], "y": v[1]}, f
    if u == "vertex-from-factorised":
        if "form" in g:
            f = poly_of_form(g)
        else:
            p, r = (R(v) for v in g["roots"])
            f = with_a_through(lambda A: A * (X - p) * (X - r), (0, g["yint"]))
        v = vertex(f)
        return {"x": v[0], "y": v[1]}, f
    if u == "vertex-from-table":
        f = fit(table_points(g["table"]))
        v = vertex(f)
        return {"x": v[0], "y": v[1], "kind": "minimum" if coeffs(f)[0] > 0 else "maximum"}, f
    if u == "max-or-min":
        if "form" in g:
            f = poly_of_form(g)
            v = vertex(f)
            return {"kind": "minimum" if coeffs(f)[0] > 0 else "maximum", "k": v[1]}, f
        return {"kind": "minimum" if g["opens"] == "up" else "maximum", "k": R(g["vertex"][1])}, None
    if u == "h-k-from-vertex":
        return {"h": R(g["vertex"][0]), "k": R(g["vertex"][1])}, None
    if u in ("vertex-form-from-general", "vertex-form-from-factorised"):
        f = poly_of_form(g)
        v = vertex(f)
        return {"a": coeffs(f)[0], "h": v[0], "k": v[1]}, f
    if u == "general-from-vertex-form":
        f = poly_of_form(g)
        a, b, c = coeffs(f)
        return {"a": a, "b": b, "c": c}, f
    if u in ("factorised-from-general", "factorised-from-vertex-form"):
        f = poly_of_form(g)
        r = real_roots(f)
        return {"a": coeffs(f)[0], "p": r[0], "q": r[1]}, f
    if u == "vertex-form-from-vertex-and-a":
        h, k = (R(v) for v in g["vertex"])
        f = sp.expand(R(g["a"]) * (X - h)**2 + k)
        return {"a": R(g["a"]), "h": h, "k": k}, f
    if u in ("a-from-vertex-and-point", "equation-from-table"):
        if "table" in g:
            f = fit(table_points(g["table"]))
        else:
            h, k = (R(v) for v in g["vertex"])
            f = with_a_through(lambda A: A * (X - h)**2 + k, g["points"][0])
        v = vertex(f)
        return {"a": coeffs(f)[0], "h": v[0], "k": v[1]}, f
    if u == "equation-from-vertex-and-root":
        h, k = (R(v) for v in g["vertex"])
        f = with_a_through(lambda A: A * (X - h)**2 + k, (g["root"], 0))
        r = real_roots(f)
        return {"a": coeffs(f)[0], "p": r[0], "q": r[1]}, f
    if u == "a-from-roots-and-point":
        if "table" in g:
            f = fit(table_points(g["table"]))
        else:
            p, r = (R(v) for v in g["roots"])
            f = with_a_through(lambda A: A * (X - p) * (X - r), g["points"][0])
        r = real_roots(f)
        return {"a": coeffs(f)[0], "p": r[0], "q": r[1]}, f
    if u == "coefficients-from-roots":
        p, r = (R(v) for v in g["roots"])
        f = sp.expand(R(g["a"]) * (X - p) * (X - r))
        _, b, c = coeffs(f)
        return {"b": b, "c": c}, f
    if u == "coefficients-from-two-points-and-axis":
        A, B, C = sp.symbols("A B C")
        eqs = [sp.Eq(A * R(px)**2 + B * R(px) + C, R(py)) for px, py in g["points"]]
        if "axis" in g:
            eqs.append(sp.Eq(-B / (2 * A), R(g["axis"])))
        else:
            eqs.append(sp.Eq(A, R(g["a"])))
        sol = sp.solve(eqs, [A, B, C], dict=True)
        need(len(sol) == 1, "the conditions don't fix one quadratic")
        f = sp.expand(sol[0][A] * X**2 + sol[0][B] * X + sol[0][C])
        a, b, c = coeffs(f)
        return ({"a": a, "b": b, "c": c} if "axis" in g else {"b": b, "c": c}), f
    if u == "range-after-finding":
        p, r = (R(v) for v in g["roots"])
        f = with_a_through(lambda A: A * (X - p) * (X - r), g["points"][0])
        up = coeffs(f)[0] > 0
        return {"var": "y", "rel": "≥" if up else "≤", "k": vertex(f)[1]}, f
    if u == "coefficients-from-three-points":
        f = fit(table_points(g["table"]) if "table" in g else g["points"])
        a, b, c = coeffs(f)
        return {"a": a, "b": b, "c": c}, f
    if u == "coefficient-from-point":
        w = g["unknown"]
        known = {k: R(v) for k, v in g["partial"].items()}
        vals = {k: known.get(k, LETTERS[k]) for k in "abc"}
        px, py = (R(v) for v in g["points"][0])
        sol = sp.solve(sp.Eq(vals["a"] * px**2 + vals["b"] * px + vals["c"], py), LETTERS[w])
        need(len(sol) == 1, "the point doesn't fix the coefficient")
        return {"v": sol[0]}, None
    if u == "match-three-forms":
        if "form" in g:
            f = poly_of_form(g)
        else:
            p, r = (R(v) for v in g["roots"])
            f = with_a_through(lambda A: A * (X - p) * (X - r), (0, g["yint"]))
            need(list(vertex(f)) == [R(v) for v in g["vertex"]], "the marked vertex is not on the curve")
        a, b, c = coeffs(f)
        r = real_roots(f)
        v = vertex(f)
        return {"ga": a, "gb": b, "gc": c, "fa": a, "fp": r[0], "fq": r[1], "va": a, "vh": v[0], "vk": v[1]}, f
    if u in ("form-for-feature", "form-for-task"):
        polys = [poly_of_form(fg) for fg in g["forms"]]
        need(polys[0] == polys[1] == polys[2], "the three forms shown are not one parabola")
        f = polys[0]
        a, b, c = coeffs(f)
        v = vertex(f)
        what = g.get("feature") or g.get("task")
        best = {"vertex": ("vertex", [v[0], v[1]]), "roots": ("factorised", real_roots(f)),
                "y-intercept": ("general", [c]), "solve": ("factorised", real_roots(f)),
                "range": ("vertex", [v[1]]), "f0": ("general", [f.subs(X, 0)])}[what]
        return {"form": best[0], "vals": best[1]}, f
    if u == "missing-form":
        f = poly_of_form(g)
        a, b, c = coeffs(f)
        disc = b**2 - 4 * a * c
        need(disc < 0, "Δ is not negative, so every form exists")
        return {"form": "factorised", "vals": [disc]}, f
    raise Fail(f"the checker has no solver for {u}")


# ── Comparing answers ────────────────────────────────────────

def values_of(kind, vals, fixed):
    """Engine values (strings) -> SymPy values; claims keep form and vals."""
    if kind == "claim":
        return {"form": vals["form"], "vals": [R(v) for v in vals["vals"]]}
    out = {}
    for k, v in vals.items():
        if k == "text":
            continue
        out[k] = v if k in WORD_SLOTS else R(v)
    for k, v in (fixed or {}).items():
        out.setdefault("fixed_" + k, R(v))
    return out


def poly_of(kind, v):
    a = v.get("a", v.get("fixed_a"))
    if kind in ("vertex_form", "vertex_form_a"):
        return sp.expand(a * (X - v["h"])**2 + v["k"])
    if kind in ("general", "general_a"):
        return sp.expand(a * X**2 + v["b"] * X + v["c"])
    if kind == "factorised":
        return sp.expand(a * (X - v["p"]) * (X - v["q"]))
    if kind == "deriv":
        return sp.expand(v["u2"] * X**2 + v["u1"] * X + v["u0"])
    if kind == "line":
        return sp.expand(v["m"] * X + v["c"])
    raise Fail(kind)


def norm(kind, v):
    """A value that is equal for two answers exactly when they mean the same thing."""
    if kind in FORM_KINDS:
        return ("poly", poly_of(kind, v))
    if kind == "triple":
        return ("triple", sp.expand(v["ga"] * X**2 + v["gb"] * X + v["gc"]),
                sp.expand(v["fa"] * (X - v["fp"]) * (X - v["fq"])), sp.expand(v["va"] * (X - v["vh"])**2 + v["vk"]))
    if kind == "roots":
        return ("roots", tuple(sorted([v["r1"], v["r2"]])))
    if kind == "points2":
        return ("points", tuple(sorted([(v["x1"], v["y1"]), (v["x2"], v["y2"])])))
    if kind == "claim":
        return ("claim", v["form"], tuple(v["vals"]))
    return tuple(sorted((k, v[k]) for k in v if not k.startswith("fixed_")))


def expected_norm(kind, exp, fixed):
    v = dict(exp)
    for k, val in (fixed or {}).items():
        v["fixed_" + k] = R(val)
    if kind in ("vertex_form_a", "general_a"):
        need(R(fixed["a"]) == exp.get("a", R(fixed["a"])), "given a differs")
    if kind in FORM_KINDS:
        if kind == "vertex_form_a":
            return ("poly", sp.expand(v["fixed_a"] * (X - v["h"])**2 + v["k"]))
        if kind == "general_a":
            return ("poly", sp.expand(v["fixed_a"] * X**2 + v["b"] * X + v["c"]))
    if kind == "triple":
        f = sp.expand(v["ga"] * X**2 + v["gb"] * X + v["gc"])
        return ("triple", f, f, f)
    if kind == "claim":
        return ("claim", v["form"], tuple(v["vals"]))
    return norm(kind, v)


def triple_right(v, f):
    n = norm("triple", v)
    return n[1] == f and n[2] == f and n[3] == f


def text_value(kind, text, fixed):
    """Reads an answer or option text back into a normalised value."""
    if kind in FORM_KINDS:
        return ("poly", parse(rhs(text)))
    if kind == "triple":
        parts = text.split(",  ")
        need(len(parts) == 3, f"triple text {text!r}")
        return ("triple",) + tuple(parse(p) for p in parts)
    if kind == "claim":
        return None
    t = text.replace("−", "-")
    nums = [R(n) for n in re.findall(r"-?\d+(?:\.\d+)?(?:/\d+)?", t)]
    if kind == "roots":
        return ("roots", tuple(sorted(nums)))
    if kind in ("point",):
        return (("x", nums[0]), ("y", nums[1]))
    if kind == "yint":
        need(nums[0] == 0, "y-intercept text without x = 0")
        return (("y", nums[1]),)
    if kind == "points2":
        need(len(nums) == 4, f"two-point text {text!r}")
        return ("points", tuple(sorted([(nums[0], nums[1]), (nums[2], nums[3])])))
    if kind == "tangent_read":
        need(len(nums) == 4 and nums[0] == nums[2] == R(fixed["x0"]), f"tangent-read text {text!r}")
        return (("m", nums[1]), ("y", nums[3]))
    if kind == "natures":
        parts = [p.split(": ") for p in t.split(",  ")]
        need(len(parts) == 2 and [R(p[0].split("= ")[1]) for p in parts] == [R(fixed["p"]), R(fixed["q"])], f"natures text {text!r}")
        return (("k1", parts[0][1]), ("k2", parts[1][1]))
    if kind in ("number", "xval"):
        return (("v", nums[-1]),)
    if kind == "axis":
        return (("h", nums[0]), ("var", t.split("=")[0].strip()))
    if kind == "maxmin":
        return (("k", nums[0]), ("kind", t.split(" ")[0]))
    if kind == "vertex_kind":
        return (("kind", t.split("a ")[-1]), ("x", nums[0]), ("y", nums[1]))
    if kind == "range":
        var, rel = t.split(" ")[0], t.split(" ")[1]
        return (("k", nums[0]), ("rel", rel), ("var", var))
    raise Fail(f"no text reader for {kind}")


# ── Clean limits ─────────────────────────────────────────────

def check_situation(q):
    s = {k: v for k, v in q["situation"].items()}
    u = q["view"]["unknown"]
    rep = q["view"]["rep"]
    a, h, k, b, c = (R(s[n]) for n in ["a", "h", "k", "b", "c"])
    f = sp.expand(a * (X - h)**2 + k)
    need(f == sp.expand(a * X**2 + b * X + c), "general form doesn't match the vertex form")
    need(R(s["disc"]) == b**2 - 4 * a * c, "Δ is wrong")
    need(a in A_ALLOWED, f"a = {a} is not a clean choice")
    if abs(a) == 3:
        need(h.q == 1 and k.q == 1 and c.q == 1, "a = ±3 with something halved")
    if h.q == 1:
        need((2 * k).q == 1, f"k = {k} is not a whole number or a half")
    need(abs(k) <= K_MAX and abs(b) <= B_MAX and abs(c) <= C_MAX, "k, b or c too big")
    need(c != 0 and h != 0, "roots, vertex and y-intercept are not distinct")
    mode = s["mode"]
    if mode == "rational":
        p, r = R(s["p"]), R(s["q"])
        need(p.q == 1 and r.q == 1 and p < r, "roots are not whole numbers with p < q")
        need(abs(p) <= ROOT_MAX and abs(r) <= ROOT_MAX, "roots too big")
        need(f == sp.expand(a * (X - p) * (X - r)), "factorised form doesn't match")
        if u not in NO_AXIS:
            need((p + r) % 2 == 0, "p + q is odd but the axis or vertex is used")
    elif mode == "surd":
        d = R(s["surd"])
        need(d in SURDS and -k / a == d, "surd roots are not h ± √d with a clean d")
        need(h.q == 1 and abs(h) <= H_MAX, "h not a small whole number")
    elif mode == "none":
        need(b**2 - 4 * a * c < 0 and h.q == 1 and abs(h) <= H_MAX and k.q == 1 and abs(k) <= 9, "no-real-roots mode out of limits")
    else:
        raise Fail(f"unknown mode {mode}")
    if s.get("x1") is not None:
        x1, y1 = R(s["x1"]), R(s["y1"])
        need(x1.q == 1 and y1.q == 1 and abs(x1) <= POINT_X_MAX, "the extra point is not small and whole")
        need(abs(y1) <= (GRAPH_Y_MAX if rep == "graph" else POINT_Y_MAX), "the extra point is too high")
        need(f.subs(X, x1) == y1 and x1 != h, "the extra point is not a clean point on the curve")
        if mode == "rational":
            need(x1 not in (R(s["p"]), R(s["q"])), "the extra point is a root")
    if q["graph"]:
        gr = q["graph"]
        need(h.q == 1 and k.q == 1 and c.q == 1, "on a graph the vertex and y-intercept must be on grid points")
        need(abs(k) <= GRAPH_Y_MAX and abs(c) <= GRAPH_Y_MAX, "the graph is too tall")
        for pnt in gr["points"]:
            px, py = sp.nsimplify(pnt["x"]), sp.nsimplify(pnt["y"])
            need(px.q == 1 and py.q == 1, f"marked point {pnt['label']} is off the grid")
            need(f.subs(X, px) == py, f"marked point {pnt['label']} is not on the curve")
            need(gr["x0"] <= px <= gr["x1"] and gr["y0"] <= py <= gr["y1"], f"marked point {pnt['label']} is outside the plot")
            need(parse_point(pnt["label"]) == (px, py), f"label {pnt['label']} is not its point")
        need(sp.nsimplify(gr["a"]) == a and sp.nsimplify(gr["h"]) == h and sp.nsimplify(gr["k"]) == k, "the drawn curve is another parabola")
    if q["table"]:
        xs = [R(v) for v in q["table"]["xs"]]
        ys = [R(v) for v in q["table"]["ys"]]
        need(all(v.q == 1 for v in xs + ys), "table values are not whole numbers")
        need(all(abs(v) <= TABLE_Y_MAX for v in ys), "table values too big")
        need(all(f.subs(X, xv) == yv for xv, yv in zip(xs, ys)), "a table value is not on the curve")
        if len(xs) == 7:
            need(xs == [xs[0] + i for i in range(7)], "table x values are not 7 consecutive whole numbers")
            need(xs[0] <= h <= xs[-1], "the table is not centred near the axis")
    return f


def parse_point(label):
    t = label.replace("−", "-").strip("()")
    xs, ys = t.split(",")
    return R(xs.strip()), R(ys.strip())


def check_lines(q, f_given):
    """The equation shown is the one in the givens."""
    g = q["given"]
    if q["view"]["rep"] == "equation" and "form" in g:
        line = q["lines"][0]
        need(line.startswith("f(x) = "), f"equation line {line!r}")
        need(parse(rhs(line)) == poly_of_form(g), f"shown {line!r} is not the given {g['form']} form")
    if q["view"]["unknown"] == "coefficient-from-point" and q["view"]["rep"] == "equation":
        w = g["unknown"]
        known = {k: R(v) for k, v in g["partial"].items()}
        want = sp.expand(sum((known.get(k, LETTERS[k])) * X**p for k, p in (("a", 2), ("b", 1), ("c", 0))))
        need(parse(rhs(q["lines"][0]), letters=[w]) == want, "shown equation with the unknown coefficient is wrong")
    if q["view"]["unknown"] == "b-from-axis" and q["view"]["rep"] == "equation":
        want = sp.expand(R(g["a"]) * X**2 + LETTERS["b"] * X + R(g["c"]))
        need(parse(rhs(q["lines"][0]), letters=["b"]) == want, "shown equation with b is wrong")


# ── One question ─────────────────────────────────────────────

# The game's default font has superscript digits but no superscript letters (FAL-499):
# a power with a letter in it is written with a caret, x^n or x^(m−1). It has no ⁻
# either (FAL-514), so a bundled DejaVu Sans subset sits behind it; the exporter asks
# the real font stack about every character, and "missing_glyphs" lists those it can't draw.
SUP_LETTER = re.compile("[ᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐⁿᵒᵖʳˢᵗᵘᵛʷˣʸᶻ]")


def check(q):
    """Routes a question to its situation's checks, then checks the answer, the
    options and the worked solutions the same way for every situation. A question in
    an extra format (FAL-459) has its own four options checked first, then the
    question it is built on, with that question's own options."""
    sup = SUP_LETTER.search(json.dumps(q, ensure_ascii=False))
    need(sup is None, f"a superscript letter {sup and sup.group()!r} the game's font can't show")
    need(not q.get("missing_glyphs"), f"characters the game's fonts can't draw: {q.get('missing_glyphs')!r}")
    if q["format"] in EXTRA_FORMATS:
        check_format(q)
        q = dict(q, choices=q["base_choices"])
    sit = q.get("situation_id", "quadratic")
    # Every question is Paper 1 or Paper 2 (FAL-419); each situation's checks hold its
    # numbers to that paper.
    need(q.get("paper") in (1, 2), f"paper is {q.get('paper')!r}, not 1 or 2")
    need(sit in SITUATION_CHECKS, f"the checker has no checks for situation {sit}")
    exp, f = SITUATION_CHECKS[sit](q)
    if exp is not None:  # the triangle and distribution checks are complete on their own
        check_common(q, exp, f)


def check_quadratic(q):
    f_sit = check_situation(q)
    exp, f = solve(q)
    if f is not None:
        need(f == f_sit, "the givens describe another parabola than the situation")
    check_lines(q, f)
    return exp, f


def check_common(q, exp, f):
    kind = q["answer"]["kind"]
    fixed = q["answer"].get("fixed") or {}
    want = expected_norm(kind, exp, fixed)
    got = values_of(kind, q["answer"]["values"], fixed)
    if kind == "triple":
        need(triple_right(got, f), "the engine's three forms are not all this parabola")
    else:
        need(norm(kind, got) == want, f"engine answer {q['answer_text']!r} is wrong (expected {exp})")
    tv = text_value(kind, q["answer_text"], fixed)
    if tv is not None:
        need(tv == norm(kind, got), f"answer text {q['answer_text']!r} doesn't say the answer's values")

    # Options: four, one right, the rest wrong and all different.
    ch = q["choices"]
    need(len(ch) == 4, f"{len(ch)} options")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right option")
    seen = set()
    texts = set()
    for o in ch:
        ov = values_of(kind, o["values"], fixed)
        n = norm(kind, ov)
        need(n not in seen, f"two options are the same: {o['text']!r}")
        seen.add(n)
        need(o["text"] not in texts, f"two options read the same: {o['text']!r}")
        texts.add(o["text"])
        right = triple_right(ov, f) if kind == "triple" else n == want
        need(right == o["correct"], f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'} but is {'right' if right else 'wrong'}")
        if kind == "claim":
            need(o["text"] == o["values"]["text"], "claim text mismatch")
        else:
            otv = text_value(kind, o["text"], fixed)
            need(otv == n, f"option text {o['text']!r} doesn't say its values")
        if o["ref"]:
            need(not o["correct"], "a misconception is the right answer")

    # Worked solutions: each ends at the answer.
    need(len(q["solutions"]) >= 1, "no worked solution")
    for sol in q["solutions"]:
        rv = values_of(kind, sol["result"], fixed)
        if kind == "triple":
            need(triple_right(rv, f), f"{sol['name']}: last step is not the answer")
        else:
            need(norm(kind, rv) == want, f"{sol['name']}: last step gives {sol['result']}, not the answer")
        last = sol["steps"][-1]
        need(last.rstrip(".").endswith(q["answer_text"].rstrip(".")) or q["answer_text"] in last,
             f"{sol['name']}: last step {last!r} doesn't state the answer")
    if q["view"]["angle"] != "any":
        need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")


# ── Triangles (FAL-395) ──────────────────────────────────────
# The `triangle` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/triangle.gd. Every value is solved again from the givens with
# SymPy and evaluated to 40 digits, so 3 s.f. rounding is decided on the true value.

TRI_SIDE = (3, 20)
TRI_ANGLE = (20, 140)
TRI_RIGHT_GAP = 10
TRI_EDGE = sp.Rational(2, 100)
TRI_AREA_MIN = 3
TRI_TOL = sp.Rational(1, 10**7)      # relative: the engine keeps nine decimal places
DIGITS = 40
LETTERS3 = ["A", "B", "C"]
# Paper 1 (FAL-419): the given angles have exact sines and cosines, and every value
# is a whole number or m√r.
TRI_NICE = {30, 45, 60, 90, 120, 135}


def deg_cos(d):
    return sp.cos(sp.pi * d / 180)


def deg_sin(d):
    return sp.sin(sp.pi * d / 180)


def to_deg(r):
    return r * 180 / sp.pi


def num(x):
    return sp.Float(x, DIGITS) if isinstance(x, (int, float)) else sp.N(x, DIGITS)


def close(a, b):
    a, b = num(a), num(b)
    return abs(a - b) <= TRI_TOL * max(abs(b), 1)


def sig3(x, n=3):
    """x to n significant figures, written as the game writes it ("7.00", "1000")."""
    d = Decimal(str(num(x)))
    e = d.copy_abs().adjusted()
    r = d.scaleb(-(e - n + 1)).quantize(Decimal(1), rounding=ROUND_HALF_UP).scaleb(e - n + 1)
    if r.copy_abs() >= Decimal(10) ** (e + 1):
        e += 1
    places = max(0, n - 1 - e)
    return f"{r:.{places}f}"


def on_edge(x):
    v = num(x)
    e = sp.floor(sp.log(v, 10))
    scaled = v / sp.Integer(10) ** (e - 2)
    return abs(scaled - sp.floor(scaled) - sp.Rational(1, 2)) < TRI_EDGE


def side_name(L):
    a, b = [x for x in LETTERS3 if x != L]
    return a + b


def angle_name(L):
    a, b = [x for x in LETTERS3 if x != L]
    return f"angle {a}{L}{b}"


def tri_area(text):
    """A shown area as the game writes it: "12", or m√r on Paper 1 ("6√3")."""
    m = re.fullmatch(r"(\d*)√(\d+)", text)
    if m:
        return (R(m[1]) if m[1] else 1) * sp.sqrt(R(m[2]))
    return R(text)


def tri_surd(e):
    """An exact positive value as (m, r): m√r with m a whole number and r square-free."""
    e = sp.radsimp(sp.simplify(e))
    m, rest = e.as_coeff_Mul()
    r = sp.simplify(rest**2)
    need(m.is_Rational and m.q == 1 and m > 0 and r.is_Integer and r >= 1 and sp.factorint(r) == {p: 1 for p in sp.factorint(r)},
         f"the value {e} is not a whole number or m√r")
    return int(m), int(r)


def tri_surd_text(m, r):
    return str(m) if r == 1 else ("" if m == 1 else str(m)) + f"√{r}"


def tri_roles(g):
    """The vertex the question turns on (X) and the other two (Y, Z), from the givens."""
    sides = {k.upper() for k in g["sides"]}
    angles = set(g["angles"])
    ask = g["ask"]
    kind = g["givens"]
    if kind in ("sas",):
        X = next(iter(angles))
    elif kind in ("sss", "area-angle"):
        X = ask
    else:  # aas, ssa, area-side: the given angle whose opposite side is given, or the only one
        X = next(iter(angles & sides)) if kind in ("aas", "ssa") else next(iter(angles))
    if kind in ("aas", "ssa"):
        Y = ask.upper()
    elif kind == "area-side":
        Y = next(iter(sides))
    else:
        Y = sorted(set(LETTERS3) - {X})[0]
    Z = (set(LETTERS3) - {X, Y}).pop()
    return X, Y, Z


def tri_solve(g):
    """Every side, angle and the area, solved from the givens alone."""
    kind = g["givens"]
    X, Y, Z = tri_roles(g)
    S = {k.upper(): R(v) for k, v in g["sides"].items()}
    A = {k: R(v) for k, v in g["angles"].items()}
    for v in list(S.values()):
        need(v.q == 1 and TRI_SIDE[0] <= v <= TRI_SIDE[1], f"given side {v} is not a whole number from 3 to 20")
    for v in A.values():
        need(v.q == 1 and TRI_ANGLE[0] <= v <= TRI_ANGLE[1], f"given angle {v} is not a whole number of degrees from 20 to 140")
    if kind == "sas":
        need(set(S) == {Y, Z} and set(A) == {X}, "sas givens are not two sides and the angle between them")
        S[X] = sp.sqrt(S[Y]**2 + S[Z]**2 - 2 * S[Y] * S[Z] * deg_cos(A[X]))
        A[Y] = to_deg(sp.acos((S[X]**2 + S[Z]**2 - S[Y]**2) / (2 * S[X] * S[Z])))
    elif kind == "sss":
        need(set(S) == set(LETTERS3) and not A, "sss givens are not three sides")
        for L, M, N in ((X, Y, Z), (Y, X, Z)):
            c = (S[M]**2 + S[N]**2 - S[L]**2) / (2 * S[M] * S[N])
            need(abs(c) < 1, "the three sides don't make a triangle")
            A[L] = to_deg(sp.acos(c))
    elif kind == "aas":
        need(set(S) == {X} and len(A) == 2 and X in A, "aas givens are not two angles and a side opposite one of them")
        if Y not in A:
            A[Y] = 180 - A[X] - A[Z]
        S[Y] = S[X] * deg_sin(A[Y]) / deg_sin(A[X])
    elif kind == "ssa":
        need(set(S) == {X, Y} and set(A) == {X}, "ssa givens are not two sides and the angle opposite one")
        need(S[X] > S[Y], "the side opposite the given angle is not the longer one, so two triangles may fit")
        A[Y] = to_deg(sp.asin(S[Y] * deg_sin(A[X]) / S[X]))
        need(num(A[X] + 180 - A[Y]) >= 180, "the obtuse angle 180° − B would also fit")
    elif kind == "area-side":
        area = tri_area(g["area"])
        need(set(S) == {Y} and set(A) == {X}, "area-side givens are not the area, a side and an angle")
        S[Z] = 2 * area / (S[Y] * deg_sin(A[X]))
        S[X] = sp.sqrt(S[Y]**2 + S[Z]**2 - 2 * S[Y] * S[Z] * deg_cos(A[X]))
        A[Y] = to_deg(sp.acos((S[X]**2 + S[Z]**2 - S[Y]**2) / (2 * S[X] * S[Z])))
    elif kind == "area-angle":
        area = tri_area(g["area"])
        need(set(S) == {Y, Z} and not A and g["obtuse"] in (True, False), "area-angle givens are not the area, two sides and acute or obtuse")
        ratio = 2 * area / (S[Y] * S[Z])
        need(ratio < 1, "no angle has that sine")
        acute = to_deg(sp.asin(ratio))
        A[X] = 180 - acute if g["obtuse"] else acute
        need(abs(num(A[X]) - 90) >= TRI_RIGHT_GAP, "the angle is too near 90° for acute or obtuse to matter")
        S[X] = sp.sqrt(S[Y]**2 + S[Z]**2 - 2 * S[Y] * S[Z] * deg_cos(A[X]))
        A[Y] = to_deg(sp.acos((S[X]**2 + S[Z]**2 - S[Y]**2) / (2 * S[X] * S[Z])))
    else:
        raise Fail(f"unknown triangle givens {kind}")
    # The asked value exactly, before the numbers take over (Paper 1 checks it exactly).
    ask = g["ask"]
    if ask == "area":
        exact = S[Y] * S[Z] * deg_sin(A[X]) / 2
    elif ask in LETTERS3:
        exact = A[ask]
    else:
        exact = S[ask.upper()]
    # From here on every quantity is a 40-digit number, which keeps the checks fast.
    S = {L: num(v) for L, v in S.items()}
    A = {L: num(v) for L, v in A.items()}
    missing = [L for L in LETTERS3 if L not in A]
    need(len(missing) <= 1, "angles left unsolved")
    for L in missing:
        A[L] = 180 - sum(A[M] for M in LETTERS3 if M != L)
    k = S[X] / deg_sin(A[X])
    for L in LETTERS3:
        if L not in S:
            S[L] = k * deg_sin(A[L])
    area = S[Y] * S[Z] * deg_sin(A[X]) / 2
    if g.get("area") is not None:
        need(close(area, tri_area(g["area"])), "the given area is not this triangle's area")
    for L in LETTERS3:
        need(TRI_ANGLE[0] <= num(A[L]) <= TRI_ANGLE[1], f"angle {L} = {num(A[L]):.4} is outside 20° to 140°")
    need(close(sum(A.values()), 180), "the angles don't add up to 180°")
    for L in LETTERS3:  # the sine rule holds all round
        need(close(S[L] / deg_sin(A[L]), k), "the sides and angles are not one triangle")
    return {"X": X, "Y": Y, "Z": Z, "S": S, "A": A, "area": area, "exact": exact}


def tri_wrongs(u, g, t):
    """Each misconception's wrong value, worked out independently of the engine."""
    X, Y, Z, S, A = t["X"], t["Y"], t["Z"], t["S"], t["A"]
    x, y, z = S[X], S[Y], S[Z]
    if u == "side-cosine-rule":
        return {"SL3.2.cosine-rule-side#0": [sp.sqrt((y**2 + z**2 - 2 * y * z) * deg_cos(A[X]))],
                "SL3.2.cosine-rule-side#1": [x**2],
                "SL3.2.right-side#2": [sp.sqrt(y**2 + z**2 - 2 * y * z * sp.cos(A[X]))]}
    if u == "angle-cosine-rule":
        return {"SL3.2.cosine-rule-angle#0": [A[Y], A[Z]], "SL3.2.cosine-rule-angle#1": [180 - A[X]]}
    if u == "side-sine-rule":
        return {"SL3.2.sine-rule#0": [x * deg_sin(A[Z]) / deg_sin(A[X])],
                "SL3.2.sine-rule#1": [x * deg_sin(A[X]) / deg_sin(A[Y])],
                "SL3.2.right-side#2": [x * sp.sin(A[Y]) / sp.sin(A[X])]}
    if u == "angle-sine-rule":
        return {"SL3.2.sine-rule#0": [to_deg(sp.asin(x * deg_sin(A[X]) / y))] if num(x * deg_sin(A[X]) / y) < 1 else [],
                "SL3.5.ambiguous-case#1": [180 - A[Y]]}
    area = t["area"]
    if u == "area-from-two-sides":
        return {"SL3.2.area-sine#2": [2 * area], "SL3.2.right-side#2": [y * z * sp.sin(A[X]) / 2]}
    if u == "side-from-area":
        return {"SL3.2.area-sine#2": [tri_area(g["area"]) / (y * deg_sin(A[X]))]}
    if u == "angle-from-area":
        acute = to_deg(sp.asin(2 * tri_area(g["area"]) / (y * z)))
        half = to_deg(sp.asin(tri_area(g["area"]) / (y * z)))
        return {"SL3.2.area-sine#1": [acute], "SL3.2.area-sine#2": [180 - half if g["obtuse"] else half]}
    raise Fail(f"no misconceptions known for {u}")


def tri_shown(q, g):
    """What the student sees says exactly the givens: the words line, or the diagram
    and its caption."""
    rep = q["view"]["rep"]
    text = " ".join(q["lines"])
    sides = {m[1]: m[2] for m in re.finditer(r"\b([ABC]{2}) = (\d+) cm", text)}
    angles = {m[1][1]: m[2] for m in re.finditer(r"angle ([ABC]{3}) = (\d+)°", text)}
    m = re.search(r"area (?:of|is) (\d*√\d+|\d+) cm²", text)
    area = m[1] if m else None
    m = re.search(r"Angle ([ABC]{3}) is (obtuse|acute)", text)
    obtuse = (m[2] == "obtuse") if m else None
    if m:
        need(m[1] == angle_name(g["ask"])[6:], "the acute or obtuse angle is not the asked one")
    if rep == "diagram":
        need(not sides and not angles, "a diagram question also lists sides or angles in words")
        dg = q["diagram"]
        need(dg is not None, "no diagram")
        for sd in dg["sides"]:
            if sd["label"].endswith(" cm"):
                sides[side_name(sd["side"].upper())] = sd["label"][:-3]
            else:
                need(sd["label"] in ("", "?"), f"side label {sd['label']!r}")
                need((sd["label"] == "?") == (g["ask"] == sd["side"]), "the ? is not on the asked side")
        for an in dg["angles"]:
            if an["label"].endswith("°"):
                angles[an["at"]] = an["label"][:-1]
            else:
                need(an["label"] in ("", "?"), f"angle label {an['label']!r}")
                need((an["label"] == "?") == (g["ask"] == an["at"]), "the ? is not on the asked angle")
    else:
        need(q["diagram"] is None, "a words question has a diagram")
        need(len(q["lines"]) == 1 and q["lines"][0].endswith("."), "the words are not one sentence or two")
    want_sides = {side_name(k.upper()): v for k, v in g["sides"].items()}
    need(sides == want_sides, f"shown sides {sides} are not the given {want_sides}")
    need(angles == g["angles"], f"shown angles {angles} are not the given {g['angles']}")
    need(area == g["area"], f"shown area {area} is not the given {g['area']}")
    need(obtuse == g["obtuse"], "acute or obtuse is not as given")


def tri_diagram(q, t):
    """The drawing is this triangle, to scale."""
    v = {L: sp.Matrix([sp.Float(c, DIGITS) for c in p]) for L, p in q["diagram"]["vertices"].items()}
    for L in LETTERS3:
        M, N = [x for x in LETTERS3 if x != L]
        need(close(sp.sqrt(((v[M] - v[N]).T * (v[M] - v[N]))[0]), t["S"][L]), f"the drawn side {M}{N} is not to scale")


def tri_measure(q, t):
    """The asked quantity, its label and unit, solved from the givens."""
    ask = q["given"]["ask"]
    if ask == "area":
        return t["area"], "Area = ", " cm²"
    if ask in LETTERS3:
        return t["A"][ask], angle_name(ask) + " = ", "°"
    return t["S"][ask.upper()], side_name(ask.upper()) + " = ", " cm"


# The worked steps' arithmetic (FAL-412): every "expr = value" in a step, where the expr
# is numbers only ("½ × 16 × 10.47", "√305.2", "sin⁻¹(0.5333)", "3 − (−5/2)"), is
# evaluated exactly from the figures shown. A decimal value on Paper 2 must be the
# expr correctly rounded to the places it shows, so following the printed working
# reaches the printed numbers; anything else (a fraction, a surd, all of Paper 1)
# must equal it.

TRI_TOKEN = re.compile(r"\s*(?:(?P<num>\d+(?:\.\d+)?)|(?P<fn>(?:sin|cos|tan)(?:⁻¹)?(?![A-Za-z]))|(?P<word>[A-Za-z]+)"
                       r"|(?P<op>[−+×÷/()²°√½])|(?P<punct>[,.:;<>]))")
TRI_FNS = {"sin": deg_sin, "cos": deg_cos, "tan": lambda d: sp.tan(sp.pi * d / 180),
           "sin⁻¹": lambda x: to_deg(sp.asin(x)), "cos⁻¹": lambda x: to_deg(sp.acos(x)), "tan⁻¹": lambda x: to_deg(sp.atan(x))}


def tri_tokens(text):
    out, i = [], 0
    while i < len(text):
        m = TRI_TOKEN.match(text, i)
        if not m or m.end() == i:
            if text[i:].strip() == "":
                break
            out.append(("other", text[i]))
            i += 1
            continue
        kind = m.lastgroup
        out.append((kind, m[kind]))
        i = m.end()
    return out


class TriParse:
    """Numbers, + − × ÷ /, ², √, ½, brackets, a factor written next to the one before it
    ("5 sin 65°", "7√3") and sin, cos, sin⁻¹ and cos⁻¹ in degrees. ° only marks degrees."""

    def __init__(self, toks):
        self.t, self.i = toks, 0

    def peek(self):
        return self.t[self.i] if self.i < len(self.t) else (None, None)

    def take(self, value=None):
        tok = self.peek()
        if tok[0] is None or (value is not None and tok[1] != value):
            raise Fail("parse")
        self.i += 1
        return tok

    def expr(self):
        v = self.term()
        while self.peek()[1] in ("+", "−"):
            v = v + self.term() if self.take()[1] == "+" else v - self.term()
        return v

    def starts_factor(self):
        k, s = self.peek()
        return k in ("num", "fn") or s in ("(", "√", "½")

    def term(self):
        v = self.unary()
        while True:
            s = self.peek()[1]
            if s in ("×", "÷", "/"):
                self.take()
                w = self.unary()
                v = v * w if s == "×" else v / w
            elif self.starts_factor():
                v = v * self.power()
            else:
                return v

    def unary(self):
        if self.peek()[1] == "−":
            self.take()
            return -self.unary()
        return self.power()

    def power(self):
        v = self.primary()
        while self.peek()[1] in ("²", "°"):
            if self.take()[1] == "²":
                v = v**2
        return v

    def primary(self):
        k, s = self.peek()
        if k == "num":
            self.take()
            return sp.Rational(s)
        if s == "½":
            self.take()
            return sp.Rational(1, 2)
        if s == "(":
            self.take()
            v = self.expr()
            self.take(")")
            return v
        if s == "√":
            self.take()
            return sp.sqrt(self.primary())
        if k == "fn":
            self.take()
            arg = self.primary()
            if self.peek()[1] == "°":
                self.take()
            return TRI_FNS[s](arg)
        raise Fail("parse")


def tri_value(toks):
    """The value of tokens that are all one numeric expression, else None."""
    if not toks or any(k in ("word", "punct", "other") for k, _ in toks):
        return None
    p = TriParse(toks)
    try:
        v = p.expr()
    except (Fail, ZeroDivisionError, TypeError, ValueError):
        return None
    return v if p.i == len(toks) else None


def tri_is_working(toks):
    """Something is worked out: an operation, not a number on its own."""
    return any(k == "fn" or s in ("+", "−", "×", "÷", "/", "²", "√", "½") for k, s in toks)


def tri_lhs(text):
    """The numeric expression a segment ends with, after its prose: the longest
    numeric tail that follows nothing, punctuation or a word (not a letter standing
    for a side or angle, nor an operator, which would make the tail part of a formula)."""
    toks = tri_tokens(text)
    for start in range(len(toks)):
        tail = toks[start:]
        v = tri_value(tail)
        if v is None:
            continue
        before = toks[start - 1] if start else None
        if before is None or before[0] == "punct" or (before[0] == "word" and len(before[1]) > 1):
            return tail, v
        return None
    return None


def tri_rhs(text):
    """The value a segment starts with: its longest numeric head, followed by nothing,
    punctuation or a word (a unit or prose), not by more of a formula."""
    toks = tri_tokens(text)
    for end in range(len(toks), 0, -1):
        head = toks[:end]
        v = tri_value(head)
        if v is None:
            continue
        after = toks[end] if end < len(toks) else None
        if after is None or after[0] == "punct" or (after[0] == "word" and len(after[1]) > 1):
            return head, v
        return None
    return None


def tri_rounds_to(v, shown):
    """v, correctly rounded to the places shown ("83.7", "0.5333", "148"), is shown."""
    places = len(shown.split(".")[1]) if "." in shown else 0
    d = Decimal(str(sp.N(v, DIGITS)))
    step = Decimal(1).scaleb(-places)
    return d.quantize(step, rounding=ROUND_HALF_UP) == Decimal(shown)


def tri_working(q, sol):
    """Each "expr = value" in a worked solution holds for the figures shown. Returns
    how many were checked."""
    checked = 0
    for st in sol["steps"]:
        parts = st.split(" = ")
        for left, right in zip(parts, parts[1:]):
            lhs, rhs = tri_lhs(left), tri_rhs(right)
            if lhs is None or rhs is None or not tri_is_working(lhs[0]):
                continue
            (_, lv), (rtoks, rv) = lhs, rhs
            plain = [s for k, s in rtoks if s != "°"]
            if q.get("paper") == 2 and len(plain) == 1 and rtoks[0][0] == "num":
                ok = tri_rounds_to(lv, plain[0])
            else:
                ok = abs(num(lv) - num(rv)) <= sp.Float(10, DIGITS)**-25 * max(abs(num(rv)), 1)
            need(ok, f"{sol['name']}: in {st!r}, {left.strip()} is {num(lv):.10}, not {right.split(',')[0].strip()}")
            checked += 1
    return checked


# The ambiguous case (t3-ambiguous-case, FAL-412): two sides and an angle opposite one of
# them. The triangles that fit are solved twice, from the sine rule with both angles
# and from the cosine rule as a quadratic in the third side, and must agree. Both, or
# the one, must keep every angle inside the limits. Paper 2 only.

AMB_GIVENS = {"both-angles": "ssa-two", "both-sides": "ssa-two", "largest-angle": "ssa-mix"}


def amb_solve(g):
    """Every triangle that fits the givens: X the given angle, Y the other side's angle,
    Z the third; each triangle has "Y" (degrees), "Z" and "z" (cm), acute Y first."""
    need(len(g["sides"]) == 2 and len(g["angles"]) == 1, "the givens are not two sides and an angle")
    X = next(iter(g["angles"]))
    need(X.lower() in g["sides"], "the given angle is not opposite a given side")
    Y = next(k.upper() for k in g["sides"] if k.upper() != X)
    Z = (set(LETTERS3) - {X, Y}).pop()
    x, y, ax = R(g["sides"][X.lower()]), R(g["sides"][Y.lower()]), R(g["angles"][X])
    for v in (x, y):
        need(v.q == 1 and TRI_SIDE[0] <= v <= TRI_SIDE[1], f"given side {v} is not a whole number from 3 to 20")
    need(ax.q == 1 and TRI_ANGLE[0] <= ax <= TRI_ANGLE[1], f"given angle {ax} is not a whole number of degrees from 20 to 140")
    ratio = y * deg_sin(ax) / x
    need(num(ratio) < 1, "side x doesn't reach the line, so no triangle fits")
    acute = num(to_deg(sp.asin(ratio)))
    tris = []
    for ay in (acute, 180 - acute):
        az = 180 - num(ax) - ay
        if az > 0:
            tris.append({"Y": ay, "Z": az, "z": num(x * deg_sin(az) / deg_sin(ax))})
    b, c = num(2 * y * deg_cos(ax)), num(y**2 - x**2)
    d = sp.sqrt(b**2 - 4 * c)
    roots = sorted([r for r in ((b + d) / 2, (b - d) / 2) if r > 0], reverse=True)
    need(len(roots) == len(tris), f"the sine rule fits {len(tris)} triangles, the cosine rule {len(roots)}")
    for tr, r in zip(tris, roots):
        need(close(tr["z"], r), "the sine rule and the cosine rule give different third sides")
        for a in (ax, tr["Y"], tr["Z"]):
            need(TRI_ANGLE[0] <= num(a) <= TRI_ANGLE[1], f"an angle of {num(a):.4} is outside 20° to 140°")
    return {"X": X, "Y": Y, "Z": Z, "x": x, "y": y, "ax": ax, "tris": tris, "acute": acute}


def amb_needs_calculator(v):
    return not any(abs(num(v) * d - round(num(v) * d)) < sp.Float("1e-7", DIGITS) * d for d in range(1, 25))


def amb_wrongs(u, t):
    """Each misconception's wrong value(s), worked out independently of the engine."""
    x, y, ax, tris, acute = t["x"], t["y"], t["ax"], t["tris"], t["acute"]
    swapped = num(x * deg_sin(ax) / y)
    w = num(to_deg(sp.asin(swapped))) if swapped < 1 else None
    if u == "both-angles":
        return {"SL3.5.ambiguous-case#0": [(acute,)], "SL3.2.sine-rule#0": [] if w is None else [(w, 180 - w)]}
    if u == "both-sides":
        return {"SL3.5.ambiguous-case#0": [(tris[0]["z"],)],
                "SL3.2.sine-rule#0": [tuple(x * deg_sin(tr["Z"]) / deg_sin(acute) for tr in tris)]}
    out = {"SL3.2.sine-rule#0": [] if w is None else [(w,)]}
    out["SL3.5.ambiguous-case#0" if len(tris) == 2 else "SL3.5.ambiguous-case#1"] = [(acute if len(tris) == 2 else 180 - acute,)]
    return out


def amb_diagram(q, t):
    """Both triangles to scale on one base line: X, then the two places of Y, with Z above."""
    dg = q["diagram"]
    v = {L: sp.Matrix([sp.Float(c, DIGITS) for c in p]) for L, p in dg["vertices"].items()}
    X, Y, Z = t["X"], t["Y"], t["Z"]
    need(dg["second"]["vertex"] == Y, "the second place is not the asked vertex's")
    other = sp.Matrix([sp.Float(c, DIGITS) for c in dg["second"]["at"]])
    dist = lambda p, r: sp.sqrt(((p - r).T * (p - r))[0])
    need(close(dist(v[X], v[Z]), t["y"]), "the drawn side y is not to scale")
    for p, tr in ((v[Y], t["tris"][0]), (other, t["tris"][1])):
        need(close(dist(p, v[X]), tr["z"]), "a drawn third side is not to scale")
        need(close(dist(p, v[Z]), t["x"]), "a drawn side x is not to scale")
        need(num(p[1]) == 0 and num(v[X][1]) == 0, "the two places are not on one base line")


def amb_values(o):
    """An option's values: both, or the one it stops at."""
    return (R(o["values"]["v1"]),) if o["values"].get("only") else (R(o["values"]["v1"]), R(o["values"]["v2"]))


def amb_text(label, unit, vals):
    return label + " or ".join(sig3(v) + unit for v in sorted(vals, key=num))


def check_ambiguous(q, u):
    g = q["given"]
    need(g["givens"] == AMB_GIVENS[u], f"{u} is asked from {g['givens']} givens")
    need(q.get("paper") == 2, "the ambiguous case is asked on Paper 1")
    t = amb_solve(g)
    X, Y, Z, tris = t["X"], t["Y"], t["Z"], t["tris"]
    if g["givens"] == "ssa-two":
        need(len(tris) == 2, "two triangles don't fit")
        need(t["x"] < t["y"], "the side opposite the given angle is not the shorter one")
    need(len(tris) == 1 or abs(t["acute"] - 90) >= TRI_RIGHT_GAP, "the two triangles are too near alike")
    tri_shown(q, g)
    if q["diagram"] is not None:
        need(len(tris) == 2, "a diagram of the ambiguous case with one triangle")
        amb_diagram(q, t)
    sit = q["situation"]
    need(close(R(sit["angles"][Y]), tris[0]["Y"]) and close(R(sit["sides"][Z.lower()]), tris[0]["z"]), "the situation is another triangle")
    if len(tris) == 2:
        need("second" in sit, "the situation has no second triangle")
        need(close(R(sit["second"]["angles"][Y]), tris[1]["Y"]) and close(R(sit["second"]["sides"][Z.lower()]), tris[1]["z"]), "the situation's second triangle differs")
    else:
        need("second" not in sit, "the situation has a second triangle that doesn't fit")

    if u == "both-angles":
        want, label, unit = tuple(tr["Y"] for tr in tris), angle_name(Y) + " = ", "°"
        need(g["ask"] == Y, "the asked angle is not the other side's")
    elif u == "both-sides":
        want, label, unit = tuple(tr["z"] for tr in tris), side_name(Z) + " = ", " cm"
        need(g["ask"] == Z.lower(), "the asked side is not the third side")
    else:
        want, label, unit = (max(tr["Y"] for tr in tris),), angle_name(Y) + " = ", "°"
    for v in want:
        need(amb_needs_calculator(v), f"the answer {num(v):.8} needs no calculator")
        need(not on_edge(v), f"the answer {num(v):.8} is on a 3 s.f. rounding edge")

    ans = q["answer"]
    kind = "measures" if len(want) == 2 else "measure"
    need(ans["kind"] == kind, f"answer kind {ans['kind']}")
    need(ans["label"] == label and ans["unit"] == unit, f"answer label {ans['label']!r}{ans['unit']!r}, expected {label!r}{unit!r}")
    ids = ("v1", "v2") if kind == "measures" else ("v",)
    got = sorted((R(ans["values"][i]) for i in ids), key=num)
    for a, b in zip(got, sorted(want, key=num)):
        need(close(a, b), f"engine answer {num(a):.8} is wrong (expected {num(b):.8})")
    text = amb_text(label, unit, want)
    need(q["answer_text"] == text, f"answer text {q['answer_text']!r}, expected {text!r}")
    if kind == "measures":
        need(sig3(want[0]) != sig3(want[1]), "the two values read the same")
        need(sorted(ans["unordered"][0]) == ["v1", "v2"], "the two values are not in either order")

    ch = q["choices"]
    need(len(ch) == 4, f"{len(ch)} options")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right option")
    wrongs = amb_wrongs(u, t)
    texts = set()
    for o in ch:
        ov = amb_values(o) if kind == "measures" else (R(o["values"]["v"]),)
        for v in ov:
            need(v > 0, f"option {o['text']!r} is not positive")
            need(not on_edge(v), f"option {o['text']!r} is on a 3 s.f. rounding edge ({num(v):.8})")
        need(o["text"] == amb_text(label, unit, ov), f"option text {o['text']!r} doesn't say its values")
        need(o["text"] not in texts, f"two options read the same: {o['text']!r}")
        texts.add(o["text"])
        right = o["text"] == text
        need(right == o["correct"], f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'} but is {'right' if right else 'wrong'}")
        if o["ref"]:
            need(not o["correct"], "a misconception is the right answer")
            need(o["ref"] in wrongs, f"{o['ref']} is not a misconception of {u}")
            sorted_ov = sorted(ov, key=num)
            need(any(len(w) == len(ov) and all(close(a, b) for a, b in zip(sorted_ov, sorted(w, key=num))) for w in wrongs[o["ref"]]),
                 f"option {o['text']!r} is not what {o['ref']} gives")

    need(len(q["solutions"]) >= 1, "no worked solution")
    for sol in q["solutions"]:
        rv = sorted((R(sol["result"][i]) for i in ids), key=num)
        need(all(close(a, b) for a, b in zip(rv, sorted(want, key=num))), f"{sol['name']}: last step doesn't give the answer")
        need(q["answer_text"] in sol["steps"][-1], f"{sol['name']}: last step {sol['steps'][-1]!r} doesn't state the answer")
        need(tri_working(q, sol) > 0, f"{sol['name']}: no step works anything out")
    need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")
    return None, None


def check_triangle(q):
    g = q["given"]
    u = q["view"]["unknown"]
    if u in AMB_GIVENS:
        return check_ambiguous(q, u)
    want_givens = {"side-cosine-rule": ("sas", None), "angle-cosine-rule": ("sss", None), "side-sine-rule": ("aas", None),
                   "angle-sine-rule": ("ssa", None), "area-from-two-sides": ("sas", "area"), "side-from-area": ("area-side", None),
                   "angle-from-area": ("area-angle", None)}
    need(u in want_givens, f"the checker has no solver for {u}")
    need(g["givens"] == want_givens[u][0], f"{u} is asked from {g['givens']} givens")
    need((g["ask"] == "area") == (want_givens[u][1] == "area"), "the area is asked on the wrong unknown")
    paper = q.get("paper")
    need(paper in (1, 2), f"paper {paper!r}")
    need(paper == 2 or u != "angle-sine-rule", "the sine rule's angle is asked on Paper 1")
    t = tri_solve(g)
    tri_shown(q, g)
    if q["diagram"] is not None:
        tri_diagram(q, t)
    exp, label, unit = tri_measure(q, t)

    # The situation the engine exported is the same triangle.
    sit = q["situation"]
    for L in LETTERS3:
        need(close(R(sit["angles"][L]), t["A"][L]), f"situation angle {L} differs")
        need(close(R(sit["sides"][L.lower()]), t["S"][L]), f"situation side {L.lower()} differs")
    need(close(R(sit["area"]), t["area"]), "situation area differs")
    if paper == 1:
        tri_check_p1(q, g, t, u, label, unit)
        return None, None
    need(t["exact"].is_rational is not True, f"the Paper 2 answer {t['exact']} needs no calculator")
    need(not on_edge(exp), f"the answer {num(exp):.8} is on a 3 s.f. rounding edge")

    # The answer: its value, and its text to 3 s.f. with the right label and unit.
    ans = q["answer"]
    need(ans["kind"] == "measure", f"answer kind {ans['kind']}")
    need(ans["label"] == label and ans["unit"] == unit, f"answer label {ans['label']!r}{ans['unit']!r}, expected {label!r}{unit!r}")
    got = R(ans["values"]["v"])
    need(close(got, exp), f"engine answer {num(got):.8} is wrong (expected {num(exp):.8})")
    need(q["answer_text"] == label + sig3(exp) + unit, f"answer text {q['answer_text']!r}, expected {label + sig3(exp) + unit!r}")

    # Options: four, one right, the rest wrong at 3 s.f., all different, each saying
    # its own value; a misconception's value is the one that slip gives.
    ch = q["choices"]
    need(len(ch) == 4, f"{len(ch)} options")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right option")
    wrongs = tri_wrongs(u, g, t)
    texts = set()
    for o in ch:
        ov = R(o["values"]["v"])
        need(ov > 0, f"option {o['text']!r} is not positive")
        need(not on_edge(ov), f"option {o['text']!r} is on a 3 s.f. rounding edge ({num(ov):.8})")
        need(o["text"] == label + sig3(ov) + unit, f"option text {o['text']!r} doesn't say its value {num(ov):.8}")
        need(o["text"] not in texts, f"two options read the same: {o['text']!r}")
        texts.add(o["text"])
        right = sig3(ov) == sig3(exp)
        need(right == o["correct"], f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'} but is {'right' if right else 'wrong'}")
        if o["correct"]:
            need(close(ov, exp), "the right option is not the answer")
        if o["ref"]:
            need(not o["correct"], "a misconception is the right answer")
            need(o["ref"] in wrongs, f"{o['ref']} is not a misconception of {u}")
            need(any(close(ov, w) for w in wrongs[o["ref"]]), f"option {o['text']!r} is not what {o['ref']} gives")

    # Worked solutions: each ends at the answer.
    need(len(q["solutions"]) >= 1, "no worked solution")
    for sol in q["solutions"]:
        need(close(R(sol["result"]["v"]), exp), f"{sol['name']}: last step gives {num(R(sol['result']['v'])):.8}, not the answer")
        last = sol["steps"][-1]
        need(q["answer_text"] in last, f"{sol['name']}: last step {last!r} doesn't state the answer")
        need(tri_working(q, sol) > 0, f"{sol['name']}: no step works anything out")
    if q["view"]["angle"] != "any":
        need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")
    return None, None


def tri_check_p1(q, g, t, u, label, unit):
    """A Paper 1 triangle: nice angles given, the answer exact (a whole number or m√r)
    and marked exactly, the options exact and wrong, the working ending at it."""
    for v in g["angles"].values():
        need(int(v) in TRI_NICE, f"Paper 1 angle {v}° has no exact sine")
    if g.get("area") is not None:
        tri_surd(tri_area(g["area"]))
    m, r = tri_surd(t["exact"])
    ans = q["answer"]
    need(ans.get("exact") is True, "a Paper 1 answer is not marked exactly")
    need(ans["label"] == label and ans["unit"] == unit, f"answer label {ans['label']!r}{ans['unit']!r}, expected {label!r}{unit!r}")

    def value(v):
        """An option's values as (m, r), checked to be a whole number or m√r."""
        if ans["kind"] == "number":
            need(set(v) == {"v"}, f"values {v}")
            return tri_surd(R(v["v"]))
        need(ans["kind"] == "surd" and set(v) == {"m", "r"}, f"answer kind {ans['kind']}")
        got = tri_surd(R(v["m"]) * sp.sqrt(R(v["r"])))
        need(got == (int(R(v["m"])), int(R(v["r"]))), f"{v} is not in simplest surd form")
        return got

    need(ans["kind"] == ("number" if r == 1 else "surd"), f"answer kind {ans['kind']} for {tri_surd_text(m, r)}")
    need(value(ans["values"]) == (m, r), f"engine answer {q['answer_text']!r} is wrong (expected {tri_surd_text(m, r)})")
    want = label + tri_surd_text(m, r) + unit
    need(q["answer_text"] == want, f"answer text {q['answer_text']!r}, expected {want!r}")

    ch = q["choices"]
    need(len(ch) == 4, f"{len(ch)} options")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right option")
    wrongs = tri_wrongs(u, g, t)
    texts = set()
    for o in ch:
        om, orr = value(o["values"])
        need(o["text"] == label + tri_surd_text(om, orr) + unit, f"option text {o['text']!r} doesn't say its value")
        need(o["text"] not in texts, f"two options read the same: {o['text']!r}")
        texts.add(o["text"])
        need(((om, orr) == (m, r)) == o["correct"], f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'} wrongly")
        if o["ref"]:
            need(not o["correct"], "a misconception is the right answer")
            need(o["ref"] in wrongs, f"{o['ref']} is not a misconception of {u}")
            need(any(close(om * sp.sqrt(orr), w) for w in wrongs[o["ref"]]), f"option {o['text']!r} is not what {o['ref']} gives")
            need(o["ref"] != "SL3.2.right-side#2", "a calculator slip on Paper 1")

    need(len(q["solutions"]) >= 1, "no worked solution")
    for sol in q["solutions"]:
        need(value(sol["result"]) == (m, r), f"{sol['name']}: last step gives {sol['result']}, not the answer")
        last = sol["steps"][-1]
        need(q["answer_text"] in last, f"{sol['name']}: last step {last!r} doesn't state the answer")
        need(2 <= len(sol["steps"]) <= 8, f"{sol['name']}: {len(sol['steps'])} steps")
        need(not any(w in " ".join(sol["steps"]) for w in ("GDC", "sin⁻¹", "cos⁻¹", "3 s.f.")), f"{sol['name']}: a calculator step on Paper 1")
        need(tri_working(q, sol) > 0, f"{sol['name']}: no step works anything out")
    if q["view"]["angle"] != "any":
        need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")


# ── Arithmetic sequences (FAL-392) ───────────────────────────
# The `arithmetic-sequence` situation's clean limits, the checker's own copy: the
# engine's is in game/engine/situations/arithmetic_sequence.gd.

U1, D, NN = sp.symbols("u1 d n")
SEQ_U1_MAX, SEQ_D_MAX = 40, 12
SEQ_N_TERM, SEQ_N_SUM = (6, 60), (5, 30)
SEQ_UN_MAX, SEQ_SN_MAX = 400, 4000
SEQ_P, SEQ_GAP, SEQ_Q_MAX = (2, 12), (2, 8), 20
SEQ_TERM_UNKNOWNS = {"term-from-u1-d", "n-from-term"}
SUBSCRIPTS = str.maketrans("₀₁₂₃₄₅₆₇₈₉ₙ", "0123456789n")
INT = r"(-?\d+)"


def seq_term(k):
    return U1 + (k - 1) * D


def seq_sum(k):
    return k * (2 * U1 + (k - 1) * D) / 2


def seq_given_eqs(g):
    """Equations in u1, d and n from the givens."""
    eqs = []
    for key, sym in (("u1", U1), ("d", D), ("n", NN)):
        if key in g:
            eqs.append(sp.Eq(sym, R(g[key])))
    for k, v in g.get("terms", []):
        eqs.append(sp.Eq(seq_term(R(k)), R(v)))
    for key in ("un", "value"):
        if key in g:
            eqs.append(sp.Eq(seq_term(NN), R(g[key])))
    if "sum" in g:
        eqs.append(sp.Eq(seq_sum(NN), R(g["sum"])))
    return eqs


def seq_shown_eqs(q):
    """Equations in u1, d and n read back from what the student sees: the notation
    line, the list of terms, the table, the words and the question itself."""
    rep = q["view"]["rep"]
    text = " ".join([q["asked"]] + q["lines"]).replace("−", "-").translate(SUBSCRIPTS)
    eqs = []
    if rep == "notation":
        for part in q["lines"][0].replace("−", "-").translate(SUBSCRIPTS).split(",  "):
            lhs, rhs_ = (x.strip() for x in part.split("="))
            v = R(rhs_)
            m = re.fullmatch(r"([uS])(\d+|n)", lhs)
            if lhs == "d":
                eqs.append(sp.Eq(D, v))
            elif m:
                k = NN if m.group(2) == "n" else R(m.group(2))
                eqs.append(sp.Eq((seq_term if m.group(1) == "u" else seq_sum)(k), v))
            else:
                raise Fail(f"can't read {part!r} in the notation line")
    elif rep == "terms":
        line = q["lines"][0]
        need(line.endswith(", …"), f"terms line {line!r}")
        vals = [R(v) for v in line[:-3].replace("−", "-").split(", ")]
        eqs += [sp.Eq(seq_term(i + 1), v) for i, v in enumerate(vals)]
    elif rep == "table":
        t = q["table"]
        need(t.get("heads") == ["n", "uₙ"], "the table is not headed n and uₙ")
        eqs += [sp.Eq(seq_term(R(k)), R(v)) for k, v in zip(t["xs"], t["ys"])]
    elif rep != "words":
        raise Fail(f"unknown representation {rep}")
    for pat, make in [
        (r"first term of an arithmetic sequence is " + INT, lambda m: [sp.Eq(U1, R(m[1]))]),
        (r"common difference(?: of an arithmetic sequence)? is " + INT, lambda m: [sp.Eq(D, R(m[1]))]),
        (r"(\d+)(?:st|nd|rd|th) term(?: of an arithmetic sequence)? is " + INT, lambda m: [sp.Eq(seq_term(R(m[1])), R(m[2]))]),
        (r"sum of its first (\d+) terms is " + INT, lambda m: [sp.Eq(seq_sum(R(m[1])), R(m[2]))]),
        (r"sum of (?:its|the) first n terms is " + INT, lambda m: [sp.Eq(seq_sum(NN), R(m[1]))]),
        (r"(?:One of its terms|Which term of the sequence) is " + INT, lambda m: [sp.Eq(seq_term(NN), R(m[1]))]),
        (r"Find ([uS])(\d+)\b", lambda m: [sp.Eq(NN, R(m[2]))]),
        (r"Find the (\d+)(?:st|nd|rd|th) term", lambda m: [sp.Eq(NN, R(m[1]))]),
        (r"first (\d+) terms", lambda m: [sp.Eq(NN, R(m[1]))]),
    ]:
        for m in re.finditer(pat, text):
            eqs += make(m)
    return eqs


def seq_solve(eqs, what):
    """The one solution with n a positive whole number (or n not involved), plus
    every root SymPy found, so the rejected one can be checked."""
    sols = sp.solve(eqs, [U1, D, NN], dict=True)
    good = [s for s in sols if NN not in s or (s[NN].is_integer and s[NN] > 0)]
    need(len(good) == 1, f"the {what} give {len(good)} sequences, not one: {sols}")
    sol = good[0]
    need(U1 in sol and D in sol, f"the {what} don't fix u1 and d")
    return sol, sols


def check_arithmetic(q):
    u = q["view"]["unknown"]
    if q.get("paper", 1) == 2:
        return seq_check_p2(q)
    s = {k: v for k, v in q["situation"].items()}
    u1, d, n, un, sn = (R(s[k]) for k in ("u1", "d", "n", "un", "sn"))
    need(all(v.q == 1 for v in (u1, d, n, un, sn)), "a value is not a whole number")
    need(u1 != 0 and abs(u1) <= SEQ_U1_MAX, f"u1 = {u1} is out of limits")
    need(d != 0 and abs(d) <= SEQ_D_MAX, f"d = {d} is out of limits")
    lo, hi = SEQ_N_TERM if u in SEQ_TERM_UNKNOWNS else SEQ_N_SUM
    need(lo <= n <= hi, f"n = {n} is outside {lo} to {hi}")
    sit = {U1: u1, D: d, NN: n}
    need(un == seq_term(n).subs(sit) and abs(un) <= SEQ_UN_MAX, "u_n is wrong or too big")
    need(sn == seq_sum(n).subs(sit) and sn != 0 and abs(sn) <= SEQ_SN_MAX, "S_n is wrong, zero or too big")
    need([R(v) for v in s["us"]] == [seq_term(k).subs(sit) for k in (1, 2, 3, 4)], "the first terms are wrong")
    if s.get("p") is not None:
        p, r = R(s["p"]), R(s["q"])
        need(SEQ_P[0] <= p <= SEQ_P[1] and SEQ_GAP[0] <= r - p <= SEQ_GAP[1] and r <= SEQ_Q_MAX, "p and q are out of limits")
        need(R(s["up"]) == seq_term(p).subs(sit) and R(s["uq"]) == seq_term(r).subs(sit), "u_p or u_q is wrong")
        need(abs(R(s["up"])) <= SEQ_UN_MAX and abs(R(s["uq"])) <= SEQ_UN_MAX, "u_p or u_q is too big")

    sol, roots = seq_solve(seq_given_eqs(q["given"]), "givens")
    need(sol[U1] == u1 and sol[D] == d, "the givens describe another sequence than the situation")
    if NN in sol:
        need(sol[NN] == n, "the givens give another n than the situation")
    shown, _ = seq_solve(seq_shown_eqs(q), "question as shown")
    need(shown == sol, f"the question as shown gives {shown}, the givens {sol}")

    if u == "n-from-sum":
        rejected = [r[NN] for r in roots if r[NN] != n]
        need(len(rejected) == 1 and rejected[0].is_integer and rejected[0] < 0, f"the other root is not a negative whole number: {roots}")
        need(R(s["other"]) == rejected[0], "the situation's other root is wrong")
        need(any(o["ref"] == "SL1.2.sum-unknown#1" and R(o["values"]["v"]) == rejected[0] for o in q["choices"]),
             "the negative root is not a wrong option")

    need(q["answer"].get("exact") is True, "the answer is not marked exactly")
    m = re.match(r"([uS])(\d+|₁) = $", q["answer"]["label"].translate(SUBSCRIPTS))
    if u in ("term-from-u1-d", "sum-from-u1-d", "sum-from-first-last"):
        need(m and R(m.group(2)) == n, f"the answer label {q['answer']['label']!r} names another term")
    v = {
        "term-from-u1-d": seq_term(NN), "n-from-term": NN, "n-from-sum": NN,
        "d-from-two-terms": D, "d-from-sum": D, "u1-from-two-terms": U1, "u1-from-sum": U1,
        "sum-from-u1-d": seq_sum(NN), "sum-from-first-last": seq_sum(NN),
    }[u]
    return {"v": sp.nsimplify(v.subs(sol))}, None


# Paper 2 (FAL-419): a context in words with a decimal u₁ and d, the checker's own copy
# of the engine's limits (arithmetic_sequence.gd, P2): in hundredths, u₁ and d with
# their step, and the threshold's step; EDGE keeps "first more than" clear of a whole n.
SEQ_P2 = {
    "money": {"u1": (500, 4000, 5), "d": (15, 250, 5), "term": 100, "sum": 1000},
    "km": {"u1": (200, 800, 10), "d": (10, 50, 5), "term": 100, "sum": 500},
}
SEQ_TO_SUB = str.maketrans("0123456789", "₀₁₂₃₄₅₆₇₈₉")
SEQ_P2_UNKNOWNS = {"term-from-u1-d", "n-from-term", "sum-from-u1-d", "n-from-sum"}
SEQ_P2_EDGE = sp.Rational(15, 100)
SEQ_NUM = r"(\d+(?:\.\d+)?)"
SEQ_P2_INTRO = {
    "money": r"^Ana saves \$" + SEQ_NUM + r" in the first week of a savings plan, and each week after that she saves \$" + SEQ_NUM + r" more than the week before\.$",
    "km": r"^Ben runs " + SEQ_NUM + r" km on the first day of his training plan, and each day after that he runs " + SEQ_NUM + r" km more than the day before\.$",
}


def seq_p2_amount(ctx, v):
    """An amount as the context writes it: money to 2 d.p. (whole dollars bare), or a decimal."""
    return money_text(v) if ctx == "money" else dec_text(v)


def seq_p2_cent(ctx, v):
    """Money to the nearest cent (half a cent up); km as it is."""
    return sp.floor(v * 100 + sp.Rational(1, 2)) / 100 if ctx == "money" else v


def seq_p2_first_over(k_real):
    """The least whole n ≥ 1 with f(n) > the threshold, from the real crossing k_real."""
    need(not k_real.is_integer, "the threshold is reached exactly at a whole n")
    frac = k_real - sp.floor(k_real)
    need(SEQ_P2_EDGE <= frac <= 1 - SEQ_P2_EDGE, f"the crossing n = {sp.N(k_real, 8)} is too close to a whole n")
    return int(sp.floor(k_real)) + 1


def seq_check_p2(q):
    """Paper 2: reads u₁ and d back from the context, solves the unknown with SymPy (a
    term, a sum, or the first n over a round threshold) and checks every tagged option."""
    u, rep, ans, L, asked = q["view"]["unknown"], q["view"]["rep"], q["answer"], q["lines"], q["asked"]
    s = q["situation"]
    need(u in SEQ_P2_UNKNOWNS and rep == "words", f"{u} ({rep}) has no Paper 2 version")
    ctx = s["ctx"]
    m = re.fullmatch(SEQ_P2_INTRO[ctx], L[0])
    need(m is not None and len(L) == 1, f"can't read the context {L[0]!r}")
    u1, d = R(m.group(1)), R(m.group(2))
    need(m.group(1) == seq_p2_amount(ctx, u1) and m.group(2) == seq_p2_amount(ctx, d), "an amount is not written as the context writes it")
    lim = SEQ_P2[ctx]
    for v, (lo, hi, by) in ((u1, lim["u1"]), (d, lim["d"])):
        c = v * 100
        need(c.is_integer and lo <= c <= hi and c % by == 0, f"{v} is outside the Paper 2 limits")
        need(not v.is_integer, f"{v} is a whole number: Paper 2 uses decimals")
    need((R(s["u1"]), R(s["d"])) == (u1, d), "the context is not the situation")
    need(R(q["given"]["u1"]) == u1 and R(q["given"]["d"]) == d, "the givens are not the context")
    sit = {U1: u1, D: d}
    need([R(v) for v in s["us"]] == [seq_term(k).subs(sit) for k in (1, 2, 3, 4)], "the first terms are wrong")
    need(ans.get("exact") is True, "the answer is not marked exactly")
    per = "week" if ctx == "money" else "day"
    unit = "$" if ctx == "money" else ""
    tail = "" if ctx == "money" else " km"
    refs = {}
    if u in ("term-from-u1-d", "sum-from-u1-d"):
        pat = (r"^How much does she save in week (\d+)\?$" if ctx == "money" else r"^How far does he run on day (\d+)\?$") \
            if u == "term-from-u1-d" else \
            (r"^How much has she saved in total after (\d+) weeks\?$" if ctx == "money" else r"^How far has he run in total after (\d+) days\?$")
        n = R(em_read(pat, asked, "n").group(1))
        lo, hi = SEQ_N_TERM if u == "term-from-u1-d" else SEQ_N_SUM
        need(lo <= n <= hi, f"n = {n} is outside {lo} to {hi}")
        need(ans.get("show") == ("money" if ctx == "money" else "dec"), "an amount is not shown as the context writes it")
        sym = "u" if u == "term-from-u1-d" else "S"
        need(ans["label"] == f"{sym}{str(n).translate(SEQ_TO_SUB)} = {unit}" and ans.get("unit", "") == tail, f"the label {ans['label']!r} names another term")
        if u == "term-from-u1-d":
            v = seq_term(n).subs(sit)
            refs = {"SL1.2.nth-term#0": {u1 + n * d}, "SL1.2.nth-term#2": {n}}
        else:
            v = seq_sum(n).subs(sit)
            refs = {"SL1.2.sum#0": {seq_p2_cent(ctx, n * (2 * u1 + n * d) / 2)}, "SL1.2.sum#1": {seq_sum(n - 1).subs(sit)},
                    "SL1.2.sum#2": {seq_term(n).subs(sit)}}
        need(R(s["n"]) == n, "the situation's n is not the one asked")
        need(v <= (SEQ_UN_MAX if sym == "u" else SEQ_SN_MAX), f"{v} is too big")
        need((v * 100).is_integer, f"{v} doesn't end in whole hundredths")
        for o in q["choices"]:
            need(o["text"] == ans["label"] + seq_p2_amount(ctx, R(o["values"]["v"])) + tail, f"option {o['text']!r} is not written as an amount")
    else:
        need(ans["label"] == "n = ", "the answer is not n")
        if u == "n-from-term":
            pat = r"^In which week n does she first save more than \$(\d+)\?$" if ctx == "money" else r"^On which day n does he first run more than (\d+) km\?$"
            y = R(em_read(pat, asked, "the threshold").group(1))
            need((y * 100) % lim["term"] == 0, "the threshold is not round")
            v = seq_p2_first_over(1 + (y - u1) / d)
            need(SEQ_N_TERM[0] <= v <= SEQ_N_TERM[1], f"n = {v} is outside the limits")
            need(seq_term(v).subs(sit) > y >= seq_term(v - 1).subs(sit), "the term n is not the first over the threshold")
            refs = {"SL1.2.find-n#2": {v - 1}, "SL1.2.find-n#1": {y}}
        else:
            pat = (r"^After how many weeks n is her total saved first more than \$(\d+)\?$" if ctx == "money"
                   else r"^After how many days n is his total distance first more than (\d+) km\?$")
            x = R(em_read(pat, asked, "the threshold").group(1))
            need((x * 100) % lim["sum"] == 0, "the threshold is not round")
            roots = sorted(sp.solve(sp.Eq(seq_sum(NN).subs(sit), x), NN), key=lambda r_: float(r_))
            need(len(roots) == 2 and roots[0] < 0 < roots[1], f"the roots {roots} are not one negative, one positive")
            v = seq_p2_first_over(roots[1])
            need(SEQ_N_SUM[0] <= v <= SEQ_N_SUM[1], f"n = {v} is outside the limits")
            need(seq_sum(v).subs(sit) > x >= seq_sum(v - 1).subs(sit), "S_n is not the first sum over the threshold")
            refs = {"SL1.2.sum-unknown#1": {R(sig3(roots[0]))}, "SL1.2.sum-unknown#2": {x}}
        for o in q["choices"]:
            need(o["text"] == "n = " + dec_text(R(o["values"]["v"])), f"option {o['text']!r} is not n as a decimal")
        v = sp.Integer(v)
        need(R(s["n"]) == v, "the situation's n is not the answer")
    for o in q["choices"]:
        if o["ref"]:
            need(o["ref"] in refs, f"the checker can't confirm {o['ref']} on {u}")
            need(R(o["values"]["v"]) in refs[o["ref"]], f"option {o['text']!r} is not what {o['ref']} gives")
    for sol in q["solutions"]:
        need(2 <= len(sol["steps"]) <= 5, f"{sol['name']}: {len(sol['steps'])} steps, not 2 to 5")
        need(any("GDC" in st for st in sol["steps"]), f"{sol['name']}: a Paper 2 solution doesn't use the GDC")
    return {"v": v}, None


# ── Discrete distributions (FAL-396) ─────────────────────────
# The `distribution` situation's clean limits, the checker's own copy: the engine's is
# in game/engine/situations/distribution.gd. The distribution is read back from what
# the student is shown (the table, the formula or the sentence), solved again with
# SymPy in exact rationals, and every answer, option and worked solution is compared
# with that.

DIST_N = (3, 5)
DIST_X = (0, 7)
DIST_P = (sp.Rational(1, 20), sp.Rational(3, 5))
DIST_K = (sp.Rational(1, 60), sp.Rational(1, 6))
DIST_PRIZES = (3, 4)
DIST_PRIZE_MAX = 20
DIST_STAKE_MIN = sp.Rational(1, 2)
DIST_TRIALS = (20, 600)
KSYM, PSYM, QSYM, MSYM = sp.symbols("k p q m")
# Asks whose options are probabilities, so between 0 and 1. k is not one: k = 21 from
# 21k = 1 is a real slip.
DIST_PROB_ASKS = {"missing-probability", "event-probability", "probabilities-from-mean"}
# Paper 2 (FAL-419): awkward decimals to 3 d.p. (never a whole number of hundredths),
# every probability from 0.05 to 0.6, a reciprocal formula k/f(x) for a whole f(x),
# a lucky dip of 1000 tokens. Paper 1 keeps the limits above.
DIST_P2_MILLE = 1000
DIST_P1_TOTAL_MAX = 60
SF3_SUFFIX = ", correct to 3 significant figures"


def dist_awkward(p):
    """A Paper 2 decimal: a whole number of thousandths, not of hundredths."""
    return (p * DIST_P2_MILLE).q == 1 and (p * 100).q != 1


def dist_needs_rounding(v):
    return sp.Rational(sig3(v)) != v


def money_round_text(v):
    """A Paper 2 stake to the nearest cent, halves up (never on a half cent)."""
    v = sp.Rational(v)
    if v.q == 1:
        return frac_text(v)
    # Not whole dollars, so written with its cents, even when they round to $8.00.
    cents = int(sp.floor(v * 100 + sp.Rational(1, 2)))
    return f"{cents // 100}.{cents % 100:02d}"


def frac_text(v):
    v = sp.Rational(v)
    body = str(abs(v.p)) if v.q == 1 else f"{abs(v.p)}/{v.q}"
    return ("−" if v < 0 else "") + body


def dec_text(v):
    """A decimal when it ends, else a fraction: 0.35, 3, 1/6."""
    v = sp.Rational(v)
    q = v.q
    while q % 2 == 0:
        q //= 2
    while q % 5 == 0:
        q //= 5
    if q != 1:
        return frac_text(v)
    d = Decimal(v.p) / Decimal(v.q)
    s = format(d.normalize(), "f")
    return s.replace("-", "−")


def money_text(v):
    v = sp.Rational(v)
    if v.q == 1:
        return frac_text(v)
    cents = v * 100
    need(cents.q == 1, f"a stake of {v} is not a whole number of cents")
    return f"{int(cents) // 100}.{int(cents) % 100:02d}"


def entry_value(text):
    """One probability as the question writes it: k, 3k, 0.35, 3/10, p, q or ?."""
    t = text.strip()
    if t == "?":
        return MSYM
    if t in ("p", "q"):
        return {"p": PSYM, "q": QSYM}[t]
    m = re.fullmatch(r"(\d*)k", t)
    if m:
        return (int(m[1]) if m[1] else 1) * KSYM
    need(re.fullmatch(r"\d+(\.\d+)?(/\d+)?", t), f"probability {t!r} is not a number")
    return sp.Rational(t)


def formula_values(line, k=None):
    """The values of x and P(X = x) from 'P(X = x) = k(x + 1), for x = 0, 1, 2.', or
    Paper 2's 'P(X = x) = k/x, for x = 1, 2, 3, where k = 6/11.' (k is put in, and
    must be the given k)."""
    m = re.fullmatch(r"P\(X = x\) = (.+), for x = ([\d, ]+?)(?:, where k = (\d+/\d+))?\.", line)
    need(m, f"formula line {line!r}")
    need((m[3] is None) == (k is None), "k is given in the formula line but not in the givens, or the other way")
    rhs_text = re.sub(r"k(?=[x(])", "k*", m[1])
    s = rhs_text.replace("−", "-").replace("²", "**2")
    f = sp.sympify(parse_expr(s, local_dict={"x": X, "k": KSYM}, transformations=TRANSFORMS))
    xs = [int(v) for v in m[2].split(",")]
    if m[3] is not None:
        need(sp.Rational(m[3]) == sp.Rational(k), "the shown k is not the given one")
        f = f.subs(KSYM, sp.Rational(m[3]))
    return xs, [sp.nsimplify(f.subs(X, x)) for x in xs]


def event_of(text):
    """The event inside P( ) or a sentence: X > 2, 1 < X ≤ 3. Returns (op, a, b)."""
    m = re.search(r"(\d+) ([<≤]) X ([<≤]) (\d+)", text)
    if m:
        return (m[2] + m[3], int(m[1]), int(m[4]))
    m = re.search(r"X ([=<>≤≥]) (\d+)", text)
    need(m, f"no event in {text!r}")
    return (m[1], int(m[2]), int(m[2]))


def event_holds(ev, x):
    op, a, b = ev
    return {"=": x == a, ">": x > a, "≥": x >= a, "<": x < b, "≤": x <= b,
            "<≤": a < x <= b, "≤<": a <= x < b, "≤≤": a <= x <= b}[op]


def same_event(given, ev):
    op, a, b = ev
    if given["op"] != op:
        return False
    if op in ("<", "≤"):
        return given["b"] == b
    if op in ("=", ">", "≥"):
        return given["a"] == a
    return (given["a"], given["b"]) == (a, b)


def dist_read(q):
    """The distribution as shown: values xs, probabilities (in k, p, q or m), and the
    game's prizes. Checks the shown text says exactly the givens."""
    g = q["given"]
    rep = q["view"]["rep"]
    lines = q["lines"]
    out = {"game": g.get("game") is not None}
    if out["game"]:
        if rep == "words" and g["game"].get("tokens"):
            # Paper 2: a lucky dip of 1000 tokens.
            text = lines[0]
            m = re.fullmatch(r"A lucky dip at the bazaar holds (\d+) tokens\. (.+), and the other (\d+) win nothing\. "
                             r"A player pays a stake to draw one token\.", text)
            need(m, f"lucky dip {text!r}")
            tokens = int(m[1])
            need(tokens == g["game"]["tokens"] == DIST_P2_MILLE, "the lucky dip's tokens are not as given")
            wins = [(int(w[2]), int(w[1])) for w in re.finditer(r"(\d+) tokens win \$(\d+)", m[2])]
            counts = {0: int(m[3]), **{w[0]: w[1] for w in wins}}
            need(len(counts) == len(wins) + 1 and sum(counts.values()) == tokens, "the tokens don't add up")
            out["xs"] = sorted(counts)
            out["ps"] = [sp.Rational(counts[x], tokens) for x in out["xs"]]
        elif rep == "words":
            text = lines[0]
            sectors = int(re.search(r"spinner with (\d+) equal sectors", text)[1])
            wins = [(int(m[2]), int(m[1])) for m in re.finditer(r"(\d+) sectors? wins? \$(\d+)", text)]
            other = int(re.search(r"the other (\d+) win nothing", text)[1])
            need(g["game"]["sectors"] == sectors, "the spinner's sectors are not as given")
            prizes = sorted([0] + [w[0] for w in wins])
            counts = {0: other, **{w[0]: w[1] for w in wins}}
            need(sum(counts.values()) == sectors, "the sectors don't add up")
            out["xs"] = prizes
            out["ps"] = [sp.Rational(counts[x], sectors) for x in prizes]
        else:
            rows = q["table"]["rows"]
            need(rows[0][0] == "Prize ($)" and rows[1][0] == "Probability", "game table headings")
            out["xs"] = [int(v) for v in rows[0][1]]
            out["ps"] = [entry_value(v) for v in rows[1][1]]
        need(out["xs"] == g["xs"], "shown prizes are not the given ones")
        return out
    if rep == "equation":
        need(len(lines) >= 2, "no formula line")
        xs, ps = formula_values(lines[1], g.get("k"))
        need(g["entries"] is None, "a formula question also lists entries")
    elif rep == "table":
        rows = q["table"]["rows"]
        need(rows[0][0] == "x" and rows[1][0] == "P(X = x)", "table headings")
        xs = [int(v) for v in rows[0][1]]
        need([str(e) for e in rows[1][1]] == g["entries"], "the table is not the given entries")
        ps = [entry_value(v) for v in rows[1][1]]
    else:
        text = lines[0]
        m = re.search(r"X takes the values ([\d, and]+), with", text)
        need(m, "no values in the sentence")
        xs = [int(v) for v in re.findall(r"\d+", m[1])]
        stated = {int(m[1]): m[2] for m in re.finditer(r"P\(X = (\d+)\) = (\d*k|\d+(?:\.\d+)?(?:/\d+)?|p|q)(?=[,. ]|$)", text)}
        ps = [entry_value(stated[x]) if x in stated else MSYM for x in xs]
        want = {x: e for x, e in zip(g["xs"], g["entries"]) if e != "?"}
        need(stated == want, f"the sentence states {stated}, not the given {want}")
        need(sum(1 for x in xs if x not in stated) == g["entries"].count("?"), "a probability is left out")
    need(xs == g["xs"], "shown values of X are not the given ones")
    out["xs"] = xs
    out["ps"] = ps
    return out


def dist_clean(u, d, style, paper=1, shown=None, k=None):
    """The clean limits. shown: the probabilities as written (k, p and q still in);
    k: k where the probabilities are k × something."""
    xs, ps = d["xs"], d["ps"]
    if d["game"]:
        need(len(xs) in DIST_PRIZES and xs[0] == 0, "a game has 3 or 4 prizes, one of them $0")
        need(all(0 < b - a for a, b in zip(xs, xs[1:])) and xs[-1] <= DIST_PRIZE_MAX, "prizes are not different whole dollars up to 20")
    else:
        need(DIST_N[0] <= len(xs) <= DIST_N[1], f"{len(xs)} values of X")
        need(all(b - a == 1 for a, b in zip(xs, xs[1:])), "the values of X are not in a row")
        need(DIST_X[0] <= xs[0] and xs[-1] <= DIST_X[1], "a value of X is outside 0 to 7")
    need(sum(ps) == 1, f"the probabilities add to {sum(ps)}, not 1")
    for p in ps:
        need(0 < p < 1, f"probability {p} is not between 0 and 1")
        if style == "decimal":
            need(paper == 1, "Paper 2 decimals that are steps of 0.05")
            need(DIST_P[0] <= p <= DIST_P[1] and (p * 20).q == 1, f"probability {p} is not a step of 0.05 from 0.05 to 0.6")
        if paper == 2:
            need(DIST_P[0] <= p <= DIST_P[1], f"Paper 2 probability {p} is not from 0.05 to 0.6")
    if paper == 1:
        need(style in ("multiples", "formula", "decimal"), f"Paper 1 style {style}")
        if style == "formula":
            need(max(sp.Rational(p).q for p in ps) <= DIST_P1_TOTAL_MAX, "a Paper 1 formula's probabilities are beyond sixtieths")
        return
    # Paper 2: decimals that want a calculator, or a reciprocal formula.
    need(style in ("calc", "formula"), f"Paper 2 style {style}")
    if style == "calc":
        for e in shown or ps:
            if not sp.sympify(e).free_symbols:
                need(dist_awkward(sp.Rational(e)), f"Paper 2 decimal {e} is not an awkward one to 3 d.p.")
    else:
        need(k is not None, "a Paper 2 formula without k")
        for p in ps:
            r = sp.Rational(p) / sp.Rational(k)
            need(r.p == 1 and r.q > 1 or r == 1, f"P(X = x) = {p} is not k over a whole number")


def dist_event_prob(xs, ps, ev):
    return sum((p for x, p in zip(xs, ps) if event_holds(ev, x)), sp.Integer(0))


def dist_show(u, style, paper=1, ans_show=None):
    if paper == 2:
        return {"sf": sig3, "dec": dec_text, "money": money_round_text}.get(ans_show, frac_text)
    if u == "k-from-sum":
        return frac_text
    if u == "fair-stake":
        return money_text
    if u in ("missing-probability", "probabilities-from-mean", "expected-count", "trials-for-count"):
        return dec_text
    return dec_text if style == "decimal" else frac_text


def check_distribution(q):
    g = q["given"]
    u = q["view"]["unknown"]
    rep = q["view"]["rep"]
    style = g["style"]
    asked = q["asked"]
    paper = q.get("paper", 1)
    need(paper in (1, 2), f"paper {paper}")
    ans_show = q["answer"].get("show")
    # Paper 2 says when it wants 3 s.f.; Paper 1 never does.
    sf = asked.endswith(SF3_SUFFIX + ".")
    need(sf == (ans_show == "sf"), f"asked {asked!r} with an answer shown {ans_show!r}")
    need(paper == 2 or not sf, "a Paper 1 answer to 3 s.f.")
    if sf:
        asked = asked[:-len(SF3_SUFFIX) - 1] + "."
    d = dist_read(q)
    xs, ps = d["xs"], d["ps"]
    shown = list(ps)
    k_val = sp.Rational(g["k"]) if g.get("k") else None
    free = set().union(*[sp.sympify(p).free_symbols for p in ps])
    ev = None
    wrongs = {}
    exp_pq = None

    if u == "k-from-sum":
        need(free == {KSYM}, f"k-from-sum shows unknowns {free}")
        sol = sp.solve(sp.Eq(sum(ps), 1), KSYM)
        need(len(sol) == 1, "the sum doesn't fix k")
        exp = sol[0]
        if paper == 1:
            need(DIST_K[0] <= exp <= DIST_K[1], f"k = {exp} is outside 1/60 to 1/6")
        else:
            need(dist_needs_rounding(exp), f"Paper 2 k = {exp} needs no calculator")
        coef = [sp.Poly(p, KSYM).coeff_monomial(KSYM) for p in ps]
        # What the multiples of k add to: 1, less any decimals beside them.
        rest = 1 - sum(sp.expand(p - c * KSYM) for p, c in zip(ps, coef))
        sxc = sum(x * c for x, c in zip(xs, coef))
        wrongs["SL4.7.find-k#0"] = [rest / v for v in (sxc, sum(xs) if rest == 1 else 0) if v > 0]
        ps = [p.subs(KSYM, exp) for p in ps]
        k_val = exp
        label = "k = "
    elif u == "missing-probability":
        need(free == {MSYM} and ps.count(MSYM) == 1, "not one missing probability")
        exp = 1 - sum(p for p in ps if p != MSYM)
        mi = ps.index(MSYM)
        ps = [exp if p == MSYM else p for p in ps]
        need(asked == f"Find P(X = {xs[mi]}).", f"asked {asked!r}")
        wrongs["SL4.7.build-distribution#1"] = [sp.Rational(1, len(xs))]
        label = f"P(X = {xs[mi]}) = "
    elif u == "probabilities-from-mean":
        need(free == {PSYM, QSYM}, "p and q are not the unknowns")
        m = re.fullmatch(r"E\(X\) = ([\d.]+)\.", q["lines"][-1])
        need(m, "E(X) is not given")
        mean = sp.Rational(m[1])
        need(str(mean) == str(sp.Rational(g["mean"])), "the shown E(X) is not the given one")
        sol = sp.solve([sp.Eq(sum(ps), 1), sp.Eq(sum(x * p for x, p in zip(xs, ps)), mean)], [PSYM, QSYM], dict=True)
        need(len(sol) == 1, "the two equations don't fix p and q")
        exp_pq = (sol[0][PSYM], sol[0][QSYM])
        need(exp_pq[0] != exp_pq[1], "p and q are equal")
        for v in exp_pq:
            if paper == 1:
                need(DIST_P[0] <= v <= DIST_P[1] and (v * 20).q == 1, f"{v} is not a step of 0.05 from 0.05 to 0.6")
            else:
                need(DIST_P[0] <= v <= DIST_P[1] and dist_awkward(v), f"{v} is not an awkward decimal from 0.05 to 0.6")
        bad = sp.solve([sp.Eq(sum(ps), 1), sp.Eq(sum(x * p for x, p in zip(xs, ps)), 1)], [PSYM, QSYM], dict=True)
        wrongs["SL4.7.unknowns-from-mean#1"] = [(b[PSYM], b[QSYM]) for b in bad]
        ps = [p.subs(sol[0]) for p in ps]
        exp = None
        label = None
    else:
        need(not free, f"{u} shows unknowns {free}")
        if u == "fair-stake":
            exp = sum(x * p for x, p in zip(xs, ps))
            need(exp >= DIST_STAKE_MIN, f"the stake {exp} is under $0.50")
            if paper == 1:
                need((exp * 100).q == 1, f"the stake {exp} is not whole cents")
                need(asked == "Find the stake that makes the game fair.", f"asked {asked!r}")
            else:
                # To the nearest cent from tenths of a cent, never on a half cent.
                mille = exp * 1000
                need(mille.q == 1 and mille % 10 not in (0, 5), f"the Paper 2 stake {exp} is not to be rounded to the cent")
                need(asked == "Find the stake that makes the game fair, to the nearest cent.", f"asked {asked!r}")
                need(ans_show == "money", "the stake is not shown as money")
            win = sum(x * p for x, p in zip(xs, ps) if x > 0)
            wrongs["SL4.7.fair-game#0"] = [sp.Rational(sp.floor(win / ps[0] * 100 + sp.Rational(1, 2)), 100)]
            label = "Stake = $"
        elif u == "expected-value":
            exp = sum(x * p for x, p in zip(xs, ps))
            wrongs["SL4.7.expected-value#0"] = [sp.Rational(sum(xs), len(xs))]
            gaps = sorted((abs(x - exp), x) for x in xs)
            wrongs["SL4.7.expected-value#1"] = [gaps[0][1]] if gaps[0][0] != 0 and gaps[0][0] != gaps[1][0] else []
            wrongs["SL4.7.expected-value#2"] = [exp / len(xs)]
            need(asked == "Find E(X).", f"asked {asked!r}")
            label = "E(X) = "
        else:
            ev = event_of(asked)
            need(g["event"] is not None and same_event(g["event"], ev), "the asked event is not the given one")
            inside = [event_holds(ev, x) for x in xs]
            need(any(inside) and not all(inside), "the event takes in every value or none")
            pe = dist_event_prob(xs, ps, ev)
            if u == "event-probability":
                need(ev[0] != "=", "an event-probability question asks P(X = a)")
                strict = {">": "≥", "<": "≤", "<≤": "≤≤", "≤<": "≤≤"}.get(ev[0])
                if strict:
                    for end in ([ev[1]] if ev[0] in (">", "<≤") else []) + ([ev[2]] if ev[0] in ("<", "≤<") else []):
                        need(end in xs, f"the strict end {end} is not a value of X")
                    wrongs["SL4.7.table-probabilities#0"] = [dist_event_prob(xs, ps, (strict, ev[1], ev[2]))]
                exp = pe
                shown_event = re.search(r"P\((.+)\)\.$", asked)
                need(shown_event, f"asked {asked!r}")
                label = f"P({shown_event[1]}) = "
            elif u == "expected-count":
                n = int(g["n"])
                need(DIST_TRIALS[0] <= n <= DIST_TRIALS[1], f"{n} trials")
                need(f" {n} " in " " + q["lines"][-1], "the number of trials is not shown")
                exp = n * pe
                need(exp >= 1, f"expected number {exp} is under 1")
                if paper == 1:
                    need((exp * 2).q == 1, f"expected number {exp} is not whole or .5")
                else:
                    need(exp.q != 1 and ans_show == "sf", f"Paper 2 expected number {exp} is whole or not to 3 s.f.")
                wrongs["SL4.5.expected-occurrences#0"] = [] if exp.q == 1 else [sp.floor(exp + sp.Rational(1, 2))]
                wrongs["SL4.5.expected-occurrences#1"] = [pe]
                label = "Expected number = "
            elif u == "trials-for-count":
                count = sp.Rational(g["count"])
                m = re.search(r"is expected to happen ([\d.]+) times", asked)
                need(m and sp.Rational(m[1]) == count, "the expected number is not shown")
                exp = count / pe
                need(exp.q == 1 and DIST_TRIALS[0] <= exp <= DIST_TRIALS[1], f"n = {exp}")
                need(count >= 1, f"expected number {count} is under 1")
                if paper == 1:
                    need((count * 2).q == 1, f"expected number {count} is not whole or .5")
                else:
                    need((count * 100).q == 1, f"expected number {count} has more than 2 decimal places")
                label = "n = "
            else:
                raise Fail(f"the checker has no solver for {u}")
    dist_clean(u, {**d, "ps": ps}, style, paper, shown, k_val)
    show = dist_show(u, style, paper, ans_show)
    if paper == 2 and ans_show != "sf" and exp is not None:
        # An exact Paper 2 answer is a decimal that ends (0.384, n = 250, $7.206).
        need(dec_text(exp).count("/") == 0, f"Paper 2 answer {exp} doesn't end")
    prob = u in DIST_PROB_ASKS

    def value_text(v):
        if exp_pq is not None:
            return f"p = {show(v[0])}, q = {show(v[1])}"
        return label + show(v)

    def right(v):
        if exp_pq is not None:
            return all(sig3(a) == sig3(b) for a, b in zip(v, exp_pq))
        return sig3(v) == sig3(exp)

    def vals(values):
        if exp_pq is not None:
            return (sp.Rational(values["p"]), sp.Rational(values["q"]))
        return sp.Rational(values["v"])

    want = exp_pq if exp_pq is not None else exp
    for v in (want if exp_pq is not None else [want]):
        need(not on_edge(v), f"the answer {v} is on a 3 s.f. rounding edge")
    ans = q["answer"]
    need(ans["kind"] == ("pq" if exp_pq is not None else "number"), f"answer kind {ans['kind']}")
    need(vals(ans["values"]) == want, f"engine answer {q['answer_text']!r} is wrong (expected {want})")
    need(q["answer_text"] == value_text(want), f"answer text {q['answer_text']!r}, expected {value_text(want)!r}")

    # Options: four, one right, the rest wrong at 3 s.f., all different, each saying its
    # own value; a misconception's value is the one that slip gives.
    ch = q["choices"]
    need(len(ch) == 4, f"{len(ch)} options")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right option")
    keys = set()
    for o in ch:
        ov = vals(o["values"])
        if o.get("trap"):
            # Q7's rounding trap (Paper 2): the answer to 2 s.f., written as a decimal.
            need(paper == 2 and exp_pq is None and ans_show == "sf", "a rounding trap off a Paper 2 3 s.f. answer")
            need(not o["correct"] and not o["ref"], f"rounding trap {o['text']!r} is wrong-tagged")
            need(dist_needs_rounding(want) and ov == sp.Rational(sig3(want, 2)), f"rounding trap {o['text']!r} is not the answer to 2 s.f.")
            need(o["text"] == label + dec_text(ov), f"rounding trap text {o['text']!r}")
            continue
        parts = ov if exp_pq is not None else (ov,)
        for v in parts:
            need(v > 0 and (not prob or v < 1), f"option {o['text']!r} is out of range")
            need(not on_edge(v), f"option {o['text']!r} is on a 3 s.f. rounding edge")
        need(o["text"] == value_text(ov), f"option text {o['text']!r} doesn't say its value {ov}")
        key = tuple(sig3(v) for v in parts)
        need(key not in keys, f"two options are the same to 3 s.f.: {o['text']!r}")
        keys.add(key)
        need(right(ov) == o["correct"], f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'} but is {'right' if right(ov) else 'wrong'}")
        if o["correct"]:
            need(ov == want, "the right option is not the answer")
        if o["ref"]:
            need(not o["correct"], "a misconception is the right answer")
            need(o["ref"] in wrongs, f"{o['ref']} is not a misconception of {u}")
            need(ov in wrongs[o["ref"]], f"option {o['text']!r} is not what {o['ref']} gives")

    # Worked solutions: each ends at the answer.
    need(len(q["solutions"]) >= 1, "no worked solution")
    for sol in q["solutions"]:
        need(vals(sol["result"]) == want, f"{sol['name']}: last step gives {sol['result']}, not the answer")
        last = sol["steps"][-1]
        need(q["answer_text"] in last, f"{sol['name']}: last step {last!r} doesn't state the answer")
    if q["view"]["angle"] != "any":
        need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")

    # The situation the engine exported is this distribution.
    sit = q["situation"]
    need([int(x) for x in sit["xs"]] == xs, "situation values differ")
    need([sp.Rational(p) for p in sit["ps"]] == ps, "situation probabilities differ")
    return None, None


# ── Quadratics region (FAL-414) ──────────────────────────────
# The four situations that finish the region: quadratic-parameter, curve-and-line,
# quadratic-equation and quadratic-inequality. Each check reads what the student sees
# back with SymPy, solves the unknown from it, and works out each tagged
# misconception's wrong value itself. Answer and option texts are written again here
# from their values (the checker's own copy of the game's writing rules) and must match
# exactly.

K = LETTERS["k"]
U = LETTERS["u"]
QR_STEPS = (2, 5)


def qr_lead(v):
    v = sp.Rational(v)
    if v == 1:
        return ""
    if v == -1:
        return "−"
    if v == sp.Rational(1, 2):
        return "½"
    if v == sp.Rational(-1, 2):
        return "−½"
    if v.q == 1:
        return frac_text(v)
    return ("−" if v < 0 else "") + f"({frac_text(abs(v))})"


def qr_poly(coeffs, letter="x"):
    out = ""
    power = len(coeffs) - 1
    for c in coeffs:
        c = sp.Rational(c)
        if c != 0:
            mag = abs(c)
            var = "" if power == 0 else (letter if power == 1 else letter + "²")
            body = frac_text(mag) if power == 0 else qr_lead(mag) + var
            if out == "":
                out = ("−" if c < 0 else "") + body
            else:
                out += (" − " if c < 0 else " + ") + body
        power -= 1
    return out or "0"


def qr_point(x, y):
    return f"({frac_text(x)}, {frac_text(y)})"


def qr_set(kind, v):
    """An inequality answer as the set it describes (None for a pm wrong option)."""
    if kind == "bound":
        x, rel = R(v["v"]), v["rel"]
        return {"<": sp.Interval.open(-sp.oo, x), "≤": sp.Interval(-sp.oo, x), ">": sp.Interval.open(x, sp.oo),
                "≥": sp.Interval(x, sp.oo)}[rel]
    lo, hi, inc = R(v["lo"]), R(v["hi"]), v["ends"] == "included"
    sh = v["shape"]
    if sh == "between":
        return sp.Interval(lo, hi, not inc, not inc)
    if sh == "outside":
        return sp.Union(sp.Interval(-sp.oo, lo, True, not inc), sp.Interval(hi, sp.oo, not inc, True))
    if sh == "below":
        return sp.Interval(-sp.oo, hi, True, not inc)
    if sh == "above":
        return sp.Interval(lo, sp.oo, not inc, True)
    return None


def qr_interval_text(var, v):
    inc = v["ends"] == "included"
    lt, gt = ("≤", "≥") if inc else ("<", ">")
    lo, hi = frac_text(v["lo"]), frac_text(v["hi"])
    return {"between": f"{lo} {lt} {var} {lt} {hi}", "outside": f"{var} {lt} {lo} or {var} {gt} {hi}",
            "pm_lt": f"{var} {lt} ±{hi}", "pm_gt": f"{var} {gt} ±{hi}", "below": f"{var} {lt} {hi}",
            "above": f"{var} {gt} {lo}"}[v["shape"]]


def qr_surd(m, r):
    m, r = R(m), R(r)
    if r == 1:
        return frac_text(m)
    return ("" if m == 1 else frac_text(m)) + "√" + frac_text(r)


def qr_text(ans, v):
    kind, fx, label, unit = ans["kind"], ans.get("fixed") or {}, ans.get("label", ""), ans.get("unit", "")
    if kind in EXT_KINDS or (kind == "number" and ans.get("show")):
        return ext_text(ans, v)
    if kind in QR_SF_KINDS and ans.get("show") == "sf":
        return qr_sf_text(ans, v)
    if kind in EL_KINDS:
        return el_text(ans, v)
    var = fx.get("var", "k")
    if kind == "number":
        return label + frac_text(v["v"]) + unit
    if kind == "choice":
        return label + v["v"]
    if kind == "delta_nature":
        return f"Δ = {frac_text(v['d'])}, so {v['nature']}"
    if kind in ("kvals", "roots"):
        a, b = sorted([R(v["r1"]), R(v["r2"])])
        var = "x" if kind == "roots" else var
        return f"{var} = {frac_text(a)} {'and' if kind == 'roots' else 'or'} {var} = {frac_text(b)}"
    if kind == "interval":
        return qr_interval_text(var, v)
    if kind == "bound":
        return f"{var} {v['rel']} {frac_text(v['v'])}"
    if kind == "quad_in":
        a = fx["A"] if "A" in fx else v["A"]
        return label + qr_poly([a, v["B"], v["C"]], fx.get("var", "x")) + fx.get("tail", "")
    if kind == "kpoint":
        return f"k = {frac_text(v['k'])}, touching at {qr_point(v['x'], v['y'])}"
    if kind == "points2":
        ps = sorted([(R(v["x1"]), R(v["y1"])), (R(v["x2"]), R(v["y2"]))])
        return f"{qr_point(*ps[0])} and {qr_point(*ps[1])}"
    if kind == "point":
        return qr_point(v["x"], v["y"])
    if kind == "surd":
        return label + qr_surd(v["m"], v["r"]) + unit
    if kind == "surd_roots":
        h = R(v["h"])
        return f"x = {'' if h == 0 else frac_text(h) + ' '}± √{frac_text(v['d'])}"
    if kind == "line":
        return "y = " + qr_poly([v["m"], v["c"]])
    if kind == "npoint":
        return f"n = {frac_text(v['n'])}, other point {qr_point(v['x'], v['y'])}"
    if kind == "kroot":
        return f"k = {frac_text(v['k'])}, other root x = {frac_text(v['r'])}"
    if kind == "ineq_a":
        return f"{qr_poly([1, v['b'], v['c']])} {v['rel']} 0"
    if kind == "measure":
        return label + sig3(R(v["v"])).replace("-", "−") + unit
    raise Fail(f"the checker can't write answers of kind {kind}")


def qr_norm(ans, v):
    """A value equal for two answers exactly when they mean the same."""
    kind, fx = ans["kind"], ans.get("fixed") or {}
    if kind in EXT_KINDS or (kind == "number" and ans.get("show") == "sf"):
        return ext_norm(ans, v)
    if kind in QR_SF_KINDS and ans.get("show") == "sf":
        return qr_sf_norm(ans, v)
    if kind in EL_KINDS:
        return el_norm(ans, v)
    if kind in ("interval", "bound"):
        st = qr_set(kind, v)
        return ("pm", v["shape"], R(v["hi"]), v["ends"]) if st is None else st
    if kind in ("kvals", "roots"):
        return tuple(sorted([R(v["r1"]), R(v["r2"])]))
    if kind == "points2":
        return tuple(sorted([(R(v["x1"]), R(v["y1"])), (R(v["x2"]), R(v["y2"]))]))
    if kind == "quad_in":
        return (R(fx["A"]) if "A" in fx else R(v["A"]), R(v["B"]), R(v["C"]))
    if kind == "measure":
        return sig3(R(v["v"]))
    out = []
    for key in sorted(v):
        x = v[key]
        out.append((key, x if not isinstance(x, str) or not re.fullmatch(r"-?\d+(/\d+)?", x) else R(x)))
    return tuple(out)


# Paper 2 (FAL-419): k values and interval ends that need a calculator, written to
# 3 s.f. Such an answer is told apart by what it shows, so its norm is its numbers to
# 3 s.f. with its shape; qr_sf_set writes an exact SymPy set the same way.
QR_SF_KINDS = {"interval", "bound", "kvals"}


def qr_sf_text(ans, v):
    var = (ans.get("fixed") or {}).get("var", "k")
    kind = ans["kind"]
    if kind == "kvals":
        a, b = sorted([R(v["r1"]), R(v["r2"])])
        return f"{var} = {ext_sf(a)} or {var} = {ext_sf(b)}"
    if kind == "bound":
        return f"{var} {v['rel']} {ext_sf(R(v['v']))}"
    inc = v["ends"] == "included"
    lt, gt = ("≤", "≥") if inc else ("<", ">")
    lo, hi = ext_sf(R(v["lo"])), ext_sf(R(v["hi"]))
    return {"between": f"{lo} {lt} {var} {lt} {hi}", "outside": f"{var} {lt} {lo} or {var} {gt} {hi}",
            "pm_lt": f"{var} {lt} ±{hi}", "pm_gt": f"{var} {gt} ±{hi}", "below": f"{var} {lt} {hi}",
            "above": f"{var} {gt} {lo}"}[v["shape"]]


def qr_sf_norm(ans, v):
    kind = ans["kind"]
    if kind == "kvals":
        return tuple(ext_sf(x) for x in sorted([R(v["r1"]), R(v["r2"])]))
    if kind == "bound":
        return (v["rel"], ext_sf(R(v["v"])))
    inc = v["ends"] == "included"
    sh = v["shape"]
    if sh in ("between", "outside"):
        return (sh, ext_sf(R(v["lo"])), ext_sf(R(v["hi"])), v["ends"])
    if sh == "below":
        return ("≤" if inc else "<", ext_sf(R(v["hi"])))
    if sh == "above":
        return ("≥" if inc else ">", ext_sf(R(v["lo"])))
    return ("pm", sh, ext_sf(R(v["hi"])), v["ends"])


def qr_sf_set(S):
    """An exact set of real numbers (one interval, one ray or two rays) as qr_sf_norm writes it."""
    if isinstance(S, sp.Union):
        need(len(S.args) == 2, f"{S} is not two rays")
        left, right = sorted(S.args, key=lambda i: float(i.end) if i.end.is_finite else float(i.start))
        need(left.start == -sp.oo and right.end == sp.oo, f"{S} is not two rays")
        return ("outside", ext_sf(left.end), ext_sf(right.start), "left out" if left.right_open else "included")
    need(isinstance(S, sp.Interval), f"{S} is not an interval")
    if S.start == -sp.oo:
        return ("<" if S.right_open else "≤", ext_sf(S.end))
    if S.end == sp.oo:
        return (">" if S.left_open else "≥", ext_sf(S.start))
    return ("between", ext_sf(S.start), ext_sf(S.end), "left out" if S.left_open else "included")


def qr_check_common(q, want, wrongs=None):
    """want: the answer normalised (qr_norm). wrongs: ref -> set of normalised values
    that misconception gives. Every tagged option must be one of its ref's values."""
    wrongs = wrongs or {}
    ans = q["answer"]
    need(qr_norm(ans, ans["values"]) == want, f"engine answer {q['answer_text']!r} is wrong (expected {want})")
    need(q["answer_text"] == qr_text(ans, ans["values"]), f"answer text {q['answer_text']!r}, expected {qr_text(ans, ans['values'])!r}")
    ch = q["choices"]
    need(len(ch) == 4, f"{len(ch)} options")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right option")
    seen, texts = [], set()
    for o in ch:
        n = qr_norm(ans, o["values"])
        if o.get("trap"):
            # Q7's rounding trap: the answer to 2 s.f., a glancing hit, never the answer.
            need(not o["correct"] and n != want and not o["ref"], f"rounding trap {o['text']!r} is wrong-tagged")
            continue
        need(n not in seen, f"two options are the same: {o['text']!r}")
        seen.append(n)
        need(o["text"] not in texts, f"two options read the same: {o['text']!r}")
        texts.add(o["text"])
        need(o["text"] == qr_text(ans, o["values"]), f"option text {o['text']!r} doesn't say its values")
        need((n == want) == o["correct"], f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'} but is {'right' if n == want else 'wrong'}")
        if o["ref"]:
            need(not o["correct"], "a misconception is the right answer")
            need(o["ref"] in wrongs, f"the checker can't confirm {o['ref']} on {q['view']['unknown']}")
            need(n in wrongs[o["ref"]], f"option {o['text']!r} is not what {o['ref']} gives")
    need(len(q["solutions"]) >= 1, "no worked solution")
    for sol in q["solutions"]:
        need(qr_norm(ans, sol["result"]) == want, f"{sol['name']}: last step gives {sol['result']}, not the answer")
        need(QR_STEPS[0] <= len(sol["steps"]) <= QR_STEPS[1], f"{sol['name']}: {len(sol['steps'])} steps, not 2 to 5")
        need(q["answer_text"] in sol["steps"][-1], f"{sol['name']}: last step {sol['steps'][-1]!r} doesn't state the answer")
    if q["view"]["angle"] != "any":
        need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")


def qr_sign(d):
    return 1 if d > 0 else (0 if d == 0 else -1)


# ── quadratic-parameter ──

QP_NAT = ["two distinct real roots", "one repeated root", "no real roots", "two negative roots"]
QP_MEET = ["two points", "one point (a tangent)", "no points"]
QP_SIGNS = ["a > 0 and Δ > 0", "a > 0 and Δ = 0", "a > 0 and Δ < 0", "a < 0 and Δ > 0", "a < 0 and Δ = 0", "a < 0 and Δ < 0"]
QP_SKETCH = ["opens upwards and crosses the x-axis twice", "opens upwards and touches the x-axis once",
             "opens upwards and never meets the x-axis", "opens downwards and crosses the x-axis twice",
             "opens downwards and touches the x-axis once", "opens downwards and never meets the x-axis"]
QP_BASE = {"nature-from-equation", "delta-sign-from-graph", "graph-from-delta"}
QP_CRIT_MAX = 30
# The unknowns with a Paper 2 version (FAL-419): Δ is a quadratic in k with irrational
# zeros, so k is found with a calculator and given to 3 s.f.
QP_P2 = {"k-for-equal-roots", "k-interval", "always-positive"}


def qp_nat(d, labels):
    return labels[0] if d > 0 else (labels[1] if d == 0 else labels[2])


def qp_family_poly(g):
    """The quadratic in x with k the givens describe, and the curve and line if any."""
    fam = g["family"]
    f = sp.expand(R(g["a0"]) * X**2 + (R(g["b0"]) + R(g["b1"]) * K) * X + R(g["c0"]) + R(g["c1"]) * K)
    curve = line = None
    if fam in ("grad", "icpt"):
        curve = X**2 + R(g["p"]) * X + R(g["r"])
        line = K * X + R(g["n"]) if fam == "grad" else R(g["m"]) * X + K
        need(sp.expand(curve - line - f) == 0, "the equated quadratic is not curve − line")
    return f, curve, line


LINE_SENTENCE = re.compile(r"^The line y = (.+?) (?:meets|is a tangent to|does not meet) the curve y = (.+?)(?: at two distinct points)?\.$")


def qp_check_shown(q, f, curve, line):
    """The equations shown are the givens: at least one line must say the quadratic."""
    said = 0
    for ln in q["lines"]:
        m = LINE_SENTENCE.match(ln)
        if m:
            need(parse(m.group(1), ("k",)) == sp.expand(line) and parse(m.group(2)) == sp.expand(curve), f"{ln!r} is not the givens")
            said += 1
        elif ln.startswith("Curve: y = "):
            need(parse(ln[11:]) == sp.expand(curve), f"{ln!r} is not the given curve")
            said += 1
        elif ln.startswith("Line: y = "):
            need(parse(ln[10:], ("k",)) == sp.expand(line), f"{ln!r} is not the given line")
            said += 1
        elif ln.startswith("f(x) = "):
            need(parse(ln[7:], ("k",)) == f, f"{ln!r} is not the given quadratic")
            said += 1
        else:
            for pat in (r"^g\(x\) = ln\((.+)\)$", r"^The expression (.+) is positive for every real value of x\.$",
                        r"^The equation (.+) = 0 has two distinct real roots, and they have the same sign\.$"):
                m = re.match(pat, ln)
                if m:
                    need(parse(m.group(1), ("k",)) == f, f"{ln!r} is not the given quadratic")
                    said += 1
    need(said >= 1, "no line shows the quadratic")


def check_qparam(q):
    u = q["view"]["unknown"]
    g = q["given"]
    ans = q["answer"]
    p2 = q["paper"] == 2
    need(not p2 or (u in QP_P2 and q["view"]["rep"] != "graph"), f"{u} on a {q['view']['rep']} has no Paper 2 version")
    if u in QP_BASE:
        a, b, c = R(g["a"]), R(g["b"]), R(g["c"])
        need(a in A_ALLOWED and abs(b) <= B_MAX and abs(c) <= C_MAX and c != 0, "the parabola is outside the clean limits")
        d = b**2 - 4 * a * c
        f = a * X**2 + b * X + c
        if u == "nature-from-equation":
            need(parse(rhs(q["lines"][0])) == sp.expand(f), "the equation shown is not the givens")
            want = qr_norm(ans, {"d": str(d), "nature": qp_nat(d, QP_NAT)})
            d0 = b**2 - 4 * a * abs(c)
            d2 = b**2 + 4 * a * c
            wr = {"SL2.7.discriminant#0": {qr_norm(ans, {"d": str(d0), "nature": qp_nat(d0, QP_NAT)})},
                  "SL2.7.discriminant#2": {qr_norm(ans, {"d": str(d2), "nature": qp_nat(d2, QP_NAT)})}}
            if d < 0:
                wr["SL2.7.discriminant#1"] = {qr_norm(ans, {"d": str(d), "nature": QP_NAT[3]})}
            qr_check_common(q, want, wr)
            return None, None
        i = (0 if a > 0 else 3) + (0 if d > 0 else (1 if d == 0 else 2))
        if u == "delta-sign-from-graph":
            gr = q["graph"]
            h, kk = -b / (2 * a), c - b**2 / (4 * a)
            need(abs(gr["a"] - float(a)) < 1e-9 and abs(gr["h"] - float(h)) < 1e-9 and abs(gr["k"] - float(kk)) < 1e-9,
                 "the graph is not the given parabola")
            qr_check_common(q, qr_norm(ans, {"v": QP_SIGNS[i]}))
        else:
            need(g["signs"] == QP_SIGNS[i] and QP_SIGNS[i] in q["lines"][0], "the signs said are not this parabola's")
            qr_check_common(q, qr_norm(ans, {"v": QP_SKETCH[i]}))
        return None, None

    f, curve, line = qp_family_poly(g)
    qp_check_shown(q, f, curve, line)
    A = R(g["a0"])
    D = sp.expand(sp.discriminant(f, X))
    crit = sorted(sp.solve(D, K), key=float)
    if p2:
        # Paper 2: two irrational critical values, each clear of a 3 s.f. rounding edge.
        need(len(crit) == 2 and not any(c.is_rational for c in crit), f"Paper 2 critical k {crit} don't need a calculator")
        need(all(abs(c) <= QP_CRIT_MAX and not on_edge(abs(c)) for c in crit), f"Paper 2 critical k {crit} outside the limits or on a rounding edge")
        need("3 significant figures" in q["asked"], "Paper 2 doesn't ask for 3 s.f.")
        need(ans.get("show") == "sf", "a Paper 2 answer is not written to 3 s.f.")
    else:
        need(1 <= len(crit) <= 2 and all(c.is_integer and abs(c) <= QP_CRIT_MAX for c in crit), f"critical k {crit} not whole numbers inside the limits")
        need(ans.get("show") != "sf", "a Paper 1 answer is written to 3 s.f.")
    # The set an answer means, as its kind compares them: exact, or to 3 s.f. on Paper 2.
    cv = qr_sf_set if p2 else (lambda S: S)
    lines_family = g["family"] in ("grad", "icpt")
    if u == "roots-from-k":
        kv = R(g["kv"])
        d = D.subs(K, kv)
        labels = QP_MEET if lines_family else QP_NAT
        qr_check_common(q, qr_norm(ans, {"d": str(d), "nature": qp_nat(d, labels)}))
    elif u == "delta-in-k":
        co = sp.Poly(D, K).all_coeffs()
        co = [0] * (3 - len(co)) + co
        want = (R(co[0]), R(co[1]), R(co[2]))
        b0, b1, c0, c1 = R(g["b0"]), R(g["b1"]), R(g["c0"]), R(g["c1"])
        wr = {"SL2.7.discriminant#2": {(want[0], 2 * b0 * b1 + 4 * A * c1, b0**2 + 4 * A * c0)}}
        if c1 == 0 and c0 < 0:
            wr["SL2.7.discriminant#0"] = {(want[0], want[1], b0**2 - 4 * A * abs(c0))}
        qr_check_common(q, want, wr)
    elif u == "k-for-equal-roots":
        want = qr_norm(ans, {"v": str(crit[0])}) if len(crit) == 1 else (tuple(ext_sf(c) for c in crit) if p2 else tuple(crit))
        wr = {}
        if g["family"] == "icpt":
            p, r = R(g["p"]), R(g["r"])
            kw = sp.solve(p**2 - 4 * (r - K), K)[0]   # b from the curve alone, c with the line's k
            wr["SL2.7.discriminant-parameter#0"] = {qr_norm(ans, {"v": str(kw)})}
        qr_check_common(q, want, wr)
    elif u in ("k-interval", "always-positive", "same-sign-roots"):
        cond = g["cond"]
        if u == "always-positive":
            need(A > 0 and cond == "none", "always positive needs a > 0 and Δ < 0")
        rel = {"two": D > 0, "none": D < 0, "real": D >= 0, "same-sign": D > 0}[cond]
        S = sp.solve_univariate_inequality(rel, K, relational=False)
        if cond == "same-sign":
            S = S.intersect(sp.solve_univariate_inequality((R(g["c0"]) + R(g["c1"]) * K) / A > 0, K, relational=False))
        wr = {}
        if u == "k-interval":
            if cond == "real":
                S2 = sp.solve_univariate_inequality(D > 0, K, relational=False)
                wr["SL2.7.discriminant-parameter#2"] = {cv(S2)}
            if len(crit) == 2:
                inc = "included" if cond == "real" else "left out"
                wr["SL2.7.inequality#1"] = {cv(sp.Interval(crit[0], crit[1], inc != "included", inc != "included"))}
                if sp.simplify(crit[0] + crit[1]) == 0:
                    wr["SL2.7.discriminant-parameter#1"] = {("pm", "pm_lt", ext_sf(crit[1]) if p2 else crit[1], inc)}
        qr_check_common(q, cv(S), wr)
    elif u == "tangent-contact-point":
        need(len(crit) == 1, "a tangent needs one critical k")
        k0 = crit[0]
        fx = f.subs(K, k0)
        x0 = sp.solve(sp.diff(fx, X), X)[0]
        need(fx.subs(X, x0) == 0, "no repeated root")
        y0 = sp.expand(line).subs({K: k0, X: x0})
        want = qr_norm(ans, {"k": str(k0), "x": str(x0), "y": str(y0)})
        p, r, m = R(g["p"]), R(g["r"]), R(g["m"])
        kw = r - p**2 / 4
        wr = {"SL2.7.discriminant-parameter#0": {qr_norm(ans, {"k": str(kw), "x": str(-p / 2), "y": str(m * (-p / 2) + kw)})}}
        qr_check_common(q, want, wr)
    else:
        raise Fail(f"the checker has no solver for {u}")
    return None, None


# ── curve-and-line ──

CL_COEF_MAX = 24
CL_SENT = [
    (re.compile(r"^The line y = (.+) meets the curve y = (.+) at A and B\.$"), ("line", "curve")),
    (re.compile(r"^The normal to the curve y = (.+) at P\((.+), (.+)\) is the line y = (.+)\.$"), ("curve", "px", "py", "line")),
    (re.compile(r"^Normal at P\((.+), (.+)\): y = (.+)$"), ("px", "py", "line")),
    (re.compile(r"^A line meets the curve y = (.+) at the points where x = (.+) and x = (.+)\.$"), ("curve", "xa", "xb")),
    (re.compile(r"^A line meets the curve at x = (.+) and x = (.+)\.$"), ("xa", "xb")),
    (re.compile(r"^The line y = (.+) meets the curve y = (.+) where x = (.+), and at one other point\.$"), ("lineN", "curve", "xg")),
    (re.compile(r"^They meet where x = (.+)\.$"), ("xg",)),
    (re.compile(r"^Curve: y = (.+)$"), ("curve",)),
    (re.compile(r"^Line: y = (.+)$"), ("lineAny",)),
]


def RD(text):
    """A number as the game displays it: −3/2."""
    return R(text.replace("−", "-"))


def cl_read(q):
    """Everything the lines say: the curve, the line, P, the given x-values."""
    seen = {}
    for ln in q["lines"]:
        for pat, names in CL_SENT:
            m = pat.match(ln)
            if m:
                for name, val in zip(names, m.groups()):
                    if name == "lineAny":
                        name = "lineN" if val.endswith("+ n") else "line"
                    seen[name] = val
                break
    return seen


def check_curve_line(q):
    u = q["view"]["unknown"]
    g = q["given"]
    ans = q["answer"]
    curve = R(g["A"]) * X**2 + R(g["B"]) * X + R(g["C"])
    m, n = R(g["m"]), R(g["n"])
    line = m * X + n
    need(abs(R(g["B"])) <= CL_COEF_MAX and abs(R(g["C"])) <= CL_COEF_MAX and m != 0, "outside the clean limits")
    seen = cl_read(q)
    need("curve" in seen, "no line shows the curve")
    need(parse(seen["curve"]) == sp.expand(curve), "the curve shown is not the givens")
    if "line" in seen:
        need(parse(seen["line"]) == sp.expand(line), "the line shown is not the givens")
    if "lineN" in seen:
        need(parse(seen["lineN"].replace("+ n", "")) == m * X, "the line's gradient shown is not the givens")
    diff = sp.expand(curve - line)
    xs = sorted(sp.solveset(diff, X, domain=sp.S.Reals))
    need(all(x.is_rational for x in xs), "meeting points are not rational")
    if q.get("graph"):
        gr = q["graph"]
        need(abs(gr["line"]["m"] - float(m)) < 1e-9 and abs(gr["line"]["n"] - float(n)) < 1e-9, "the sketch's line is not the givens")
        A, B, C = R(g["A"]), R(g["B"]), R(g["C"])
        need(abs(gr["a"] - float(A)) < 1e-9 and abs(gr["h"] - float(-B / (2 * A))) < 1e-9, "the sketch's curve is not the givens")
    if u == "equate-to-quadratic":
        co = sp.Poly(diff, X).all_coeffs()
        need(R(ans["fixed"]["A"]) == co[0], "the leading coefficient given is not the equated quadratic's")
        qr_check_common(q, (co[0], co[1], co[2]))
    elif u == "meeting-x":
        need(len(xs) == 2, "not two meeting points")
        qr_check_common(q, tuple(xs), {"SL2.7.solve-equation#1": {tuple(sorted([-xs[0], -xs[1]]))}})
    elif u == "meeting-points":
        qr_check_common(q, tuple(sorted((x, line.subs(X, x)) for x in xs)))
    elif u == "chord-length":
        need(len(xs) == 2, "not two meeting points")
        L = sp.sqrt((xs[1] - xs[0])**2 + (line.subs(X, xs[1]) - line.subs(X, xs[0]))**2)
        mv, rv = R(ans["values"]["m"]), R(ans["values"]["r"])
        need(sp.simplify(mv * sp.sqrt(rv) - L) == 0, f"{q['answer_text']} is not AB = {L}")
        need(rv == 1 or sp.factorint(int(rv)) and all(e == 1 for e in sp.factorint(int(rv)).values()), "the surd is not simplified")
        want = qr_norm(ans, ans["values"])
        for o in q["choices"]:
            val = R(o["values"]["m"]) * sp.sqrt(R(o["values"]["r"]))
            need((sp.simplify(val - L) == 0) == o["correct"], f"option {o['text']!r} is marked wrong/right wrongly")
        qr_check_common(q, want)
    elif u == "normal-meets-again":
        px, py = RD(seen["px"]), RD(seen["py"])
        need(curve.subs(X, px) == py, "P is not on the curve")
        slope = sp.diff(curve, X).subs(X, px)
        need(slope != 0 and m == -1 / slope and line.subs(X, px) == py, "the line is not the normal at P")
        others = [x for x in xs if x != px]
        need(len(others) == 1, "the normal doesn't meet the curve again once")
        qr_check_common(q, qr_norm(ans, {"x": str(others[0]), "y": str(line.subs(X, others[0]))}))
    elif u == "line-from-meeting-points":
        xa, xb = RD(seen["xa"]), RD(seen["xb"])
        ya, yb = curve.subs(X, xa), curve.subs(X, xb)
        mm = (yb - ya) / (xb - xa)
        qr_check_common(q, qr_norm(ans, {"m": str(mm), "c": str(ya - mm * xa)}))
    elif u == "intercept-from-one-point":
        xg = RD(seen["xg"])
        nn = curve.subs(X, xg) - m * xg
        need(nn == n, "n from the given point is not the givens'")
        others = [x for x in sp.solve(curve - (m * X + nn), X) if x != xg]
        need(len(others) == 1, "no single other point")
        qr_check_common(q, qr_norm(ans, {"n": str(nn), "x": str(others[0]), "y": str(m * others[0] + nn)}))
    elif u == "count-from-sketch":
        cnt = len(set(xs)) if xs else 0
        wr = {}
        gr = q["graph"]
        on_screen = [x for x in xs if gr["x0"] <= x <= gr["x1"]]
        if len(on_screen) < cnt:
            wr["SL2.4.intersection#1"] = {qr_norm(ans, {"v": str(len(on_screen))})}
        qr_check_common(q, qr_norm(ans, {"v": str(cnt)}), wr)
    else:
        raise Fail(f"the checker has no solver for {u}")
    return None, None


# ── quadratic-equation ──

def sgn_num(sign, num):
    v = R(num)
    return -v if sign in ("−", "-") else v


def qe_roots_poly(f):
    return sorted(sp.solveset(f, X, domain=sp.S.Reals))


# The unknowns with a Paper 2 version (FAL-419): a context, b^(2x) and a sum of logs
# whose root needs a calculator, given to 3 s.f.
QE_P2 = {"solve-in-context", "solve-hidden-exponential", "solve-hidden-log"}


def qe_paper2(q, x):
    """A Paper 2 root: irrational, clear of a 3 s.f. rounding edge, asked to 3 s.f."""
    need(not x.is_rational, "Paper 2 root doesn't need a calculator")
    need(not on_edge(x), "the answer is on a 3 s.f. rounding edge")
    need(q["answer"].get("show") == "sf" and "3 significant figures" in q["asked"], "Paper 2 is not asked and written to 3 s.f.")
    need(not q["answer"].get("exact"), "a Paper 2 answer is marked exactly")


def check_qeq(q):
    u = q["view"]["unknown"]
    g = q["given"]
    ans = q["answer"]
    L = q["lines"]
    p2 = q["paper"] == 2
    need(not p2 or u in QE_P2, f"{u} has no Paper 2 version")
    need(not p2 or q["view"]["angle"] != "factorise" or q["view"].get("same_angle"), "a factorising method was given Paper 2 numbers")
    if u in ("solve-factorisable", "solve-surd"):
        f = R(g["a"]) * X**2 + R(g["b"]) * X + R(g["c"])
        need(L[0].endswith(" = 0") and parse(L[0][:-4]) == sp.expand(f), "the equation shown is not the givens")
        need(R(g["a"]) in A_ALLOWED, "a outside the clean limits")
        rs = qe_roots_poly(f)
        need(len(rs) == 2, "not two roots")
        if u == "solve-factorisable":
            need(all(r.is_integer for r in rs), "the roots are not whole numbers")
            qr_check_common(q, tuple(rs), {"SL2.7.solve-equation#1": {tuple(sorted([-rs[0], -rs[1]]))}})
        else:
            h = (rs[0] + rs[1]) / 2
            d = sp.nsimplify(((rs[1] - rs[0]) / 2)**2)
            need(h.is_integer and d.is_integer and int(d) in SURDS, "the surd roots are outside the clean limits")
            qr_check_common(q, qr_norm(ans, {"h": str(h), "d": str(d)}))
    elif u == "solve-no-constant":
        lhs, rhs_ = L[0].split(" = ")
        f = parse(lhs) - parse(rhs_)
        need(sp.expand(f - (R(g["a"]) * X**2 + R(g["b"]) * X)) == 0, "the equation shown is not the givens")
        rs = qe_roots_poly(f)
        need(len(rs) == 2 and 0 in rs, "not two roots with 0 among them")
        qr_check_common(q, tuple(rs))
    elif u == "solve-in-context":
        m = re.match(r"^A rectangular yard is x m wide and \(x \+ (\d+)\) m long\. Its area is (\d+) m²\.$", L[0])
        if m:
            f = X * (X + R(m.group(1))) - R(m.group(2))
        else:
            m = re.match(r"^A right-angled triangle has shorter sides x cm and \(x \+ (\d+)\) cm, and its hypotenuse is \(x \+ (\d+)\) cm\.$", L[0])
            need(m is not None, "the context can't be read")
            f = X**2 + (X + R(m.group(1)))**2 - (X + R(m.group(2)))**2
        rs = qe_roots_poly(sp.expand(f))
        pos = [r for r in rs if r > 0]
        neg = [r for r in rs if r <= 0]
        need(len(pos) == 1 and len(neg) == 1, "the context doesn't rule out exactly one root")
        x = pos[0]
        need(g["paper"] == q["paper"], "the context's paper is not the question's")
        if g["paper"] == 1:
            need(x.is_integer and ans.get("exact"), "Paper 1 answer is not an exact whole number")
            want = qr_norm(ans, {"v": str(x)})
            wr = {"SL2.7.solve-equation#1": {qr_norm(ans, {"v": str(-neg[0])})}}
        else:
            need(not x.is_rational, "Paper 2 root doesn't need a calculator")
            need(not on_edge(x), "the answer is on a 3 s.f. rounding edge")
            want = sig3(x)
            wr = {"SL2.7.solve-equation#1": {sig3(-neg[0])}}
        qr_check_common(q, want, wr)
    elif u in ("solve-hidden-exponential", "choose-substitution"):
        m = re.match(r"^(\d+)\^\(2x\)(?: ([+−]) (?:(\d+) × )?(\d+)\^x)? ([+−]) (\d+) = 0$", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        b = R(m.group(1))
        B = sgn_num(m.group(2), m.group(3) or "1") if m.group(2) else 0
        need(m.group(4) is None or R(m.group(4)) == b, "two different bases")
        C = sgn_num(m.group(5), m.group(6))
        need((b, B, C) == (R(g["base"]), R(g["B"]), R(g["C"])), "the equation shown is not the givens")
        if u == "choose-substitution":
            need(ans["label"] == f"With u = {frac_text(b)}^x: ", "the substitution is not u = b^x")
            qr_check_common(q, (1, B, C))
        else:
            us = sorted(sp.solve(U**2 + B * U + C, U))
            good = [w for w in us if w > 0]
            bad = [w for w in us if w <= 0]
            need(len(good) == 1 and len(bad) == 1, "not exactly one u-root to reject")
            wrong1 = -sp.nsimplify(sp.log(-bad[0], b))
            if p2:
                # b is 2 or 3, so log_b u is rational only when u is a whole power of b.
                need(b in (2, 3) and good[0].is_integer and b ** round(float(sp.log(good[0], b))) != good[0], "Paper 2: x = log_b u should need a calculator")
                x = sp.log(good[0]) / sp.log(b)
                qe_paper2(q, x)
                wr = {"SL2.7.hidden-quadratic#0": {ext_sf(good[0])}, "SL2.7.hidden-quadratic#1": {ext_sf(wrong1)}}
                qr_check_common(q, ext_sf(x), wr)
            else:
                x = sp.nsimplify(sp.log(good[0], b))
                need(x.is_integer, "x is not a whole number")
                wr = {"SL2.7.hidden-quadratic#0": {qr_norm(ans, {"v": str(good[0])})},
                      "SL2.7.hidden-quadratic#1": {qr_norm(ans, {"v": str(wrong1)})}}
                qr_check_common(q, qr_norm(ans, {"v": str(x)}), wr)
    elif u == "solve-hidden-reciprocal":
        m = re.match(r"^x ([+−]) (\d+)/x = (−?\d+)$", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        c, t = sgn_num(m.group(1), m.group(2)), RD(m.group(3))
        rs = qe_roots_poly(X**2 - t * X + c)
        need(len(rs) == 2 and 0 not in rs, "not two non-zero solutions")
        qr_check_common(q, tuple(rs))
    elif u == "solve-hidden-log":
        m = re.match(r"^ln x \+ ln\(x ([+−]) (\d+)\) = ln (\d+)$", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        d, c = sgn_num(m.group(1), m.group(2)), R(m.group(3))
        rs = qe_roots_poly(X * (X + d) - c)
        ok = [r for r in rs if r > 0 and r + d > 0]
        bad = [r for r in rs if r not in ok]
        need(len(ok) == 1 and len(bad) == 1, "not exactly one root to reject")
        if p2:
            qe_paper2(q, ok[0])
            need(not on_edge(abs(bad[0])), "the rejected root is on a 3 s.f. rounding edge")
            qr_check_common(q, ext_sf(ok[0]), {"SL2.7.hidden-quadratic#1": {ext_sf(bad[0])}})
        else:
            need(ok[0].is_integer, "a Paper 1 root is not a whole number")
            qr_check_common(q, qr_norm(ans, {"v": str(ok[0])}), {"SL2.7.hidden-quadratic#1": {qr_norm(ans, {"v": str(bad[0])})}})
    elif u == "equation-from-roots":
        m = re.match(r"^The roots of a quadratic equation are x = (.+)\.$", L[0]) or re.match(r"^A quadratic equation has roots (.+)\.$", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        txt = m.group(1).replace("−", "-").replace("√", "sqrt")
        if "±" in txt:
            h, d = txt.split(" ± ")
            rs = [sp.sympify(h) + sp.sympify(d.replace("sqrt", "sqrt(") + ")"), sp.sympify(h) - sp.sympify(d.replace("sqrt", "sqrt(") + ")")]
        else:
            parts = txt.split(" and ")
            rs = [sp.sympify(re.sub(r"sqrt(\d+)", r"sqrt(\1)", p)) for p in parts]
        co = sp.Poly(sp.expand((X - rs[0]) * (X - rs[1])), X).all_coeffs()
        need(all(sp.nsimplify(c).is_integer for c in co), "the coefficients are not integers")
        qr_check_common(q, (1, sp.nsimplify(co[1]), sp.nsimplify(co[2])))
    elif u == "coefficient-from-root":
        txt = " ".join(L)
        m = re.search(r"x² \+ kx ([+−]) (\d+) = 0", txt)
        r = re.search(r"x = (−?\d+)", txt[m.end():])
        need(m is not None and r is not None, "can't read the equation and its root")
        c, r0 = sgn_num(m.group(1), m.group(2)), RD(r.group(1))
        k = sp.solve(r0**2 + K * r0 + c, K)[0]
        other = [x for x in sp.solve(X**2 + k * X + c, X) if x != r0]
        need(len(other) == 1, "no other root")
        qr_check_common(q, qr_norm(ans, {"k": str(k), "r": str(other[0])}))
    else:
        raise Fail(f"the checker has no solver for {u}")
    return None, None


# ── quadratic-inequality ──

QI_REL = {"<": lambda f: f < 0, "≤": lambda f: f <= 0, ">": lambda f: f > 0, "≥": lambda f: f >= 0}
# Papers (FAL-419): these have a Paper 2 version whose roots need a calculator (the ends
# to 3 s.f.); the largest-integer context always needs one; the rest are Paper 1.
QI_P2 = {"solve-against-zero", "solve-against-constant", "negative-a"}
QI_P2_ONLY = {"largest-integer"}


def qi_read(line):
    """'2x² − 3x + 1 ≤ 5' -> (f, rel, rhs) with f = lhs − rhs."""
    m = re.match(r"^(.+) (<|≤|>|≥) (−?[\d/]+)$", line)
    need(m is not None, f"can't read {line!r}")
    return sp.expand(parse(m.group(1)) - RD(m.group(3))), m.group(2), RD(m.group(3))


def check_qineq(q):
    u = q["view"]["unknown"]
    g = q["given"]
    ans = q["answer"]
    L = q["lines"]
    p2 = q["paper"] == 2
    need(p2 == (u in QI_P2_ONLY) or u in QI_P2, f"{u} is not asked on Paper {q['paper']}")
    if u == "largest-integer":
        m = re.match(r"^A mosaic has n rows of \(n \+ (\d+)\) tiles, and there are (\d+) tiles to use\.$", L[0])
        need(m is not None, "can't read the context")
        d, T = R(m.group(1)), R(m.group(2))
        S = sp.solve_univariate_inequality(X * (X + d) <= T, X, relational=False).intersect(sp.Interval(0, sp.oo))
        best = sp.floor(S.sup)
        need(not S.sup.is_rational, "Paper 2: the boundary should need a calculator")
        need(ans.get("exact"), "a whole-number count must be marked exactly")
        qr_check_common(q, qr_norm(ans, {"v": str(best)}))
        return None, None
    if u == "inequality-from-solution":
        p, qq = R(g["p"]), R(g["q"])
        inc = g["ends"] == "included"
        S = sp.Interval(p, qq, not inc, not inc) if g["shape"] == "between" else \
            sp.Union(sp.Interval(-sp.oo, p, True, not inc), sp.Interval(qq, sp.oo, not inc, True))
        if q["view"]["rep"] == "words":
            said = qr_interval_text("x", {"shape": g["shape"], "lo": g["p"], "hi": g["q"], "ends": g["ends"]})
            need(L[0] == f"The solution of a quadratic inequality is {said}.", "the solution shown is not the givens")
        else:
            side = "below" if g["shape"] == "between" else "above"
            need(f"where it is {side} the x-axis" in L[0] and (", the roots included" in L[0]) == inc, "the solution said is not the givens")
        if q.get("graph"):
            gr = q["graph"]
            need(sorted(pt["x"] for pt in gr["points"]) == [float(p), float(qq)], "the roots marked are not the givens")
        want = None
        for rel in QI_REL:
            f = X**2 - (p + qq) * X + p * qq
            if sp.solve_univariate_inequality(QI_REL[rel](f), X, relational=False) == S:
                want = qr_norm(ans, {"b": str(-(p + qq)), "c": str(p * qq), "rel": rel})
        need(want is not None, "no monic inequality has this solution")
        qr_check_common(q, want)
        return None, None
    f, rel, rhs_ = qi_read(L[0])
    need(sp.expand(f - (R(g["a"]) * X**2 + R(g["b"]) * X + R(g["c"]))) == 0 and rel == g["rel"], "the inequality shown is not the givens")
    S = sp.solve_univariate_inequality(QI_REL[rel](f), X, relational=False)
    if u == "no-real-roots-case":
        need(sp.discriminant(f, X) < 0, "the quadratic has real roots")
        h = -R(g["b"]) / (2 * R(g["a"]))
        want = qr_norm(ans, {"v": "all real x" if S == sp.S.Reals else "no real x"})
        need(S in (sp.S.Reals, sp.S.EmptySet), "the solution is not all x or no x")
        need(ans["fixed"]["options"][2:] == [f"x = {frac_text(h)} only", f"every x except {frac_text(h)}"], "the options don't name the vertex")
        qr_check_common(q, want)
        return None, None
    rs = sorted(sp.solveset(f, X, domain=sp.S.Reals), key=float)
    if p2:
        # Paper 2: whole-number coefficients, irrational roots clear of a 3 s.f. rounding edge.
        a_, b_, c_ = R(g["a"]), R(g["b"]), R(g["c"])
        need(a_ in A_ALLOWED and a_.q == 1 and abs(b_) <= B_MAX and abs(c_) <= C_MAX and c_ != 0, "the quadratic is outside the clean limits")
        need(len(rs) == 2 and not any(r.is_rational for r in rs), "Paper 2: the roots should need a calculator")
        need(not any(on_edge(abs(r)) for r in rs), "a root is on a 3 s.f. rounding edge")
        need(ans.get("show") == "sf" and "3 significant figures" in q["asked"], "Paper 2 is not asked and written to 3 s.f.")
    else:
        need(len(rs) == 2 and all(r.is_rational for r in rs), "the roots are not two rational numbers")
    cv = qr_sf_set if p2 else (lambda S: S)
    if q.get("graph"):
        gr = q["graph"]
        if p2:
            # The roots are for the GDC to find, so none are marked; the curve is f.
            need(not gr["points"], "a Paper 2 graph marks its roots")
            need(abs(gr["a"] - float(R(g["a"]))) < 1e-9 and abs(gr["h"] - float(-R(g["b"]) / (2 * R(g["a"])))) < 1e-9, "the graph is not the given parabola")
        else:
            need(sorted(pt["x"] for pt in gr["points"]) == [float(rs[0]), float(rs[1])], "the roots marked are not the roots")
    wr = {}
    inc = "left out" if rel in ("<", ">") else "included"
    between = sp.Interval(rs[0], rs[1], inc == "left out", inc == "left out")
    outside = sp.Union(sp.Interval(-sp.oo, rs[0], True, inc == "left out"), sp.Interval(rs[1], sp.oo, inc == "left out", True))
    if S == outside:
        wr["SL2.7.inequality#1"] = {cv(between)}
    if u == "negative-a":
        need(R(g["a"]) < 0, "a is not negative")
        # Dividing by −1 but keeping the sign solves the opposite inequality.
        wr["SL2.7.inequality#2"] = {cv(sp.solve_univariate_inequality(QI_REL[rel](-f), X, relational=False))}
    if u == "square-against-constant":
        n = sp.sqrt(rhs_)
        need(n.is_integer and f == X**2 - rhs_, "not x² against a square")
        lt = rel in ("<", "≤")
        wr["SL2.7.inequality#0"] = {("pm", "pm_lt" if lt else "pm_gt", n, inc),
                                    qr_set("bound", {"rel": rel, "v": str(n)})}
    qr_check_common(q, cv(S), wr)
    return None, None



# ── Coverage from the catalogue itself ───────────────────────

def catalogue_cells(type_ids):
    doc = json.loads((ROOT / "curriculum/question-types.json").read_text())
    out = {}
    for t in doc["types"]:
        if t["id"] not in type_ids:
            continue
        cells = []
        for u in t["unknowns"]:
            ms = []
            for a in t["angles"]:
                if u["id"] in a["suits"] and a["method"] not in ms:
                    ms.append(a["method"])
            for rep in u["reps"]:
                for m in ms or ["any"]:
                    cells.append(f"{t['id']}|{u['id']}|{rep}|{m}")
        out[t["id"]] = cells
    return out


# ── Cubic: tangents, normals and stationary points (FAL-394) ─
# The `cubic` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/cubic.gd.

CUBIC_A = {1, -1, 2, -2}
CUBIC_PQ_MAX, CUBIC_B_MAX, CUBIC_C_MAX, CUBIC_D_MAX = 4, 30, 30, 9
CUBIC_Y_MAX, CUBIC_X0_MAX, CUBIC_M0_MAX = 60, 3, 40
CUBIC_R_MAX, CUBIC_G_MAX = 5, 60
CUBIC_NORMAL_DEN_MAX = 6
CUBIC_EXACT = {"derivative", "derivative-from-fraction", "coefficient-from-tangent"}
MAXMIN = ("local maximum", "local minimum")
K = LETTERS["k"]
INT_ = r"(−?\d+)"


def cubic_poly(co):
    a, b, c, d = (R(v) for v in co)
    return sp.expand(a * X**3 + b * X**2 + c * X + d)


def shown_curve(q, letters=()):
    """The curve as the first line shows it: f(x) = … , (…)/x, or "A curve has
    equation y = …"."""
    line = q["lines"][0]
    if q["view"]["rep"] == "words":
        m = re.fullmatch(r"A curve has equation y = (.+?)(?:, where k is a constant)?\.", line)
        need(m, f"words line {line!r}")
        return parse(m.group(1), letters)
    need(line.startswith("f(x) = "), f"equation line {line!r}")
    body = rhs(line)
    if body.endswith(",  x ≠ 0"):
        num = re.fullmatch(r"\((.+)\)/x,  x ≠ 0", body)
        need(num, f"fraction line {line!r}")
        top = parse(num.group(1))
        need(sp.Poly(top, X).coeff_monomial(1) == 0, "the top has a constant term, so it isn't a cubic over x")
        return sp.expand(sp.cancel(top / X))
    return parse(body, letters)


def shown_number(text, pattern):
    m = re.search(pattern, text)
    need(m, f"{pattern!r} not in {text!r}")
    return R(m.group(1).replace("−", "-"))


def shown_line_gradient(text):
    """The gradient of the line y = mx + c named in the text."""
    m = re.search(r"line (y = [^.]+?)\. ", text + " ")
    need(m, f"no line in {text!r}")
    p = sp.Poly(parse(rhs(m.group(1))), X)
    need(p.degree() == 1, f"not a line: {m.group(1)}")
    return p.coeff_monomial(X)


def check_cubic(q):
    if q.get("paper", 1) == 2:
        return check_cubic_p2(q)
    u = q["view"]["unknown"]
    s = q["situation"]
    g = q["given"]
    a, b, c, d, p, r = (R(s[n]) for n in ["a", "b", "c", "d", "p", "q"])
    f = sp.expand(a * X**3 + b * X**2 + c * X + d)
    f1 = sp.diff(f, X)
    f2 = sp.diff(f, X, 2)
    need(a in CUBIC_A, f"a = {a} is not a clean choice")
    need(all(v.q == 1 for v in (b, c, d, p, r)), "a coefficient or a stationary x is not a whole number")
    need(p < r and abs(p) <= CUBIC_PQ_MAX and abs(r) <= CUBIC_PQ_MAX, "p and q out of limits")
    need(sp.expand(f1 - 3 * a * (X - p) * (X - r)) == 0, "f′ is not 3a(x − p)(x − q)")
    need(abs(b) <= CUBIC_B_MAX and abs(c) <= CUBIC_C_MAX and abs(d) <= CUBIC_D_MAX, "b, c or d too big")
    need(abs(f.subs(X, p)) <= CUBIC_Y_MAX and abs(f.subs(X, r)) <= CUBIC_Y_MAX, "a stationary point is too high")
    need(R(s["fp"]) == f.subs(X, p) and R(s["fq"]) == f.subs(X, r), "f(p) or f(q) is wrong")
    need(cubic_poly(g["f"]) == f, "the givens describe another cubic than the situation")
    x0 = None
    if "x0" in g:
        x0 = R(g["x0"])
        need(x0.q == 1 and x0 != 0 and abs(x0) <= CUBIC_X0_MAX, f"x0 = {x0} out of limits")
        need(R(s["x0"]) == x0, "x0 differs from the situation")
        need(f1.subs(X, x0) != 0 and abs(f1.subs(X, x0)) <= CUBIC_M0_MAX, "f′(x0) is 0 or too big")
        need(abs(f.subs(X, x0)) <= CUBIC_Y_MAX, "f(x0) too big")
    text = " ".join(q["lines"] + [q["asked"]])

    # What the student sees is the given cubic (with k for the hidden coefficient).
    if u == "coefficient-from-tangent":
        hid = g["hidden"]
        need(hid in ("b", "c") and s["hidden"] == hid, "hidden coefficient")
        fk = sp.expand(f - (b * X**2 if hid == "b" else c * X) + (K * X**2 if hid == "b" else K * X))
        need(shown_curve(q, ["k"]) == fk, "the curve shown with k is not the given one")
    elif u != "read-from-tangent":
        need(shown_curve(q) == f, "the curve shown is not the given one")
    if u == "derivative-from-fraction":
        need(g.get("fraction") is True and q["view"]["rep"] == "equation", "fraction form")

    if u in CUBIC_EXACT:
        need(q["answer"].get("exact") is True, "the answer is not marked exactly")

    def coeffs2(e):
        pl = sp.Poly(e, X)
        return pl.coeff_monomial(X**2), pl.coeff_monomial(X), pl.coeff_monomial(1)

    if u in ("derivative", "derivative-from-fraction"):
        u2, u1, u0 = coeffs2(f1)
        return {"u2": u2, "u1": u1, "u0": u0}, None
    if u == "gradient-at-point":
        need(shown_number(text, r"(?:f′\(|where x = )" + INT_) == x0, "the x shown is not x0")
        return {"v": f1.subs(X, x0)}, None
    if u in ("tangent-at-point", "normal-at-point"):
        need(shown_number(q["asked"], r"x = " + INT_) == x0, "the x shown is not x0")
        m = f1.subs(X, x0)
        if u == "normal-at-point":
            m = -1 / m
            need(m.q <= CUBIC_NORMAL_DEN_MAX and (f.subs(X, x0) - m * x0).q <= CUBIC_NORMAL_DEN_MAX,
                 "the normal is not Paper 1 friendly (a denominator above 6)")
        return {"m": m, "c": f.subs(X, x0) - m * x0}, None
    if u == "read-from-tangent":
        m = re.fullmatch(r"(?:L: |.* has equation )(y = [^.]+)\.?", q["lines"][0])
        need(m, "no tangent shown")
        tl = parse(rhs(m.group(1)))
        need(shown_number(text, r"x = " + INT_) == x0, "the x shown is not x0")
        need(R(q["answer"]["fixed"]["x0"]) == x0, "the answer names another x")
        tangent = sp.expand(f1.subs(X, x0) * (X - x0) + f.subs(X, x0))
        need(tl == tangent, "the line shown is not the tangent to the situation's cubic at x0")
        pl = sp.Poly(tl, X)
        return {"m": pl.coeff_monomial(X), "y": tl.subs(X, x0)}, None
    if u == "x-for-gradient":
        gr = R(g["g"])
        if q["view"]["rep"] == "words":
            need(shown_line_gradient(q["asked"]) == gr, "the line shown has another gradient")
        else:
            need(shown_number(q["asked"], r"f′\(x\) = " + INT_) == gr, "the gradient shown is not g")
        xs = sorted(sp.solve(sp.Eq(f1, gr), X))
        need(len(xs) == 2 and all(v.is_integer and abs(v) <= CUBIC_R_MAX for v in xs), f"f′(x) = {gr} gives {xs}")
        need(gr != 0 and abs(gr) <= CUBIC_G_MAX, "g out of limits")
        return {"r1": xs[0], "r2": xs[1]}, None
    if u == "coefficient-from-tangent":
        gr = R(g["g"])
        need(gr == f1.subs(X, x0), "the given gradient is not f′(x0)")
        need(shown_number(q["asked"], r"x = " + INT_) == x0, "the x shown is not x0")
        if q["view"]["rep"] == "words":
            need(shown_line_gradient(q["asked"]) == gr, "the line shown has another gradient")
            lm = re.search(r"line (y = [^.]+?)\. ", q["asked"] + " ")
            need(parse(rhs(lm.group(1))) != sp.expand(gr * (X - x0) + f.subs(X, x0)), "the parallel line is the tangent itself")
        else:
            need(shown_number(q["asked"], r"has gradient " + INT_) == gr, "the gradient shown is not g")
        sol = sp.solve(sp.Eq(sp.diff(fk, X).subs(X, x0), gr), K)
        need(len(sol) == 1, "the gradient doesn't fix k")
        need(sol[0] == (b if hid == "b" else c), "k is not the hidden coefficient")
        return {"v": sol[0]}, None

    xs = sorted(sp.solve(f1, X))
    need(len(xs) == 2 and xs == [p, r], "the stationary points are not at p and q")
    if u == "stationary-points":
        return {"x1": xs[0], "y1": f.subs(X, xs[0]), "x2": xs[1], "y2": f.subs(X, xs[1])}, None
    if u == "nature":
        need([R(v) for v in g["xs"]] == xs, "the x-values given are not the stationary points")
        need(shown_number(q["asked"], r"x = " + INT_ + r" and") == xs[0], "the first x shown")
        need(shown_number(q["asked"], r"and x = " + INT_) == xs[1], "the second x shown")
        need([R(q["answer"]["fixed"][k]) for k in ("p", "q")] == xs, "the answer names other x-values")
        kinds = []
        for x in xs:
            v = f2.subs(X, x)
            need(v != 0, "f″ = 0 at a stationary point")
            kinds.append(MAXMIN[0] if v < 0 else MAXMIN[1])
        return {"k1": kinds[0], "k2": kinds[1]}, None
    if u == "inflexion-point":
        xi = sp.solve(f2, X)
        need(len(xi) == 1 and xi[0].is_integer, f"f″ = 0 at {xi}")
        xi = xi[0]
        need(f2.subs(X, xi - 1) * f2.subs(X, xi + 1) < 0, "f″ doesn't change sign")
        need(abs(f.subs(X, xi)) <= CUBIC_Y_MAX, "the point of inflexion is too high")
        return {"x": xi, "y": f.subs(X, xi)}, None
    if u == "max-value":
        mx = [x for x in xs if f2.subs(X, x) < 0]
        need(len(mx) == 1, "not one local maximum")
        return {"v": f.subs(X, mx[0])}, None
    raise Fail(f"the checker has no solver for {u}")


# ── Cubic, Paper 2 (FAL-419) ──
# The calculator cubic: decimal coefficients (tenths, at least one of a, b, c not
# whole), f′ with two irrational roots, and x₀ a decimal to one place. Every value is
# solved again with SymPy and given to 3 s.f., clear of a rounding edge. The engine's
# copy of these limits is in game/engine/situations/cubic.gd (P2_*).

CUBIC_P2_UNKNOWNS = {"x-for-gradient", "tangent-at-point", "normal-at-point", "stationary-points", "max-value"}
CUBIC_P2_A = {sp.Rational(n, 10) * sg for n in (2, 4, 5, 10, 15, 20) for sg in (1, -1)}
CUBIC_P2_B_MAX, CUBIC_P2_C_MAX, CUBIC_P2_D_MAX = 4, 9, 9
CUBIC_P2_X_MAX, CUBIC_P2_X_MIN, CUBIC_P2_X_GAP = 5, sp.Rational(1, 10), sp.Rational(1, 2)
CUBIC_P2_X0_MAX, CUBIC_P2_G_MAX = 3, 20
CUBIC_P2_TOL = sp.Rational(1, 10**6)
CUBIC_P2_V_MIN = sp.Rational(1, 10)   # every number of an answer is at least this big
DEC_ = r"(−?\d+(?:\.\d+)?)"


def cubic_sf(x):
    return "0" if x == 0 else sig3(x).replace("-", "−")


def cubic_p2_vals(kind, v):
    """An answer's numbers in a fixed order: roots and points sorted, as written."""
    if kind == "roots":
        return sorted([v["r1"], v["r2"]], key=num)
    if kind == "points2":
        ps = sorted([(v["x1"], v["y1"]), (v["x2"], v["y2"])], key=lambda p: (num(p[0]), num(p[1])))
        return [ps[0][0], ps[0][1], ps[1][0], ps[1][1]]
    if kind == "line":
        return [v["m"], v["c"]]
    return [v["v"]]


def cubic_p2_text(ans, v):
    kind = ans["kind"]
    xs = [cubic_sf(x) for x in cubic_p2_vals(kind, v)]
    if kind == "roots":
        return f"x = {xs[0]} and x = {xs[1]}"
    if kind == "points2":
        return f"({xs[0]}, {xs[1]}) and ({xs[2]}, {xs[3]})"
    if kind == "line":
        m, c = v["m"], v["c"]
        return "y = " + xs[0] + "x" + ("" if c == 0 else (" − " if c < 0 else " + ") + cubic_sf(abs(c)))
    return ans["label"] + xs[0]


def cubic_p2_common(q, want, wrongs):
    """want: slot -> exact value. wrongs: ref -> list of slot dicts that slip gives."""
    ans = q["answer"]
    kind = ans["kind"]
    need(ans.get("show") == "sf" and not ans.get("exact"), "a Paper 2 answer is not written to 3 s.f.")
    need("correct to 3 significant figures" in q["asked"], "the question doesn't ask for 3 s.f.")
    wv = cubic_p2_vals(kind, want)
    for x in wv:
        need(abs(x) >= CUBIC_P2_V_MIN and not on_edge(abs(x)), f"the answer's {float(num(x)):.8} is too small or on a 3 s.f. rounding edge")
    need(any(not sp.sympify(x).is_rational or R(sig3(x)) != x for x in wv), "no number needs rounding: no calculator needed")

    def rv(vals):
        return {k: R(x) for k, x in vals.items()}

    def close(vals):
        got = cubic_p2_vals(kind, rv(vals))
        return all(abs(num(a) - num(b)) <= CUBIC_P2_TOL * max(1, abs(num(b))) for a, b in zip(got, wv))

    right = cubic_p2_text(ans, want)
    need(close(ans["values"]), f"engine answer {q['answer_text']!r} is wrong (expected {right!r})")
    need(q["answer_text"] == right, f"answer text {q['answer_text']!r}, expected {right!r}")
    ch = q["choices"]
    need(len(ch) == 4, f"{len(ch)} options")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right option")
    texts = set()
    wrong_texts = {ref: {cubic_p2_text(ans, w) for w in ws} for ref, ws in wrongs.items()}
    for o in ch:
        ov = rv(o["values"])
        need(o["text"] not in texts, f"two options read the same: {o['text']!r}")
        texts.add(o["text"])
        if o.get("trap"):
            need(kind == "number" and not o["correct"] and not o["ref"], f"rounding trap {o['text']!r} is wrong-tagged")
            need(ov["v"] == R(sig3(want["v"], 2)) and o["text"] != right, f"rounding trap {o['text']!r} is not the answer to 2 s.f.")
            continue
        for x in cubic_p2_vals(kind, ov):
            need(x == 0 or not on_edge(abs(x)), f"option {o['text']!r} is on a 3 s.f. rounding edge ({float(num(x)):.8})")
        need(o["text"] == cubic_p2_text(ans, ov), f"option text {o['text']!r} doesn't say its values")
        need((o["text"] == right) == o["correct"], f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'} but is {'right' if o['text'] == right else 'wrong'}")
        if o["correct"]:
            need(close(o["values"]), "the right option is not the answer")
        if o["ref"]:
            need(not o["correct"], "a misconception is the right answer")
            need(o["ref"] in wrong_texts, f"the checker can't confirm {o['ref']} on {q['view']['unknown']}")
            need(o["text"] in wrong_texts[o["ref"]], f"option {o['text']!r} is not what {o['ref']} gives")
    need(len(q["solutions"]) >= 1, "no worked solution")
    for sol in q["solutions"]:
        need(close(sol["result"]), f"{sol['name']}: last step gives {sol['result']}, not the answer")
        need(QR_STEPS[0] <= len(sol["steps"]) <= QR_STEPS[1], f"{sol['name']}: {len(sol['steps'])} steps, not 2 to 5")
        need(any("GDC" in st for st in sol["steps"]), f"{sol['name']}: the working doesn't use the calculator")
        need(right in sol["steps"][-1], f"{sol['name']}: last step {sol['steps'][-1]!r} doesn't state the answer")
    if q["view"]["angle"] != "any":
        need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")


def cubic_p2_pair(xs, what):
    """Two x-values fit to ask for to 3 s.f.: irrational, in range, apart, clear."""
    need(len(xs) == 2 and all(x.is_real for x in xs), f"{what}: not two real roots ({xs})")
    need(all(not x.is_rational for x in xs), f"{what}: a root is rational, so no calculator is needed")
    need(xs[1] - xs[0] >= CUBIC_P2_X_GAP, f"{what}: the roots are too close")
    for x in xs:
        need(CUBIC_P2_X_MIN <= abs(x) <= CUBIC_P2_X_MAX, f"{what}: x = {float(num(x)):.6} out of limits")
        need(not on_edge(abs(x)), f"{what}: x = {float(num(x)):.8} is on a 3 s.f. rounding edge")


def check_cubic_p2(q):
    u = q["view"]["unknown"]
    s = q["situation"]
    g = q["given"]
    need(u in CUBIC_P2_UNKNOWNS, f"{u} has no Paper 2 version")
    need(s.get("paper") == 2, "the situation is not the Paper 2 cubic")
    a, b, c, d = (R(v) for v in g["f"])
    need([R(s[n]) for n in "abcd"] == [a, b, c, d], "the givens describe another cubic than the situation")
    need(a in CUBIC_P2_A, f"a = {a} is not a Paper 2 choice")
    need(all((10 * v).q == 1 and v != 0 for v in (b, c, d)), "b, c or d is 0 or not in tenths")
    need(abs(b) <= CUBIC_P2_B_MAX and abs(c) <= CUBIC_P2_C_MAX and abs(d) <= CUBIC_P2_D_MAX, "b, c or d too big")
    need(any(v.q != 1 for v in (a, b, c)), "every coefficient of f′ is whole: not a calculator cubic")
    f = sp.expand(a * X**3 + b * X**2 + c * X + d)
    f1 = sp.diff(f, X)
    f2 = sp.diff(f, X, 2)
    need(sp.expand(sp.nsimplify(shown_curve(q), rational=True)) == f, "the curve shown is not the given one")
    xs = sorted(sp.solve(f1, X), key=num)
    cubic_p2_pair(xs, "f′(x) = 0")
    for x in xs:
        y = f.subs(X, x)
        need(abs(num(y)) <= CUBIC_Y_MAX and not on_edge(abs(y)), f"f({float(num(x)):.6}) = {float(num(y)):.8} is too high or on a rounding edge")
    for k, x in (("p", xs[0]), ("q", xs[1]), ("fp", f.subs(X, xs[0])), ("fq", f.subs(X, xs[1]))):
        need(abs(num(R(s[k])) - num(x)) <= CUBIC_P2_TOL * max(1, abs(num(x))), f"the situation's {k} is not f's")
    text = " ".join(q["lines"] + [q["asked"]])

    if u == "x-for-gradient":
        gr = R(g["g"])
        need(gr.q == 1 and gr != 0 and abs(gr) <= CUBIC_P2_G_MAX, "g out of limits")
        if q["view"]["rep"] == "words":
            need(shown_line_gradient(q["asked"]) == gr, "the line shown has another gradient")
        else:
            need(shown_number(q["asked"], r"f′\(x\) = " + INT_) == gr, "the gradient shown is not g")
        rs = sorted(sp.solve(sp.Eq(f1, gr), X), key=num)
        cubic_p2_pair(rs, f"f′(x) = {gr}")
        cubic_p2_common(q, {"r1": rs[0], "r2": rs[1]}, {})
        return None, None
    if u == "max-value":
        mx = [x for x in xs if f2.subs(X, x) < 0]
        need(len(mx) == 1, "not one local maximum")
        need(q["answer"]["label"] == ("y = " if q["view"]["rep"] == "words" else "local maximum = "), "the answer's label")
        cubic_p2_common(q, {"v": f.subs(X, mx[0])}, {"SL5.8.optimise-given-function#0": [{"v": mx[0]}]})
        return None, None
    if u == "stationary-points":
        ys = [f.subs(X, x) for x in xs]
        cubic_p2_common(q, {"x1": xs[0], "y1": ys[0], "x2": xs[1], "y2": ys[1]},
                        {"SL5.8.find-stationary-points#2": [{"x1": xs[0], "y1": 0, "x2": xs[1], "y2": 0}]})
        return None, None

    # The tangent and the normal at x₀.
    x0 = R(g["x0"])
    need((10 * x0).q == 1 and x0.q != 1 and abs(x0) <= CUBIC_P2_X0_MAX, f"x0 = {x0} is not a decimal to one place up to 3")
    need(R(s["x0"]) == x0, "x0 differs from the situation")
    need(shown_number(q["asked"], r"x = " + DEC_) == x0, "the x shown is not x0")
    y0, m = f.subs(X, x0), f1.subs(X, x0)
    ct = y0 - m * x0
    need(m != 0 and abs(m) != 1 and abs(m) <= CUBIC_M0_MAX and abs(y0) <= CUBIC_Y_MAX, "f′(x0) or f(x0) out of limits")
    need(ct != 0, "the tangent goes through the origin")
    if u == "tangent-at-point":
        mn = -1 / m
        cubic_p2_common(q, {"m": m, "c": ct}, {
            "SL5.4.tangent-equation#1": [{"m": m, "c": m - m * x0}],
            "SL5.4.tangent-equation#2": [{"m": mn, "c": y0 - mn * x0}]})
        return None, None
    if u == "normal-at-point":
        mn = -1 / m
        cubic_p2_common(q, {"m": mn, "c": y0 - mn * x0}, {
            "SL5.4.normal-equation#0": [{"m": -m, "c": y0 + m * x0}, {"m": 1 / m, "c": y0 - x0 / m}],
            "SL5.4.normal-equation#1": [{"m": mn, "c": ct}]})
        return None, None
    raise Fail(f"the checker has no Paper 2 solver for {u}")


# ── Quadratics extension types (FAL-459) ─────────────────────
# The fn-pre-* prior learning, fn-ext-quadratic-model and the two fn-link-* types,
# each on its own situation. Their answers add kinds (see game/engine/answer.gd), and
# three formats are built on their questions: error-spot, method-pick and
# true-false-reason.

EXT_KINDS = {"poly", "named", "pair", "brackets", "brackets2", "common", "pm_surd", "range2", "related", "features", "angles", "factorised", "axis"}
EXTRA_FORMATS = {"error-spot", "method-pick", "true-false-reason"}
SUPS = str.maketrans("0123456789-", "⁰¹²³⁴⁵⁶⁷⁸⁹⁻")
CATALOGUE = None


def game_type(tid):
    """A type as the game's catalogue copy has it (with method names)."""
    global CATALOGUE
    if CATALOGUE is None:
        CATALOGUE = {t["id"]: t for t in json.loads((ROOT / "game/data/catalogue.json").read_text())["types"]}
    return CATALOGUE[tid]


def ext_sup(p):
    p = int(p)
    return "" if p == 1 else str(p).translate(SUPS)


def ext_terms(coeffs, powers, letter="x", dec=False):
    out = ""
    for c, p in zip(coeffs, powers):
        c, p = R(c), int(p)
        if c == 0:
            continue
        if dec:
            body = dec_text(abs(c)) if p == 0 else ("" if abs(c) == 1 else dec_text(abs(c))) + letter + ext_sup(p)
        else:
            body = frac_text(abs(c)) if p == 0 else qr_lead(abs(c)) + letter + ext_sup(p)
        out = (("−" if c < 0 else "") + body) if out == "" else out + (" − " if c < 0 else " + ") + body
    return out or "0"


def ext_sf(x):
    return sig3(x).replace("-", "−")


def ext_shown(ans, x):
    show = ans.get("show", "")
    if show == "sf":
        return ext_sf(R(x))
    if show == "dec":
        return dec_text(x)
    return frac_text(x)


def ext_pi(x):
    x = R(x)
    if x == 0:
        return "0"
    top = "π" if abs(x.p) == 1 else f"{abs(x.p)}π"
    return ("−" if x < 0 else "") + top + ("" if x.q == 1 else f"/{x.q}")


def ext_poly_parts(ans, v):
    fx = ans["fixed"]
    n = len(fx["powers"])
    cs = [fx["lead"] if i == 0 and "lead" in fx else v[f"c{i}"] for i in range(n)]
    ps = [int(R(v[f"e{i}"])) if fx.get("typed_powers") else int(fx["powers"][i]) for i in range(n)]
    return cs, ps


def ext_bracket(r):
    """(x + r) as the game writes it: "(x + 3)", "(x − 5)"."""
    r = R(r)
    return "x" if r == 0 else f"(x {'+' if r > 0 else '−'} {frac_text(abs(r))})"


def ext_text(ans, v):
    kind, fx, label = ans["kind"], ans.get("fixed") or {}, ans.get("label", "")
    if kind == "number":
        return label + ext_shown(ans, v["v"]) + ans.get("unit", "")
    if kind == "poly":
        cs, ps = ext_poly_parts(ans, v)
        return label + ext_terms(cs, ps, fx.get("var", "x"), ans.get("show") == "dec")
    if kind == "named":
        units = fx.get("units", [""] * len(fx["names"]))
        return ", ".join(f"{n} = {ext_shown(ans, v[f'v{i}'])}{units[i]}" for i, n in enumerate(fx["names"]))
    if kind == "pair":
        a, b = sorted([R(v["r1"]), R(v["r2"])])
        return f"{label}{frac_text(a)} and {frac_text(b)}"
    if kind == "brackets":
        a, b = sorted([R(v["r"]), R(v["s"])])
        return label + ext_bracket(b) + ext_bracket(a)
    if kind == "brackets2":
        return label + f"({qr_poly([v['a1'], v['b1']])})({qr_poly([v['a2'], v['b2']])})"
    if kind == "common":
        return label + qr_lead(v["g"]) + "x(" + qr_poly([v["a"], v["b"]]) + ")"
    if kind == "pm_surd":
        h = R(v["h"])
        return label + ("" if h == 0 else frac_text(h) + " ") + "± " + qr_surd(v["m"], v["r"])
    if kind == "range2":
        return f"{frac_text(v['lo'])} {v['r1']} {fx.get('var', 'x')} {v['r2']} {frac_text(v['hi'])}"
    if kind == "related":
        a, b = sorted([R(v["o1"]), R(v["o2"])])
        return f"same value {ext_pi(v['s'])}; opposite sign {ext_pi(a)} and {ext_pi(b)}"
    if kind == "features":
        a, b = sorted([R(v["r1"]), R(v["r2"])])
        return f"y-intercept {frac_text(v['c'])}; roots {frac_text(a)} and {frac_text(b)}; vertex {qr_point(v['h'], v['k'])}"
    if kind == "axis":
        return f"{v['var']} = {frac_text(v['h'])}"
    if kind == "factorised":
        p_, q_ = sorted([R(v["p"]), R(v["q"])])
        return "f(x) = " + qr_lead(v["a"]) + ext_bracket(-p_) + ext_bracket(-q_)
    if kind == "angles":
        xs = [ext_pi(x) for x in sorted(R(v[f"a{i}"]) for i in range(int(fx["n"])))]
        return "x = " + (", ".join(xs[:-1]) + " or " + xs[-1] if len(xs) > 1 else xs[0])
    raise Fail(f"the checker can't write answers of kind {kind}")


def ext_norm(ans, v):
    kind, fx = ans["kind"], ans.get("fixed") or {}
    if kind == "number":
        return ext_sf(R(v["v"]))
    if kind == "poly":
        cs, ps = ext_poly_parts(ans, v)
        return tuple(sorted(zip(ps, (R(c) for c in cs))))
    if kind == "named":
        vals = [R(v[f"v{i}"]) for i in range(len(fx["names"]))]
        return tuple(ext_sf(x) if ans.get("show") == "sf" else x for x in vals)
    if kind == "pair":
        return tuple(sorted([R(v["r1"]), R(v["r2"])]))
    if kind == "brackets":
        return tuple(sorted([R(v["r"]), R(v["s"])]))
    if kind == "brackets2":
        return tuple(sorted([(R(v["a1"]), R(v["b1"])), (R(v["a2"]), R(v["b2"]))]))
    if kind == "common":
        return (R(v["g"]), R(v["a"]), R(v["b"]))
    if kind == "pm_surd":
        return (R(v["h"]), R(v["m"]), R(v["r"]))
    if kind == "range2":
        return (R(v["lo"]), v["r1"], v["r2"], R(v["hi"]))
    if kind == "related":
        return (R(v["s"]), tuple(sorted([R(v["o1"]), R(v["o2"])])))
    if kind == "features":
        return (R(v["c"]), tuple(sorted([R(v["r1"]), R(v["r2"])])), R(v["h"]), R(v["k"]))
    if kind == "angles":
        return tuple(sorted(R(v[f"a{i}"]) for i in range(int(fx["n"]))))
    if kind == "factorised":
        return (R(v["a"]), tuple(sorted([R(v["p"]), R(v["q"])])))
    if kind == "axis":
        return (v["var"], R(v["h"]))
    raise Fail(f"the checker can't compare answers of kind {kind}")


def ext_poly_values(ans, coeffs):
    """Answer values for a polynomial given as power -> coefficient, in ans's shape."""
    fx = ans["fixed"]
    out = {}
    for i, p in enumerate(fx["powers"]):
        c = coeffs.get(int(p), 0)
        if i == 0 and "lead" in fx:
            need(R(fx["lead"]) == c, f"the given leading coefficient {fx['lead']} is not {c}")
            continue
        out[f"c{i}"] = str(c)
    extra = set(coeffs) - {int(p) for p in fx["powers"]}
    need(all(coeffs[p] == 0 for p in extra), f"the answer's powers {fx['powers']} miss a term of {coeffs}")
    return out


def poly_coeffs(f):
    return {int(m[0]): c for m, c in sp.Poly(sp.expand(f), X).terms()} if f != 0 else {}


def ext_misconception_refs(tid, as_=None):
    """The type's misconceptions by ref (its own, or <type id>#<index>)."""
    t = game_type(tid)
    return {m.get("ref", f"{tid}#{i}"): m for i, m in enumerate(t.get("misconceptions", [])) if as_ is None or m["as"] == as_}


def eq_true(line, letters=()):
    """Whether a line 'A = B' (or 'A = B = C') is an identity in x."""
    sides = [p.strip() for p in line.replace("[", "(").replace("]", ")").split(" = ")]
    need(len(sides) >= 2, f"no '=' in {line!r}")
    vals = [parse(p, letters) for p in sides]
    return all(sp.expand(vals[0] - w) == 0 for w in vals[1:])


SPOT_CHECKS = {}


def check_format(q):
    """The four options of an error-spot, method-pick or true-false-reason question."""
    fmt, ch = q["format"], q["choices"]
    need(len(ch) == 4, f"{len(ch)} options")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right option")
    need(len({o["text"] for o in ch}) == 4, "two options read the same")
    right = next(o for o in ch if o["correct"])
    base = q["base_choices"]
    need(len(base) == 4 and sum(1 for o in base if o["correct"]) == 1, "the question it is built on has no four options")
    t = game_type(q["view"]["type"])
    u = q["view"]["unknown"]
    need(fmt in t["formats"], f"{t['id']} does not list the format {fmt}")
    if fmt == "true-false-reason":
        claim = q["claim"]
        claimed = [o for o in base if o["text"] == claim]
        need(len(claimed) == 1 and not claimed[0].get("trap"), f"the student's answer {claim!r} is not one of the question's options")
        need(f"A student's answer: {claim}. True or false?" in q["prompt"], "the prompt doesn't state the student's answer")
        wrong_texts = {o["text"] for o in base if not o["correct"]}
        if claimed[0]["correct"]:
            need(right["text"] == "True", "a right answer is not marked True")
        else:
            need(right["text"] == f"False: it should be {q['answer_text']}", "a wrong answer is not corrected to the answer")
            tru = [o for o in ch if o["text"] == "True"]
            need(len(tru) == 1 and tru[0]["ref"] == claimed[0]["ref"], "agreeing with the wrong answer doesn't log its misconception")
        for o in ch:
            if o["correct"] or o["text"] == "True":
                continue
            need(o["text"].startswith("False: it should be ") and o["text"][20:] in wrong_texts and o["text"][20:] != claim,
                 f"option {o['text']!r} doesn't correct to another wrong option")
    elif fmt == "method-pick":
        view_angle = q["view"]["angle"]
        need(view_angle != "any", "method-pick without a method")
        failing = {a["name"] for a in t["angles"] if a.get("weak", {}).get("kind") == "fails" and u in a["weak"]["unknowns"]}
        works = {a["name"] for a in t["angles"] if u in a["suits"]} - failing
        need(right["text"] not in failing, f"the right method {right['text']!r} fails for {u}")
        name = next(a["name"] for a in t["angles"] if a["method"] == view_angle and u in a["suits"])
        need(right["text"] == name, f"the right method is {right['text']!r}, not the view's {name!r}")
        need("Which method works for this question?" in q["prompt"] and "Method:" not in q["prompt"], "the prompt gives the method away")
        for o in ch:
            if not o["correct"]:
                need(o["text"] not in works, f"{o['text']!r} works for {u} but is marked wrong")
    elif fmt == "error-spot":
        spot = q["spot"]
        need([o["text"] for o in ch] == [f"Line {i + 1}" for i in range(4)], "the options are not Line 1 to Line 4")
        need(ch[spot["bad"]]["correct"], "the right option is not the first wrong line")
        need(spot["ref"] in ext_misconception_refs(t["id"], "error-spot"), f"{spot['ref']} is not an error-spot of {t['id']}")
        need(q["lines"][-5:] == ["A student's working:"] + [f"Line {i + 1}: {l}" for i, l in enumerate(spot["lines"])], "the working shown is not the spot's")
        sit = q["situation_id"]
        need(sit in SPOT_CHECKS, f"the checker has no error-spot checks for {sit}")
        first = SPOT_CHECKS[sit](q, spot["lines"])
        need(first == spot["bad"], f"the first wrong line is {first + 1 if first is not None else 'none'}, not {spot['bad'] + 1}")


def first_false(lines, letters=()):
    for i, line in enumerate(lines):
        if not eq_true(line, letters):
            return i
    return None


# ── fn-pre-expand ──

EXP_LIMIT = 9


def check_expand(q):
    g, ans, u, L = q["given"], q["answer"], q["view"]["unknown"], q["lines"]
    T = "fn-pre-expand"
    if u == "missing-term":
        b = R(g["b"])
        need(L[0] == f"(x + r)² = {qr_poly([1, b])} + c", "the identity shown is not the givens")
        r = b / 2
        need(r.q == 1 and r != 0 and abs(r) <= EXP_LIMIT, "r is not a small whole number")
        qr_check_common(q, qr_norm(ans, {"v0": str(r), "v1": str(r**2)}))
        return None, None
    k, r, s_, d = (R(g[n]) for n in ["k", "r", "s", "d"])
    for n, v in (("k", k), ("r", r), ("s", s_)):
        need(v != 0 and abs(v) <= EXP_LIMIT and v.q == 1, f"{n} = {v} is not a small whole number")
    form = g["form"]
    e = {"single": k * X * (X + r), "double": (X + r) * (X + s_), "square": (X + r)**2,
         "scaled": k * (X + r) * (X + s_), "vertex": k * (X + r)**2 + d}[form]
    need(parse(L[0]) == sp.expand(e), f"the expression shown {L[0]!r} is not the givens")
    if form in ("double", "scaled"):
        need(r != s_ and r + s_ != 0, "the brackets have no middle term")
    full = poly_coeffs(e)
    want = qr_norm(ans, ext_poly_values(ans, full))
    def shape(c):
        return qr_norm(ans, ext_poly_values(ans, {p: v for p, v in c.items() if v != 0} | {p: 0 for p in full if p not in c}))
    wr = {}
    if form == "double":
        wr[f"{T}#2"] = {shape({2: 1, 1: -(r + s_), 0: r * s_})}
    if form == "square":
        wr[f"{T}#0"] = {shape({2: 1, 1: 0, 0: r**2})}
    if form == "scaled":
        wr[f"{T}#1"] = {shape({2: k, 1: r + s_, 0: r * s_})}
    if form == "vertex":
        wr[f"{T}#0"] = {shape({2: k, 1: 0, 0: k * r**2 + d})}
        wr[f"{T}#3"] = {shape({2: k, 1: 2 * k * r, 0: k * (r**2 + d)})}
    if q["view"]["rep"] == "graph":
        t = q["table"]["rows"]
        sgn = lambda v: ("+" if v > 0 else "−") + frac_text(abs(v))
        other = r if form == "square" else s_
        need(t == [["×", ["x", sgn(other)]], ["x", ["?", "?"]], [sgn(r), ["?", "?"]]], "the area grid's edges are not the brackets")
    qr_check_common(q, want, wr)
    return None, None


def spot_expand(q, lines):
    return first_false(lines)


SPOT_CHECKS["fn-pre-expand"] = spot_expand


# ── fn-pre-factorise ──

def check_factorise(q):
    g, ans, u, L = q["given"], q["answer"], q["view"]["unknown"], q["lines"]
    T = "fn-pre-factorise"
    if u == "factor-pair":
        P, S = R(g["P"]), R(g["S"])
        need(L[0] == f"Two numbers have product {frac_text(P)} and sum {frac_text(S)}.", "the product and sum shown are not the givens")
        m, n = sorted(sp.solve(X**2 - S * X + P, X))
        need(m.is_integer and n.is_integer and m != n and m != 0 and n != 0, "the two numbers are not different nonzero whole numbers")
        qr_check_common(q, qr_norm(ans, {"r1": str(m), "r2": str(n)}))
        return None, None
    A, B, C = R(g["A"]), R(g["B"]), R(g["C"])
    f = A * X**2 + B * X + C
    if u == "missing-bracket-term":
        r = R(g["r"])
        need(L[0] == f"{ext_bracket(r)}(x + □) = {qr_poly([A, B, C])}", "the identity shown is not the givens")
        S_ = sp.Symbol("S")
        sol = sp.solve(sp.Poly(sp.expand((X + r) * (X + S_) - f), X).coeffs(), S_, dict=True)
        need(len(sol) == 1 and sol[0][S_].is_integer, "no whole number fills the bracket")
        need(ans.get("exact"), "a missing whole number must be marked exactly")
        qr_check_common(q, qr_norm(ans, {"v": str(sol[0][S_])}))
        return None, None
    need(parse(L[0]) == sp.expand(f), f"the expression shown {L[0]!r} is not the givens")
    need(all(c.q == 1 and abs(c) <= 81 for c in (A, B, C)), "coefficients are not small whole numbers")
    wr = {}
    if u == "difference-of-squares":
        need(B == 0 and sp.sqrt(A).is_integer and sp.sqrt(abs(C)).is_integer, "not p²x² ± q²")
        p_, q_ = sp.sqrt(A), sp.sqrt(abs(C))
        if C > 0:
            need(len(sp.factor_list(f)[1]) == 1, "a sum of squares that factorises")
            fake = f"({qr_lead(p_)}x + {q_})({qr_lead(p_)}x − {q_})"
            need(ans["kind"] == "choice" and fake in ans["fixed"]["options"], "the sum of squares is not offered as a difference")
            wr[f"{T}#1"] = {qr_norm(ans, {"v": fake})}
            qr_check_common(q, qr_norm(ans, {"v": "It does not factorise"}), wr)
            return None, None
    if u == "common-factor":
        need(C == 0 and A > 0, "not kx² + mx")
        gg = sp.gcd(A, B)
        a_, b_ = A / gg, B / gg
        need(gg >= 2, "the highest common factor is only x")
        wr[f"{T}#2"] = {qr_norm(ans, {"g": str(gg), "a": str(a_), "b": str(B)})}
        qr_check_common(q, qr_norm(ans, {"g": str(gg), "a": str(a_), "b": str(b_)}), wr)
        return None, None
    # The factors, by SymPy: each linear factor written with a positive x term.
    content, fs = sp.factor_list(f)
    lin = []
    for fac, mult in fs:
        need(sp.degree(fac, X) == 1, f"{f} has a factor {fac} that is not linear")
        a1, b1 = sp.Poly(fac, X).all_coeffs()
        if a1 < 0:
            a1, b1, content = -a1, -b1, -content
        lin += [(a1, b1)] * mult
    need(content == 1 and len(lin) == 2, f"{f} is not the product of two primitive brackets")
    if q.get("table"):
        lead = "x" if A == 1 else "?x"
        need(q["table"]["rows"] == [["×", [lead, "?"]], [lead, [ext_terms([A], [2]), "?"]], ["?", ["?", frac_text(C)]]],
             "the area grid's corners are not the expression's")
        need(L[1] == f"The area grid's total is {qr_poly([A, B, C])}: its two empty cells add to {ext_terms([B], [1])}.", "the grid's line is wrong")
    if u == "monic-trinomial":
        need(A == 1, "not monic")
        (_, r), (_, s_) = lin
        wr[f"{T}#0"] = {qr_norm(ans, {"r": str(-r), "s": str(-s_)})}
        qr_check_common(q, qr_norm(ans, {"r": str(r), "s": str(s_)}), wr)
        return None, None
    (a1, b1), (a2, b2) = lin
    if u == "non-monic":
        need(A >= 2, "a is not more than 1")
        # The pair of c only, in brackets with x: (x + b1)(x + b2).
        wr[f"{T}#3"] = {qr_norm(ans, {"a1": "1", "b1": str(b1), "a2": "1", "b2": str(b2)})}
    qr_check_common(q, qr_norm(ans, {"a1": str(a1), "b1": str(b1), "a2": str(a2), "b2": str(b2)}), wr)
    return None, None


def spot_factorise(q, lines):
    """The first wrong line of a working for ax² + bx + c (fn-pre-factorise#3)."""
    g = q["given"]
    A, B, C = R(g["A"]), R(g["B"]), R(g["C"])
    e = qr_poly([A, B, C])
    for i, line in enumerate(lines):
        if line == f"{e} has a = {frac_text(A)}, b = {frac_text(B)} and c = {frac_text(C)}":
            continue
        if line == f"We need two numbers that add to {frac_text(B)}":
            continue
        m = re.fullmatch(r"Two numbers that multiply to (\S+): (\S+) and (\S+)", line)
        if m:
            if RD(m.group(1)) == A * C and RD(m.group(2)) * RD(m.group(3)) == A * C:
                continue
            return i
        line = line.removeprefix("So ").removeprefix("Check: ")
        m = re.fullmatch(r"The roots are x = (\S+) and x = (\S+)", line)
        if m:
            if {RD(m.group(1)), RD(m.group(2))} == set(sp.solve(A * X**2 + B * X + C, X)):
                continue
            return i
        if not eq_true(line):
            return i
    return None


SPOT_CHECKS["fn-pre-factorise"] = spot_factorise


# ── fn-pre-surds ──

def surd_parts(e):
    """A positive surd m√r (r square-free) as (m, r)."""
    e = sp.nsimplify(e)
    m, rest = e.as_coeff_Mul()
    r = rest**2
    need(m.is_rational and r.is_integer and r >= 1, f"{e} is not m√r")
    return sp.Rational(m), int(r)


def surd_expr(text):
    """A surd expression as the game writes it: '√(4 × 24)', '√4 × √24', '(2√24)²', '4√6'."""
    t = text.replace("−", "-").replace("×", "*").replace("²", "**2")
    t = re.sub(r"(\d)√", r"\1*√", t)
    t = re.sub(r"√(\d+)", r"sqrt(\1)", t).replace("√(", "sqrt(")
    return sp.nsimplify(sp.sympify(t))


def check_surds(q):
    g, ans, u, L = q["given"], q["answer"], q["view"]["unknown"], q["lines"]
    T = "fn-pre-surds"
    wr = {}
    def sv(e):
        m, r = surd_parts(e)
        return qr_norm(ans, {"m": str(m), "r": str(r)})
    if u == "simplify-root":
        n = R(g["n"])
        need(L[0] == f"√{n}" and n <= 300, "the root shown is not the givens")
        m, r = surd_parts(sp.sqrt(n))
        need(m.q == 1 and m > 1 and not sp.isprime(m), "the square factor's root is not a composite whole number")
        f = sp.divisors(m)[1]
        wr[f"{T}#2"] = {qr_norm(ans, {"m": str(f), "r": str(n / f**2)})}
        qr_check_common(q, sv(sp.sqrt(n)), wr)
    elif u == "add-like-surds":
        n1, n2 = R(g["n1"]), R(g["n2"])
        need(L[0] == f"√{n1} + √{n2}", "the sum shown is not the givens")
        need(surd_parts(sp.sqrt(n1))[1] == surd_parts(sp.sqrt(n2))[1] and n1 != n2, "not two different multiples of one surd")
        wr[f"{T}#0"] = {sv(sp.sqrt(n1 + n2))}
        qr_check_common(q, sv(sp.sqrt(n1) + sp.sqrt(n2)), wr)
    elif u == "multiply-surds":
        m_, n_ = R(g["m"]), R(g["n"])
        need(L[0] == f"√{m_} × √{n_}", "the product shown is not the givens")
        need(not sp.sqrt(m_).is_integer and not sp.sqrt(n_).is_integer, "one of the roots is a whole number")
        qr_check_common(q, sv(sp.sqrt(m_) * sp.sqrt(n_)))
    elif u == "formula-fraction":
        m0, n, d = R(g["m0"]), R(g["n"]), R(g["d"])
        need(L[0] == f"({frac_text(m0)} ± √{n})/{d}", "the fraction shown is not the givens")
        h = m0 / d
        m, r = surd_parts(sp.sqrt(n) / d)
        need(h.q == 1 and m.q == 1, "the fraction doesn't simplify to whole numbers")
        wr[f"{T}#1"] = {qr_norm(ans, {"h": str(m0), "m": str(m), "r": str(r)})}
        qr_check_common(q, qr_norm(ans, {"h": str(h), "m": str(m), "r": str(r)}), wr)
    elif u == "surd-to-root":
        a, b = R(g["a"]), R(g["b"])
        need(L[0] == qr_surd(a, b) and surd_parts(a * sp.sqrt(b)) == (a, b), "the surd shown is not in simplest form")
        need(ans.get("exact"), "the whole number under the root must be marked exactly")
        qr_check_common(q, qr_norm(ans, {"v": str(a**2 * b)}))
    else:
        raise Fail(f"the checker has no solver for {u}")
    # Every option is a different value or a different form: none may equal the answer
    # in simplest form unless it is the answer.
    return None, None


def spot_surds(q, lines):
    """The first wrong line of a working for √n (fn-pre-surds#2)."""
    for i, line in enumerate(lines):
        m = re.fullmatch(r"(\d+) has no square factor(?:, so (\S+) is simplest)?", line)
        if m:
            if sp.factorint(int(m.group(1))) and max(sp.factorint(int(m.group(1))).values()) >= 2:
                return i
            continue
        m = re.fullmatch(r"So √(\d+) in simplest form is (\S+)", line)
        if m:
            mm, r = surd_parts(sp.sqrt(int(m.group(1))))
            if m.group(2) != qr_surd(mm, r):
                return i
            continue
        line = line.removeprefix("So ").removeprefix("Check: ")
        sides = [p.strip() for p in line.split(" = ")]
        vals = [surd_expr(p) for p in sides]
        if any(sp.simplify(vals[0] - w) != 0 for w in vals[1:]):
            return i
    return None


SPOT_CHECKS["fn-pre-surds"] = spot_surds


# ── fn-pre-linear-inequalities ──

LI_REL = {"<": lambda l, r: l < r, "≤": lambda l, r: l <= r, ">": lambda l, r: l > r, "≥": lambda l, r: l >= r}
LI_WORDS = {"<": "is less than", "≤": "is at most", ">": "is more than", "≥": "is at least"}
LI_FLIP = {"<": ">", ">": "<", "≤": "≥", "≥": "≤"}


@lru_cache(maxsize=None)
def li_set(cond):
    return sp.solve_univariate_inequality(cond, X, relational=False)


def ineq_set(text):
    """'−3 < 2x + 1 ≤ 9', 'x ≥ −10 and x < −1' or '5x > 20' as the set of x it holds for."""
    if " and " in text:
        out = sp.S.Reals
        for part in text.split(" and "):
            out = out.intersect(ineq_set(part))
        return out
    parts = re.split(r" (<|≤|>|≥) ", text)
    need(len(parts) in (3, 5), f"can't read the inequality {text!r}")
    vals = [parse(p) for p in parts[0::2]]
    out = sp.S.Reals
    for i, rel in enumerate(parts[1::2]):
        out = out.intersect(li_set(LI_REL[rel](vals[i], vals[i + 1])))
    return out


def li_range2(S):
    """A bounded interval as range2 values (lo, r1, r2, hi)."""
    need(isinstance(S, sp.Interval) and S.start.is_finite and S.end.is_finite, f"{S} is not a bounded interval")
    return (S.start, "<" if S.left_open else "≤", "<" if S.right_open else "≤", S.end)


def li_words_one(a, b, rel, c):
    if a > 0:
        return f"{frac_text(a)} times a number x, {'plus' if b > 0 else 'minus'} {frac_text(abs(b))}, {LI_WORDS[rel]} {frac_text(c)}."
    return f"{frac_text(b)} minus {frac_text(abs(a))} times a number x {LI_WORDS[rel]} {frac_text(c)}."


def check_lineq(q):
    g, ans, u, L, rep = q["given"], q["answer"], q["view"]["unknown"], q["lines"], q["view"]["rep"]
    T = "fn-pre-linear-inequalities"
    wr = {}
    if u == "read-number-line":
        gr = q["graph"]
        need(gr["kind"] == "numberline", "the graph is not a number line")
        seg, marks = gr["segment"], gr["marks"]
        lo = sp.nsimplify(seg["from"]) if seg["from"] is not None else -sp.oo
        hi = sp.nsimplify(seg["to"]) if seg["to"] is not None else sp.oo
        opens = {sp.nsimplify(m["at"]): m["open"] for m in marks}
        need(set(opens) == {v for v in (lo, hi) if v.is_finite}, "a circle is not at an end of the shading")
        S = sp.Interval(lo, hi, opens.get(lo, True), opens.get(hi, True))
        swapped = sp.Interval(lo, hi, not opens.get(lo, False) if lo.is_finite else True, not opens.get(hi, False) if hi.is_finite else True)
        if ans["kind"] == "bound":
            wr[f"{T}#1"] = {swapped}
            qr_check_common(q, S, wr)
        else:
            wr[f"{T}#1"] = {li_range2(swapped)}
            qr_check_common(q, li_range2(S), wr)
        return None, None
    a, b = R(g["a"]), R(g["b"])
    need(a.q == 1 and abs(a) >= 2 and abs(a) <= 5 and b != 0 and b.q == 1, "a or b is out of its limits")
    e = a * X + b
    if u == "one-sided":
        rel, c = g["rel"], R(g["c"])
        if rep == "words":
            need(L[0] == li_words_one(a, b, rel, c), "the words are not the givens")
        else:
            need(ineq_set(L[0]) == li_set(LI_REL[rel](e, c)) and L[0] == f"{qr_poly([a, b])} {rel} {frac_text(c)}", "the inequality shown is not the givens")
        S = li_set(LI_REL[rel](e, c))
        if a < 0:
            wr[f"{T}#0"] = {li_set(LI_REL[rel](X, (c - b) / a))}
        qr_check_common(q, S, wr)
        return None, None
    c1, c2, rel1, rel2 = R(g["c1"]), R(g["c2"]), g["rel1"], g["rel2"]
    S = li_set(LI_REL[rel1](c1, e)).intersect(li_set(LI_REL[rel2](e, c2)))
    shown = f"{frac_text(c1)} {rel1} {qr_poly([a, b])} {rel2} {frac_text(c2)}"
    if rep == "words":
        lhs = qr_poly([a, b]) if a > 0 else f"{frac_text(b)} − {qr_lead(abs(a))}x"
        need(L[0] == f"{lhs} {LI_WORDS[LI_FLIP[rel1]]} {frac_text(c1)} and {LI_WORDS[rel2]} {frac_text(c2)}.", "the words are not the givens")
    else:
        need(L[0] == shown, "the inequality shown is not the givens")
    if u == "count-integers":
        need(S.is_finite_set is False and S.measure.is_finite, "the solution is not a bounded interval")
        n = sum(1 for k in range(int(sp.floor(S.start)) - 1, int(sp.ceiling(S.end)) + 2) if sp.Integer(k) in S)
        need(2 <= n <= 12, f"{n} whole numbers")
        need(not (S.start.is_integer and S.end.is_integer), "both ends are whole numbers")
        need(ans.get("exact"), "a count must be marked exactly")
        qr_check_common(q, qr_norm(ans, {"v": str(n)}))
        return None, None
    # two-sided
    if a < 0:
        wr[f"{T}#0"] = {((c1 - b) / a, rel1, rel2, (c2 - b) / a)}
    wr[f"{T}#2"] = {li_range2(li_set(LI_REL[rel1](c1, a * X)).intersect(li_set(LI_REL[rel2](a * X, c2))))}
    qr_check_common(q, li_range2(S), wr)
    return None, None


def spot_lineq(q, lines):
    """The first line of a working whose inequality has another solution than the question's."""
    g = q["given"]
    a, b = R(g["a"]), R(g["b"])
    S = li_set(LI_REL[g["rel1"]](R(g["c1"]), a * X + b)).intersect(li_set(LI_REL[g["rel2"]](a * X + b, R(g["c2"]))))
    for i, line in enumerate(lines):
        need(": " in line, f"can't read {line!r}")
        if ineq_set(line.rsplit(": ", 1)[1]) != S:
            return i
    return None


SPOT_CHECKS["fn-pre-linear-inequalities"] = spot_lineq


# ── quadratic-model (fn-ext-quadratic-model) ──

QM_A = {"ball": {sp.Integer(-5), sp.Integer(-4), sp.Rational(-49, 10)}, "pen": {sp.Integer(-2), sp.Integer(-1)}}


def qm_expr(text):
    """'−4.9t² + 19.6t + 1.6' (in t or x) as a polynomial in x."""
    return sp.nsimplify(parse(text.replace("t", "x")), rational=True)


def check_qmodel(q):
    g, ans, u, L, rep = q["given"], q["answer"], q["view"]["unknown"], q["lines"], q["view"]["rep"]
    T_ = "SL2.6.model"
    ctx = g["ctx"]
    a, b, c = R(g["a"]), R(g["b"]), R(g["c"])
    f = a * X**2 + b * X + c
    need(a in QM_A[ctx], f"a = {a} is not a clean {ctx} model")
    # Paper 2 is a ball with a = −4.9 (FAL-419); a pen or a table is Paper 1.
    need(q["paper"] == (2 if a == sp.Rational(-49, 10) else 1), f"a = {a} on Paper {q['paper']}")
    need(q["paper"] == 1 or (ctx == "ball" and rep != "table"), "a pen or a table on Paper 2")
    name = "h(t)" if ctx == "ball" else "A(x)"
    tv, hv = vertex(f)
    need(sp.expand(R(g["a"]) * (X - R(g["T"]))**2 + R(g["H"]) - f) == 0, "the vertex form doesn't match the model")
    need(tv > 0 and hv > 0, "the top is not after the start and above the ground")
    if ctx == "pen":
        Lf = R(g["L"])
        want_f = X * (Lf - 2 * X) if g["wall"] else X * (Lf / 2 - X)
        need(sp.expand(want_f - f) == 0, "the pen's model doesn't come from its fence")
        need(f"{frac_text(Lf)} m of fence" in L[0], "the fence length shown is not the givens")
    else:
        need(L[0].startswith("A ball is thrown upwards") or u == "model-from-features" or rep == "words", "the context is not a thrown ball")
        need(c >= 0, "the ball starts below the ground")
    model_lines = [l for l in L if l.startswith(f"{name} = ") or l.startswith(f"The graph of y = {name} = ")]
    for l in model_lines:
        rhs_ = l.split(f"{name} = ", 1)[1].removesuffix(" is shown.").split(". ")[0].rstrip(".")
        if "(" in rhs_ and u == "interpret-vertex":
            need(qm_expr(rhs_) == sp.expand(f), "the vertex form shown is not the model")
        else:
            need(qm_expr(rhs_) == sp.expand(f), f"the model shown {rhs_!r} is not the givens")
    if q.get("graph"):
        gr = q["graph"]
        need(sp.nsimplify(gr["a"]) == a and sp.nsimplify(gr["h"]) == tv and sp.nsimplify(gr["k"]) == hv, "the graph is another curve")
        for pt in gr["points"]:
            need(f.subs(X, sp.nsimplify(pt["x"])) == sp.nsimplify(pt["y"]), f"the marked point {pt['label']} is not on the curve")
    if q.get("table"):
        t = q["table"]
        need(all(f.subs(X, R(x)) == R(y) for x, y in zip(t["xs"], t["ys"])), "a table value is not on the curve")
    wr = {}
    if u == "max-value":
        wr[f"{T_}#0"] = {qr_norm(ans, {"v": str(tv)})}
        qr_check_common(q, qr_norm(ans, {"v": str(hv)}), wr)
    elif u == "time-of-max":
        wr[f"{T_}#0"] = {qr_norm(ans, {"v": str(hv)})}
        qr_check_common(q, qr_norm(ans, {"v": str(tv)}), wr)
    elif u == "zero-time":
        rs = sorted(sp.solve(f, X), key=float)
        need(len(rs) == 2 and rs[0] < 0 < rs[1], "the model has no negative root to reject")
        sf = ans.get("show") == "sf"
        need(sf == (a == sp.Rational(-49, 10)), "Paper 2 is not written to 3 s.f.")
        if not sf:
            need(rs[1].is_rational, "a Paper 1 landing time is not exact")
        else:
            need(not on_edge(rs[1]), "the landing time is on a rounding edge")
        val = lambda r: {"v": str(r) if r.is_rational else str(sp.Rational(round(float(r) * 10**9), 10**9))}
        wr[f"{T_}#1"] = {qr_norm(ans, val(rs[0]))}
        qr_check_common(q, qr_norm(ans, val(rs[1])), wr)
    elif u == "form-area-model":
        need(ctx == "pen", "not a pen")
        qr_check_common(q, qr_norm(ans, {"v0": str(tv), "v1": str(hv)}))
    elif u == "interpret-vertex":
        T, H = dec_text(tv), dec_text(hv)
        right = f"The ball is highest, {H} m, after {T} s" if ctx == "ball" else f"The area is largest, {H} m², when the width is {T} m"
        swap = f"The ball is highest, {T} m, after {H} s" if ctx == "ball" else f"The area is largest, {T} m², when the width is {H} m"
        if rep == "words":
            need(f"has its vertex at ({T}, {H})." in L[1], "the vertex said is not the model's")
        wr[f"{T_}#0"] = {qr_norm(ans, {"v": swap})}
        qr_check_common(q, qr_norm(ans, {"v": right}), wr)
    elif u == "second-time-at-height":
        t1 = R(g["t1"])
        need(0 < t1 < tv, "the first time is not before the top")
        y1 = f.subs(X, t1)
        said = f"{dec_text(y1)} m high at t = {dec_text(t1)} s."
        need(any(said in l for l in L), "the height and time said are not on the model")
        if rep == "words":
            need(f"is highest after {dec_text(tv)} s" in L[0], "the top said is not the model's")
        other = [r for r in sp.solve(f - y1, X) if r != t1]
        need(len(other) == 1, "no other time at that height")
        qr_check_common(q, qr_norm(ans, {"v": str(other[0])}))
    elif u == "model-from-features":
        m = re.fullmatch(r"A ball is thrown upwards from (\S+) m\. It is highest, (\S+) m, after (\S+) s\.", L[0])
        need(m is not None, "can't read the features")
        h0, H, T = (RD(x) for x in m.groups())
        A_ = sp.Symbol("A")
        sol = sp.solve(sp.Eq(A_ * T**2 + H, h0), A_)
        model = sp.expand(sol[0] * (X - T)**2 + H)
        co = poly_coeffs(model)
        qr_check_common(q, qr_norm(ans, ext_poly_values(ans, co)))
    else:
        raise Fail(f"the checker has no solver for {u}")
    return None, None


# ── fn-link-equivalent-forms ──

EF_PAIRS = {
    "log-sub": lambda m, n: (sp.log(m * n) - sp.log(n), sp.log(m)),
    "log-div": lambda m, n: (sp.log(m * n) / sp.log(n), sp.log(m)),
    "log-pow": lambda m, n: (2 * sp.log(m), sp.log(m * m)),
    "log-add": lambda m, n: (sp.log(m) + sp.log(n), sp.log(m + n)),
    "sq-sum": lambda m, n: ((X + m)**2, X**2 + m * m),
    "dos": lambda m, n: ((X + m) * (X - m), X**2 - m * m),
}
EF_CLAIMS = {
    "log(a + b) = log a + log b": lambda a, b: (sp.log(a + b, 10), sp.log(a, 10) + sp.log(b, 10)),
    "(log a)² = 2 log a": lambda a, b: (sp.log(a, 10)**2, 2 * sp.log(a, 10)),
    "log a − log b = log(a/b)": lambda a, b: (sp.log(a, 10) - sp.log(b, 10), sp.log(a / b, 10)),
    "log(a^n) = n log a": lambda a, b: (sp.log(a**3, 10), 3 * sp.log(a, 10)),
    "log(a/b) = log a / log b": lambda a, b: (sp.log(a / b, 10), sp.log(a, 10) / sp.log(b, 10)),
}
TRIG = {"sin": sp.sin, "cos": sp.cos}


@lru_cache(maxsize=None)
def trig_solutions(fn, B, C):
    """The solutions in [0, 2π] of cos 2x + B·fn(x) + C = 0 (cached: the same equation comes up often)."""
    return sp.solveset(sp.cos(2 * X) + B * TRIG[fn](X) + C, X, sp.Interval(0, 2 * sp.pi))


@lru_cache(maxsize=None)
def trig_level(fn, val):
    """The x in [0, 2π] with fn(x) = val."""
    return sp.solveset(TRIG[fn](X) - val, X, sp.Interval(0, 2 * sp.pi))


def ef_same(x, y):
    """Whether two expressions are one object: equal as polynomials, or as numbers."""
    d = sp.simplify(sp.expand_log(x - y, force=True))
    return d == 0 or (d.is_number and abs(sp.N(d, 30)) < 1e-25)


def ef_trig_text(c, fn):
    mag = "" if abs(c) == 1 else frac_text(abs(c)) + " "
    return (" − " if c < 0 else " + ") + mag + fn + " x"


def check_eqforms(q):
    g, ans, u, L, rep = q["given"], q["answer"], q["view"]["unknown"], q["lines"], q["view"]["rep"]
    wr = {}
    if u == "form-for-feature":
        m = re.search(r"f\(x\) = (.+)\.$", L[0])
        need(m is not None, "can't read the three forms")
        forms = m.group(1).split(" = ")
        need(len(forms) == 3, "not three forms")
        fs = [parse(f) for f in forms]
        need(fs[0] == fs[1] == fs[2], "the three forms are not one quadratic")
        f = fs[0]
        a, b, c = coeffs(f)
        need(forms[0] == qr_poly([a, b, c]), "the first form is not the general form")
        rs = real_roots(f)
        hv, kv = vertex(f)
        need(all(r.is_integer for r in rs) and hv != 0, "the roots are not whole numbers, or the vertex is on the y-axis")
        if q.get("graph"):
            gr = q["graph"]
            need(sp.nsimplify(gr["a"]) == a and sp.nsimplify(gr["h"]) == hv and sp.nsimplify(gr["k"]) == kv, "the graph is another parabola")
        feat = lambda cc, r1, r2, h, k: qr_norm(ans, {"c": str(cc), "r1": str(r1), "r2": str(r2), "h": str(h), "k": str(k)})
        wr["SL2.6.complete-square#1"] = {feat(c, rs[0], rs[1], hv, c - hv**2)}
        wr["SL2.6.factorised-form#0"] = {feat(c, -rs[0], -rs[1], hv, kv)}
        wr["SL2.6.factorised-form#2"] = {feat(rs[0] * rs[1], rs[0], rs[1], hv, kv)}
        qr_check_common(q, feat(c, rs[0], rs[1], hv, kv), wr)
    elif u == "identity-constants":
        m = re.fullmatch(r"(.+) ≡ \(x \+ p\)² \+ q", L[0])
        need(m is not None, "can't read the identity")
        P_, Q_ = sp.symbols("P Q")
        sol = sp.solve(sp.Poly(sp.expand(parse(m.group(1)) - (X + P_)**2 - Q_), X).coeffs(), [P_, Q_], dict=True)
        need(len(sol) == 1, "the identity doesn't fix p and q")
        p_, q_ = sol[0][P_], sol[0][Q_]
        c = parse(m.group(1)).subs(X, 0)
        wr["SL2.6.complete-square#0"] = {qr_norm(ans, {"v0": str(p_), "v1": str(c)})}
        wr["SL2.6.complete-square#2"] = {qr_norm(ans, {"v0": str(-p_), "v1": str(q_)})}
        qr_check_common(q, qr_norm(ans, {"v0": str(p_), "v1": str(q_)}), wr)
    elif u == "same-or-not":
        mm, nn = R(g["m"]), R(g["n"])
        x, y = EF_PAIRS[g["pair"]](mm, nn)
        same = ef_same(x, y)
        right = ans["values"]["v"]
        need(right.startswith("The same: ") == same and (right.startswith("Not the same: ") != same), f"the answer {right!r} gets the verdict wrong")
        for o in ans["fixed"]["options"]:
            if o == "The same: ln a/ln b = ln(a/b)":
                need(g["pair"] == "log-div" and not same, "the log-quotient misconception on another pair")
                wr["SL1.7.log-laws#1"] = {qr_norm(ans, {"v": o})}
            if o == "The same: they agree when x = 0":
                need(not same and sp.expand(x - y).subs(X, 0) == 0, "they don't agree at x = 0, or are the same")
                wr["SL1.6.identity-constants#0"] = {qr_norm(ans, {"v": o})}
        qr_check_common(q, qr_norm(ans, {"v": right}), wr)
    elif u == "log-law-check":
        claim = next((c for c in EF_CLAIMS if c in L[0]), None)
        need(claim is not None, f"can't read the claim in {L[0]!r}")
        sides = EF_CLAIMS[claim](sp.Integer(5), sp.Integer(3))
        true_ = ef_same(*sides)
        right = ans["values"]["v"]
        need(right.startswith("True") == true_ and not right.startswith("True, but"), f"the answer {right!r} gets the claim wrong")
        if "True" in ans["fixed"]["options"]:
            ref = {"log(a + b) = log a + log b": "SL1.7.log-laws#0", "(log a)² = 2 log a": "SL1.7.log-laws#2"}.get(claim)
            if ref:
                wr[ref] = {qr_norm(ans, {"v": "True"})}
        qr_check_common(q, qr_norm(ans, {"v": right}), wr)
    elif u == "cos2x-form":
        fn, B, C = g["fn"], R(g["B"]), R(g["C"])
        need(L[0] == f"cos 2x{ef_trig_text(B, fn)}{'' if C == 0 else (' − ' if C < 0 else ' + ') + frac_text(abs(C))} = 0, for 0 ≤ x ≤ 2π", "the equation shown is not the givens")
        sols = trig_solutions(fn, B, C)
        need(isinstance(sols, sp.FiniteSet) and 2 <= len(sols) <= 4, f"{sols} is not 2 to 4 solutions")
        vals = sorted(sp.nsimplify(s_ / sp.pi) for s_ in sols)
        want = qr_norm(ans, {f"a{i}": str(v_) for i, v_ in enumerate(vals)})
        qr_check_common(q, want, wr)
    elif u == "power-form-first":
        A, m_, B, n_ = R(g["A"]), R(g["m"]), R(g["B"]), R(g["n"])
        f = parse(L[0].removeprefix("f(x) = "))
        need(sp.simplify(f - (A / X**m_ + 1 / (B * X**n_))) == 0, "the function shown is not the givens")
        def pairs(e):
            out = []
            for t in sp.Add.make_args(sp.expand(e)):
                c_, pw = t.as_coeff_exponent(X)
                out.append((int(pw), sp.Rational(c_)))
            return tuple(sorted(out))
        def vals(ts):
            """Two terms (coefficient, power), kept apart even when the powers are equal."""
            ps = sorted((int(pw), sp.Rational(c_)) for c_, pw in ts)
            return qr_norm(ans, {k: str(v_) for i, (pw, c_) in enumerate(ps) for k, v_ in ((f"c{i}", c_), (f"e{i}", pw))})
        d = sp.diff(f, X)
        right = [(-m_ * A, -m_ - 1), (-n_ / B, -n_ - 1)]
        need(pairs(d) == tuple(sorted((int(pw), c_) for c_, pw in right)), "the derivative is not two powers of x")
        # 1/(Bxⁿ) written as Bx⁻ⁿ; the denominator differentiated (A/xᵐ -> A/(m·xᵐ⁻¹));
        # the new power one up instead of one down.
        wr["SL1.5.zero-negative#2"] = {vals([right[0], (-n_ * B, -n_ - 1)])}
        wr["SL5.3.negative-powers#0"] = {vals([(A / m_, -(m_ - 1)), right[1]])}
        wr["SL5.3.negative-powers#1"] = {vals([(-m_ * A, -m_ + 1), right[1]])}
        qr_check_common(q, vals(right), wr)
    elif u == "roots-from-vertex-form":
        f = parse(L[0].removeprefix("f(x) = "))
        a, _, _ = coeffs(f)
        rs = real_roots(f)
        need(all(r.is_integer for r in rs), "the roots are not whole numbers")
        qr_check_common(q, qr_norm(ans, {"a": str(a), "p": str(rs[0]), "q": str(rs[1])}))
    else:
        raise Fail(f"the checker has no solver for {u}")
    return None, None


# ── fn-link-symmetry ──

SY_MIRRORS = {"normal": "For X ~ N(μ, σ²), P(X < μ − a) = P(X > μ + a)", "trig": "sin(π − θ) = sin θ", "ncr": "nCr = nC(n − r)"}
SY_NOT = {"The terms of an arithmetic sequence go up by the same amount each time", "log(ab) = log a + log b",
          "A line has the same gradient between any two of its points", "e^(a + b) = e^a × e^b", "The angles of a triangle add up to π"}
SY_EXACT = {"1/2": sp.Rational(1, 2), "√2/2": sp.sqrt(2) / 2, "√3/2": sp.sqrt(3) / 2}
TH = sp.Symbol("theta")


def sy_parabola(g):
    a, h, k = R(g["a"]), R(g["h"]), R(g["k"])
    need(a in {1, -1, 2, -2, sp.Rational(1, 2)} and h.q == 1 and k.q == 1 and h != 0, "the parabola is out of its limits")
    return sp.expand(a * (X - h)**2 + k)


def check_symmetry(q):
    g, ans, u, L, rep = q["given"], q["answer"], q["view"]["unknown"], q["lines"], q["view"]["rep"]
    wr = {}
    if u == "same-idea":
        topic = g["topic"]
        right = SY_MIRRORS[topic]
        need(set(ans["fixed"]["options"]) - {right} <= SY_NOT, "an option is neither the mirror fact nor a fact without a mirror")
        # The mirror fact really holds.
        if topic == "trig":
            need(sp.simplify(sp.sin(sp.pi - TH) - sp.sin(TH)) == 0, "sin(π − θ) ≠ sin θ")
        elif topic == "ncr":
            need(all(sp.binomial(n, r) == sp.binomial(n, n - r) for n in range(1, 12) for r in range(n + 1)), "nCr ≠ nC(n − r)")
        else:
            Z = sp.Symbol("z")
            need(sp.simplify(sp.erf(-Z) + sp.erf(Z)) == 0, "the normal curve is not symmetric")
        qr_check_common(q, qr_norm(ans, {"v": right}))
    elif u == "mirror-point":
        f = sy_parabola(g)
        h, d, y = R(g["h"]), R(g["d"]), R(g["y"])
        x1 = h - d
        need(f.subs(X, x1) == y, "the point is not on the parabola")
        if rep == "equation":
            m = re.fullmatch(r"The parabola y = (.+) has its axis of symmetry at x = (\S+) and passes through \((\S+), (\S+)\)\.", L[0])
            need(m is not None and parse(m.group(1)) == f and RD(m.group(2)) == vertex(f)[0], "the parabola or its axis shown is not the givens")
            need((RD(m.group(3)), RD(m.group(4))) == (x1, y), "the point shown is not the givens")
        if q.get("table"):
            t = q["table"]
            need(all(f.subs(X, R(x)) == R(yy) for x, yy in zip(t["xs"], t["ys"])), "a table value is not on the parabola")
            need(max(R(x) for x in t["xs"]) == h, "the table doesn't stop at the axis")
        if q.get("graph"):
            gr = q["graph"]
            need(sp.nsimplify(gr["axis"]) == vertex(f)[0], "the axis drawn is not the parabola's")
            need(all(f.subs(X, sp.nsimplify(pt["x"])) == sp.nsimplify(pt["y"]) for pt in gr["points"]), "a marked point is off the curve")
        other = [r for r in sp.solve(f - y, X) if r != x1]
        need(len(other) == 1, "no single matching point")
        pt = lambda x: qr_norm(ans, {"x": str(x), "y": str(y)})
        wr["SL2.4.symmetry#0"] = {pt(-x1)}
        wr["SL2.4.symmetry#1"] = {pt(h), pt(h + 2 * d)}
        qr_check_common(q, pt(other[0]), wr)
    elif u == "find-the-mirror":
        ctx = g.get("ctx", "parabola")
        if ctx == "ncr":
            m = re.fullmatch(r"nC(\d+) = nC(\d+), and \d+ ≠ \d+\.", L[0]) if rep == "words" else None
            r1, r2 = (int(m.group(1)), int(m.group(2))) if m else (int(R(g["r"])), int(R(g["n"]) - R(g["r"])))
            n = R(g["n"])
            need(r1 != r2, "the two r are equal")
            sol = [v_ for v_ in range(max(r1, r2), 30) if sp.binomial(v_, r1) == sp.binomial(v_, r2)]
            need(sol == [n], f"nC{r1} = nC{r2} has n = {sol}, not {n}")
            if q.get("table"):
                need(q["table"]["rows"] == [["r", [str(r1), str(r2)]], ["nCr", [str(sp.binomial(n, r1))] * 2]], "the table is not the row's values")
            if q.get("graph"):
                gr = q["graph"]
                need(gr["kind"] == "bars" and [R(y_) for y_ in gr["ys"]] == [sp.binomial(n, k) for k in range(n + 1)], "the bars are not row n")
            need(ans.get("exact"), "n must be marked exactly")
            qr_check_common(q, qr_norm(ans, {"v": str(n)}))
        elif ctx == "normal":
            m = re.fullmatch(r"X ~ N\(μ, σ²\) and P\(X < (\S+)\) = P\(X > (\S+)\)\.", L[0])
            need(m is not None, "can't read the tails")
            lo, hi = RD(m.group(1)), RD(m.group(2))
            qr_check_common(q, qr_norm(ans, {"v": str((lo + hi) / 2)}))
        else:
            f = sy_parabola(g)
            xa, xb, yv = R(g["xa"]), R(g["xb"]), R(g["yv"])
            need(xa != xb and f.subs(X, xa) == yv == f.subs(X, xb), "the two points are not a pair at one height on the parabola")
            if rep == "words":
                need(L[0] == f"A parabola has y = {frac_text(yv)} at x = {frac_text(xa)} and at x = {frac_text(xb)}.", "the pair said is not the givens")
            if q.get("table"):
                t = q["table"]
                need(all(f.subs(X, R(x)) == R(yy) for x, yy in zip(t["xs"], t["ys"])), "a table value is not on the parabola")
                need(str(xa) in [str(R(x)) for x in t["xs"]] and str(xb) in [str(R(x)) for x in t["xs"]], "the pair is not in the table")
            if q.get("graph"):
                gr = q["graph"]
                need(gr["axis"] is None, "the graph gives the axis away")
                need(all(f.subs(X, sp.nsimplify(pt["x"])) == sp.nsimplify(pt["y"]) for pt in gr["points"]), "a marked point is off the curve")
            h = vertex(f)[0]
            wr["SL2.6.axis-symmetry#1"] = {qr_norm(ans, {"var": "y", "h": str(h)})}
            qr_check_common(q, qr_norm(ans, {"var": "x", "h": str(h)}), wr)
    elif u in ("normal-middle", "normal-other-tail"):
        mu, a, p_ = R(g["mu"]), R(g["a"]), R(g["p"])
        need("σ²" in L[0] and f"N({frac_text(mu)}, σ²)" in L[0], "σ is given, but the tail fixes it")
        need(0 < p_ < sp.Rational(1, 2), "the tail is not less than a half")
        # The mirror: a tail p beyond μ + a means σ = a/z, with Φ(z) = 1 − p.
        z = sp.sqrt(2) * sp.erfinv(1 - 2 * p_)
        sigma = a / z
        Phi = lambda x: (1 + sp.erf((x - mu) / (sigma * sp.sqrt(2)))) / 2
        if q.get("graph"):
            need(abs(float(q["graph"]["sigma"]) - float(sigma)) < 1e-6, "the curve drawn has another σ than the tail fixes")
        if u == "normal-middle":
            need(f"P(X > {frac_text(mu + a)}) = {dec_text(p_)}" in L[0] or f"P(X > {frac_text(mu + a)}), is {dec_text(p_)}" in L[0], "the tail shown is not the givens")
            mid = sp.nsimplify(sp.N(Phi(mu + a) - Phi(mu - a), 30), rational=True, tolerance=1e-20)
            wr["SL4.9.symmetry-probability#0"] = {qr_norm(ans, {"v": str(2 * p_)})}
            qr_check_common(q, qr_norm(ans, {"v": str(mid)}), wr)
        else:
            need(f"P(X < {frac_text(mu - a)}) = {dec_text(p_)}" in L[0] or f"P(X < {frac_text(mu - a)}), is {dec_text(p_)}" in L[0], "the tail shown is not the givens")
            up = sp.nsimplify(sp.N(1 - Phi(mu + a), 30), rational=True, tolerance=1e-20)
            wr["SL4.9.symmetry-probability#1"] = {qr_norm(ans, {"v0": str(p_), "v1": str(p_ + sp.Rational(1, 2))})}
            qr_check_common(q, qr_norm(ans, {"v0": str(up), "v1": str(1 - up)}), wr)
    elif u == "central-interval":
        mu, sigma, qq = R(g["mu"]), R(g["sigma"]), R(g["q"])
        need(L[0] == f"X ~ N({frac_text(mu)}, {frac_text(sigma)}²).", "the distribution shown is not the givens")
        mpmath.mp.dps = 40
        z = sp.Float(str(mpmath.sqrt(2) * mpmath.erfinv(mpmath.mpf(qq.p) / qq.q)), 40)
        lo, hi = mu - z * sigma, mu + z * sigma
        need(lo > 0 and not on_edge(lo) and not on_edge(hi), "an end is negative or on a rounding edge")
        zw = sp.Float(str(mpmath.sqrt(2) * mpmath.erfinv(2 * mpmath.mpf(qq.p) / qq.q - 1)), 40)
        nine = lambda x: str(sp.Rational(round(float(x) * 10**9), 10**9))
        wr["SL4.9.central-interval#0"] = {qr_norm(ans, {"v0": nine(mu - zw * sigma), "v1": nine(mu + zw * sigma)})}
        qr_check_common(q, qr_norm(ans, {"v0": nine(lo), "v1": nine(hi)}), wr)
    elif u == "related-angle":
        fn, th = g["fn"], R(g["theta"])
        val = TRIG[fn](th * sp.pi)
        need(th in {sp.Rational(1, 6), sp.Rational(1, 4), sp.Rational(1, 3)}, "θ is not a special angle")
        m = re.search(r"the line y = (\S+) through", L[0]) if rep == "graph" else re.search(r"= (\S+?)\.?$", L[0])
        need(m is not None and sp.simplify(SY_EXACT[m.group(1)] - val) == 0, "the value shown is not the angle's")
        same = sorted(trig_level(fn, val), key=float)
        opp = sorted(trig_level(fn, -val), key=float)
        need(len(same) == 2 and th * sp.pi in same and len(opp) == 2, "not two angles each way")
        other = [x for x in same if x != th * sp.pi][0] / sp.pi
        o1, o2 = (x / sp.pi for x in opp)
        rel = lambda s_, a_, b_: qr_norm(ans, {"s": str(s_), "o1": str(a_), "o2": str(b_)})
        wr["SL3.5.related-angles#0"] = {rel(o1, other, o2), rel(o2, other, o1)}
        wr["SL3.5.related-angles#1"] = {rel(sp.Rational(1, 2) + th, o1, o2)}
        qr_check_common(q, rel(other, o1, o2), wr)
    elif u == "ncr-mirror":
        n, r = R(g["n"]), R(g["r"])
        m = re.fullmatch(r"(\d+)C(\d+) = (\d+)Cr, with r ≠ (\d+)", L[0])
        need(m is not None and (R(m.group(1)), R(m.group(2))) == (n, r), "the nCr shown is not the givens")
        others = [k for k in range(int(n) + 1) if k != r and sp.binomial(n, k) == sp.binomial(n, r)]
        need(len(others) == 1, "no single other r")
        need(ans.get("exact"), "r and the value must be marked exactly")
        wr["SL1.9.ncr-pascal#0"] = {qr_norm(ans, {"v0": str(others[0]), "v1": str(sp.factorial(n) / sp.factorial(r))})}
        qr_check_common(q, qr_norm(ans, {"v0": str(others[0]), "v1": str(sp.binomial(n, r))}), wr)
    else:
        raise Fail(f"the checker has no solver for {u}")
    return None, None


# ── Exponentials and logs (FAL-418) ──────────────────────────
# Answer kinds the region adds (game/engine/answer.gd): lnq (m·ln r, exact), pct (a
# rise or fall of r%), expmodel (P₀(a)^t) and limited (C, A and k of C + Ae^(−kt)).

EL_KINDS = {"lnq", "pct", "expmodel", "limited", "fn", "logform", "xpow", "range", "yint"}


def el_num(text):
    """A number as the game writes it: 1.05, −455, 7/20."""
    return sp.Rational(text.replace("−", "-"))


def el_lnq_text(m, r):
    m, r = R(m), R(r)
    top = f"ln {frac_text(r)}" if r.q == 1 else f"ln({frac_text(r)})"
    if abs(m.p) != 1:
        top = f"{abs(m.p)} {top}"
    body = top
    if m.q != 1:
        body = (f"({top})" if " " in top and r.q == 1 else top) + f"/{m.q}"
    return ("−" if m < 0 else "") + body


def el_text(ans, v):
    kind, fx, label = ans["kind"], ans.get("fixed") or {}, ans.get("label", "")
    if kind == "lnq":
        if v.get("form") == "sub":
            m = R(v["m"])
            return label + f"ln {frac_text(v['r'])} {'−' if m >= 0 else '+'} {frac_text(abs(m))}"
        if v.get("form") == "dive":
            m = R(v["m"])
            return label + f"{frac_text(v['r'])}/({'' if m == 1 else frac_text(m)}e)"
        return label + el_lnq_text(v["m"], v["r"])
    if kind == "pct":
        pv = dec_text(v["v"]) if ans.get("exact") else sig3(R(v["v"]))
        return f"a {v['dir']} of {pv}% {fx.get('per', '')}".strip()
    if kind == "expmodel":
        return f"{fx.get('sym', 'P')}(t) = {dec_text(v['p0'])}({dec_text(v['a'])})^t"
    if kind == "limited":
        return f"C = {frac_text(v['C'])}, A = {frac_text(v['A'])}, k = {sig3(R(v['k'])).replace('-', '−')}"
    if kind == "fn":
        return fx.get("name", "f(x)") + " = " + el_fn_text(v.get("form", fx.get("shape", "exp")), fx["b"], v.get("p", 0), v["q"])
    if kind == "logform":
        return f"{el_log_name(v['b'])} {frac_text(v['x'])} = {frac_text(v['y'])}"
    if kind == "range":
        return f"{v['var']} {v['rel']} {frac_text(v['k'])}"
    if kind == "yint":
        return f"(0, {frac_text(v['y'])})"
    if kind == "xpow":
        n = R(v["n"])
        if v.get("form") == "lin":
            return fx.get("name", "y") + " = " + qr_lead(n) + "x"
        return fx.get("name", "y") + " = x" + (ext_sup(n) if n.q == 1 and n > 0 else f"^({frac_text(n)})")
    raise Fail(f"the checker can't write answers of kind {kind}")


def el_norm(ans, v):
    kind = ans["kind"]
    if kind == "lnq":
        m, r = R(v["m"]), R(v["r"])
        if r <= 0:
            return None
        if v.get("form") == "sub":
            return round(float(sp.log(r) - m), 9)
        if v.get("form") == "dive":
            return round(float(r / (m * sp.E)), 9)
        return round(float(m * sp.log(r)), 9)
    if kind == "pct":
        return (v["dir"], R(v["v"]) if ans.get("exact") else sig3(R(v["v"])))
    if kind == "expmodel":
        return (R(v["p0"]), R(v["a"]))
    if kind == "limited":
        return (R(v["C"]), R(v["A"]), sig3(R(v["k"])))
    if kind == "fn":
        return (v.get("form", ans["fixed"].get("shape", "exp")), R(v.get("p", 0)), R(v["q"]))
    if kind == "logform":
        return (R(v["b"]), R(v["x"]), R(v["y"]))
    if kind == "xpow":
        return (v.get("form", "pow"), R(v["n"]))
    if kind == "range":
        return (v["var"], v["rel"], R(v["k"]))
    if kind == "yint":
        return R(v["y"])
    raise Fail(f"the checker can't compare answers of kind {kind}")


def el_m(x):
    """A measure's normalised value (as qr_norm writes one): 3 s.f., sign kept."""
    return sig3(x)


# ── exp-model (fn-exponential-model) ──
# The clean limits, the checker's own copy of game/engine/situations/exp_model.gd's.

EM_STARTS = {100, 200, 250, 400, 500, 800, 1000, 1200, 1500, 2000, 2500, 5000}
EM_TABLE_STARTS = {1000, 2000, 4000, 5000}
EM_TABLE_RATES = {10, 20, 25, 30, 50, -10, -20, -40, -50}
EM_T_MAX = 60
EM_MAX_VALUE = 100000
EM_LOG_M = {1, 2, 5, 10, 20}
EM_LOG_X0 = {2, 4, 5, 10, 20, 50}
EM_REL = sp.Rational(1, 10**6)
T_ = sp.Symbol("t")


def em_k(g):
    """The model's rate k, exact (a log for a half-life or a reading)."""
    f = g["form"]
    if f == "half":
        return (1 if g["dir"] == "double" else -1) * sp.log(2) / int(g["T"])
    if f == "data":
        return sp.log(R(g["P1"]) / R(g["A"])) / int(g["t1"])
    if f == "limited" and "t1" in g:
        return -sp.log((R(g["P1"]) - R(g["C"])) / R(g["A"])) / int(g["t1"])
    return R(g["k"])


def em_f(g):
    """The model as an expression in t."""
    f = g["form"]
    if f in ("factor", "shift"):
        return R(g["P0"]) * R(g["a"]) ** (T_ - int(g.get("t0", 0)))
    if f in ("cont", "half", "data"):
        return R(g["A"]) * sp.exp(em_k(g) * T_)
    if f == "limited":
        return R(g["C"]) + R(g["A"]) * sp.exp(-em_k(g) * T_)
    raise Fail(f"no model for form {f}")


def em_time(g, lv):
    """When the model equals lv, exact."""
    f = g["form"]
    if f in ("factor", "shift"):
        return int(g.get("t0", 0)) + sp.log(lv / R(g["P0"])) / sp.log(R(g["a"]))
    if f in ("cont", "half", "data"):
        return sp.log(lv / R(g["A"])) / em_k(g)
    return -sp.log((lv - R(g["C"])) / R(g["A"])) / em_k(g)


def em_growing(g):
    f = g["form"]
    if f in ("factor", "shift", "two"):
        return R(g["a"]) > 1
    if f == "limited":
        return R(g["A"]) < 0
    return num(em_k(g)) > 0


def em_clean(g):
    f = g["form"]
    need(f in {"factor", "shift", "cont", "half", "data", "limited", "log10", "two"}, f"unknown form {f}")
    if f in ("factor", "shift"):
        r, P0 = int(g["r"]), R(g["P0"])
        need(R(g["a"]) == 1 + sp.Rational(r, 100), "a is not 1 + r/100")
        need((P0 in EM_STARTS and (2 <= r <= 25 or -30 <= r <= -3)) or (P0 in EM_TABLE_STARTS and r in EM_TABLE_RATES),
             f"P₀ = {P0}, r = {r}% is not a clean model")
        need(int(g["t0"]) == (0 if f == "factor" else int(g["t0"])) and (f == "factor" or 1 <= int(g["t0"]) <= 5), "t0 out of range")
    elif f == "cont":
        k = R(g["k"])
        need(R(g["A"]) in EM_STARTS and (k * 200).q == 1 and 5 <= abs(k * 200) <= 60, f"k = {k} is not a clean rate")
    elif f == "half":
        need(R(g["A"]) in EM_STARTS and 2 <= int(g["T"]) <= 30 and g["dir"] in ("half", "double"), "not a clean half-life")
    elif f == "data":
        P1, A = R(g["P1"]), R(g["A"])
        need(A in EM_STARTS and 2 <= int(g["t1"]) <= 10 and 0 < P1 != A, "not a clean reading")
    elif f == "limited":
        C, A = R(g["C"]), R(g["A"])
        need(C > 0 and C + A > 0 and A != 0, "the limited model starts at or below zero")
        if "t1" in g:
            frac = (R(g["P1"]) - C) / A
            need(0 < frac < 1, "the reading is not between the start and the long run")
    elif f == "log10":
        m, x0, Rv = R(g["m"]), R(g["x0"]), R(g["R"])
        need(m in EM_LOG_M and x0 in EM_LOG_X0 and sp.Rational(6, 5) <= Rv / m <= sp.Rational(9, 2), "not a clean log model")
    elif f == "two":
        need(R(g["P0"]) < R(g["P0b"]) and R(g["a"]) > R(g["ab"]), "the two models never meet")


def em_model_text(g, k_shown=True):
    """The model as the checker writes it, to find among the lines."""
    s, f = g["ctx"]["sym"], g["form"]
    if f == "factor":
        return f"{s}(t) = {frac_text(g['P0'])}({dec_text(g['a'])})^t"
    if f == "shift":
        return f"{s}(t) = {frac_text(g['P0'])}({dec_text(g['a'])})^(t − {g['t0']})"
    if f == "cont":
        return f"{s}(t) = {frac_text(g['A'])}e^({dec_text(g['k'])}t)"
    if f in ("half", "data"):
        return f"{s}(t) = {frac_text(g['A'])}e^(kt)"
    if f == "limited":
        A = R(g["A"])
        e = f"e^(−{dec_text(g['k'])}t)" if k_shown and "t1" not in g else "e^(−kt)"
        return f"{s}(t) = {frac_text(g['C'])} {'+' if A > 0 else '−'} {frac_text(abs(A))}{e}"
    if f == "log10":
        m = R(g["m"])
        return f"{s} = {'' if m == 1 else frac_text(m) + ' '}log₁₀(x/{frac_text(g['x0'])})"
    raise Fail(f"no model text for {f}")


def em_read(pattern, text, what):
    m = re.search(pattern, text)
    need(m is not None, f"can't read {what} from {text!r}")
    return m


def em_shown(q, g):
    """The model and its extras as the lines show them, read back with regexes and
    compared with the givens. Returns the joined lines."""
    L = " / ".join(q["lines"])
    f = g["form"]
    if f in ("factor", "shift"):
        m = em_read(r"(\w)\(t\) = (\d+)\(([\d.]+)\)(\^t|\^\(t − (\d+)\))", L, "the model")
        need(el_num(m.group(2)) == R(g["P0"]) and el_num(m.group(3)) == R(g["a"]), "the model shown is not the givens")
        need((m.group(5) is None) == (f == "factor") and (f == "factor" or int(m.group(5)) == int(g["t0"])), "the shift shown is not t0")
    elif f == "cont":
        m = em_read(r"(\w)\(t\) = (\d+)e\^\((−?[\d.]+)t\)", L, "the model")
        need(el_num(m.group(2)) == R(g["A"]) and el_num(m.group(3)) == R(g["k"]), "the model shown is not the givens")
    elif f in ("half", "data"):
        m = em_read(r"(\w)\(t\) = (\d+)e\^\(kt\)", L, "the model")
        need(el_num(m.group(2)) == R(g["A"]), "the start shown is not A")
        if f == "half":
            m2 = em_read(r"(?:Its half-life is|It doubles every) (\d+) ", L, "the half-life")
            need(int(m2.group(1)) == int(g["T"]) and ("half-life" in m2.group(0)) == (g["dir"] == "half"), "the half-life shown is not T")
    elif f == "limited":
        m = em_read(r"(\w)\(t\) = (\d+) ([+−]) (\d+)e\^\(−([\d.]+|k)t\)", L, "the model")
        A = el_num(m.group(4)) * (1 if m.group(3) == "+" else -1)
        need(el_num(m.group(2)) == R(g["C"]) and A == R(g["A"]), "the model shown is not the givens")
        need(m.group(5) == "k" or el_num(m.group(5)) == R(g["k"]), "the k shown is not the givens")
    elif f == "log10":
        need(em_model_text(g) in L, "the log model shown is not the givens")
    if f == "data" and q["view"]["rep"] != "table" and q["view"]["unknown"] not in ("initial-from-later",):
        m = em_read(r"(?:\w\((\d+)\) = (\d+)|After (\d+) \w+ it is (\d+)\.)", L, "the reading")
        t1, P1 = (m.group(1), m.group(2)) if m.group(1) else (m.group(3), m.group(4))
        need(int(t1) == int(g["t1"]) and el_num(P1) == R(g["P1"]), "the reading shown is not the givens")
    if f == "shift":
        need(f"The model holds for t ≥ {g['t0']}." in L, "the model's domain is not shown")
    return L


def em_graph(q, g, curves):
    """The curves are sampled from the model(s); every marked point is on one of them."""
    gr = q["graph"]
    need(gr is not None and len(gr["curves"]) == len(curves), "the graph does not show the model")
    for pts, fn in zip(gr["curves"], curves):
        for x, y in pts[::20]:
            need(abs(num(fn.subs(T_, sp.Float(x, 30))) - sp.Float(y, 30)) <= EM_REL * max(1, abs(y)), f"the curve misses ({x}, {y})")
    for p in gr["points"]:
        need(any(abs(num(fn.subs(T_, sp.Float(p["x"], 30))) - sp.Float(p["y"], 30)) <= EM_REL * max(1, abs(p["y"])) for fn in curves),
             f"the marked point {p['label']} is not on the curve")
        need(p["label"] in (f"({frac_text(sp.nsimplify(p['x']))}, {frac_text(sp.nsimplify(p['y']))})", "P", "Q"),
             f"the point's label {p['label']!r} is not its coordinates")
    return gr


def check_exp_model(q):
    g, ans, u, rep = q["given"], q["answer"], q["view"]["unknown"], q["view"]["rep"]
    asked = q["asked"]
    em_clean(g)
    M, CA, LG, FP = "SL2.9.exp-model", "SL2.10.context-apply", "SL1.7.solve-with-logs", "SL2.9.find-parameters"
    wr = {}
    m3 = lambda x: (need(not on_edge(abs(num(x))), f"{u}: {num(x)} is on a rounding edge"), el_m(x))[1]
    if "t2" in g and g["form"] not in ("log10", "two"):
        later = num(em_f(g).subs(T_, int(g["t2"])))
        need(1 <= later <= EM_MAX_VALUE, f"the prediction {later} is not a believable size")
    if u not in ("factor-from-percent", "model-from-table", "model-from-graph", "initial-from-later", "time-from-graph",
                 "two-models-equal"):
        em_shown(q, g)
    if u == "initial-value":
        C, A = R(g["C"]), R(g["A"])
        wr[f"{FP}#0"] = {qr_norm(ans, {"v": str(A)})}
        wr[f"{FP}#1"] = {qr_norm(ans, {"v": str(C)})}
        need(ans.get("exact"), "the start value is not marked exactly")
        want = qr_norm(ans, {"v": str(C + A)})
    elif u == "predict-value":
        t2 = int(em_read(r"Find \w\((\d+)\)", asked, "the time").group(1))
        P0, a, r = R(g["P0"]), R(g["a"]), int(g["r"])
        want = m3(P0 * a**t2)
        wr[f"{M}#1"] = {el_m(P0 * a * t2), el_m(P0 * (1 + sp.Rational(r, 100) * t2))}
        wr[f"{M}#2"] = {el_m(P0 * a ** (t2 - 1))}
        if rep == "graph":
            em_graph(q, g, [em_f(g)])
    elif u == "interpret-factor":
        a = R(g["a"])
        d = "rise" if a > 1 else "fall"
        need(ans.get("exact") and f"the {dec_text(a)} in the model" in asked, "the factor asked is not the model's")
        want = (d, abs(a - 1) * 100)
        wr[f"{M}#0"] = {(d, a * 100)}
    elif u == "long-run-value":
        need(ans.get("exact"), "the long-run value is not marked exactly")
        want = qr_norm(ans, {"v": g["C"]})
        if rep == "graph":
            gr = em_graph(q, g, [em_f(g)])
            need(any(R(sp.nsimplify(h["at"])) == R(g["C"]) for h in gr["hlines"]), "the asymptote is not drawn at C")
    elif u == "k-from-half-life":
        need(ans.get("exact") and "exact" in asked, "an exact k is not asked exactly")
        want = round(float(em_k(g)), 9)
    elif u == "k-from-data-point":
        if rep == "table":
            rows = q["table"]["rows"]
            need(rows[0][1] == ["0", str(g["t1"])] and rows[1][1] == [frac_text(g["A"]), frac_text(g["P1"])], "the table is not the reading")
        want = m3(em_k(g))
    elif u == "predict-from-data-point":
        if rep == "table":
            rows = q["table"]["rows"]
            need(rows[0][1] == ["0", str(g["t1"])] and rows[1][1] == [frac_text(g["A"]), frac_text(g["P1"])], "the table is not the reading")
        t2 = int(em_read(r"Find \w\((\d+)\)", asked, "the time").group(1))
        k = em_k(g)
        want = m3(R(g["A"]) * sp.exp(k * t2))
        k2 = sp.Rational(sig3(k, 2))
        wr[f"{LG}#2"] = {el_m(R(g["A"]) * sp.exp(k2 * t2))}
    elif u in ("time-to-level", "whole-units-inequality"):
        lv = el_num(em_read(r"(?:= |than )(\d+)\.", asked, "the level").group(1))
        need(lv == R(g["L"]), "the level asked is not L")
        t = em_time(g, lv)
        tn = num(t)
        need(int(g.get("t0", 0)) + sp.Rational(1, 2) < tn <= EM_T_MAX, f"t = {tn} is out of range")
        if u == "time-to-level":
            want = m3(t)
            wr[f"{CA}#1"] = {el_m(-t)}
            wr[f"{CA}#2"] = {el_m(lv)}
            if g["form"] == "shift":
                wr[f"{LG}#0"] = {el_m(sp.log(lv / R(g["P0"])) + int(g["t0"]) * sp.log(R(g["a"])))}
        else:
            frac = tn - sp.floor(tn)
            need(sp.Rational(1, 10) <= frac <= sp.Rational(9, 10), "the crossing is too near a whole number")
            need(("more than" in asked) == em_growing(g), "more or less than is the wrong way for the model")
            need(ans.get("exact"), "a whole number of periods is not marked exactly")
            first = int(sp.ceiling(tn))
            want = qr_norm(ans, {"v": str(first)})
            wr[f"{CA}#0"] = {qr_norm(ans, {"v": str(int(sp.floor(tn + sp.Rational(1, 2))))})}
    elif u == "log-model-solve":
        Rv = el_num(em_read(r"when \w = ([\d.]+)\.", asked, "the reading").group(1))
        need(Rv == R(g["R"]), "the reading asked is not R")
        e = Rv / R(g["m"])
        want = m3(R(g["x0"]) * 10**e)
        wr["SL1.5.exp-log-form#1"] = {el_m(R(g["x0"]) * e**10)}
    elif u == "factor-from-percent":
        m = em_read(r"is (\d+) at t = 0, and it (grows|falls) by (\d+)% each (\w+)\.", q["lines"][0], "the start and rate")
        P0, pr = el_num(m.group(1)), sp.Rational(int(m.group(3)), 100)
        a = 1 + pr if m.group(2) == "grows" else 1 - pr
        need((P0, a) == (R(g["P0"]), R(g["a"])), "the words are not the givens")
        need(ans.get("exact"), "the model is not marked exactly")
        want = (P0, a)
        wr[f"{M}#0"] = {(P0, pr)}
    elif u == "model-from-table":
        rows = q["table"]["rows"]
        need(rows[0][1] == ["1", "2", "3", "4"], "the table is not t = 1 to 4")
        vs = [el_num(x) for x in rows[1][1]]
        a = vs[1] / vs[0]
        need(all(vs[i + 1] / vs[i] == a for i in range(3)), "the table has no constant ratio")
        need((vs[0] / a, a) == (R(g["P0"]), R(g["a"])), "the table is not the givens' model")
        want = (vs[0] / a, a)
        wr[f"{M}#2"] = {(vs[0], a)}
    elif u == "model-from-graph":
        gr = em_graph(q, g, [em_f(g)])
        Cs = [R(sp.nsimplify(h["at"])) for h in gr["hlines"]]
        pts = [(R(sp.nsimplify(p["x"])), R(sp.nsimplify(p["y"]))) for p in gr["points"]]
        need(len(Cs) == 1 and len(pts) == 2 and pts[0][0] == 0, "the graph doesn't show the asymptote, the start and a point")
        C, start, (t1, P1) = Cs[0], pts[0][1], pts[1]
        A = start - C
        k = -sp.log((P1 - C) / A) / t1
        need(0.02 <= num(k) <= 0.6, "k is out of range")
        want = (C, A, m3(k))
        kw = -sp.log((P1 - start) / (C - start)) / t1
        wr[f"{FP}#1"] = {(start, C - start, el_m(kw))}
    elif u == "initial-from-later":
        L = " / ".join(q["lines"])
        a = el_num(em_read(r"P₀\(([\d.]+)\)\^t", L, "the factor").group(1))
        m = em_read(r"(?:\w\((\d+)\) = (\d+)|After (\d+) \w+ it is (\d+)\.)", L, "the reading")
        t1, P1 = (int(m.group(1)), el_num(m.group(2))) if m.group(1) else (int(m.group(3)), el_num(m.group(4)))
        need((a, t1, P1) == (R(g["a"]), int(g["t1"]), R(g["P1"])), "the reading shown is not the givens")
        want = m3(P1 / a**t1)
        wr[f"{M}#2"] = {el_m(P1 / a ** (t1 - 1))}
    elif u == "half-life-from-k":
        need(R(g["k"]) < 0, "a half-life of a growing model")
        want = m3(sp.log(2) / abs(R(g["k"])))
    elif u == "time-from-graph":
        gr = em_graph(q, g, [em_f(g)])
        need(f"The graph of {em_model_text(g)} is shown" in q["lines"][0], "the model named is not the givens")
        lv = el_num(em_read(r"when \w\(t\) = (\d+)\.", asked, "the level").group(1))
        need(any(R(sp.nsimplify(h["at"])) == lv for h in gr["hlines"]), "the level is not drawn")
        t = sp.nsimplify(sp.simplify(em_time(g, lv)))
        need(t.is_integer and 0 < t <= 24, f"the level is not reached at a whole number of half-lives (t = {t})")
        need(ans.get("exact"), "a time read off the grid is not marked exactly")
        want = qr_norm(ans, {"v": str(t)})
    elif u == "change-over-period":
        n = int(em_read(r"over (\d+) ", asked, "the period").group(1))
        gf = R(g["a"]) ** n
        want = ("rise" if gf > 1 else "fall", m3(abs(gf - 1) * 100))
    elif u == "two-models-equal":
        L = q["lines"]
        P0, a = [el_num(x) for x in em_read(r"^P\(t\) = (\d+)\(([\d.]+)\)\^t$", L[1], "P").groups()]
        Pb, ab = [el_num(x) for x in em_read(r"^Q\(t\) = (\d+)\(([\d.]+)\)\^t$", L[2], "Q").groups()]
        need((P0, a, Pb, ab) == (R(g["P0"]), R(g["a"]), R(g["P0b"]), R(g["ab"])), "the models shown are not the givens")
        t = sp.log(Pb / P0) / sp.log(a / ab)
        need(2 < num(t) < 40, "the models meet out of range")
        want = m3(t)
        wr[f"{CA}#1"] = {el_m(-t)}
        if rep == "graph":
            em_graph(q, g, [P0 * a**T_, Pb * ab**T_])
    else:
        raise Fail(f"the checker has no solver for {u}")
    qr_check_common(q, want, wr)
    return None, None


# ── exp-log-pair (fn-exp-log-inverse-composite) ──

EL_SUB = str.maketrans("₀₁₂₃₄₅₆₇₈₉", "0123456789")
EL_TO_SUB = str.maketrans("0123456789", "₀₁₂₃₄₅₆₇₈₉")
EL_NOT_DEFINED = "not defined: there is no log of a number that is not positive"
EL_PTS = [sp.Rational(1, 3), sp.Rational(7, 4), sp.Rational(5, 2), 4]


def el_log_name(b):
    return "ln" if str(b) == "e" else "log" + frac_text(b).translate(EL_TO_SUB)


def el_x_minus(p):
    p = R(p)
    return "x" if p == 0 else f"x {'−' if p > 0 else '+'} {frac_text(abs(p))}"


def el_plus_q(q):
    q = R(q)
    return "" if q == 0 else f" {'+' if q > 0 else '−'} {frac_text(abs(q))}"


def el_fn_text(form, b, p, q):
    bb = "e" if str(b) == "e" else frac_text(b)
    xp = el_x_minus(p)
    pw = bb + "^x" if xp == "x" else f"{bb}^({xp})"
    if form == "exp":
        return pw + el_plus_q(q)
    if form == "log":
        return f"{el_log_name(b)}({xp}){el_plus_q(q)}"
    if form == "recip":
        return f"1/({pw}{el_plus_q(q)})" if R(q) != 0 else f"1/{pw}"
    if form == "pow":
        return (f"({xp})" if xp != "x" else "x") + ext_sup(b) + el_plus_q(q)
    if form == "exphalf":
        return bb + "^(x/2)" + el_plus_q(q)
    if form == "pm":
        return ("" if R(q) == 0 else frac_text(q) + " ") + "± " + bb + "^(x/2)"
    raise Fail(f"no fn form {form}")


def el_fn_expr(form, b, p, q):
    """The function an fn answer writes, as a SymPy expression in x."""
    b, p, q = (sp.E if str(b) == "e" else R(b)), R(p), R(q)
    return {"exp": b ** (X - p) + q, "log": sp.log(X - p, b) + q, "recip": 1 / (b ** (X - p) + q),
            "pow": (X - p) ** b + q, "exphalf": b ** (X / 2) + q}[form]


def el_m_text(text):
    return text.replace("-", "−")


def el_parse_shift(xp):
    """'x − 3' -> 3, 'x + 2' -> −2, 'x' -> 0."""
    m = re.fullmatch(r"x(?: ([−+]) (\d+))?", xp)
    need(m is not None, f"can't read the shift in {xp!r}")
    return 0 if m.group(1) is None else (int(m.group(2)) if m.group(1) == "−" else -int(m.group(2)))


def el_parse_q(sign, n):
    return 0 if sign is None else (int(n) if sign == "+" else -int(n))


def el_parse_log(text, name):
    """'g(x) = log₄(x − 5) + 4, for x > 5' -> (b, h, c), with the domain checked."""
    m = re.fullmatch(name + r" = log([₀-₉]+)\((x(?: [−+] \d+)?)\)(?: ([+−]) (\d+))?(?:, for x > (−?\d+))?", text)
    need(m is not None, f"can't read the log function {text!r}")
    b, h, c = int(m.group(1).translate(EL_SUB)), el_parse_shift(m.group(2)), el_parse_q(m.group(3), m.group(4))
    if m.group(5) is not None:
        need(el_num(m.group(5)) == h, "the domain shown is not x > h")
    return b, h, c


def el_parse_exp(text, name="f\\(x\\)"):
    """'f(x) = 4^(x + 1) + 1' or 'f(x) = 2^x' -> (b, h, c)."""
    m = re.fullmatch(name + r" = (\d+)(?:\^x|\^\((x(?: [−+] \d+)?)\))(?: ([+−]) (\d+))?", text)
    need(m is not None, f"can't read the exponential {text!r}")
    return int(m.group(1)), (0 if m.group(2) is None else el_parse_shift(m.group(2))), el_parse_q(m.group(3), m.group(4))


def el_is_inverse(F, f, xs):
    """F(f(x)) = x at each x (numerically, to 30 digits)."""
    for x0 in xs:
        y = f.subs(X, x0)
        back = F.subs(X, y)
        need(abs(sp.N(back - x0, 30)) < sp.Rational(1, 10**20), f"the answer is not the inverse at x = {x0}")


def el_fn_norm(form, p, q):
    return (form, R(p), R(q))


def el_check_log_table(q, b, h, c, hide):
    rows = q["table"]["rows"]
    xs, ys = rows[0][1], rows[1][1]
    need(len(xs) == len(ys) >= 3, "the table is too short")
    for xt, yt in zip(xs, ys):
        n = sp.nsimplify(sp.log(el_num(xt) - h, b))
        need(n.is_integer, f"x = {xt} is not h plus a power of b")
        if yt == "?":
            need(el_num(xt) == hide, "the missing value is not the one asked for")
        else:
            need(el_num(yt) == n + c, f"the table's g({xt}) = {yt} is wrong")


# ── fn-ext-exp-graph (on exp-log-pair) ──

EG_UNKNOWNS = {"y-intercept", "asymptote", "range", "growth-or-decay", "pick-graph", "moves-from-parent",
               "equation-from-graph", "compare-reflections"}


def eg_parse(text):
    """'y = 2 × 3^(x − 1) + 2' or 'y = −2^x + 1' -> (A, b, h, c)."""
    m = re.search(r"y = (?:(−)|\(?(\d+(?:/\d+)?)\)? × )?(\d+)(?:\^x|\^\((x(?: [−+] \d+)?)\))(?: ([+−]) (\d+))?", text)
    need(m is not None, f"can't read the exponential in {text!r}")
    A = -1 if m.group(1) else (R(m.group(2)) if m.group(2) else 1)
    return sp.Rational(A), int(m.group(3)), (0 if m.group(4) is None else el_parse_shift(m.group(4))), el_parse_q(m.group(5), m.group(6))


def check_exp_graph(q):
    ans, u, rep, L, asked = q["answer"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    Lj = " ".join(L)
    wr = {}
    if u in ("growth-or-decay", "compare-reflections", "equation-from-graph"):
        A = b = h = c = None
    else:
        A, b, h, c = eg_parse(asked if u == "pick-graph" else Lj.split("transformed to ")[-1])
        need(b in (2, 3) and A in {1, 2, 3, -1, sp.Rational(1, 2)} and abs(h) <= 2 and abs(c) <= 4, "not a clean exponential")
        f = A * sp.Integer(b) ** (X - h) + c
        if q.get("graph"):
            for x0, y0 in q["graph"]["curves"][0][::16]:
                need(abs(sp.N(f.subs(X, sp.Float(x0, 30))) - y0) <= 1e-6 * max(1, abs(y0)), "the curve is not the function")
    if u == "y-intercept":
        need(h != 0, "h = 0 makes the slip the answer")
        want = qr_norm(ans, {"y": str(f.subs(X, 0))})
        wr["SL2.9.exp-graph#0"] = {qr_norm(ans, {"y": str(A + c)})}
    elif u == "asymptote":
        need(c != 0, "c = 0 makes y = 0 the answer")
        want = qr_norm(ans, {"var": "y", "h": str(sp.limit(f, X, -sp.oo))})
        wr["SL2.9.exp-graph#1"] = {qr_norm(ans, {"var": "y", "h": "0"})}
    elif u == "range":
        lim = sp.limit(f, X, -sp.oo)
        rng_ = sp.calculus.util.function_range(f, X, sp.S.Reals)
        need(rng_ in (sp.Interval.open(lim, sp.oo), sp.Interval.open(-sp.oo, lim)), f"the range {rng_} is not one side of the asymptote")
        want = qr_norm(ans, {"rel": ">" if rng_.sup == sp.oo else "<", "v": str(lim)})
        wr["SL2.2.range#1"] = {qr_norm(ans, {"rel": "≥" if rng_.sup == sp.oo else "≤", "v": str(lim)})}
    elif u == "growth-or-decay":
        if rep == "table":
            ys = [el_num(y) for y in q["table"]["rows"][1][1]]
            up = ys[1] > ys[0]
            need(all(ys[i + 1] / ys[i] == ys[1] / ys[0] for i in range(3)), "the table is not exponential")
        elif rep == "graph":
            pts = q["graph"]["curves"][0]
            up = pts[-1][1] > pts[0][1]
        else:
            m = em_read(r"^y = (\d+)(\^x|\^\(−x\))$", L[0], "the function")
            up = m.group(2) == "^x"
        right = "increasing: the base is greater than 1" if up else "decreasing: the base is between 0 and 1"
        want = qr_norm(ans, {"v": right})
    elif u == "pick-graph":
        need(A > 0, "a reflected graph is not offered as increasing")
        y0 = f.subs(X, 0)
        say = lambda asym, a_, b_, up_: el_m_text(f"asymptote y = {asym}, through {a_ if a_ == b_ else a_ + ' and ' + b_}, {'increasing' if up_ else 'decreasing'}")
        P = lambda x_, y_: el_m_text(f"({frac_text(x_)}, {frac_text(y_)})")
        want = qr_norm(ans, {"v": say(c, P(0, y0), P(h, A + c), True)})
    elif u == "moves-from-parent":
        need(f"(0, 1) on y = {b}^x" in asked, "the parent is not b^x")
        # (0, 1) on b^x is where the exponent is 0: x = h, y = A + c.
        need(sp.simplify(f.subs(X, h) - (A + c)) == 0, "the image is not on the curve")
        want = qr_norm(ans, {"x": str(h), "y": str(A + c)})
    elif u == "equation-from-graph":
        if rep == "table":
            c = el_num(em_read(r"y → (−?\d+)\.", Lj, "the asymptote").group(1))
            xs = [int(x) for x in q["table"]["rows"][0][1]]
            ys = [el_num(y) for y in q["table"]["rows"][1][1]]
        else:
            gr = q["graph"]
            c = R(sp.nsimplify(gr["hlines"][0]["at"]))
            need(el_num(em_read(r"asymptote y = (−?\d+)\.", Lj, "the asymptote").group(1)) == c, "the asymptote said is not the one drawn")
            xs = [R(sp.nsimplify(p["x"])) for p in gr["points"]]
            ys = [R(sp.nsimplify(p["y"])) for p in gr["points"]]
        need(xs[:2] == [0, 1], "the points are not at x = 0 and x = 1")
        A_ = ys[0] - c
        b_ = (ys[1] - c) / A_
        need(b_.is_integer and b_ > 1 and all(A_ * b_ ** x + c == y for x, y in zip(xs, ys)), "the points are not on one A·b^x + c")
        if rep == "graph":
            fn = A_ * b_ ** X + c
            for x0, y0 in q["graph"]["curves"][0][::16]:
                need(abs(sp.N(fn.subs(X, sp.Float(x0, 30))) - y0) <= 1e-6 * max(1, abs(y0)), "the curve is not the function")
        want = qr_norm(ans, {"v0": str(c), "v1": str(A_), "v2": str(b_)})
    elif u == "compare-reflections":
        b = int(em_read(r"y = (\d+)\^x and y = \(1/(\d+)\)\^x", Lj, "the two").group(1))
        need(sp.simplify(sp.Integer(b) ** (-X) - sp.Rational(1, b) ** X) == 0, "not a reflection pair")
        want = qr_norm(ans, {"v": "reflections of each other in the y-axis"})
        wr["SL2.9.exp-graph#2"] = {qr_norm(ans, {"v": "reflections of each other in the x-axis"})}
    qr_check_common(q, want, wr)
    return None, None


def check_exp_log_pair(q):
    g, ans, u, rep, L, asked = q["given"], q["answer"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    if u in EG_UNKNOWNS:
        return check_exp_graph(q)
    for t in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"-\d", t), f"a hyphen for a minus in {t!r}")
    wr = {}
    FI, ELI, ELF = "SL2.5.find-inverse", "SL2.9.exp-log-inverse", "SL1.5.exp-log-form"
    if q.get("paper", 1) == 2:
        return check_exp_log_pair_p2(q)
    need(u not in EL_P2 or ans.get("exact") is True, "a Paper 1 answer is not exact")
    if u in ("evaluate-log-function", "evaluate-inverse", "inverse-of-log"):
        b, h, c = el_parse_log(L[0], r"g\(x\)")
        need(b in (2, 3, 4, 5, 10) and -5 <= h <= 5 and -4 <= c <= 4, "not a clean log function")
    if u == "evaluate-log-function":
        x = el_num(em_read(r"g\((−?\d+)\)\.", asked, "the input").group(1))
        val = sp.nsimplify(sp.log(x - h, b)) + c
        need(val.is_integer and x - h <= 125, f"g({x}) = {val} is not a whole power")
        if rep == "table":
            el_check_log_table(q, b, h, c, x)
        want = qr_norm(ans, {"v": str(val)})
        wr[f"{ELF}#0"] = {qr_norm(ans, {"v": str((x - h) / b + c)})}
    elif u == "log-of-non-positive":
        b, h, c = el_parse_log(L[0], r"g\(x\)")
        x0 = el_num(em_read(r"Find g\((−?\d+)\)", asked, "the input").group(1))
        need(x0 - h <= 0, "the inside is positive, so g is defined")
        want = qr_norm(ans, {"v": EL_NOT_DEFINED})
        wr[f"{ELF}#2"] = {qr_norm(ans, {"v": el_m_text(f"g({x0}) = {c}")})}
    elif u == "inverse-of-exponential":
        b, h, c = el_parse_exp(L[0])
        f = b ** (X - h) + c
        vals = ans["values"]
        el_is_inverse(el_fn_expr("log", b, vals["p"], vals["q"]), f, EL_PTS)
        want = el_fn_norm("log", c, h)
        wr[f"{FI}#0"] = {el_fn_norm("recip", h, c)}
    elif u == "inverse-of-log":
        f = sp.log(X - h, b) + c
        vals = ans["values"]
        el_is_inverse(el_fn_expr("exp", b, vals["p"], vals["q"]), f, [h + x for x in EL_PTS])
        want = el_fn_norm("exp", c, h)
        wr[f"{FI}#1"] = {el_fn_norm("exp", -h, -c)}
        wr[f"{ELF}#1"] = {el_fn_norm("pow", c, h)}
    elif u == "evaluate-inverse":
        a = el_num(em_read(r"Find g⁻¹\((−?\d+)\)\.", asked, "the value").group(1))
        x = b ** (a - c) + h
        need(sp.log(x - h, b) + c == a and 1 <= a - c <= 3, "g at the answer is not the value asked")
        if rep == "table":
            el_check_log_table(q, b, h, c, None)
            need(frac_text(a) in q["table"]["rows"][1][1], "the value asked is not in the table")
        want = qr_norm(ans, {"v": str(x)})
        wr[f"{ELI}#1"] = {qr_norm(ans, {"v": str((a - c) ** b + h)})}
    elif u == "inverse-awkward-base":
        b1 = int(em_read(r"^f\(x\) = (\d+)\^x$", L[0], "f").group(1))
        v = el_num(em_read(r"Find f⁻¹\((\d+)\)", asked, "the value").group(1))
        val = sp.nsimplify(sp.log(v) / sp.log(b1))
        need(val.is_rational and not val.is_integer, f"log_{b1} {v} = {val} is not a fraction")
        want = qr_norm(ans, {"v": str(val)})
        wr["SL1.7.change-of-base#0"] = {qr_norm(ans, {"v": str(1 / val)})}
    elif u == "simplify-composite":
        b1 = int(em_read(r"^f\(x\) = (\d+)\^x$", L[0], "f").group(1))
        b2 = int(em_read(r"^g\(x\) = log([₀-₉]+) x, for x > 0$", L[1], "g").group(1).translate(EL_SUB))
        n = sp.nsimplify(sp.log(b1) / sp.log(b2))
        need(n.is_rational and n != 1, "the bases are not from one family")
        need(sp.simplify(sp.Integer(b1) ** sp.log(sp.Integer(7), b2) - sp.Integer(7) ** n) == 0, "f(g(7)) is not 7 to that power")
        want = ("pow", n)
        wr["SL2.5.composite-expression#0"] = {("lin", n)}
        pbase = min(p for p in (2, 3) if sp.log(b2, p).is_integer and sp.log(b1, p).is_integer)
        if b2 != pbase:
            wr["SL1.7.change-of-base#2"] = {("pow", sp.Rational(int(sp.log(b1, pbase)), b2))}
    elif u == "composite-inequality":
        fpoly = parse(em_read(r"^f\(x\) = (.+)$", L[0], "f").group(1))
        b = int(em_read(r"^g\(x\) = log([₀-₉]+) x, for x > 0$", L[1], "g").group(1).translate(EL_SUB))
        m = em_read(r"^Solve f\(g\(x\)\) ([<>≤≥]) (−?\d+)\.$", asked, "the inequality")
        rel, d = m.group(1), el_num(m.group(2))
        xs = sp.Symbol("xs", positive=True)
        lhs = fpoly.subs(X, sp.log(xs, b))
        op = {"<": sp.Lt, ">": sp.Gt, "≤": sp.Le, "≥": sp.Ge}[rel]
        sol = sp.solveset(op(lhs, d), xs, sp.Interval.open(0, sp.oo))
        need(isinstance(sol, sp.Interval), f"the solution {sol} is not one interval")
        if sol.inf == 0:
            need(sol.left_open and sol.sup.is_integer, "not 0 < x < v")
            want = qr_norm(ans, {"lo": "0", "r1": "<", "r2": "<" if sol.right_open else "≤", "hi": str(sol.sup)})
            need(ans["kind"] == "range2", "a bounded set is not written as lo < x < hi")
        else:
            need(sol.sup == sp.oo and sol.inf.is_integer, "not x > v")
            want = qr_norm(ans, {"rel": ">" if sol.left_open else "≥", "v": str(sol.inf)})
            need(ans["kind"] == "bound", "a ray is not written as x > v")
    elif u == "transformations-between":
        Lf = [l for l in L if l.startswith("f(x) = ")][0]
        Lg = [l for l in L if l.startswith("g(x) = ")][0]
        b, h0, c0 = el_parse_exp(Lf)
        need(h0 == 0 and c0 == 0, "f is not the parent b^x")
        bg, hg, cg = el_parse_exp(Lg, r"g\(x\)")
        if "translation" in asked:
            need(bg == b and hg != 0, "g is not a translation of f")
            right = el_m_text(f"a translation by the vector ({hg}, {cg})")
            wr["SL2.11.describe#0"] = {qr_norm(ans, {"v": el_m_text(f"a translation by the vector ({-hg}, {cg})")})}
            gx = b ** (X - hg) + cg
        else:
            j = sp.nsimplify(sp.log(bg) / sp.log(b))
            need("stretch" in asked and j.is_integer and j > 1 and hg == 0 and cg == 0, "g is not a stretch of f")
            right = f"a horizontal stretch, scale factor 1/{j}"
            wr["SL2.11.describe#2"] = {qr_norm(ans, {"v": f"a stretch, scale factor 1/{j}"})}
            gx = sp.Integer(bg) ** X
        if rep == "graph":
            gr = q["graph"]
            for pts, fn in zip(gr["curves"], [sp.Integer(b) ** X, gx]):
                for x0, y0 in pts[::16]:
                    need(abs(sp.N(fn.subs(X, sp.Float(x0, 30))) - y0) <= 1e-6 * max(1, abs(y0)), "a curve is not its function")
        want = qr_norm(ans, {"v": right})
    elif u == "write-log-form":
        m = em_read(r"^(\d+)([⁰¹²³⁴⁵⁶⁷⁸⁹]+) = (\d+)$", L[0], "the power")
        b, n, x = int(m.group(1)), int(m.group(2).translate(str.maketrans("⁰¹²³⁴⁵⁶⁷⁸⁹", "0123456789"))), int(m.group(3))
        need(b ** n == x, "the power statement is false")
        want = (R(b), R(x), R(n))
        wr[f"{ELF}#1"] = {(R(n), R(x), R(b))}
    elif u == "solve-exp-equation":
        m = em_read(r"^e\^\((\d+)x\)(?: ([+−]) (\d+))? = (−?\d+)$", L[0], "the equation")
        mm, c, d = int(m.group(1)), el_parse_q(m.group(2), m.group(3)), el_num(m.group(4))
        sol = sp.solve(sp.exp(mm * X) + c - d, X)
        real = [s_ for s_ in sol if s_.is_real]
        need(len(real) == 1, "not one real solution")
        r = d - c
        want = round(float(real[0]), 9)
        wr[f"{ELI}#0"] = {round(float(mm * sp.log(r)), 9), round(float(sp.log(r) - mm), 9)}
        wr[f"{ELI}#2"] = {round(float(r / (mm * sp.E)), 9)}
    elif u == "solve-log-equation":
        m = em_read(r"^log([₀-₉]+)\((x(?: [−+] \d+)?)\)(?: ([+−]) (\d+))? = (−?\d+)$", L[0], "the equation")
        b, h, c, d = int(m.group(1).translate(EL_SUB)), el_parse_shift(m.group(2)), el_parse_q(m.group(3), m.group(4)), el_num(m.group(5))
        sol = sp.solve(sp.log(X - h, b) + c - d, X)
        need(len(sol) == 1 and sol[0].is_integer, f"the solution {sol} is not one whole number")
        want = qr_norm(ans, {"v": str(sol[0])})
        wr[f"{ELI}#1"] = {qr_norm(ans, {"v": str((d - c) ** b + h)})}
    elif u == "composite-order":
        b, _, _ = el_parse_exp(L[0])
        if "log" in L[1]:
            need(L[1] == f"g(x) = {el_log_name(b)} x, for x > 0", "g is not log_b x")
            fg_e, gf_e, fg, gf = X, X, "x", "x"
        else:
            p = parse(em_read(r"^g\(x\) = (.+)$", L[1], "g").group(1)) - X
            need(p.is_integer and p != 0, "g is not x + p")
            fg_e, gf_e = sp.Integer(b) ** (X + p), sp.Integer(b) ** X + p
            fg, gf = el_fn_text("exp", b, -p, 0), f"{b}^x{el_plus_q(p)}"
        same = sp.simplify(fg_e - gf_e) == 0
        say = lambda a_, c_, e_: f"f(g(x)) = {a_}, g(f(x)) = {c_}: {'equal' if e_ else 'not equal'}"
        want = qr_norm(ans, {"v": say(fg, gf, same)})
        if not same:
            wr["SL2.5.composite-expression#2"] = {qr_norm(ans, {"v": say(fg, gf, True)})}
    elif u == "inverse-graph":
        b, h, c = el_parse_exp(L[0])
        f = b ** (X - h) + c
        y0 = f.subs(X, 0)
        need(y0.is_integer, "the inverse's x-intercept is not whole")
        gr = q["graph"]
        for x0, yv in gr["curves"][0][::16]:
            need(abs(sp.N(f.subs(X, sp.Float(x0, 30))) - yv) <= 1e-6 * max(1, abs(yv)), "the curve is not f")
        need([R(sp.nsimplify(hl["at"])) for hl in gr["hlines"]] == [c], "the asymptote drawn is not y = c")
        want = qr_norm(ans, {"v0": str(c), "v1": str(y0)})
    elif u == "inverse-log-of-square":
        m = em_read(r"^g\(x\) = log([₀-₉]+)\(\((x(?: [−+] \d+)?)\)²\), for x > (−?\d+)$|^g\(x\) = log([₀-₉]+)\(x²\), for x > (−?\d+)$", L[0], "g")
        if m.group(1):
            b, h = int(m.group(1).translate(EL_SUB)), el_parse_shift(m.group(2))
            need(el_num(m.group(3)) == h, "the domain is not x > h")
        else:
            b, h = int(m.group(4).translate(EL_SUB)), 0
            need(el_num(m.group(5)) == 0, "the domain is not x > 0")
        f = sp.log((X - h) ** 2, b)
        vals = ans["values"]
        el_is_inverse(el_fn_expr("exphalf", b, 0, vals["q"]), f, [h + x for x in EL_PTS])
        want = el_fn_norm("exphalf", 0, h)
        wr[f"{FI}#2"] = {el_fn_norm("pm", 0, h)}
    elif u == "function-from-inverse":
        b, h, c = el_parse_log(L[0], r"f⁻¹\(x\)")
        finv = sp.log(X - h, b) + c
        vals = ans["values"]
        el_is_inverse(finv, el_fn_expr("exp", b, vals["p"], vals["q"]), EL_PTS)
        want = el_fn_norm("exp", c, h)
    else:
        raise Fail(f"the checker has no solver for {u}")
    qr_check_common(q, want, wr)
    return None, None


# Paper 2 (FAL-419): the cells with a calculator version, and its limits (the engine's
# are in exp_log_pair.gd): the inside of g(x) is 2 to 60 and not a power of b; g⁻¹ and
# the log equation are at c + t, t in tenths (0.2 to 2.9, not whole), with b^t ≤ 150.
EL_P2 = {"evaluate-log-function", "evaluate-inverse", "solve-exp-equation", "solve-log-equation"}
EL_P2_INSIDE = (2, 60)
EL_P2_T = (sp.Rational(1, 5), sp.Rational(29, 10))
EL_P2_BT = 150
EL_SF = ", correct to 3 significant figures"


def el_p2_value(v):
    """A Paper 2 answer: needs a calculator and is clear of a 3 s.f. rounding edge."""
    need(not sp.nsimplify(v).is_rational, f"{v} doesn't need a calculator")
    need(not on_edge(abs(v)), f"{sp.N(v, 12)} is on a 3 s.f. rounding edge")
    return ext_sf(v)


def el_p2_t(text, c):
    """The decimal a = c + t asked at: t in tenths, in limits, not whole."""
    a = el_num(text)
    t = a - c
    need(t.q == 10 or t.q == 5 or t.q == 2, f"t = {t} is not in tenths")
    need(EL_P2_T[0] <= t <= EL_P2_T[1] and not t.is_integer, f"t = {t} is outside the limits")
    return a, t


def check_exp_log_pair_p2(q):
    """Paper 2: the same functions at numbers that need a calculator, each answer to
    3 s.f. (show sf), solved again here with SymPy."""
    g, ans, u, rep, L, asked = q["given"], q["answer"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    ELI, ELF = "SL2.9.exp-log-inverse", "SL1.5.exp-log-form"
    need(u in EL_P2 and rep == "equation", f"{u} ({rep}) has no Paper 2 version")
    need(ans.get("show") == "sf" and not ans.get("exact") and ans["kind"] == "number", "a Paper 2 answer is not a number to 3 s.f.")
    need(asked.endswith(EL_SF + "."), "a Paper 2 question doesn't ask for 3 s.f.")
    wr = {}
    if u in ("evaluate-log-function", "evaluate-inverse"):
        b, h, c = el_parse_log(L[0], r"g\(x\)")
        need(b in (2, 3, 4, 5, 10) and -5 <= h <= 5 and -4 <= c <= 4, "not a clean log function")
    if u == "evaluate-log-function":
        x = el_num(em_read(r"^Find g\((−?\d+)\),", asked, "the input").group(1))
        k = x - h
        need(EL_P2_INSIDE[0] <= k <= EL_P2_INSIDE[1], f"the inside {k} is outside the limits")
        need(not sp.nsimplify(sp.log(k, b)).is_rational, f"{k} is a power of {b}")
        need(ans["label"] == el_m_text(f"g({x}) = "), "the label is not g at the input")
        want = el_p2_value(sp.log(k, b) + c)
        wr[f"{ELF}#0"] = {ext_sf(k / sp.Integer(b) + c)}
    elif u == "evaluate-inverse":
        m = em_read(r"^Find g⁻¹\((−?\d+(?:\.\d+)?)\),", asked, "the value")
        a, t = el_p2_t(m.group(1), c)
        need(sp.Integer(b) ** t <= EL_P2_BT, "b^t is too big")
        x = sp.Integer(b) ** t + h
        need(sp.simplify(sp.log(x - h, b) + c - a) == 0, "g at the answer is not the value asked")
        need(abs(x) >= 1, "the answer is too close to 0")
        want = el_p2_value(x)
        wr[f"{ELI}#1"] = {ext_sf(t ** b + h)}
    elif u == "solve-exp-equation":
        m = em_read(r"^e\^\((\d+)x\)(?: ([+−]) (\d+))? = (−?\d+)$", L[0], "the equation")
        mm, c, d = int(m.group(1)), el_parse_q(m.group(2), m.group(3)), el_num(m.group(4))
        need(asked == f"Solve {L[0]}, giving x{EL_SF}.", "the question is not the equation shown")
        sol = [s_ for s_ in sp.solve(sp.exp(mm * X) + c - d, X) if s_.is_real]
        need(len(sol) == 1, "not one real solution")
        r = d - c
        want = el_p2_value(sol[0])
        wr[f"{ELI}#0"] = {ext_sf(mm * sp.log(r)), ext_sf(sp.log(r) - mm)}
        wr[f"{ELI}#2"] = {ext_sf(r / (mm * sp.E))}
    elif u == "solve-log-equation":
        m = em_read(r"^log([₀-₉]+)\((x(?: [−+] \d+)?)\)(?: ([+−]) (\d+))? = (−?\d+\.\d+)$", L[0], "the equation")
        b, h, c = int(m.group(1).translate(EL_SUB)), el_parse_shift(m.group(2)), el_parse_q(m.group(3), m.group(4))
        need(b in (2, 3, 4, 5, 10) and -5 <= h <= 5 and -4 <= c <= 4, "not a clean log equation")
        need(asked == f"Solve {L[0]}, giving x{EL_SF}.", "the question is not the equation shown")
        a, t = el_p2_t(m.group(5), c)
        need(sp.Integer(b) ** t <= EL_P2_BT, "b^t is too big")
        sol = sp.solve(sp.log(X - h, b) + c - a, X)
        need(len(sol) == 1, f"the solution {sol} is not one number")
        need(abs(sol[0]) >= 1, "the answer is too close to 0")
        want = el_p2_value(sol[0])
        wr[f"{ELI}#1"] = {ext_sf(t ** b + h)}
    qr_check_common(q, want, wr)
    if any(o.get("trap") for o in q["choices"]):
        trap = [o for o in q["choices"] if o.get("trap")][0]
        need(sig3(R(trap["values"]["v"]), 2) == sig3(R(ans["values"]["v"]), 2), "the rounding trap is not the answer to 2 s.f.")
    for sol in q["solutions"]:
        need(any("GDC" in st for st in sol["steps"]), f"{sol['name']}: a Paper 2 solution doesn't use the GDC")
    return None, None


# ── log-quadratic (fn-log-of-quadratic) ──
# The clean limits, the checker's own copy of game/engine/situations/log_quadratic.gd's.

LQ_A = {sp.Integer(-1), sp.Rational(-1, 2)}
LQ_N = {2, 3}
LQ_H_MAX = 5


def lq_surd(expr):
    """A zero h ± m√r as the game writes it: "3 − 2√2", "−√3"."""
    h, rest = sp.expand(expr).as_coeff_Add()
    m, root = rest.as_coeff_Mul()
    r = sp.Integer(root ** 2)
    body = qr_surd(abs(m), r)
    if h == 0:
        return ("−" if m < 0 else "") + body
    return f"{frac_text(h)} {'−' if m < 0 else '+'} {body}"


def lq_read(q):
    """The base (None when it is the unknown k) and g, from the lines."""
    L = " ".join(q["lines"])
    m = re.search(r"f\(x\) = log([₀-₉]+|_k)\(([^()]*)\)", L)
    if m and "g(x)" not in m.group(2):
        base = None if m.group(1) == "_k" else int(m.group(1).translate(EL_SUB))
        return base, parse(m.group(2).replace("½", "(1/2)"))
    m = re.search(r"g\(x\) = (.+?)\. ", L)
    need(m is not None, "can't read g")
    return None, parse(m.group(1))


@lru_cache(maxsize=None)
def lq_facts(gtext, base):
    """Everything about one f(x) = log_base(g(x)) that doesn't depend on the question:
    solved once per function (there are only a few dozen), with the clean limits."""
    gp = sp.sympify(gtext, locals={"x": X})
    out = {"error": None}
    a, b_, c = [R(x) for x in sp.Poly(gp, X).all_coeffs()]
    rts = sorted(sp.solve(gp, X))
    if a not in LQ_A:
        out["error"] = f"a = {a} is not a clean downward parabola"
        return out
    if len(rts) != 2 or not all(r_.is_integer for r_ in rts):
        out["error"] = "the roots of g are not whole"
        return out
    p, qq = rts
    h, G = (p + qq) / 2, gp.subs(X, (p + qq) / 2)
    n = sp.nsimplify(sp.log(G, base))
    zs = sorted(sp.solve(gp - 1, X), key=lambda z: float(z))
    if abs(h) > LQ_H_MAX or not h.is_integer:
        out["error"] = "the axis is out of range"
    elif not (n.is_integer and int(n) in LQ_N and G / n != base):
        out["error"] = f"G = {G} is not a clean power of {base}"
    elif len(zs) != 2 or zs[0].is_rational:
        out["error"] = "the zeros are not surds"
    gf = sp.lambdify(X, gp, "math")
    out.update(a=a, b=b_, c=c, p=p, q=qq, h=h, G=G, n=n, zs=zs,
               dom=sp.solveset(gp > 0, X, sp.S.Reals),
               neg=sp.solveset(sp.log(gp, base) < 0, X, sp.Interval.open(p, qq)),
               fnum=lambda x0: mpmath.log(gf(x0)) / mpmath.log(base))
    return out


def check_log_quadratic(q):
    g, ans, u, rep, L = q["given"], q["answer"], q["view"]["unknown"], q["view"]["rep"], q["lines"]
    for t in [q["asked"]] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"-\d", t), f"a hyphen for a minus in {t!r}")
    if u == "quadratic-from-features":
        base = int(em_read(r"f\(x\) = log([₀-₉]+)\(g\(x\)\)", L[0], "the base").group(1).translate(EL_SUB))
        if rep == "graph":
            p, qq = sorted(R(sp.nsimplify(v["at"])) for v in q["graph"]["vlines"])
            n = R(em_read(r"maximum point is \((−?\d+), (\d+)\)", L[0], "the maximum").group(2))
        else:
            m = em_read(r"asymptotes x = (−?\d+) and x = (−?\d+), and its maximum value is (\d+)\.", L[1], "the features")
            p, qq, n = el_num(m.group(1)), el_num(m.group(2)), R(m.group(3))
        G = sp.Integer(base) ** n
        a = -G / ((qq - p) / 2) ** 2
        gp = sp.expand(a * (X - p) * (X - qq))
    else:
        base, gp = lq_read(q)
        if base is None:
            base = int(g["base"])
    F = lq_facts(str(gp), base)
    need(F["error"] is None, F["error"] or "")
    a, b_, c, p, qq, h, G, n, zs = (F[k] for k in ("a", "b", "c", "p", "q", "h", "G", "n", "zs"))
    f = sp.log(gp, base)
    if q.get("graph") and u != "quadratic-from-features" or (u == "quadratic-from-features" and rep == "graph"):
        gr = q["graph"]
        for x0, y0 in gr["curves"][0][::16]:
            need(abs(F["fnum"](x0) - y0) <= 1e-6 * max(1, abs(y0)), f"the curve misses ({x0}, {y0})")
        need(sorted(R(sp.nsimplify(v["at"])) for v in gr["vlines"]) == [p, qq], "the asymptotes drawn are not at the roots")
        for pt in gr["points"]:
            need(sp.simplify(f.subs(X, sp.nsimplify(pt["x"])) - sp.nsimplify(pt["y"])) == 0, f"the marked point {pt['label']} is not on f")
    wr = {}
    if u == "argument-roots":
        want = qr_norm(ans, {"r1": str(p), "r2": str(qq)})
    elif u == "domain-from-inequality":
        want = F["dom"]
        wr["SL2.7.inequality#0"] = {sp.Interval.open(p, sp.oo)}
    elif u == "asymptotes":
        say = lambda a_, b2: el_m_text(f"x = {frac_text(a_)} and x = {frac_text(b2)}")
        want = qr_norm(ans, {"v": say(p, qq)})
        wr["SL2.4.asymptotes#0"] = {qr_norm(ans, {"v": f"{frac_text(p)} and {frac_text(qq)}"})}
        wr["SL2.4.asymptotes#1"] = {qr_norm(ans, {"v": f"y = {frac_text(p)} and y = {frac_text(qq)}"})}
        wr["SL2.4.asymptotes#2"] = {qr_norm(ans, {"v": say(-p, -qq)})}
        wr["SL2.9.log-graph#0"] = {qr_norm(ans, {"v": "y = 0"})}
    elif u == "zeros":
        half = sp.expand(zs[1] - h)
        m_, root = half.as_coeff_Mul()
        want = qr_norm(ans, {"h": str(h), "m": str(m_), "r": str(sp.Integer(root ** 2))})
    elif u == "max-value":
        want = qr_norm(ans, {"v0": str(n), "v1": str(h)})
        wr["SL2.6.vertex#0"] = {qr_norm(ans, {"v0": str(n), "v1": str(-h)})}
        wr["SL2.6.vertex#1"] = {qr_norm(ans, {"v0": str(h), "v1": str(h)})}
    elif u == "base-from-max":
        Ls = " ".join(L)
        nn = R(em_read(r"(?:maximum value of f is|largest value f takes is|maximum point is \(−?\d+,) (\d+)", Ls, "the maximum").group(1))
        k = sp.nsimplify(G ** (sp.Integer(1) / nn))
        need(k.is_integer and k == base, "the base from the maximum is not the given base")
        want = qr_norm(ans, {"v": str(k)})
        wr["SL1.5.exp-log-form#0"] = {qr_norm(ans, {"v": str(G / nn)})}
    elif u == "range":
        want = ("y", "≤", n)
        wr["SL2.6.vertex#2"] = {("y", "≥", n)}
        wr["SL2.2.range#2"] = {("x", "≤", n)}
    elif u == "axis-of-graph":
        need(h != 0, "the axis is the y-axis, so x = 0 can't be a wrong option")
        want = qr_norm(ans, {"var": "x", "h": str(h)})
        wr["SL2.4.symmetry#0"] = {qr_norm(ans, {"var": "x", "h": "0"})}
    elif u == "y-intercept":
        need(p < 0 < qq, "the graph does not meet the y-axis")
        need(ans["label"] == f"f(0) = {el_log_name(base)} ", "the form asked is not log_k c")
        want = qr_norm(ans, {"v": str(gp.subs(X, 0))})
    elif u == "sign-of-f":
        neg = F["neg"]
        z1, z2 = zs
        need(neg == sp.Union(sp.Interval.open(p, z1), sp.Interval.open(z2, qq)), f"f < 0 on {neg}")
        right = f"{frac_text(p)} < x < {lq_surd(z1)} or {lq_surd(z2)} < x < {frac_text(qq)}"
        want = qr_norm(ans, {"v": right})
        wr["SL2.7.inequality#1"] = {qr_norm(ans, {"v": f"{lq_surd(z1)} < x < {lq_surd(z2)}"})}
    elif u == "quadratic-from-features":
        want = qr_norm(ans, {"A": str(a), "B": str(b_), "C": str(c)})
    else:
        raise Fail(f"the checker has no solver for {u}")
    qr_check_common(q, want, wr)
    return None, None


# ── log-function (fn-log-function-features) ──

def lf_parse(text):
    """'y = 2log₃(2x − 6) + 1' -> (A, b, inside, c)."""
    m = re.search(r"(?:y|f\(x\)) = (−|\d+)?log([₀-₉]+)\(([^()]+)\)(?: ([+−]) (\d+))?", text)
    need(m is not None, f"can't read the log function in {text!r}")
    A = 1 if m.group(1) is None else (-1 if m.group(1) == "−" else int(m.group(1)))
    return A, int(m.group(2).translate(EL_SUB)), parse(m.group(3)), el_parse_q(m.group(4), m.group(5))


def lf_set_want(ans, sol):
    """The answer values for a solution set: lo < x < hi (range2) or a ray (bound)."""
    need(isinstance(sol, sp.Interval), f"the solution {sol} is not one interval")
    if sol.sup == sp.oo:
        need(ans["kind"] == "bound", "a ray is not written as x > v")
        return qr_norm(ans, {"rel": ">" if sol.left_open else "≥", "v": str(sol.inf)})
    if sol.inf == -sp.oo:
        need(ans["kind"] == "bound", "a ray is not written as x < v")
        return qr_norm(ans, {"rel": "<" if sol.right_open else "≤", "v": str(sol.sup)})
    need(ans["kind"] == "range2", "a bounded set is not written as lo < x < hi")
    return qr_norm(ans, {"lo": str(sol.inf), "r1": "<" if sol.left_open else "≤", "r2": "<" if sol.right_open else "≤", "hi": str(sol.sup)})


def lf_curve(q, fn):
    gr = q["graph"]
    need(gr is not None, "no graph")
    for x0, y0 in gr["curves"][0][::16]:
        need(abs(sp.N(fn.subs(X, sp.Float(x0, 30))) - y0) <= 1e-6 * max(1, abs(y0)), f"the curve misses ({x0}, {y0})")
    return gr


def check_log_function(q):
    g, ans, u, rep, L, asked = q["given"], q["answer"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    for t in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"-\d", t), f"a hyphen for a minus in {t!r}")
    wr = {}
    xs = sp.Symbol("xs", real=True)
    say_x = lambda v: el_m_text(f"x = {frac_text(v)}")
    if u == "sign-of-log-expression":
        m = em_read(r"^f\(x\) = ln\((x(?: [−+] \d+)?)\)/x([¹²³]?), for x > (\d+)$", L[0], "f")
        h = el_parse_shift(m.group(1))
        pw = int((m.group(2) or "¹").translate(str.maketrans("¹²³", "123")))
        need(h >= 0 and int(m.group(3)) == h, "the domain is not x > h with h ≥ 0")
        rel = em_read(r"f\(x\) ([<>]) 0", asked, "the sign").group(1)
        fx = sp.log(xs - h) / xs ** pw
        sol = sp.solveset(sp.Gt(fx, 0) if rel == ">" else sp.Lt(fx, 0), xs, sp.Interval.open(h, sp.oo))
        want = lf_set_want(ans, sol)
        qr_check_common(q, want, wr)
        return None, None
    if u == "reflect-exponential":
        b, hh, cc = el_parse_exp(L[0].split(" is shown")[0].split(" passes")[0].replace("The graph of y", "f(x)"))
        need(cc == 0, "the exponential is shifted vertically")
        px, py = [el_num(v) for v in em_read(r"matches \((−?\d+), (−?\d+)\)", asked, "the point").groups()]
        need(sp.Integer(b) ** (px - hh) == py, "the point is not on the exponential")
        if rep == "graph":
            lf_curve(q, sp.Integer(b) ** (X - hh))
        want = qr_norm(ans, {"x": str(py), "y": str(px)})
        qr_check_common(q, want, wr)
        return None, None
    if u == "n-from-asymptote":
        b = int(em_read(r"y = log([₀-₉]+)\(x − n\)", L[0], "the base").group(1).translate(EL_SUB))
        if rep == "graph":
            a = R(sp.nsimplify(q["graph"]["vlines"][0]["at"]))
        else:
            a = el_num(em_read(r"asymptote x = (−?\d+)\.", L[0], "the asymptote").group(1))
        cc = el_parse_q(*em_read(r"\(x − n\)(?: ([+−]) (\d+))?", L[0], "c").groups())
        if rep == "graph":
            lf_curve(q, sp.log(X - a, b) + cc)
        want = qr_norm(ans, {"v": str(a)})
        if a != 0:
            wr["SL2.4.asymptotes#2"] = {qr_norm(ans, {"v": str(-a)})}
        qr_check_common(q, want, wr)
        return None, None
    if u == "pick-graph" and rep == "graph":
        gr = q["graph"]
        def matches(text):
            A, b, ins, c = lf_parse(text)
            fn = A * sp.log(ins, b) + c
            pts = gr["curves"][0][::16]
            inside_ = [(x0, y0) for x0, y0 in pts if sp.N(ins.subs(X, sp.Float(x0, 30))) > 0]
            return len(inside_) * 2 >= len(pts) and all(abs(sp.N(fn.subs(X, sp.Float(x0, 30))) - y0) <= 1e-6 * max(1, abs(y0))
                                                       for x0, y0 in inside_)
        good = [o["text"] for o in q["choices"] if matches(o["text"])]
        need(len(good) == 1, f"{len(good)} equations fit the graph")
        want = qr_norm(ans, {"v": good[0]})
        qr_check_common(q, want, wr)
        return None, None
    A, b, ins, c = lf_parse(" ".join(L) if u != "pick-graph" else asked)
    mm, nn = [R(v) for v in sp.Poly(ins, X).all_coeffs()] if sp.Poly(ins, X).degree() == 1 else (None, None)
    need(mm is not None and mm in {1, 2, 3, -1, -2, -3} and A in {1, 2, 3, -1}, "not a clean log function")
    x0 = -nn / mm
    need(x0.q in (1, 2), "the asymptote is not whole or a half")
    fn = A * sp.log(ins, b) + c
    dom = sp.solveset(ins.subs(X, xs) > 0, xs, sp.S.Reals)
    if rep == "graph" and u != "log-inequality":
        gr = lf_curve(q, fn)
        need([R(sp.nsimplify(v["at"])) for v in gr["vlines"]] == [x0], "the asymptote drawn is not x = x0")
    if u == "asymptote-from-equation":
        want = qr_norm(ans, {"v": say_x(x0)})
        wr["SL2.9.log-graph#1"] = {qr_norm(ans, {"v": say_x(nn / mm)})}
        wr["SL2.4.asymptotes#0"] = {qr_norm(ans, {"v": frac_text(x0)})}
    elif u == "domain-from-equation":
        want = lf_set_want(ans, dom)
        wr["SL2.2.domain#1"] = {qr_norm(ans, {"rel": ">", "v": "0"})}
    elif u == "domain-from-graph":
        need(isinstance(dom, sp.Interval), "the domain is not one interval")
        right = el_m_text(f"x > {frac_text(dom.inf)}" if dom.sup == sp.oo else f"x < {frac_text(dom.sup)}")
        want = qr_norm(ans, {"v": right})
        wr["SL2.2.domain#2"] = {qr_norm(ans, {"v": "all real values of y"})}
    elif u == "asymptote-from-graph":
        want = qr_norm(ans, {"v": say_x(x0)})
        wr["SL2.4.asymptotes#1"] = {qr_norm(ans, {"v": el_m_text(f"y = {frac_text(x0)}")})}
        wr["SL2.9.log-graph#0"] = {qr_norm(ans, {"v": "y = 0"})}
    elif u == "x-intercept":
        sol = sp.solveset(fn.subs(X, xs), xs, dom)
        need(isinstance(sol, sp.FiniteSet) and len(sol) == 1 and list(sol)[0].is_rational, f"the x-intercept {sol} is not one exact number")
        want = qr_norm(ans, {"v": str(list(sol)[0])})
        wr["SL2.9.log-graph#2"] = {qr_norm(ans, {"v": str(x0)})}
    elif u == "pick-graph":
        need(mm == 1 and A == 1, "pick-graph is on log_b(x − h) + c")
        h = x0
        P = lambda x_, y_: el_m_text(f"({frac_text(x_)}, {frac_text(y_)})")
        say = lambda a_, p1, p2, up: el_m_text(f"asymptote x = {frac_text(a_)}, through {p1} and {p2}, {'increasing' if up else 'decreasing'}")
        p2 = P(h + b, c + 1)
        need(fn.subs(X, h + 1) == c and sp.simplify(fn.subs(X, h + b) - (c + 1)) == 0, "the key points are not on the graph")
        want = qr_norm(ans, {"v": say(h, P(h + 1, c), p2, True)})
        wr["SL2.9.log-graph#2"] = {qr_norm(ans, {"v": say(h, P(h, 0), p2, True)})}
    elif u == "log-inequality":
        m = em_read(r"^Solve log([₀-₉]+)\(([^()]+)\) ([<>≤≥]) (−?\d+)\.$", asked, "the inequality")
        k = el_num(m.group(4))
        op = {"<": sp.Lt, ">": sp.Gt, "≤": sp.Le, "≥": sp.Ge}[m.group(3)]
        sol = sp.solveset(op(sp.log(ins.subs(X, xs), b), k), xs, dom)
        if rep == "graph":
            gr = lf_curve(q, sp.log(ins, b))
            need([R(sp.nsimplify(hl["at"])) for hl in gr["hlines"]] == [k], "the line drawn is not y = k")
        want = lf_set_want(ans, sol)
    else:
        raise Fail(f"the checker has no solver for {u}")
    qr_check_common(q, want, wr)
    return None, None


# ── fn-pre-percent-multiplier ──
# The clean limits, the checker's own copy of game/engine/situations/percent.gd's.

PC_RATES = {5, 8, 10, 12, 15, 20, 25, 30, 35, 40}
PC_AMOUNTS = {80, 120, 160, 200, 240, 300, 360, 400, 500, 640, 800, 1200, 1500, 2000}


def pc_val(text):
    """A side of a line of working, with every decimal read exactly."""
    t = re.sub(r"\d+\.\d+", lambda m: f"({sp.Rational(m.group(0))})", text.replace("−", "-").replace("×", "*"))
    return sp.sympify(t)


def pc_first_false(q, lines):
    for i, line in enumerate(lines):
        a, b = line.split(" = ")
        if pc_val(a) != pc_val(b):
            return i
    return None


def pc_change(text):
    """'an increase of 15%' -> 115/100."""
    m = em_read(r"(increase|decrease|rises by|falls by) (?:of )?(\d+)%", text, "the change")
    r = int(m.group(2))
    return 1 + sp.Rational(r, 100) * (1 if m.group(1) in ("increase", "rises by") else -1), r


def check_percent(q):
    g, ans, u, rep, L = q["given"], q["answer"], q["view"]["unknown"], q["view"]["rep"], q["lines"]
    T = "fn-pre-percent-multiplier"
    need(R(g["P"]) in PC_AMOUNTS and int(g["r"]) in PC_RATES and int(g["r2"]) in PC_RATES, "not a clean amount or rate")
    wr = {}
    Lj = " ".join(L)
    tab = {row[0]: row[1][0] for row in q["table"]["rows"]} if q.get("table") else {}
    def amount(key, pat):
        return el_num(tab[key]) if key in tab else el_num(em_read(pat, Lj, key).group(1))
    if u in ("increase-multiplier", "decrease-multiplier"):
        m, r = pc_change(q["asked"])
        want = qr_norm(ans, {"v": str(m)})
        if u == "decrease-multiplier":
            wr[f"{T}#0"] = {qr_norm(ans, {"v": str(sp.Rational(r, 100))})}
        elif r < 10:
            wr[f"{T}#1"] = {qr_norm(ans, {"v": str(1 + sp.Rational(r, 10))})}
    elif u == "apply-change":
        if rep == "table":
            P, ch = el_num(tab["Before"]), tab["Change"]
            m = 1 + sp.Rational(int(ch[1:-1]), 100) * (1 if ch[0] == "+" else -1)
            r = int(ch[1:-1])
        else:
            P = el_num(em_read(r"([\d.]+)(?:,| changes)", Lj, "the amount").group(1))
            m, r = pc_change(q["asked"])
        want = qr_norm(ans, {"v": str(P * m)})
        if m < 1:
            wr[f"{T}#0"] = {qr_norm(ans, {"v": str(P * sp.Rational(r, 100))})}
    elif u == "multiplier-to-percent":
        mm = el_num(em_read(r"multiplying by ([\d.]+) stand for\?", q["asked"], "the multiplier").group(1))
        want = ("rise" if mm > 1 else "fall", abs(mm - 1) * 100)
    elif u == "reverse-percentage":
        if rep == "table":
            A, ch = el_num(tab["After"]), tab["Change"]
            r, up = int(ch[1:-1]), ch[0] == "+"
        else:
            A = el_num(em_read(r"([\d.]+)(?: after|\.$)", Lj, "the amount after").group(1))
            m_, r = pc_change(Lj)
            up = m_ > 1
        m = 1 + sp.Rational(r, 100) * (1 if up else -1)
        want = qr_norm(ans, {"v": str(A / m)})
        wr[f"{T}#2"] = {qr_norm(ans, {"v": str(A - A * sp.Rational(r, 100) if up else A + A * sp.Rational(r, 100))})}
    elif u == "repeated-changes":
        parts = Lj.replace("A price has ", "").rstrip(".").split(", then ")
        (m1, _), (m2, _) = pc_change(parts[0]), pc_change(parts[1])
        M = m1 * m2
        want = qr_norm(ans, {"v0": str(M), "v1": str((M - 1) * 100)})
    elif u == "percent-from-amounts":
        if rep == "table":
            P, A = el_num(tab["Before"]), el_num(tab["After"])
        else:
            P, A = [el_num(x) for x in em_read(r"(\d+(?:\.\d+)?) (?:→|to) (\d+(?:\.\d+)?)", Lj, "the amounts").groups()]
        want = ("rise" if A > P else "fall", abs(A - P) / P * 100)
    else:
        raise Fail(f"the checker has no solver for {u}")
    qr_check_common(q, want, wr)
    return None, None


SPOT_CHECKS["fn-pre-percent-multiplier"] = pc_first_false


# ── exp-growth-vs-linear (fn-concept-growth-patterns) ──

GP_LIN = "linear: the differences are constant"
GP_EXP = "exponential: the ratios are constant"
GP_NEITHER = "neither: the differences and the ratios both change"


def gp_pattern(vals):
    d = {vals[i + 1] - vals[i] for i in range(len(vals) - 1)}
    r = {vals[i + 1] / vals[i] for i in range(len(vals) - 1)}
    return GP_LIN if len(d) == 1 else (GP_EXP if len(r) == 1 else GP_NEITHER)


def gp_models(L):
    Lj = " ".join(L)
    m = re.search(r"L\(t\) = (\d+) \+ (\d+)t", Lj) or re.search(r"L starts at (\d+) and gains (\d+) a year", Lj)
    e = re.search(r"E\(t\) = (\d+)\(([\d.]+)\)\^t", Lj)
    if e:
        P0, a = el_num(e.group(1)), el_num(e.group(2))
    else:
        e = em_read(r"E starts at (\d+) and grows by (\d+(?:\.\d+)?)% a year", Lj, "E")
        P0, a = el_num(e.group(1)), 1 + el_num(e.group(2)) / 100
    need(m is not None, "can't read L")
    return el_num(m.group(1)), el_num(m.group(2)), P0, a


def check_growth(q):
    ans, u, rep, L = q["answer"], q["view"]["unknown"], q["view"]["rep"], q["lines"]
    wr = {}
    if u == "classify-table":
        vals = [el_num(v) for v in q["table"]["rows"][1][1]]
        want = qr_norm(ans, {"v": gp_pattern(vals)})
    elif u == "classify-graph":
        vals = [R(sp.nsimplify(p["y"])) for p in q["graph"]["points"]]
        need([R(sp.nsimplify(p["x"])) for p in q["graph"]["points"]] == [0, 1, 2, 3], "the marked points are not t = 0 to 3")
        want = qr_norm(ans, {"v": gp_pattern(vals)})
    elif u == "classify-words":
        m = re.search(r"starts with (\d+) cells and grows by (\d+)% each hour", L[0])
        if m:
            P0, r = el_num(m.group(1)), el_num(m.group(2))
            want = qr_norm(ans, {"v": f"exponential: N = {dec_text(P0)}({dec_text(1 + r / 100)})^t"})
            wr["SL2.9.exp-model#0"] = {qr_norm(ans, {"v": f"exponential: N = {dec_text(P0)}({dec_text(r / 100)})^t"})}
            wr["SL2.9.exp-model#1"] = {qr_norm(ans, {"v": f"linear: N = {dec_text(P0)} + {dec_text(P0 * r / 100)}t"})}
        else:
            m = em_read(r"holds (\d+) litres and gains (\d+) litres each hour", L[0], "the tank")
            P0, d = el_num(m.group(1)), el_num(m.group(2))
            want = qr_norm(ans, {"v": f"linear: N = {dec_text(P0)} + {dec_text(d)}t"})
            wr["SL2.1.line-model#1"] = {qr_norm(ans, {"v": f"linear: N = {dec_text(d)} + {dec_text(P0)}t"})}
    elif u == "next-values":
        v0, v1 = [el_num(x) for x in em_read(r"are (\d+(?:\.\d+)?) and (\d+(?:\.\d+)?)\.", L[0], "the values").groups()]
        want = qr_norm(ans, {"v0": str(2 * v1 - v0), "v1": str(v1 ** 2 / v0)})
    elif u == "interpret-d-and-r":
        Q0, d, P0, a = gp_models(L)
        want = qr_norm(ans, {"v": f"each step L gains {dec_text(d)} and E is multiplied by {dec_text(a)}"})
        wr["SL2.1.line-model#0"] = {qr_norm(ans, {"v": f"L gains {dec_text(d)} in total and E is multiplied by {dec_text(a)} each step"})}
    elif u == "when-overtakes":
        Q0, d, P0, a = gp_models(L)
        E = lambda t: P0 * a ** t
        Lf = lambda t: Q0 + d * t
        n = next(t for t in range(0, 60) if all(E(k) > Lf(k) for k in range(t, t + 40)))
        need(3 <= n <= 25 and Q0 > P0, "the overtaking is out of range")
        neg = sp.nsolve(P0 * a ** X - Q0 - d * X, X, -5)
        need(neg < 0, "no crossing before the start")
        want = qr_norm(ans, {"v": str(n)})
        wr["SL2.1.line-model#2"] = {qr_norm(ans, {"v": str(int(sp.floor(neg + sp.Rational(1, 2))))})}
        if rep == "table":
            rows = {r_[0]: r_[1] for r_ in q["table"]["rows"]}
            for t_, lv, ev in zip(rows["t"], rows["L(t)"], rows["E(t)"]):
                need(el_num(lv) == Lf(int(t_)) and abs(float(el_num(ev)) - float(E(int(t_)))) <= 0.006, f"the table at t = {t_} is wrong")
    else:
        raise Fail(f"the checker has no solver for {u}")
    qr_check_common(q, want, wr)
    return None, None


# ── fn-link-multiplicative-growth ──
# The clean limits, the checker's own copy of game/engine/situations/link_growth.gd's.

LG_STARTS = {1000, 2000, 5000, 8000, 12000, 20000}
LG_RATES = {2, 4, 5, 8, 10, 12, 15, 20, 25}


def check_link_growth(q):
    g, ans, u, rep, L, asked = q["given"], q["answer"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    Lj = " ".join(L)
    need(R(g["P0"]) in LG_STARTS and int(g["r"]) in LG_RATES, "not a clean start or rate")
    wr = {}
    m3 = lambda x: (need(not on_edge(abs(num(x))), f"{u}: {num(x)} is on a rounding edge"), el_m(x))[1]
    T = "fn-link-multiplicative-growth"
    if u == "percent-to-factor":
        m = em_read(r"A value (rises|falls) by (\d+)% a year\.", L[0], "the rate")
        r = int(m.group(2))
        f = 1 + sp.Rational(r, 100) * (1 if m.group(1) == "rises" else -1)
        say = lambda v: f"r = {dec_text(v)}: the graph {'rises' if v > 1 else 'falls'}"
        want = qr_norm(ans, {"v": say(f)})
        wr["SL2.9.exp-model#0"] = {qr_norm(ans, {"v": say(sp.Rational(r, 100))})}
        if f < 1:
            wr["SL1.3.model#1"] = {qr_norm(ans, {"v": say(1 + sp.Rational(r, 100))})}
    elif u in ("sequence-vs-function", "depreciation-two-ways", "compounding-factor"):
        n = int(em_read(r"after (\d+) years", asked, "the years").group(1))
        if u == "sequence-vs-function":
            m = re.search(r"V\(t\) = (\d+)\(([\d.]+)\)\^t", Lj)
            if m:
                P0, f = el_num(m.group(1)), el_num(m.group(2))
            else:
                m = em_read(r"An investment of (\d+) (rises|falls) by (\d+)% a year\.", Lj, "the investment")
                P0, f = el_num(m.group(1)), 1 + sp.Rational(int(m.group(3)), 100) * (1 if m.group(2) == "rises" else -1)
            want = m3(P0 * f ** n)
            wr["SL2.9.exp-model#1"] = {el_m(P0 * f * n)}
            wr["SL2.9.exp-model#2"] = wr["SL1.3.model#2"] = {el_m(P0 * f ** (n - 1))}
            wr["SL1.3.nth-term#0"] = {el_m(P0 * f ** (n + 1))}
        elif u == "depreciation-two-ways":
            m = em_read(r"bought for (\d+) loses (\d+)% of its value each year", Lj, "the machine")
            P0, r = el_num(m.group(1)), sp.Rational(int(m.group(2)), 100)
            if rep == "table":
                vals = [el_num(v) for v in q["table"]["rows"][1][1]]
                need(vals == [P0, P0 * (1 - r), P0 * (1 - r) ** 2], "the table is not the machine's values")
            want = m3(P0 * (1 - r) ** n)
            wr["SL1.4.depreciation#1"] = wr["SL1.3.model#1"] = {el_m(P0 * (1 - r * n))}
            wr["SL1.4.depreciation#0"] = {el_m(P0 * (1 + r) ** n), el_m(P0 * r ** n)}
        else:
            m = em_read(r"(\d+) is invested at (\d+)% a year, compounded (half-yearly|quarterly|monthly)\.", Lj, "the investment")
            P0, R_ = el_num(m.group(1)), sp.Rational(int(m.group(2)), 100)
            k = {"half-yearly": 2, "quarterly": 4, "monthly": 12}[m.group(3)]
            want = m3(P0 * (1 + R_ / k) ** (k * n))
            wr["SL1.4.future-value#0"] = {el_m(P0 * (1 + R_) ** (k * n))}
            wr["SL1.4.future-value#1"] = {el_m(P0 * (1 + R_ * n))}
    elif u == "first-below":
        Tv = el_num(em_read(r"below (\d+)\.", asked, "the threshold").group(1))
        if rep == "words":
            m = em_read(r"bought for (\d+) loses (\d+)% of its value each year", Lj, "the car")
            P0, f = el_num(m.group(1)), 1 - sp.Rational(int(m.group(2)), 100)
        elif rep == "table":
            P0, f = R(g["P0"]), 1 - sp.Rational(int(em_read(r"falls by (\d+)% a year", Lj, "the rate").group(1)), 100)
            for t_, v_ in zip(q["table"]["rows"][0][1], q["table"]["rows"][1][1]):
                need(sig3(P0 * f ** int(t_), 6) == v_.replace("−", "-") or abs(float(el_num(v_)) - float(P0 * f ** int(t_))) < 0.01, f"the table at n = {t_} is wrong")
        else:
            m = em_read(r"V\(n\) = (\d+)\(([\d.]+)\)\^n", Lj, "the model")
            P0, f = el_num(m.group(1)), el_num(m.group(2))
        nx = sp.log(Tv / P0) / sp.log(f)
        frac = num(nx) - sp.floor(num(nx))
        need(sp.Rational(1, 10) <= frac <= sp.Rational(9, 10), "the crossing is too near a whole year")
        want = qr_norm(ans, {"v": str(int(sp.ceiling(num(nx))))})
    elif u == "factor-from-two-values":
        if rep == "table":
            (t1, t2), (V1, V2) = [int(x) for x in q["table"]["rows"][0][1]], [el_num(x) for x in q["table"]["rows"][1][1]]
        else:
            m = em_read(r"is (\d+(?:\.\d+)?) after (\d+) years and (\d+(?:\.\d+)?) after (\d+) years", Lj, "the values")
            V1, t1, V2, t2 = el_num(m.group(1)), int(m.group(2)), el_num(m.group(3)), int(m.group(4))
        f = sp.nsimplify((V2 / V1) ** sp.Rational(1, t2 - t1))
        need(f.is_rational, "the factor is not exact")
        want = qr_norm(ans, {"v0": str(f), "v1": str((f - 1) * 100)})
    elif u == "graph-from-factor":
        m = em_read(r"y = (\d+)\(([\d.]+)\)\^x", asked, "the function")
        P0, f = el_num(m.group(1)), el_num(m.group(2))
        if f > 1:
            right = f"starts at (0, {frac_text(P0)}) and rises, with y = 0 as its asymptote on the left"
        else:
            right = f"starts at (0, {frac_text(P0)}) and falls towards y = 0"
            wr["SL2.9.exp-graph#2"] = {qr_norm(ans, {"v": f"starts at (0, −{frac_text(P0)}) and falls, the growth graph reflected in the x-axis"})}
        if rep == "graph":
            for x0, y0 in q["graph"]["curves"][0][::16]:
                need(abs(float(P0 * f ** sp.Float(x0, 30)) - y0) <= 1e-6 * max(1, abs(y0)), "the curve is not the function")
        want = qr_norm(ans, {"v": right})
    elif u == "sum-to-infinity-link":
        if rep == "words":
            qv = el_num(em_read(r"common ratio (−?\d+(?:\.\d+)?(?:/\d+)?)\.$", L[0], "the ratio").group(1))
        else:
            parts = re.findall(r"([+−]?) ?(\d+(?:/\d+)?)", L[0])
            vals = [el_num(n_) * (-1 if s_ == "−" else 1) for s_, n_ in parts]
            need(len(vals) == 3 and vals[0] == 8, "can't read the series")
            qv = vals[1] / vals[0]
            need(vals[2] == vals[1] * qv, "the series is not geometric")
        conv = abs(qv) < 1
        want = qr_norm(ans, {"v": "yes: |r| < 1, so r^n dies away to 0" if conv else "no: |r| ≥ 1, so r^n does not die away"})
        if not conv and qv < 1 and qv != -1:
            wr["SL1.8.convergence#0"] = {qr_norm(ans, {"v": "yes: r < 1 is enough"})}
        if abs(qv) == 1:
            wr["SL1.8.convergence#2"] = {qr_norm(ans, {"v": "yes: |r| ≤ 1 is enough"})}
    elif u == "continuous-factor":
        kc = el_num(em_read(r"e\^\((−?[\d.]+)t\)", L[0], "k").group(1))
        e = sp.exp(kc)
        m3(e), m3((e - 1) * 100)
        want = (ext_sf(e), ext_sf((e - 1) * 100))
    else:
        raise Fail(f"the checker has no solver for {u}")
    qr_check_common(q, want, wr)
    return None, None


# ── Graphs and key features (FAL-420): gdc-curve ──────────────
# One awkward curve on a closed domain. Its function and domain are read back from the
# question's text, and every feature is found again with mpmath to 30 digits: zeros
# from sign changes on a fine grid closed in by findroot, turning points as zeros of
# the derivative SymPy takes. Answers are compared as the game writes them, to 3 s.f.
# (an exact value too: 2.5 is "2.50"). The clean limits are the checker's own copy:
# the engine's are in game/engine/situations/gdc_curve.gd.

GC_ZEROS = (1, 3)
GC_TURNS = (1, 2)
GC_SEP = sp.Rational(1, 2)          # features at least this far apart in x
GC_Y_SPAN = 20                      # the whole graph fits a window about 20 high
GC_SLOPE = sp.Rational(1, 4)        # each zero a clean crossing
GC_TOL = sp.Rational(1, 10**7)      # the engine keeps nine decimal places
GC_GRID = 800
GC_SIT, GC_ZI, GC_MM, GC_NS, GC_SG = ("SL2.3.sketch-from-equation", "SL2.4.zeros-intercepts", "SL2.4.max-min",
                                      "SL2.10.number-of-solutions", "SL2.10.solve-gdc")
GC_LOCALS = {"x": X, "exp": sp.exp, "log": sp.log, "sin": sp.sin, "cos": sp.cos}


def gc_expr(text):
    """The game's way of writing a function, as SymPy: '2e^(0.5x) − 3x − 1'."""
    t = text.replace("−", "-").replace("e^(", "exp(").replace("ln(", "log(")
    t = t.replace("x³", "x**3").replace("x²", "x**2").replace(")²", ")**2").replace("^", "**")
    # x·e^(…) is written xe^(…): keep the parser from reading "xexp" as one name.
    t = re.sub(r"([x)])exp\(", r"\1*exp(", t)
    need(re.fullmatch(r"[0-9x+\-*/(). a-z]+", t) is not None, f"can't read the function {text!r}")
    return sp.nsimplify(parse_expr(t, transformations=TRANSFORMS, local_dict=GC_LOCALS), rational=True)


def gc_read(q):
    """(f, d1, d2, open_left) from the first 'f(x) = …, for d1 ≤ x ≤ d2' the question says."""
    for t in [q["asked"]] + q["lines"]:
        m = re.search(r"f\(x\) = (.+?),? (?:for|on) (−?\d+) (<|≤) x ≤ (−?\d+)", t)
        if m:
            return gc_expr(m.group(1)), el_num(m.group(2)), el_num(m.group(4)), m.group(3) == "<"
    raise Fail("can't find f(x) and its domain in the question")


def gc_f(fn):
    return sp.lambdify(X, fn, "mpmath")


def gc_zeros(fn, a, b):
    """Every zero of fn on [a, b]: a sign change on a fine float grid, then refined to
    30 digits with mpmath."""
    fl = sp.lambdify(X, fn, "math")
    f = gc_f(fn)
    mpmath.mp.dps = 30
    a, b = float(a), float(b)
    out = []
    xs = [a + (b - a) * i / GC_GRID for i in range(GC_GRID + 1)]
    ys = []
    for x in xs:
        try:
            ys.append(fl(x))
        except (ValueError, ZeroDivisionError, OverflowError):
            ys.append(float("nan"))
    for i in range(GC_GRID):
        y0, y1 = ys[i], ys[i + 1]
        if y0 == 0:
            out.append(mpmath.mpf(xs[i]))
        elif y0 * y1 < 0:
            out.append(mpmath.findroot(f, (mpmath.mpf(xs[i]), mpmath.mpf(xs[i + 1])), solver="anderson"))
    if ys[-1] == 0:
        out.append(mpmath.mpf(xs[-1]))
    return out


@lru_cache(maxsize=4096)
def gc_features(fn, d1, d2, open_left):
    """zeros, turns [(x, y, 'max'|'min')], ends [(x, y)] of fn on its domain."""
    lo = d1 + sp.Rational(1, 1000) if open_left else d1
    f = gc_f(fn)
    df = sp.diff(fn, X)
    zs = gc_zeros(fn, lo, d2)
    turns = []
    for t in gc_zeros(df, lo, d2):
        if t <= lo or t >= d2:
            continue
        s = gc_f(sp.diff(df, X))(t)
        need(s != 0, "a stationary point that doesn't turn")
        turns.append((t, f(t), "max" if s < 0 else "min"))
    ends = [] if open_left else [(mpmath.mpf(d1), f(mpmath.mpf(d1)))]
    ends.append((mpmath.mpf(d2), f(mpmath.mpf(d2))))
    return tuple(zs), tuple(turns), tuple(ends)


def gc_s(x):
    """x to 3 s.f., as the game writes it (0 is "0", and so is a GDC zero below 1e−9:
    the engine keeps nine decimal places)."""
    if x == 0 or abs(x) < sp.Rational(1, 10**9):
        return "0"
    return ext_sf(sp.Float(x, 30)) if not isinstance(x, sp.Rational) else ext_sf(x)


def gc_rounds(x):
    """Whether x needs rounding at 3 s.f. (an exact 2.5 doesn't)."""
    return not (isinstance(x, sp.Rational) and sp.Rational(sig3(x)) == x) and x != 0


def gc_s2(x):
    """x as the rounding trap writes it: to 2 s.f. as a decimal, or exact if it needs no rounding."""
    if not gc_rounds(x):
        return dec_text(R(x))
    return dec_text(sp.Rational(sig3(sp.Float(x, 30) if not isinstance(x, sp.Rational) else x, 2)))


def gc_trap(vals, text):
    """The rounding trap's text, or None when no value needs rounding."""
    return text if any(gc_rounds(v) for v in vals) else None


def gc_xs2(xs):
    names = sorted([gc_s2(x) for x in xs], key=lambda t: float(sp.Rational(t.replace("−", "-"))))
    return "x = " + (names[0] if len(names) == 1 else ", ".join(names[:-1]) + " or " + names[-1])


def gc_pt(x, y):
    return f"({gc_s(x)}, {gc_s(y)})"


def gc_xs(xs):
    names = [gc_s(x) for x in sorted(xs, key=lambda v: float(v))]
    return "x = " + (names[0] if len(names) == 1 else ", ".join(names[:-1]) + " or " + names[-1])


def gc_close(engine, true):
    return abs(num(R(engine)) - num(true)) <= GC_TOL * max(1, abs(num(true)))


def gc_fair(x):
    v = num(x)
    return not on_edge(abs(v)) and abs(v - sp.Integer(round(v))) > sp.Rational(2, 100) if v != 0 else False


def gc_clean(q, fn, d1, d2, open_left, F):
    zs, ts, ends = F
    g = q["given"]
    exact = g["fam"] in ("product", "xcubic")
    need(GC_ZEROS[0] <= len(zs) <= GC_ZEROS[1], f"{len(zs)} zeros, not 1 to 3")
    need(GC_TURNS[0] <= len(ts) <= GC_TURNS[1], f"{len(ts)} turning points, not 1 or 2")
    df = gc_f(sp.diff(fn, X))
    for z in zs:
        need(abs(df(z)) >= GC_SLOPE, f"the zero at {z} is not a clean crossing")
        need(exact or gc_fair(z), f"the zero {z} is not a fair 3 s.f. value")
    for t in ts:
        need(abs(t[1]) >= sp.Rational(2, 5), "a turning point too near the x-axis")
        need(g["fam"] == "bellform" or (gc_fair(t[0]) and gc_fair(t[1])), f"the turning point {t[:2]} is not fair to 3 s.f.")
    xs = sorted([float(z) for z in zs] + [float(t[0]) for t in ts])
    need(all(b - a >= float(GC_SEP) - 1e-9 for a, b in zip(xs, xs[1:])), "two features closer than 0.5 in x")
    ys = [t[1] for t in ts] + [e[1] for e in ends]
    if open_left:
        ys.append(gc_f(fn)(mpmath.mpf(d1) + mpmath.mpf("0.051")))
    need(max(ys) - min(ys) <= GC_Y_SPAN + sp.Rational(1, 10), "the graph is more than about 20 high")
    need(g["d1"] == str(d1) and g["d2"] == str(d2), "the domain shown is not the situation's")


def gc_pieces(fn, a, b, open_left_at=None):
    """The monotone pieces of fn on [a, b]: breakpoint values, ±inf at an asymptote end."""
    f = gc_f(fn)
    df = sp.diff(fn, X)
    xs = [mpmath.mpf(a)] + [t for t in gc_zeros(df, a, b) if mpmath.mpf(a) < t < mpmath.mpf(b)] + [mpmath.mpf(b)]
    vs = [f(x) for x in xs]
    if open_left_at is not None:
        vs[0] = -mpmath.inf if sp.limit(fn, X, open_left_at, "+") == -sp.oo else mpmath.inf
    return vs


def gc_count(vs, k):
    n = sum(1 for i in range(len(vs) - 1) if min(vs[i], vs[i + 1]) - 1e-20 <= k <= max(vs[i], vs[i + 1]) + 1e-20)
    return n - sum(1 for v in vs[1:-1] if abs(v - k) < 1e-20)


def gc_kset(vs, n):
    """The k with exactly n solutions, as one interval (lo, lo_in, hi, hi_in), or None."""
    levels = sorted({v for v in vs if mpmath.isfinite(v)})
    tests = [(levels[0] - 1, False)]
    for i, l in enumerate(levels):
        tests.append((l, True))
        tests.append((l + 1 if i == len(levels) - 1 else (l + levels[i + 1]) / 2, False))
    runs, cur = [], None
    for i, (k, at) in enumerate(tests):
        ok = gc_count(vs, k) == n
        if ok and cur is None:
            if i in (0, len(tests) - 1):
                return None
            cur = [k if at else tests[i - 1][0], at]
        elif not ok and cur is not None:
            runs.append((cur[0], cur[1], k if at else tests[i - 1][0], not at))
            cur = None
    return runs[0] if cur is None and len(runs) == 1 else None


def gc_range2(ks):
    lo, lo_in, hi, hi_in = ks
    return f"{gc_s(lo)} {'≤' if lo_in else '<'} k {'≤' if hi_in else '<'} {gc_s(hi)}"


def gc_curve_is(curve, g, tol=1e-6):
    """Whether the sampled curve [[x, y], ...] lies on y = g(x)."""
    return len(curve) > 10 and all(abs(float(g(mpmath.mpf(x))) - y) <= tol * max(1, abs(y)) for x, y in curve[::10])


def gc_cards(q, fn, d1, d2, open_left, F):
    """Pick the graph: the right card is f on its domain with every feature marked, and
    each wrong card is f with exactly the one mistake it names."""
    zs, ts, ends = F
    f = gc_f(fn)
    lo = float(d1) + (0.001 if open_left else 0)
    graphs, ch = q["graphs"], q["choices"]
    need(len(graphs) == 4 and len(ch) == 4, "pick the graph needs four graphs")
    need([o["text"] for o in ch] == ["Graph A", "Graph B", "Graph C", "Graph D"], "the graphs are not lettered A to D")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right graph")
    need(all(gr.get("card") for gr in graphs), "a graph is not drawn as a card")
    need(len({json.dumps(gr["curves"]) for gr in graphs}) == 4, "two graphs are the same")
    need(len({(gr["x0"], gr["x1"], gr["y0"], gr["y1"]) for gr in graphs}) == 1, "the cards don't share one window")
    refs = {"past-domain": GC_SIT + "#1", "squashed": GC_SIT + "#2", "through-asymptote": GC_SIT + "#0", "reflected": "", "mirrored": ""}
    t_rows = ""
    for o, gr in zip(ch, graphs):
        cs = gr["curves"]
        mk = o.get("mistake", "")
        if o["correct"]:
            need(len(cs) == 1 and gc_curve_is(cs[0], f), "the right graph is not f")
            need(abs(cs[0][0][0] - lo) < 1e-6 and abs(cs[0][-1][0] - float(d2)) < 1e-6, "the right graph doesn't stop at the domain's ends")
            dots = sorted((round(p["x"], 6), round(p["y"], 6)) for p in gr["points"])
            want = sorted([(round(float(z), 6), 0.0) for z in zs] + [(round(float(t[0]), 6), round(float(t[1]), 6)) for t in ts]
                          + [(round(float(e[0]), 6), round(float(e[1]), 6)) for e in ends])
            need(len(dots) == len(want) and all(abs(a[0] - b[0]) < 1e-5 and abs(a[1] - b[1]) < 1e-5 for a, b in zip(dots, want)),
                 "the right graph doesn't mark every zero, turning point and endpoint")
            continue
        need(mk in refs, f"a wrong graph names no mistake ({mk!r})")
        need(o["ref"] == refs[mk], f"the {mk} graph is tagged {o['ref']!r}, not {refs[mk]!r}")
        need(o.get("why", "") != "", f"the {mk} graph doesn't say what is wrong")
        if mk == "past-domain":
            need(len(cs) == 1 and gc_curve_is(cs[0], f), "the past-domain graph is not f")
            need(cs[0][-1][0] > float(d2) + 1 and (open_left or cs[0][0][0] < float(d1) - 1), "the past-domain graph stops at the domain")
            need(not any(abs(p["x"] - float(e[0])) < 1e-6 and abs(p["y"] - float(e[1])) < 1e-6 for p in gr["points"] for e in ends),
                 "the past-domain graph marks an endpoint")
        elif mk == "squashed":
            dy = min((t[1] for t in ts), key=lambda v: abs(v))
            need(len(cs) == 1 and gc_curve_is(cs[0], lambda x: f(x) - dy), "the squashed graph is not f moved so a turning point sits on the x-axis")
        elif mk == "reflected":
            need(len(cs) == 1 and gc_curve_is(cs[0], lambda x: -f(x)), "the reflected graph is not −f")
        elif mk == "mirrored":
            need(len(cs) == 1 and gc_curve_is(cs[0], lambda x: f(-x)), "the mirrored graph is not f(−x)")
        elif mk == "through-asymptote":
            need(open_left and len(cs) == 2, "the through-asymptote graph needs an asymptote and two pieces")
            left = gc_f(fn.subs(sp.log(X - d1), sp.log(-(X - d1))))
            need(gc_curve_is(cs[0], left) and cs[0][-1][0] < float(d1) and gc_curve_is(cs[1], f), "the through-asymptote graph is not f carried through x = d1")
    return next(o["text"] for o in ch if o["correct"])


def gc_check_common(q, want, wrongs, trap=None, steps=(2, 5)):
    """want: the answer's text as the game writes it, from the checker's own values.
    wrongs: ref -> the texts that misconception gives. trap: the 2 s.f. text, or None."""
    ch = q["choices"]
    need(q["answer_text"] == want, f"engine answer {q['answer_text']!r} is wrong (expected {want!r})")
    need(len(ch) == 4, f"{len(ch)} options")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right option")
    need(len({o["text"] for o in ch}) == 4, "two options read the same")
    for o in ch:
        need(o["correct"] == (o["text"] == want), f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'}")
        if o.get("trap"):
            need(trap is not None and o["text"] == trap, f"rounding trap {o['text']!r} is not the answer to 2 s.f. ({trap!r})")
        if o["ref"] and not o.get("trap"):
            need(o["ref"] in wrongs, f"the checker can't confirm {o['ref']} on {q['view']['unknown']}")
            need(o["text"] in wrongs[o["ref"]], f"option {o['text']!r} is not what {o['ref']} gives ({wrongs[o['ref']]})")
    need(len(q["solutions"]) >= 1, "no worked solution")
    for sol in q["solutions"]:
        need(steps[0] <= len(sol["steps"]) <= steps[1], f"{sol['name']}: {len(sol['steps'])} steps, not 2 to 5")
        need(q["answer_text"] in sol["steps"][-1], f"{sol['name']}: last step {sol['steps'][-1]!r} doesn't state the answer")
    if q["view"]["angle"] != "any":
        need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")


def gc_table(q, f):
    t = q["table"]
    need(t is not None, "no table")
    for xv, yv in zip(t["xs"], t["ys"]):
        need(gc_close(yv, f(mpmath.mpf(R(xv)))), f"the table's f({xv}) is wrong")
    written = [["x", [dec_text(R(v)) for v in t["xs"]]], ["f(x)", [gc_s(R(v)) for v in t["ys"]]]]
    need(t["rows"] == written, "the table's written rows are not its values to 3 s.f.")
    return [R(v) for v in t["xs"]], [R(v) for v in t["ys"]]


def check_gdc_curve(q):
    g, u, rep, L, asked = q["given"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    need(q["paper"] == 2, "a GDC curve is Paper 2")
    for t in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    if u == "constant-from-max":
        m = re.search(r"f\(x\) = (.+) \+ c, for (−?\d+) ≤ x ≤ (−?\d+), .*The local maximum value of f is (−?[\d.]+)\.", asked)
        need(m is not None, "can't read constant-from-max")
        gfn, d1, d2, M = gc_expr(m.group(1)), el_num(m.group(2)), el_num(m.group(3)), R(sp.nsimplify(m.group(4).replace("−", "-")))
        _, ts, _ = gc_features(gfn, d1, d2, False)
        mx = [t for t in ts if t[2] == "max"]
        need(len(mx) == 1, "g has no single local maximum")
        c = M - mx[0][1]
        gc_check_common(q, "c = " + gc_s(c), {}, gc_trap([c], "c = " + gc_s2(c)))
        return None, None
    if u == "solve-as-zeros":
        m = re.fullmatch(r"(.+) = (−?[\d.]+)", L[0])
        need(m is not None, "can't read the equation")
        k = R(sp.nsimplify(m.group(2).replace("−", "-")))
        fn = gc_expr(m.group(1)) - k
        d = re.search(r"for (−?\d+) ≤ x ≤ (−?\d+)", asked)
        d1, d2, open_left = el_num(d.group(1)), el_num(d.group(2)), False
    else:
        fn, d1, d2, open_left = gc_read(q)
    F = gc_features(fn, d1, d2, open_left)
    zs, ts, ends = F
    gc_clean(q, fn, d1, d2, open_left, F)
    f = gc_f(fn)
    wr = {}
    if rep == "graph" and q.get("graph") is not None:
        need(gc_curve_is(q["graph"]["curves"][0], f), "the graph drawn is not f")
    if q["format"] == "pick-the-graph":
        if u == "sketch-from-table":
            gc_table(q, f)
        right = gc_cards(q, fn, d1, d2, open_left, F)
        # gc_cards confirmed each wrong graph's mistake, and so its misconception.
        gc_check_common(q, right, {o["ref"]: {o["text"]} for o in q["choices"] if o["ref"]})
        return None, None
    exact_x = g["fam"] in ("product", "xcubic")
    zq = [sp.nsimplify(z, [], tolerance=1e-20, rational=True) if exact_x and abs(z - round(z)) < 1e-20 else z for z in zs]
    y0 = sp.nsimplify(fn.subs(X, 0)) if d1 <= 0 <= d2 else None
    trap = None
    if u in ("label-zeros", "zeros-gdc", "zeros-with-x-factor", "solve-as-zeros"):
        want = gc_xs(zq)
        trap = gc_trap(zq, gc_xs2(zq))
        if u in ("label-zeros", "zeros-gdc") and y0 is not None:
            wr[GC_ZI + "#0"] = {gc_xs(zq[:i] + [y0] + zq[i + 1:]) for i in range(len(zq))}
        if u == "label-zeros" and g["fam"] == "product":
            wr[GC_ZI + "#1"] = {gc_xs([R(g["p"]), -R(g["q"])])}
        if u == "zeros-gdc":
            wr[GC_SG + "#0"] = {gc_xs([z for z in zq if abs(z) <= 10])}
        if u == "zeros-with-x-factor":
            need(len(zq) == 3 and 0 in zq, "x-factor mode needs three zeros, one of them 0")
            wr[GC_ZI + "#2"] = {gc_xs([z for z in zq if z != 0])}
    elif u in ("label-y-intercept", "y-intercept"):
        need(y0 is not None, "0 is not in the domain")
        want = f"(0, {gc_s(y0)})"
        trap = gc_trap([y0], f"(0, {gc_s2(y0)})")
        if u == "y-intercept":
            wr[GC_ZI + "#0"] = {f"(0, {gc_s(z)})" for z in zq}
    elif u in ("label-turning-point", "turning-point-coordinates", "extreme-value-only"):
        word = "maximum" if "local maximum" in asked else "minimum"
        t = [t for t in ts if t[2] == word[:3]]
        need(len(t) == 1, f"not one local {word}")
        tx, ty = t[0][:2]
        if g["fam"] == "bellform":
            tx, ty = R(g["h"]), R(g["A"]) + R(g["c"])
        if u == "extreme-value-only":
            want = gc_s(ty)
            trap = gc_trap([ty], gc_s2(ty))
            wr[GC_MM + "#0"] = {gc_s(tx)}
        else:
            want = gc_pt(tx, ty)
            trap = gc_trap([tx, ty], f"({gc_s2(tx)}, {gc_s2(ty)})")
            wr[GC_MM + "#0"] = {f"({gc_s(tx)}, 0)"}
            if u == "turning-point-coordinates":
                tr = [o for o in q["choices"] if o.get("trap")]
                need(all(o["ref"] == GC_MM + "#2" for o in tr), "the 2 s.f. trap doesn't log SL2.4.max-min#2")
    elif u == "endpoint-coordinates":
        want = " and ".join(gc_pt(*e) for e in ends)
        trap = gc_trap([e[1] for e in ends], " and ".join(f"({gc_s2(e[0])}, {gc_s2(e[1])})" for e in ends))
        wr[GC_SIT + "#1"] = {f"{gc_pt(d1 - 1, f(mpmath.mpf(d1 - 1)))} and {gc_pt(d2 + 1, f(mpmath.mpf(d2 + 1)))}"}
    elif u == "greatest-on-domain":
        cands = [(t[1], "turn") for t in ts] + [(e[1], "end") for e in ends]
        top = max(cands, key=lambda c_: c_[0])
        need(top[1] == "end", "the greatest value is not at an endpoint (endpoint-extreme mode)")
        mx = [t for t in ts if t[2] == "max"]
        need(mx and top[0] - mx[0][1] >= sp.Rational(1, 2), "the endpoint is not clearly above the local maximum")
        want, trap = gc_s(top[0]), gc_trap([top[0]], gc_s2(top[0]))
        wr[GC_MM + "#1"] = {gc_s(t[1]) for t in mx}
    elif u == "window-for-domain":
        def window(o):
            m_ = re.fullmatch(r"Xmin = (−?\d+), Xmax = (−?\d+), Ymin = (−?\d+), Ymax = (−?\d+)", o)
            need(m_ is not None, f"can't read the window {o!r}")
            return [el_num(v) for v in m_.groups()]
        ys = [t[1] for t in ts] + [e[1] for e in ends]
        lo_y, hi_y = min(ys), max(ys)
        good = [o["text"] for o in q["choices"] if (lambda w: w[0] == d1 and w[1] == d2 and w[2] < lo_y and w[3] > hi_y
                                                     and w[3] - w[2] <= hi_y - lo_y + 4)(window(o["text"]))]
        need(len(good) == 1, f"{len(good)} windows show the whole graph without squashing it")
        want = good[0]
        wr[GC_SIT + "#2"] = {"Xmin = −10, Xmax = 10, Ymin = −10, Ymax = 10"}
    elif u == "judge-a-sketch":
        labs = g["labels"]
        need(len(labs) == 4 and sum(1 for lb in labs if lb["bad"]) == 1, "the sketch doesn't have one wrong label among four")
        feats = {}
        for z in zs:
            feats[f"the zero at x ≈ {gc_s(z)}"] = f"({gc_s(z)}, 0)"
        for t in ts:
            feats["the local " + ("maximum" if t[2] == "max" else "minimum")] = gc_pt(t[0], t[1])
        for i, e in enumerate(ends):
            feats[f"the {['left', 'right'][i]} endpoint"] = f"({frac_text(R(sp.nsimplify(e[0])))}, {gc_s(e[1])})"
        pts = {p["label"] for p in q["graph"]["points"]}
        for lb in labs:
            need(lb["name"] in feats, f"the sketch labels {lb['name']}, which f doesn't have")
            need(lb["label"] in pts, f"the label {lb['label']} isn't drawn")
            need((lb["label"] != feats[lb["name"]]) == lb["bad"], f"the label {lb['label']} at {lb['name']} is {'right' if lb['label'] == feats[lb['name']] else 'wrong'}")
        bad = next(lb for lb in labs if lb["bad"])
        want = f"The label {bad['label']} at {bad['name']}"
    elif u == "count-solutions-from-sketch":
        touch = g["touch"]
        if touch:
            word = "max" if "local maximum" in asked else "min"
            k = next(t[1] for t in ts if t[2] == word)
        else:
            k = R(g["line_k"])
            need((k * 10).q == 1 and f"f(x) = {dec_text(k)} have" in asked, "k is not the one-place decimal asked")
        lo_open = d1 if open_left else None
        vs = gc_pieces(fn, d1 + (sp.Rational(1, 10**6) if open_left else 0), d2, lo_open)
        n = gc_count(vs, k)
        want = str(n)
        if touch:
            wr[GC_NS + "#0"] = {str(n + 1)}
        ext = gc_count(gc_pieces(fn, (d1 + sp.Rational(1, 10**6)) if open_left else d1 - 3, d2 + 3, lo_open), k)
        wr[GC_NS + "#1"] = {str(ext)}
    elif u == "k-for-count":
        lo_open = d1 if open_left else None
        ks = gc_kset(gc_pieces(fn, d1 + (sp.Rational(1, 10**6) if open_left else 0), d2, lo_open), 2)
        need(ks is not None and ks[2] - ks[0] >= sp.Rational(1, 2), "two solutions is not one interval of k")
        want = gc_range2(ks)
        trap = gc_trap([ks[0], ks[2]], f"{gc_s2(ks[0])} {'≤' if ks[1] else '<'} k {'≤' if ks[3] else '<'} {gc_s2(ks[2])}")
        ext = gc_kset(gc_pieces(fn, (d1 + sp.Rational(1, 10**6)) if open_left else d1 - 3, d2 + 3, lo_open), 2)
        if ext is not None:
            wr[GC_NS + "#1"] = {gc_range2(ext)}
    elif u == "count-zeros":
        want = str(len(zs))
        wr[GC_SG + "#0"] = {str(sum(1 for z in zs if abs(z) <= 10))}
    elif u == "zero-from-table":
        xs_, ys_ = gc_table(q, f)
        z = max(zs)
        need(sum(1 for i in range(len(ys_) - 1) if ys_[i] * ys_[i + 1] < 0) == len(zs), "the table doesn't show each zero as a sign change")
        want, trap = "x = " + gc_s(z), gc_trap([z], "x = " + gc_s2(z))
    elif u == "use-stored-zeros":
        need(len(zs) == 2, "use-stored-zeros needs two zeros")
        dz = zs[1] - zs[0]
        want, trap = gc_s(dz), gc_trap([dz], gc_s2(dz))
        r = sp.Rational(sig3(sp.Float(zs[1], 30))) - sp.Rational(sig3(sp.Float(zs[0], 30)))
        wr[GC_SG + "#1"] = {gc_s(r)}
    else:
        raise Fail(f"the checker has no gdc-curve check for {u}")
    # The engine's own answer values say the same, to its nine decimal places.
    gc_check_common(q, want, wr, trap)
    return None, None


# ── Graphs and key features (FAL-420): gdc-two-curves ─────────
# Two functions that cross one to three times. Both are read back from the question's
# text (t is read as x), and every crossing is found again as a zero of f − g with
# mpmath, its y from f at the unrounded x. The clean limits are the checker's own copy:
# the engine's are in game/engine/situations/gdc_two_curves.gd.

TC_SLOPE = sp.Rational(3, 10)       # each crossing at a clear angle
TC_IN, TC_SG = "SL2.4.intersection", "SL2.10.solve-gdc"


def tc_expr(text):
    return gc_expr(text.replace("t", "x"))


def tc_read(q):
    """(f, g, lo, hi, open_left) from the question's text."""
    texts = [q["asked"]] + q["lines"]
    joined = " ".join(texts)
    pats = [r"f\(x\) = (.+?),? and (?:its inverse f⁻¹\(x\)|g\(x\)) = (.+?), for ",
            r"A\(t\) = (.+?) m, and in tank B is B\(t\) = (.+?) m, ",
            r"P\(t\) = (.+?) and Q\(t\) = (.+?) thousand people, ",
            r"^Solve (.+?) = (.+?), for "]
    for p in pats:
        m = re.search(p, joined)
        if m:
            f, g = tc_expr(m.group(1)), tc_expr(m.group(2))
            break
    else:
        raise Fail("can't read the two functions")
    d = re.search(r"for (−?\d+) ≤ [xt] ≤ (−?\d+)", joined)
    if d:
        return f, g, el_num(d.group(1)), el_num(d.group(2)), False
    d = re.search(r"for x > (−?[\d.]+)", joined)
    need(d is not None, "can't read the domain")
    return f, g, R(sp.nsimplify(d.group(1).replace("−", "-"))), None, True


@lru_cache(maxsize=4096)
def gc_exact_point(f, x):
    """A crossing as (x, y). The checker finds x numerically, so both would come out as
    30-digit floats, and a float always "needs rounding". The game keeps a designed crossing
    exact (x = 2.5, y = −5.75, which needs none at 3 s.f.), so when x is a rational root
    (to 20 places) and f(x) is rational, both are returned as Rationals."""
    q = sp.Rational(int(mpmath.nint(x * 10**6)), 10**6)
    if abs(x - mpmath.mpf(q.p) / q.q) < mpmath.mpf(10) ** -20:
        y = f.subs(X, q)
        if y.is_Rational:
            return q, y
    return x, gc_f(f)(x)


def tc_crossings(f, g, lo, hi, open_left):
    a = lo + sp.Rational(1, 1000) if open_left else lo
    return tuple(gc_exact_point(f, x) for x in gc_zeros(f - g, a, hi))


def tc_pts(cs):
    names = [gc_pt(x, y) for x, y in sorted(cs, key=lambda c: float(c[0]))]
    return names[0] if len(names) == 1 else ", ".join(names[:-1]) + " and " + names[-1]


def tc_pts2(cs):
    names = [f"({gc_s2(x)}, {gc_s2(y)})" for x, y in sorted(cs, key=lambda c: float(c[0]))]
    return names[0] if len(names) == 1 else ", ".join(names[:-1]) + " and " + names[-1]


def tc_only_x(cs):
    names = [gc_s(x) for x, _ in sorted(cs, key=lambda c: float(c[0]))]
    return "x = " + (names[0] if len(names) == 1 else ", ".join(names[:-1]) + " and x = " + names[-1])


def tc_window(cs):
    return [c for c in cs if abs(c[0]) <= 10 and abs(c[1]) <= 10]


# fn-concept-solutions-as-intersections (FAL-420): solutions as meeting points, on the
# gdc-two-curves situation. The curves are read back and every crossing found again; a
# cubic's count of solutions of f(x) = k comes from its exact turning values.

def tc_concept(q):
    u, rep, asked, L = q["view"]["unknown"], q["view"]["rep"], q["asked"], q["lines"]
    j = " ".join([asked] + L)
    for t in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    m = re.search(r"The sketch shows y = (.+?), with turning points \((−?\d+), (−?\d+)\) and \((−?\d+), (−?\d+)\)\.", j)
    if m:
        need(q["paper"] == 1, "the cubic's count is Paper 1")
        f = gc_expr(m.group(1))
        ts = sorted(sp.solve(sp.diff(f, X), X))
        need([(t, f.subs(X, t)) for t in ts] == [(el_num(m.group(2)), el_num(m.group(3))), (el_num(m.group(4)), el_num(m.group(5)))],
             "the turning points shown are not the cubic's")
        lo_v, hi_v = sorted([f.subs(X, t) for t in ts])
        if u == "k-for-count":
            gc_check_common(q, f"{frac_text(lo_v)} < k < {frac_text(hi_v)}", {"SL2.10.number-of-solutions#0": {f"{frac_text(lo_v)} ≤ k ≤ {frac_text(hi_v)}"}})
            return None, None
        k = el_num(re.search(r"= (−?\d+) have\?", asked).group(1))
        n = len(set(sp.real_roots(sp.Poly(f - k, X))))
        wr = {"SL2.10.number-of-solutions#0": {"3"}} if n == 2 else {}
        gc_check_common(q, str(n), wr)
        return None, None
    need(q["paper"] == 2, "two GDC curves are Paper 2")
    pats = [r"To solve (.+?) = (.+?) with a GDC", r"The sketch shows y = (.+?) and y = (.+?) for ", r"graph(?:s of|s)? y = (.+?) and y = (.+?)(?:;| meet)",
            r"Equation A: (.+?) = (.+?)\.  Equation B", r"Solving (.+?) = (.+?) is the same", r"f\(x\) = (.+?) and g\(x\) = (.+?), for "]
    for p in pats:
        m = re.search(p, j)
        if m:
            break
    need(m is not None, "can't read the two functions")
    f, g = gc_expr(m.group(1)), gc_expr(m.group(2))
    d1, d2 = el_num(q["given"]["d1"]), el_num(q["given"]["d2"])
    cs = tc_crossings(f, g, d1, d2, False)
    need(all(gc_fair(x) and gc_fair(y) for x, y in cs), "a crossing is not a fair 3 s.f. value")
    right = next(o for o in q["choices"] if o["correct"])
    if u == "graphs-for-equation":
        need("read the x-coordinates where they meet" in right["text"], "the right plan doesn't read the x-coordinates")
        gc_check_common(q, right["text"], {})
    elif u == "count-from-sketch":
        wr = {}
        if [c for c in cs if abs(c[0]) <= 10 and abs(c[1]) <= 10] != list(cs):
            wr["SL2.10.solve-gdc#0"] = {str(len([c for c in cs if abs(c[0]) <= 10 and abs(c[1]) <= 10]))}
        gc_check_common(q, str(len(cs)), wr)
    elif u == "x-not-y":
        need(len(cs) == 2, "not two meeting points")
        want = f"x = {gc_s(cs[0][0])} and x = {gc_s(cs[1][0])}"
        pts = f"({gc_s(cs[0][0])}, {gc_s(cs[0][1])}) and ({gc_s(cs[1][0])}, {gc_s(cs[1][1])})"
        need(pts in j, "the meeting points said are not the curves'")
        gc_check_common(q, want, {"SL2.4.intersection#0": {pts, f"y = {gc_s(cs[0][1])} and y = {gc_s(cs[1][1])}"}})
    elif u == "difference-picture":
        ff, gg = gc_f(f), gc_f(g)
        mk = {"sum": lambda x: ff(x) + gg(x), "lifted": lambda x: ff(x) - gg(x) + 2, "f-alone": ff}
        for o, gr in zip(q["choices"], q["graphs"]):
            fn = (lambda x: ff(x) - gg(x)) if o["correct"] else mk[o["mistake"]]
            need(gc_curve_is(gr["curves"][0], fn), f"the {o.get('mistake') or 'right'} graph is not what it says")
        gc_check_common(q, right["text"], {})
    elif u == "same-solutions-after-rearranging":
        need(right["text"].startswith("Yes: B is A with"), "the right option doesn't say they have the same solutions")
        gc_check_common(q, right["text"], {})
    else:
        raise Fail(f"no check for {u}")
    return None, None


def check_gdc_two_curves(q):
    if q["view"]["type"] == "fn-concept-solutions-as-intersections":
        return tc_concept(q)
    g_, u, rep, L, asked = q["given"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    need(q["paper"] == 2, "two GDC curves are Paper 2")
    for t in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    if u == "constant-from-crossing":
        m = re.search(r"line y = (.+?) \+ k meets the curve y = (.+?) where x = 0\.", " ".join(L)) or \
            re.search(r"line with gradient (−?[\d.]+) passes through the point where the curve y = (.+?) crosses the y-axis\.", " ".join(L))
        need(m is not None, "can't read the line and the curve")
        mtext = m.group(1)
        mm = R(sp.nsimplify(mtext.replace("−", "-").replace("x", "") or "1")) if mtext not in ("x", "−x") else (1 if mtext == "x" else -1)
        f = gc_expr(m.group(2))
        k = sp.nsimplify(f.subs(X, 0))
        need(k.is_rational, "f(0) is not exact")
        g = mm * X + k
        d1, d2 = el_num(g_["d1"]), el_num(g_["d2"])
        cs = tc_crossings(f, g, d1, d2, False)
        others = [c for c in cs if abs(c[0]) > 1e-20]
        need(len(cs) == 2 and len(others) == 1, "the line doesn't meet the curve once more")
        need(gc_fair(others[0][0]), "the other crossing is not a fair 3 s.f. value")
        want = f"k = {gc_s(k)}, x = {gc_s(others[0][0])}"
        gc_check_common(q, want, {}, gc_trap([k, others[0][0]], f"k = {gc_s2(k)}, x = {gc_s2(others[0][0])}"))
        return None, None
    f, g, lo, hi, open_left = tc_read(q)
    if hi is None:
        hi = el_num(g_["d2"])
    cs = tc_crossings(f, g, lo, hi, open_left)
    need(1 <= len(cs) <= 3, f"{len(cs)} crossings, not 1 to 3")
    df = gc_f(sp.diff(f - g, X))
    for i, (x, y) in enumerate(cs):
        need(abs(df(x)) >= TC_SLOPE, f"the crossing at x = {x} is near a tangent")
        need(gc_fair(x) and gc_fair(y), f"the crossing ({x}, {y}) is not fair to 3 s.f.")
        need(x - lo >= sp.Rational(1, 5) and hi - x >= sp.Rational(1, 5), "a crossing at the end of the domain")
        if i:
            need(x - cs[i - 1][0] >= GC_SEP, "two crossings closer than 0.5")
    if open_left:
        # f⁻¹ really is the inverse: f(f⁻¹(x)) = x.
        ff, gg = gc_f(f), gc_f(g)
        for x0 in [lo + 1, lo + 2, hi]:
            need(abs(ff(gg(mpmath.mpf(x0))) - x0) < 1e-20, "f⁻¹ is not the inverse of f")
    if rep == "graph" and q.get("graph") is not None:
        need(gc_curve_is(q["graph"]["curves"][0], gc_f(f)) and gc_curve_is(q["graph"]["curves"][1], gc_f(g)), "the graphs drawn are not f and g")
    wr, trap = {}, None
    if u in ("intersection-points", "function-and-inverse"):
        want, trap = tc_pts(cs), tc_pts2(cs)
        wr[TC_IN + "#0"] = {tc_only_x(cs)}
        if u == "intersection-points" and tc_window(cs):
            wr[TC_IN + "#1"] = {tc_pts(tc_window(cs))}
        if u == "function-and-inverse":
            need(all(abs(x - y) < 1e-20 for x, y in cs), "f and f⁻¹ meet off y = x")
    elif u == "solve-f-equals-g":
        want, trap = gc_xs([c[0] for c in cs]), gc_xs2([c[0] for c in cs])
        if tc_window(cs):
            wr[TC_SG + "#0"] = {gc_xs([c[0] for c in tc_window(cs)])}
    elif u == "models-equal":
        need(lo == 0 and all(gc_f(fn)(mpmath.mpf(0)) >= 0 for fn in (f, g)), "a model starts below 0")
        if len(cs) == 2:
            # Two towns that meet twice, the second time past the standard window's t = 10.
            need(cs[0][0] < 9 and cs[1][0] > sp.Rational(103, 10), "the second meeting is not past t = 10")
            want, trap = gc_xs([c[0] for c in cs]).replace("x = ", "t = "), gc_xs2([c[0] for c in cs]).replace("x = ", "t = ")
            wr[TC_SG + "#0"] = {"t = " + gc_s(cs[0][0])}
        else:
            need(len(cs) == 1, "the models don't meet once for t ≥ 0")
            want, trap = "t = " + gc_s(cs[0][0]), "t = " + gc_s2(cs[0][0])
            need(all(o["ref"] == TC_SG + "#1" for o in q["choices"] if o.get("trap")), "the 2 s.f. time doesn't log SL2.10.solve-gdc#1")
    elif u == "distance-between-crossings":
        need(len(cs) == 2, "not two crossings")
        (x1, y1), (x2, y2) = cs
        d = mpmath.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
        want, trap = gc_s(d), gc_s2(d)
        rr = [sp.Rational(sig3(sp.Float(v, 30))) for v in (x1, y1, x2, y2)]
        wr[TC_IN + "#2"] = {gc_s(sp.N(sp.sqrt((rr[2] - rr[0]) ** 2 + (rr[3] - rr[1]) ** 2), 30))}
    elif u == "count-crossings":
        want = str(len(cs))
        wr[TC_IN + "#1"] = {str(len(tc_window(cs)))}
    elif u == "crossing-in-interval":
        m = re.search(r"for (−?[\d.]+) < x < (−?[\d.]+)\.", asked)
        a, b = [R(sp.nsimplify(v.replace("−", "-"))) for v in m.groups()]
        inside = [c for c in cs if a < c[0] < b]
        need(len(inside) == 1, f"{len(inside)} crossings in the interval")
        want, trap = gc_pt(*inside[0]), f"({gc_s2(inside[0][0])}, {gc_s2(inside[0][1])})"
    elif u == "crossing-from-table":
        t = q["table"]
        ff, gg = gc_f(f), gc_f(g)
        for xv, fv, gv in zip(t["xs"], t["fs"], t["gs"]):
            need(gc_close(fv, ff(mpmath.mpf(R(xv)))) and gc_close(gv, gg(mpmath.mpf(R(xv)))), f"the table is wrong at x = {xv}")
        hs = [R(fv) - R(gv) for fv, gv in zip(t["fs"], t["gs"])]
        need(sum(1 for i in range(len(hs) - 1) if hs[i] * hs[i + 1] < 0) == len(cs), "the table doesn't show each crossing as a sign change")
        want, trap = "x = " + gc_s(cs[-1][0]), "x = " + gc_s2(cs[-1][0])
    else:
        raise Fail(f"the checker has no gdc-two-curves check for {u}")
    gc_check_common(q, want, wr, trap)
    return None, None


# ── Graphs and key features (FAL-420): gdc-combined ───────────
# Two models and a function made from them: D(t) (how far one is ahead), the distance
# d(x) from a point to a curve, or the sum f + g. The models are read back from the
# question's text; D's maximum, d's minimum and the zeros are found again with mpmath.

CB_MM, CB_SD, CB_CA = "SL2.4.max-min", "SL2.3.sum-difference", "SL2.10.context-apply"


def cb_read(q):
    """(kind, f, g, lo, hi, P): kind 'towns', 'drugs', 'distance' or 'sum'; D = Q − P for
    towns and A − B for drugs."""
    j = " ".join([q["asked"]] + q["lines"])
    m = re.search(r"P\(t\) = (.+?)(?: thousand people)?,? and (?:town Q has |town Q, )?Q\(t\) = (.+?)(?: thousand people|, in thousands)?, .*?(?:for 0 ≤ t ≤ (\d+)|t years after 2020)", j)
    if m and "P(t)" in j:
        f, g = tc_expr(m.group(1)), tc_expr(m.group(2))
        d = re.search(r"for 0 ≤ t ≤ (\d+)", j)
        return "towns", f, g, sp.Integer(0), el_num(d.group(1)) if d else el_num(q["given"]["d2"]), None
    m = re.search(r"A\(t\) = (.+?) and B\(t\) = (.+?)(?: mg/l)?, .*?for 0 ≤ t ≤ (\d+)", j)
    if m:
        return "drugs", tc_expr(m.group(1)), tc_expr(m.group(2)), sp.Integer(0), el_num(m.group(3)), None
    m = re.search(r"f\(x\) = (.+?), for (−?\d+) ≤ x ≤ (−?\d+), and the point P\((−?\d+), (−?\d+)\)", j)
    if m:
        return "distance", gc_expr(m.group(1)), None, el_num(m.group(2)), el_num(m.group(3)), (el_num(m.group(4)), el_num(m.group(5)))
    m = re.search(r"f\(x\) = (.+?) and g\(x\) = (.+?), for (−?\d+) ≤ x ≤ (−?\d+)", j)
    need(m is not None, "can't read the models")
    return "sum", gc_expr(m.group(1)), gc_expr(m.group(2)), el_num(m.group(3)), el_num(m.group(4)), None


def cb_extreme(h, lo, hi, want):
    """The one interior max (or min) of h, which beats both ends: (x, h(x))."""
    fh = gc_f(h)
    ts = [t for t in gc_zeros(sp.diff(h, X), lo, hi) if mpmath.mpf(lo) < t < mpmath.mpf(hi)]
    d2 = gc_f(sp.diff(h, X, 2))
    ext = [t for t in ts if (d2(t) < 0) == (want == "max")]
    need(len(ext) == 1, f"not one interior {want}")
    x = ext[0]
    for e in (lo, hi):
        v = fh(mpmath.mpf(e))
        need(v < fh(x) if want == "max" else v > fh(x), f"the {want} is at an end of the domain")
    return x, fh(x)


def check_gdc_combined(q):
    u, rep, asked = q["view"]["unknown"], q["view"]["rep"], q["asked"]
    need(q["paper"] == 2, "a combined GDC function is Paper 2")
    for t in [asked] + q["lines"] + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    kind, f, g, lo, hi, P = cb_read(q)
    wr, trap = {}, None
    D = (g - f) if kind == "towns" else (f - g) if kind == "drugs" else None
    if u == "form-difference":
        right = [o for o in q["choices"] if sp.simplify(tc_expr(o["text"].split(" = ", 1)[1]) - D) == 0]
        need(len(right) == 1 and right[0]["correct"], "not exactly one option is D(t) the right way round")
        gc_check_common(q, right[0]["text"], {})
        return None, None
    if u in ("max-difference", "interpret-extreme"):
        x, y = cb_extreme(D, lo, hi, "max")
        need(abs(y) >= 1 and gc_fair(x) and gc_fair(y), "the greatest difference is not a fair 3 s.f. value")
        if u == "interpret-extreme":
            need(f"maximum point at ({gc_s(x)}, {gc_s(y)})" in asked, "the maximum point asked is not D's")
            right = next(o for o in q["choices"] if o["correct"])
            need("furthest" in right["text"] and gc_s(x) in right["text"], "the right option doesn't say the time of the greatest lead")
            for o in q["choices"]:
                if o["ref"] == CB_CA + "#2":
                    need(gc_s(y) in o["text"] and "greatest" in o["text"], "CA#2 doesn't give the size of the lead")
            gc_check_common(q, right["text"], {CB_CA + "#2": {o["text"] for o in q["choices"] if o["ref"] == CB_CA + "#2"}})
            return None, None
        want, trap = f"t = {gc_s(x)}, D = {gc_s(y)}", f"t = {gc_s2(x)}, D = {gc_s2(y)}"
        wr[CB_MM + "#0"] = {f"t = {gc_s(y)}, D = {gc_s(x)}"}
        if kind == "drugs":
            k = -sp.Poly(sp.log(f / X).expand(force=True), X).all_coeffs()[0]
            tA = 1 / k
            wr[CB_SD + "#2"] = {f"t = {gc_s(tA)}, D = {gc_s(gc_f(D)(mpmath.mpf(tA)))}"}
    elif u == "difference-zero":
        zs = gc_zeros(D, lo, hi)
        need(len(zs) == 1, "D is not zero once in the domain")
        before = gc_zeros(D, -20, 0)
        need(len(before) == 1, "D has no one zero before t = 0")
        want, trap = "t = " + gc_s(zs[0]), "t = " + gc_s2(zs[0])
        wr[CB_CA + "#1"] = {f"t = {gc_s(before[0])} or {gc_s(zs[0])}"}
    elif u in ("least-distance", "closest-point"):
        d = sp.sqrt((X - P[0]) ** 2 + (f - P[1]) ** 2)
        x, dm = cb_extreme(d, lo, hi, "min")
        y = gc_f(f)(x)
        if u == "least-distance":
            want, trap = gc_s(dm), gc_s2(dm)
            wr[CB_MM + "#0"] = {gc_s(x)}
            need(all(o["ref"] == CB_MM + "#2" for o in q["choices"] if o.get("trap")), "the 2 s.f. distance doesn't log SL2.4.max-min#2")
        else:
            want, trap = gc_pt(x, y), f"({gc_s2(x)}, {gc_s2(y)})"
    elif u == "sum-graph":
        S_ = gc_f(f + g)
        ff, gg = gc_f(f), gc_f(g)
        mk = {"sideways": (CB_SD + "#0", lambda x: ff(x + gg(x))), "difference": ("", lambda x: ff(x) - gg(x)),
              "constant-lift": ("", lambda x: ff(x) + gg(mpmath.mpf(0)))}
        ch, graphs = q["choices"], q["graphs"]
        need(len(graphs) == 4 and sum(1 for o in ch if o["correct"]) == 1, "pick the graph needs four graphs, one right")
        for o, gr in zip(ch, graphs):
            if o["correct"]:
                need(gc_curve_is(gr["curves"][0], S_), "the right graph is not f + g")
            else:
                need(o["mistake"] in mk and o["ref"] == mk[o["mistake"]][0], f"the {o['mistake']} graph is mistagged")
                need(gc_curve_is(gr["curves"][0], mk[o["mistake"]][1]), f"the {o['mistake']} graph is not that mistake")
        gc_check_common(q, next(o["text"] for o in ch if o["correct"]), {o["ref"]: {o["text"]} for o in ch if o["ref"]})
        return None, None
    elif u == "sum-zeros":
        zs = gc_zeros(f + g, lo, hi)
        need(1 <= len(zs) <= 3 and all(gc_fair(z) for z in zs), "f + g has no fair zeros")
        want, trap = gc_xs(zs), gc_xs2(zs)
        wr[CB_SD + "#1"] = {gc_xs(sorted(list(gc_zeros(f, lo, hi)) + list(gc_zeros(g, lo, hi)), key=float))}
    elif u == "first-whole-day":
        zs = gc_zeros(f - g, lo, hi)
        need(len(zs) == 1 and gc_fair(zs[0]), "P doesn't overtake Q once")
        n = int(mpmath.ceil(zs[0]))
        want = f"t = {n}"
        wr[CB_CA + "#0"] = {f"t = {int(mpmath.floor(zs[0]))}"}
        if rep == "table":
            t = q["table"]
            for xv, fv, gv in zip(t["xs"], t["fs"], t["gs"]):
                need(gc_close(fv, gc_f(f)(mpmath.mpf(R(xv)))) and gc_close(gv, gc_f(g)(mpmath.mpf(R(xv)))), f"the table is wrong at t = {xv}")
    else:
        raise Fail(f"the checker has no gdc-combined check for {u}")
    gc_check_common(q, want, wr, trap)
    return None, None


# ── Graphs and key features (FAL-420): gdc-context-equation ───
# An equation that mixes families, from a context. The equation is read back from the
# question's text and every root in a wide window found again with mpmath; the
# context's interval picks the one asked for.

CE_SG, CE_CA = "SL2.10.solve-gdc", "SL2.10.context-apply"


def ce_num(t):
    return R(sp.nsimplify(t.replace("−", "-").replace(",", "")))


def check_gdc_context_equation(q):
    u, rep, asked, L = q["view"]["unknown"], q["view"]["rep"], q["asked"], q["lines"]
    need(q["paper"] == 2, "a GDC equation is Paper 2")
    j = " ".join([asked] + L)
    for t in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    wr, trap = {}, None
    if u == "constant-from-root":
        m = re.search(r"(?:has a solution x = |where x = )([\d.]+)\.", j)
        x0 = ce_num(m.group(1))
        k = x0 / sp.sin(x0)
        gc_check_common(q, "k = " + gc_s(sp.N(k, 30)), {}, "k = " + gc_s2(sp.N(k, 30)))
        return None, None
    if u == "smallest-whole-number":
        m = re.search(r"\$(\d+) is invested at ([\d.]+)% a year", j)
        mt = re.search(r"worth more than \$(\d+)\.", asked)
        need(m is not None and mt is not None, "can't read the investment")
        P0, rate, T = ce_num(m.group(1)), ce_num(m.group(2)), ce_num(mt.group(1))
        mul = 1 + rate / 100
        n = 0
        while P0 * mul ** n <= T:
            n += 1
        need(n >= 4, "the target is reached too soon")
        nr = sp.log(T / P0) / sp.log(mul)
        need(abs(sp.N(nr) - round(sp.N(nr))) >= sp.Rational(5, 100), "the real n is too near a whole number")
        if rep == "table":
            t = q["table"]
            for xv, yv in zip(t["xs"], t["ys"]):
                need(abs(R(yv) - P0 * mul ** R(xv)) <= sp.Rational(1, 200), f"the table's value at n = {xv} is wrong")
        gc_check_common(q, f"n = {n}", {CE_CA + "#0": {f"n = {n - 1}"}})
        return None, None
    lo, hi = -20, 20
    if u == "form-and-solve":
        m = re.search(r"radius (\d+) cm\. The segment's area is ([\d.]+) cm²", asked)
        r, A = ce_num(m.group(1)), ce_num(m.group(2))
        th = sp.Symbol("th")
        h = r ** 2 / 2 * (X - sp.sin(X)) - A
        rs = gc_zeros(h, sp.Rational(1, 10**6), sp.pi)
        need(len(rs) == 1, "not one angle between 0 and π")
        arc = r * rs[0]
        th2 = sp.Rational(sig3(sp.Float(rs[0], 30), 2))
        gc_check_common(q, gc_s(arc) + " cm", {CE_SG + "#1": {gc_s(r * th2) + " cm"}}, gc_s2(arc) + " cm")
        return None, None
    if u == "simultaneous-nonlinear":
        a, b = re.search(r"y = (.+?) and y = (.+?), for x > 0", asked).groups()
        fa, fb = gc_expr(a), gc_expr(b)
        rs = gc_zeros(fa - fb, -20, 20)
        pos = [x for x in rs if x > 0]
        need(len(pos) == 1, "not one solution with x > 0")
        y = gc_f(fb)(pos[0])
        x2 = sp.Rational(sig3(sp.Float(pos[0], 30), 2))
        gc_check_common(q, "y = " + gc_s(y), {CE_SG + "#1": {"y = " + gc_s(fb.subs(X, x2))}}, "y = " + gc_s2(y))
        return None, None
    if u == "first-time":
        m = re.search(r"h\(t\) = (.+?)\. Find the first time it is ([\d.]+) m high", asked)
        f, c = tc_expr(m.group(1)), ce_num(m.group(2))
        rs = gc_zeros(f - c, sp.Rational(1, 10**6), 20)
        need(len(rs) == 2, "the ball is not at that height twice")
        if rep == "graph":
            need(gc_curve_is(q["graph"]["curves"][0], gc_f(f)), "the graph drawn is not h")
        gc_check_common(q, "t = " + gc_s(rs[0]), {CE_CA + "#2": {"t = " + gc_s(c)}}, "t = " + gc_s2(rs[0]))
        return None, None
    # x = k sin x, or an exponential against a line.
    if L[0].startswith("Two quantities"):
        m2 = re.search(r"modelled by (e\^\([^)]*\)) and (.+?), where", L[0])
        lhs, rhs = tc_expr(m2.group(1)), tc_expr(m2.group(2))
    elif L[0].startswith("x = "):
        lhs, rhs = X, gc_expr(L[0][4:].replace("sin x", "sin(x)"))
    elif L[0].startswith("The graph of y = "):
        m3 = re.search(r"y = (e\^\([^)]*\)) − \((.+?)\) is shown", L[0])
        lhs, rhs = gc_expr(m3.group(1)), gc_expr(m3.group(2))
    else:
        # The line is the equation itself: "e^(0.3x) = 2.5x + 4".
        need(L[0].count(" = ") == 1, f"can't read the equation {L[0]!r}")
        a_, b_ = L[0].split(" = ")
        lhs, rhs = gc_expr(a_), gc_expr(b_)
    rs = gc_zeros(lhs - rhs, lo, hi)
    need(1 <= len(rs) <= 4 and all(abs(x) < 1e-20 or gc_fair(x) for x in rs), "the roots are not fair 3 s.f. values")
    v = "t" if u in ("reject-a-root",) or (u == "root-in-interval" and rep == "words") else "x"
    if u == "solve-mixed-equation":
        if "positive solution" in asked:
            pos = [x for x in rs if x > 1e-9]
            need(len(pos) == 1, "not one positive solution")
            want = pos[0]
        else:
            need("largest solution" in asked, "which solution is asked?")
            want = rs[-1]
            need(want > sp.Rational(105, 10), "the largest solution is not past x = 10")
            wr[CE_SG + "#0"] = {"x = " + gc_s(max(x for x in rs if abs(x) <= 10))}
        gc_check_common(q, "x = " + gc_s(want), wr, "x = " + gc_s2(want))
    elif u in ("root-in-interval", "reject-a-root"):
        need(len(rs) == 2 and rs[0] < 0 < rs[1], "not one negative and one positive root")
        if u == "root-in-interval":
            gc_check_common(q, f"{v} = {gc_s(rs[1])}", {CE_CA + "#1": {f"{v} = {gc_s(rs[0])}"}}, f"{v} = {gc_s2(rs[1])}")
        else:
            right = next(o for o in q["choices"] if o["correct"])
            need(right["text"].startswith(f"t = {gc_s(rs[1])}:") and f"t = {gc_s(rs[0])}" in right["text"], "the right option doesn't keep the positive root")
            for o in q["choices"]:
                if o["ref"]:
                    need(o["text"].startswith(f"t = {gc_s(rs[0])}:"), "CA#1 doesn't keep the negative root")
            gc_check_common(q, right["text"], {CE_CA + "#1": {o["text"] for o in q["choices"] if o["ref"]}})
    elif u == "count-roots":
        if rep == "graph":
            need(gc_curve_is(q["graph"]["curves"][0], gc_f(lhs - rhs)), "the graph drawn is not the difference")
        gc_check_common(q, str(len(rs)), {CE_SG + "#0": {str(sum(1 for x in rs if abs(x) <= 10))}})
    else:
        raise Fail(f"the checker has no gdc-context-equation check for {u}")
    return None, None


# ── Graphs and key features (FAL-420): graph-from-features ────
# Paper 1: exact features and the sketch that shows them. The function is read back
# from the question's text, its features worked out exactly with SymPy, and each card
# of a pick-the-graph question is checked: the right one is the function with its
# features marked, each wrong one exactly its named mistake.

GF_SK, GF_SI = "SL2.6.sketch", "SL2.3.sketch-from-info"


def gf_expr(text):
    return tc_expr(text.replace("½", "(1/2)"))


def gf_read(q):
    """(fam, f, info) from the question's text: f as SymPy in x (t read as x)."""
    u = q["view"]["unknown"]
    j = " ".join([q["asked"]] + q["lines"])
    m = re.search(r"roots x = (−?\d+) and x = (−?\d+), its vertex at \((.+?), (.+?)\) and its y-intercept at \(0, (.+?)\), with a ([<>]) 0", j)
    if m:
        r1, r2, c = el_num(m.group(1)), el_num(m.group(2)), el_num(m.group(5))
        a = c / (r1 * r2)
        need((a > 0) == (m.group(6) == ">"), "the sign of a doesn't match the features")
        f = a * (X - r1) * (X - r2)
        need(sp.nsimplify(m.group(3).replace("−", "-")) == (r1 + r2) / 2 and sp.nsimplify(m.group(4).replace("−", "-")) == f.subs(X, (r1 + r2) / 2), "the vertex said is not the parabola's")
        return "quadratic", f, {}
    m = re.search(r"f\(x\) = (.+?)$", q["lines"][0]) if q["lines"] and q["lines"][0].startswith("f(x) = ") else None
    if m:
        return "quadratic", gf_expr(m.group(1)), {}
    m = re.search(r"([hv])\(t\) = (.+?)(?: m/s| metres)?(?:, for 0 ≤ t ≤ (\d+)|\.)", j)
    if m:
        T = re.search(r"(?:0 ≤ t ≤ |lands at t = )(\d+)", j)
        return "interval", gf_expr(m.group(2)), {"T": el_num(T.group(1)), "kind": "height" if m.group(1) == "h" else "velocity"}
    m = re.search(r"y = (\d+)xe\^\(−x\)|maximum at \(1, (\d+)/e\)", j)
    if m:
        a = el_num(m.group(1) or m.group(2))
        return "texp", a * X * sp.exp(-X), {}
    m = re.search(r"T\(t\) = (\d+) \+ (\d+)e\^\(−([\d.]+)t\)", j)
    if m:
        R_, D_, k = el_num(m.group(1)), el_num(m.group(2)), R(sp.nsimplify(m.group(3)))
        return "cooling", R_ + D_ * sp.exp(-k * X), {"R": R_, "D": D_, "k": k}
    m = re.search(r"y = (\d*)(sin|cos) x, for 0 ≤ x ≤ 2π", j) or re.search(r"A (sin|cos) graph with amplitude (\d+)", j)
    if m:
        if m.re.pattern.startswith("y"):
            A, fn = el_num(m.group(1) or "1"), m.group(2)
        else:
            fn, A = m.group(1), el_num(m.group(2))
        return "trig", A * (sp.sin(X) if fn == "sin" else sp.cos(X)), {"A": A, "fn": fn}
    m = re.search(r"passes through \(0, (\d+)\), has a zero at x = (−\d+)", j)
    need(m is not None, "can't read the function")
    return "conditions", None, {"y0": el_num(m.group(1)), "z": el_num(m.group(2))}


def gf_feats(fam, f, info):
    """The exact features a sketch marks: [(x, y), ...]."""
    if fam == "quadratic":
        rs = sorted(sp.solve(f, X))
        need(len(rs) == 2 and all(r.is_integer for r in rs), "the roots are not whole numbers")
        h = (rs[0] + rs[1]) / 2
        need(h.q in (1, 2), "the vertex is not at a whole number or a half")
        return [(rs[0], 0), (rs[1], 0), (h, f.subs(X, h)), (0, f.subs(X, 0))]
    if fam == "interval":
        T = info["T"]
        if info["kind"] == "height":
            return [(0, 0), (T, 0), (T / 2, f.subs(X, T / 2))]
        rs = sorted(sp.solve(f, X))
        v = (rs[0] + rs[1]) / 2
        return [(0, f.subs(X, 0)), (rs[0], 0), (rs[1], 0), (v, f.subs(X, v)), (T, f.subs(X, T))]
    if fam == "texp":
        return [(0, 0), (1, f.subs(X, 1))]
    if fam == "cooling":
        return [(0, f.subs(X, 0))]
    if fam == "trig":
        return [(sp.pi / 2 * i, f.subs(X, sp.pi / 2 * i)) for i in range(5)]
    return [(0, info["y0"]), (info["z"], 0)]


def gf_dots(gr, want):
    got = sorted((round(p["x"], 6), round(p["y"], 6)) for p in gr["points"])
    exp_ = sorted((round(float(x), 6), round(float(y), 6)) for x, y in want)
    return len(got) == len(exp_) and all(abs(a[0] - b[0]) < 1e-5 and abs(a[1] - b[1]) < 1e-5 for a, b in zip(got, exp_))


def gf_cards(q, fam, f, info):
    ch, graphs = q["choices"], q["graphs"]
    need(len(graphs) == 4 and [o["text"] for o in ch] == ["Graph A", "Graph B", "Graph C", "Graph D"], "not four lettered graphs")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right graph")
    need(len({(g["x0"], g["x1"], g["y0"], g["y1"]) for g in graphs}) == 1, "the cards don't share one window")
    feats = gf_feats(fam, f, info)
    ff = gc_f(f) if f is not None else None
    a = sp.Poly(f, X).LC() if fam == "quadratic" else None
    for o, gr in zip(ch, graphs):
        c = gr["curves"][0]
        mk = o.get("mistake", "")
        if o["correct"]:
            if fam == "conditions":
                xs = [p[0] for p in c]
                need(all(b > a_ for a_, b in zip(xs, xs[1:])), "the right graph is not a function")
                need(all(c[i + 1][1] > c[i][1] for i in range(len(c) - 1)), "the right graph is not increasing")
                for x0, y0 in feats:
                    near = min(c, key=lambda p: abs(p[0] - float(x0)))
                    need(abs(near[0] - float(x0)) < 0.05 and abs(near[1] - float(y0)) < 0.1, f"the right graph misses ({x0}, {y0})")
            else:
                need(gc_curve_is(c, ff), "the right graph is not f")
                need(gf_dots(gr, feats), "the right graph doesn't mark the features")
            continue
        refs = {"flipped": GF_SK + "#0" if (a is not None and a < 0) else "", "pointed": GF_SK + "#1", "vertex-on-axis": GF_SK + "#2",
                "below-zero": GF_SI + "#1", "below-room": GF_SI + "#1", "turns-back": GF_SI + "#2", "doubles-back": GF_SI + "#0"}
        need(o["ref"] == refs.get(mk, ""), f"the {mk} graph is tagged {o['ref']!r}")
        need(o.get("why", "") != "", f"the {mk} graph doesn't say what is wrong")
        if mk == "flipped":
            need(gc_curve_is(c, lambda x: -ff(x)), "the flipped graph is not −f")
        elif mk == "pointed":
            (hx, hy) = feats[2] if fam == "quadratic" else feats[3] if info.get("kind") == "velocity" else feats[2]
            r = feats[0][0] if fam == "quadratic" else (feats[1][0] if info.get("kind") == "velocity" else 0)
            need(gc_curve_is(c, lambda x: hy - hy * abs(x - hx) / abs(hx - r)), "the pointed graph is not a V at the vertex")
        elif mk == "vertex-on-axis":
            need(gc_curve_is(c, lambda x: a * x ** 2 + ff(0)), "the vertex-on-axis graph is not ax² + c")
        elif mk in ("below-zero", "past-domain"):
            need(gc_curve_is(c, ff) and c[-1][0] > float(info["T"]) + 1, f"the {mk} graph doesn't carry f past the end")
            if mk == "below-zero":
                need(c[-1][1] < 0, "the height doesn't go below 0")
        elif mk == "turns-back":
            A = ff(1) * mpmath.e
            need(gc_curve_is(c, lambda x: ff(x) + A / 4 * max(0, x - 2.5) ** 2), "the turns-back graph is not f turned up after x = 2.5")
        elif mk == "max-moved":
            A = ff(1) * mpmath.e
            need(gc_curve_is(c, lambda x: A * x * mpmath.exp(-x / 2)), "the max-moved graph is not axe^(−x/2)")
        elif mk == "swapped":
            other = info["A"] * (sp.cos(X) if info["fn"] == "sin" else sp.sin(X))
            need(gc_curve_is(c, gc_f(other)), "the swapped graph is not the other trig function")
        elif mk == "amplitude":
            amp = 1 if info["A"] > 1 else 2
            need(gc_curve_is(c, gc_f(amp * f / info["A"])), "the amplitude graph has the wrong amplitude")
        elif mk == "below-room":
            Rr, Dd, k = info["R"], info["D"], info["k"]
            need(gc_curve_is(c, gc_f(Rr - 6 + (Dd + 6) * sp.exp(-k * X))), "the below-room graph doesn't level off below the room")
        elif mk == "steady":
            need(gc_curve_is(c, gc_f(info["R"] + info["D"] - info["D"] * info["k"] * X)), "the steady graph is not the starting rate")
        elif mk == "warming":
            need(gc_curve_is(c, gc_f(info["R"] + info["D"] - info["D"] * sp.exp(-info["k"] * X))), "the warming graph is not warming")
        elif mk == "doubles-back":
            xs = [p[0] for p in c]
            need(any(b < a_ for a_, b in zip(xs, xs[1:])) and any(b > a_ for a_, b in zip(xs, xs[1:])), "the doubles-back graph doesn't turn back")
        elif mk == "shifted":
            near = min(c, key=lambda p: abs(p[0]))
            need(abs(near[1] - float(info["y0"])) > 1, "the shifted graph still passes through (0, y0)")
        elif mk == "mirrored":
            need(c[0][1] > c[-1][1], "the mirrored graph is not decreasing")
        else:
            raise Fail(f"unknown mistake {mk}")
    return next(o["text"] for o in ch if o["correct"])


def check_graph_from_features(q):
    u, rep = q["view"]["unknown"], q["view"]["rep"]
    need(q["paper"] == 1, "graph-from-features is Paper 1")
    for t in [q["asked"]] + q["lines"] + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    if q["format"] == "pick-the-graph":
        fam, f, info = gf_read(q)
        right = gf_cards(q, fam, f, info)
        gc_check_common(q, right, {o["ref"]: {o["text"]} for o in q["choices"] if o["ref"]})
        return None, None
    g = q["given"]
    a, r1, r2 = R(g["a"]), R(g["r1"]), R(g["r2"])
    f = a * (X - r1) * (X - r2)
    h = (r1 + r2) / 2
    k, c = f.subs(X, h), f.subs(X, 0)
    pt = lambda x_, y_: f"({frac_text(x_)}, {frac_text(y_)})"
    if u == "features-from-sketch":
        labels = {p["label"] for p in q["graph"]["points"]}
        need({pt(r1, 0), pt(r2, 0), pt(h, k), pt(0, c)} == labels, "the sketch's labels are not the parabola's features")
        need(gc_curve_is(q["graph"]["curves"][0], gc_f(f)), "the sketch is not the parabola")
        d = "opens upwards" if a > 0 else "opens downwards"
        desc = lambda dd: f"vertex {pt(h, k)}, roots {frac_text(r1)} and {frac_text(r2)}, y-intercept {frac_text(c)}, {dd}"
        wr = {GF_SK + "#0": {desc("opens upwards")}} if a < 0 else {}
        gc_check_common(q, desc(d), wr)
        return None, None
    if u == "judge-a-sketch":
        shown = gf_expr(q["lines"][0].split(" = ", 1)[1])
        need(sp.expand(shown - f) == 0, "the equation shown is not the parabola")
        gr = q["graph"]["curves"][0]
        ff = gc_f(f)
        flaw = g["flaw"]
        if flaw == "flipped":
            need(gc_curve_is(gr, lambda x: -ff(x)), "the sketch is not f flipped")
            want = f"It opens the wrong way: a {'>' if a > 0 else '<'} 0, so it should open {'upwards' if a > 0 else 'downwards'}."
        else:
            need(gc_curve_is(gr, lambda x: k - k * abs(x - h) / abs(h - r1)), "the sketch is not a V at the vertex")
            want = "Its vertex is a sharp point: a parabola is smooth there."
        gc_check_common(q, want, {GF_SK + "#2": {f"Its vertex should be on the y-axis, at {pt(0, c)}."}})
        return None, None
    raise Fail(f"the checker has no graph-from-features check for {u}")


# ── Graphs and key features (FAL-420): gdc-inequality ─────────
# An inequality between two curves, solved from their crossings: the curves and the
# inequality are read back, the crossings found again, and the solution set worked
# out from the sign of f − g in each part of the domain.

IQ_IE = "SL2.10.inequality-graphical"


def iq_sets(cs, d1, d2, v="x"):
    a, b = gc_s(cs[0][0]), gc_s(cs[1][0])
    D1, D2 = frac_text(d1), frac_text(d2)
    return {"inside": f"{a} < {v} < {b}", "outside": f"{D1} ≤ {v} < {a} or {b} < {v} ≤ {D2}", "right": f"{b} < {v} ≤ {D2}",
            "points": f"{v} = {a} or {v} = {b}"}


def check_gdc_inequality(q):
    u, asked, L = q["view"]["unknown"], q["asked"], q["lines"]
    need(q["paper"] == 2, "a GDC inequality is Paper 2")
    j = " ".join([asked] + L)
    for t in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    v = "x"
    if u == "exceeds-in-context":
        m = re.search(r"C\(t\) = (.+?) mg/l, for 0 ≤ t ≤ (\d+)", j)
        f, g, rel, d1, d2, v = tc_expr(m.group(1)), el_num(re.search(r"above ([\d.]+) mg/l", asked).group(1)), ">", sp.Integer(0), el_num(m.group(2)), "t"
        g = R(sp.nsimplify(str(g)))
    elif u == "inequality-from-region":
        m = re.search(r"The graphs of y = (.+?) and y = (.+?) are shown", j)
        f, g = gc_expr(m.group(1)), gc_expr(m.group(2))
        d1, d2 = el_num(q["given"]["d1"]), el_num(q["given"]["d2"])
        rel = None
    else:
        m = re.search(r"[Ss]olve (.+?) ([<>]) (.+?), for (−?\d+) ≤ x ≤ (−?\d+)\.", asked)
        need(m is not None, "can't read the inequality")
        f, rel, g, d1, d2 = gc_expr(m.group(1)), m.group(2), gc_expr(m.group(3)), el_num(m.group(4)), el_num(m.group(5))
    cs = tc_crossings(f, g, d1 + (sp.Rational(1, 10**6) if v == "t" else 0), d2, False)
    need(len(cs) == 2 and all(gc_fair(x) for x, _ in cs), "not two fair crossings")
    h = gc_f(f - g)
    mid = (cs[0][0] + cs[1][0]) / 2
    above_mid = h(mid) > 0
    st = iq_sets(cs, d1, d2, v)
    if q.get("graph") is not None:
        need(gc_curve_is(q["graph"]["curves"][0], gc_f(f)) and gc_curve_is(q["graph"]["curves"][1], gc_f(g)), "the graphs drawn are not f and g")
    if rel is None:
        inside = st["inside"] in asked
        need(inside or st["outside"] in asked, "the set asked is not one the crossings make")
        want_rel = ">" if inside == above_mid else "<"
        fs, gs = m.group(1), m.group(2)
        gc_check_common(q, f"{fs} {want_rel} {gs}", {})
        return None, None
    inside = (rel == ">") == above_mid
    want = st["inside"] if inside else st["outside"]
    wr = {IQ_IE + "#0": {st["points"]}, IQ_IE + "#1": {st["inside"]}, IQ_IE + "#2": {st["right"]}}
    if inside:
        wr.pop(IQ_IE + "#1")
    gc_check_common(q, want, wr)
    return None, None


# ── Graphs and key features (FAL-420): fn-pre-graph-reading ───
# Reading a grid and rounding. The number or point is read back from the question and
# rounded again with Decimal (half up), each misconception's value worked out the same.

GR_T = "fn-pre-graph-reading#"


def gr_round(text, places=None, sf=None):
    d = Decimal(text.replace("−", "-"))
    if sf is not None:
        e = d.copy_abs().adjusted()
        q = Decimal(1).scaleb(e - sf + 1)
    else:
        q = Decimal(1).scaleb(-places)
    return dec_text(sp.Rational(str(d.quantize(q, rounding=ROUND_HALF_UP))))


def check_graph_reading(q):
    u, asked, L = q["view"]["unknown"], q["asked"], q["lines"]
    need(q["paper"] == 1, "graph reading is Paper 1")
    wr = {}
    if u == "read-coordinates":
        p = [p for p in q["graph"]["points"] if p["label"] == "P"]
        need(len(p) == 1, "no point P on the grid")
        x, y = int(p[0]["x"]), int(p[0]["y"])
        want = f"({frac_text(x)}, {frac_text(y)})"
        wr[GR_T + "1"] = {f"({frac_text(y)}, {frac_text(x)})"}
    elif u == "read-with-scale":
        sc = int(re.search(r"Each grid square on the y-axis is (\d+) units", asked).group(1))
        n = int(re.search(r"The point is (\d+) squares above", L[0]).group(1))
        need(abs(q["graph"]["points"][0]["y"] - n * sc) < 1e-9, "the point drawn is not at that height")
        want = f"y = {n * sc}"
        wr[GR_T + "0"] = {f"y = {n}"}
    elif u == "plot-from-table":
        t = q["table"]
        pts = sorted((int(R(x)), int(R(y))) for x, y in zip(t["xs"], t["ys"]))
        mk = {"swapped": lambda p: (p[1], p[0]), "up-one": lambda p: (p[0], p[1] + 1), "flipped": lambda p: (p[0], -p[1])}
        for o, gr in zip(q["choices"], q["graphs"]):
            got = sorted((int(round(p["x"])), int(round(p["y"]))) for p in gr["points"])
            exp_ = pts if o["correct"] else sorted(mk[o["mistake"]](p) for p in pts)
            need(got == exp_, f"the {o.get('mistake') or 'right'} grid doesn't show its points")
            if not o["correct"]:
                need(o["ref"] == (GR_T + "1" if o["mistake"] == "swapped" else ""), "a grid is mistagged")
        gc_check_common(q, next(o["text"] for o in q["choices"] if o["correct"]), {o["ref"]: {o["text"]} for o in q["choices"] if o["ref"]})
        return None, None
    elif u in ("round-3sf", "round-small-3sf"):
        v = re.search(r"Write (.+?) correct to 3 significant figures\.", asked).group(1)
        want = gr_round(v, sf=3)
        if u == "round-3sf":
            wr[GR_T + "4"] = {gr_round(v, sf=2)}
        else:
            wr[GR_T + "2"] = {gr_round(v, places=3)}
    elif u == "round-dp":
        m = re.search(r"Write (.+?) correct to (\d) decimal places?\.", asked)
        want = gr_round(m.group(1), places=int(m.group(2)))
    elif u == "which-values-round":
        b = sp.Rational(re.search(r"A value x is (.+?), correct to 3 significant figures", asked).group(1).replace("−", "-"))
        want = f"{dec_text(b - sp.Rational(1, 200))} ≤ x < {dec_text(b + sp.Rational(1, 200))}"
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wr)
    return None, None


# ── Graphs and key features (FAL-420): graph-match ────────────
# An equation (y = a·b^x + c or y = a(x − p)(x − q)) and its graph. Each equation is read
# back with SymPy; each graph is tested against the equations, and each wrong graph or
# equation against the one change it names.

GM_MG = "SL2.3.match-graph"


def gm_expr(text):
    t = text.split(" = ", 1)[1] if text.startswith("y = ") else text
    return gc_expr(t)


def gm_parts(f):
    """('exp', a, b, c) or ('quad', a, p, q) for a parsed equation."""
    f = sp.expand(f)
    if f.is_polynomial(X):
        P = sp.Poly(f, X)
        rs = sorted(sp.roots(P).keys())
        return ("quad", P.LC(), rs[0], rs[-1])
    # a·b^x + c from f(0), f(1) and f(2), exactly: b = (f(2) − f(1))/(f(1) − f(0)).
    y0, y1, y2 = [sp.nsimplify(f.subs(X, k)) for k in (0, 1, 2)]
    b = (y2 - y1) / (y1 - y0)
    a = (y1 - y0) / (b - 1)
    c = y0 - a
    need(sp.simplify(a * b ** X + c - f) == 0, f"{f} is not a·b^x + c")
    return ("exp", a, b, c)


def gm_change(f, mk):
    kind, a, u, v = gm_parts(f)
    if kind == "exp":
        b, c = u, v
        return {"lifted": a * b ** X + c + 2, "swapped": a * (1 / b) ** X + c, "moved": -a * b ** X + c}[mk]
    p, q = u, v
    return {"lifted": 2 * a * (X - p) * (X - q), "swapped": -a * (X - p) * (X - q), "moved": a * (X - p - 1) * (X - q - 1)}[mk]


def check_graph_match(q):
    u, rep, asked, L = q["view"]["unknown"], q["view"]["rep"], q["asked"], q["lines"]
    need(q["paper"] == 1, "matching a graph is Paper 1")
    for t in [asked] + L + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    right = next(o for o in q["choices"] if o["correct"])
    if q["format"] == "pick-the-graph":
        if u == "graph-from-facts":
            m = re.search(r"decays towards the line y = (−?\d+) and passes through \(0, (−?\d+)\)", asked)
            c, y0 = el_num(m.group(1)), el_num(m.group(2))
            gr = q["graphs"][q["choices"].index(right)]["curves"][0]
            ys = [p[1] for p in gr]
            need(all(b < a for a, b in zip(ys, ys[1:])), "the right curve doesn't decay")
            near0 = min(gr, key=lambda p: abs(p[0]))
            need(abs(near0[0]) < 1e-9 and abs(near0[1] - float(y0)) < 1e-6 and abs(ys[-1] - float(c)) < 0.5, "the right curve misses its facts")
            f = None
        else:
            m = re.search(r"Which graph is (y = .+?)\?", asked)
            f = gm_expr(m.group(1))
        others = []
        if u == "match-several":
            others = [gm_expr(t) for t in re.search(r"Three equations: (y = .+?), (y = .+?) and (y = .+?)\.", asked).groups()]
        for o, gr in zip(q["choices"], q["graphs"]):
            c0 = gr["curves"][0]
            if f is None:
                if not o["correct"]:
                    need(o["ref"] == "", "a graph-from-facts card is tagged")
                continue
            if o["correct"]:
                need(gc_curve_is(c0, gc_f(f)), "the right graph is not the equation")
                continue
            mk = o["mistake"]
            if mk in ("other-a", "other-b"):
                need(any(gc_curve_is(c0, gc_f(g)) for g in others if sp.simplify(g - f) != 0), "an other graph is not one of the other equations")
                need(o["ref"] == "", "an other graph is tagged")
                continue
            need(gc_curve_is(c0, gc_f(gm_change(f, mk))), f"the {mk} graph is not that change")
            kind = gm_parts(f)[0]
            want_ref = {"lifted": GM_MG + "#0", "swapped": (GM_MG + "#1" if kind == "exp" else "") if u != "match-several" else GM_MG + "#2",
                        "moved": ""}[mk]
            need(o["ref"] == want_ref, f"the {mk} graph is tagged {o['ref']!r}")
        gc_check_common(q, right["text"], {o["ref"]: {o["text"]} for o in q["choices"] if o["ref"]})
        return None, None
    curve = q["graph"]["curves"][0]
    if u in ("equation-from-graph", "match-several"):
        fits = [o for o in q["choices"] if gc_curve_is(curve, gc_f(gm_expr(o["text"])))]
        need(len(fits) == 1 and fits[0]["correct"], f"{len(fits)} equations fit the graph")
        f = gm_expr(right["text"])
        mk = "lifted" if u == "equation-from-graph" else "swapped"
        wr = {(GM_MG + "#0" if mk == "lifted" else GM_MG + "#2"): {o["text"] for o in q["choices"] if o["ref"] and sp.simplify(gm_expr(o["text"]) - gm_change(f, mk)) == 0}}
        gc_check_common(q, right["text"], wr)
    elif u == "rule-out-graph":
        f = gm_expr(L[0])
        need(gc_curve_is(curve, gc_f(gm_change(f, "lifted"))), "the graph shown is not the equation with another y-intercept")
        y0, y1 = f.subs(X, 0), gm_change(f, "lifted").subs(X, 0)
        gc_check_common(q, f"It crosses the y-axis at ({frac_text(0)}, {frac_text(y1)}), but the equation gives ({frac_text(0)}, {frac_text(y0)}) at x = 0.", {})
    elif u == "signs-from-graph":
        g = q["given"]
        if g["fam"] == "exp":
            f = R(g["a"]) * R(g["b"]) ** X + R(g["c"])
            ap, bb = R(g["a"]) > 0, R(g["b"]) > 1
            want = f"a {'>' if ap else '<'} 0 and {'b > 1' if bb else '0 < b < 1'}"
            flip = f"a {'>' if ap else '<'} 0 and {'0 < b < 1' if bb else 'b > 1'}"
            wr = {GM_MG + "#1": {flip}}
        else:
            f = R(g["a"]) * (X - R(g["p"])) * (X - R(g["q"]))
            ap, cp = R(g["a"]) > 0, f.subs(X, 0) > 0
            want = f"a {'>' if ap else '<'} 0 and the y-intercept is {'positive' if cp else 'negative'}"
            flip = f"a {'<' if ap else '>'} 0 and the y-intercept is {'positive' if cp else 'negative'}"
            wr = {GM_MG + "#2": {flip}}
        need(gc_curve_is(curve, gc_f(f)), "the graph is not the given function")
        gc_check_common(q, want, wr)
    else:
        raise Fail(f"no check for {u}")
    return None, None


# ── Graphs and key features (FAL-420): fn-link-extremes ───────
# An extreme value found several ways. Each function is read back from the question
# and its extremes found again with SymPy: the vertex from h′(t) = 0, the wave's from
# sympy's maximum and minimum on a period, the touching lines from a zero
# discriminant, the closed interval's from its stationary points and ends, and the
# cubic's from f′ = 0 and f″.

LE_SIGN = r"(?: ([+−]) (\d+))?"


def le_signed(sign, n):
    return 0 if n is None else (int(n) if sign == "+" else -int(n))


def le_no_hyphen(q):
    for t in [q["asked"]] + q["lines"] + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")


def le_wave(text):
    m = re.search(r"y = (−?\d+) sin\((\d+)x\)" + LE_SIGN, text)
    need(m is not None, f"can't read the wave in {text!r}")
    return el_num(m.group(1)), int(m.group(2)), le_signed(m.group(3), m.group(4))


def le_graph_is(q, fn):
    if q["view"]["rep"] == "graph":
        need(q["graph"] is not None and gc_curve_is(q["graph"]["curves"][0], gc_f(fn)), "the graph drawn is not the function")


def check_link_extremes(q):
    u, asked, L = q["view"]["unknown"], q["asked"], q["lines"]
    need(q["paper"] == 1, "fn-link-extremes is Paper 1")
    le_no_hyphen(q)
    ft = frac_text
    wr = {}
    if u == "max-height-methods":
        m = re.search(r"h\(t\) = (.+?) metres", asked)
        h = gc_expr(m.group(1).replace("t", "x"))
        a = sp.Poly(h, X).LC()
        need(a < 0, "the height model doesn't open downwards")
        T = sp.solve(sp.diff(h, X), X)[0]
        H = h.subs(X, T)
        need(T.is_integer and H.is_integer and T > 0, "the top is not at whole numbers")
        need(all(not r.is_rational for r in sp.solve(h, X)), "the roots are not surds")
        say = lambda what, v, t: f"a {what} of {ft(v)} m at t = {ft(t)} s"
        want = say("maximum", H, T)
        wr = {"SL2.4.max-min#0": {say("maximum", T, H)}, "SL2.6.vertex#2": {say("minimum", H, T)}}
        le_graph_is(q, h)
    elif u in ("wave-extremes", "wave-max-point"):
        A, B, D = le_wave(asked)
        f = A * sp.sin(B * X) + D
        per = sp.Interval(0, 2 * sp.pi)
        hi, lo = sp.maximum(f, X, per), sp.minimum(f, X, per)
        if u == "wave-extremes":
            say = lambda a, b: f"greatest {ft(a)}, least {ft(b)}"
            want = say(hi, lo)
            amp = abs(A)
            wr["SL3.7.read-features#1"] = {say(amp, -amp), say(D + abs(A + D), D - abs(A + D))}
        else:
            first = min(sp.solveset(sp.Eq(f, hi), X, sp.Interval.open(0, 2 * sp.pi)))
            want = "x = " + ext_pi(first / sp.pi)
            wr["SL3.7.read-features#0"] = {"x = " + ft(sp.Rational(B * (1 if A > 0 else 3), 4))}
        if q["view"]["rep"] == "graph":
            need(gc_curve_is(q["graph"]["curves"][0], gc_f(f)), "the graph drawn is not the wave")
    elif u == "range-from-extremes":
        m = re.search(r"with A > 0, is (−?\d+) ≤ y ≤ (−?\d+)\.", L[0])
        lo, hi = el_num(m.group(1)), el_num(m.group(2))
        A_, D_ = sp.symbols("A D")
        sol = sp.solve([D_ + A_ - hi, D_ - A_ - lo], [A_, D_])
        say = lambda a, d: f"amplitude {ft(a)}, principal axis y = {ft(d)}"
        want = say(sol[A_], sol[D_])
        wr["SL3.7.read-features#1"] = {say(abs(hi), sol[D_])}
    elif u == "tangent-means-touch":
        ml = re.search(r"The line y = mx" + LE_SIGN + r" is a tangent", asked)
        mc = re.search(r"to the curve y = x²" + LE_SIGN + r"\.", asked)
        n, r = le_signed(ml.group(1), ml.group(2)), le_signed(mc.group(1), mc.group(2))
        M = sp.Symbol("m")
        quad = sp.Poly(X**2 + r - (M * X + n), X)
        ms = sorted(sp.solve(sp.discriminant(quad.as_expr(), X), M))
        need(len(ms) == 2 and all(v.is_integer for v in ms), "the gradients are not two whole numbers")
        parts = []
        for mv in ms:
            xs = sp.solve(quad.as_expr().subs(M, mv), X)
            need(len(xs) == 1, "the line meets the curve twice")
            parts.append(f"m = {ft(mv)} at ({ft(xs[0])}, {ft(xs[0] ** 2 + r)})")
        want = " or ".join(parts)
        wr["SL5.4.tangency-condition#1"] = {f"m < {ft(ms[0])} or m > {ft(ms[1])}"}
        if q["view"]["rep"] == "graph":
            need(gc_curve_is(q["graph"]["curves"][0], gc_f(X**2 + r)), "the curve drawn is not the parabola")
    elif u == "endpoint-beats-vertex":
        m = re.search(r"Find the range of f\(x\) = (.+?), for (−?\d+) ≤ x ≤ (−?\d+)\.", asked)
        f, p, qq = gc_expr(m.group(1)), el_num(m.group(2)), el_num(m.group(3))
        crit = [c for c in sp.solve(sp.diff(f, X), X) if p < c < qq]
        need(len(crit) == 1, "no turning point inside the interval")
        ends = [f.subs(X, p), f.subs(X, qq)]
        vals = ends + [f.subs(X, crit[0])]
        k, hi = min(vals), max(vals)
        need(hi in ends and hi != min(ends), "the greatest value is not at one end only")
        rt = lambda a, b: f"{ft(a)} ≤ f(x) ≤ {ft(b)}"
        want = rt(k, hi)
        wr = {"SL2.4.max-min#1": {rt(k, min(ends))}, "SL2.2.range#0": {rt(min(ends), max(ends))},
              "SL2.2.range#2": {f"{ft(p)} ≤ x ≤ {ft(qq)}"}, "SL5.8.closed-interval-extremes#0": {f"f(x) ≥ {ft(k)}"}}
        le_graph_is(q, f)
    elif u == "cubic-turning":
        f = gc_expr(re.search(r"turning points of f\(x\) = (.+?), and say", asked).group(1))
        xs = sorted(sp.solve(sp.diff(f, X), X))
        need(len(xs) == 2 and all(v.is_integer for v in xs), "the turning points are not at two whole numbers")
        kinds = {x: ("max" if sp.diff(f, X, 2).subs(X, x) < 0 else "min") for x in xs}
        mx = next(x for x in xs if kinds[x] == "max")
        mn = next(x for x in xs if kinds[x] == "min")
        say = lambda ya, yb: f"maximum ({ft(mx)}, {ft(ya)}), minimum ({ft(mn)}, {ft(yb)})"
        want = say(f.subs(X, mx), f.subs(X, mn))
        wr["SL5.8.find-stationary-points#2"] = {say(0, 0)}
        le_graph_is(q, f)
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wr)
    return None, None


# ── Graphs and key features (FAL-420): fn-link-graph-vs-algebra ──
# An equation as two graphs that meet. Each equation is read back; exact solutions
# come from SymPy's solveset, GDC ones from root brackets refined with mpmath to 30
# digits, counts from solveset on the interval (or real-root counts of f − k), and the
# area from integrating between the meeting points.


def lg_ex(text):
    m = re.fullmatch(r"(e\^x|e\^\((\d)x\)) = (\d+)", text)
    return None if m is None else (int(m.group(2) or 1), int(m.group(3)))


def lg_ln_over(c, k, name="ln"):
    return f"{name} {c}" if k == 1 else f"({name} {c})/{k}"


def lg_xs(names):
    return "x = " + (names[0] if len(names) == 1 else ", ".join(names[:-1]) + " or " + names[-1])


def lg_s2(x):
    return sig3(x, 2).replace("-", "−")


def lg_pi(text):
    m = re.fullmatch(r"(\d*)π(?:/(\d+))?", text)
    return sp.Rational(int(m.group(1) or 1), int(m.group(2) or 1))


def lg_sols(xs):
    n = len(xs)
    return f"{n} solution{'' if n == 1 else 's'}: " + lg_xs([ext_pi(x / sp.pi) for x in xs])


def check_link_graph_algebra(q):
    u, asked, L = q["view"]["unknown"], q["asked"], q["lines"]
    le_no_hyphen(q)
    ft = frac_text
    wr = {}
    paper = 1
    if u == "which-method":
        paper = 2
        eq = re.fullmatch(r"Can (.+) be solved exactly by algebra\? Choose the true statement\.", asked).group(1)
        e = lg_ex(eq)
        if e:
            k, c = e
            x0 = sp.solveset(sp.exp(k * X) - c, X, sp.S.Reals)
            need(len(x0) == 1, "e^(kx) = c has not one solution")
            want = f"Yes: x = {lg_ln_over(c, k)} ≈ {gc_s(sp.N(next(iter(x0)), 30))}"
        else:
            m = re.fullmatch(r"(e\^x|ln x) = (\d+) − x", eq)
            a = int(m.group(2))
            lhs = sp.exp(X) if m.group(1) == "e^x" else sp.log(X)
            zs = gc_zeros(lhs - (a - X), 0.001 if m.group(1) == "ln x" else -10, a + 2)
            need(len(zs) == 1 and not on_edge(abs(zs[0])), "not one clean meeting point")
            want = "No: graph both sides; x ≈ " + gc_s(zs[0])
    elif u == "solve-by-intersection":
        paper = 2
        rhs_ = gc_expr(re.fullmatch(r"Solve e\^x = (.+), giving every solution to 3 s\.f\.", asked).group(1))
        zs = gc_zeros(sp.exp(X) - rhs_, -20, 10)
        need(len(zs) == 2 and all(not on_edge(abs(z)) for z in zs), "not two clean meeting points")
        want = lg_xs([gc_s(z) for z in zs])
        wr = {"SL2.10.solve-gdc#0": {lg_xs([gc_s(zs[1])])}, "SL2.10.solve-gdc#1": {lg_xs([lg_s2(z) for z in zs])}}
        if q["view"]["rep"] == "graph":
            cs = q["graph"]["curves"]
            need(gc_curve_is(cs[0], gc_f(sp.exp(X))) and gc_curve_is(cs[1], gc_f(rhs_)), "the graphs drawn are not the two sides")
            need(q["graph"]["x0"] < float(zs[0]), "the window hides the left meeting point")
    elif u == "count-trig-solutions":
        m = re.fullmatch(r"How many solutions has (\d) (cos|sin) x = (−?\d+) for 0 ≤ x ≤ (.+)\? Find them\.", asked)
        A, fn, rv, U = int(m.group(1)), getattr(sp, m.group(2)), el_num(m.group(3)), lg_pi(m.group(4)) * sp.pi
        eq = A * fn(X) - rv
        sols = sorted(sp.solveset(eq, X, sp.Interval(0, U)), key=float)
        nxt = min(sp.solveset(eq, X, sp.Interval.Lopen(U, U + 2 * sp.pi)), key=float)
        want = lg_sols(sols)
        wr = {"SL2.10.number-of-solutions#1": {lg_sols(sols + [nxt])}, "SL3.8.graphical#0": {lg_sols([s_ for s_ in sols if s_ <= 2 * sp.pi])}}
        if q["view"]["rep"] == "graph":
            g = q["graph"]
            need(gc_curve_is(g["curves"][0], gc_f(A * fn(X))) and abs(g["hlines"][0]["at"] - float(rv)) < 1e-9, "the graph drawn is not the equation's")
    elif u == "k-for-count":
        f = gc_expr(re.search(r"The graph of f\(x\) = (.+?) is shown", L[0]).group(1))
        n = {"one": 1, "two": 2, "three": 3}[re.search(r"exactly (one|two|three) solution", asked).group(1)]
        tv = sorted(f.subs(X, x) for x in sp.solve(sp.diff(f, X), X))
        lo, hi = tv
        cnt = lambda k: len(set(sp.Poly(f - k, X).real_roots()))
        L_, H_ = ft(lo), ft(hi)
        got = {"inside": cnt((lo + hi) / 2), "at": (cnt(lo), cnt(hi)), "out": (cnt(lo - 1), cnt(hi + 1))}
        need(got["inside"] == 3 and got["at"] == (2, 2) and got["out"] == (1, 1), f"the counts are not 1, 2, 3: {got}")
        want = {3: f"{L_} < k < {H_}", 2: f"k = {L_} or k = {H_}", 1: f"k < {L_} or k > {H_}"}[n]
        if n == 3:
            wr["SL2.10.number-of-solutions#0"] = {f"{L_} ≤ k ≤ {H_}"}
        need(gc_curve_is(q["graph"]["curves"][0], gc_f(f)), "the graph drawn is not f")
    elif u == "limits-first":
        m = re.search(r"The curve y = (.+?) and the line y = (.+?) enclose a region", asked)
        cv, ln_ = gc_expr(m.group(1)), gc_expr(m.group(2))
        p, qq = sorted(sp.solve(cv - ln_, X))
        need(p < 0 < qq and p.is_integer and qq.is_integer, "the meeting points are not whole numbers either side of 0")
        area = sp.integrate(sp.Abs(ln_ - cv), (X, p, qq))
        say = lambda a, b, ar: f"x = {ft(a)} and x = {ft(b)}; area {ft(ar)}"
        want = say(p, qq, area)
        u0, v0 = sorted(sp.solve(cv, X))
        wr = {"SL5.11.area-between-curves#0": {say(p, qq, -area)},
              "SL5.11.area-between-curves#1": {say(u0, v0, abs(sp.integrate(ln_ - cv, (X, u0, v0))))},
              "SL2.4.intersection#1": {say(0, qq, abs(sp.integrate(ln_ - cv, (X, 0, qq))))}}
        if q["view"]["rep"] == "graph":
            cs = q["graph"]["curves"]
            need(gc_curve_is(cs[0], gc_f(cv)) and gc_curve_is(cs[1], gc_f(ln_)), "the graphs drawn are not the curve and the line")
    elif u == "log-equation-check":
        m = re.fullmatch(r"Solve ln x \+ ln\(x \+ (\d+)\) = ln (\d+)\.", asked)
        a, b = int(m.group(1)), int(m.group(2))
        lhs = sp.log(X) + sp.log(X + a) - sp.log(b)
        # The meeting points of the graphs (x > 0 only), and the roots algebra gives.
        zs = gc_zeros(lhs, sp.Rational(1, 1000), 60)
        need(len(zs) == 1, f"the graphs meet {len(zs)} times")
        roots = sorted(sp.solve(X**2 + a * X - b, X))
        good = [x for x in roots if x > 0 and abs(sp.N(lhs.subs(X, x), 30)) < 1e-25]
        need(len(good) == 1 and abs(good[0] - zs[0]) < 1e-20, "the algebra's root is not the meeting point")
        r = good[0]
        bad = [x for x in roots if x != r]
        need(len(bad) == 1 and bad[0] < 0 and r.is_integer, "no rejected whole-number root")
        want = "x = " + ft(r)
        both = f"x = {ft(r)} or x = {ft(bad[0])}"
        wr = {"SL2.10.solve-analytic#0": {both}, "SL1.7.log-equations#0": {both}}
        if q["view"]["rep"] == "graph":
            g = q["graph"]
            need(gc_curve_is(g["curves"][0], gc_f(sp.log(X) + sp.log(X + a))) and abs(g["hlines"][0]["at"] - float(sp.log(b))) < 1e-9,
                 "the graphs drawn are not the two sides")
    elif u == "exponential-two-ways":
        paper = 2
        k, c = lg_ex(re.fullmatch(r"Solve (.+) exactly, and give x to 3 s\.f\.", asked).group(1))
        x0 = sp.N(next(iter(sp.solveset(sp.exp(k * X) - c, X, sp.S.Reals))), 30)
        need(not on_edge(abs(x0)), "x is on a rounding edge")
        want = f"x = {lg_ln_over(c, k)} ≈ {gc_s(x0)}"
        wr["SL1.5.evaluate-tech#0"] = {f"x = {lg_ln_over(c, k, 'log')} ≈ {gc_s(sp.N(sp.log(c, 10) / k, 30))}"}
    else:
        raise Fail(f"no check for {u}")
    need(q["paper"] == paper, f"paper {q['paper']}, not {paper}")
    gc_check_common(q, want, wr)
    return None, None


# ── binomial (t4-binomial, FAL-695) ──────────────────────────
# The `binomial` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/binomial.gd. Every probability is solved again from n and p with
# exact rationals and rounded to 3 s.f. on the true value; the engine works in floats.

BN_SKILL = "SL4.8."
BN_EDGE = sp.Rational(29, 1000)         # the engine's is 0.03; a hair under it, so no float-vs-exact tie fails
BN_RANGES = {"exact-probability": (sp.Rational(1, 100), sp.Rational(2, 5)),
             "at-most-probability": (sp.Rational(1, 50), sp.Rational(49, 50)),
             "at-least-probability": (sp.Rational(1, 50), sp.Rational(49, 50)),
             "between-probability": (sp.Rational(1, 20), sp.Rational(19, 20)),
             "kth-success-trial": (sp.Rational(1, 100), sp.Rational(2, 5)),
             "conditional-probability": (sp.Rational(1, 50), sp.Rational(3, 5))}
BN_TERMS_MAX = 6
BN_LEAST_GAP = sp.Rational(99, 1000)    # the engine's is 0.1
BN_LEAST_MAX = 60
# The stories, in the engine's order: unit, singular, plural verb phrase, singular verb phrase.
BN_CONTEXTS = [("seeds", "seed", "germinate", "germinates"), ("filters", "filter", "work", "works"),
               ("scans", "scan", "pick up a signal", "picks up a signal"), ("cans", "can", "go bad", "goes bad"),
               ("arrows", "arrow", "hit the target", "hits the target"), ("bridges", "bridge", "hold", "holds"),
               ("trips", "trip", "arrive on time", "arrives on time"), ("batteries", "battery", "last all night", "lasts all night")]


def bn_pmf(n, p, k):
    return sp.binomial(n, k) * p**k * (1 - p)**(n - k) if 0 <= k <= n else sp.Integer(0)


def bn_cdf(n, p, k):
    return sum((bn_pmf(n, p, r) for r in range(0, min(k, n) + 1)), sp.Integer(0)) if k >= 0 else sp.Integer(0)


def bn_clear(x, lo, hi):
    """x is between lo and hi, and at least BN_EDGE of a unit of its 3rd figure from a rounding edge."""
    if not (lo <= x <= hi):
        return False
    v = num(x)
    e = sp.floor(sp.log(v, 10))
    scaled = v / sp.Integer(10) ** (e - 2)
    return abs(scaled - sp.floor(scaled) - sp.Rational(1, 2)) >= BN_EDGE


def bn_ordinal(i):
    if 11 <= i % 100 <= 13:
        return f"{i}th"
    return f"{i}{ {1: 'st', 2: 'nd', 3: 'rd'}.get(i % 10, 'th') }"


def bn_event(form, k, a, b):
    return {"le": f"X ≤ {k}", "lt": f"X < {k}", "ge": f"X ≥ {k}", "gt": f"X > {k}", "in": f"{a} ≤ X ≤ {b}",
            "lo-open": f"{a} < X ≤ {b}", "": f"X = {k}"}[form]


def bn_event_words(form, k, a, b, tail):
    return {"le": f"at most {k} {tail}", "lt": f"fewer than {k} {tail}", "ge": f"at least {k} {tail}", "gt": f"more than {k} {tail}",
            "in": f"at least {a} but at most {b} {tail}", "lo-open": f"more than {a} but at most {b} {tail}", "": f"exactly {k} {tail}"}[form]


def bn_prob_text(label, x):
    return label + sig3(x).replace("-", "−")


def bn_trap(label, x):
    """The rounding trap's text: the answer to 2 s.f., or None where the answer is exact at 3 s.f."""
    if sp.Rational(sig3(x)) == x:
        return None
    return label + dec_text(sp.Rational(sig3(x, 2)))


def check_binomial(q):
    g, u, L, rep = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"]
    T = "t4-binomial"
    need(q["paper"] == 2, "binomial questions are Paper 2")
    n, p = int(g["n"]), R(g["p"])
    qq = 1 - p
    need(0 < p < 1 and (p * 20).q == 1, "p is not a multiple of 0.05")
    ctx = BN_CONTEXTS[int(g["ctx"])]
    unit, sing, good, good1 = ctx
    ptxt = dec_text(p)
    form, k, a, b, lo, hi, m = g["form"], int(g["k"]), int(g["a"]), int(g["b"]), int(g["lo"]), int(g["hi"]), int(g["m"])

    # What is shown is what is given.
    if u not in ("least-trials", "kth-success-trial"):
        if u == "n-and-p-from-mean-variance":
            need(L[0].startswith("X ~ B(n, p)") if rep == "equation" else L[0].startswith("Let X be "), f"first line {L[0]!r}")
        elif rep == "equation":
            need(L[0] == f"X ~ B({n}, {ptxt})", f"the model shown is {L[0]!r}, not B({n}, {ptxt})")
        else:
            need(f" {ptxt}," in L[0] and f"{n} {unit}" in L[0] or f"{n} " in L[0], f"the story {L[0]!r} doesn't give n and p")
            need(f"probability {ptxt}" in L[0], f"the story {L[0]!r} doesn't give p = {ptxt}")
    asked = q["asked"]

    wrongs, trap, want = {}, None, None
    if u == "n-and-p-from-words":
        need(rep == "words" and f"{n} " in L[0] and f"probability {ptxt}" in L[0], "the story doesn't give n and p")
        want = f"n = {n}, p = {ptxt}"
        wrongs[BN_SKILL + "identify#0"] = {f"n = {ptxt}, p = {n}"}
    elif u in ("exact-probability", "at-most-probability", "at-least-probability", "between-probability"):
        need(form == {"exact-probability": ""}.get(u, form) and form in {"exact-probability": [""], "at-most-probability": ["le", "lt"],
             "at-least-probability": ["ge", "gt"], "between-probability": ["in", "lo-open"]}[u] or u == "exact-probability" and form == "", f"form {form!r}")
        # The event as bounds on X.
        want_bounds = {"": (k, k), "le": (0, k), "lt": (0, k - 1), "ge": (k, n), "gt": (k + 1, n), "in": (a, b), "lo-open": (a + 1, b)}[form]
        need((lo, hi) == want_bounds, f"bounds {(lo, hi)} are not {want_bounds} for {form!r}")
        need(0 <= lo <= hi <= n, "the event is outside 0 to n")
        ev = bn_event(form, k, a, b)
        if rep == "equation":
            need(asked == f"Find P({ev}).", f"the question asks {asked!r}, not P({ev})")
        else:
            tail = f"of the {n} {unit} {good}"
            need(asked == f"Find the probability that {bn_event_words(form, k, a, b, tail)}.", f"the question asks {asked!r}")
        x = bn_cdf(n, p, hi) - bn_cdf(n, p, lo - 1)
        label = f"P({ev}) = " if u != "exact-probability" else f"P(X = {k}) = "
        need(bn_clear(x, *BN_RANGES[u]), f"P({ev}) = {float(x):.6f} is out of range or on a rounding edge")
        if u == "between-probability":
            need(hi - lo + 1 <= BN_TERMS_MAX, "the working adds more than 6 terms")
        if u == "at-most-probability":
            need(k <= 6, "k is above 6")
        want, trap = bn_prob_text(label, x), bn_trap(label, x)
        if u == "exact-probability":
            wrongs[BN_SKILL + "exact-probability#0"] = {bn_prob_text(label, p**k * qq**(n - k))}
            wrongs[BN_SKILL + "exact-probability#1"] = {bn_prob_text(label, sp.binomial(n, k) * p**(n - k) * qq**k)}
            wrongs[BN_SKILL + "exact-probability#2"] = {bn_prob_text(label, bn_cdf(n, p, k))}
        elif u == "at-most-probability":
            if form == "lt":
                wrongs[BN_SKILL + "cumulative-probability#1"] = {bn_prob_text(label, bn_cdf(n, p, k))}
        elif u == "at-least-probability":
            wrongs[BN_SKILL + "cumulative-probability#0"] = {bn_prob_text(label, 1 - bn_cdf(n, p, k if form == "ge" else k - 1))}
        else:
            if form == "lo-open":
                wrongs[BN_SKILL + "cumulative-probability#2"] = {bn_prob_text(label, bn_cdf(n, p, b) - bn_cdf(n, p, lo))}
    elif u in ("mean-from-parameters", "variance-from-parameters", "std-deviation"):
        if rep == "equation":
            need(asked == {"mean-from-parameters": "Find E(X).", "variance-from-parameters": "Find Var(X).",
                           "std-deviation": "Find the standard deviation of X, to 3 s.f."}[u], f"asked {asked!r}")
        else:
            need(asked == {"mean-from-parameters": f"Find the expected number of {unit} that {good}.", "variance-from-parameters": "Find the variance of X.",
                           "std-deviation": "Find the standard deviation of X, to 3 s.f."}[u], f"asked {asked!r}")
        mean, var = n * p, n * p * qq
        need(R(g["mean"]) == mean if u == "mean-from-parameters" else R(g["variance"]) == var if u != "mean-from-parameters" else True, "E(X) or Var(X) given is not npq")
        if u == "mean-from-parameters":
            need(n >= 10 and n <= 60, "n is outside 10 to 60")
            want = f"E(X) = {dec_text(mean)}"
            if mean.q != 1:
                wrongs[BN_SKILL + "mean-variance#2"] = {f"E(X) = {dec_text(sp.Integer(sp.floor(mean + sp.Rational(1, 2))))}"}
        elif u == "variance-from-parameters":
            need((p * 10).q == 1, "p is not a multiple of 0.1 for a variance")
            want = f"Var(X) = {dec_text(var)}"
            wrongs[BN_SKILL + "mean-variance#0"] = {f"Var(X) = {dec_text(mean)}"}
        else:
            need((p * 10).q == 1, "p is not a multiple of 0.1 for a standard deviation")
            sd = sp.sqrt(var)
            need(bn_clear(sd, sp.Rational(0), sp.Integer(100)), "the standard deviation is on a rounding edge")
            label = "standard deviation = "
            want, trap = bn_prob_text(label, sd), bn_trap(label, sd) if not sd.is_rational or sp.Rational(sig3(sd)) != sd else None
            wrongs[BN_SKILL + "mean-variance#1"] = {bn_prob_text(label, var)}
    elif u == "n-and-p-from-mean-variance":
        eline = L[-1]
        mt = re.fullmatch(r"E\(X\) = ([\d.]+) and Var\(X\) = ([\d.]+)", eline)
        need(mt is not None, f"can't read {eline!r}")
        E, V = R(mt.group(1)), R(mt.group(2))
        need(V < E, "Var(X) is not below E(X)")
        # n and p from what is SHOWN, not from the givens.
        p2 = 1 - V / E
        n2 = E / p2
        need(n2.q == 1 and (p2 * 10).q == 1, f"n = {n2}, p = {p2} are not a whole number and a multiple of 0.1")
        need(int(n2) == n and p2 == p, "the givens are not what the shown E(X) and Var(X) give")
        need(asked == "Find n and p.", f"asked {asked!r}")
        want = f"n = {n}, p = {dec_text(p)}"
        wrongs[BN_SKILL + "find-n-or-p#2"] = {f"n = {n}, p = {dec_text(1 - p)}"}
    elif u == "least-trials":
        c = R(g["c"])
        if rep == "equation":
            need(L[0] == f"X ~ B(n, {ptxt})", f"first line {L[0]!r}")
            need(asked == f"Find the least n such that P(X ≥ 1) > {dec_text(c)}.", f"asked {asked!r}")
        else:
            need(f"probability {ptxt}" in L[0], f"the story {L[0]!r} doesn't give p")
            need(asked == f"How many {unit} are needed so that the probability that at least one {sing} {good1} is greater than {dec_text(c)}?", f"asked {asked!r}")
        need(c in (sp.Rational(9, 10), sp.Rational(19, 20), sp.Rational(99, 100)), "c is not 0.9, 0.95 or 0.99")
        nn = next(i for i in range(1, 400) if 1 - qq**i > c)
        need(nn == int(g["nn"]), f"the least n is {nn}, not {g['nn']}")
        x = sp.log(1 - c) / sp.log(qq)
        frac = sp.N(x - sp.floor(x), 20)
        need(BN_LEAST_GAP <= frac <= 1 - BN_LEAST_GAP, f"the quotient {float(x):.4f} is not clear of a whole number")
        need(3 <= nn <= BN_LEAST_MAX, f"n = {nn} is outside 3 to {BN_LEAST_MAX}")
        want = f"n = {nn}"
        if nn > 1:
            wrongs[BN_SKILL + "find-n-or-p#1"] = {f"n = {nn - 1}"}
    elif u == "kth-success-trial":
        if rep == "equation":
            need(L[0] == f"Independent trials, each a success with probability {ptxt}.", f"first line {L[0]!r}")
            need(asked == f"Find the probability that the {bn_ordinal(k)} success is on trial {m}.", f"asked {asked!r}")
        else:
            need(f"probability {ptxt}" in L[0], f"the story {L[0]!r} doesn't give p")
            need(asked == f"Find the probability that the {bn_ordinal(k)} {sing} to {good} is the {bn_ordinal(m)} {sing} used.", f"asked {asked!r}")
        need(2 <= k <= 4 and k + 2 <= m <= k + 8, f"k = {k}, m = {m} are outside the limits")
        x = sp.binomial(m - 1, k - 1) * p**k * qq**(m - k)
        label = "probability = "
        need(bn_clear(x, *BN_RANGES[u]), f"the probability {float(x):.6f} is out of range or on a rounding edge")
        want, trap = bn_prob_text(label, x), bn_trap(label, x)
        wrongs[BN_SKILL + "binomial-in-context#1"] = {bn_prob_text(label, bn_pmf(m, p, k))}
    elif u == "conditional-probability":
        j = k
        if rep == "equation":
            need(asked == f"Find P(X = {j} | X ≥ 1).", f"asked {asked!r}")
        else:
            need(asked == f"Given that at least one {sing} {good1}, find the probability that exactly {j} of the {n} {unit} {good}.", f"asked {asked!r}")
        at_one = 1 - qq**n
        need(at_one <= sp.Rational(97, 100), "P(X ≥ 1) is above 0.97, so dividing by it hardly matters")
        x = bn_pmf(n, p, j) / at_one
        label = "probability = "
        need(1 <= j <= n - 1 and bn_clear(x, *BN_RANGES[u]), f"the probability {float(x):.6f} is out of range or on a rounding edge")
        want, trap = bn_prob_text(label, x), bn_trap(label, x)
        wrongs[BN_SKILL + "binomial-in-context#2"] = {bn_prob_text(label, bn_pmf(n, p, j) * at_one)}
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wrongs, trap)
    need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")
    for sol in q["solutions"]:
        need(want in sol["steps"][-1], f"{sol['name']}: the last step {sol['steps'][-1]!r} doesn't state {want!r}")
    return None, None


# ── data-summary (t4-summary-statistics, FAL-695) ────────────
# The `data-summary` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/data_summary.gd. The data are read back from the lines and the
# table the student sees, and every summary is found again with exact rationals.

DS_SKILL = "SL4.3."
DS_EDGE = sp.Rational(29, 1000)         # the engine's is 0.03
# The stories, in the engine's order.
DS_CONTEXTS = [("quiz scores", "score"), ("daily temperatures in °C", "temperature"), ("journey times in minutes", "time"),
               ("parcel masses in kg", "mass"), ("plant heights in cm", "height"), ("ages in years", "age")]
DS_GROUPS = [("boys", "girls", "mark", "students"), ("morning shifts", "evening shifts", "number of customers", "shifts"),
             ("small packets", "large packets", "number of seeds", "packets"),
             ("first-year pupils", "second-year pupils", "homework time in minutes", "pupils"),
             ("cyclists", "walkers", "distance in km", "people")]
DS_SPREADS = ["The masses, in kg, of 8 crates of tinned food:", "The times, in minutes, 8 couriers took to cross the wasteland:",
              "The daily water use, in litres, of 8 households:", "The distances, in km, 8 scavengers travelled in a day:",
              "The lengths, in cm, of 8 pipes:", "The rainfall, in mm, a station recorded on 8 days:"]
DS_CENTRES = ["the mean", "the median", "the mode", "the midrange"]
DS_MEASURES = ["the range", "the interquartile range", "the standard deviation", "the variance"]
# Limits by paper: a list's size and values, a table's number of values, total frequency and values.
DS_LIST = {1: ((5, 11), (1, 20)), 2: ((10, 18), (10, 60))}
DS_TABLE = {1: ((4, 6), (8, 24), (1, 15)), 2: ((5, 8), (25, 60), (10, 60))}


def ds_median(v):
    n = len(v)
    return v[n // 2] if n % 2 else (v[n // 2 - 1] + v[n // 2]) / 2


def ds_quartiles(v):
    n = len(v)
    h = n // 2
    return ds_median(v[:h]), ds_median(v[h + n % 2:])


def ds_clear(x):
    """x is at least DS_EDGE of a unit of its 3rd figure from a rounding edge."""
    v = num(x)
    e = sp.floor(sp.log(v, 10))
    scaled = v / sp.Integer(10) ** (e - 2)
    return abs(scaled - sp.floor(scaled) - sp.Rational(1, 2)) >= DS_EDGE


def ds_mode(v):
    counts = {}
    for x in v:
        counts[x] = counts.get(x, 0) + 1
    top = max(counts.values())
    modes = [x for x, c in counts.items() if c == top]
    return modes, top


def ds_num(x, label):
    """A number answer as the game writes it: exact where it ends, else to 3 s.f."""
    if sp.Rational(sig3(x)) == x:
        return label + dec_text(x), None
    return label + sig3(x).replace("-", "−"), label + dec_text(sp.Rational(sig3(x, 2)))


def ds_numbers(text):
    return [R(v) for v in re.findall(r"\d+(?:\.\d+)?", text.replace("−", "-"))]


def check_data_summary(q):
    g, u, L, rep, paper = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"], q["paper"]
    asked = q["asked"]
    need(paper in (1, 2), f"paper {paper}")
    for tx in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", tx), f"a hyphen for a minus in {tx!r}")
    wrongs, want, trap = {}, None, None

    # The data as shown: a list in the order shown, or a table's values and frequencies.
    def shown_list(line):
        need(re.fullmatch(r"\d+(\.\d)?(, \d+(\.\d)?)*", line) is not None, f"can't read the list {line!r}")
        return [R(x) for x in line.split(", ")]

    xs, fs, data = None, None, None
    if u in ("mean-of-data", "median-of-data", "mode-of-data", "range-of-data", "quartiles-of-data", "iqr-of-data"):
        if rep == "table":
            need(L == ["The table shows the data."], f"the line {L!r}")
            rows = q["table"]["rows"]
            need(rows[0][0] == "x" and rows[1][0] == "Frequency", "table heads")
            xs, fs = [R(v) for v in rows[0][1]], [int(v) for v in rows[1][1]]
            need(xs == sorted(set(xs)) and all(f >= 1 for f in fs), "the table's values are not distinct and ascending")
            (m_lo, m_hi), (t_lo, t_hi), (v_lo, v_hi) = DS_TABLE[paper]
            need(m_lo <= len(xs) <= m_hi, f"{len(xs)} values in the table")
            need(t_lo <= sum(fs) <= t_hi, f"the frequencies add to {sum(fs)}")
            need(all(v_lo <= x <= v_hi for x in xs), "a table value is outside the limits")
            need(max(fs) <= (7 if paper == 1 else 12), "a frequency is above the limit")
            data = sorted(x for x, f in zip(xs, fs) for _ in range(f))
        else:
            need(len(L) == 1 and q["table"] is None, f"the lines {L!r}")
            xs = shown_list(L[0])
            (n_lo, n_hi), (v_lo, v_hi) = DS_LIST[paper]
            need(n_lo <= len(xs) <= n_hi, f"{len(xs)} values")
            need(all(x == int(x) and v_lo <= x <= v_hi for x in xs), "a value is outside the limits or not whole")
            data = sorted(xs)
            need(xs != data, "the list is already in order")
        n = len(data)
    if u == "mean-of-data":
        mean = sum(data) / n
        if paper == 1:
            need((mean * 10).q == 1, f"the Paper 1 mean {mean} does not end within one decimal place")
            need(n <= (10 if rep == "terms" else 24), f"n = {n}")
        else:
            need(sp.Rational(sig3(mean)) != mean, f"the Paper 2 mean {mean} needs no rounding")
            need(ds_clear(mean), f"the mean {float(mean):.6f} is on a rounding edge")
        need(R(g["mean"]) == mean, "the mean given is not the mean of the data shown")
        need(asked == ("Find the mean of the data." if paper == 1 else "Find the mean of the data, to 3 s.f."), f"asked {asked!r}")
        want, trap = ds_num(mean, "mean = ")
        sol = next((s for s in q["solutions"] if s["angle"] == "sum-over-n"), None)
        if sol is not None and rep == "terms":
            need(sol["steps"][0].endswith(f"= {dec_text(sum(data))}"), f"the sum in {sol['steps'][0]!r}")
            need(f"÷ {n} = " in sol["steps"][1], f"the division in {sol['steps'][1]!r}")
    elif u == "median-of-data":
        med = ds_median(data)
        need(asked == "Find the median of the data.", f"asked {asked!r}")
        want = "median = " + dec_text(med)
        if rep == "terms":
            need(5 <= n <= (11 if paper == 1 else 18), f"n = {n}")
            wrongs[DS_SKILL + "mean-median-mode#0"] = {"median = " + dec_text(ds_median(xs))}
        wrongs[DS_SKILL + "mean-median-mode#1"] = {"median = " + dec_text(sp.Rational(n + 1, 2))}
        for sol in q["solutions"]:
            if sol["angle"] == "ordered-position" and rep == "terms":
                need(sol["steps"][0] == "Put the values in order: " + ", ".join(dec_text(x) for x in data), f"order step {sol['steps'][0]!r}")
    elif u == "mode-of-data":
        modes, top = ds_mode(data)
        need(len(modes) == 1 and top >= 2, f"modes {modes} occurring {top} times")
        need(sp.Integer(top) != modes[0], "the mode equals its own count")
        need(R(g["mode"]) == modes[0] and int(g["mode_count"]) == top, "the mode given is not the mode of the data shown")
        need(asked == "Write down the mode of the data.", f"asked {asked!r}")
        want = "mode = " + dec_text(modes[0])
        wrongs[DS_SKILL + "mean-median-mode#2"] = {"mode = " + str(top)}
    elif u == "range-of-data":
        need(asked == "Find the range of the data.", f"asked {asked!r}")
        want = "range = " + dec_text(data[-1] - data[0])
    elif u in ("quartiles-of-data", "iqr-of-data"):
        q1, q3 = ds_quartiles(data)
        need(q1 < q3, "Q1 is not below Q3")
        need(R(g["q1"]) == q1 and R(g["q3"]) == q3, "the quartiles given are not those of the data shown")
        need(rep == "table" or (paper == 1 and 7 <= n <= 11) or (paper == 2 and 11 <= n <= 17), f"n = {n}")
        if u == "quartiles-of-data":
            need(asked == "Find the lower quartile and the upper quartile of the data.", f"asked {asked!r}")
            want = f"Q₁ = {dec_text(q1)}, Q₃ = {dec_text(q3)}"
            if rep == "terms":
                h = n // 2
                wrongs[DS_SKILL + "quartiles-discrete#1"] = {f"Q₁ = {dec_text(ds_median(xs[:h]))}, Q₃ = {dec_text(ds_median(xs[h + n % 2:]))}"}
        else:
            need(asked == "Find the interquartile range of the data.", f"asked {asked!r}")
            want = "IQR = " + dec_text(q3 - q1)
            wrongs[DS_SKILL + "quartiles-discrete#0"] = {"IQR = " + dec_text(q1 + q3)}
    elif u == "missing-value-from-mean":
        if rep == "terms":
            items = L[0].split(", ")
            need(L[0].count("k") == 1 and re.fullmatch(r"(\d+|k)(, (\d+|k))*", L[0]) is not None, f"can't read {L[0]!r}")
            mt = re.fullmatch(r"The mean of these numbers is (\d+(?:\.\d)?)\.", L[1])
            need(mt is not None and asked == "Find k.", f"can't read {L[1]!r} / {asked!r}")
            known = [R(x) for x in items if x != "k"]
            n = len(items)
            label = "k = "
        else:
            cm = next((c for c in DS_CONTEXTS if L[0].endswith(f" {c[0]}") or f" {c[0]} is " in L[0]), None)
            need(cm is not None, f"no story in {L[0]!r}")
            mt = re.fullmatch(r"The mean of (\d+) " + re.escape(cm[0]) + r" is (\d+(?:\.\d)?)\.", L[0])
            need(mt is not None, f"can't read {L[0]!r}")
            n = int(mt.group(1))
            m2 = re.fullmatch(r"(\d+) of them are (.+)\.", L[1])
            need(m2 is not None and int(m2.group(1)) == n - 1, f"can't read {L[1]!r}")
            known = [R(x) for x in re.split(r", | and ", m2.group(2))]
            need(asked == f"Find the missing {cm[1]}.", f"asked {asked!r}")
            label = f"missing {cm[1]} = "
            mt = re.fullmatch(r"The mean of (\d+) .+ is (\d+(?:\.\d)?)\.", L[0])
        M = R(mt.group(mt.lastindex))
        need(len(known) == n - 1 and 4 <= n <= 7, f"n = {n}")
        need((M * 10).q == 1, "the mean ends in more than one decimal place")
        k = M * n - sum(known)
        need(k == int(k) and 2 <= k <= 40 and k != M, f"k = {k} is not a whole number from 2 to 40, or is the mean")
        need(all(x == int(x) and 2 <= x <= 40 for x in known), "a known value is outside 2 to 40")
        need(R(g["k"]) == k, "the k given is not the missing value")
        want = label + dec_text(k)
    elif u == "missing-frequency-from-mean":
        need(rep == "table" and asked == "Find p.", f"asked {asked!r}")
        mt = re.fullmatch(r"The mean of the data is (\d+(?:\.\d)?)\.", L[0])
        need(mt is not None, f"can't read {L[0]!r}")
        M = R(mt.group(1))
        rows = q["table"]["rows"]
        need(rows[0][0] == "x" and rows[1][0] == "Frequency" and rows[1][1].count("p") == 1, "table")
        xs2 = [R(v) for v in rows[0][1]]
        at = rows[1][1].index("p")
        known_f = [(x, int(f)) for x, f in zip(xs2, rows[1][1]) if f != "p"]
        need(4 <= len(xs2) <= 5 and xs2 == [xs2[0] + i for i in range(len(xs2))] and 1 <= xs2[0] <= 6, f"the values {xs2}")
        need(all(2 <= f <= 9 for _, f in known_f), "a known frequency is outside 2 to 9")
        xp = xs2[at]
        need((M * 10).q == 1 and xs2[0] < M < xs2[-1] and M != xp, f"the mean {M} is not between the values, or is the missing column's value")
        F, S = sum(f for _, f in known_f), sum(x * f for x, f in known_f)
        p = (M * F - S) / (xp - M)
        need(p == int(p) and 2 <= p <= 9, f"p = {p} is not a whole number from 2 to 9")
        need(F + p <= 40, "the table's total is above 40")
        need(R(g["p"]) == p, "the p given is not the missing frequency")
        want = "p = " + dec_text(p)
        slip = (M * F - S) / xp
        if slip > 0 and (slip * 100).q == 1:
            wrongs[DS_SKILL + "mean-totals#1"] = {"p = " + dec_text(slip)}
    elif u == "combined-mean":
        gi = int(g["ctx"])
        a, b, what, alls = DS_GROUPS[gi]
        m1 = re.fullmatch(r"(\d+) " + re.escape(a) + r" have a mean " + re.escape(what) + r" of (\d+)\.", L[0])
        m2 = re.fullmatch(r"(\d+) " + re.escape(b) + r" have a mean " + re.escape(what) + r" of (\d+)\.", L[1])
        need(m1 is not None and m2 is not None, f"can't read {L!r}")
        n1, mu1, n2, mu2 = int(m1.group(1)), int(m1.group(2)), int(m2.group(1)), int(m2.group(2))
        need(asked == f"Find the mean {what} of all {n1 + n2} {alls}.", f"asked {asked!r}")
        need(n1 != n2 and mu1 != mu2 and 6 <= n1 <= 30 and 6 <= n2 <= 30 and 10 <= mu1 <= 90 and 10 <= mu2 <= 90, "the groups are outside the limits")
        mean = sp.Rational(n1 * mu1 + n2 * mu2, n1 + n2)
        need((mean * 10).q == 1, f"the combined mean {mean} does not end within one decimal place")
        need(mean != sp.Rational(mu1 + mu2, 2), "the combined mean is the mean of the means")
        want = "mean = " + dec_text(mean)
        wrongs[DS_SKILL + "mean-totals#0"] = {"mean = " + dec_text(sp.Rational(mu1 + mu2, 2))}
    elif u in ("choose-average", "choose-spread"):
        gi = int(g["ctx"])
        need(L[0] == DS_SPREADS[gi], f"the story {L[0]!r}")
        v8 = shown_list(L[1])
        need(len(v8) == 8 and len(set(v8)) == 8, "eight different values")
        sv = sorted(v8)
        need(v8 != sv, "the list is already in order")
        need(all(sp.Rational(4) <= x <= 12 for x in sv[:7]) and 30 <= sv[7] <= 60, "seven values from 4 to 12 and an outlier from 30 to 60")
        mean, med = sum(sv) / 8, ds_median(sv)
        q1, q3 = ds_quartiles(sv)
        need(mean >= sp.Rational(14, 10) * med, f"the mean {float(mean):.3f} is not 40% above the median {float(med):.3f}")
        need(sv[7] - sv[0] > 2 * (q3 - q1), "the range is not more than twice the IQR")
        if u == "choose-average":
            need(asked == "Which is the most appropriate measure of the centre of these data?", f"asked {asked!r}")
            want = DS_CENTRES[1]
            wrongs[DS_SKILL + "choose-measure#0"] = {DS_CENTRES[0]}
            wrongs[DS_SKILL + "choose-measure#1"] = {DS_CENTRES[2]}
            need({o["text"] for o in q["choices"]} <= set(DS_CENTRES), "an option is not a measure of centre")
        else:
            need(asked == "One value is an outlier. Which measure of spread is least affected by it?", f"asked {asked!r}")
            want = DS_MEASURES[1]
            need({o["text"] for o in q["choices"]} <= set(DS_MEASURES), "an option is not a measure of spread")
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wrongs, trap)
    if q["view"]["angle"] != "any":
        need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")
    for sol in q["solutions"]:
        need(want in sol["steps"][-1], f"{sol['name']}: the last step {sol['steps'][-1]!r} doesn't state {want!r}")
    return None, None


# ── composite-pair (fn-composite) ──

CP_PREFIX = "SL2.5.composite-"
CP_REFS = {"value-order": "SL2.5.composite-value#0", "product": "SL2.5.composite-value#1", "twice": "SL2.5.composite-value#2",
           "order": "SL2.5.composite-expression#0", "equal": "SL2.5.composite-expression#2", "undo": "SL2.5.find-inverse#1"}
CP_COEF_MAX = 60
CP_V_MAX = 200
K = sp.Symbol("k")


def cp_step(st, e):
    """One step of a rule said in words ("subtract 4"), applied to the expression e."""
    w = st.replace("−", "-").split(" ")
    if w[0] == "add":
        return e + R(w[1])
    if w[0] == "subtract":
        return e - R(w[1])
    if w[0] == "double":
        return 2 * e
    if w[0] == "treble":
        return 3 * e
    if w[0] == "square":
        return e**2
    if w[0] == "cube":
        return e**3
    if w[0] == "negate":
        return -e
    if w[0] == "multiply" and w[1] == "by":
        return R(w[2]) * e
    raise Fail(f"can't read the step {st!r}")


def cp_steps(text):
    e = X
    for st in text.split(", then "):
        e = cp_step(st, e)
    return sp.expand(e)


def cp_rules(q):
    """f and g (and h) from the lines of a question: 'f(x) = …' or 'f: double, then add 1.'"""
    out = {}
    for line in q["lines"]:
        m = re.fullmatch(r"([a-z])\(x\) = (.+)", line)
        if m:
            out[m.group(1)] = parse(m.group(2), letters=("k",))
            continue
        m = re.fullmatch(r"([a-z]): (.+)\.", line)
        if m:
            out[m.group(1)] = cp_steps(m.group(2))
    return out


def cp_poly_text(e, var="x"):
    co = poly_coeffs(sp.expand(e))
    deg = max(co) if co else 0
    return ext_terms([co.get(p, 0) for p in range(deg, -1, -1)], list(range(deg, -1, -1)), var)


def cp_int_poly(e, what):
    co = poly_coeffs(sp.expand(e))
    need(all(sp.Rational(c).q == 1 and abs(c) <= CP_COEF_MAX for c in co.values()), f"{what} has a coefficient that is not a whole number up to {CP_COEF_MAX}")


def cp_is_linear(e, what):
    co = poly_coeffs(sp.expand(e))
    need(set(co) <= {0, 1} and co.get(1, 0) != 0 and sp.Rational(co[1]).q == 1 and sp.Rational(co.get(0, 0)).q == 1, f"{what} is not a linear rule with whole numbers")


def cp_check_text(q, want, wrongs, trap=None):
    for t in [q["asked"]] + q["lines"] + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    gc_check_common(q, want, wrongs, trap)


def check_composite(q):
    ans, u, rep, L, asked = q["answer"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    lab = ans.get("label", "")
    r = cp_rules(q)
    wr = {}
    trap = None
    need(q["paper"] == 1 or u in ("value-inside-out", "parameter-from-value"), "a Paper 2 question that needs no calculator")
    need(q["paper"] == 1 or u == "parameter-from-value" or "sin x" in " ".join(L), "the paper is not the one the numbers need")
    if u == "value-inside-out":
        f, g = r["f"], r["g"]
        m = re.fullmatch(r"Find \(f∘g\)\((−?\d+)\)\.", asked.replace("-", "−"))
        need(m is not None, f"can't read {asked!r}")
        x0 = el_num(m.group(1))
        need(lab == f"(f∘g)({m.group(1)}) = ", f"label {lab!r}")
        cp_is_linear(g, "g")
        need(poly_coeffs(g)[1] != 1, "g has gradient 1")
        gx = g.subs(X, x0)
        v = f.subs(X, gx)
        if f == sp.sin(X):
            need(L[2] == "x is in radians.", "radians are not stated")
            val = lambda e: R(str(sp.N(e, 30)))
            want = lab + ext_sf(val(v))
            wr[CP_REFS["value-order"]] = {lab + ext_sf(val(g.subs(X, f.subs(X, x0))))}
            wr[CP_REFS["product"]] = {lab + ext_sf(val(f.subs(X, x0) * gx))}
            wr[CP_REFS["twice"]] = {lab + ext_sf(val(g.subs(X, gx)))}
            trap = lab + dec_text(R(sig3(val(v), 2).replace("−", "-")))
        else:
            need(abs(v) <= CP_V_MAX, "the value is more than 200")
            cp_int_poly(f, "f")
            want = lab + frac_text(v)
            wr[CP_REFS["value-order"]] = {lab + frac_text(g.subs(X, f.subs(X, x0)))}
            wr[CP_REFS["product"]] = {lab + frac_text(f.subs(X, x0) * gx)}
            wr[CP_REFS["twice"]] = {lab + frac_text(f.subs(X, f.subs(X, x0)))}
    elif u == "expression":
        f, g = r["f"], r["g"]
        m = re.fullmatch(r"Find \((f∘g|g∘f)\)\(x\), simplified\.", asked)
        need(m is not None, f"can't read {asked!r}")
        cp_is_linear(g, "g")
        h, h2 = (f.subs(X, g), g.subs(X, f)) if m.group(1) == "f∘g" else (g.subs(X, f), f.subs(X, g))
        cp_int_poly(h, "the composite")
        want = f"({m.group(1)})(x) = " + cp_poly_text(h)
        need(lab == f"({m.group(1)})(x) = ", f"label {lab!r}")
        wr[CP_REFS["order"]] = {lab + cp_poly_text(h2)}
    elif u == "parameter-from-value":
        m = re.fullmatch(r"Given that \(f∘g\)\((−?\d+)\) = (−?\d+), find (the possible values of k|k)\.", asked)
        need(m is not None, f"can't read {asked!r}")
        f, g = r["f"], r["g"]
        x0, V = el_num(m.group(1)), el_num(m.group(2))
        sols = sorted(sp.solve(f.subs(X, g.subs(X, x0)) - V, K))
        if q["paper"] == 2:
            # Paper 2: (a·x₀ + k)² = r with r not a square, k to 3 s.f.
            need(m.group(3) != "k" and len(sols) == 2 and g.has(K) and not f.has(K), "Paper 2 is the ± pair in g")
            need(all(not s_.is_rational for s_ in sols), "a Paper 2 k is a whole number: it needs no calculator")
            vals = [R(str(sp.N(s_, 30))) for s_ in sols]
            need(all(abs(v_) <= 30 for v_ in vals), "k is out of range")
            cp_check_text(q, f"k = {ext_sf(vals[0])} or k = {ext_sf(vals[1])}", {})
            return None, None
        need(all(s_.is_rational and s_.q == 1 and abs(s_) <= 20 for s_ in sols), f"k is not a whole number from −20 to 20: {sols}")
        if m.group(3) == "k":
            need(len(sols) == 1 and f.has(K) and not g.has(K), "a single k is in f")
            want = "k = " + frac_text(sols[0])
            other = sorted(sp.solve(g.subs(X, f.subs(X, x0)) - V, K))
            wr[CP_REFS["order"]] = {"k = " + frac_text(other[0])}
        else:
            need(len(sols) == 2 and g.has(K) and not f.has(K), "a ± pair of k is in g")
            want = f"k = {frac_text(sols[0])} or k = {frac_text(sols[1])}"
    elif u == "parameter-from-coefficients":
        m = re.fullmatch(r"The composite \(f∘g\)\(x\) can be written as (\d+)x² \+ qx \+ r\. Find the possible values of k\.", asked)
        need(m is not None, f"can't read {asked!r}")
        f, g = r["f"], r["g"]
        P = int(m.group(1))
        co = sp.Poly(sp.expand(f.subs(X, g)), X).coeff_monomial(X**2)
        sols = sorted(sp.solve(co - P, K))
        need(len(sols) == 2 and all(s_.q == 1 for s_ in sols) and sols[0] == -sols[1], f"k = {sols}")
        need(g.has(K) and not f.has(K), "k is in g only")
        want = f"k = {frac_text(sols[0])} or k = {frac_text(sols[1])}"
    elif u == "solve-composite":
        m = re.fullmatch(r"Solve \(f∘g\)\(x\) = (−?\d+)\.", asked)
        need(m is not None, f"can't read {asked!r}")
        f, g = r["f"], r["g"]
        cp_is_linear(g, "g")
        T = el_num(m.group(1))
        need(abs(T) <= CP_V_MAX, "the target is more than 200")
        roots = sp.Poly(sp.expand(f.subs(X, g)) - T, X).real_roots()
        need(all(rt_.is_rational and rt_.q == 1 for rt_ in roots), f"the solutions {roots} are not whole numbers")
        xs = sorted(set(roots))
        parts = [frac_text(x) for x in xs]
        want = "x = " + ((", ".join(parts[:-1]) + " or " + parts[-1]) if len(parts) > 1 else parts[0])
    elif u == "self-composite":
        f = r["f"]
        need(asked == "Find (f∘f)(x), simplified.", f"asked {asked!r}")
        h = f.subs(X, f)
        cp_int_poly(h, "the composite")
        want = "(f∘f)(x) = " + cp_poly_text(h)
    elif u == "compare-orders":
        need(asked == "Find f∘g and g∘f, and say whether they are equal.", f"asked {asked!r}")
        f, g = r["f"], r["g"]
        cp_is_linear(g, "g")
        fg, gf = sp.expand(f.subs(X, g)), sp.expand(g.subs(X, f))
        need(sp.simplify(fg - gf) != 0, "the composites are equal")
        cp_int_poly(fg, "f∘g")
        cp_int_poly(gf, "g∘f")
        T_ = cp_poly_text
        want = f"f∘g = {T_(fg)} and g∘f = {T_(gf)}: not equal"
        wr[CP_REFS["order"]] = {f"f∘g = {T_(gf)} and g∘f = {T_(fg)}: not equal"}
        wr[CP_REFS["equal"]] = {f"f∘g = {T_(fg)} and g∘f = {T_(fg)}: equal"}
    elif u == "build-from-words":
        m = re.fullmatch(r"A rule takes x and does this: (.+)\. Write it as one expression, h\(x\)\.", asked)
        need(m is not None, f"can't read {asked!r}")
        steps = m.group(1).split(", then ")
        need(2 <= len(steps) <= 3 and sum(1 for st in steps if st == "square") <= 1, "the chain is not 2 or 3 steps with one power at most")
        h = cp_steps(m.group(1))
        cp_int_poly(h, "h")
        want = "h(x) = " + cp_poly_text(h)
        rev = X
        for st in reversed(steps):
            rev = cp_step(st, rev)
        wr[CP_REFS["order"]] = {"h(x) = " + cp_poly_text(sp.expand(rev))}
    elif u == "decompose":
        h = r["h"]
        cp_int_poly(h, "h")
        pair = lambda t: re.fullmatch(r"g\(x\) = (.+) and f\(x\) = (.+)", t)
        mm = pair(q["answer_text"])
        need(mm is not None, f"can't read {q['answer_text']!r}")
        g, f = parse(mm.group(1)), parse(mm.group(2))
        cp_is_linear(g, "g")
        need(sp.expand(f.subs(X, g) - h) == 0, "f(g(x)) is not h")
        need(sp.degree(f, X) in (2, 3) and f.subs(X, X) == f, "f is not a power rule")
        for o in q["choices"]:
            if o["correct"]:
                continue
            m2 = pair(o["text"])
            need(m2 is not None, f"can't read the option {o['text']!r}")
            need(sp.expand(parse(m2.group(2)).subs(X, parse(m2.group(1))) - h) != 0, f"the option {o['text']!r} is also a decomposition of h")
            if o["ref"]:
                need(o["ref"] == CP_REFS["order"] and (parse(m2.group(1)), parse(m2.group(2))) == (f, g), f"{o['ref']} is not the swapped pair")
        want = q["answer_text"]
        wr[CP_REFS["order"]] = {o["text"] for o in q["choices"] if o["ref"]}
    elif u == "inner-from-composite":
        need(L[1].startswith("(f∘g)(x) = "), f"lines {L!r}")
        h = parse(L[1].split(" = ", 1)[1])
        f = r["f"]
        co = poly_coeffs(f)
        need(set(co) <= {0, 1} and co.get(1, 0) not in (0, 1) and co.get(0, 0) != 0, "f is not mx + c with m ≠ 0, 1 and c ≠ 0")
        m_, c_ = co[1], co.get(0, 0)
        g = sp.expand((h - c_) / m_)
        cp_int_poly(g, "g")
        need(sp.degree(g, X) in (1, 2), "g is not linear or quadratic")
        want = "g(x) = " + cp_poly_text(g)
        wr[CP_REFS["undo"]] = {"g(x) = " + cp_poly_text(sp.expand(h / m_ - c_))}
    elif u == "outer-from-composite":
        need(L[1].startswith("(f∘g)(x) = "), f"lines {L!r}")
        h = parse(L[1].split(" = ", 1)[1])
        g = r["g"]
        cp_is_linear(g, "g")
        co = poly_coeffs(g)
        a_, b_ = co[1], co.get(0, 0)
        f = sp.expand(h.subs(X, (X - b_) / a_))
        cp_int_poly(f, "f")
        need(sp.degree(f, X) == 2, "f is not a quadratic")
        want = "f(x) = " + cp_poly_text(f)
    else:
        raise Fail(f"the checker has no solver for {u}")
    cp_check_text(q, want, wr, trap)
    return None, None


# ── inverse-rule (fn-inverse-algebraic) ──
# A function of x is picked from four written options, so the checker reads each option
# back with SymPy and tests it as maths: the right one is the inverse, every wrong one is not.

from sympy.calculus.util import continuous_domain, function_range

XR = sp.Symbol("x", real=True)
IR_SUBS = str.maketrans("₀₁₂₃₄₅₆₇₈₉", "0123456789")
IR_REFS = {"reciprocal": "SL2.5.find-inverse#0", "order": "SL2.5.find-inverse#1", "pm": "SL2.5.find-inverse#2",
           "domain-of-f": "SL2.5.inverse-domain-range#0", "y-intercept": "SL2.5.inverse-domain-range#1",
           "excluded": "SL2.8.rational-inverse#1", "one": "SL2.5.identity#0", "solve-inverse": "SL2.5.identity#1",
           "reflect": "SL2.11.reflect#1"}
IR_POINTS = [sp.Rational(n, 2) for n in range(-16, 21)]


def ir_expr(text, letters=()):
    """A function the game writes ('(x − 3)/2', '3 + √(x − 2)', 'log₂(x + 1)', '2^x − 1') as SymPy."""
    t = text.replace("−", "-").replace("²", "**2").replace("√x", "sqrt(x)").replace("√", "sqrt")
    t = re.sub(r"log([₀-₉]+)\(([^()]*)\)", lambda m: f"log({m.group(2)}, {m.group(1).translate(IR_SUBS)})", t)
    t = re.sub(r"log([₀-₉]+) x", lambda m: f"log(x, {m.group(1).translate(IR_SUBS)})", t)
    t = t.replace("ln x", "log(x)").replace("ln(", "log(").replace("e^x", "exp(x)").replace("^", "**")
    need(re.fullmatch(r"[0-9x+\-*/(). a-z,]+", t) is not None, f"can't read the function {text!r}")
    local = {"x": XR}
    for n in letters:
        local[n] = LETTERS[n]
    return parse_expr(t, local_dict=local, transformations=TRANSFORMS)


def ir_step(st, e):
    st = st.replace("−", "-")
    w = st.split(" ")
    if w[0] in ("add", "subtract", "double", "treble", "negate", "square", "halve") or st.startswith("multiply by") or st.startswith("divide by"):
        return cp_step(st, e) if w[0] not in ("halve", "divide") else (e / 2 if w[0] == "halve" else e / R(w[2]))
    if st == "take the square root":
        return sp.sqrt(e)
    if st.startswith("raise "):
        base = w[1]
        return sp.exp(e) if base == "e" else R(base) ** e
    if st == "take the natural log":
        return sp.log(e)
    if st.startswith("take log base "):
        return sp.log(e, R(w[3]))
    raise Fail(f"can't read the step {st!r}")


def ir_steps(text):
    e = XR
    for st in text.split(", then "):
        e = ir_step(st, e)
    return e


def ir_rule(line):
    """(expression, restriction) of 'f(x) = …, for x ≥ 3', 'f: double, then add 1.' or 'f⁻¹: …'."""
    m = re.fullmatch(r"f\(x\) = (.+?)(?:, for x (≥|≤) (−?\d+))?", line)
    if m:
        return ir_expr(m.group(1)), (None if m.group(2) is None else (m.group(2), el_num(m.group(3))))
    m = re.fullmatch(r"f(?:⁻¹)?: (.+)\.", line)
    need(m is not None, f"can't read the rule {line!r}")
    return ir_steps(m.group(1)), None


def ir_range(e, dom):
    """The range of e on dom. SymPy can't do a bare c**x, so powers of a number become exp."""
    e2 = e.replace(lambda t: t.is_Pow and t.base.is_number and t.exp.has(XR), lambda t: sp.exp(t.exp * sp.log(t.base)))
    return function_range(e2, XR, dom)


def ir_domain(e, restriction):
    d = continuous_domain(e, XR, sp.S.Reals)
    if restriction is not None:
        rel, k = restriction
        d = d.intersect(sp.Interval(k, sp.oo) if rel == "≥" else sp.Interval(-sp.oo, k))
    return d


def ir_cond(S, var):
    """A set of reals as the game writes a condition: 'x ≥ 3', 'x ≠ 2', 'all real x'."""
    if S == sp.S.Reals:
        return f"all real {var}"
    if isinstance(S, sp.Union):
        need(len(S.args) == 2 and all(isinstance(i, sp.Interval) and i.is_open for i in S.args), f"{S} is not two open rays")
        lo, hi = sorted(S.args, key=lambda i: 0 if i.start == -sp.oo else 1)
        need(lo.start == -sp.oo and hi.end == sp.oo and lo.end == hi.start, f"{S} is not the reals minus a point")
        return f"{var} ≠ {frac_text(lo.end)}"
    need(isinstance(S, sp.Interval), f"{S} is not an interval")
    if S.end == sp.oo:
        return f"{var} {'>' if S.left_open else '≥'} {frac_text(S.start)}"
    need(S.start == -sp.oo, f"{S} is bounded")
    return f"{var} {'<' if S.right_open else '≤'} {frac_text(S.end)}"


def ir_coeffs(e):
    return {int(m[0]): c for m, c in sp.Poly(sp.expand(e), XR).terms()}


def ir_fn(e):
    return sp.lambdify(XR, e, "mpmath")


def ir_close(a, b):
    try:
        return abs(mpmath.mpmathify(a) - mpmath.mpmathify(b)) < mpmath.mpf(10) ** -12
    except (TypeError, ValueError):
        return False


def ir_inside(S, x0):
    return bool(S.contains(x0) == sp.true)


def ir_points(S, e):
    """x-values inside S where e is a finite real number."""
    f = ir_fn(e)
    out = []
    mpmath.mp.dps = 40
    for x0 in IR_POINTS:
        if not ir_inside(S, x0):
            continue
        try:
            y = f(mpmath.mpf(x0.p) / x0.q)
        except (ZeroDivisionError, ValueError, TypeError):
            continue
        if isinstance(y, mpmath.mpf) and abs(y) < 1e6:
            out.append(x0)
    need(len(out) >= 4, "fewer than four test points")
    return out


def ir_is_inverse(F, f, dom):
    """True when F(f(x)) = x on the sample points of dom, with F defined there."""
    ff, Ff = ir_fn(f), ir_fn(F)
    for x0 in ir_points(dom, f):
        xv = mpmath.mpf(x0.p) / x0.q
        try:
            back = Ff(ff(xv))
        except (ZeroDivisionError, ValueError, TypeError):
            return False
        if not (isinstance(back, mpmath.mpf) and ir_close(back, xv)):
            return False
    return True


def ir_same(a, b, S):
    """Two expressions agree on the sample points of S."""
    fa, fb = ir_fn(a), ir_fn(b)
    for x0 in ir_points(S, a):
        xv = mpmath.mpf(x0.p) / x0.q
        try:
            va, vb = fa(xv), fb(xv)
        except (ZeroDivisionError, ValueError, TypeError):
            return False
        if not (isinstance(vb, mpmath.mpf) and ir_close(va, vb)):
            return False
    return True


def ir_split(text, prefix="f⁻¹(x) = "):
    """('F', tail) from 'f⁻¹(x) = F, domain …' or 'f⁻¹(x) = F = −f(−x)'."""
    need(text.startswith(prefix), f"{text!r} does not start with {prefix!r}")
    body = text[len(prefix):]
    for sep in (", domain ", ", which ", " = "):
        if sep in body:
            F, tail = body.split(sep, 1)
            return F, sep.strip(" ,") + " " + tail if sep != " = " else tail
    return body, ""


def ir_graph(q, f, dom):
    g = q.get("graph")
    need(g is not None, "no graph")
    curves = g["curves"]
    need(curves[-1] == [[-8.0, -8.0], [8.0, 8.0]], "the line y = x is not drawn last")
    ff = ir_fn(f)
    for c in curves[:-1]:
        need(len(c) > 5, "a curve with too few points")
        for x0, y0 in c:
            need(abs(ff(mpmath.mpf(x0)) - y0) < 1e-4 * max(1, abs(y0)), f"the graph's point ({x0}, {y0}) is not on f")


def check_inverse(q):
    ans, u, rep, L, asked = q["answer"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    need(q["paper"] in (1, 2), "paper")
    for t in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    right = q["answer_text"]
    ch = q["choices"]
    wr = {}
    if u == "restrict-for-inverse":
        f = parse(rhs(L[0]))
        co = poly_coeffs(f)
        need(set(co) == {0, 1, 2} or set(co) == {1, 2} or set(co) == {0, 2} or set(co) == {2}, f"f is not a quadratic: {f}")
        h = -co.get(1, 0) / (2 * co[2])
        need(h.q == 1 and h != 0, f"the vertex {h} is not a whole number")
        least = "least value of k for which f has an inverse on the domain x ≥ k." in asked
        need(least or "greatest value of k for which f has an inverse on the domain x ≤ k." in asked, f"asked {asked!r}")
        if q["graph"] is not None:
            ir_graph(q, f, sp.S.Reals)
        wr[IR_REFS["y-intercept"]] = {"k = 0"}
        gc_check_common(q, "k = " + frac_text(h), wr)
        return None, None
    if u == "self-inverse-constant":
        fk = ir_expr(rhs(L[0]), letters=("k",))
        numer = sp.numer(sp.together(fk.subs(XR, fk) - XR))
        sols = sp.solve(sp.Poly(sp.expand(numer), XR).all_coeffs(), K, dict=True)
        vals = {s_[K] for s_ in sols if K in s_}
        need(len(vals) == 1, f"k = {vals}")
        k0 = vals.pop()
        need(k0.is_rational and k0.q == 1, f"k = {k0}")
        gc_check_common(q, "k = " + frac_text(k0), {})
        return None, None
    f, restriction = ir_rule(L[0] if not L[0].startswith("f⁻¹(x)") else "f(x) = 0")
    dom = ir_domain(f, restriction) if not L[0].startswith("f⁻¹(x)") else None
    if u in ("function-from-inverse",):
        G = ir_expr(rhs(L[0])) if L[0].startswith("f⁻¹(x) = ") else ir_steps(re.fullmatch(r"f⁻¹: (.+)\.", L[0]).group(1))
        gdom = continuous_domain(G, XR, sp.S.Reals)
        need(asked == "Find f(x).", f"asked {asked!r}")
        truth = {}
        for o in ch:
            mm = re.fullmatch(r"f\(x\) = (.+)", o["text"])
            need(mm is not None, f"can't read the option {o['text']!r}")
            E = ir_expr(mm.group(1))
            ok = True
            gf, Ef = ir_fn(G), ir_fn(E)
            for y0 in ir_points(gdom, G):
                yv = mpmath.mpf(y0.p) / y0.q
                try:
                    back = Ef(gf(yv))
                except (ZeroDivisionError, ValueError, TypeError):
                    ok = False
                    break
                if not (isinstance(back, mpmath.mpf) and ir_close(back, yv)):
                    ok = False
                    break
            truth[o["text"]] = ok
            if o["ref"]:
                wr.setdefault(o["ref"], set()).add(o["text"])
        need(truth[right] and sum(truth.values()) == 1, f"the options that are inverses of f⁻¹: {[t for t, v in truth.items() if v]}")
        gc_check_common(q, right, {k: v for k, v in wr.items() if all(not truth[t] for t in v)})
        return None, None
    need(dom is not None, "no rule")
    rng = ir_range(f, dom)
    if q["graph"] is not None:
        ir_graph(q, f, dom)
    if u in ("inverse-linear", "inverse-rational", "inverse-restricted-quadratic", "inverse-root", "inverse-exponential"):
        # domain and range of f⁻¹ (root, exponential): the range and the domain of f
        dom_text, ran_text = ir_cond(rng, "x"), ir_cond(dom, "y")
        f_dom_text, f_ran_text = ir_cond(dom, "x"), ir_cond(rng, "y")
        truth = {}
        for o in ch:
            if u == "inverse-root":
                mm = re.fullmatch(r"(f⁻¹\(x\) = .+), domain (.+), range (.+)", o["text"])
                need(mm is not None, f"can't read {o['text']!r}")
                F, claim = mm.group(1)[len("f⁻¹(x) = "):], (mm.group(2), mm.group(3))
                want_claim = (dom_text, ran_text)
                f_claim = (f_dom_text, f_ran_text)
            elif u == "inverse-exponential":
                mm = re.fullmatch(r"(f⁻¹\(x\) = .+), domain (.+)", o["text"])
                need(mm is not None, f"can't read {o['text']!r}")
                F, claim = mm.group(1)[len("f⁻¹(x) = "):], mm.group(2)
                want_claim, f_claim = dom_text, f_dom_text
            else:
                need(o["text"].startswith("f⁻¹(x) = "), f"can't read {o['text']!r}")
                F, claim, want_claim, f_claim = o["text"][len("f⁻¹(x) = "):], None, None, None
            is_inv = "±" not in F and ir_is_inverse(ir_expr(F), f, dom)
            truth[o["text"]] = is_inv and claim == want_claim
            if o["ref"]:
                ref = o["ref"]
                if ref == IR_REFS["domain-of-f"]:
                    need(is_inv and claim == f_claim, f"{o['text']!r} is not the right inverse with f's own domain")
                elif ref == IR_REFS["reciprocal"]:
                    need(ir_same(ir_expr(F), 1 / f, dom), f"{o['text']!r} is not 1/f(x)")
                elif ref == IR_REFS["order"]:
                    a_ = ir_coeffs(f)
                    need(not is_inv and ir_same(ir_expr(F), XR / a_[1] - a_.get(0, 0), dom), f"{o['text']!r} is not x/a − b")
                elif ref == IR_REFS["pm"]:
                    # A ± in the answer, or the other branch of the root: 2h − (the right inverse).
                    other = 2 * restriction[1] - ir_expr(right[len("f⁻¹(x) = "):])
                    need("±" in F or (not is_inv and ir_same(ir_expr(F), other, rng)), f"{o['text']!r} is not a ± or the other branch")
                else:
                    raise Fail(f"the checker can't confirm {ref} on {u}")
                wr.setdefault(ref, set()).add(o["text"])
        need(truth[right] and sum(truth.values()) == 1, f"the options that are right: {[t for t, v in truth.items() if v]}")
        if u == "inverse-restricted-quadratic":
            need(restriction is not None, "no restriction on the quadratic")
        gc_check_common(q, right, wr)
        return None, None
    # Conditions and values (domain, range, asymptotes, constants)
    if u == "inverse-domain":
        need(asked == "Find the domain of f⁻¹.", f"asked {asked!r}")
        want = ir_cond(rng, "x")
        wr[IR_REFS["domain-of-f"]] = {ir_cond(dom, "x")}
    elif u == "inverse-range":
        need(asked == "Find the range of f⁻¹.", f"asked {asked!r}")
        want = ir_cond(dom, "y")
        wr[IR_REFS["domain-of-f"]] = {ir_cond(rng, "y")}
    elif u == "rational-inverse-domain":
        want = f"domain {ir_cond(rng, 'x')}, range {ir_cond(dom, 'y')}"
        wr[IR_REFS["excluded"]] = {f"domain {ir_cond(dom, 'x')}, range {ir_cond(rng, 'y')}"}
    elif u == "inverse-asymptotes":
        vert = sp.solve(sp.denom(sp.together(f)), XR)
        ends = {sp.limit(f, XR, sp.oo), sp.limit(f, XR, -sp.oo)}
        finite = [e_ for e_ in ends if e_.is_rational]
        if not vert and not finite:
            # SymPy's limit of c**x at −∞ is wrong: take the finite bound of the range instead.
            finite = [b_ for b_ in {rng.inf, rng.sup} if b_.is_rational]
        need(len(finite) == 1, f"f has {len(finite)} horizontal asymptotes")
        horiz = finite[0]
        if vert:
            need(len(vert) == 1 and horiz.is_rational, "f has one vertical and one horizontal asymptote")
            want = f"x = {frac_text(horiz)} and y = {frac_text(vert[0])}"
            wr[IR_REFS["excluded"]] = {f"x = {frac_text(vert[0])} and y = {frac_text(horiz)}"}
        else:
            need(horiz.is_rational, "an exponential has one horizontal asymptote")
            want = f"x = {frac_text(horiz)}"
            wr[IR_REFS["excluded"]] = {f"y = {frac_text(horiz)}"}
    elif u == "show-self-inverse":
        truth = {}
        for o in ch:
            mm = re.fullmatch(r"f⁻¹\(x\) = (.+), which (is|is not) f\(x\)", o["text"])
            need(mm is not None, f"can't read {o['text']!r}")
            F = ir_expr(mm.group(1))
            truth[o["text"]] = ir_is_inverse(F, f, dom) and ir_same(F, f, dom) == (mm.group(2) == "is")
        need(truth[right] and sum(truth.values()) == 1, f"the options that are right: {[t for t, v in truth.items() if v]}")
        gc_check_common(q, right, {})
        return None, None
    elif u == "inverse-as-reflections":
        truth = {}
        for o in ch:
            mm = re.fullmatch(r"f⁻¹\(x\) = (.+) = (−f\(−x\)|f\(−x\)|−f\(x\))", o["text"])
            need(mm is not None, f"can't read {o['text']!r}")
            F = ir_expr(mm.group(1))
            R_ = {"−f(−x)": -f.subs(XR, -XR), "f(−x)": f.subs(XR, -XR), "−f(x)": -f}[mm.group(2)]
            inv = ir_is_inverse(F, f, dom)
            truth[o["text"]] = inv and ir_same(F, R_, dom)
            if o["ref"]:
                need(o["ref"] == IR_REFS["reflect"] and inv and mm.group(2) != "−f(−x)", f"{o['text']!r} is not the reflection slip")
                wr.setdefault(o["ref"], set()).add(o["text"])
        need(truth[right] and sum(truth.values()) == 1, f"the options that are right: {[t for t, v in truth.items() if v]}")
        gc_check_common(q, right, wr)
        return None, None
    elif u == "compose-to-identity":
        g = ir_expr(rhs(L[1]))
        c = sp.simplify(f.subs(XR, g))
        co = ir_coeffs(c)
        need(set(co) <= {0, 1}, f"f(g(x)) = {c}")
        want = ("(f∘g)(x) = x: g is the inverse of f" if c == XR else f"(f∘g)(x) = {cp_poly_text(c.subs(XR, X))}: g is not the inverse of f")
    elif u == "identity-value":
        m = re.fullmatch(r"Given that f has an inverse, find \(f∘f⁻¹\)\((−?\d+)\)\.", asked)
        need(m is not None, f"can't read {asked!r}")
        n = el_num(m.group(1))
        need(ir_inside(rng, n), f"{n} is not in the range of f, so f⁻¹({n}) is not defined")
        want = f"(f∘f⁻¹)({m.group(1)}) = {m.group(1)}"
        wr[IR_REFS["one"]] = {f"(f∘f⁻¹)({m.group(1)}) = 1"}
    elif u == "solve-inverse-equals":
        m = re.fullmatch(r"Solve f⁻¹\(x\) = (−?\d+)\.", asked)
        need(m is not None, f"can't read {asked!r}")
        c0 = el_num(m.group(1))
        need(ir_inside(dom, c0), f"{c0} is not in the domain of f")
        v = sp.nsimplify(f.subs(XR, c0))
        need(v.is_rational and v.q == 1, f"f({c0}) = {v} is not a whole number")
        want = "x = " + frac_text(v)
        sol = [t for t in sp.solve(f - c0, XR) if t.is_real and ir_inside(dom, t)]
        if len(sol) == 1 and sol[0].is_rational:
            wr[IR_REFS["solve-inverse"]] = {"x = " + frac_text(sol[0])}
    else:
        raise Fail(f"the checker has no solver for {u}")
    gc_check_common(q, want, wr)
    return None, None


# ── composite-graph-table (fn-graph-table-composite-inverse) ──
# f and g are read back from the table, the graph's dots or the sentence the question
# shows, never from the engine's givens.

GT_REFS = {"notation-rule": "SL2.2.evaluate-notation#1", "shifted": "SL2.2.evaluate-notation#2", "solve-as-value": "SL2.3.read-graph#0",
           "one-crossing": "SL2.3.read-graph#1", "order": "SL2.5.composite-value#0", "product": "SL2.5.composite-value#1",
           "twice": "SL2.5.composite-value#2", "reciprocal": "SL2.2.inverse-undo#0", "axis": "SL2.2.inverse-undo#1",
           "value-not-inverse": "SL2.2.inverse-undo#2", "solve-inverse": "SL2.5.identity#1", "domain-of-f": "SL2.5.inverse-domain-range#0",
           "y-intercept": "SL2.5.inverse-domain-range#1", "every-inverse": "SL2.5.inverse-domain-range#2"}


def gt_int(text):
    return int(text.replace("−", "-"))


def gt_read(q):
    """{'f': {x: y}, 'g': {x: y}} from the table, the graph's dots and the sentence."""
    out = {"f": {}, "g": {}}
    t = q.get("table")
    if t:
        xs = [gt_int(c) for c in t["rows"][0][1]]
        for label, cells in t["rows"][1:]:
            name = label[0]
            for x, c in zip(xs, cells):
                if c != "?":
                    out[name][x] = gt_int(c)
    gr = q.get("graph")
    if gr and gr["points"] and not q["lines"][0].startswith("f(x)"):
        for p in gr["points"]:
            need(p["x"] == int(p["x"]) and p["y"] == int(p["y"]), "a dot is off the grid")
            out["f"][int(p["x"])] = int(p["y"])
        curve = gr["curves"][0]
        need([(int(a), int(b)) for a, b in curve] == [(int(p["x"]), int(p["y"])) for p in gr["points"]], "the lines don't join the dots")
    for line in q["lines"]:
        for name, x, y in re.findall(r"([fg])\((−?\d+)\) = (−?\d+)", line):
            out[name][gt_int(x)] = gt_int(y)
    return out


def gt_monotone(d):
    ys = [d[x] for x in sorted(d)]
    need(all(a < b for a, b in zip(ys, ys[1:])) or all(a > b for a, b in zip(ys, ys[1:])), f"{ys} is not one-to-one")


def gt_inv(d, y):
    xs = [x for x in d if d[x] == y]
    need(len(xs) == 1, f"f⁻¹({y}) has {len(xs)} values")
    return xs[0]


def gt_num(label, v):
    return label.replace("-", "−") + frac_text(v)


def check_graph_table(q):
    ans, u, rep, L, asked = q["answer"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    need(q["paper"] == 1, "the graph and table readings are Paper 1")
    for t in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    wr = {}
    if u == "value-from-rule":
        f = parse(rhs(L[0]))
        a = gt_int(re.fullmatch(r"Find f\((−?\d+)\)\.", asked).group(1))
        v = f.subs(X, a)
        co = poly_coeffs(f)
        if a != 0 and co.get(2, 0) != 0:
            wr[GT_REFS["notation-rule"]] = {gt_num(f"f({a}) = ".replace("-", "−"), co.get(0, 0) + co.get(1, 0) * a - co[2] * a * a)}
        if rep == "graph":
            curve = q["graph"]["curves"][0]
            need(all(abs(float(f.subs(X, x0)) - y0) < 1e-6 for x0, y0 in curve), "the curve is not the rule")
        gc_check_common(q, gt_num(f"f({a}) = ", v), wr)
        return None, None
    if u == "self-composite-read" and L[0].startswith("f(x) = "):
        f = parse(rhs(L[0]))
        fn = {x: f.subs(X, x) for x in range(-4, 9)}
        a = gt_int(re.fullmatch(r"Find \(f∘f\)\((−?\d+)\)\.", asked).group(1))
        mid = f.subs(X, a)
        v = f.subs(X, mid)
        need(abs(mid) <= 6 and abs(v) <= 99, "the numbers are out of range")
        wr[GT_REFS["product"]] = {gt_num(f"(f∘f)({a}) = ", mid * mid)}
        if rep != "equation":
            d = gt_read(q)["f"]
            need(all(d[x] == fn[x] for x in d), "the table or graph is not the rule")
        gc_check_common(q, gt_num(f"(f∘f)({a}) = ", v), wr)
        return None, None
    d = gt_read(q)
    f, g = d["f"], d["g"]
    xs = sorted(f)
    need(len(xs) >= 3 and xs == list(range(xs[0], xs[0] + len(xs))) or rep == "words", "the inputs are not consecutive")
    if u == "read-value":
        a = gt_int(re.fullmatch(r"Find f\((−?\d+)\)\.", asked).group(1))
        want = gt_num(f"f({a}) = ", f[a])
    elif u == "self-composite-read":
        a = gt_int(re.fullmatch(r"Find \(f∘f\)\((−?\d+)\)\.", asked).group(1))
        gt_monotone(f)
        need(f[a] in f, "f(a) is not an input")
        mid = f[a]
        wr[GT_REFS["product"]] = {gt_num(f"(f∘f)({a}) = ", mid * mid)}
        want = gt_num(f"(f∘f)({a}) = ", f[mid])
    elif u == "composite-from-table":
        m = re.fullmatch(r"Find \((f∘g|g∘f)\)\((−?\d+)\)\.", asked)
        need(m is not None, f"can't read {asked!r}")
        a = gt_int(m.group(2))
        gt_monotone(f)
        gt_monotone(g)
        outer, inner = (f, g) if m.group(1) == "f∘g" else (g, f)
        need(inner[a] in outer, "the inner value is not an input of the outer rule")
        lab = f"({m.group(1)})({a}) = "
        want = gt_num(lab, outer[inner[a]])
        if outer[a] in inner:
            wr[GT_REFS["order"]] = {gt_num(lab, inner[outer[a]])}
        wr[GT_REFS["product"]] = {gt_num(lab, f[a] * g[a])}
        if inner[a] in inner:
            wr[GT_REFS["twice"]] = {gt_num(lab, inner[inner[a]])}
    elif u == "solve-from-table":
        k = gt_int(re.fullmatch(r"Solve f\(x\) = (−?\d+)\.", asked).group(1))
        gt_monotone(f)
        x = gt_inv(f, k)
        want = "x = " + frac_text(x)
        if k in f and k != x:
            wr[GT_REFS["solve-as-value"]] = {"x = " + frac_text(f[k])}
    elif u == "inverse-value-read":
        b = gt_int(re.fullmatch(r"Find f⁻¹\((−?\d+)\)\.", asked).group(1))
        gt_monotone(f)
        a = gt_inv(f, b)
        lab = f"f⁻¹({b}) = "
        want = gt_num(lab, a)
        if b in f:
            wr[GT_REFS["value-not-inverse"]] = {gt_num(lab, f[b])}
            if f[b] != 0:
                wr[GT_REFS["reciprocal"]] = {gt_num(lab, sp.Rational(1, f[b]))}
    elif u in ("inverse-domain-read", "inverse-range-read"):
        gt_monotone(f)
        m = re.fullmatch(r"The graph of f is shown, for (−?\d+) ≤ x ≤ (−?\d+)\.", L[0])
        need(m is not None and (gt_int(m.group(1)), gt_int(m.group(2))) == (xs[0], xs[-1]), "the stated domain is not the graph's")
        ylo, yhi = min(f.values()), max(f.values())
        fx = lambda lo, hi, v: f"{frac_text(lo)} ≤ {v} ≤ {frac_text(hi)}"
        if u == "inverse-domain-read":
            want, wr[GT_REFS["domain-of-f"]] = fx(ylo, yhi, "x"), {fx(xs[0], xs[-1], "x")}
        else:
            want, wr[GT_REFS["domain-of-f"]] = fx(xs[0], xs[-1], "y"), {fx(ylo, yhi, "y")}
    elif u == "solve-inverse-equation":
        m = re.fullmatch(r"Solve f⁻¹\((.+)\) = (−?\d+)\.", asked)
        need(m is not None, f"can't read {asked!r}")
        inner = parse(m.group(1))
        gt_monotone(f)
        c = gt_int(m.group(2))
        x = sp.solve(inner - f[c], X)
        need(len(x) == 1 and x[0].q == 1, f"x = {x}")
        want = "x = " + frac_text(x[0])
        if c in f.values():
            back = gt_inv(f, c)
            sl = sp.solve(inner - back, X)
            need(len(sl) == 1, "the slip has one value")
            wr[GT_REFS["solve-inverse"]] = {"x = " + frac_text(sl[0])}
    elif u == "value-at-shifted-input":
        gt_monotone(f)
        k = gt_inv(f, 0)
        need(k + 1 in f, "k + 1 is not an input")
        want = gt_num("f(k + 1) = ", f[k + 1])
        wr[GT_REFS["shifted"]] = {"f(k + 1) = 1"}
    elif u == "mixed-inverse-composite":
        b = gt_int(re.fullmatch(r"Find \(f∘g⁻¹\)\((−?\d+)\)\.", asked).group(1))
        gt_monotone(f)
        gt_monotone(g)
        lab = f"(f∘g⁻¹)({b}) = "
        want = gt_num(lab, f[gt_inv(g, b)])
        if b in g:
            wr[GT_REFS["value-not-inverse"]] = {gt_num(lab, f[g[b]] if g[b] in f else f[b])}
    elif u == "missing-entry":
        m = re.fullmatch(r"The table has one entry missing\. Given that \(f∘g\)\((−?\d+)\) = (−?\d+), find g\(\1\)\.", asked)
        need(m is not None, f"can't read {asked!r}")
        a, v = gt_int(m.group(1)), gt_int(m.group(2))
        need(a not in g and "?" in " ".join(" ".join(r[1]) for r in q["table"]["rows"]), "the blank is not g(a)")
        gt_monotone(f)
        want = gt_num(f"g({a}) = ", gt_inv(f, v))
    elif u == "inverse-points":
        pts = {}
        for p in q["graph"]["points"]:
            m = re.fullmatch(r"([AB]) \((−?\d+), (−?\d+)\)", p["label"] or "")
            if m:
                need(int(p["x"]) == gt_int(m.group(2)) and int(p["y"]) == gt_int(m.group(3)), "a label is not its point")
                pts[m.group(1)] = (int(p["x"]), int(p["y"]))
        need(set(pts) == {"A", "B"}, "the points A and B")
        gt_monotone(f)
        right = sorted((y, x) for x, y in pts.values())
        want = " and ".join(f"({frac_text(x)}, {frac_text(y)})" for x, y in right)
        axis = sorted((x, -y) for x, y in pts.values())
        wr[GT_REFS["axis"]] = {" and ".join(f"({frac_text(x)}, {frac_text(y)})" for x, y in axis)}
    elif u == "count-solutions":
        k = gt_int(re.fullmatch(r"Find every solution of f\(x\) = (−?\d+)\.", asked).group(1))
        sols = []
        for x0, x1 in zip(xs, xs[1:]):
            lo, hi = sorted((f[x0], f[x1]))
            need(not (lo < k < hi), "the line y = k crosses between two dots")
        sols = [x for x in xs if f[x] == k]
        need(len(sols) == 2, f"{len(sols)} solutions")
        want = "x = " + " or ".join(frac_text(x) for x in sols)
        wr[GT_REFS["one-crossing"]] = {"x = " + frac_text(sols[1])}
    elif u == "why-no-inverse":
        pat = r"It is not one-to-one: f\((−?\d+)\) = f\((−?\d+)\) = (−?\d+), so f⁻¹\(\3\) would have two values"
        truth = {}
        for o in q["choices"]:
            m = re.fullmatch(pat, o["text"])
            truth[o["text"]] = bool(m) and gt_int(m.group(1)) != gt_int(m.group(2)) and f.get(gt_int(m.group(1))) == f.get(gt_int(m.group(2))) == gt_int(m.group(3))
        need(truth[q["answer_text"]] and sum(truth.values()) == 1, f"the options that are true: {[t for t, v in truth.items() if v]}")
        wr[GT_REFS["every-inverse"]] = {"It has one: reflect the graph in y = x"}
        want = q["answer_text"]
    elif u == "restrict-from-graph":
        ys = [f[x] for x in xs]
        turns = [x for i, x in enumerate(xs[1:-1], 1) if (ys[i] - ys[i - 1]) * (ys[i + 1] - ys[i]) < 0]
        need(len(turns) == 1, f"turns at {turns}")
        want = "k = " + frac_text(turns[0])
        need(turns[0] != 0, "the turn is at x = 0, so the y-intercept slip is right")
        wr[GT_REFS["y-intercept"]] = {"k = 0"}
    else:
        raise Fail(f"the checker has no solver for {u}")
    gc_check_common(q, want, wr)
    return None, None


# ── fn-pre-rearrange ──
# The rearrangement is picked from four written options. Each option's equation is solved
# for the subject with SymPy: the right one gives the formula's own solutions, a wrong one
# does not. The checker's own table of the one-step formulas (RA_FORMULAS) reads a sentence.

RA_T = "fn-pre-rearrange"
RA_FORMULAS = {
    "The speed v is the starting speed u plus the acceleration a times the time t.": "v = u + a*t",
    "The distance d is the speed s times the time t.": "d = s*t",
    "The force F is the mass m times the acceleration a.": "F = m*a",
    "The area A is the length l times the width w.": "A = l*w",
    "y is x plus 5.": "y = x + 5",
    "The circumference C is π times the diameter d.": "C = pi*d",
}
RA_SYMS = {ch: sp.Symbol(ch) for ch in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"}


def ra_parse(text):
    """A formula side as the game writes it: 'y/2 + 3', '(m − 4)/(k − 2)', '√(y − 1)', 'π', '2yx'."""
    t = text.replace("−", "-").replace("²", "**2").replace("√", "@").replace("π", "#")
    t = re.sub(r"@([A-Za-z])", r"@(\1)", t)
    t = re.sub(r"(?<=[A-Za-z0-9#)])(?=[A-Za-z@#(])", "*", t)
    t = re.sub(r"(?<=[A-Za-z#)])(?=[0-9])", "*", t)
    t = t.replace("*@", "*sqrt").replace("@", "sqrt").replace("#", "pi")
    t = t.replace("*(", "*(")
    need(re.fullmatch(r"[0-9A-Za-z+\-*/(). ]+", t) is not None, f"can't read the formula {text!r}")
    return parse_expr(t, local_dict=dict(RA_SYMS, pi=sp.pi, sqrt=sp.sqrt), transformations=standard_transformations)


def ra_sides(line):
    need(line.count("=") == 1, f"not an equation: {line!r}")
    left, right = [p.strip() for p in line.split("=")]
    return left, right


def ra_solutions(line, subject):
    """The subject's solutions of an equation, a set of expressions (± gives two)."""
    left, right = ra_sides(line)
    sym = RA_SYMS[subject]
    if left == subject and "±" in right:
        e = ra_parse(right.replace("±", ""))
        return [e, -e]
    if left == subject:
        return [ra_parse(right)]
    return [sp.simplify(s_) for s_ in sp.solve(sp.Eq(ra_parse(left), ra_parse(right)), sym)]


def ra_same(a, b):
    """Two lists of expressions equal as sets, to SymPy's simplification."""
    if len(a) != len(b):
        return False
    rest = list(b)
    for x_ in a:
        hit = next((y_ for y_ in rest if sp.simplify(x_ - y_) == 0), None)
        if hit is None:
            return False
        rest.remove(hit)
    return True


def ra_original(q, u):
    """(equation text, subject letter) of the formula a question asks about."""
    L = q["lines"]
    if u == "one-step":
        eq = RA_FORMULAS[L[0]] if L[0] in RA_FORMULAS else L[0]
        m = re.fullmatch(r"Make (\w) the subject of the formula\.", q["asked"])
        need(m is not None, f"asked {q['asked']!r}")
        return eq.replace("a*t", "at").replace("s*t", "st").replace("m*a", "ma").replace("l*w", "lw").replace("pi*d", "πd"), m.group(1)
    need(q["asked"] == "Make x the subject of the formula.", f"asked {q['asked']!r}")
    line = L[0]
    m = re.fullmatch(r"x is (doubled|trebled|multiplied by (−?\d+)), and then (\d+) is (added|subtracted), to give y\.", line)
    if m:
        a = {"doubled": 2, "trebled": 3}.get(m.group(1), None) or int(m.group(2).replace("−", "-"))
        b = int(m.group(3)) * (1 if m.group(4) == "added" else -1)
        return f"y = {a}x + {b}".replace("+ -", "- "), "x"
    m = re.fullmatch(r"y is x squared (plus|minus) (\d+)\.", line)
    if m:
        return f"y = x² {'+' if m.group(1) == 'plus' else '−'} {m.group(2)}", "x"
    m = re.fullmatch(r"y is the square root of x (plus|minus) (\d+)\.", line)
    if m:
        return f"y = √(x {'+' if m.group(1) == 'plus' else '−'} {m.group(2)})", "x"
    return line, "x"


def check_rearrange(q):
    u, L, asked = q["view"]["unknown"], q["lines"], q["asked"]
    for t in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    need(q["paper"] == 1, "prior learning has no calculator")
    if u == "which-original":
        need(asked == "Which formula did this come from?", f"asked {asked!r}")
        shown = ra_solutions(L[0], "x")
        truth = {o["text"]: ra_same(ra_solutions(o["text"], "x"), shown) for o in q["choices"]}
        need(truth[q["answer_text"]] and sum(truth.values()) == 1, f"the options that give {L[0]!r}: {[t for t, v in truth.items() if v]}")
        gc_check_common(q, q["answer_text"], {})
        return None, None
    if u == "subject-twice-linear":
        need(re.fullmatch(r"kx [+−] \d+ = \dx \+ m", L[0]) is not None, f"can't read {L[0]!r}")
        eq, subject = L[0], "x"
    else:
        eq, subject = ra_original(q, u)
    orig = ra_solutions(eq, subject)
    truth = {}
    wr = {}
    for o in q["choices"]:
        need(o["text"].startswith(f"{subject} = "), f"option {o['text']!r} is not {subject} = …")
        sols = ra_solutions(o["text"], subject)
        truth[o["text"]] = ra_same(sols, orig)
        if o["ref"]:
            wr.setdefault(o["ref"], set()).add(o["text"])
    need(truth[q["answer_text"]] and sum(truth.values()) == 1, f"the options that are rearrangements: {[t for t, v in truth.items() if v]}")
    # What each misconception gives, checked as maths.
    right = ra_solutions(q["answer_text"], subject)
    y = RA_SYMS["y"]
    for ref, texts in wr.items():
        for t in texts:
            e = ra_solutions(t, subject)
            if ref == RA_T + "#0":
                co = sp.Poly(ra_parse(ra_sides(eq)[1]), RA_SYMS["x"]).all_coeffs()
                need(ra_same(e, [y / co[0] - co[1]]), f"{t!r} is not y/a − b")
            elif ref == RA_T + "#1":
                c_ = ra_parse(ra_sides(eq)[1]) - RA_SYMS["x"] ** 2
                r_ = sp.sqrt(abs(c_))
                need(ra_same(e, [sp.sqrt(y) - r_ if c_ > 0 else sp.sqrt(y) + r_]), f"{t!r} is not √y − √c")
            elif ref == RA_T + "#2":
                top = sp.numer(sp.together(ra_parse(ra_sides(eq)[1])))
                bot = sp.denom(sp.together(ra_parse(ra_sides(eq)[1])))
                b2 = -sp.Poly(bot, RA_SYMS["x"]).all_coeffs()[1]
                need(ra_same(e, [y / top + b2]), f"{t!r} is not y/a + b")
            elif ref == RA_T + "#4":
                need(len(e) == 1 and ra_same(e, [ra_solutions(q["answer_text"], subject)[0]]), f"{t!r} is not the positive root alone")
            else:
                raise Fail(f"the checker can't confirm {ref} on {u}")
    gc_check_common(q, q["answer_text"], {ref: texts for ref, texts in wr.items()})
    return None, None


def ra_spot(q, lines):
    """The first line of a student's working on subject-twice that is wrong: one that has
    x on both sides of 'x = …', or one that is not the original equation rearranged."""
    eq, subject = ra_original(q, "subject-twice")
    orig = ra_solutions(eq, subject)
    for i, line in enumerate(lines):
        line = line[3:] if line.startswith("So ") else line
        left, right = ra_sides(line)
        if left == subject and subject in right:
            return i
        if not ra_same(ra_solutions(line, subject), orig):
            return i
    return None


SPOT_CHECKS["fn-pre-rearrange"] = ra_spot


# ── regression (t4-regression-gdc, FAL-695) ──────────────────
# The `regression` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/regression.gd. The data are read back from the table shown, and
# a, b, r and every estimate are found again with exact rationals (r with a square root).

RG_SKILL = "SL4.4."
RG_EDGE = sp.Rational(29, 1000)         # the engine's is 0.03
# The stories, in the engine's order: what x is, what y is, what a row is, and the sign of r.
RG_CONTEXTS = [("hours of study per week", "test score out of 100", "students", 1),
               ("daily temperature in °C", "number of cans of lemonade sold", "days", 1),
               ("age of a car in years", "value in hundreds of dollars", "cars", -1),
               ("hours of sunshine in a day", "litres of water collected", "days", 1),
               ("height above sea level in hundreds of metres", "air temperature in °C", "weather stations", -1),
               ("minutes of exercise per day", "resting heart rate in beats per minute", "adults", -1),
               ("number of workers on a repair crew", "repairs finished in a week", "crews", 1),
               ("distance from the city in km", "house price in tens of thousands of dollars", "houses", -1)]


def rg_clear(x):
    """x is zero, or at least RG_EDGE of a unit of its 3rd figure from a rounding edge."""
    if x == 0:
        return True
    v = num(x)
    e = sp.floor(sp.log(abs(v), 10))
    scaled = abs(v) / sp.Integer(10) ** (e - 2)
    return abs(scaled - sp.floor(scaled) - sp.Rational(1, 2)) >= RG_EDGE


def rg_s(x):
    return sig3(x).replace("-", "−")


def rg_line(m, c):
    """mx + c as the game writes it to 3 s.f.: "2.31x − 0.552", "−4.70x"."""
    out = rg_s(m) + "x"
    if c != 0:
        out += (" − " if c < 0 else " + ") + sig3(abs(c))
    return out


def rg_num(x, label):
    """A number answer as the game writes it: exact where 3 s.f. changes nothing, else to 3 s.f."""
    if sp.Rational(sig3(x)) == x:
        return label + dec_text(x), None
    return label + rg_s(x), label + dec_text(sp.Rational(sig3(x, 2)))


def rg_decimal(text, places):
    v = R(text.replace("−", "-"))
    need((v * 10 ** places).q == 1, f"{text!r} has more than {places} decimal places")
    return v


def check_regression(q):
    g, u, L, rep = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"]
    asked = q["asked"]
    need(q["paper"] == 2, "regression questions are Paper 2")
    for tx in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", tx), f"a hyphen for a minus in {tx!r}")
    wrongs, want, trap = {}, None, None

    if u in ("regression-line", "correlation-coefficient", "mean-point", "predict-from-data"):
        need(rep == "table" and q["table"] is not None, "a table")
        mt = re.fullmatch(r"The table shows the (.+) \(x\) and the (.+) \(y\) for (\d+) (.+)\.", L[0])
        need(mt is not None, f"can't read {L[0]!r}")
        ctx = next((c for c in RG_CONTEXTS if c[:2] == (mt.group(1), mt.group(2)) and c[2] == mt.group(4)), None)
        need(ctx is not None, f"no story matches {L[0]!r}")
        need(RG_CONTEXTS.index(ctx) == int(g["ctx"]), "the story is not the one given")
        rows = q["table"]["rows"]
        need(rows[0][0] == "x" and rows[1][0] == "y", "table heads")
        xs, ys = [int(v) for v in rows[0][1]], [int(v) for v in rows[1][1]]
        n = len(xs)
        need(n == len(ys) == int(mt.group(3)) and 6 <= n <= 9, f"n = {n}")
        need(xs == sorted(set(xs)) and 1 <= xs[0] and xs[-1] <= 20, f"x-values {xs}")
        need(all(8 <= y <= 99 for y in ys), "a y-value is outside 8 to 99")
        sx, sy = sum(xs), sum(ys)
        mx, my = sp.Rational(sx, n), sp.Rational(sy, n)
        sxx = sp.Rational(n * sum(x * x for x in xs) - sx * sx, n)
        sxy = sp.Rational(n * sum(x * y for x, y in zip(xs, ys)) - sx * sy, n)
        syy = sp.Rational(n * sum(y * y for y in ys) - sy * sy, n)
        a = sxy / sxx
        b = my - a * mx
        r = sxy / sp.sqrt(sxx * syy)
        need(sp.Rational(8, 10) <= abs(r) <= sp.Rational(99, 100), f"|r| = {float(abs(r)):.4f} is outside 0.8 to 0.99")
        need((r > 0) == (ctx[3] > 0), "the sign of r does not match the story")
        need(R(g["a"]) == a and R(g["b"]) == b and R(g["mx"]) == mx and R(g["my"]) == my, "the givens are not the line and means of the table shown")
        ay = sxy / syy
        by = mx - ay * my
        if u == "regression-line":
            need(asked == "Find the equation of the regression line of y on x, in the form y = ax + b, with a and b to 3 s.f.", f"asked {asked!r}")
            need(rg_clear(a) and rg_clear(b) and abs(b) >= 1, "a or b is on a rounding edge, or |b| < 1")
            need(rg_clear(ay) and rg_clear(by) and sig3(a) != sig3(ay) and sig3(b) != sig3(by), "the swapped line is not clear or reads the same")
            want = "y = " + rg_line(a, b)
            wrongs[RG_SKILL + "regression-y-on-x#0"] = {"y = " + rg_line(ay, by)}
        elif u == "correlation-coefficient":
            need(asked == "Find the value of r, Pearson's product-moment correlation coefficient, to 3 s.f.", f"asked {asked!r}")
            need(rg_clear(r) and rg_clear(r * r), "r or r² is on a rounding edge")
            want, trap = rg_num(r, "r = ")
            wrongs[RG_SKILL + "pearson-r#0"] = {"r = " + rg_s(r * r)}
        elif u == "mean-point":
            need(asked == "Write down the coordinates of the mean point.", f"asked {asked!r}")
            need((mx * 100).q == 1 and (my * 100).q == 1, "a mean ends in more than two decimal places")
            want = f"({dec_text(mx)}, {dec_text(my)})"
        else:
            mt2 = re.fullmatch(r"Use the regression line of y on x to estimate y when x = (\d+)\. Give your answer to 3 s\.f\.", asked)
            need(mt2 is not None, f"asked {asked!r}")
            x0 = int(mt2.group(1))
            need(xs[0] < x0 < xs[-1] and x0 not in xs, f"x = {x0} is not strictly inside the data and off the table")
            y0 = a * x0 + b
            a3, b3 = sp.Rational(sig3(a)), sp.Rational(sig3(b))
            y3 = a3 * x0 + b3
            xr = (x0 - b) / a
            need(a3 != a and b3 != b, "a or b needs no rounding")
            need(y0 > 0 and rg_clear(y0) and rg_clear(y3) and rg_clear(xr), "an estimate is not positive, or is on a rounding edge")
            need(sp.Rational(sig3(y0)) != y0, "the estimate needs no rounding")
            need(len({sig3(y0), sig3(y3), sig3(xr)}) == 3, "the estimates read the same at 3 s.f.")
            want, trap = rg_num(y0, "y = ")
            wrongs[RG_SKILL + "regression-y-on-x#1"] = {"y = " + rg_s(y3)}
            wrongs[RG_SKILL + "predict#1"] = {"y = " + rg_s(xr)}
    elif u == "c-from-mean-point":
        need(rep == "equation" and asked == "The regression line passes through the mean point. Find c.", f"asked {asked!r}")
        mt = re.fullmatch(r"The mean point of a set of data is \((\d+(?:\.\d)?), (\d+(?:\.\d{1,2})?)\)\.", L[0])
        need(mt is not None, f"can't read {L[0]!r}")
        ml = re.fullmatch(r"The regression line of y on x is y = (−?\d+(?:\.\d)?)x \+ c\.", L[1])
        need(ml is not None, f"can't read {L[1]!r}")
        mx, my, a = R(mt.group(1)), R(mt.group(2)), rg_decimal(ml.group(1), 1)
        need(2 <= mx <= 15 and 20 <= my <= 90 and (my * 100).q == 1, "the mean point is outside the limits")
        need(sp.Rational(1, 2) <= abs(a) <= sp.Rational(49, 10) and abs(a) != 1, f"the gradient {a}")
        c = my - a * mx
        need(1 <= abs(c) <= 150 and rg_clear(c), f"c = {c} is outside 1 to 150 or on a rounding edge")
        need(R(g["c"]) == c, "the c given is not the constant")
        want, trap = rg_num(c, "c = ")
        wrongs[RG_SKILL + "mean-point#0"] = {"c = 0"}
    elif u == "predict-from-line":
        need(rep == "equation", "equation rep")
        ml = re.fullmatch(r"The regression line of y on x is y = (−?\d+\.\d\d?|−?\d+)x ([+−]) (\d+(?:\.\d)?)\.", L[0])
        need(ml is not None, f"can't read {L[0]!r}")
        a = rg_decimal(ml.group(1), 2)
        b = rg_decimal(ml.group(3), 1) * (1 if ml.group(2) == "+" else -1)
        need(sp.Rational(1, 2) <= abs(a) <= sp.Rational(999, 100) and sp.Rational(3, 2) <= abs(b) <= sp.Rational(999, 10), "the line is outside the limits")
        mt2 = re.fullmatch(r"Use the line to estimate y when x = (\d+)\. Give your answer to 3 s\.f\.", asked)
        need(mt2 is not None, f"asked {asked!r}")
        x0 = int(mt2.group(1))
        need(5 <= x0 <= 40, f"x = {x0}")
        y0 = a * x0 + b
        xr = (x0 - b) / a
        need(5 <= y0 <= 500 and sp.Rational(sig3(y0)) != y0 and rg_clear(y0) and rg_clear(xr) and sig3(xr) != sig3(y0), "the estimate is outside the limits or on a rounding edge")
        need(R(g["y0"]) == y0, "the estimate given is not the line at x")
        want, trap = rg_num(y0, "y = ")
        wrongs[RG_SKILL + "predict#1"] = {"y = " + rg_s(xr)}
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wrongs, trap)
    need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")
    for sol in q["solutions"]:
        need(want in sol["steps"][-1], f"{sol['name']}: the last step {sol['steps'][-1]!r} doesn't state {want!r}")
    return None, None


# ── compound-interest (t1-compound-interest, FAL-695) ────────
# The `compound-interest` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/compound_interest.gd. Every value is found again with exact
# rationals (Python integers do not overflow), and a rate or a time from a high-precision root
# or logarithm.

CI_SKILL = "SL1.4."
CI_WHO = ["Kira", "Tomas", "The Guild", "A trader", "Ines", "The caravan fund"]
CI_FREQ = {"annually": 1, "half-yearly": 2, "quarterly": 4, "monthly": 12}
CI_TENTHS = {sp.Rational(t, 10) for t in range(15, 81, 5)}
CI_QUARTERS = {sp.Rational(t, 100) for t in range(175, 726, 50)}
CI_CENT_EDGE = sp.Rational(149, 1000)   # the engine's is 0.15
CI_EDGE = sp.Rational(29, 1000)         # the engine's is 0.03
CI_YEAR_GAP = sp.Rational(149, 1000)    # the engine's is 0.15


def ci_value(pv, r, k, n):
    return pv * (1 + r / (100 * k)) ** (k * n)


def ci_cents(x):
    """x to the nearest cent, half up, as a Rational."""
    return sp.floor(x * 100 + sp.Rational(1, 2)) / 100


def ci_clear(x):
    """x rounds to a cent without doubt: its leftover fraction of a cent is at least CI_CENT_EDGE from 0.5."""
    if not (0 < x <= 100000):
        return False
    f = x * 100 - sp.floor(x * 100)
    return abs(f - sp.Rational(1, 2)) >= CI_CENT_EDGE


def ci_money(c):
    """A cents value as the game writes it: whole dollars bare, else two decimals."""
    c = sp.Rational(c)
    return str(int(c)) if c.q == 1 else f"{Decimal(c.p) / Decimal(c.q):.2f}"


def ci_rate_clear(x):
    v = num(x)
    e = sp.floor(sp.log(v, 10))
    scaled = v / sp.Integer(10) ** (e - 2)
    return abs(scaled - sp.floor(scaled) - sp.Rational(1, 2)) >= CI_EDGE


def check_compound_interest(q):
    g, u, L, rep = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"]
    asked = q["asked"]
    paper = q["paper"]
    need(paper in (1, 2), f"paper {paper}")
    need(paper == 2 or (u in ("future-value", "interest-earned") and q["view"]["angle"] == "compound-formula"), "only a future value or interest by formula is Paper 1")
    for tx in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", tx), f"a hyphen for a minus in {tx!r}")
    wrongs, want, trap = {}, None, None
    freqs = "|".join(CI_FREQ)

    def who_ok(w):
        need(w in CI_WHO and CI_WHO.index(w) == int(g["ctx"]), f"the story's name {w!r}")

    if u in ("future-value", "interest-earned", "time-needed"):
        m = re.fullmatch(r"(.+) invests \$(\d+) in an account that pays ([\d.]+)% per year, compounded (" + freqs + r")\.", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        who_ok(m.group(1))
        pv, r, k = sp.Integer(m.group(2)), R(m.group(3)), CI_FREQ[m.group(4)]
        if paper == 1:
            need(k == 1 and pv in (1000, 2000, 4000, 5000, 8000, 10000) and r in (5, 10, 20, 25, 50), f"Paper 1 PV {pv}, rate {r} or compounding {k} is outside the limits")
        else:
            need(pv % 500 == 0 and 1000 <= pv <= 20000 and r in CI_TENTHS, f"PV {pv} or rate {r} is outside the limits")
        need(R(g["pv"]) == pv and R(g["r"]) == r and int(g["k"]) == k, "the givens are not what is shown")
        if u in ("future-value", "interest-earned"):
            mn = re.fullmatch(r"Find the (?:value of the investment after|interest earned over the) (\d+) years, to the nearest cent\.", asked)
            need(mn is not None and asked == (f"Find the value of the investment after {mn.group(1)} years, to the nearest cent." if u == "future-value"
                                              else f"Find the interest earned over the {mn.group(1)} years, to the nearest cent."), f"asked {asked!r}")
            n = int(mn.group(1))
            need((paper == 1 and 2 <= n <= 4 or paper == 2 and 2 <= n <= 12) and int(g["n"]) == n, f"n = {n}")
            need(paper == 2 or (int(r), n) in ((10, 2), (10, 3), (10, 4), (20, 2), (20, 3), (5, 2), (50, 2), (25, 2)), f"Paper 1 rate {r} for {n} years")
            fv = ci_value(pv, r, k, n)
            annual, simple = ci_value(pv, r, 1, k * n), pv * (1 + n * r / 100)
            need(all(ci_clear(x) for x in (fv, fv - pv, annual, simple)), "a value is on the edge between two cents, or outside the limits")
            need(abs(fv - simple) >= 1 and (paper == 1 or abs(fv - annual) >= 1), "a slip reads the same as the answer")
            if u == "future-value":
                want = "value = $" + ci_money(ci_cents(fv))
                wrongs[CI_SKILL + "future-value#0"] = {"value = $" + ci_money(ci_cents(annual))}
                wrongs[CI_SKILL + "future-value#1"] = {"value = $" + ci_money(ci_cents(simple))}
                wrongs[CI_SKILL + "future-value#2"] = {"value = $" + ci_money(ci_cents(fv - pv))}
            else:
                want = "interest = $" + ci_money(ci_cents(fv - pv))
                wrongs[CI_SKILL + "future-value#2"] = {"interest = $" + ci_money(ci_cents(fv))}
        else:
            mt = re.fullmatch(r"Find the number of complete years needed for the investment to be worth more than \$(\d+)\.", asked)
            need(mt is not None, f"asked {asked!r}")
            target = sp.Integer(mt.group(1))
            need(target % 500 == 0 and target >= sp.Rational(12, 10) * pv and R(g["target"]) == target, f"target {target}")
            years = next(i for i in range(1, 400) if ci_value(pv, r, k, i) > target)
            x = sp.log(sp.Rational(target) / pv) / (k * sp.log(1 + r / (100 * k)))
            xn = num(x)
            frac = xn - sp.floor(xn)
            need(CI_YEAR_GAP <= frac <= 1 - CI_YEAR_GAP, f"the real solution {float(xn):.4f} is not clear of a whole number")
            need(years == int(g["years"]) and 3 <= years <= 40, f"the least n is {years}, not {g['years']}")
            want = f"years = {years}"
            if sp.floor(xn + sp.Rational(1, 2)) != years:
                wrongs[CI_SKILL + "find-time#0"] = {f"years = {int(sp.floor(xn + sp.Rational(1, 2)))}"}
            if k > 1:
                wrongs[CI_SKILL + "find-time#1"] = {f"years = {int(sp.ceiling(xn * k))}"}
    elif u == "present-value":
        m = re.fullmatch(r"(.+) wants an account to be worth \$(\d+) after (\d+) years\. The account pays ([\d.]+)% per year, compounded (" + freqs + r")\.", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        who_ok(m.group(1))
        fv, n, r, k = sp.Integer(m.group(2)), int(m.group(3)), R(m.group(4)), CI_FREQ[m.group(5)]
        need(fv % 500 == 0 and 2000 <= fv <= 50000 and 2 <= n <= 12 and r in CI_TENTHS, f"FV {fv}, n {n} or rate {r} is outside the limits")
        need(asked == "Find the amount to invest now, to the nearest cent.", f"asked {asked!r}")
        need(R(g["fv"]) == fv and int(g["n"]) == n and R(g["r"]) == r and int(g["k"]) == k, "the givens are not what is shown")
        pv = fv / (1 + r / (100 * k)) ** (k * n)
        need(ci_clear(pv) and pv >= 500, f"PV {float(pv):.4f} is on a cent edge or too small")
        need(ci_clear(fv * (1 + r / (100 * k)) ** (k * n)) and ci_clear(fv / (1 + r / 100) ** (k * n)) and ci_clear(fv / (1 + n * r / 100)), "a wrong option is on a cent edge")
        want = "PV = $" + ci_money(ci_cents(pv))
    elif u == "interest-rate":
        m = re.fullmatch(r"(.+) invests \$(\d+) in an account that pays interest compounded (" + freqs + r")\. After (\d+) years the account is worth \$([\d.]+)\.", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        who_ok(m.group(1))
        pv, k, n, fv = sp.Integer(m.group(2)), CI_FREQ[m.group(3)], int(m.group(4)), R(m.group(5))
        need(pv % 500 == 0 and 1000 <= pv <= 20000 and 2 <= n <= 12, f"PV {pv} or n {n} is outside the limits")
        need(asked == "Find the annual interest rate, as a percentage to 3 s.f.", f"asked {asked!r}")
        need(R(g["pv"]) == pv and R(g["fv"]) == fv and int(g["k"]) == k and int(g["n"]) == n, "the givens are not what is shown")
        ratio = fv / pv
        found = 100 * k * (ratio ** sp.Rational(1, k * n) - 1)
        fn = num(found)
        nearest = sp.Rational(sp.floor(fn * 4 + sp.Rational(1, 2)), 4)
        need(nearest in CI_QUARTERS and abs(fn - nearest) < sp.Rational(1, 100) and abs(fn - nearest) >= sp.Rational(1, 10**6), f"the rate {float(fn):.6f} is not a quarter, or is on it exactly")
        need(ci_rate_clear(found), "the rate is on a rounding edge")
        slip_root, slip_share = ratio ** sp.Rational(1, k * n), (ratio - 1) * 100 / n
        need(ci_rate_clear(slip_root) and ci_rate_clear(slip_share), "a slip is on a rounding edge")
        need(len({sig3(found), sig3(slip_root), sig3(slip_share)}) == 3, "the slips read the same as the answer")
        need(sig3(found) == sig3(nearest), "the rate does not read as its quarter at 3 s.f.")
        want = "rate = " + sig3(found).replace("-", "−") + "%"
        trap = "rate = " + dec_text(sp.Rational(sig3(found, 2))) + "%"
        wrongs[CI_SKILL + "find-rate-or-pv#0"] = {"rate = " + sig3(slip_root) + "%"}
        wrongs[CI_SKILL + "find-rate-or-pv#2"] = {"rate = " + sig3(slip_share) + "%"}
    elif u == "compare-options":
        m = re.fullmatch(r"(.+) invests \$(\d+) for (\d+) years in one of two accounts\.", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        who_ok(m.group(1))
        pv, n = sp.Integer(m.group(2)), int(m.group(3))
        need(pv % 1000 == 0 and 1000 <= pv <= 20000 and 3 <= n <= 15, f"PV {pv} or n {n} is outside the limits")
        need(asked == f"How much more is account A worth than account B at the end of the {n} years? Give your answer to the nearest cent.", f"asked {asked!r}")
        if rep == "table":
            rows = q["table"]["rows"]
            need(rows[0] == ["Account", ["A", "B"]] and rows[1][0] == "Rate (% per year)" and rows[2][0] == "Compounded", "table heads")
            ra, rb = R(rows[1][1][0]), R(rows[1][1][1])
            ka, kb = CI_FREQ[rows[2][1][0]], CI_FREQ[rows[2][1][1]]
        else:
            mm = re.fullmatch(r"Account A pays ([\d.]+)% per year, compounded (" + freqs + r"). Account B pays ([\d.]+)% per year, compounded (" + freqs + r")\.", L[1])
            need(mm is not None, f"can't read {L[1]!r}")
            ra, ka, rb, kb = R(mm.group(1)), CI_FREQ[mm.group(2)], R(mm.group(3)), CI_FREQ[mm.group(4)]
        need(ra in CI_TENTHS and rb in CI_TENTHS and not (ra == rb and ka == kb), "the accounts are outside the limits or the same")
        need(R(g["pv"]) == pv and R(g["r"]) == ra and R(g["rb"]) == rb and int(g["k"]) == ka and int(g["kb"]) == kb and int(g["n"]) == n, "the givens are not what is shown")
        a, b = ci_value(pv, ra, ka, n), ci_value(pv, rb, kb, n)
        d = a - b
        need(d >= 20 and ci_clear(a) and ci_clear(b) and ci_clear(d), "the difference is below 20 or a value is on a cent edge")
        need(ci_cents(a) - ci_cents(b) == ci_cents(d), "rounding first changes the difference")
        a1, b1 = ci_value(pv, ra, 1, n), ci_value(pv, rb, 1, n)
        need(ci_clear(a1 - b1) and a1 - b1 >= 1 and abs(a1 - b1 - d) >= 1, "the nominal-rate slip is on a cent edge or reads the same")
        want = "difference = $" + ci_money(ci_cents(d))
        wrongs[CI_SKILL + "compare-options#0"] = {"difference = $" + ci_money(ci_cents(a1 - b1))}
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wrongs, trap)
    need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")
    for sol in q["solutions"]:
        need(want in sol["steps"][-1], f"{sol['name']}: the last step {sol['steps'][-1]!r} doesn't state {want!r}")
    return None, None


# ── Rational functions (FAL-423): rational-function ───────────
# f(x) = (ax + b)/(cx + d) is read back from the question (its equation, or its graph's
# curve and asymptote lines, or the givens a, b, c, d where only a table or words show it)
# and every asymptote, intercept, set and count is worked out again with SymPy. Each pick-
# the-graph card is read back as a triple (A, B, h) of y = A + B/(x − h) from its dashed
# lines and its curve, and each wrong card is tested against the one change it names.

RF = "SL2.8."
RF_VA_SIGN, RF_HA_RATIO = RF + "asymptotes#0", RF + "asymptotes#1"
RF_NUMBER, RF_SWAP = "SL2.4.asymptotes#0", "SL2.4.asymptotes#1"
RF_ZERO_YINT, RF_ZERO_SIGN = "SL2.4.zeros-intercepts#0", "SL2.4.zeros-intercepts#1"
RF_RANGE_INCL, RF_RANGE_X = "SL2.2.range#1", "SL2.2.range#2"
RF_CORNERS, RF_ZERO_AT_H, RF_ACROSS = RF + "sketch-rational#0", RF + "sketch-rational#1", RF + "sketch-rational#2"
RF_INEQ_POINTS, RF_INEQ_BELOW, RF_INEQ_ONE = ("SL2.10.inequality-graphical#%d" % i for i in range(3))
RF_TANGENT, RF_DOMAIN, RF_ASYMPTOTE_SOLVES = ("SL2.10.number-of-solutions#%d" % i for i in range(3))
RF_SELF_PRODUCT, RF_PARENT_AXES, RF_PARENT_QUADRANTS = RF + "reciprocal#0", RF + "reciprocal#1", RF + "reciprocal#2"
RF_WIN = (-8, 8, -8, 8)
RF_PLOT = 6
RF_DEN_MAX = 3
RF_PAPER1_U = {"va-from-equation", "ha-from-equation", "x-intercept", "y-intercept"}


def rf_expr(text, letters=()):
    """The game's way of writing f as SymPy: '(3x − 2)/(x − 2)', '3 + 2/(x − 2)'."""
    t = text.split(" = ", 1)[1] if text.startswith(("f(x) = ", "y = ")) else text
    t = t.replace("−", "-").replace("kx", "k*x").replace("²", "**2")
    need(re.fullmatch(r"[0-9x+\-*/(). k]+", t) is not None, f"can't read the function {text!r}")
    loc = {"x": X, "k": LETTERS["k"]}
    return sp.nsimplify(parse_expr(t, transformations=TRANSFORMS, local_dict=loc), rational=True)


def rf_given(g):
    a, b, c, d = (int(R(g[n])) for n in "abcd")
    return (a * X + b) / (c * X + d), (a, b, c, d)


def rf_truth(f):
    """h, A, B, x-intercept and y-intercept of a linear-over-linear f, exactly."""
    f = sp.together(f)
    num, den = sp.fraction(f)
    pn, pd = sp.Poly(num, X), sp.Poly(den, X)
    need(pn.degree() == 1 and pd.degree() == 1, f"{f} is not linear over linear")
    a, b = pn.all_coeffs()
    c, d = pd.all_coeffs()
    need(a * d - b * c != 0, "ad − bc is zero: f is not a real rational function")
    h, A = -d / c, a / c
    B = sp.simplify((b * c - a * d) / c**2)
    return {"h": sp.nsimplify(h), "A": sp.nsimplify(A), "B": sp.nsimplify(B), "xi": sp.nsimplify(-b / a), "yi": sp.nsimplify(b / d), "co": (a, b, c, d)}


def rf_num(v, paper):
    return frac_text(R(v)) if paper == 1 else gc_s(R(v))


def rf_nonterminating(v):
    v = R(v)
    return v.q % 10 != 0 and gc_rounds(v) and abs(float(v)) > 0.05


def rf_clean(q, T, f):
    """The situation's clean limits for f."""
    paper = q["paper"]
    a, b, c, d = T["co"]
    need(all(sp.Integer(v).is_integer for v in (a, b, c, d)), "a, b, c, d are not whole numbers")
    need(1 <= c <= (9 if paper == 2 else 3), f"c = {c} is out of range")
    need(a != 0 and d != 0, "a or d is zero: an intercept is missing")
    if paper == 1:
        need(R(T["xi"]).q <= RF_DEN_MAX and R(T["yi"]).q <= RF_DEN_MAX, "Paper 1 intercepts are whole numbers, halves or thirds")
        need(abs(R(T["h"])) <= 7 and abs(R(T["A"])) <= 7, "an asymptote is out of range")
    elif q["view"]["unknown"] in RF_PAPER1_U:
        for k in ("h", "A", "xi", "yi"):
            need(rf_nonterminating(T[k]), f"Paper 2 {k} = {T[k]} needs no calculator")
            need(abs(float(T[k])) < 99, f"Paper 2 {k} is too big")


def rf_graph_is(gr, T, whole=True):
    """The graph's curves lie on f, its dashed lines are f's asymptotes and, in the plot, its
    asymptotes and intercepts are on grid lines."""
    a, b, c, d = (float(v) for v in T["co"])
    need(len(gr["vlines"]) == 1 and len(gr["hlines"]) >= 1, "the graph has no dashed asymptotes")
    need(abs(gr["vlines"][0]["at"] - float(T["h"])) < 1e-9 and any(abs(hl["at"] - float(T["A"])) < 1e-9 for hl in gr["hlines"]), "the dashed lines are not the asymptotes")
    for cv in gr["curves"][:2]:
        for x, y in cv:
            need(abs((a * x + b) / (c * x + d) - y) < 1e-6 * max(1, abs(y)), "a point of the curve is not on f")
    for cv, side in zip(gr["curves"][:2], (-1, 1)):
        need(len(cv) > 5, "a branch is missing")
        need(all((x - float(T["h"])) * side > 0 for x, _ in cv), "a branch crosses the vertical asymptote")


def rf_triple_of(gr):
    """(A, B, h) read from a card: its dashed lines and its curve."""
    need(len(gr["vlines"]) == 1 and len(gr["hlines"]) == 1, "a card has no dashed asymptotes")
    h, A = sp.nsimplify(gr["vlines"][0]["at"], rational=True, tolerance=1e-9), sp.nsimplify(gr["hlines"][0]["at"], rational=True, tolerance=1e-9)
    pts = [p for cv in gr["curves"] for p in cv]
    need(len(pts) > 10, "a card has too few points")
    x, y = pts[len(pts) // 3]
    B = sp.nsimplify((y - float(A)) * (x - float(h)), rational=True, tolerance=1e-6)
    for x, y in pts:
        need(abs(float(A) + float(B) / (x - float(h)) - y) < 1e-6 * max(1, abs(y)), "a card's curve is not y = A + B/(x − h)")
    return A, B, h


def rf_card_marks(gr, t):
    """The marked points are the card's own intercepts, inside the plot."""
    A, B, h = t
    marks = set()
    if A != 0:
        xi = h - B / A
        if abs(xi) <= RF_WIN[1]:
            marks.add((float(xi), 0.0))
    if h != 0:
        yi = A - B / h
        if abs(yi) <= RF_WIN[3]:
            marks.add((0.0, float(yi)))
    got = {(round(p["x"], 6), round(p["y"], 6)) for p in gr["points"]}
    need(got == {(round(a, 6), round(b, 6)) for a, b in marks}, f"a card's marked points {got} are not its intercepts {marks}")


def rf_branch_shape(gr, across, h):
    cs = gr["curves"]
    if across:
        need(len(cs) == 1, "the wrong card is not one curve")
        need(min(p[0] for p in cs[0]) < float(h) < max(p[0] for p in cs[0]), "the joined curve doesn't cross the asymptote")
        need(any(cs[0][i][0] < float(h) < cs[0][i + 1][0] for i in range(len(cs[0]) - 1)), "no line is drawn across the asymptote")
    else:
        need(len(cs) <= 2, "a card has more than two branches")
        for cv in cs:
            need(all(p[0] < float(h) for p in cv) or all(p[0] > float(h) for p in cv), "a branch crosses the vertical asymptote")


def rf_cards(q, t_right, expected, refs):
    """Four lettered cards: the right one is t_right; each wrong card is the triple that its
    named mistake makes (expected: mistake -> triple, or None for a card of another shape),
    with the ref the misconception gives. Returns {ref: texts} for gc_check_common."""
    gs, ch = q["graphs"], q["choices"]
    need(len(gs) == 4 and len(ch) == 4, "pick the graph needs four graphs")
    need([o["text"] for o in ch] == ["Graph A", "Graph B", "Graph C", "Graph D"], "the graphs are not lettered A to D")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right graph")
    need(all(g.get("card") for g in gs), "a graph is not drawn as a card")
    need(len({json.dumps(g["curves"]) for g in gs}) == 4, "two graphs are the same")
    need(len({(g["x0"], g["x1"], g["y0"], g["y1"]) for g in gs}) == 1 and (gs[0]["x0"], gs[0]["x1"], gs[0]["y0"], gs[0]["y1"]) == RF_WIN, "the cards don't share one window")
    wr = {}
    for o, g in zip(ch, gs):
        mk = o.get("mistake", "")
        if mk == "touching":
            gcv = g["curves"][0]
            k = expected["touching"]
            need(len(gcv) > 10 and all(abs(k / (x * x + 1) - y) < 1e-6 for x, y in gcv[::5]), "the touching card is not k/(x² + 1)")
            need(o["ref"] == refs["touching"], "the touching card is mistagged")
            wr.setdefault(o["ref"], set()).add(o["text"])
            continue
        t = rf_triple_of(g)
        rf_card_marks(g, t)
        if o["correct"]:
            need(t == t_right, f"the right card is y = {t[0]} + {t[1]}/(x − {t[2]}), not {t_right}")
            rf_branch_shape(g, False, t[2])
            continue
        need(mk in expected, f"unknown mistake {mk!r}")
        across = mk == "through"
        rf_branch_shape(g, across, t[2])
        need(t == expected[mk], f"the {mk} card is {t}, not {expected[mk]}")
        need(o["ref"] == refs[mk], f"the {mk} card is tagged {o['ref']!r}, not {refs[mk]!r}")
        need(o.get("why", "") != "", f"the {mk} card doesn't say what is wrong")
        if o["ref"]:
            wr.setdefault(o["ref"], set()).add(o["text"])
    return wr


def rf_expected(t):
    A, B, h = t
    xi = h - B / A
    return {"flipped": (A, -B, h), "zero-at-h": (A, -B, xi), "mirrored": (A, B, -h), "swapped": (h, B, A), "same": t, "through": t, "negated": (-A, -B, h)}


def rf_no_hyphens(q):
    for t in [q["asked"]] + q["lines"] + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")


def rf_read_f(q):
    """f from the question's equation line, or from the givens where only a graph, a table or
    words show it; the two must agree when both are there."""
    f_given, co = rf_given(q["given"]) if "a" in q["given"] else (None, None)
    for t in q["lines"] + [q["asked"]]:
        if t.startswith("f(x) = "):
            f = rf_expr(t)
            if f_given is not None:
                need(sp.simplify(f - f_given) == 0, f"the equation shown {t!r} is not the givens")
            return f
    need(f_given is not None, "can't find f")
    return f_given


def check_rational(q):
    u, rep, asked, L = q["view"]["unknown"], q["view"]["rep"], q["asked"], q["lines"]
    paper = q["paper"]
    rf_no_hyphens(q)
    if u == "asymptotes-with-letters":
        return rf_letters(q)
    if u in ("constants-from-asymptotes", "constant-from-intercept"):
        return rf_unknown_constant(q)
    if u in ("parent-reciprocal", "reciprocal-self-inverse"):
        return rf_parent(q)
    if u in RF_EXT_U:
        return rf_ext(q)
    f = rf_read_f(q)
    T = rf_truth(f)
    if "a" in q["given"]:
        need(sp.simplify(f - rf_given(q["given"])[0]) == 0, "the givens describe another function")
    rf_clean(q, T, f)
    h, A, xi, yi, B = T["h"], T["A"], T["xi"], T["yi"], T["B"]
    a, b, c, d = T["co"]
    n = lambda v: rf_num(v, paper)
    gr = q.get("graph")
    if rep == "graph" and gr is not None and u != "count-with-horizontal":
        rf_graph_is(gr, T)
    if u in RF_PAPER1_U:
        need(q["view"]["rep"] == "equation", "an equation question")
        trap = None
        if u == "va-from-equation":
            want, wr = f"x = {n(h)}", {RF_VA_SIGN: {f"x = {n(-h)}"}, RF_SWAP: {f"y = {n(h)}"}, RF_NUMBER: {n(h)}}
            trap = f"x = {gc_s2(h)}" if paper == 2 and gc_rounds(h) else None
        elif u == "ha-from-equation":
            want, wr = f"y = {n(A)}", {RF_HA_RATIO: {f"y = {n(sp.Rational(b, d))}"}, RF_SWAP: {f"x = {n(A)}"}, RF_NUMBER: {n(A)}}
            trap = f"y = {gc_s2(A)}" if paper == 2 and gc_rounds(A) else None
        elif u == "x-intercept":
            want, wr = f"({n(xi)}, 0)", {RF_ZERO_YINT: {f"({n(yi)}, 0)"}, RF_ZERO_SIGN: {f"({n(sp.Rational(b, a))}, 0)"}}
            trap = f"({gc_s2(xi)}, 0)" if paper == 2 and gc_rounds(xi) else None
        else:
            want, wr = f"(0, {n(yi)})", {RF_ZERO_YINT: {f"(0, {n(xi)})"}}
            trap = f"(0, {gc_s2(yi)})" if paper == 2 and gc_rounds(yi) else None
        need(paper == 2 or all(not o.get("trap") for o in q["choices"]), "a Paper 1 answer has no rounding trap")
        if paper == 2:
            need(any(o.get("trap") for o in q["choices"]) == (trap is not None), "the rounding trap is missing or unneeded")
        gc_check_common(q, want, wr, trap)
        return None, None
    need(paper == 1 or u == "reciprocal-of-f", f"{u} is Paper 1")
    if u == "features-from-graph":
        ft = lambda h_, A_, x_, y_: f"asymptotes x = {frac_text(h_)} and y = {frac_text(A_)}; x-intercept ({frac_text(x_)}, 0), y-intercept (0, {frac_text(y_)})"
        want = ft(h, A, xi, yi)
        need({(round(p["x"], 6), round(p["y"], 6)) for p in gr["points"]} == {(float(xi), 0.0), (0.0, float(yi))}, "the marked points are not the intercepts")
        gc_check_common(q, want, {RF_SWAP: {ft(A, h, xi, yi)}, RF_ZERO_YINT: {ft(h, A, yi, xi)}, RF_VA_SIGN: {ft(-h, A, xi, yi)}})
    elif u == "asymptotes-from-table":
        t = q["table"]["rows"]
        need(t[0][0] == "x" and t[1][0] == "f(x)", "the table's heads")
        for xs, ys in zip(t[0][1], t[1][1]):
            xv = R(xs.replace("−", "-"))
            exp = f.subs(X, xv)
            need(abs(float(exp) - float(R(ys.replace("−", "-")))) < 0.00006, f"the table's f({xs}) is {ys}, not {float(exp):.4f}")
        want = f"x = {frac_text(h)} and y = {frac_text(A)}"
        gc_check_common(q, want, {RF_SWAP: {f"x = {frac_text(A)} and y = {frac_text(h)}"}, RF_VA_SIGN: {f"x = {frac_text(-h)} and y = {frac_text(A)}"}})
    elif u == "equation-from-features":
        eqs = [(o, rf_expr(o["text"])) for o in q["choices"]]
        right = [o for o, g in eqs if sp.simplify(g - f) == 0]
        need(len(right) == 1 and right[0]["correct"], f"{len(right)} options are the function")
        by = q["given"]["by"]
        need(sp.simplify(f.subs(X, 0) - yi) == 0, "f(0) is not the y-intercept")
        flip_d = (a * X + b) / (X - d)
        wr = {RF_VA_SIGN: {o["text"] for o, g in eqs if sp.simplify(g - flip_d) == 0 and o["ref"]}}
        for o, g in eqs:
            if not o["correct"]:
                need(not (rf_truth(g)["h"] == h and rf_truth(g)["A"] == A and sp.simplify(g.subs(X, 0) - yi) == 0), f"a wrong option {o['text']!r} has all the features")
        if rep == "words":
            j = " ".join(L)
            need(f"vertical asymptote x = {frac_text(h)}" in j and f"horizontal asymptote y = {frac_text(A)}" in j, "the words don't give the asymptotes")
            pt = f"(0, {frac_text(yi)})" if by == "y" else f"({frac_text(xi)}, 0)"
            need(pt in j, "the words don't give the intercept")
        else:
            rf_graph_is(gr, T)
        gc_check_common(q, right[0]["text"], wr)
    elif u == "range-from-asymptote":
        want = f"domain x ≠ {frac_text(h)}, range y ≠ {frac_text(A)}"
        gc_check_common(q, want, {RF_RANGE_X: {f"domain x ≠ {frac_text(h)}, range x ≠ {frac_text(A)}"}, RF_RANGE_INCL: {f"domain x ≠ {frac_text(h)}, range all real y"}})
    else:
        rf_sketch(q, f, T)
    return None, None


def rf_unknown_constant(q):
    u, rep, asked, L = q["view"]["unknown"], q["view"]["rep"], q["asked"], q["lines"]
    need(q["paper"] == 1, f"{u} is Paper 1")
    if u == "constants-from-asymptotes":
        m = re.fullmatch(r"f\(x\) = (?:\((a)x ([+−]) (\d+)\)|(a)x)/\(x \+ d\)", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        b = 0 if m.group(4) else (int(m.group(3)) if m.group(2) == "+" else -int(m.group(3)))
        gv = q["given"]
        if rep == "graph":
            gr = q["graph"]
            h, A = sp.nsimplify(gr["vlines"][0]["at"], rational=True), sp.nsimplify(gr["hlines"][0]["at"], rational=True)
            f = (int(R(gv["a"])) * X + b) / (X + int(R(gv["d"])))
            rf_graph_is(gr, rf_truth(f))
        else:
            j = " ".join(L[1:])
            mh, ma = re.search(r"x = (−?\d+)", j), re.search(r"y = (−?\d+)", j)
            need(mh is not None and ma is not None, "the asymptotes are not stated")
            h, A = R(mh.group(1).replace("−", "-")), R(ma.group(1).replace("−", "-"))
        need(int(R(gv["b"])) == b and R(gv["c"]) == 1, "the givens' b or c are not the question's")
        a_, d_ = A, -h
        T = rf_truth((a_ * X + b) / (X + d_))
        need(T["h"] == h and T["A"] == A, "the constants don't give the asymptotes")
        rf_clean(q, T, None)
        want = f"a = {frac_text(a_)}, d = {frac_text(d_)}"
        gc_check_common(q, want, {RF_VA_SIGN: {f"a = {frac_text(A)}, d = {frac_text(h)}"}, RF_SWAP: {f"a = {frac_text(h)}, d = {frac_text(-A)}"}})
        return None, None
    m = re.search(r"f\(x\) = \((−?)(?:(\d+))?x \+ k\)/\((.+?)\)", L[0])
    need(m is not None, f"can't read {L[0]!r}")
    a = (-1 if m.group(1) else 1) * (int(m.group(2)) if m.group(2) else 1)
    den = rf_expr(m.group(3))
    j = " ".join(L)
    my = re.search(r"crosses the y-axis at \(0, (−?[\d/]+)\)", j)
    mx = re.search(r"crosses the x-axis at \((−?[\d/]+), 0\)", j)
    need((my is None) != (mx is None), "one intercept is given")
    K = sp.Symbol("K")
    f = (a * X + K) / den
    if my:
        y0 = R(my.group(1).replace("−", "-"))
        k = sp.solve(f.subs(X, 0) - y0, K)[0]
        wrong_k = -a * y0
    else:
        x0 = R(mx.group(1).replace("−", "-"))
        k = sp.solve(f.subs(X, x0), K)[0]
        wrong_k = x0 * den.subs(X, 0)
    T = rf_truth((a * X + k) / den)
    rf_clean(q, T, None)
    need(k != 0, "k is zero")
    gc_check_common(q, f"k = {frac_text(k)}", {RF_ZERO_YINT: {f"k = {frac_text(wrong_k)}"}})
    return None, None


def rf_letters(q):
    L, asked = q["lines"], q["asked"]
    need(q["paper"] == 1, "Paper 1")
    K = LETTERS["k"]
    f = rf_expr(L[0], ("k",))
    num, den = sp.fraction(sp.together(f))
    pn, pd = sp.Poly(num, X), sp.Poly(den, X)
    need(pn.degree() == 1 and pd.degree() == 1, "not linear over linear")
    a, b = pn.all_coeffs()
    c, d = pd.all_coeffs()
    need(sp.simplify(a * d - b * c) != 0, "ad − bc is zero")
    va, ha = sp.simplify(-d / c), sp.simplify(a / c)
    wrong_ha = sp.nsimplify(b / d)

    def txt(e):
        e = sp.simplify(e)
        s = str(e).replace("-", "−").replace("*", "")
        return s
    right = f"x = {txt(va)} and y = {txt(ha)}"
    wr = {RF_VA_SIGN: {f"x = {txt(-va)} and y = {txt(ha)}"}, RF_HA_RATIO: {f"x = {txt(va)} and y = {txt(wrong_ha)}"},
          RF_SWAP: {f"x = {txt(ha)} and y = {txt(va)}"}}
    wr = {k: {t.replace("−1/k", "−1/k") for t in v} for k, v in wr.items()}
    gc_check_common(q, right, wr)
    return None, None


# Sketches ---------------------------------------------------

RF_REFS = {"flipped": RF_CORNERS, "zero-at-h": RF_ZERO_AT_H, "through": RF_ACROSS, "mirrored": "", "swapped": "", "same": "", "negated": ""}


def rf_set(f, rel, k):
    """The solution set of f(x) rel k as intervals [(lo, hi, lo_in, hi_in)], from f − k's
    roots and poles and a test point in each part."""
    g = sp.together(f - k)
    num, den = sp.fraction(g)
    pts = sorted(set(sp.real_roots(sp.Poly(num, X))) | set(sp.real_roots(sp.Poly(den, X))))
    roots = set(sp.real_roots(sp.Poly(num, X)))
    strict = {">": lambda v: v > 0, "<": lambda v: v < 0, "≥": lambda v: v > 0, "≤": lambda v: v < 0}[rel]
    inc = rel in ("≥", "≤")
    edges = [-sp.oo] + pts + [sp.oo]
    out = []
    for lo, hi in zip(edges, edges[1:]):
        t = (lo + hi) / 2 if lo != -sp.oo and hi != sp.oo else (hi - 1 if lo == -sp.oo else lo + 1)
        if strict(g.subs(X, t)):
            out.append((lo, hi, inc and lo in roots, inc and hi in roots))
    return out


def rf_set_text(iv):
    parts = []
    for lo, hi, li, hi_in in iv:
        if lo == -sp.oo:
            parts.append(f"x {'≤' if hi_in else '<'} {frac_text(hi)}")
        elif hi == sp.oo:
            parts.append(f"x {'≥' if li else '>'} {frac_text(lo)}")
        else:
            parts.append(f"{frac_text(lo)} {'≤' if li else '<'} x {'≤' if hi_in else '<'} {frac_text(hi)}")
    return " or ".join(parts), parts


def rf_sketch(q, f, T):
    u, rep, asked, L = q["view"]["unknown"], q["view"]["rep"], q["asked"], q["lines"]
    h, A, B, xi, yi = T["h"], T["A"], T["B"], T["xi"], T["yi"]
    a, b, c, d = T["co"]
    n = frac_text
    if q["format"] == "pick-the-graph":
        t = (A, B, h)
        if u in ("sketch-from-equation", "sketch-from-transformed"):
            m = re.fullmatch(r"Which graph is y = (.+)\?", asked)
            need(m is not None and sp.simplify(rf_expr(m.group(1)) - f) == 0, "the equation asked is not f")
            need(rep == "equation", "equation rep")
            exp = rf_expected(t)
            if u == "sketch-from-transformed":
                need(m.group(1) == RF_split_text(A, B, h), "the form is not A + B/(x − h)")
            wr = rf_cards(q, t, {k: exp[k] for k in ("flipped", "zero-at-h", "through", "mirrored", "swapped")}, RF_REFS)
        elif u == "sketch-from-description":
            need(sp.nsimplify(q["given"]["A"]) == A and sp.nsimplify(q["given"]["h"]) == h, "givens")
            if rep == "table":
                for xs, ys in zip(q["table"]["rows"][0][1], q["table"]["rows"][1][1]):
                    need(R(ys.replace("−", "-")) == f.subs(X, R(xs.replace("−", "-"))), "the table's values are not f's")
            else:
                j = " ".join(L)
                need(f"x = {n(h)}" in j and f"y = {n(A)}" in j and f"({n(xi)}, 0)" in j and f"(0, {n(yi)})" in j, "the words don't give the features")
            wr = rf_cards(q, t, {k: rf_expected(t)[k] for k in ("flipped", "zero-at-h", "through", "mirrored", "swapped")}, RF_REFS)
        elif u == "equation-from-sketch":
            raise Fail("equation-from-sketch is not a pick-the-graph")
        elif u == "reciprocal-of-f":
            g = sp.nsimplify(1 / f)
            Tg = rf_truth(g)
            tg = (Tg["A"], Tg["B"], Tg["h"])
            neg = (-tg[0], -tg[1], tg[2])
            need(asked == "Which graph is y = 1/f(x)?", "asked")
            if rep == "graph":
                rf_graph_is(q["graph"], T)
            wr = rf_cards(q, tg, {"same": t, "negated": neg, "through": tg}, {**RF_REFS, "same": "", "negated": ""})
        else:
            raise Fail(f"no check for {u} as a graph pick")
        gc_check_common(q, next(o["text"] for o in q["choices"] if o["correct"]), wr)
        return
    if u == "branch-corners":
        if rep == "equation":
            px, py = sp.Integer(0), yi
        else:
            px, py = R(q["given"]["px"]), R(q["given"]["py"])
            need(sp.simplify(f.subs(X, px) - py) == 0, "the point is not on f")
            if rep == "words":
                need(f"({n(px)}, {n(py)})" in " ".join(L), "the point is not in the words")
            else:
                for xs, ys in zip(q["table"]["rows"][0][1], q["table"]["rows"][1][1]):
                    need(R(ys.replace("−", "-")) == f.subs(X, R(xs.replace("−", "-"))), "the table's values are not f's")
        right = "top right and bottom left" if B > 0 else "top left and bottom right"
        other = "top left and bottom right" if B > 0 else "top right and bottom left"
        right_pt = ("right" if px > h else "left", "top" if py > A else "bottom")
        need((right_pt in (("right", "top"), ("left", "bottom"))) == (B > 0), "the point's corner doesn't agree with B")
        gc_check_common(q, right, {RF_CORNERS: {other}})
    elif u == "equation-from-sketch":
        need(rep == "graph", "graph rep")
        rf_graph_is(q["graph"], T)
        by = q["given"]["by"]
        pt = q["graph"]["points"]
        need(len(pt) == 1, "one intercept is marked")
        need((abs(pt[0]["x"]) < 1e-9 and abs(pt[0]["y"] - float(yi)) < 1e-9) if by == "y" else (abs(pt[0]["y"]) < 1e-9 and abs(pt[0]["x"] - float(xi)) < 1e-9), "the marked point is not the intercept")
        eqs = [(o, rf_expr(o["text"])) for o in q["choices"]]
        right = [o for o, g in eqs if sp.simplify(g - f) == 0]
        need(len(right) == 1 and right[0]["correct"], f"{len(right)} options fit the graph")
        exp = rf_expected((A, B, h))
        wr = {}
        for o, g in eqs:
            if o["correct"]:
                continue
            Tg = rf_truth(g)
            tg = (Tg["A"], Tg["B"], Tg["h"])
            hit = [mk for mk in ("flipped", "zero-at-h", "mirrored") if tg == exp[mk]]
            if o["ref"]:
                need(hit and o["ref"] == RF_REFS[hit[0]], f"option {o['text']!r} is tagged {o['ref']!r} but is {hit}")
                wr.setdefault(o["ref"], set()).add(o["text"])
            need(tg != (A, B, h), "a wrong option is f")
        gc_check_common(q, right[0]["text"], wr)
    elif u == "inequality-from-sketch":
        m = re.fullmatch(r"Solve the inequality f\(x\) ([<>≤≥]) (−?\d+)\.", asked)
        need(m is not None, f"can't read {asked!r}")
        rel, k = m.group(1), R(m.group(2).replace("−", "-"))
        need(k == 0 or (rep == "equation" and R(B).q == 1 and c == 1), "k is not 0 on a graph")
        iv = rf_set(f, rel, k)
        right, pieces = rf_set_text(iv)
        flip = {">": "<", "<": ">", "≥": "≤", "≤": "≥"}[rel]
        below, _ = rf_set_text(rf_set(f, flip, k))
        bnd = sorted(set(sp.real_roots(sp.Poly(sp.fraction(sp.together(f - k))[0], X))) | {h})
        wr = {RF_INEQ_POINTS: {" or ".join(f"x = {n(v)}" for v in bnd)}, RF_INEQ_BELOW: {below}}
        if len(pieces) == 2:
            wr[RF_INEQ_ONE] = {pieces[1]}
        xk = h + B / (k - A)
        need(k == 0 or xk.q == 1, "the boundary of f(x) = k is not a whole number")
        if rep == "graph":
            rf_graph_is(q["graph"], T)
        gc_check_common(q, right, wr)
    elif u == "count-with-horizontal":
        m = re.fullmatch(r"The graph of y = f\(x\) is shown with the line y = (−?\d+)\. How many solutions does f\(x\) = (−?\d+) have\?", asked)
        need(m is not None and m.group(1) == m.group(2), f"can't read {asked!r}")
        k = R(m.group(1).replace("−", "-"))
        sols = [s for s in sp.solve(f - k, X) if s != h]
        want = f"number of solutions = {len(sols)}"
        gr = q["graph"]
        need(any(R(hl["at"]) == k for hl in gr["hlines"]), "the line y = k is not drawn")
        wr = {RF_ASYMPTOTE_SOLVES: {"number of solutions = 1"}} if k == A else {}
        gc_check_common(q, want, wr)
    elif u == "k-for-no-solution":
        K = sp.Symbol("K")
        need(sp.solve(sp.Eq(f, A), X) == [], "f(x) = A has a solution")
        # no other k fails: f = k has the solution x = (kd − b)/(a − kc), unless a = kc
        sol_exists = lambda kv: sp.solve(sp.Eq(f, kv), X) != []
        need(not sol_exists(A) and all(sol_exists(v) for v in (A + 1, A - 1, A + 2)), "A is not the only k with no solution")
        if rep == "graph":
            rf_graph_is(q["graph"], T)
        gc_check_common(q, f"k = {n(A)}", {RF_ASYMPTOTE_SOLVES: {f"no value of k: every horizontal line meets the graph, even y = {n(A)}"}})
    elif u == "count-with-line":
        m = re.fullmatch(r"How many times does the line (y = .+?) meet the graph of y = f\(x\)\?", asked)
        need(m is not None, f"can't read {asked!r}")
        ln = rf_expr(m.group(1))
        sols = {s for s in sp.solve(sp.together(f - ln), X) if s.is_real and s != h}
        want = f"number of solutions = {len(sols)}"
        if rep == "graph":
            gr = q["graph"]
            rf_graph_is({**gr, "curves": gr["curves"][:-1]}, T)
            lnf = sp.lambdify(X, ln, "math")
            need(all(abs(lnf(x) - y) < 1e-6 for x, y in gr["curves"][-1]), "the line drawn is not the line asked")
            need(gr.get("sand_from") == len(gr["curves"]) - 1, "the line is not in the second colour")
        gc_check_common(q, want, {RF_TANGENT: {"number of solutions = 2"}} if len(sols) == 1 else {})
    elif u == "count-with-curve":
        m = re.fullmatch(r"How many times does the parabola (y = .+?) meet the graph of y = f\(x\)( for x [<>] 0)?\?", asked)
        need(m is not None, f"can't read {asked!r}")
        pb = rf_expr(m.group(1))
        cub = sp.Poly(sp.fraction(sp.together(f - pb))[0], X)
        roots = [r for r in sp.real_roots(cub) if r != h]
        need(len(roots) == len(set(roots)), "a repeated meeting point")
        dom = m.group(2)
        kept = [r for r in roots if (r > 0 if "x > 0" in (dom or "") else r < 0)] if dom else roots
        need(all(abs(float(r)) > 0.2 for r in roots), "a meeting point is next to x = 0")
        if rep == "graph":
            gr = q["graph"]
            rf_graph_is({**gr, "curves": gr["curves"][:-1]}, T)
            pbf = sp.lambdify(X, pb, "math")
            need(all(abs(pbf(x) - y) < 1e-6 for x, y in gr["curves"][-1]), "the curve drawn is not the parabola asked")
        wr = {RF_DOMAIN: {f"number of solutions = {len(roots)}"}} if dom and len(kept) != len(roots) else {}
        gc_check_common(q, f"number of solutions = {len(kept)}", wr)
    else:
        raise Fail(f"no check for {u}")


def RF_split_text(A, B, h):
    base = "" if A == 0 else frac_text(A)
    den = "x" if h == 0 else f"x {'+' if h < 0 else '−'} {frac_text(abs(h))}"
    head = ("−" if B < 0 else "") if base == "" else base + (" − " if B < 0 else " + ")
    return f"{head}{frac_text(abs(B))}/({den})"


def rf_parent(q):
    u, rep, asked, L = q["view"]["unknown"], q["view"]["rep"], q["asked"], q["lines"]
    need(q["paper"] == 1, "Paper 1")
    k = sp.Integer(int(R(q["given"]["k"]))) if "k" in q["given"] else None
    if u == "parent-reciprocal":
        k = R(q["given"]["k"])
        if rep == "equation":
            need(asked == f"Which graph is y = {frac_text(k)}/x?" and L == [f"y = {frac_text(k)}/x"], "the equation asked is not y = k/x")
        else:
            rows = q["table"]["rows"]
            for xs, ys in zip(rows[0][1], rows[1][1]):
                xv, yv = R(xs.replace("−", "-")), R(ys.replace("−", "-"))
                need(xv * yv == k, f"the table's ({xs}, {ys}) is not on y = k/x")
        need(k in (1, 2, 3), "k is a small positive whole number")
        t = (sp.Integer(0), k, sp.Integer(0))
        exp = {"negated": (0, -k, 0), "through": t, "other-k": (0, 5 - k, 0), "touching": float(k)}
        wr = rf_cards(q, t, exp, {"negated": RF_PARENT_QUADRANTS, "through": RF_PARENT_AXES, "touching": RF_PARENT_AXES, "other-k": ""})
        wr = {r: v for r, v in wr.items()}
        gc_check_common(q, next(o["text"] for o in q["choices"] if o["correct"]), wr)
        return None, None
    need(rep in ("equation", "graph"), "rep")
    kx = f"{frac_text(k)}/x" if k != 1 else "1/x"
    need(L[0] in (f"f(x) = {kx}", f"The graph of f(x) = {kx} is shown."), "the function shown is not k/x")
    y = sp.Symbol("y")
    inv = sp.solve(sp.Eq(X, k / y), y)
    need(len(inv) == 1 and sp.simplify(inv[0] - k / X) == 0, "k/x is not its own inverse")
    right = f"f⁻¹(x) = {kx}, because swapping x and y gives the same equation"
    wr = {RF_SELF_PRODUCT: {f"f⁻¹(x) = {kx}, because ({kx}) × x = {frac_text(k)}"}}
    if rep == "graph":
        gr = q["graph"]
        for cv in gr["curves"]:
            need(all(abs(float(k) / x - yy) < 1e-6 for x, yy in cv), "the graph is not y = k/x")
    gc_check_common(q, right, wr)
    return None, None



# fn-ext-transformed-reciprocal ---------------------------------

RF_EXT_U = {"split-to-form", "split-scaled", "translation-vector", "transformation-sequence", "combine-to-single", "form-from-graph", "form-from-words"}
RF_T = "SL2.8.transformed-reciprocal#"


def rf_vec(h, A):
    return f"{frac_text(abs(h))} {'right' if h > 0 else 'left'} and {frac_text(abs(A))} {'up' if A > 0 else 'down'}"


def rf_split_text(A, B, h):
    return RF_split_text(A, B, h)


def rf_single(a, b, d):
    num = ("(%s)" if " " in rf_poly(a, b) else "%s") % rf_poly(a, b)
    den = ("(%s)" if " " in rf_poly(1, d) else "%s") % rf_poly(1, d)
    return f"{num}/{den}"


def rf_poly(m, n):
    """mx + n as the game writes it."""
    m, n = R(m), R(n)
    out = ""
    if m != 0:
        out = ("−" if m < 0 else "") + ("" if abs(m) == 1 else frac_text(abs(m))) + "x"
    if n != 0:
        out += (" − " if n < 0 else " + ") + frac_text(abs(n)) if out else ("−" if n < 0 else "") + frac_text(abs(n))
    return out or "0"


def rf_ext(q):
    u, rep, asked, L = q["view"]["unknown"], q["view"]["rep"], q["asked"], q["lines"]
    need(q["paper"] == 1, f"{u} is Paper 1")
    f, co = rf_given(q["given"])
    for t in L:
        if t.startswith("f(x) = "):
            need(sp.simplify(rf_expr(t) - f) == 0, f"the equation shown {t!r} is not the givens")
    T = rf_truth(f)
    h, A, B = T["h"], T["A"], T["B"]
    a, b, c, d = T["co"]
    need(sp.Integer(c) == c and 1 <= c <= 3, "c is 1, 2 or 3")
    if u != "split-scaled":
        need(c == 1 and B.q == 1 and A.q == 1 and h.q == 1, "A, B and h are whole numbers")
    if u == "split-to-form":
        want = f"A = {frac_text(A)}, B = {frac_text(B)}"
        need(sp.simplify(A + B / (X - h) - f) == 0, "A + B/(x − h) is not f")
        gc_check_common(q, want, {RF_T + "2": {f"A = {frac_text(A)}, B = {frac_text(b)}"}})
    elif u == "split-scaled":
        k = sp.nsimplify(b - A * d)
        need(sp.simplify(A + k / (c * X + d) - f) == 0, "A + k/(cx + d) is not f")
        need(A.q == 1 and k.q == 1 and k != 0, "A and k are whole")
        m = re.fullmatch(r"Write f\(x\) in the form A \+ k/\((.+)\): find A and k\.", asked)
        need(m is not None and sp.simplify(rf_expr(m.group(1)) - (c * X + d)) == 0, "the denominator asked is not cx + d")
        gc_check_common(q, f"A = {frac_text(A)}, k = {frac_text(k)}", {RF_T + "2": {f"A = {frac_text(A)}, k = {frac_text(b)}"}})
    elif u == "translation-vector":
        if rep == "words":
            j = " ".join(L)
            need(f"asymptotes are x = {frac_text(h)} and y = {frac_text(A)}" in j and f"y = {frac_text(B)}/x" in j, "the words don't give the asymptotes and the stretch")
        else:
            need(L[0] == "f(x) = " + rf_split_text(A, B, h), "the form shown is not f")
        need(asked == f"Describe the translation that maps y = {frac_text(B)}/x onto the graph of f.", "the question asks about another stretch")
        gc_check_common(q, rf_vec(h, A), {RF_T + "0": {rf_vec(-h, A)}})
    elif u == "transformation-sequence":
        want = f"stretch by factor {frac_text(B)} in the y-direction, then translate {rf_vec(h, A)}"
        if rep == "words":
            need(f"vertical asymptote x = {frac_text(h)} and the horizontal asymptote y = {frac_text(A)}" in L[0] and f"passes through (0, {frac_text(T['yi'])})" in L[0], "the words don't give the features")
        gc_check_common(q, want, {RF_T + "1": {f"translate {rf_vec(h, A)} only, with no stretch"}, RF_T + "0": {f"stretch by factor {frac_text(B)} in the y-direction, then translate {rf_vec(-h, A)}"}})
    elif u == "combine-to-single":
        m = re.fullmatch(r"Write f\(x\) = (.+) as a single fraction \(ax \+ b\)/\(x − h\)\.", asked)
        need(m is not None and sp.simplify(rf_expr(m.group(1)) - f) == 0, "the form asked is not f")
        right = rf_single(a, b, d)
        need(sp.simplify(rf_expr(right) - f) == 0, "the right option is not f")
        wr = {}
        for o in q["choices"]:
            if not o["correct"]:
                need(sp.simplify(rf_expr(o["text"]) - f) != 0, f"the wrong option {o['text']!r} is f")
        gc_check_common(q, right, wr)
    elif u == "form-from-graph":
        gr = q["graph"]
        rf_graph_is(gr, T)
        pt = gr["points"]
        need(len(pt) == 1 and abs(float(f.subs(X, sp.nsimplify(pt[0]["x"]))) - pt[0]["y"]) < 1e-9, "the marked point is not on f")
        need(pt[0]["label"] == f"({frac_text(sp.nsimplify(pt[0]['x']))}, {frac_text(sp.nsimplify(pt[0]['y']))})", "the marked point's label")
        want = f"A = {frac_text(A)}, B = {frac_text(B)}, h = {frac_text(h)}"
        gc_check_common(q, want, {RF_T + "1": {f"A = {frac_text(A)}, B = 1, h = {frac_text(h)}"}, RF_T + "0": {f"A = {frac_text(A)}, B = {frac_text(B)}, h = {frac_text(-h)}"}})
    elif u == "form-from-words":
        need(f"stretched by factor {frac_text(B)} in the y-direction, then translated {rf_vec(h, A)}" in L[0], "the words don't give the stretch and the translation")
        right = rf_single(a, b, d)
        need(sp.simplify(rf_expr(right) - f) == 0, "the right option is not f")
        gc_check_common(q, right, {RF_T + "1": {rf_single(a, 1 - A * h, d)}, RF_T + "0": {rf_single(a, B + A * h, d)}})
    return None, None


def rf_spot(q, lines):
    """The first false line of a student's split of (ax + b)/(x − h): lines that are
    equations are tested; the closing 'so …' line is not."""
    for i, line in enumerate(lines):
        if line.startswith("so "):
            continue
        l, r = line.split(" = ", 1)
        if sp.simplify(rf_expr(l) - rf_expr(r)) != 0:
            return i
    return None


SPOT_CHECKS["rational-function"] = rf_spot

# ── Algebraic fractions (FAL-423): fn-pre-algebraic-fractions ─
# Each fraction or equation is read back from the question and worked out again with
# SymPy: the excluded value is where the bottom is zero, a simplified form is the same
# function (with the same excluded value), a sum is the same function, an equation's
# solution is solved for and substituted back, and each wrong option is shown to be a
# different function.

AF = "fn-pre-algebraic-fractions#"
AF_ZERO_WORDS = "no value: dividing by 0 gives 0"


def af_expr(text):
    t = text.replace("−", "-").replace("²", "**2")
    need(re.fullmatch(r"[0-9x+\-*/(). ]+", t) is not None, f"can't read {text!r}")
    return sp.nsimplify(parse_expr(t, transformations=TRANSFORMS, local_dict={"x": X}), rational=True)


def af_split_frac(text):
    """'(3x + 1)/(x − 4)' -> (top text, bottom text)."""
    m = re.fullmatch(r"(\(.+?\)|[^/]+)/(\(.+\)|[^/]+)", text)
    need(m is not None, f"can't read the fraction {text!r}")
    return m.group(1), m.group(2)


def af_excluded(f):
    """The x-values that make the bottom of f (a ratio of polynomials) zero."""
    num, den = sp.fraction(sp.together(f))
    return sorted(sp.real_roots(sp.Poly(den, X)))


def af_same(f, g):
    return sp.simplify(f - g) == 0


def check_algfrac(q):
    u, rep, asked, L = q["view"]["unknown"], q["view"]["rep"], q["asked"], q["lines"]
    need(q["paper"] == 1, "Paper 1")
    for t in [asked] + L + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    ft = frac_text
    if u == "excluded-value":
        if rep == "equation":
            top, bot = af_split_frac(L[0])
        else:
            m = re.fullmatch(r"A fraction has (.+) on the top and (.+) on the bottom\.", L[0])
            need(m is not None, f"can't read {L[0]!r}")
            top, bot = m.group(1), m.group(2)
        t, b = af_expr(top), af_expr(bot)
        h = sp.solve(b, X)
        need(len(h) == 1, "the bottom has one zero")
        h = sp.nsimplify(h[0])
        need(sp.simplify(t.subs(X, h)) != 0, "the top is zero where the bottom is")
        want = f"x ≠ {ft(h)}, because the bottom would be 0"
        wr = {AF + "3": {AF_ZERO_WORDS}}
        gc_check_common(q, want, wr)
    elif u == "simplify-by-cancelling":
        top, bot = af_split_frac(L[0])
        t, b = af_expr(top), af_expr(bot)
        f = sp.cancel(t / b)
        num, den = sp.fraction(f)
        h = sp.nsimplify(sp.solve(b, X)[0])
        common = sp.Poly(sp.gcd(t, b), X).degree()
        if common == 0:
            want = "it cannot be simplified"
            need(sp.Poly(t, X).degree() == 1 and sp.Poly(b, X).degree() == 1, "a cancel that is not one bracket over one bracket")
            a_, b_ = sp.Poly(t, X).all_coeffs()[1], sp.Poly(b, X).all_coeffs()[1]
            need(a_ != b_, "the brackets are the same")
            wr = {AF + "0": {ft(sp.Rational(a_, b_))}}
        else:
            need(common == 1, "more than one common factor")
            want = f"{af_poly_text(sp.cancel(t / b))} (x ≠ {ft(h)})"
            need(sp.Poly(sp.fraction(sp.cancel(t / b))[1], X).degree() == 0, "the simplest form still has x in the bottom")
            wr = {}
        gc_check_common(q, want, wr)
    elif u == "add-fractions":
        m = re.fullmatch(r"(−?\d+)/\((.+?)\) \+ (−?\d+)/\((.+?)\)", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        f = af_expr(m.group(1)) / af_expr(m.group(2)) + af_expr(m.group(3)) / af_expr(m.group(4))
        g = sp.together(f)
        num, den = sp.fraction(g)
        bot = f"(({m.group(2)})({m.group(4)}))"
        npoly = sp.Poly(num, X)
        want = f"{af_wrap(af_poly_text(npoly.as_expr()))}/{bot}"
        need(af_same(af_expr(want), f), "the right option is not the sum")
        p, a, q_, b = (int(m.group(i).replace("−", "-")) if i in (1, 3) else None for i in (1, 2, 3, 4))
        wrong_sum = f"{ft(af_expr(m.group(1)) + af_expr(m.group(3)))}/{af_wrap(af_poly_text(af_expr(m.group(2)) + af_expr(m.group(4))))}"
        for o in q["choices"]:
            if not o["correct"]:
                try:
                    need(not af_same(af_expr(o["text"]), f), f"a wrong option {o['text']!r} is the sum")
                except ZeroDivisionError:
                    pass
        gc_check_common(q, want, {AF + "1": {wrong_sum}})
    elif u == "clear-and-solve":
        m = re.fullmatch(r"(−?\d+)(?: ([+−]) (\d+))?/\((.+?)\) = (−?\d+)", L[0].replace(" + ", " + ", 1))
        m = re.fullmatch(r"(−?\d+) ([+−]) (\d+)/\((.+?)\) = (−?\d+)", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        a = int(m.group(1).replace("−", "-"))
        k = int(m.group(3)) * (1 if m.group(2) == "+" else -1)
        bracket = af_expr(m.group(4))
        c = int(m.group(5).replace("−", "-"))
        sol = sp.solve(sp.Eq(a + k / bracket, c), X)
        need(len(sol) == 1 and sol[0].is_integer and bracket.subs(X, sol[0]) != 0, "the solution is not a whole number or is excluded")
        x = sol[0]
        need(a + k / bracket.subs(X, x) == c, "the solution doesn't satisfy the equation")
        wrong_x = sp.nsimplify(sp.solve(sp.Eq(a + k, c * bracket), X)[0])
        need(wrong_x != x, "the slip gives the right answer")
        gc_check_common(q, f"x = {ft(x)}", {AF + "2": {f"x = {ft(wrong_x)}"}})
    elif u == "missing-numerator":
        m = re.fullmatch(r"Fill in the numerator: (.+?) = \(□\)/\((.+?)\)\.", asked)
        need(m is not None, f"can't read {asked!r}")
        top, bot = af_expr(m.group(1)), af_expr(m.group(2))
        num = sp.expand(sp.cancel((top - 0) * bot))
        want = af_poly_text(num) if num.has(X) else ft(num)
        need(af_same(top, num / bot), "the right option is not the numerator")
        for o in q["choices"]:
            if not o["correct"]:
                need(not af_same(af_expr(o["text"]) / bot, top), f"a wrong option {o['text']!r} is the numerator")
        gc_check_common(q, want, {})
    else:
        raise Fail(f"no check for {u}")
    return None, None


def af_poly_text(e):
    """A polynomial in x as the game writes it ('x² + 5x + 6' is not used: the game writes
    the simplified results, which here are linear or constant)."""
    P = sp.Poly(sp.expand(e), X)
    cs = P.all_coeffs()
    if P.degree() == 0:
        return frac_text(cs[0])
    if P.degree() == 1:
        a, b = cs
        out = ("−" if a < 0 else "") + ("" if abs(a) == 1 else frac_text(abs(a))) + "x"
        if b != 0:
            out += (" − " if b < 0 else " + ") + frac_text(abs(b))
        return out
    raise Fail(f"can't write {e}")


def af_wrap(t):
    return t if " " not in t else f"({t})"


def af_spot(q, lines):
    """The first line of a student's solution of a + k/(x − h) = c that is not an equation with
    the true solution: a line is right when its solution is the equation's solution."""
    m = re.fullmatch(r"(−?\d+) ([+−]) (\d+)/\((.+?)\) = (−?\d+)", q["lines"][0] if not q["lines"][0].startswith("A student") else q["lines"][0])
    # the question's own equation is the first of the lines before the student's working
    eq_line = next(l for l in q["lines"] if re.fullmatch(r"(−?\d+) ([+−]) (\d+)/\((.+?)\) = (−?\d+)", l))
    m = re.fullmatch(r"(−?\d+) ([+−]) (\d+)/\((.+?)\) = (−?\d+)", eq_line)
    a = int(m.group(1).replace("−", "-"))
    k = int(m.group(3)) * (1 if m.group(2) == "+" else -1)
    bracket = af_expr(m.group(4))
    true_x = sp.solve(sp.Eq(a + k / bracket, int(m.group(5).replace("−", "-"))), X)
    for i, line in enumerate(lines):
        if " = " not in line:
            continue
        l, r = line.split(" = ", 1)
        try:
            sol = sp.solve(sp.Eq(af_expr(l), af_expr(r)), X)
        except Exception:
            sol = None
        if sol != true_x:
            return i
    return None


SPOT_CHECKS["fn-pre-algebraic-fractions"] = af_spot

# ── Asymptote gallery (FAL-423): rational-asymptote-gallery ───
# Each fact about the example is worked out again with SymPy (a limit, where f(x) = A, where
# the function is undefined, what cancels), the right statement is written from those facts,
# and every other option is shown not to be it.

AG_STORIES = {"the number of fish in a lake": (" thousand fish", "years"), "the concentration of salt in a tank": (" g per litre", "minutes"),
              "the speed of a rocket sled": (" m/s", "seconds")}
AG_RM, AG_NO_HA, AG_SWAP, AG_RATIO = "SL2.8.rational-model#0", "SL2.8.asymptotes#2", "SL2.4.asymptotes#1", "SL2.8.asymptotes#1"


def ag_lin(q):
    """f(x) = (ax + b)/(x + d) from the givens, checked against the line that shows it."""
    g = q["given"]
    a, b, d = (int(R(g[n])) for n in "abd")
    f = (a * X + b) / (X + d)
    for t in q["lines"]:
        if t.startswith("f(x) = ") and "(" in t:
            need(sp.simplify(rf_expr(t) - f) == 0, f"the equation shown {t!r} is not the givens")
    T = rf_truth(f)
    need(sp.nsimplify(g["A"]) == T["A"] and sp.nsimplify(g["h"]) == T["h"] and sp.nsimplify(g["B"]) == T["B"], "the givens' A, h and B are not f's")
    need(T["A"].q == 1 and T["h"].q == 1 and T["B"].q == 1 and T["A"] != 0 and T["h"] != 0, "A, h and B are whole numbers")
    return f, T, (a, b, d)


def ag_dec4(v):
    return dec_text(sp.Rational(str(round(float(v) * 10000)), 10000))


def check_gallery(q):
    u, rep, asked, L = q["view"]["unknown"], q["view"]["rep"], q["asked"], q["lines"]
    need(q["paper"] == 1, "Paper 1")
    for t in [asked] + L + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    ft = frac_text
    if u == "asymptote-in-context":
        m = re.fullmatch(r"(.+) is modelled by P\(t\) = \((\d+)t \+ (\d+)\)/\(t \+ (\d+)\), where t is in (.+)\.", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        story = m.group(1)[0].lower() + m.group(1)[1:]
        need(story in AG_STORIES and AG_STORIES[story][1] == m.group(5), "the story's units")
        P = (int(m.group(2)) * X + int(m.group(3))) / (X + int(m.group(4)))
        Lv = sp.limit(P, X, sp.oo)
        need(Lv == int(m.group(2)), "the long-run value is not L")
        need(sp.simplify(Lv - P).subs(X, 0) > 0 and sp.solve(sp.Eq(P, Lv), X) == [], "the level reaches L")
        unit = AG_STORIES[story][0]
        cap = m.group(1)
        want = f"In the long run {story} gets closer and closer to {ft(Lv)}{unit}, but it never reaches it."
        wr = {AG_RM: {f"{cap} reaches {ft(Lv)}{unit} after enough {m.group(5)}."}}
        gc_check_common(q, want, wr)
        return None, None
    if u == "gap-not-asymptote":
        fr = L[0].split(" = ", 1)[1]
        top, bot = af_split_frac(fr)
        num, den = af_expr(top), af_expr(bot)
        simple = sp.cancel(num / den)
        need(not simple.has(X), "f is not a constant with a gap")
        h = sp.solve(den, X)
        need(len(h) == 1, "the bottom has one zero")
        h = sp.nsimplify(h[0])
        need(sp.simplify(num.subs(X, h)) == 0, "the top is not zero at the gap")
        want = f"{fr} is {ft(simple)} for every x except x = {ft(h)}, so the graph is the line y = {ft(simple)} with one point missing: a gap, not an asymptote."
        need(asked == f"Does f have an asymptote at x = {ft(h)}? Say why.", "the question names another x")
        gc_check_common(q, want, {})
        return None, None
    if u == "crosses-horizontal":
        g = q["given"]
        kind = g["kind"]
        if kind == "lin":
            f, T, co = ag_lin(q)
            A, shown = T["A"], RationalFunctionSituation_text(co)
        else:
            A = sp.Integer(int(R(g["A"])))
            f = {"bell": X / (X**2 + 1), "decay": X * sp.exp(-X), "shifted": A + X / (X**2 + 1)}[kind]
            shown = {"bell": "x/(x² + 1)", "decay": "x·e^(−x)", "shifted": f"{ft(A)} + x/(x² + 1)"}[kind]
        need(any(shown in t for t in L), "the function shown is not the one in the givens")
        need(sp.limit(f, X, sp.oo) == A, "A is not the horizontal asymptote")
        line = f"y = {ft(A)}"
        need(f"horizontal asymptote {line}" in asked, "the question's asymptote")
        sols = sp.solve(sp.Eq(f, A), X)
        if kind != "lin":
            need(sols == [0], "the curve meets its asymptote at x = 0 only")
            want = f"Yes: it crosses {line} at x = 0, where {'x·e^(−x)' if kind == 'decay' else 'x/(x² + 1)'} is 0."
        else:
            need(sols == [], "f meets its asymptote")
            B, h = T["B"], T["h"]
            want = f"No: f(x) = {ft(A)} would need {ft(B)}/(x − {ft(h)}) = 0, and a fraction with a top of {ft(B)} is never 0."
        if rep == "graph":
            gr = q["graph"]
            fl = sp.lambdify(X, f, "math")
            need(all(abs(fl(x) - y) < 1e-6 for cv in gr["curves"] for x, y in cv), "the curve drawn is not f")
            need(any(abs(hl["at"] - float(A)) < 1e-9 for hl in gr["hlines"]), "the horizontal asymptote is not drawn")
        gc_check_common(q, want, {})
        return None, None
    f, T, co = ag_lin(q)
    h, A, B = T["h"], T["A"], T["B"]
    a, b, d = co
    if u == "why-vertical":
        need(asked == f"Why does the graph have a vertical asymptote at x = {ft(h)}, and what happens to y on each side?", "the question names another x")
        left, right_ = sp.limit(f, X, h, "-"), sp.limit(f, X, h, "+")
        need({left, right_} == {-sp.oo, sp.oo}, "the sides don't go to ±∞")
        low = "very large and negative" if left == -sp.oo else "very large and positive"
        high = "very large and positive" if left == -sp.oo else "very large and negative"
        h_ = ft(h)
        mk = lambda l, r: f"At x = {h_} the bottom is 0, so f is undefined there. Just left of x = {h_}, y is {l}; just right of it, y is {r}."
        want = mk(low, high)
        if rep == "table":
            for xs, ys in zip(q["table"]["rows"][0][1], q["table"]["rows"][1][1]):
                need(abs(float(f.subs(X, R(xs.replace("−", "-")))) - float(R(ys.replace("−", "-")))) < 0.00006, f"the table's f({xs}) is not {ys}")
        wr = {AG_SWAP: {f"The graph levels off at the value x = {h_}, so it is a horizontal asymptote."}}
        gc_check_common(q, want, wr)
    elif u == "why-horizontal":
        need(asked == f"Why does y get close to {ft(A)} for large x?", "the question names another value")
        need(sp.limit(f, X, sp.oo) == A, "the limit is not A")
        ax = "x" if a == 1 else f"{a}x"
        ax = ("−" if a < 0 else "") + ("" if abs(a) == 1 else str(abs(a))) + "x"
        ax = ax if a != 1 else "x"
        want = f"For large x the numbers {ft(b)} and {ft(d)} matter less and less next to {ax} and x, so f(x) is close to {ft(A)}."
        if rep == "table":
            for xs, ys in zip(q["table"]["rows"][0][1], q["table"]["rows"][1][1]):
                need(abs(float(f.subs(X, R(xs.replace("−", "-")))) - float(R(ys.replace("−", "-")))) < 0.00006, f"the table's f({xs}) is not {ys}")
        frac = L[0].split(" = ", 1)[1] if rep == "equation" else RationalFunctionSituation_text(co)
        wr = {AG_NO_HA: {f"It doesn't: {frac} has no horizontal asymptote, because the top is not a constant."},
              AG_RATIO: {f"f(x) gets close to {ft(sp.Rational(b, d))}, the ratio of the constants {ft(b)} and {ft(d)}."}}
        gc_check_common(q, want, wr)
    elif u == "crosses-vertical":
        need(asked == f"A student says the graph can cross its vertical asymptote x = {ft(h)}. Is that right?", "the question names another x")
        need(sp.simplify(sp.fraction(sp.together(f))[1].subs(X, h)) == 0, "f is defined at x = h")
        if rep == "graph":
            rf_graph_is(q["graph"], rf_truth(f))
        want = f"No: f is not defined at x = {ft(h)}, so no point of the graph has x = {ft(h)}."
        gc_check_common(q, want, {})
    else:
        raise Fail(f"no check for {u}")
    return None, None


def RationalFunctionSituation_text(co):
    a, b, d = co
    return f"{af_wrap(rf_poly(a, b))}/{af_wrap(rf_poly(1, d))}"


# ── Rational models (FAL-423): rational-model ─────────────────
# The model f(x) = (αx + β)/(x + γ) is read back from the givens and from the formula or the
# words the question shows; every value, input, count and constant is worked out again with
# SymPy by substituting, solving and trying whole numbers.

RM = "SL2.8.rational-model#"
RM_REACHES, RM_ROUND_DOWN, RM_REAL_VALUE, RM_OUTPUT = RM + "0", RM + "1", RM + "2", "SL2.2.function-model#2"
RM_UNITS = {"cost": (" dollars per item", " items", "A", "n"), "mix": (" g per litre", " litres", "C", "x")}


def rm_model(q):
    g = q["given"]
    ctx = g["ctx"]
    al, be, ga = (int(R(g[n])) for n in ("al", "be", "ga"))
    if ctx == "cost":
        need(ga == 0 and al == int(R(g["v"])) and be == int(R(g["F"])), "the cost model's numbers")
        info = RM_UNITS["cost"]
    elif ctx == "mix":
        need(ga == int(R(g["V"])) and al == int(R(g["p"])) and be == int(R(g["s"])) == int(R(g["V"])) * int(R(g["c0"])), "the mixture's numbers")
        info = RM_UNITS["mix"]
    else:
        need(ga == int(R(g["k"])) and al == int(R(g["L"])) and be == int(R(g["P0"])) * int(R(g["k"])), "the settling model's numbers")
        story = g["story"]
        need(tuple(story[:1]) and story[0] in AG_STORIES and AG_STORIES[story[0]] == (story[1], story[2]), "the story's units")
        info = ("%s" % story[1], " " + story[2], "P", "t")
    f = (al * X + be) / (X + ga)
    return ctx, al, be, ga, f, info


def rm_terminates(v):
    v = R(v)
    d = v.q
    while d % 2 == 0:
        d //= 2
    while d % 5 == 0:
        d //= 5
    return d == 1


def check_model(q):
    u, rep, asked, L = q["view"]["unknown"], q["view"]["rep"], q["asked"], q["lines"]
    need(q["paper"] == 1, "Paper 1")
    for t in [asked] + L + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")
    ctx, al, be, ga, f, (unit, in_unit, fn, v) = rm_model(q)
    g = q["given"]
    ft, dt = frac_text, dec_text
    # the formula or the words shown are the givens
    for t in L:
        m = re.search(rf"{fn}\({v}\) = (\(.+?\)/\(?.+?\)?)(?: dollars| grams|,|\.)", t)
        if m and u not in ("parameters-from-data", "build-model"):
            rhs = m.group(1).replace(f"({v})", "(x)").replace(v, "x")
            need(sp.simplify(rf_expr(rhs.replace(" grams", "")) - f) == 0, f"the formula shown {m.group(1)!r} is not the givens")
    if rep == "words" and u != "parameters-from-data":
        j = " ".join(L)
        if ctx == "cost":
            need(f"fixed cost of {be} dollars, and each item costs {al} dollars" in j, "the words don't give F and v")
        else:
            need(f"holds {ga} litres of water with {be} grams of salt" in j and f"at {al} grams per litre" in j, "the words don't give V, s and p")
    nm = "settle" if ctx == "settle" else ctx
    long_run = {"cost": ("The average cost per item gets closer and closer to {a} dollars, the cost of making one more item, but never reaches it.", "The average cost per item reaches {a} dollars once enough items are made."),
                "mix": ("The concentration gets closer and closer to {a} g per litre, the strength of the water added, but never reaches it.", "The concentration reaches {a} g per litre after enough litres are added.")}
    if u == "evaluate-model":
        m = re.fullmatch(rf"Find {fn}\((\d+)\)\.", asked)
        need(m is not None, f"can't read {asked!r}")
        x0 = int(m.group(1))
        val = f.subs(X, x0)
        need(rm_terminates(val) and val > 0, "the value is not a decimal that ends")
        if rep == "table":
            need(x0 not in [int(R(x)) for x in q["table"]["rows"][0][1]], "x0 is in the table")
        gc_check_common(q, f"{fn}({x0}) = {dt(val)}{unit}", {})
    elif u == "long-run-value":
        need(sp.limit(f, X, sp.oo) == al and sp.solve(sp.Eq(f, al), X) == [], "the long-run value is α and is never reached")
        if ctx == "settle":
            story = g["story"][0]
            cap = story[0].upper() + story[1:]
            want = f"In the long run {story} gets closer and closer to {al}{unit}, but never reaches it."
            wr = {RM_REACHES: {f"{cap} reaches {al}{unit} after enough {in_unit.strip()}."}}
        else:
            want = long_run[ctx][0].format(a=al)
            wr = {RM_REACHES: {long_run[ctx][1].format(a=al)}}
        if rep == "graph":
            gr = q["graph"]
            fl = sp.lambdify(X, f, "math")
            need(all(abs(fl(x) - y) < 1e-6 * max(1, abs(y)) for cv in gr["curves"] for x, y in cv), "the curve drawn is not the model")
            need(any(abs(hl["at"] - al) < 1e-9 for hl in gr["hlines"]), "the asymptote isn't drawn")
        gc_check_common(q, want, wr)
    elif u in ("least-n-for-target", "input-for-value"):
        if u == "least-n-for-target":
            m = re.search(r"(?:less than|at least) (−?[\d.]+) (?:dollars|g per litre|[a-z ]+?)(?: of|\?|$)", asked)
            m = re.search(r"(?:less than|at least) (−?[\d.]+)", asked) if m is None else m
            need(m is not None, f"can't read {asked!r}")
            T = sp.nsimplify(m.group(1).replace("−", "-"), rational=True)
            if ctx == "settle":
                T = T
            cond = (lambda val: val < T) if ctx == "cost" else (lambda val: val >= T)
            ns = next(n for n in range(1, 2000) if cond(f.subs(X, n)))
            need(not cond(f.subs(X, ns - 1)) if ns > 1 else True, "n is not the least")
            xstar = sp.solve(sp.Eq(f, T), X)
            need(len(xstar) == 1 and not xstar[0].is_integer and xstar[0] > 0, "the exact solution is whole or not positive")
            need(sp.ceiling(xstar[0]) == ns, "n is not the next whole number up")
            val_n = f.subs(X, ns)
            shown = dt(sp.Rational(int(sp.floor(val_n * 100 + sp.Rational(1, 2))), 100))
            want = f"{v} = {ns}{in_unit}"
            gc_check_common(q, want, {RM_ROUND_DOWN: {f"{v} = {ns - 1}{in_unit}"}, RM_OUTPUT: {f"{v} = {shown}{in_unit}"}})
        else:
            m = re.fullmatch(rf"For which {v} is {fn}\({v}\) = (−?[\d.]+)\?", asked)
            need(m is not None, f"can't read {asked!r}")
            T = sp.nsimplify(m.group(1).replace("−", "-"), rational=True)
            sol = sp.solve(sp.Eq(f, T), X)
            need(len(sol) == 1 and sol[0].is_integer and sol[0] > 0, "the input is not a whole number")
            if rep == "table":
                need(int(sol[0]) not in [int(R(x)) for x in q["table"]["rows"][0][1]], "the answer is in the table")
            if rep == "graph":
                need(any(abs(hl["at"] - float(T)) < 1e-9 for hl in q["graph"]["hlines"]), "the line y = T isn't drawn")
            gc_check_common(q, f"{v} = {sol[0]}{in_unit}", {})
        if rep == "table":
            for xs, ys in zip(q["table"]["rows"][0][1], q["table"]["rows"][1][1]):
                need(R(ys.replace("−", "-")) == f.subs(X, R(xs)), f"the table's value at {xs} is wrong")
    elif u == "build-model":
        if ctx == "cost":
            want = f"A(n) = ({be} + {al}n)/n"
            need(asked == "Write the model for the average cost per item of n items, A(n)." and sp.simplify((be + al * X) / X - f) == 0, "the cost model")
        else:
            want = f"C(x) = ({be} + {al}x)/({ga} + x)"
            need(asked == "Write the model for the concentration after x litres are added, C(x)." and sp.simplify((be + al * X) / (ga + X) - f) == 0, "the mixture model")
        for o in q["choices"]:
            rhs = o["text"].split(" = ", 1)[1].replace("n", "x")
            if o["correct"]:
                need(sp.simplify(rf_expr(rhs) - f) == 0, "the right model is not the model")
            else:
                need(sp.simplify(rf_expr(rhs) - f) != 0, f"a wrong option {o['text']!r} is the model")
        gc_check_common(q, want, {})
    elif u == "interpret-vertical-asymptote":
        need(f"vertical asymptote at {v} = {ft(-ga)}." in asked, "the asymptote asked about")
        need(sp.fraction(sp.together(f))[1].subs(X, -ga) == 0, "the asymptote is not where the bottom is 0")
        if ctx == "cost":
            want = "n = 0 is outside the sensible domain: with no items made the average cost is not defined."
            wr = {RM_REAL_VALUE: {"n = 0 is a real production level: making 0 items gives the highest average cost."}}
        elif ctx == "mix":
            want = f"x = {ft(-ga)} is outside the sensible domain: a negative number of litres can't be added."
            wr = {RM_REAL_VALUE: {f"x = {ft(-ga)} is a real amount: adding {ft(-ga)} litres gives the strongest mixture."}}
        else:
            want = f"t = {ft(-ga)} is outside the sensible domain: the model starts at t = 0, so a negative time is never used."
            wr = {RM_REAL_VALUE: {f"t = {ft(-ga)} is a real time: the level is largest {ga} {g['story'][2]} before the start."}}
        if rep == "graph":
            gr = q["graph"]
            fl = sp.lambdify(X, f, "math")
            need(all(abs(fl(x) - y) < 1e-6 * max(1, abs(y)) for cv in gr["curves"] for x, y in cv), "the curve drawn is not the model")
        gc_check_common(q, want, wr)
    elif u == "parameters-from-data":
        K = sp.Symbol("K")
        g_ = q["given"]
        if ctx == "cost":
            name, shown_f, val = "F", (K + al * X) / X, be
        elif ctx == "mix":
            name, shown_f, val = "s", (K + al * X) / (ga + X), be
        else:
            name, shown_f, val = "k", (al * X + int(R(g_["P0"])) * K) / (X + K), ga
        x1, y1 = int(R(g_["x1"])), R(g_["y1"])
        sol = sp.solve(sp.Eq(shown_f.subs(X, x1), y1), K)
        need(len(sol) == 1 and sol[0] == val and sol[0].is_integer and sol[0] > 0, f"the constant is {sol}, not {val}")
        if rep == "words":
            need(f"{dt(y1)}" in " ".join(L), "the data point is not in the words")
        else:
            for xs, ys in zip(q["table"]["rows"][0][1], q["table"]["rows"][1][1]):
                need(R(ys.replace("−", "-")) == f.subs(X, R(xs)), f"the table's value at {xs} is wrong")
            need(any(int(R(xs)) == x1 for xs in q["table"]["rows"][0][1]), "the data point is not in the table")
        gc_check_common(q, f"{name} = {val}{' dollars' if ctx == 'cost' else ' grams' if ctx == 'mix' else ' ' + g_['story'][2]}", {})
    else:
        raise Fail(f"no check for {u}")
    return None, None


# ── Differentiation (FAL-723) ────────────────────────────────
# Reads the function back from the line shown, differentiates it with SymPy and compares
# every option with that at several points, in mpmath. Each tagged wrong option is worked
# out again from the misconception, from the numbers in the given, and those numbers are
# first held to the function on screen.

CX, CP = sp.Symbol("x"), sp.Symbol("p")
CALC_PTS = (sp.Rational(137, 100), sp.Rational(271, 100), sp.Rational(393, 100))
CALC_LOCALS = {"x": CX, "t": CX, "p": CP, "exp": sp.exp, "sqrt": sp.sqrt, "log": sp.log, "sin": sp.sin, "cos": sp.cos,
               "cbrt": lambda e: e ** sp.Rational(1, 3)}
SUP_DIGITS = str.maketrans("⁰¹²³⁴⁵⁶⁷⁸⁹⁻", "0123456789-")


def calc_expr(text):
    """The game's way of writing a function, as SymPy: '4x e^(3x)(2 + x)', '(ln x)/x⁴', '6/∛x', 'x^(−1/2)'."""
    t = text.strip().replace("−", "-").replace("½", "(1/2)").replace("×", "*")
    t = re.sub(r"(?<![a-z])e([⁻⁰¹²³⁴⁵⁶⁷⁸⁹]+)", lambda m: "exp(" + m.group(1).translate(SUP_DIGITS) + ")", t)
    t = t.replace("e^(", "exp(").replace("e^x", "exp(x)").replace("e^t", "exp(t)")
    t = re.sub(r"[⁻⁰¹²³⁴⁵⁶⁷⁸⁹]+", lambda m: "**(" + m.group(0).translate(SUP_DIGITS) + ")", t)
    t = t.replace("√(", "sqrt(").replace("√x", "sqrt(x)").replace("∛(", "cbrt(").replace("∛x", "cbrt(x)")
    t = re.sub(r"ln ([0-9]+|x|t)", r"log(\1)", t).replace("ln(", "log(")
    t = re.sub(r"(sin|cos) (x|t)", r"\1(\2)", t).replace("^", "**")
    t = re.sub(r"([0-9xtp)]) ?(exp|sqrt|cbrt|log|sin|cos)\(", r"\1*\2(", t)
    t = re.sub(r"\) ?([a-z(0-9])", r")*\1", t)
    t = re.sub(r"\*\*\*", "**", t)
    t = re.sub(r"(?<![a-z])([xtp]) ?\(", r"\1*(", t)
    need(re.fullmatch(r"[0-9xtp+\-*/(). a-z]+", t) is not None, f"can't read the expression {text!r}")
    return parse_expr(t, transformations=TRANSFORMS, local_dict=CALC_LOCALS)


def calc_same(a, b):
    """Whether two expressions agree at three points (p = 1.7 where a letter is left in)."""
    d = sp.sympify(a) - sp.sympify(b)
    for x in CALC_PTS:
        v = sp.N(d.subs({CX: x, CP: sp.Rational(17, 10)}), 30)
        if abs(complex(v)) > 1e-10 * max(1.0, abs(complex(sp.N(sp.sympify(a).subs({CX: x, CP: sp.Rational(17, 10)}), 30)))):
            return False
    return True


def calc_rhs(text):
    return text.split(" = ", 1)[1]


def calc_template(ans, values):
    """The expression the slots make: the answer's own template, with these numbers in."""
    out = ""
    for item in ans["template"]:
        if isinstance(item, str):
            out += item
        else:
            v = str(values[item["slot"]])
            out += "(" + v + ")"
    return calc_rhs(out)


def calc_steps(q, steps=(2, 5)):
    need(len(q["solutions"]) >= 1, "no worked solution")
    for sol in q["solutions"]:
        need(steps[0] <= len(sol["steps"]) <= steps[1], f"{sol['name']}: {len(sol['steps'])} steps, not {steps[0]} to {steps[1]}")
        need(q["answer_text"] in sol["steps"][-1], f"{sol['name']}: last step {sol['steps'][-1]!r} doesn't state the answer")
    if q["view"]["angle"] != "any":
        need(q["solutions"][0]["angle"] == q["view"]["angle"], "the asked method is not the first worked solution")
    for t in [q["asked"]] + q["lines"] + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", t), f"a hyphen for a minus in {t!r}")


def calc_options(q):
    ch = q["choices"]
    need(len(ch) == 4, f"{len(ch)} options")
    need(sum(1 for o in ch if o["correct"]) == 1, "not exactly one right option")
    need(len({o["text"] for o in ch}) == 4, "two options read the same")
    need(q["answer_text"] == next(o["text"] for o in ch if o["correct"]), "the answer's text is not the right option")


DR_CHAIN = "SL5.6.chain-rule#"
DR_PROD = "SL5.6.product-rule#"
DR_QUOT = "SL5.6.quotient-rule#"
DR_STD = "SL5.6.standard-derivatives#"


def dr_wrongs(u, fam, g, f, df):
    """ref -> the expressions that misconception gives, worked out from f itself."""
    x = CX
    a, b, c, d, m, n = (int(g[k]) for k in "abcdmn")
    w = {}
    if u == "standard-terms":
        tr = sp.cos(x) if fam == "cos" else sp.sin(x)
        dtr = sp.diff(tr, x)
        w[DR_STD + "1"] = [a * x * sp.exp(x - 1) + b / x + c * dtr]
        if fam == "cos":
            w[DR_STD + "0"] = [a * sp.exp(x) + b / x + c * sp.sin(x)]
    elif u == "root-powers":
        r = {"sqrt": sp.Rational(1, 2), "cbrt": sp.Rational(1, 3), "invsqrt": -sp.Rational(1, 2), "invcbrt": -sp.Rational(1, 3)}[fam]
        w[DR_STD + "2"] = [a * r * x ** (r + 1) - n * b * x ** (-n - 1)]
    elif u == "log-power-terms":
        if fam == "power":
            w[DR_CHAIN + "0"] = [a / x ** n + b * m * x ** (m - 1)]
        else:
            w[DR_CHAIN + "1"] = [a / (d * x) + b * m * x ** (m - 1)]
    elif u == "chain-power":
        inn = a * x ** m + b
        w[DR_CHAIN + "0"] = [c * n * inn ** (n - 1)]
        w[DR_CHAIN + "2"] = [c * n * sp.diff(inn, x) ** (n - 1)]
    elif u == "chain-small-power":
        w[DR_CHAIN + "0"] = [2 * (a * x + b)]
    elif u == "chain-function":
        lin = a * x + b
        w[DR_CHAIN + "0"] = [{"exp-quad": sp.exp(a * x ** 2 + b), "exp-lin": sp.exp(lin), "ln-quad": 1 / (x ** 2 + b), "ln-lin": 1 / lin,
                              "sin-lin": sp.cos(lin), "cos-lin": -sp.sin(lin), "sqrt-lin": 1 / (2 * sp.sqrt(lin))}[fam]]
        if fam == "cos-lin":
            w[DR_STD + "0"] = [a * sp.sin(lin)]
    elif u == "chain-log-split":
        w[DR_CHAIN + "0"] = [(n if fam == "power" else sp.Rational(1, 2)) / (a * x + b)]
    elif u == "product-functions":
        U, V = {"exp": (x ** n, sp.exp(a * x)), "ln": (x ** n, sp.log(x)), "sin": (x ** n, sp.sin(x)), "cos": (x ** n, sp.cos(x)),
                "exp-sin": (sp.exp(x), sp.sin(x))}[fam]
        w[DR_PROD + "0"] = [sp.diff(U, x) * sp.diff(V, x)]
        w[DR_PROD + "1"] = [sp.diff(U, x) * V, U * sp.diff(V, x)]
        if fam == "ln":
            w[DR_PROD + "2"] = [x ** (n - 1) * n * sp.log(x)]
    elif u == "product-polys":
        U, V = a * x + b, c * x ** 2 + d
        w[DR_PROD + "0"] = [sp.diff(U, x) * sp.diff(V, x)]
        w[DR_PROD + "1"] = [sp.diff(U, x) * V, U * sp.diff(V, x)]
    elif u == "product-powers":
        U, V = a * x ** m, sp.sqrt(x)
        w[DR_PROD + "0"] = [sp.diff(U, x) * sp.diff(V, x)]
        w[DR_PROD + "1"] = [sp.diff(U, x) * V, U * sp.diff(V, x)]
    elif u in ("quotient-linear", "quotient-functions", "quotient-split"):
        U, V = {"quotient-linear": (a * x + b, c * x + d), "quotient-split": (a * x ** 2 + b * x + c, x)}.get(u) or \
            {"ln": (sp.log(x), x ** n), "exp": (sp.exp(a * x), x), "sin": (sp.sin(x), x)}[fam]
        du, dv = sp.diff(U, x), sp.diff(V, x)
        w[DR_QUOT + "0"] = [(U * dv - V * du) / V ** 2]
        w[DR_QUOT + "1"] = [(V * du - U * dv) / V]
        w[DR_QUOT + "2"] = [du / dv]
        if u == "quotient-functions" and fam == "ln":
            # The bracket's common factor cancelled as in the right answer, with v left unsquared.
            w[DR_QUOT + "1"].append((1 - n * sp.log(x)) / x ** n)
        if u == "quotient-functions" and fam == "exp":
            w[DR_QUOT + "1"].append(sp.exp(a * x) * (a * x - 1) / x)
    elif u == "parameter-derivative":
        L = a * x + CP
        K = x + c
        w[DR_QUOT + "0"] = [-df]
        w[DR_CHAIN + "0"] = [(3 * L ** 2 * K ** 2 - L ** 3 * 2 * K) / K ** 4]
        w[DR_QUOT + "1"] = [df * K]
    return w


def check_differentiation(q):
    g, u, L, ans = q["given"], q["view"]["unknown"], q["lines"], q["answer"]
    fam, paper = g["fam"], q["paper"]
    src = L[0]
    m = re.search(r"(?:y|f\(x\)) = (.+?)(?:, (?:for|where) .*)?\.?$", src)
    need(m is not None, f"can't read the function in {src!r}")
    f = calc_expr(m.group(1))
    df = sp.diff(f, CX)
    a, b, c, d, nm, n = (int(g[k]) for k in "abcdmn")
    x = CX
    # The numbers in the given are the function on screen.
    held = {"standard-terms": a * sp.exp(x) + b * sp.log(x) + c * (sp.cos(x) if fam == "cos" else sp.sin(x)) + d,
            "chain-power": c * (a * x ** nm + b) ** n, "chain-small-power": (a * x + b) ** 2,
            "product-polys": (a * x + b) * (c * x ** 2 + d), "product-powers": a * x ** nm * sp.sqrt(x),
            "quotient-linear": (a * x + b) / (c * x + d), "quotient-split": (a * x ** 2 + b * x + c) / x}.get(u)
    if held is not None:
        need(calc_same(f, held), "the function shown is not the one in the given")
    if u == "quotient-linear":
        need(a * d != b * c, "the quotient is a constant")
    calc_options(q)
    calc_steps(q)
    if paper == 2:
        need(u in ("chain-power", "chain-function", "quotient-functions", "gradient-chain", "gradient-product", "gradient-quotient", "parameter-derivative"), f"{u} is Paper 1 only")
    need(u != "parameter-derivative" or paper == 2, "the letter p is Paper 2 only")

    if u == "show-form":
        tm = re.fullmatch(r"Show that (?:dy/dx|f′\(x\)) = (.+), and state .*", L[1])
        need(tm is not None, f"can't read the target in {L[1]!r}")
        for o in q["choices"]:
            vals = dict(re.findall(r"([pqr]) = (−?\d+)", o["text"]))
            t = tm.group(1)
            for k, v in vals.items():
                t = re.sub(rf"(?<![a-z]){k}(?=x|[^a-z]|$)", "(" + v + ")", t)
            need(calc_same(calc_expr(t), df) == o["correct"], f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'}")
            if o["ref"]:
                nb = {k: int(v.replace("−", "-")) for k, v in vals.items()}
                right = {k: int(R(ans["values"]["v%d" % i])) for i, k in enumerate(["p", "q", "r"][:len(vals)])}
                if o["ref"].endswith("show-derivative-form#2"):
                    slip = {"ln": ("q", -right.get("q", 0)), "linear": ("p", -right["p"]), "alg": ("q", -right.get("q", 0) - 2)}[fam]
                    need(nb[slip[0]] == slip[1], f"{o['text']!r} is not a sign slip")
                else:
                    need(o["ref"] == DR_QUOT + "1" and nb["r"] == 2 * (right["r"] - 1), f"{o['text']!r} is not the bottom left unsimplified")
        return None, None

    if u.startswith("gradient-"):
        km = re.search(r"(?:f′\(|x = )(−?[\d.]+)", q["asked"])
        k = sp.Rational(km.group(1).replace("−", "-"))
        need(R(g["k"]) == k, "the x asked is not the x in the given")
        v = df.subs(x, k)
        if paper == 2:
            need((k * 10).q == 1 and k.q != 1, "a Paper 2 gradient is at an x to 1 d.p.")
            val = sp.Float(sp.N(v, 40), 40)
            need(not on_edge(abs(val)), "the gradient sits on a rounding edge")
            need(q["answer_text"] == "Gradient = " + gc_s(val), f"gradient {q['answer_text']!r}, not {gc_s(val)}")
            for o in q["choices"]:
                need((o["text"] == q["answer_text"]) == o["correct"], f"option {o['text']!r}")
            return None, None
        need(k.q == 1, "a Paper 1 gradient is at a whole x")
        for o in q["choices"]:
            t = calc_rhs(o["text"]).replace("(−", "(-")
            got = sp.sympify(calc_expr(t))
            need(calc_same(got, v) == o["correct"], f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'} ({v})")
            if o["ref"]:
                U = {"chain": None, "product": x ** n, "quotient": a * x + b}[fam]
                V = {"chain": None, "product": (a * x - b) ** 2, "quotient": x ** 2 + c}[fam]
                if fam == "chain":
                    want = [sp.exp(k ** 2 + b)]
                else:
                    du, dv = sp.diff(U, x).subs(x, k), sp.diff(V, x).subs(x, k)
                    Uk, Vk = U.subs(x, k), V.subs(x, k)
                    want = {DR_PROD + "0": [du * dv], DR_PROD + "1": [du * Vk, Uk * dv], DR_QUOT + "0": [(Uk * dv - Vk * du) / Vk ** 2],
                            DR_QUOT + "1": [(Vk * du - Uk * dv) / Vk], DR_QUOT + "2": [du / dv] if dv != 0 else []}[o["ref"]]
                need(any(calc_same(got, e) for e in want), f"option {o['text']!r} is not what {o['ref']} gives")
        return None, None

    wrongs = dr_wrongs(u, fam, g, f, df)
    filled = calc_expr(calc_template(ans, ans["values"]))
    need(calc_same(filled, df), f"the answer's slots make {filled}, not f′")
    for o in q["choices"]:
        got = calc_expr(calc_rhs(o["text"]))
        need(calc_same(got, df) == o["correct"], f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'}")
        if o["ref"]:
            need(o["ref"] in wrongs, f"the checker can't confirm {o['ref']} on {u}")
            need(any(calc_same(got, e) for e in wrongs[o["ref"]]), f"option {o['text']!r} is not what {o['ref']} gives")
        if not o["correct"] and "shape" not in o["values"]:
            need(calc_same(calc_expr(calc_template(ans, o["values"])), got), f"option {o['text']!r} is not what its slots make")
    return None, None


# ── What a derivative means, and limits (FAL-723) ────────────

DM_CONTEXTS = [("V", "volume of water in a tank", "litres", "minute", "minutes"), ("H", "temperature of a generator", "°C", "minute", "minutes"),
               ("R", "radiation reading at a checkpoint", "microsieverts", "hour", "hours"), ("D", "depth of water in a flooded canal", "metres", "hour", "hours"),
               ("P", "population of a settlement", "people", "year", "years"), ("F", "fuel in a convoy's tanks", "litres", "hour", "hours"),
               ("L", "length of a vine on the wall", "cm", "day", "days"), ("C", "charge in a battery bank", "kilowatt-hours", "hour", "hours")]
DM_I = "SL5.1.interpret-derivative#"
DM_L = "SL5.1.estimate-limit#"


def dm_model(q):
    for t in q["lines"]:
        m = re.search(r"[A-Z]\(t\) = (.+?), t ≥ 0", t)
        if m:
            return calc_expr(m.group(1).replace("t", "x").replace("x ≥", "t ≥"))
    raise Fail("can't read the model")


def dm_word(r):
    return "increasing" if r > 0 else "decreasing"


def dm_num(v):
    return str(v).replace("-", "−")


def dm_graph_curve(q, fn):
    f = sp.lambdify(CX, fn, "mpmath")
    for x, y in q["graph"]["curves"][0][:: 20]:
        need(abs(f(mpmath.mpf(str(x))) - mpmath.mpf(str(y))) < mpmath.mpf(10) ** -6, "the graph drawn is not the model")


def check_derivative_meaning(q):
    g, u, L, rep, asked = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"], q["asked"]
    need(q["paper"] == 2, "a derivative's meaning is Paper 2")
    sym, what, y, per, time = DM_CONTEXTS[int(g["ctx"])]
    unit = f"{y} per {per}"
    calc_options(q)
    calc_steps(q)
    wrongs, want, trap = {}, None, None
    if u in ("rate-at-time", "interpret-value"):
        fn = dm_model(q)
        t0 = int(g["t0"])
        r = sp.N(sp.diff(fn, CX).subs(CX, t0), 40)
        v = sp.N(fn.subs(CX, t0), 40)
        need(not on_edge(abs(r)) and not on_edge(abs(v)), "a value sits on a rounding edge")
        if u == "rate-at-time":
            label, tail = (f"{sym}′({t0}) = ", "") if rep == "equation" else (f"d{sym}/dt = ", " " + unit)
            want = label + gc_s(r) + tail
            trap = label + gc_s2(r) + tail
            wrongs = {DM_I + "0": {label + gc_s(v) + tail}, DM_I + "1": {label + gc_s(-r) + tail}}
        else:
            need(L[1] == f"{sym}′({t0}) = {gc_s(r)}, to 3 s.f.", f"the rate shown is {L[1]!r}")
            mag = gc_s(abs(r))
            want = f"At t = {t0}, the {what} is {dm_word(r)} at {mag} {unit}."
            wrongs = {DM_I + "0": {f"At t = {t0}, the {what} is {mag} {y}."},
                      DM_I + "1": {f"At t = {t0}, the {what} is {dm_word(-r)} at {mag} {unit}."},
                      DM_I + "2": {f"At t = {t0}, the {what} has {'gone up' if r > 0 else 'gone down'} by {mag} {y}."}}
            if rep == "graph":
                dm_graph_curve(q, fn)
                tang = q["graph"]["curves"][1]
                f = sp.lambdify(CX, v + r * (CX - t0), "mpmath")
                for x, yy in tang[:: 20]:
                    need(abs(f(mpmath.mpf(str(x))) - mpmath.mpf(str(yy))) < mpmath.mpf(10) ** -6, "the line drawn is not the tangent")
    elif u == "units-of-rate":
        want = unit
        wrongs = {DM_I + "2": {y}}
    elif u == "write-in-notation":
        m = re.fullmatch(rf"The {re.escape(what)} is (increasing|decreasing) at (\d+) {re.escape(unit)}\.", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        n = int(m.group(2)) * (1 if m.group(1) == "increasing" else -1)
        want = f"d{sym}/dt = {dm_num(n)}"
        wrongs = {DM_I + "0": {f"{sym} = {dm_num(n)}"}, DM_I + "1": {f"d{sym}/dt = {dm_num(-n)}"}}
    elif u == "compare-rates":
        t0 = int(g["t0"])
        if rep == "table":
            b, c = q["table"]["rows"][1][1]
        else:
            m = re.fullmatch(rf"A′\({t0}\) = (\S+) and B′\({t0}\) = (\S+)", L[1])
            need(m is not None, f"can't read {L[1]!r}")
            b, c = m.groups()
        b, c = R(b.replace("−", "-")), R(c.replace("−", "-"))
        need(abs(b) != abs(c), "the two rates have the same size")
        fast, slow = ("A", "B") if abs(b) > abs(c) else ("B", "A")
        move = f"A is {dm_word(b)} and B is {dm_word(c)}"
        want = f"{move}, and {fast} is changing faster."
        same = dm_word(-b) if b * c > 0 else "increasing"
        wrongs = {DM_I + "1": {f"Both are {same}, and {fast} is changing faster."}, DM_I + "0": {f"{fast} holds more than {slow} at t = {t0}."}}
    elif u in ("limit-of-model", "limit-of-rate"):
        fn = None
        if rep == "graph":
            m = re.search(r"= (.+), t ≥ 0", L[0])
            fn = calc_expr(m.group(1).replace("t", "x").replace("x ≥", "t ≥"))
            dm_graph_curve(q, fn)
        elif rep == "table":
            A, B, k = R(g["A"]), R(g["B"]), R(g["k"])
            fn = A + B * sp.exp(-k * CX)
            rows = q["table"]["rows"]
            for ts, vs in zip(rows[0][1], rows[1][1]):
                need(abs(sp.N(fn.subs(CX, int(ts))) - sp.Float(vs.replace("−", "-"))) < sp.Float(vs.replace("−", "-")).__abs__() * sp.Float("0.0001"), f"the table's value at t = {ts} is wrong")
        else:
            fn = dm_model(q)
        first = fn.subs(CX, 0)
        lim = sp.limit(fn, CX, sp.oo) if u == "limit-of-model" else sp.limit(sp.diff(fn, CX), CX, sp.oo)
        want = f"The limit is {dm_num(lim)}"
        wrongs = {DM_L + "0": {"The limit does not exist"}, DM_L + "1": {f"The limit is {dm_num(first)}" if u == "limit-of-model" else f"The limit is {dm_num(sp.limit(fn, CX, sp.oo))}"}}
    else:
        a = int(g["a"])
        if u == "limit-from-graph":
            m, rr, yd = int(g["m"]), int(g["rr"]), int(g["y"])
            lim = m * (a - rr)
            need(yd != lim, "the dot is at the height of the limit")
            need(len(q["graph"]["curves"]) == 1, "the two sides of the gap are one curve")
            pts = [p for p in q["graph"]["curves"][0] if p[1] <= q["graph"]["y1"]]
            need(all(abs(p[0] - a) > 0.1 for p in pts), "the curve has no gap at a")
            need({p[0] < a for p in pts} == {True, False}, "the curve is not on both sides of a")
            need(all(abs(p[1] - m * (p[0] - rr)) < 1e-6 for p in pts), "the curve is not m(x − r)")
            dot = q["graph"]["points"][0]
            need(dot["x"] == a and dot["y"] == yd, "the dot is not at (a, y)")
            wrongs = {DM_L + "1": {f"The limit is {dm_num(yd)}"}}
        else:
            top, bot = re.fullmatch(r"f\(x\) = \((.+)\)/\((.+)\)", L[0]).groups()
            ft, fb = calc_expr(top), calc_expr(bot)
            need(ft.subs(CX, a) == 0 and fb.subs(CX, a) == 0, "this is not 0/0 at a")
            f = sp.cancel(ft / fb)
            lim = f.subs(CX, a)
            if u == "limit-from-table":
                rows = q["table"]["rows"]
                xs, ys = [R(t.replace("−", "-")) for t in rows[0][1]], [R(t.replace("−", "-")) for t in rows[1][1]]
                need(xs == sorted(xs) and xs[1] < a < xs[2], "the table is not either side of a")
                for xv, yv in zip(xs, ys):
                    need(f.subs(CX, xv) == yv, f"the table's f({xv}) is wrong")
                wrongs = {DM_L + "2": {"The limit is " + dec_text(ys[1])}}
        want = f"The limit is {dm_num(lim)}"
        wrongs[DM_L + "0"] = {"The limit does not exist"}
    gc_check_common(q, want, wrongs, trap)
    return None, None


# ── Increasing and decreasing (FAL-723) ──────────────────────

MO_I = "SL5.2.increasing-decreasing-intervals#"
MO_G = "SL5.2.sign-from-graph#"
MO_P = "SL5.2.parameter-for-monotonic#"


def mo_iv(shape, lo, hi, s=dm_num):
    return f"{s(lo)} < x < {s(hi)}" if shape == "between" else f"x < {s(lo)} or x > {s(hi)}"


def mo_where(df, word, lo, hi):
    """Where f rises or falls, from the sign of f′ at a point inside each stretch: between or outside lo and hi."""
    mid = sp.N(df.subs(CX, (lo + hi) / 2), 30)
    up = mid > 0
    return "between" if up == (word == "increasing") else "outside"


def mo_two_roots(df):
    rs = sorted(sp.Poly(df, CX).ground_roots().keys())
    need(len(rs) == 2, f"f′ does not have two rational roots: {df}")
    return rs


def mo_sign(v):
    return "positive" if v > 0 else ("negative" if v < 0 else "zero")


def check_monotonic(q):
    g, u, L, rep, asked = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"], q["asked"]
    calc_options(q)
    calc_steps(q)
    word = "increasing" if "increasing" in asked or " increases " in asked else "decreasing"
    if q["view"]["angle"] in ("gdc-turning-points", "gdc-slider"):
        need(q["paper"] == 2, "a GDC method is Paper 2")
    wrongs, want = {}, None
    if u == "interval-from-equation":
        f = calc_expr(re.search(r"= (.+?)\.?$", L[0]).group(1))
        df = sp.diff(f, CX)
        p, r2 = mo_two_roots(df)
        shape = mo_where(df, word, p, r2)
        want = mo_iv(shape, p, r2)
        ys = sorted([f.subs(CX, p), f.subs(CX, r2)])
        wrongs = {MO_I + "0": {mo_iv(shape, ys[0], ys[1])}, MO_I + "2": {mo_iv("outside" if shape == "between" else "between", p, r2)}}
        need(sp.Poly(df, CX).LC() < 0 or not any(o["ref"] == MO_I + "2" for o in q["choices"]), "a wrong way round is only for a negative leading coefficient")
    elif u == "interval-from-table":
        rows = q["table"]["rows"]
        xs = [R(t.replace("−", "-")) for t in rows[0][1]]
        ys = [R(t.replace("−", "-")) for t in rows[1][1]]
        zs = [x for x, y in zip(xs, ys) if y == 0]
        need(len(zs) == 2 and xs == sorted(xs), "the table doesn't show two zeros of f′")
        # A cubic's f′ is the parabola through the table: it must fit all five points.
        fit = sp.interpolate(list(zip(xs[:3], ys[:3])), CX)
        for x, y in zip(xs, ys):
            need(fit.subs(CX, x) == y, "the table is not a quadratic f′")
        between = ys[2]
        need(between != 0 and ys[0] * between < 0 and ys[4] * between < 0, "f′ doesn't change sign at the zeros")
        shape = "between" if (between > 0) == (word == "increasing") else "outside"
        want = mo_iv(shape, zs[0], zs[1])
        wrongs = {MO_I + "2": {mo_iv("outside" if shape == "between" else "between", zs[0], zs[1])}}
    elif u == "quadratic-interval":
        f = calc_expr(L[0].split(" = ", 1)[1])
        df = sp.diff(f, CX)
        h = sp.solve(df, CX)[0]
        a = sp.Poly(f, CX).LC()
        rel = ">" if (a > 0) == (word == "increasing") else "<"
        want = f"x {rel} {dm_num(h)}"
        rs = sorted(sp.Poly(f, CX).ground_roots().keys())
        wrongs = {MO_I + "0": {f"y {rel} {dm_num(f.subs(CX, h))}"}, MO_I + "1": {f"{dm_num(rs[0])} < x < {dm_num(rs[1])}"},
                  MO_I + "2": {f"x {'<' if rel == '>' else '>'} {dm_num(h)}"}}
    elif u == "interval-from-derivative-graph":
        gp = q["graph"]
        pts = gp["points"]
        r1, r2 = R(int(pts[0]["x"])), R(int(pts[1]["x"]))
        need(pts[0]["y"] == 0 and pts[1]["y"] == 0, "the marked points are not on the axis")
        curve = gp["curves"][0]
        xm = float((r1 + r2) / 2)
        mid = min(curve, key=lambda c: abs(c[0] - xm))[1]
        need(mid != 0, "the curve is on the axis at the middle")
        for a, b in curve[:: 40]:
            sg = (mpmath.mpf(str(a)) - r1) * (mpmath.mpf(str(a)) - r2)
            need(abs(sg) < 1e-3 or abs(b / sg - (mid / ((xm - float(r1)) * (xm - float(r2))))) < 1e-6, "the curve is not a parabola through its marked points")
        shape = "between" if (mid > 0) == (word == "increasing") else "outside"
        want = mo_iv(shape, r1, r2)
        wrongs = {MO_I + "2": {mo_iv("outside" if shape == "between" else "between", r1, r2)}}
    elif u == "interval-gdc":
        need(q["paper"] == 2, "f′ with an exponential is Paper 2")
        df = calc_expr(L[0].split(" = ", 1)[1])
        fn = sp.lambdify(CX, df, "mpmath")
        zs = gc_zeros(df, -20, 8)
        need(len(zs) == 2, f"f′ has {len(zs)} zeros")
        need(all(gc_fair(z) for z in zs), "a zero sits on a rounding edge")
        up = fn((zs[0] + zs[1]) / 2) > 0
        shape = "between" if up == (word == "increasing") else "outside"
        want = mo_iv(shape, zs[0], zs[1], gc_s)
        wrongs = {MO_I + "2": {mo_iv("outside" if shape == "between" else "between", zs[0], zs[1], gc_s)}}
    elif u == "sign-at-points":
        x1, x2 = int(g["x1"]), int(g["x2"])
        co = [int(c) for c in g["coeffs"]]
        f = sum(c * CX ** (3 - i) for i, c in enumerate(co))
        df = sp.diff(f, CX)
        curve = q["graph"]["curves"][0]
        fnf = sp.lambdify(CX, f, "mpmath")
        for a, b in curve[:: 40]:
            need(abs(fnf(mpmath.mpf(str(a))) - mpmath.mpf(str(b))) < 1e-6, "the curve drawn is not f")
        need({p["label"] for p in q["graph"]["points"]} >= {"A", "B"}, "the points aren't marked")
        d1, d2 = df.subs(CX, x1), df.subs(CX, x2)
        txt = lambda a, b: f"f′({dm_num(x1)}) is {a} and f′({dm_num(x2)}) is {b}"
        want = txt(mo_sign(d1), mo_sign(d2))
        wrongs = {MO_G + "0": {txt(mo_sign(f.subs(CX, x1)), mo_sign(f.subs(CX, x2)))}}
    elif u == "intervals-from-graph":
        pts = q["graph"]["points"]
        h, k = R(int(pts[0]["x"])), R(int(pts[0]["y"]))
        r1, r2 = R(int(pts[1]["x"])), R(int(pts[2]["x"]))
        need(pts[1]["y"] == 0 and pts[2]["y"] == 0 and h == (r1 + r2) / 2, "the marks are not the vertex and roots")
        a = k / ((h - r1) * (h - r2))
        neg = "< 0" in asked
        rel = ">" if (a > 0) != neg else "<"
        want = f"x {rel} {dm_num(h)}"
        below = mo_iv("between" if a > 0 else "outside", r1, r2)
        above = mo_iv("outside" if a > 0 else "between", r1, r2)
        wrongs = {MO_G + "0": {below if neg else above}, MO_G + "1": {above if neg else below}}
    elif u == "negative-and-increasing":
        f = calc_expr(L[0].split(" = ", 1)[1])
        df = sp.diff(f, CX)
        rs = sorted(sp.Poly(f, CX).ground_roots().keys())
        a = sp.Poly(f, CX).LC()
        h = sp.solve(df, CX)[0]
        need(("negative and increasing" in asked) == (a > 0), "the words don't suit the parabola")
        # Checked on the x-axis: both conditions at a grid of points.
        good = [sp.Rational(i, 2) for i in range(-30, 30)]
        sign_ok = lambda x: (f.subs(CX, x) < 0 and df.subs(CX, x) > 0) if a > 0 else (f.subs(CX, x) > 0 and df.subs(CX, x) < 0)
        hit = [x for x in good if sign_ok(x)]
        want = f"{dm_num(min(hit) - sp.Rational(1, 2))} < x < {dm_num(max(hit) + sp.Rational(1, 2))}"
        wrongs = {MO_I + "1": {f"{dm_num(rs[0])} < x < {dm_num(rs[1])}"}}
    elif u == "parameter-discriminant":
        K = sp.Symbol("k")
        m = re.fullmatch(r"f\(x\) = (−?)x³ \+ kx² ([+−]) (\d*)x(?: ([+−]) (\d+))?", L[0])
        need(m is not None, f"can't read {L[0]!r}")
        sa = -1 if m.group(1) else 1
        c = int(m.group(3) or 1) * (-1 if m.group(2) == "−" else 1)
        need(sa * c > 0, "f′ can have no roots only if its ends agree")
        need(word == ("increasing" if sa > 0 else "decreasing"), "the word doesn't suit the sign of x³")
        bound = sp.solve((2 * K) ** 2 - 4 * 3 * sa * c, K)
        need(all(b.is_integer for b in bound) and len(bound) == 2, f"the bound isn't whole: {bound}")
        lo, hi = sorted(bound)
        want = f"{dm_num(lo)} ≤ k ≤ {dm_num(hi)}"
        b2 = sp.sqrt(4 * sa * c) * 1
        wrongs = {MO_P + "0": {f"−{mo_surd(b2)} ≤ k ≤ {mo_surd(b2)}"}, MO_P + "1": {f"k < {dm_num(lo)} or k > {dm_num(hi)}"}, MO_P + "2": {f"k ≤ {dm_num(hi)}"}}
    elif u == "parameter-shift":
        f = calc_expr(L[0].split(" = ", 1)[1])
        df = sp.diff(f, CX)
        h = sp.solve(df, CX)[0]
        k = f.subs(CX, h)
        need(sp.Poly(f, CX).LC() > 0, "g′ opens down, so g can't increase everywhere")
        want = f"d ≤ {dm_num(k)}"
        wrongs = {MO_P + "1": {f"d > {dm_num(k)}"}}
    gc_check_common(q, want, wrongs)
    return None, None


def mo_surd(v):
    """2√3 as the game writes it, from a SymPy surd."""
    c, r = v.as_coeff_Mul()
    return ("" if c == 1 else str(c)) + "√" + str(r.args[0])


# ── Second derivative and concavity (FAL-723) ────────────────

CO_F = "SL5.7.find-second-derivative#"
CO_C = "SL5.7.concavity#"
CO_M = "SL5.7.sketch-match-graphs#"


def co_read(line):
    m = re.search(r"(?:y|f\(x\)|f′\(x\)|f″\(x\)) = (.+?)(?:, (?:for|with) .*)?\.?$", line)
    need(m is not None, f"can't read {line!r}")
    return calc_expr(m.group(1))


def co_curve_is(curve, fn, tol=1e-6):
    f = sp.lambdify(CX, fn, "mpmath")
    return all(abs(f(mpmath.mpf(str(a))) - mpmath.mpf(str(b))) < tol for a, b in curve[:: 25])


def co_cubic(g):
    co = [int(c) for c in g["coeffs"]]
    return sum(c * CX ** (3 - i) for i, c in enumerate(co))


def co_cards(q, want, mistakes, main=None):
    """The right card is want; each wrong card is its named mistake and nothing else."""
    if main is not None:
        need(co_curve_is(q["graph"]["curves"][0], main), "the graph shown is not the function")
    cards = q["graphs"]
    need(len(cards) == 4, f"{len(cards)} cards")
    calc_options(q)
    calc_steps(q)
    for o, card in zip(q["choices"], cards):
        c = card["curves"][0]
        need(len(c) > 3, "a card has no curve")
        if o["correct"]:
            need(co_curve_is(c, want), "the right card is not the graph asked for")
        else:
            need(not co_curve_is(c, want), f"{o['text']} is the right graph too")
            m = o["mistake"]
            need(m in mistakes, f"the checker can't confirm the mistake {m!r}")
            need(co_curve_is(c, mistakes[m][0]), f"{o['text']} is not {m}")
            need(o["ref"] == mistakes[m][1], f"{o['text']}: ref {o['ref']!r} is not {mistakes[m][1]!r}")


def check_concavity(q):
    g, u, L, rep, asked = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"], q["asked"]
    if u.startswith("match-"):
        f = co_cubic(g)
        d1, d2 = sp.diff(f, CX), sp.diff(f, CX, 2)
        p, r2 = int(g["p"]), int(g["q"])
        need(sorted(sp.Poly(d1, CX).ground_roots().keys()) == [p, r2], "the turning points are not the ones the question gives")
        if q["view"]["angle"] == "gdc-nderiv":
            need(q["paper"] == 2, "a GDC method is Paper 2")
        A = sp.Poly(f, CX).LC()
        if u == "match-derivative":
            zs = gc_zeros(f, p - 2, r2 + 2)
            mist = {"shifted": (f - 4, CO_M + "0"), "flipped": (-d1, ""), "moved": (d1.subs(CX, CX - 1), CO_M + "1")}
            if len(zs) >= 2:
                mist["intercepts"] = (3 * A * (CX - sp.Float(zs[0], 25)) * (CX - sp.Float(zs[-1], 25)), CO_M + "1")
            co_cards(q, d1, mist, f)
        elif u == "match-second-derivative":
            co_cards(q, d2, {"shifted": (d1 - 3, CO_M + "0"), "flipped": (-d2, ""), "intercepts": (6 * A * (CX - p), CO_M + "1")}, d1)
        else:
            if rep == "table":
                rows = q["table"]["rows"]
                h = (p + r2) // 2
                need(rows[1][1] == ["+", "−", "−", "+"] and rows[2][1] == ["−", "−", "+", "+"], "the signs are not this cubic's")
                for x, a, b in [(p - 1, "+", "−"), (p + sp.Rational(1, 2), "−", "−"), (r2 - sp.Rational(1, 2), "−", "+"), (r2 + 1, "+", "+")]:
                    need((d1.subs(CX, x) > 0) == (a == "+") and (d2.subs(CX, x) > 0) == (b == "+"), f"the signs at {x} are wrong")
                need(dm_num(p) in rows[0][1][0] and dm_num(r2) in rows[0][1][3] and dm_num(h) in rows[0][1][1], "the stretches are not this cubic's")
            co_cards(q, f, {"flipped": (-f, ""), "moved": (f.subs(CX, CX + 2), ""), "parabola": (d1, CO_M + "0")})
        return None, None
    calc_options(q)
    calc_steps(q)
    if q["view"]["angle"] in ("gdc-gradient-of-derivative", "gdc-shape"):
        need(q["paper"] == 2, "a GDC method is Paper 2")
    wrongs, want, trap = {}, None, None
    up = "concave up" in asked
    if u == "second-derivative":
        f = co_read(L[0])
        d1, d2 = sp.diff(f, CX), sp.diff(f, CX, 2)
        wrongs = {CO_F + "0": [d1 ** 2], CO_F + "2": [d1 ** 2], CO_F + "1": [d1]}
        ans = q["answer"]
        need(calc_same(calc_expr(calc_template(ans, ans["values"])), d2), "the answer's slots are not f″")
        for o in q["choices"]:
            got = calc_expr(calc_rhs(o["text"]))
            need(calc_same(got, d2) == o["correct"], f"option {o['text']!r} is marked {'right' if o['correct'] else 'wrong'}")
            if o["ref"]:
                need(o["ref"] in wrongs and any(calc_same(got, e) for e in wrongs[o["ref"]]), f"option {o['text']!r} is not what {o['ref']} gives")
            if not o["correct"] and "shape" not in o["values"]:
                need(calc_same(calc_expr(calc_template(ans, o["values"])), got), f"option {o['text']!r} is not what its slots make")
        return None, None
    if u == "second-derivative-value":
        k = R(g["k"])
        e = co_read(L[0])
        given_prime = L[0].startswith("f′")
        d1 = e if given_prime else sp.diff(e, CX)
        d2 = sp.diff(d1, CX)
        v, b = d2.subs(CX, k), d1.subs(CX, k)
        lab = f"f″({dec_text(k)}) = "
        if q["paper"] == 2:
            need(k.q != 1 and (k * 10).q == 1, "a Paper 2 value is at an x to 1 d.p.")
            vv, bb = sp.N(v, 40), sp.N(b, 40)
            need(not on_edge(abs(vv)), "the value sits on a rounding edge")
            want, trap = lab + gc_s(vv), lab + gc_s2(vv)
            wrongs = {CO_F + "1": {lab + gc_s(bb)}, CO_F + "0": {lab + gc_s(bb ** 2)}}
        else:
            need(k.q == 1, "a Paper 1 value is at a whole x")
            want = lab + dm_num(v)
            wrongs = {CO_F + "1": {lab + dm_num(b)}, CO_F + "0": {lab + dm_num(b ** 2)}}
    elif u == "concave-interval":
        f = co_read(L[0])
        d1, d2 = sp.diff(f, CX), sp.diff(f, CX, 2)
        rs = sorted(sp.Poly(d2, CX).ground_roots().keys())
        if len(rs) == 1:
            h = rs[0]
            more = (sp.Poly(d2, CX).LC() > 0) == up
            want = f"x {'>' if more else '<'} {dm_num(h)}"
            z = sorted(sp.Poly(d1, CX).ground_roots().keys())
            wrongs = {CO_C + "0": {mo_iv("outside" if sp.Poly(d1, CX).LC() > 0 else "between", z[0], z[1])}}
        else:
            need(len(rs) == 2, f"f″ has {len(rs)} roots")
            shape = "between" if (d2.subs(CX, (rs[0] + rs[1]) / 2) > 0) == up else "outside"
            want = mo_iv(shape, rs[0], rs[1])
    elif u == "concave-exponential":
        d2 = co_read(L[0])
        h = sp.solve(d2, CX)
        need(len(h) == 1 and h[0].is_integer, f"f″ has no whole-number root: {h}")
        h = h[0]
        pos_right = d2.subs(CX, h + 1) > 0
        want = f"x {'>' if pos_right == up else '<'} {dm_num(h)}"
    elif u == "concave-gdc":
        need(q["paper"] == 2, "f′ with an exponential is Paper 2")
        d1 = co_read(L[0])
        zs = gc_zeros(d1, -20, 8)
        need(len(zs) == 2, "f′ doesn't have two zeros")
        d2 = sp.diff(d1, CX)
        x0 = sp.solve(d2, CX)[0]
        val = sp.N(x0, 40)
        need(not on_edge(abs(val)), "the answer sits on a rounding edge")
        right_pos = d2.subs(CX, x0 + 1) > 0
        want = f"x {'>' if right_pos == up else '<'} {gc_s(val)}"
        wrongs = {CO_C + "0": {mo_iv("between", zs[0], zs[1], gc_s)}}
    elif u == "concave-from-derivative-graph":
        pts = q["graph"]["points"]
        h, k, r1, r2 = R(int(pts[0]["x"])), R(int(pts[0]["y"])), R(int(pts[1]["x"])), R(int(pts[2]["x"]))
        need(pts[1]["y"] == 0 and pts[2]["y"] == 0 and h == (r1 + r2) / 2, "the marks are not the vertex and roots")
        a = k / ((h - r1) * (h - r2))
        need(co_curve_is(q["graph"]["curves"][0], a * (CX - r1) * (CX - r2)), "the graph is not the parabola its marks say")
        want = f"x {'>' if (a > 0) == up else '<'} {dm_num(h)}"
        wrongs = {CO_C + "0": {mo_iv("outside" if a > 0 else "between", r1, r2)}}
    elif u == "concave-at-point":
        m = re.search(r"f\(x\) = (.+?)(?:, with .*)?$", L[0])
        f = calc_expr(m.group(1))
        k = int(g["k"])
        d1, d2 = sp.diff(f, CX), sp.diff(f, CX, 2)
        v, b = d2.subs(CX, k), d1.subs(CX, k)
        need(v != 0, "f″ is 0 at the point")
        word = "up" if v > 0 else "down"
        txt = lambda n, w: f"f″({dm_num(k)}) = {dm_num(n)}, so the curve is concave {w}"
        want = txt(v, word)
        by_dir = "up" if b > 0 else "down"
        wrongs = {CO_C + "0": {txt(v, "up")}, CO_C + "1": {txt(v, "down")}}
        if rep == "graph":
            need(co_curve_is(q["graph"]["curves"][0], f), "the graph is not f")
            need(co_curve_is(q["graph"]["curves"][1], f.subs(CX, k) + b * (CX - k)), "the line is not the tangent")
        for o in q["choices"]:
            if o["ref"] in wrongs:
                need(by_dir != word and by_dir == o["text"].rsplit(" ", 1)[1], f"{o['text']!r} is not the shape read from the direction")
    gc_check_common(q, want, wrongs, trap)
    return None, None


# ── Indefinite integrals (FAL-724) ───────────────────────────
# Reads the integrand back from the question, then differentiates every option: the one
# right option must give the integrand back and end in + C, and no wrong one may. Each
# tagged wrong option is worked out again from its misconception, from the given's numbers,
# which are first held to the integrand on screen. Shares nothing with the engine.

IN_S = "SL5.10.standard-integrals#"
IN_P = "SL5.5.antidiff-power#"
IN_L = "SL5.10.linear-composites#"
IN_I = "SL5.10.inspection-substitution#"
IN_R = "SL5.10.rewrite-before-integrating#"
IN_U = sp.Symbol("u")


def in_expr(text):
    """An option or integrand as SymPy; '+ C' is taken off first."""
    t = re.sub(r" \+ C$", "", text.strip())
    t = re.sub(r"ln\|([^|]+)\|", r"ln(\1)", t).replace("e^u", "exp(u)").replace("ln u", "log(u)")
    t = re.sub(r"(sin|cos)([⁰¹²³⁴⁵⁶⁷⁸⁹]+) x", r"(\1 x)\2", t)
    return calc_expr(t)


def in_template(ans, values):
    out = ""
    for item in ans["template"]:
        out += item if isinstance(item, str) else "(" + str(values[item["slot"]]) + ")"
    return in_expr(out)


def in_wrongs(u, g):
    """(integrand, ref -> expressions) from the given's numbers. x is the only variable."""
    x, half = CX, sp.Rational(1, 2)
    v = {k: int(g[k]) for k in "abcknpq" if k in g and not isinstance(g[k], str)}
    a, b, c, k, n = (v.get(s, 0) for s in "abckn")
    p, q = v.get("p", 0), v.get("q", 0)
    fam = g.get("fam", "")
    lin = a * x + b
    w = {}
    if u == "power-polynomial":
        f = a * x ** 2 + b * x + c
        w[IN_P + "0"] = [a * x ** 3 / 2 + b * x ** 2 + c * x]
    elif u == "power-negative":
        f = a / x ** n + b * x
        w[IN_P + "0"] = [a * x ** (1 - n) / (-n) + b * x ** 2]
        w[IN_P + "2"] = [a * (n + 1) / x ** (n + 1) + b * x ** 2 / 2, a * sp.log(x ** n) + b * x ** 2 / 2]
    elif u == "power-product":
        f = (x + p) * (x + q)
    elif u == "standard-exp-trig":
        f = a * sp.exp(x) + b * sp.sin(x) + c * sp.cos(x)
        w[IN_S + "0"] = [a * sp.exp(x) + b * sp.cos(x) + c * sp.sin(x)]
    elif u == "standard-reciprocal":
        f = a * x + b + c / x
    elif u == "standard-roots":
        e = half if fam == "sqrt" else sp.Rational(1, 3)
        f = a * x ** e + b * x ** (-e)
        w[IN_S + "2"] = [a * (e + 1) * x ** (e + 1) + b * (1 - e) * x ** (1 - e)]
    elif u == "linear-exp":
        f = sp.exp(lin) + c
        w[IN_L + "0"] = [a * sp.exp(lin) + c * x]
        w[IN_L + "1"] = [sp.exp(lin) + c * x]
        w[IN_L + "2"] = [sp.exp(lin) / lin + c * x]
    elif u == "linear-trig":
        f = k * (sp.cos(lin) if fam == "cos" else sp.sin(lin))
        body = sp.sin(lin) if fam == "cos" else -sp.cos(lin)
        w[IN_L + "0"] = [k * a * body]
        w[IN_L + "1"] = [k * body]
    elif u == "linear-reciprocal":
        f = k / lin
        w[IN_L + "0"] = [k * a * sp.log(lin)]
        w[IN_L + "1"] = [k * sp.log(lin)]
    elif u in ("linear-power", "linear-square"):
        n1 = 2 if u == "linear-square" else n
        k1 = 1 if u == "linear-square" else k
        f = k1 * lin ** n1
        w[IN_L + "0"] = [k1 * a * lin ** (n1 + 1) / (n1 + 1)]
        w[IN_L + "1"] = [k1 * lin ** (n1 + 1) / (n1 + 1)]
    elif u == "inspection-power":
        ins = x ** 2 + a
        top = fam == "top"
        f = k * x * ins ** (n if top else -n)
        e = n + 1 if top else 1 - n
        w[IN_I + "0"] = [sp.Rational(k, e) * x * ins ** e]
        w[IN_I + "1"] = [sp.Rational(k, e) * ins ** e]
        w[IN_I + "2"] = [sp.Rational(k, 2 * e) * IN_U ** e]
    elif u == "inspection-exp":
        ins = x ** 2 + a
        f = k * x * sp.exp(ins)
        w[IN_I + "0"] = [k * x * sp.exp(ins)]
        w[IN_I + "1"] = [k * sp.exp(ins)]
        w[IN_I + "2"] = [sp.Rational(k, 2) * sp.exp(IN_U)]
    elif u == "inspection-log":
        ins = x ** 2 + a
        f = k * x / ins
        w[IN_I + "0"] = [k * x * sp.log(ins)]
        w[IN_I + "1"] = [k * sp.log(ins)]
        w[IN_I + "2"] = [sp.Rational(k, 2) * sp.log(IN_U)]
    elif u == "inspection-trig":
        sc = fam == "sincos"
        outer, inn = (sp.sin(x), sp.cos(x)) if sc else (sp.cos(x), sp.sin(x))
        f = k * outer * inn ** n
        c0 = sp.Rational(-k if sc else k, n + 1)
        w[IN_I + "0"] = [c0 * outer * inn ** (n + 1)]
        w[IN_I + "2"] = [c0 * IN_U ** (n + 1)]
    elif u == "rewrite-fraction":
        f = (a * x ** 2 + b * x + c) / x
        w[IN_R + "0"] = [(sp.Rational(a, 3) * x ** 3 + sp.Rational(b, 2) * x ** 2 + c * x) / (x ** 2 / 2)]
    elif u == "rewrite-square":
        if fam == "root":
            f = (a + sp.sqrt(x)) ** 2
            w[IN_R + "1"] = [a ** 2 * x + x ** 2 / 2]
        else:
            f = (sp.exp(x) + a) ** 2
            w[IN_R + "1"] = [sp.exp(2 * x) / 2 + a ** 2 * x]
    elif u == "rewrite-trig-product":
        f = k * sp.sin(x) * sp.cos(x)
    else:
        raise Fail(f"no check for {u}")
    return f, w


def check_integration(q):
    g, u, L, rep = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"]
    calc_options(q)
    calc_steps(q)
    ang = q["view"]["angle"]
    if u.startswith("inspection-") or u == "rewrite-trig-product":
        need(q["paper"] == 1, "a reverse chain rule question is Paper 1")
    if rep == "words":
        m = re.fullmatch(r"F′\(x\) = (.+)", L[0])
        need("using C for the constant" in q["asked"], "the question doesn't ask for the constant")
    else:
        m = re.fullmatch(r"∫ (.+) dx", L[0])
    need(m is not None, f"can't read the integrand {L[0]!r}")
    shown = in_expr(m.group(1))
    f, wr = in_wrongs(u, g)
    need(calc_same(shown, f), f"the integrand shown is not the one in the given: {shown} vs {f}")
    an = sp.integrate(sp.expand(f), CX) if f.is_polynomial(CX) else None
    for o in q["choices"]:
        t = o["text"]
        if "x⁰/0" in t:                                  # the power rule run on 1/x
            need(not o["correct"] and o["ref"] == IN_S + "1", f"{t!r} is not the misconception")
            continue
        e = in_expr(t)
        right = t.endswith(" + C") and not e.has(IN_U) and calc_same(sp.diff(e, CX), f)
        need(right == o["correct"], f"option {t!r} is {'wrong' if o['correct'] else 'also right'} by differentiating it")
        if o["correct"] and an is not None:
            d = sp.simplify(sp.expand(e) - an)
            need(d.is_constant(), f"{t!r} is not the integral {an}")
        if o["ref"] == IN_P + "1":
            need(not t.endswith(" + C") and calc_same(sp.diff(e, CX), f), f"{t!r} is not the right terms without + C")
        elif o["ref"]:
            need(o["ref"] in wr, f"the checker can't confirm {o['ref']} on {u}")
            need(any(calc_same(e.subs(IN_U, 1), w.subs(IN_U, 1)) if e.has(IN_U) else (not sp.sympify(w).has(IN_U) and calc_same(e, w)) for w in wr[o["ref"]]),
                 f"option {t!r} is not what {o['ref']} gives ({wr[o['ref']]})")
    ans = q["answer"]
    need(calc_same(in_template(ans, ans["values"]), in_expr(q["answer_text"])), "the slots don't make the expression shown")
    if u == "linear-square":
        need((")³" in q["answer_text"]) == (ang == "divide-by-a"), "the answer's shape is not the method's")
    if u == "rewrite-trig-product":
        need(("cos(2x)" in q["answer_text"]) == (ang == "identity-substitution"), "the answer's shape is not the method's")
    return None, None


# ── Definite integrals and areas (FAL-724) ───────────────────
# Reads the integrand, limits or story back from the question and works each answer out
# again with SymPy, or mpmath for a Paper 2 model, splitting at the roots it finds itself.
# A figure is held to its curve: the shaded strips must be the region the question asks for.

DI_E = "SL5.11.evaluate-definite#"
DI_N = "SL5.11.area-with-negative-regions#"
DI_K = "SL5.11.unknown-limit-or-parameter#"
DI_R = "SL5.11.composite-region-area#"
DI_S = "SL5.5.total-change-from-rate#"
DI_CONTEXTS = [("water", "in the tank", "litres", "minute", "minutes"), ("fuel", "in the tanker", "litres", "minute", "minutes"),
               ("charge", "in the bank", "kilowatt-hours", "hour", "hours"), ("grain", "in the silo", "kilograms", "minute", "minutes")]
DI_K_SYM = sp.Symbol("K")


def di_num(text):
    t = text.strip().replace("−", "-")
    if t == "π":
        return sp.pi
    if t == "π/2":
        return sp.pi / 2
    return sp.Rational(t)


def di_read(line):
    """(lo, hi, f) from '∫ from lo to hi of f dx'."""
    m = re.match(r"∫ from (.+?) to (.+?) of (.+?) d[xt]\b", line)
    need(m is not None, f"can't read the integral {line!r}")
    return m.group(1), m.group(2), in_expr(m.group(3))


def di_text(v, sf):
    return gc_s(v) if sf else dm_num(v)


def di_exact_value(text):
    """A value written with π, ln or e, as a number."""
    t = re.sub(r"^(Area|k|m) = ", "", text)
    t = re.sub(r"(?<=[\d)])π", "*pi", t).replace("π", "pi")
    t = re.sub(r"(?<![a-z])e(?![a-z^⁰¹²³⁴⁵⁶⁷⁸⁹(])", "e^(1)", t)      # e¹ is written e
    return in_expr(t)


def di_same(a, b):
    return abs(sp.N(a - b, 40)) < sp.Rational(1, 10 ** 25)


def di_symbolic(q, v, wr=None):
    """Options with π, ln or e: the option equal to v in value is the right one and no other is."""
    wr = wr or {}
    for o in q["choices"]:
        if o["text"].endswith(" + C"):
            need(not o["correct"], "an option with + C is right on a definite integral")
            continue
        e = di_exact_value(o["text"])
        need(di_same(e, v) == o["correct"], f"option {o['text']!r} is {'wrong' if o['correct'] else 'also right'}: the value is {v}")
        if o["ref"]:
            need(o["ref"] in wr and any(di_same(e, w) for w in wr[o["ref"]]), f"option {o['text']!r} is not what {o['ref']} gives")


def di_refs(q, wr):
    """A + C option is the right value with + C after it."""
    for o in q["choices"]:
        if o["ref"] == DI_E + "2":
            need(o["text"] == q["answer_text"] + " + C", f"{o['text']!r} is not the answer with + C")


def di_common(q, want, wrongs):
    gc_check_common(q, want, wrongs)


def di_shade(q, top, bottom, a, b, region=0):
    """Every shaded strip of a region sits between bottom and top, and it runs from a to b."""
    strips = q["graph"]["shade"][region]
    need(abs(strips[0][0] - float(a)) < 1e-6 and abs(strips[-1][0] - float(b)) < 1e-6, f"the shading runs {strips[0][0]} to {strips[-1][0]}, not {a} to {b}")
    ft, fb = sp.lambdify(CX, top, "math"), sp.lambdify(CX, bottom, "math")
    for x, lo, hi in strips:
        need(abs(hi - max(ft(x), fb(x))) < 1e-6 and abs(lo - min(ft(x), fb(x))) < 1e-6, f"the shading at x = {x} is not the region")


def di_figure(q, f):
    dm_graph_curve(q, f)


def di_area(f, a, b):
    """The size of the area between f and the axis on [a, b], split at the rational roots inside."""
    rs = sorted(r for r in sp.roots(sp.Poly(f, CX)) if r.is_real and a < r < b)
    ends = [a] + rs + [b]
    return sum(abs(sp.integrate(f, (CX, u, v))) for u, v in zip(ends, ends[1:]))


def check_definite_integral(q):
    g, u, L, rep, asked = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"], q["asked"]
    calc_options(q)
    calc_steps(q)
    ang = q["view"]["angle"]
    sf = q["paper"] == 2
    need(sf == ang.startswith("gdc-") or u == "area-gdc", "only a GDC method is Paper 2")
    if sf and u != "unknown-upper-limit":      # there the GDC finds a whole k
        need("3 s.f." in asked, "a Paper 2 answer doesn't ask for 3 s.f.")
    x = CX
    if u == "evaluate-polynomial":
        lo, hi, f = di_read(L[0])
        v = sp.integrate(f, (x, di_num(lo), di_num(hi)))
        di_common(q, di_text(v, sf), {DI_E + "0": {di_text(-v, sf)}})
    elif u == "evaluate-roots":
        lo, hi, f = di_read(L[0])
        a, b = di_num(lo), di_num(hi)
        need(sp.sqrt(a).is_integer and sp.sqrt(b).is_integer and a < b, "the limits are not perfect squares")
        v = sp.integrate(f, (x, a, b))
        di_common(q, dm_num(v), {DI_E + "0": {dm_num(-v)}})
    elif u == "evaluate-trig":
        lo, hi, f = di_read(L[0])
        a, b = di_num(lo), di_num(hi)
        need(a == 0 and b in (sp.pi, sp.pi / 2), "the limits are not 0 and π or π/2")
        v = sp.integrate(f, (x, a, b))
        F = sp.integrate(f, x)
        di_symbolic(q, v, {DI_E + "1": [F.subs(x, b)]})
    elif u == "evaluate-log":
        lo, hi, f = di_read(L[0])
        a, b = di_num(lo), di_num(hi)
        v = sp.integrate(f, (x, a, b))
        di_symbolic(q, v, {DI_E + "0": [-v]})
        di_refs(q, {})
    elif u == "evaluate-exp":
        lo, hi, f = di_read(L[0])
        a, b = di_num(lo), di_num(hi)
        v = sp.integrate(f, (x, a, b))
        di_symbolic(q, v, {DI_E + "0": [-v], DI_E + "1": [sp.integrate(f, x).subs(x, b)]})
    elif u == "evaluate-odd-even":
        lo, hi, f = di_read(L[0])
        need(di_num(lo) == -di_num(hi), "the limits are not −a and a")
        di_common(q, dm_num(sp.integrate(f, (x, di_num(lo), di_num(hi)))), {})
    elif u == "evaluate-linear":
        lo, hi, f = di_read(L[0])
        a, b = di_num(lo), di_num(hi)
        need(f.subs(x, a) > 0 and f.subs(x, b) > 0, "the line is not above the axis")
        v = sp.integrate(f, (x, a, b))
        di_common(q, dm_num(v), {DI_E + "0": {dm_num(-v)}, DI_E + "2": {dm_num(v) + " + C"}})
    elif u in ("area-above-axis", "area-below-axis"):
        f = in_expr(re.search(r"curve y = (.+?)\. ", L[0]).group(1))
        r, t = sorted(sp.roots(sp.Poly(f, x)))
        mid = f.subs(x, (r + t) / 2)
        need((mid > 0) == (u == "area-above-axis"), "the region is on the wrong side of the axis")
        v = sp.integrate(f, (x, r, t))
        if rep == "graph":
            di_figure(q, f)
            di_shade(q, f, sp.Integer(0), r, t)
        di_common(q, f"Area = {dm_num(abs(v))}", {DI_N + "1": {f"Area = {dm_num(v)}"}} if u == "area-below-axis" else {})
    elif u == "area-across-root":
        f = in_expr(re.search(r"curve y = (.+?)\. ", L[0]).group(1))
        r, t = sorted(sp.roots(sp.Poly(f, x)))
        hi = di_num(re.search(r"line x = (−?\d+)", L[0]).group(1))
        need(t < hi, "the root is not inside the interval")
        v = di_area(f, r, hi)
        h = (r + t) / 2
        net = abs(sp.integrate(f, (x, r, hi)))
        bad = abs(sp.integrate(f, (x, r, h))) + abs(sp.integrate(f, (x, h, hi)))
        if rep == "graph":
            di_figure(q, f)
            di_shade(q, f, sp.Integer(0), r, t, 0)
            di_shade(q, f, sp.Integer(0), t, hi, 1)
        di_common(q, "Area = " + di_text(v, sf), {DI_N + "0": {"Area = " + di_text(net, sf)}, DI_N + "2": {"Area = " + di_text(bad, sf)}})
    elif u == "area-gdc":
        m = re.search(r"curve y = (.+?), for (\d+) ≤ x ≤ (\d+)\.", L[0])
        f = in_expr(m.group(1))
        lo, hi = int(m.group(2)), int(m.group(3))
        zs = gc_zeros(sp.nsimplify(f, rational=True), lo + sp.Rational(1, 1000), hi - sp.Rational(1, 1000))
        need(len(zs) == 1, f"the curve has {len(zs)} roots inside")
        fn = sp.lambdify(x, f, "mpmath")
        p1, p2 = mpmath.quad(fn, [lo, zs[0]]), mpmath.quad(fn, [zs[0], hi])
        area, net = abs(p1) + abs(p2), abs(p1 + p2)
        need(not on_edge(sp.Float(str(area), 30)) and not on_edge(sp.Float(str(net), 30)), "a value sits on a rounding edge")
        di_figure(q, f)
        di_shade(q, f, sp.Integer(0), lo, zs[0], 0)
        di_shade(q, f, sp.Integer(0), zs[0], hi, 1)
        di_common(q, "Area = " + gc_s(sp.Float(str(area), 30)), {DI_N + "0": {"Area = " + gc_s(sp.Float(str(net), 30))}})
    elif u == "area-symmetry":
        f = in_expr(re.search(r"curve y = (.+?)(, for|\. )", L[0]).group(1))
        if f.has(sp.sin):
            a, b = sp.Integer(0), 2 * sp.pi
            v = 2 * abs(sp.integrate(f, (x, 0, sp.pi)))
            di_shade(q, f, sp.Integer(0), 0, sp.pi, 0)
            di_shade(q, f, sp.Integer(0), sp.pi, 2 * sp.pi, 1)
        else:
            rs = sorted(sp.roots(sp.Poly(f, x)))
            need(len(rs) == 3 and rs[0] == -rs[2] and rs[1] == 0, "the cubic is not odd about its middle root")
            v = di_area(f, rs[0], rs[2])
            di_shade(q, f, sp.Integer(0), rs[0], 0, 0)
            di_shade(q, f, sp.Integer(0), 0, rs[2], 1)
        di_figure(q, f)
        di_common(q, f"Area = {dm_num(v)}", {DI_N + "0": {"Area = 0"}})
    elif u == "unknown-upper-limit":
        lo, hi, f = di_read(L[0])
        need(hi == "k", "the upper limit is not k")
        m = re.search(r"dx = (−?[\d/]+), where k > (−?\d+)\.", L[0])
        N_, p = di_num(m.group(1)), di_num(m.group(2))
        F = sp.integrate(f, x)
        rs = sp.solve(F.subs(x, DI_K_SYM) - F.subs(x, p) - N_, DI_K_SYM)
        keep = [r for r in rs if r > p]
        need(len(keep) == 1 and keep[0].is_rational, f"k is {rs}")
        noL = [r for r in sp.solve(F.subs(x, DI_K_SYM) - N_, DI_K_SYM) if r.is_rational]
        di_common(q, f"k = {dm_num(keep[0])}", {DI_K + "0": {f"k = {dm_num(r)}" for r in rs if r != keep[0]}, DI_K + "1": {f"k = {dm_num(r)}" for r in noL}})
    elif u == "unknown-limit-log":
        lo, hi, f = di_read(L[0])
        need(lo == "0" and hi == "k", "the limits are not 0 and k")
        m = re.search(r"\(1/2\) ln\((.+?)\), where k > 0", L[0])
        M = di_num(m.group(1))
        a = sp.denom(sp.together(f)).subs(x, 0)
        y = sp.Symbol("y", positive=True)
        check_F = sp.integrate(f, x)
        sol = sp.solve((y ** 2 + a) / a - M, y)
        need(len(sol) == 1 and sol[0].is_integer, f"k is {sol}")
        need(di_same(check_F.subs(x, sol[0]) - check_F.subs(x, 0), sp.log(M) / 2), "the value shown is not the integral")
        bad = [r for r in sp.solve(y ** 2 + a - M, y) if r.is_integer]
        di_common(q, f"k = {sol[0]}", {DI_K + "1": {f"k = {r}" for r in bad}})
    elif u == "unknown-limit-trig":
        lo, hi, f = di_read(L[0])
        need(lo == "0" and hi == "m", "the limits are not 0 and m")
        V = di_num(re.search(r"dx = (.+?), where 0 < m", L[0]).group(1))
        n = sp.degree(f.subs(sp.sin(x), sp.Symbol("y")).subs(sp.cos(x), 1), sp.Symbol("y"))
        m_ = sp.asin((V * (n + 1)) ** sp.Rational(1, n + 1))
        d = sp.pi / m_
        need(sp.nsimplify(d).is_integer, f"m is {m_}")
        want = f"m = π/{sp.nsimplify(d)}"
        for o in q["choices"]:
            need(di_same(sp.integrate(f, (x, 0, sp.pi / di_num(o["text"].split("/")[1]))), V) == o["correct"], f"{o['text']} against the integral")
        di_common(q, want, {})
    elif u == "unknown-stretch":
        m = re.search(r"lines x = (\d+) and x = (\d+)\. Its area is (.+?)\.", L[0])
        lo, hi, A = int(m.group(1)), int(m.group(2)), di_num(m.group(3))
        k = A / sp.integrate(x ** 2, (x, lo, hi))
        if rep == "graph":
            di_figure(q, k * x ** 2)
            di_shade(q, k * x ** 2, sp.Integer(0), lo, hi)
        di_common(q, f"k = {dm_num(k)}", {DI_K + "1": {f"k = {dm_num(A / sp.integrate(x ** 2, (x, 0, hi)))}"}} if lo else {})
    elif u == "region-tangent":
        f = in_expr(re.search(r"curve y = (.+?) touches", L[0]).group(1))
        pts = {p["label"][0]: p for p in q["graph"]["points"]}
        px, py = sp.nsimplify(pts["P"]["x"]), sp.nsimplify(pts["P"]["y"])
        need(f.subs(x, px) == py, "P is not on the curve")
        r = [c for c in sp.roots(sp.Poly(f, x))]
        need(len(r) == 1, "the curve doesn't touch the axis")
        r = r[0]
        slope = sp.diff(f, x).subs(x, px)
        tan = py + slope * (x - px)
        qx = sp.solve(tan, x)[0]
        need(qx == sp.nsimplify(pts["Q"]["x"]) and r == sp.nsimplify(pts["R"]["x"]), "Q or R is not where it should be")
        whole = sp.integrate(f, (x, r, px))
        tri = (px - qx) * py / 2
        v = sp.integrate(f, (x, r, qx)) + sp.integrate(f - tan, (x, qx, px))
        need(v == whole - tri, "the two ways to the area disagree")
        strips = q["graph"]["shade"][0]
        ff, tf = sp.lambdify(x, f, "math"), sp.lambdify(x, tan, "math")
        for s_, lo_, hi_ in strips:
            need(abs(hi_ - ff(s_)) < 1e-6 and abs(lo_ - max(0.0, tf(s_))) < 1e-6, f"the shading at x = {s_} is not the region")
        wr = {DI_R + "0": {"Area = " + di_text(abs(whole - (px - r) * py / 2), sf)}, DI_R + "1": {"Area = " + di_text(whole + tri, sf)}, DI_R + "2": {"Area = " + di_text(whole, sf)}}
        di_common(q, "Area = " + di_text(v, sf), wr)
    elif u == "region-line-curve":
        m = re.search(r"The line y = (.+?) and the curve y = (.+?), for x > 0, meet at P\..*as far as x = (\d+)\.", L[0])
        ln, cv, b = in_expr(m.group(1)), in_expr(m.group(2)), int(m.group(3))
        ps = [r for r in sp.solve(ln - cv, x) if r > 0]
        need(len(ps) == 1, "the line and the curve don't meet once")
        p = ps[0]
        tri, rest = sp.integrate(ln, (x, 0, p)), sp.integrate(cv, (x, p, b))
        v = tri + rest
        need(ang.startswith("gdc") == sf, "paper")
        strips = q["graph"]["shade"][0]
        fl, fc = sp.lambdify(x, ln, "math"), sp.lambdify(x, cv, "math")
        for s_, lo_, hi_ in strips:
            need(abs(hi_ - (fl(s_) if s_ <= p else fc(s_))) < 1e-6 and lo_ == 0, f"the shading at x = {s_} is not the region")
        if sf:
            di_common(q, "Area = " + gc_s(sp.N(v, 40)), {DI_R + "1": {"Area = " + gc_s(sp.N(rest - tri, 40))}})
        else:
            di_symbolic(q, v, {DI_R + "1": [rest - tri]})
    elif u in ("total-from-rate", "amount-with-start", "interpret-integral"):
        what, where, y, per, time = DI_CONTEXTS[int(g["ctx"])]
        unit = f"{y} per {per}"
        words = rep == "words"
        src = L[0]
        m = re.search(r"r\(t\) = ([^=]+?)\.?$", src)
        need(m is not None, f"can't read the rate in {src!r}")
        f = in_expr(m.group(1))
        T = int(re.search(r"(?:first|from 0 to|at t =) (\d+)", asked if u != "interpret-integral" else L[1]).group(1))
        need(float(sp.minimum(f, x, sp.Interval(0, T))) > 0 if f.is_polynomial(x) else True, "the rate is not positive")
        if not f.is_polynomial(x):
            need(sf or u == "interpret-integral", "a model is Paper 2")
        total = sp.integrate(f, (x, 0, T))
        end = f.subs(x, T)
        if not total.is_rational:
            total, end = sp.N(total, 40), sp.N(end, 40)
        tx = (lambda v: gc_s(v)) if sf else dm_num
        if u == "total-from-rate":
            tail = f" {y}" if words else ""
            wr = {DI_S + "0": {f"{tx(end)} {unit}"} if words else {tx(end)}}
            if words:
                wr[DI_S + "2"] = {f"{tx(total)} {unit}"}
            di_common(q, tx(total) + tail, wr)
        elif u == "amount-with-start":
            need(not sf, "a start is a Paper 1 question")
            st = int(re.search(r"there are (\d+) ", L[1]).group(1))
            di_common(q, f"{dm_num(total + st)} {y}", {DI_S + "1": {f"{dm_num(total)} {y}"}})
        else:
            v = L[1].rsplit(" = ", 1)[1]
            need(v == tx(total), f"the integral shown, {v}, is not {tx(total)}")
            di_common(q, f"{v} {y} of {what} were added in the first {T} {time}.", {DI_S + "2": {f"At t = {T}, {what} was being added at {v} {unit}."}})
    elif u == "total-from-rate-graph":
        what, where, y, per, time = DI_CONTEXTS[int(g["ctx"])]
        c = q["graph"]["curves"][0]
        total = sum((sp.nsimplify(a[1]) + sp.nsimplify(b[1])) * (sp.nsimplify(b[0]) - sp.nsimplify(a[0])) / 2 for a, b in zip(c, c[1:]))
        need(sp.nsimplify(c[0][0]) == 0 and sp.nsimplify(c[-1][0]) == int(re.search(r"first (\d+)", asked).group(1)), "the graph doesn't cover the time asked")
        need(all(b[0] > a[0] and b[1] >= 0 for a, b in zip(c, c[1:])), "the rate graph is not a function above the axis")
        di_common(q, f"{dm_num(total)} {y}", {DI_S + "2": {f"{dm_num(total)} {y} per {per}"}})
    elif u == "time-to-reach":
        what, where, y, per, time = DI_CONTEXTS[int(g["ctx"])]
        f = in_expr(re.search(r"r\(t\) = (.+?)\. At", L[0]).group(1))
        N_ = di_num(re.search(r"when (.+?) " + y, asked).group(1))
        Y = sp.Symbol("Y", positive=True)
        sol = sp.solve(sp.integrate(f, (x, 0, Y)) - N_, Y)
        need(len(sol) == 1 and sol[0].is_integer, f"the time is {sol}")
        di_common(q, f"t = {sol[0]} {time}", {})
    else:
        raise Fail(f"no check for {u}")
    return None, None


# ── Kinematics (FAL-724) ─────────────────────────────────────
# Reads s(t) or v(t) back from the question, differentiates it, and finds rests, turning
# points and extremes again: exactly for a Paper 1 polynomial, with mpmath for a Paper 2 model.
# A motion graph is read from the corners drawn. Tagged wrong options are worked out again.

MT_V = "SL5.9.velocity-acceleration#"
MT_D = "SL5.9.rest-and-direction#"
MT_X = "SL5.9.max-speed#"
MT_G = "SL5.9.motion-graphs#"


def mt_times(fn, T, exact):
    """The times in (0, T) where fn is 0, in order."""
    if exact:
        return sorted(r for r in sp.roots(sp.Poly(fn, CX)) if r.is_real and 0 < r < T)
    return gc_zeros(sp.nsimplify(fn, rational=True), sp.Rational(1, 100), T - sp.Rational(1, 100))


def mt_at(fn, t):
    return sp.N(fn.subs(CX, t), 40) if not fn.is_polynomial(CX) or not sp.sympify(t).is_rational else fn.subs(CX, t)


def mt_read(q):
    m = re.search(r"\b([vs])\(t\) = (.+?), for 0 ≤ t ≤ (\d+)\.", q["lines"][0])
    need(m is not None, f"can't read the motion in {q['lines'][0]!r}")
    return m.group(1), in_expr(m.group(2)), int(m.group(3))


def mt_extremes(v, a, T, exact):
    """[(t, v)] at the ends and the turning points of v."""
    ts = [sp.Integer(0), sp.Integer(T)] + list(mt_times(a, T, exact))
    return [(t, mt_at(v, t)) for t in ts]


def mt_graph_corners(q):
    c = q["graph"]["curves"][0]
    return [(sp.nsimplify(p[0]), sp.nsimplify(p[1])) for p in c]


def check_motion(q):
    g, u, L, rep, asked = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"], q["asked"]
    calc_options(q)
    calc_steps(q)
    ang = q["view"]["angle"]
    sf = q["paper"] == 2
    if ang.startswith("gdc-"):
        need(sf, "a GDC method is Paper 2")
    tx = (lambda v: gc_s(sp.Float(v, 40) if not isinstance(v, sp.Rational) else v)) if sf else dm_num
    x = CX
    tail = lambda head, v, unit: f"{head}{tx(v)}{unit}"
    if u in ("speed-from-graph", "acceleration-from-graph", "velocity-from-graph", "displacement-from-graph", "direction-from-graph"):
        cs = mt_graph_corners(q)
        need(all(b[0] > a[0] for a, b in zip(cs, cs[1:])), "the graph goes back in time")
        if u == "speed-from-graph":
            ys = [c[1] for c in cs]
            top, spd = max(ys), max(abs(y) for y in ys)
            need(top > 0 and min(ys) < 0, "the graph doesn't go both ways")
            mk = lambda a, b: f"Maximum velocity {dm_num(a)} m/s, maximum speed {dm_num(b)} m/s"
            gc_check_common(q, mk(top, spd), {MT_X + "0": {mk(top, top), mk(top, -min(ys))}})
        elif u in ("acceleration-from-graph", "velocity-from-graph"):
            t = R(re.search(r"when t = (.+?)\.$", asked).group(1))
            for a, b in zip(cs, cs[1:]):
                if a[0] < t < b[0]:
                    grad = (b[1] - a[1]) / (b[0] - a[0])
            head, unit = ("a = ", " m/s²") if u == "acceleration-from-graph" else ("v = ", " m/s")
            gc_check_common(q, f"{head}{dm_num(grad)}{unit}", {})
        elif u == "displacement-from-graph":
            bits = [(a[1] + b[1]) * (b[0] - a[0]) / 2 for a, b in zip(cs, cs[1:])]
            gc_check_common(q, f"{dm_num(sum(bits))} m", {MT_G + "0": {f"{dm_num(max(c[1] for c in cs))} m"}, MT_G + "2": {f"{dm_num(sum(abs(b) for b in bits))} m"}})
        else:
            below = [(a[0], b[0]) for a, b in zip(cs, cs[1:]) if a[1] + b[1] < 0]
            falls = [(a[0], b[0]) for a, b in zip(cs, cs[1:]) if b[1] < a[1]]
            gc_check_common(q, f"{dm_num(below[0][0])} < t < {dm_num(below[-1][1])}", {MT_G + "1": {f"{dm_num(falls[0][0])} < t < {dm_num(falls[-1][1])}"}})
        return None, None
    if u == "returns-to-start":
        m = re.search(r"s\(t\) = (.+?), for 0 ≤ t ≤ (\d+)\.", L[0])
        f = in_expr(m.group(1))
        rs = sorted(r for r in sp.roots(sp.Poly(f, x)) if r > 0)
        gc_check_common(q, f"t = {rs[-1]} s", {})
        return None, None
    name, f, T = mt_read(q)
    s_ = f if name == "s" else None
    v = sp.diff(f, x) if name == "s" else f
    a = sp.diff(v, x)
    exact = v.is_polynomial(x) and not sf
    need(exact != sf, f"Paper {q['paper']} has the wrong kind of function")
    Z = mt_times(v, T, exact)
    A = mt_times(a, T, exact)
    if rep == "words":
        need("cart" in L[0], "the story is not in words")
    if u in ("velocity-expression", "acceleration-expression"):
        want = a if u == "acceleration-expression" else v
        for o in q["choices"]:
            need(calc_same(in_expr(o["text"].split(" = ", 1)[1]), want) == o["correct"], f"option {o['text']!r} against {want}")
        return None, None
    if u == "velocity-at-time":
        t0 = int(re.search(r"t = (\d+)", asked).group(1))
        V, P = mt_at(v, t0), mt_at(s_, t0)
        gc_check_common(q, tail("v = ", V, " m/s"), {MT_V + "0": {tail("v = ", P, " m/s")}, MT_V + "1": {tail("v = ", P / t0, " m/s")}})
    elif u == "acceleration-at-time":
        t0 = int(re.search(r"t = (\d+)", asked).group(1))
        V, A0 = mt_at(v, t0), mt_at(a, t0)
        gc_check_common(q, tail("a = ", A0, " m/s²"), {MT_V + "0": {tail("a = ", V, " m/s²")}, MT_V + "2": {tail("a = ", (V - mt_at(v, 0)) / t0, " m/s²")}})
    elif u == "time-from-acceleration":
        c = R(re.search(r"acceleration is (−?[\d.]+) m/s²", asked).group(1).replace("−", "-"))
        rs = mt_times(a - c, T, exact)
        need(len(rs) == 1, f"the acceleration is {c} at {len(rs)} times")
        gc_check_common(q, tail("t = ", rs[0], " s"), {})
    elif u == "time-from-velocity":
        need(sf, "time from velocity is Paper 2")
        c = R(re.search(r"velocity is (−?[\d.]+) m/s", asked).group(1).replace("−", "-"))
        rs = mt_times(v - c, T, False)
        gc_check_common(q, tail("t = ", rs[0], " s"), {})
    elif u == "first-at-rest":
        gc_check_common(q, tail("t = ", Z[0], " s"), {MT_D + "0": {tail("t = ", t, " s") for t in A}})
    elif u == "change-direction":
        if exact:
            mult = sp.roots(sp.Poly(v, x))
            cross = [r for r in Z if mult[r] % 2 == 1]
            touch = [r for r in Z if mult[r] % 2 == 0]
            need(len(cross) == 1 and len(touch) == 1, f"crossings {cross}, touches {touch}")
            w = {MT_D + "2": {tail("t = ", touch[0], " s")}, MT_D + "0": {tail("t = ", t, " s") for t in A}}
            gc_check_common(q, tail("t = ", cross[0], " s"), w)
        else:
            gc_check_common(q, tail("t = ", Z[0], " s"), {MT_D + "0": {tail("t = ", t, " s") for t in A}})
        if rep == "graph":
            dm_graph_curve(q, v)
    elif u == "moving-one-way":
        lo, hi = Z[0], Z[1]
        mid = mt_at(v, (lo + hi) / 2)
        word = "positive" if mid > 0 else "negative"
        need(f"the {word} direction" in asked, "the direction asked is not the sign of v")
        gc_check_common(q, f"{tx(lo)} < t < {tx(hi)}", {})
        if rep == "graph":
            dm_graph_curve(q, v)
    elif u == "acceleration-at-rest":
        gc_check_common(q, tail("a = ", mt_at(a, Z[0]), " m/s²"), {})
    elif u == "speeding-up":
        t0 = int(re.search(r"t = (\d+)\?", asked).group(1))
        V, A0 = mt_at(v, t0), mt_at(a, t0)
        need(L[1] == f"When t = {t0}, v = {tx(V)} and a = {tx(A0)}.", f"the values shown in {L[1]!r}")
        same = (V > 0) == (A0 > 0)
        only = "Speeding up: a is positive." if A0 > 0 else "Slowing down: a is negative."
        gc_check_common(q, "Speeding up: v and a have the same sign." if same else "Slowing down: v and a have opposite signs.", {MT_D + "1": {only}})
    elif u == "max-velocity-quadratic":
        need(sp.Poly(v, x).LC() < 0, "v doesn't open down")
        ex = mt_extremes(v, a, T, exact)
        gc_check_common(q, tail("v = ", max(y for _, y in ex), " m/s"), {MT_X + "2": {"v = 0 m/s"}})
    elif u == "max-velocity":
        ex = mt_extremes(v, a, T, exact)
        top = max(ex, key=lambda p: p[1])
        need(0 < top[0] < T, "the maximum is at an end")
        gc_check_common(q, tail("v = ", top[1], " m/s"), {})
    elif u == "max-speed":
        ex = mt_extremes(v, a, T, exact)
        spd = max(abs(y) for _, y in ex)
        inner = [abs(y) for t, y in ex if 0 < t < T]
        gc_check_common(q, tail("Speed = ", spd, " m/s"), {MT_X + "0": {tail("Speed = ", max(y for _, y in ex), " m/s")}, MT_X + "1": {tail("Speed = ", max(inner), " m/s")}})
        if rep == "graph":
            dm_graph_curve(q, v)
    elif u == "acceleration-at-max-speed":
        ex = mt_extremes(v, a, T, exact)
        ts = max(ex, key=lambda p: abs(p[1]))[0]
        gc_check_common(q, tail("a = ", mt_at(a, ts), " m/s²"), {})
    elif u == "max-acceleration":
        ex = mt_extremes(a, sp.diff(a, x), T, exact)
        gc_check_common(q, tail("a = ", max(y for _, y in ex), " m/s²"), {})
    else:
        raise Fail(f"no check for {u}")
    return None, None


# ── regression-x-on-y (t4-regression-x-on-y, FAL-725) ────────
# The `regression-x-on-y` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/regression_pair.gd. The data and the lines are read back from what the
# student sees, and every line and estimate is found again with exact rationals.

RP_SKILL = "SL4.10."
RP_YBAR = "ȳ"
RP_P2_ONLY = ("x-on-y-line", "d-from-mean-point", "predict-x-from-data", "predict-x-from-lines", "judge-estimate")
RP_NUM = r"−?\d+(?:\.\d+)?"
RP_LINE = rf"({RP_NUM})([xy]) ([+−]) (\d+(?:\.\d+)?)"


def rp_read(line, left):
    """m and k from "<left> = mv + k", in the sentence or bare."""
    mt = re.search(rf"{left} = {RP_LINE}", line)
    need(mt is not None, f"can't read a line for {left} in {line!r}")
    need(mt.group(2) == ("x" if left == "y" else "y"), f"the line in {line!r} is in the wrong letter")
    m, k = R(mt.group(1).replace("−", "-")), R(mt.group(4))
    return m, k if mt.group(3) == "+" else -k


def rp_table(q):
    """The table back: the regression sums, the line y = ax + b and the line x = cy + d."""
    g, L = q["given"], q["lines"]
    need(q["table"] is not None, "a table")
    mt = re.fullmatch(r"The table shows the (.+) \(x\) and the (.+) \(y\) for (\d+) (.+)\.", L[0])
    need(mt is not None, f"can't read {L[0]!r}")
    ctx = next((c for c in RG_CONTEXTS if c[:2] == (mt.group(1), mt.group(2)) and c[2] == mt.group(4)), None)
    need(ctx is not None, f"no story matches {L[0]!r}")
    rows = q["table"]["rows"]
    need(rows[0][0] == "x" and rows[1][0] == "y", "table heads")
    xs, ys = [int(v) for v in rows[0][1]], [int(v) for v in rows[1][1]]
    n = len(xs)
    need(n == len(ys) == int(mt.group(3)) and 6 <= n <= 9, f"n = {n}")
    sx, sy = sum(xs), sum(ys)
    mx, my = sp.Rational(sx, n), sp.Rational(sy, n)
    sxx = sp.Rational(n * sum(x * x for x in xs) - sx * sx, n)
    sxy = sp.Rational(n * sum(x * y for x, y in zip(xs, ys)) - sx * sy, n)
    syy = sp.Rational(n * sum(y * y for y in ys) - sy * sy, n)
    a, c = sxy / sxx, sxy / syy
    r = sxy / sp.sqrt(sxx * syy)
    need(sp.Rational(8, 10) <= abs(r) <= sp.Rational(99, 100), f"|r| = {float(abs(r)):.4f} is outside 0.8 to 0.99")
    need((r > 0) == (ctx[3] > 0), "the sign of r does not match the story")
    return xs, ys, a, my - a * mx, c, mx - c * my


def check_regression_pair(q):
    g, u, L, rep = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"]
    asked, paper = q["asked"], q["paper"]
    need(paper == 2 if u in RP_P2_ONLY else paper in (1, 2), f"paper {paper} for {u}")
    for tx in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", tx), f"a hyphen for a minus in {tx!r}")
    wrongs, want, trap = {}, None, None
    if u == "x-on-y-line":
        xs, ys, a, b, c, d = rp_table(q)
        need(asked == "Find the equation of the regression line of x on y, in the form x = cy + d, with c and d to 3 s.f.", f"asked {asked!r}")
        ra, rb = 1 / a, -b / a
        need(all(rg_clear(v) for v in (a, b, c, d, ra, rb)), "a value is on a rounding edge")
        need(sig3(c) != sig3(ra) and sig3(d) != sig3(rb) and sig3(c) != sig3(a) and sig3(d) != sig3(b), "the wrong lines read the same as the right one")
        want = f"c = {rg_s(c)}, d = {rg_s(d)}"
        wrongs[RP_SKILL + "x-on-y-line#0"] = {f"c = {rg_s(ra)}, d = {rg_s(rb)}"}
        wrongs[RP_SKILL + "x-on-y-line#1"] = {f"c = {rg_s(a)}, d = {rg_s(b)}"}
    elif u == "predict-x-from-data":
        xs, ys, a, b, c, d = rp_table(q)
        mt = re.fullmatch(r"Use the appropriate regression line to estimate x when y = (\d+)\. Give your answer to 3 s\.f\.", asked)
        need(mt is not None, f"asked {asked!r}")
        y0 = int(mt.group(1))
        need(min(ys) < y0 < max(ys) and y0 not in ys, f"y = {y0} is not strictly inside the data and off the table")
        x0, xr = c * y0 + d, (y0 - b) / a
        need(x0 > 0 and xr > 0 and rg_clear(x0) and rg_clear(xr) and sig3(x0) != sig3(xr), "an estimate is not positive, on an edge, or the slip reads the same")
        want, trap = rg_num(x0, "x = ")
        wrongs[RP_SKILL + "predict-x#0"] = {"x = " + rg_s(xr)}
    elif u == "d-from-mean-point":
        mt = re.fullmatch(rf"The mean point of a set of data is \(({RP_NUM}), ({RP_NUM})\)\.", L[0])
        ml = re.fullmatch(rf"The regression line of x on y is x = ({RP_NUM})y \+ d\.", L[1])
        need(mt is not None and ml is not None and asked == "The line passes through the mean point. Find d.", f"can't read {L}")
        mx, my, c = R(mt.group(1)), R(mt.group(2).replace("−", "-")), R(ml.group(1).replace("−", "-"))
        d = mx - c * my
        need(1 <= abs(d) <= 900 and rg_clear(d), f"d = {d}")
        want, trap = rg_num(d, "d = ")
        need(sp.Rational(sig3(d)) != d, "d needs no rounding")
        wrongs[RP_SKILL + "mean-point-intersection#1"] = {"d = " + rg_s(my - c * mx)}
    elif u == "choose-line":
        a, b = rp_read(L[-2], "y")
        c, d = rp_read(L[-1], "x")
        need(0 < a * c < 1, "the two lines are not a regression pair")
        est = None
        if rep == "equation":
            mt = re.fullmatch(r"Which line should be used to estimate ([xy]) when ([xy]) = (\d+)\?", asked)
            need(mt is not None and mt.group(1) != mt.group(2), f"asked {asked!r}")
            est = mt.group(1)
        else:
            mt = re.fullmatch(r"The data are the (.+) \(x\) and the (.+) \(y\) for some (.+)\.", L[0])
            ma = re.fullmatch(r"Which line should be used to estimate the (.+) when the (.+) is (\d+)\?", asked)
            need(mt is not None and ma is not None, f"can't read {L[0]!r} and {asked!r}")
            need({ma.group(1), ma.group(2)} == {mt.group(1), mt.group(2)}, "the question is not about the story's two variables")
            est = "x" if ma.group(1) == mt.group(1) else "y"
        want = "The line of x on y, since x is being estimated" if est == "x" else "The line of y on x, since y is being estimated"
        wrongs[RP_SKILL + "choose-line#0"] = {"The line of y on x, rearranged to make x the subject" if est == "x" else "The line of x on y, rearranged to make y the subject"}
        wrongs[RP_SKILL + "choose-line#1"] = {"The line of y on x, since x is on the horizontal axis" if est == "x" else "The line of x on y, since y is on the vertical axis"}
        gc_check_common(q, want, wrongs)
        for sol in q["solutions"]:
            need(want in sol["steps"][-1], "the working doesn't end at the right line")
        return None, None
    elif u == "predict-x-from-lines":
        a, b = rp_read(L[0], "y")
        c, d = rp_read(L[1], "x")
        need(0 < a * c < 1, "the two lines are not a regression pair")
        mt = re.fullmatch(r"Estimate x when y = (\d+)\. Give your answer to 3 s\.f\.", asked)
        need(mt is not None, f"asked {asked!r}")
        y0 = int(mt.group(1))
        x0, xr = c * y0 + d, (y0 - b) / a
        need(x0 > 0 and xr > 0 and rg_clear(x0) and rg_clear(xr) and sig3(x0) != sig3(xr), "the estimate is not clean")
        want, trap = rg_num(x0, "x = ")
        wrongs[RP_SKILL + "predict-x#0"] = {"x = " + rg_s(xr)}
    elif u == "judge-estimate":
        mr = re.search(rf"have r = ({RP_NUM})\.", L[0])
        my = re.fullmatch(r"The values of y in the data run from (\d+) to (\d+)\.", L[1])
        ma = re.fullmatch(r"The line of x on y is used to estimate x when y = (\d+)\. How reliable is this estimate\?", asked)
        need(mr is not None and my is not None and ma is not None, f"can't read {L} / {asked!r}")
        r, lo, hi, y0 = R(mr.group(1).replace("−", "-")), int(my.group(1)), int(my.group(2)), int(ma.group(1))
        strong, inside = abs(r) >= sp.Rational(9, 10), lo <= y0 <= hi
        need(strong or abs(r) <= sp.Rational(45, 100), f"r = {r} is neither strong nor weak")
        need(strong or inside, "both weak and outside: two reasons at once")
        want = ("Reliable: y is inside the data and the correlation is strong" if inside else "Not reliable: y is outside the range of the data") if strong else "Not reliable: the correlation is weak"
        wrongs[RP_SKILL + "predict-x#1"] = {"Reliable: r is strong, so the line can be used for any y"}
        gc_check_common(q, want, wrongs)
        need(want in q["solutions"][0]["steps"][-1], "the working doesn't end at the verdict")
        return None, None
    elif u == "mean-point-from-lines":
        a, b = rp_read(L[0], "y")
        c, d = rp_read(L[1], "x")
        need(0 < a * c < 1, "the two lines are not a regression pair")
        x, y = sp.symbols("x y")
        sol = sp.solve([y - a * x - b, x - c * y - d], [x, y])
        mx, my = sol[x], sol[y]
        need(mx.q == 1 and my.q == 1 and mx > 0 and my > 0, f"the mean point ({mx}, {my}) is not a positive whole point")
        need(asked == f"Find the mean point (x̄, {RP_YBAR}).", f"asked {asked!r}")
        want = f"({mx}, {my})"
        if rep == "graph":
            pts = q["graph"]["points"]
            need(len(pts) == 1 and R(str(pts[0]["x"])) == mx and R(str(pts[0]["y"])) == my, "the point marked is not where the lines cross")
            for curve, f in zip(q["graph"]["curves"], (lambda t: a * t + b, lambda t: (t - d) / c)):
                for px, py in curve[:: max(1, len(curve) // 5)]:
                    need(abs(float(f(sp.Rational(str(px)))) - py) < 1e-6, "a curve drawn is not its line")
    elif u == "mean-from-one-mean":
        which = "y" if "of y on x" in L[0] else "x"
        m, k = rp_read(L[0], which)
        mk = re.fullmatch(rf"(x̄|{RP_YBAR}) = ({RP_NUM})", L[1])
        need(mk is not None, f"can't read {L[1]!r}")
        known = "x" if mk.group(1) == "x̄" else "y"
        v = R(mk.group(2))
        need(asked == f"Find {RP_YBAR if known == 'x' else 'x̄'}.", f"asked {asked!r}")
        # The line: subject = m × other + k. The known mean is the subject's or the other's.
        val = m * v + k if known != which else (v - k) / m
        slip = (v - k) / m if known != which else m * v + k
        need(val == sp.Rational(int(val)) and val > 0, f"the other mean is {val}")
        lab = (RP_YBAR if known == "x" else "x̄") + " = "
        want = lab + dec_text(val)
        wrongs[RP_SKILL + "mean-point-intersection#1"] = {lab + dec_text(slip)}
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wrongs, trap)
    for sol in q["solutions"]:
        need(want in sol["steps"][-1], f"{sol['name']}: the last step {sol['steps'][-1]!r} doesn't state {want!r}")
    return None, None


# ── normal-unknown (t4-normal-unknown-parameter, FAL-725) ────
# The `normal-unknown` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/normal_unknown.gd. The facts are read back from what the student sees;
# z comes from mpmath's erfinv, and each parameter is then checked by putting it back into erf.

NU_SKILL = "SL4.12."
NU_NUM = r"−?\d+(?:\.\d+)?"
NU_CONTEXTS = [("The masses of the grain sacks at a depot", " kg"), ("The lengths of the copper pipes in a yard", " cm"),
               ("The times couriers take to cross the flats", " minutes"), ("The volumes of water in the filled cans", " ml"),
               ("The heights of the fence posts at a camp", " cm"), ("The lifetimes of the lamp batteries", " hours"),
               ("The distances the patrols cover in a day", " km"), ("The masses of the salvaged engine parts", " kg")]


def nu_phi(z):
    with mpmath.workdps(40):
        return mpmath.mpf("0.5") * mpmath.erfc(-mpmath.mpf(z) / mpmath.sqrt(2))


def nu_inv(p):
    with mpmath.workdps(40):
        return mpmath.sqrt(2) * mpmath.erfinv(2 * mpmath.mpf(sp.Rational(p).p) / sp.Rational(p).q - 1)


def nu_f(x):
    return sp.Float(mpmath.nstr(mpmath.mpf(x), 35), 35)


def nu_clear(x):
    return x != 0 and rg_clear(nu_f(x))


def nu_val(t):
    return R(t.replace("−", "-"))


def nu_text(label, x):
    return label + rg_s(nu_f(x))


def nu_model(q):
    """(mu, sigma) from the first line: a Rational, or None where it is hidden."""
    line = q["lines"][0]
    if q["view"]["rep"] != "words":
        mt = re.fullmatch(rf"X ~ N\((μ|{NU_NUM}), (σ|{NU_NUM})²\)", line)
        need(mt is not None, f"can't read {line!r}")
        return None if mt.group(1) == "μ" else nu_val(mt.group(1)), None if mt.group(2) == "σ" else nu_val(mt.group(2))
    what, unit = NU_CONTEXTS[int(q["given"]["ctx"])]
    mu = re.search(rf"with mean ({NU_NUM}){unit}", line)
    sg = re.search(rf"standard deviation ({NU_NUM}){unit}", line)
    need(line.startswith(what + " are normally distributed"), f"the story {line!r} is not the one given")
    return nu_val(mu.group(1)) if mu else None, nu_val(sg.group(1)) if sg else None


def nu_tail(q, i):
    """x, the side and the area from line i: ("lt" or "gt")."""
    line = q["lines"][i]
    if q["view"]["rep"] != "words":
        mt = re.fullmatch(rf"P\(X ([<>]) ({NU_NUM})\) = ({NU_NUM})", line)
        need(mt is not None, f"can't read {line!r}")
        return nu_val(mt.group(2)), "lt" if mt.group(1) == "<" else "gt", nu_val(mt.group(3))
    unit = NU_CONTEXTS[int(q["given"]["ctx"])][1]
    mt = re.fullmatch(rf"({NU_NUM})% of them are (below|above) ({NU_NUM}){unit}\.", line)
    need(mt is not None, f"can't read {line!r}")
    return nu_val(mt.group(3)), "lt" if mt.group(2) == "below" else "gt", nu_val(mt.group(1)) / 100


def nu_shaded(q, want):
    """The curve drawn: each shaded area adds up to `want`, under the mean and σ it is drawn with."""
    g = q["graph"]
    need(g is not None and g["kind"] == "normal", "no normal curve")
    mu, sg = mpmath.mpf(g["mu"]), mpmath.mpf(g["sigma"])
    total = 0
    for a, b in g["shade"]:
        hi = nu_phi((mpmath.mpf(b) - mu) / sg) if b is not None else 1
        lo = nu_phi((mpmath.mpf(a) - mu) / sg) if a is not None else 0
        total += hi - lo
    need(abs(total - want) < mpmath.mpf("1e-5"), f"the shaded area is {total}, not {want}")


def check_normal_unknown(q):
    with mpmath.workdps(40):
        return nu_check(q)


def nu_check(q):
    g, u, L, rep = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"]
    asked = q["asked"]
    need(q["paper"] == 2, "these are Paper 2")
    for tx in [asked] + L + [st for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z^])-\d", tx), f"a hyphen for a minus in {tx!r}")
    wrongs, want, trap = {}, None, None
    sq = "standard deviation" if rep == "words" else "σ"

    def sd_answer(x):
        need(x > 0 and nu_clear(x), f"σ = {x} is not positive, or on a rounding edge")
        return nu_text("σ = ", x), bn_trap("σ = ", nu_f(x))

    if u == "z-from-area":
        need(L[0] == "Z ~ N(0, 1)" and asked == "Find k.", f"{L[0]!r} {asked!r}")
        mt = re.fullmatch(rf"P\(Z ([<>]) k\) = ({NU_NUM})", L[1])
        need(mt is not None, f"can't read {L[1]!r}")
        p = nu_val(mt.group(2))
        left = p if mt.group(1) == "<" else 1 - p
        z = nu_inv(left)
        need(abs(z) >= mpmath.mpf("0.1") and nu_clear(z), f"z = {z}")
        want, trap = nu_text("k = ", z), bn_trap("k = ", nu_f(z))
        if mt.group(1) == ">":
            wrongs[NU_SKILL + "unknown-mean-or-sd#1"] = {nu_text("k = ", -z)}
        if rep == "diagram":
            nu_shaded(q, mpmath.mpf(p.p) / p.q)
    elif u == "standardise-event":
        mu, sg = nu_model(q)
        mt = re.search(rf"P\(X ([<>]) ({NU_NUM})\)", asked)
        need(mt is not None and mu is not None and sg is not None, f"can't read {asked!r}")
        r, x = mt.group(1), nu_val(mt.group(2))
        z = (x - mu) / sg
        zv = (x - mu) / sg**2
        need((z * 100).q == 1, f"z = {z} doesn't end within two places")
        want = f"P(Z {r} {dec_text(z)})"
        other = ">" if r == "<" else "<"
        wrongs[NU_SKILL + "standardise#0"] = {f"P(Z {other} {dec_text(z)})"}
        wrongs[NU_SKILL + "standardise#1"] = {f"P(Z {r} {dec_text(zv)})"}
        if rep == "diagram":
            a = nu_phi(mpmath.mpf(z.p) / z.q)
            nu_shaded(q, a if r == "<" else 1 - a)
    elif u == "within-k-sd":
        mt = re.search(r"(\d\.\d)σ < X < μ \+ (\d\.\d)σ", asked) if rep != "words" else re.search(r"within (\d\.\d) standard deviations", asked)
        need(mt is not None, f"can't read {asked!r}")
        k = R(mt.group(1))
        need(sp.Rational(6, 5) <= k <= sp.Rational(14, 5) and k != 2, f"k = {k}")
        x = nu_phi(k.p / mpmath.mpf(k.q)) - nu_phi(-k.p / mpmath.mpf(k.q))
        need(nu_clear(x), "on a rounding edge")
        want, trap = nu_text("probability = ", x), bn_trap("probability = ", nu_f(x))
    elif u in ("unknown-sd", "unknown-mean"):
        mu, sg = nu_model(q)
        x, side, p = nu_tail(q, 1)
        left = p if side == "lt" else 1 - p
        z = nu_inv(left)
        need(sp.Rational(2, 100) <= p <= sp.Rational(48, 100) and (p * 100).q == 1, f"the tail {p}")
        xf = mpmath.mpf(x.p) / x.q
        if u == "unknown-sd":
            need(mu is not None and sg is None and asked == f"Find {'the ' if rep == 'words' else ''}{sq}.", f"asked {asked!r}")
            s_ = (xf - mpmath.mpf(mu.p) / mu.q) / z
            need(abs(nu_phi((xf - mpmath.mpf(mu.p) / mu.q) / s_) - left) < mpmath.mpf("1e-25"), "σ does not give the area")
            need(1 <= s_ <= mpmath.mpf(mu.p) / mu.q / 4, f"σ = {s_} is outside the limits")
            want, trap = sd_answer(s_)
            wrongs[NU_SKILL + "unknown-mean-or-sd#2"] = {nu_text("σ = ", -s_)}
            if rep == "diagram":
                nu_shaded(q, mpmath.mpf(p.p) / p.q)
        else:
            need(mu is None and sg is not None and asked == f"Find {'the mean' if rep == 'words' else 'μ'}.", f"asked {asked!r}")
            sf_ = mpmath.mpf(sg.p) / sg.q
            m = xf - z * sf_
            need(abs(nu_phi((xf - m) / sf_) - left) < mpmath.mpf("1e-25"), "μ does not give the area")
            need(m >= 4 * sf_ and nu_clear(m) and nu_clear(xf + z * sf_), f"μ = {m}")
            want, trap = nu_text("μ = ", m), bn_trap("μ = ", nu_f(m))
            wrongs[NU_SKILL + "unknown-mean-or-sd#1"] = {nu_text("μ = ", xf + z * sf_)}
            if rep == "diagram":
                nu_shaded(q, mpmath.mpf(p.p) / p.q)
    elif u == "sd-from-iqr":
        mu, sg = nu_model(q)
        mt = re.search(rf"interquartile range (?:of X )?is ({NU_NUM})", L[1])
        need(mt is not None and mu is not None and sg is None, f"can't read {L[1]!r}")
        iqr = nu_val(mt.group(1))
        s_ = (mpmath.mpf(iqr.p) / iqr.q) / (2 * nu_inv(sp.Rational(3, 4)))
        need(abs(nu_phi(mpmath.mpf(iqr.p) / iqr.q / 2 / s_) - mpmath.mpf("0.75")) < mpmath.mpf("1e-25"), "σ does not put 75% below Q₃")
        want, trap = sd_answer(s_)
    elif u == "sd-from-central-area":
        mu, sg = nu_model(q)
        need(mu is not None and sg is None, "μ is given")
        if rep == "words":
            unit = NU_CONTEXTS[int(g["ctx"])][1]
            mt = re.fullmatch(rf"({NU_NUM})% of them are between ({NU_NUM}){unit} and ({NU_NUM}){unit}\.", L[1])
            need(mt is not None, f"can't read {L[1]!r}")
            c, lo, hi = nu_val(mt.group(1)) / 100, nu_val(mt.group(2)), nu_val(mt.group(3))
        else:
            mt = re.fullmatch(rf"P\(({NU_NUM}) < X < ({NU_NUM})\) = ({NU_NUM})", L[1])
            need(mt is not None, f"can't read {L[1]!r}")
            lo, hi, c = nu_val(mt.group(1)), nu_val(mt.group(2)), nu_val(mt.group(3))
        need(mu - lo == hi - mu > 0, "the interval is not centred on the mean")
        z = nu_inv((1 + c) / 2)
        s_ = (mpmath.mpf((hi - mu).p) / (hi - mu).q) / z
        want, trap = sd_answer(s_)
        if rep == "diagram":
            nu_shaded(q, mpmath.mpf(c.p) / c.q)
    elif u == "mean-and-sd":
        x1, s1, p1 = nu_tail(q, 1)
        x2, s2, p2 = nu_tail(q, 2)
        need(s1 == "lt" and x1 < x2, "the first fact is the lower tail")
        a1, a2 = p1, (p2 if s2 == "lt" else 1 - p2)
        need(a1 < a2, "the areas are out of order")
        m, s_ = sp.symbols("m s")
        z1, z2 = nu_inv(a1), nu_inv(a2)
        xa, xb = mpmath.mpf(x1.p) / x1.q, mpmath.mpf(x2.p) / x2.q

        def solve2(u1, u2):
            ss = (xb - xa) / (u2 - u1)
            return xa - u1 * ss, ss

        mu, sg = solve2(z1, z2)
        need(sg > 0 and nu_clear(mu) and nu_clear(sg) and sg <= mu / 3, f"μ = {mu}, σ = {sg}")
        need(abs(nu_phi((xa - mu) / sg) - mpmath.mpf(a1.p) / a1.q) < mpmath.mpf("1e-25"), "μ and σ don't give the first area")
        need(abs(nu_phi((xb - mu) / sg) - mpmath.mpf(a2.p) / a2.q) < mpmath.mpf("1e-25"), "μ and σ don't give the second area")
        pair = lambda a, b: f"μ = {rg_s(nu_f(a))}, σ = {rg_s(nu_f(b))}"
        want = pair(mu, sg)
        if abs(z2) != abs(z1):
            pm, ps = solve2(abs(z1), abs(z2))
            wrongs[NU_SKILL + "unknown-mean-and-sd#0"] = {pair(pm, ps)}
        pm, ps = solve2(mpmath.mpf(a1.p) / a1.q, mpmath.mpf(a2.p) / a2.q)
        wrongs[NU_SKILL + "unknown-mean-and-sd#1"] = {pair(pm, ps)}
        round1 = lambda v: mpmath.floor(v * 10 + mpmath.mpf("0.5")) / 10
        pm, ps = solve2(round1(z1), round1(z2))
        wrongs[NU_SKILL + "unknown-mean-and-sd#2"] = {pair(pm, ps)}
        if rep == "diagram":
            nu_shaded(q, mpmath.mpf(a1.p) / a1.q + 1 - mpmath.mpf(a2.p) / a2.q if s2 == "gt" else mpmath.mpf(a2.p) / a2.q)
    elif u in ("mean-from-equal-tails", "sd-from-equal-tails"):
        unit = NU_CONTEXTS[int(g["ctx"])][1]
        p = None
        if u == "mean-from-equal-tails":
            mt = re.fullmatch(rf"The percentage below ({NU_NUM}){unit} equals the percentage above ({NU_NUM}){unit}\.", L[1]) if rep == "words" else re.fullmatch(rf"P\(X < ({NU_NUM})\) = P\(X > ({NU_NUM})\)", L[1])
            need(mt is not None, f"can't read {L[1]!r}")
            a, b = nu_val(mt.group(1)), nu_val(mt.group(2))
            need(a < b and ((a + b) / 2).q == 1, "the mean is not a whole number")
            want = f"μ = {dec_text((a + b) / 2)}"
            if rep == "diagram":
                ga = q["graph"]
                mid = (mpmath.mpf(a.p) / a.q + mpmath.mpf(b.p) / b.q) / 2
                need(abs(mpmath.mpf(ga["mu"]) - mid) < mpmath.mpf("1e-6"), "the curve is not centred between the two values")
        else:
            if rep == "words":
                mt = re.fullmatch(rf"({NU_NUM})% of them are below ({NU_NUM}){unit}, and ({NU_NUM})% are above ({NU_NUM}){unit}\.", L[1])
                need(mt is not None and mt.group(1) == mt.group(3), f"can't read {L[1]!r}")
                p, a, b = nu_val(mt.group(1)) / 100, nu_val(mt.group(2)), nu_val(mt.group(4))
            else:
                mt = re.fullmatch(rf"P\(X < ({NU_NUM})\) = P\(X > ({NU_NUM})\) = ({NU_NUM})", L[1])
                need(mt is not None, f"can't read {L[1]!r}")
                a, b, p = nu_val(mt.group(1)), nu_val(mt.group(2)), nu_val(mt.group(3))
            half = (b - a) / 2
            s_ = (mpmath.mpf(half.p) / half.q) / nu_inv(1 - p)
            want, trap = sd_answer(s_)
    elif u == "mean-from-two-z":
        if rep == "words":
            unit = NU_CONTEXTS[int(g["ctx"])][1]
            ms = [re.fullmatch(rf"A value of ({NU_NUM}){unit} has z-value ({NU_NUM})\.", ln) for ln in L[1:3]]
        else:
            ms = [re.fullmatch(rf"x = ({NU_NUM}) has z = ({NU_NUM})", ln) for ln in L[1:3]]
        need(all(ms), f"can't read {L}")
        (x1, z1), (x2, z2) = [(nu_val(mt.group(1)), nu_val(mt.group(2))) for mt in ms]
        m, s_ = sp.symbols("m s")
        sol = sp.solve([m + z1 * s_ - x1, m + z2 * s_ - x2], [m, s_])
        need(sol[m].q == 1 and sol[s_].q == 1 and sol[s_] > 0, f"μ = {sol[m]}, σ = {sol[s_]}")
        want = f"μ = {sol[m]}"
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wrongs, trap)
    for sol in q["solutions"]:
        last = sol["steps"][-1]
        need(want in last or (u == "standardise-event" and last.endswith(f"= {want}.")), f"{sol['name']}: the last step {last!r} doesn't state {want!r}")
    return None, None


# ── venn (t4-venn-addition-rule, FAL-725) ────────────────────
# The `venn` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/venn.gd. The regions are read back from the lines, the diagram or the
# table, by working out the unknown region from what is shown, never from the situation.

VN_SKILL = "SL4.6."
VN_EDGE = sp.Rational(29, 1000)         # the engine's is 0.03
VN_NUM = r"\d+(?:/\d+)?(?:\.\d+)?"
VN_CONTEXTS = [("scavengers", "scavenger", "carry a radio", "carry a water filter", "carries a radio", "carries a water filter"),
               ("traders", "trader", "sell fuel", "sell salt", "sells fuel", "sells salt"),
               ("guards", "guard", "own a crossbow", "own a shield", "owns a crossbow", "owns a shield"),
               ("settlers", "settler", "keep goats", "grow beans", "keeps goats", "grows beans"),
               ("mechanics", "mechanic", "repair engines", "repair radios", "repairs engines", "repairs radios"),
               ("drivers", "driver", "hold a permit", "carry a spare wheel", "holds a permit", "carries a spare wheel"),
               ("medics", "medic", "carry bandages", "carry painkillers", "carries bandages", "carries painkillers"),
               ("farmers", "farmer", "use a well", "use a rain tank", "uses a well", "uses a rain tank")]


def vn_p(line, name):
    mt = re.fullmatch(rf"P\({name}\) = ({VN_NUM})", line)
    need(mt is not None, f"can't read P({name}) in {line!r}")
    return R(mt.group(1))


def vn_prob_shown(v, dec, paper):
    """How a probability answer is written: exact, except a Paper 2 count that needs rounding."""
    if dec:
        return dec_text(v), None
    if paper == 1:
        return frac_text(v), None
    return rg_s(v), bn_trap("", v)


def vn_opts(q, label, v, dec, paper, table):
    """want, trap and wrongs for a probability v with its misconception values in `table`."""
    w, tr = vn_prob_shown(v, dec, paper)
    wrongs = {}
    for ref, x in table.items():
        wrongs[VN_SKILL + ref] = {label + vn_prob_shown(x, dec, paper)[0]}
    return label + w, (label + tr if tr else None), wrongs


def vn_story(q):
    """u, n(A), n(B) and n(both) from "Of the u who in a camp, ..."."""
    c = VN_CONTEXTS[int(q["given"]["ctx"])]
    mt = re.fullmatch(rf"Of the (\d+) {c[0]} in a camp, (\d+) {c[2]}, (\d+) {c[3]} and (\d+) do both\.", q["lines"][0])
    need(mt is not None, f"can't read {q['lines'][0]!r}")
    return [int(mt.group(i)) for i in (1, 2, 3, 4)]


def vn_diagram(q):
    """The four regions as Rationals out of u: probabilities, or counts with the total in the line."""
    g = q["graph"]
    need(g is not None and g["kind"] == "venn" and g["names"] == ["A", "B"], "no Venn diagram")
    a, i, b, o = [R(g[k]) for k in ("a", "i", "b", "o")]
    if "." in g["a"] or "." in g["i"] or "." in g["b"] or "." in g["o"]:
        need(a + i + b + o == 1, "the diagram's probabilities don't add to 1")
        need(q["lines"][0] == "The Venn diagram shows the probability of each region for events A and B.", f"{q['lines'][0]!r}")
        return a, i, b, o, True
    mt = re.match(r"The Venn diagram shows how many of (\d+) outcomes", q["lines"][0])
    need(mt is not None, f"can't read {q['lines'][0]!r}")
    u = int(mt.group(1))
    need(a + i + b + o == u, "the diagram's numbers don't add to the total")
    return a / u, i / u, b / u, o / u, False


def vn_table(q):
    rows = q["table"]["rows"]
    need(rows[0][1] == ["B", "B′", "Total"] and [r[0] for r in rows[1:]] == ["A", "A′", "Total"], "table heads")
    return rows


def check_venn(q):
    g, u, L, rep, asked, paper = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"], q["asked"], q["paper"]
    wrongs, want, trap = {}, None, None
    words = rep == "words"
    if u in ("union-from-rule", "intersection-from-rule", "neither-from-rule"):
        c = VN_CONTEXTS[int(g["ctx"])]
        lab = "probability = " if words else {"union-from-rule": "P(A ∪ B) = ", "intersection-from-rule": "P(A ∩ B) = ", "neither-from-rule": "P(A′ ∩ B′) = "}[u]
        if words:
            if u == "intersection-from-rule":
                mt = re.fullmatch(rf"Of the (\d+) {c[0]} in a camp, (\d+) {c[2]} and (\d+) {c[3]}\. In all, (\d+) do at least one of these\.", L[0])
                need(mt is not None, f"can't read {L[0]!r}")
                n, na, nb, nu = [int(mt.group(i)) for i in (1, 2, 3, 4)]
                pa, pb, pu = sp.Rational(na, n), sp.Rational(nb, n), sp.Rational(nu, n)
                pi = pa + pb - pu
            else:
                n, na, nb, ni = vn_story(q)
                pa, pb, pi = sp.Rational(na, n), sp.Rational(nb, n), sp.Rational(ni, n)
                pu = pa + pb - pi
            dec = False
        else:
            pa, pb = vn_p(L[0], "A"), vn_p(L[1], "B")
            if u == "intersection-from-rule":
                pu = vn_p(L[2], "A ∪ B")
                pi = pa + pb - pu
            else:
                pi = vn_p(L[2], "A ∩ B")
                pu = pa + pb - pi
            dec = "." in L[0] or "." in L[1] or "." in L[2]
            need(dec or paper == 1, "fractions are Paper 1 only")
        need(0 < pi < min(pa, pb) and pu < 1, f"P(A ∩ B) = {pi}, P(A ∪ B) = {pu}")
        if u == "union-from-rule":
            need(words or asked == "Find P(A ∪ B).", f"asked {asked!r}")
            need(pa + pb < 1, "P(A) + P(B) is not below 1")
            want, trap, wrongs = vn_opts(q, lab, pu, dec, paper, {"union#0": pa + pb, "union#1": pa * pb, "union#2": pu - pi})
        elif u == "intersection-from-rule":
            want, trap, wrongs = vn_opts(q, lab, pi, dec, paper, {"union#1": pa * pb})
        else:
            want, trap, wrongs = vn_opts(q, lab, 1 - pu, dec, paper, {"union#0": 1 - pa - pb})
    elif u == "union-from-regions":
        a, i, b, o, dec = vn_diagram(q)
        need(asked == "Find P(A ∪ B).", f"asked {asked!r}")
        want, trap, wrongs = vn_opts(q, "P(A ∪ B) = ", a + i + b, dec, paper, {"union#0": a + b + 2 * i, "union#2": a + b})
    elif u == "union-from-table":
        rows = vn_table(q)
        i, a, na = [int(v) for v in rows[1][1]]
        b, o, nn = [int(v) for v in rows[2][1]]
        nb, nbn, n = [int(v) for v in rows[3][1]]
        need(i + a == na and b + o == nn and i + b == nb and a + o == nbn and na + nn == n, "the table doesn't add up")
        want, trap, wrongs = vn_opts(q, "P(A ∪ B) = ", sp.Rational(a + i + b, n), False, paper, {"union#0": sp.Rational(a + b + 2 * i, n), "union#2": sp.Rational(a + b, n)})
    elif u == "table-missing-entry":
        rows = vn_table(q)
        T = {(ri, ci): rows[ri + 1][1][ci] for ri in range(3) for ci in range(3)}
        mt = re.fullmatch(r"The two-way table shows (\d+) outcomes\.", L[0])
        need(mt is not None and T[(2, 2)] == mt.group(1), "the total is not the one in the table")
        need(sum(v == "?" for v in T.values()) == 1, "one entry is asked")
        i, na, nb, n = int(T[(0, 0)]), int(T[(0, 2)]), int(T[(2, 0)]), int(T[(2, 2)])
        full = {(0, 1): na - i, (1, 0): nb - i, (1, 1): n - na - nb + i, (1, 2): n - na, (2, 1): n - nb}
        pos = next(k for k, v in T.items() if v == "?")
        need(full[pos] > 0, "the entry is not positive")
        want = f"? = {full[pos]}"
    elif u == "one-event-only":
        need(asked == "Find P(A ∩ B′).", f"asked {asked!r}")
        if rep == "diagram":
            a, i, b, o, dec = vn_diagram(q)
        else:
            pa, pb, i = vn_p(L[0], "A"), vn_p(L[1], "B"), vn_p(L[2], "A ∩ B")
            a, b, o, dec = pa - i, pb - i, 1 - pa - pb + i, "." in L[0] or "." in L[1] or "." in L[2]
        want, trap, wrongs = vn_opts(q, "P(A ∩ B′) = ", a, dec, paper, {"venn#2": o, "venn#0": a + i})
    elif u == "exactly-one":
        if rep == "diagram":
            a, i, b, o, dec = vn_diagram(q)
        else:
            n, na, nb, ni = vn_story(q)
            a, i, b, dec = sp.Rational(na - ni, n), sp.Rational(ni, n), sp.Rational(nb - ni, n), False
        want, trap, wrongs = vn_opts(q, "probability = ", a + b, dec, paper, {"union#2": a + b + i})
    elif u == "region-from-totals":
        if rep == "diagram":
            mt = re.fullmatch(r"n\(U\) = (\d+), n\(A\) = (\d+) and n\(B\) = (\d+)", L[0])
            need(mt is not None and q["graph"]["o"] == "?", f"can't read {L[0]!r}")
            n, na, nb, ni = int(mt.group(1)), int(mt.group(2)), int(mt.group(3)), int(q["graph"]["i"])
        else:
            n, na, nb, ni = vn_story(q)
        o = n - (na + nb - ni)
        need(o > 0, "nothing is outside the circles")
        want = f"number = {o}"
        wrongs[VN_SKILL + "venn#0"] = {f"number = {n - na - nb - ni}"}
        wrongs[VN_SKILL + "venn#1"] = {"number = 0"}
    elif u == "x-from-total":
        x = sp.symbols("x")
        if rep == "diagram":
            gr = q["graph"]
            mt = re.fullmatch(r"The Venn diagram shows the number in each region\. The total is (\d+)\.", L[0])
            need(mt is not None, f"can't read {L[0]!r}")
            exprs, o, n = [sp.sympify(re.sub(r"(\d)x", r"\1*x", gr[k]).replace("−", "-")) for k in "aib"], int(gr["o"]), int(mt.group(1))
        else:
            c = VN_CONTEXTS[int(g["ctx"])]
            mt = re.fullmatch(rf"Of the (\d+) {c[0]} in a camp, (.+) only {c[2]}, (.+) only {c[3]}, (.+) do both and (\d+) do neither\.", L[0])
            need(mt is not None, f"can't read {L[0]!r}")
            exprs = [sp.sympify(re.sub(r"(\d)x", r"\1*x", mt.group(k)).replace("−", "-")) for k in (2, 4, 3)]
            n, o = int(mt.group(1)), int(mt.group(5))
        sols = sp.solve(sum(exprs) + o - n, sp.Symbol("x"))
        need(len(sols) == 1 and sols[0].q == 1, f"x = {sols}")
        xv = sols[0]
        need(all(e.subs(sp.Symbol("x"), xv) >= 1 for e in exprs), "a region isn't positive")
        want = f"x = {xv}"
        slip = sp.solve(sum(exprs) - n, sp.Symbol("x"))[0]
        need(slip.q == 1, "forgetting the outside doesn't give a whole number")
        wrongs[VN_SKILL + "venn#1"] = {f"x = {slip}"}
    elif u in ("least-overlap", "greatest-overlap"):
        pa, pb = vn_p(L[0], "A"), vn_p(L[1], "B")
        need(pa + pb > 1 and pa != pb, "the events need not overlap")
        v = pa + pb - 1 if u == "least-overlap" else min(pa, pb)
        need(asked == f"Find the {'least' if u == 'least-overlap' else 'greatest'} possible value of P(A ∩ B).", f"asked {asked!r}")
        want = "P(A ∩ B) = " + dec_text(v)
        wrongs[VN_SKILL + "union#1"] = {"P(A ∩ B) = " + dec_text(pa * pb)}
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wrongs, trap)
    for o in q["choices"]:
        if u not in ("region-from-totals", "x-from-total", "table-missing-entry"):
            m = re.search(r"= (.+)$", o["text"])
            need(0 < R(m.group(1).replace("−", "-")) < 1, f"option {o['text']!r} is not a probability")
    for sol in q["solutions"]:
        need(want in sol["steps"][-1], f"{sol['name']}: the last step {sol['steps'][-1]!r} doesn't state {want!r}")
    return None, None


# ── conditional (t4-conditional-probability, FAL-725) ────────
# The `conditional` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/conditional.gd. Each question's facts are read back from what the
# student sees, and the ratio is found again with exact rationals, or mpmath for a normal.

CD_SKILL = "SL4.11."
CD_TREES = [("crates", "are spoiled", "the scanner flags", "A crate", "spoiled", "flagged"),
            ("fuel cans", "are watered down", "the tester rejects", "A can", "watered down", "rejected"),
            ("water samples", "are unsafe", "the filter test marks red", "A sample", "unsafe", "marked red"),
            ("coins in a till", "are fake", "the scales reject", "A coin", "fake", "rejected"),
            ("seed packets", "are old stock", "the sorter sets aside", "A packet", "old stock", "set aside"),
            ("batteries", "are worn out", "the meter fails", "A battery", "worn out", "failed"),
            ("travellers", "are carrying fever", "the medic's strip marks", "A traveller", "carrying fever", "marked"),
            ("parts in a bin", "are cracked", "the inspector rejects", "A part", "cracked", "rejected")]
CD_COLOURS = [("red", "blue"), ("green", "white"), ("black", "yellow"), ("red", "green")]
CD_THINGS = ["tokens", "marbles", "fuses", "tags"]


def cd_shown(v, paper, dec):
    """Paper 2 to 3 s.f.; Paper 1 as the question writes its numbers. A decimal of more than nine
    places is written as a fraction, as the game's Fmt.dec does."""
    if paper == 2:
        return rg_s(v)
    if not dec:
        return frac_text(v)
    return dec_text(v) if len(dec_text(v).split(".")[-1]) <= 9 else frac_text(v)


def cd_set(q, label, v, table, dec=True):
    """want, trap and wrongs for a probability v; `table` is ref -> the value that mistake gives."""
    paper = q["paper"]
    want = label + cd_shown(v, paper, dec)
    trap = bn_trap(label, v) if paper == 2 else None
    wrongs = {CD_SKILL + ref: {label + cd_shown(x, paper, dec)} for ref, x in table.items()}
    return want, trap, wrongs


def cd_dec(q):
    """Whether an event question writes its numbers as decimals."""
    rep, L = q["view"]["rep"], q["lines"]
    if rep == "diagram":
        return vn_diagram(q)[4]
    return rep == "equation" and any("." in ln for ln in L)


def cd_regions(q):
    """a, i, b, o as probabilities, read from the lines, the story, the diagram or the table."""
    rep, L = q["view"]["rep"], q["lines"]
    if rep == "diagram":
        return vn_diagram(q)[:4]
    if rep == "table":
        rows = vn_table(q)
        i, a, na = [int(v) for v in rows[1][1]]
        b, o, nn = [int(v) for v in rows[2][1]]
        nb, nbn, n = [int(v) for v in rows[3][1]]
        need(i + a == na and b + o == nn and i + b == nb and a + o == nbn and na + nn == n, "the table doesn't add up")
        return sp.Rational(a, n), sp.Rational(i, n), sp.Rational(b, n), sp.Rational(o, n)
    if rep == "words":
        n, na, nb, ni = vn_story(q)
        return sp.Rational(na - ni, n), sp.Rational(ni, n), sp.Rational(nb - ni, n), sp.Rational(n - na - nb + ni, n)
    pa, pb, i = vn_p(L[0], "A"), vn_p(L[1], "B"), vn_p(L[2], "A ∩ B")
    return pa - i, i, pb - i, 1 - pa - pb + i


def cd_pct(t):
    return R(t) / 100


def cd_lines_rule(q, u):
    """P(A), P(B), P(A | B) (some None), from the lines or the percentages."""
    L, rep = q["lines"], q["view"]["rep"]
    if rep == "equation":
        vals = {}
        for ln in L:
            mt = re.fullmatch(rf"P\((A|B|A \| B|A ∪ B)\) = ({VN_NUM})", ln)
            need(mt is not None, f"can't read {ln!r}")
            vals[mt.group(1)] = R(mt.group(2))
        return vals.get("A"), vals.get("B"), vals.get("A | B"), vals.get("A ∪ B")
    c = VN_CONTEXTS[int(q["given"]["ctx"])]
    if u == "intersection-from-conditional":
        m1 = re.fullmatch(rf"(\d+(?:\.\d+)?)% of the {c[0]} in a camp {c[3]}\.", L[0])
        m2 = re.fullmatch(rf"Of those, (\d+(?:\.\d+)?)% also {c[2]}\.", L[1])
        need(m1 is not None and m2 is not None, f"can't read {L}")
        return None, cd_pct(m1.group(1)), cd_pct(m2.group(1)), None
    m1 = re.fullmatch(rf"(\d+(?:\.\d+)?)% of the {c[0]} in a camp {c[2]} and (\d+(?:\.\d+)?)% {c[3]}\.", L[0])
    m2 = re.fullmatch(rf"Of those who {c[3]}, (\d+(?:\.\d+)?)% also {c[2]}\.", L[1])
    need(m1 is not None and m2 is not None, f"can't read {L}")
    return cd_pct(m1.group(1)), cd_pct(m1.group(2)), cd_pct(m2.group(1)), None


def check_conditional(q):
    with mpmath.workdps(40):
        return cd_check(q)


def cd_check(q):
    g, u, L, rep, asked, paper = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"], q["asked"], q["paper"]
    need(paper == 2 or u not in ("conditional-normal", "conditional-binomial"), "normal and binomial conditionals are Paper 2")
    wrongs, want, trap = {}, None, None
    if u in ("conditional-from-probabilities", "conditional-from-venn", "conditional-from-table"):
        a, i, b, o = cd_regions(q)
        need(i + b >= sp.Rational(1, 10), "the given event is below 0.1")
        label = "P(A | B) = " if rep in ("equation", "diagram") else "probability = "
        table = {"conditional-formula#0": i / (a + i), "conditional-formula#1": i}
        if u == "conditional-from-probabilities":
            table["conditional-formula#2"] = (a + i) * (b + i)
        want, trap, wrongs = cd_set(q, label, i / (i + b), table, cd_dec(q))
    elif u == "conditional-complement":
        a, i, b, o = cd_regions(q)
        label = "P(A′ | B′) = " if rep == "equation" else "probability = "
        want, trap, wrongs = cd_set(q, label, o / (a + o), {"conditional-formula#0": o / (b + o), "conditional-formula#1": o}, cd_dec(q))
    elif u == "unknown-from-conditional":
        rows = q["table"]["rows"]
        need(rows[0][1] == ["B", "B′"] and rows[2][1][1] == "n", "the table")
        a = int(rows[1][1][1])
        r = R(re.fullmatch(r"P\(A′ \| B′\) = (\d+/\d+)", L[1]).group(1))
        n = sp.Symbol("n")
        sol = sp.solve(n / (a + n) - r, n)
        need(len(sol) == 1 and sol[0].q == 1 and sol[0] > 0, f"n = {sol}")
        want = f"n = {sol[0]}"
    elif u == "reverse-from-tree":
        if rep == "diagram":
            t = q["graph"]
            need(t["kind"] == "tree", "no tree")
            pa, pan = R(t["p"][0]), R(t["p"][1])
            pba, pbna, pbn, pbnn = [R(v) for v in t["q"][0] + t["q"][1]]
            need(pa + pan == 1 and pba + pbna == 1 and pbn + pbnn == 1, "the branches don't add to 1")
            label = "P(A | B) = "
        else:
            c = CD_TREES[int(g["ctx"])]
            m1 = re.fullmatch(rf"Of the {c[0]} at a depot, (\d+(?:\.\d+)?)% {c[1]}\.", L[0])
            m2 = re.fullmatch(rf"A check: {c[2]} (\d+(?:\.\d+)?)% of those, and (\d+(?:\.\d+)?)% of the others\.", L[1])
            need(m1 is not None and m2 is not None, f"can't read {L}")
            need(asked == f"{c[3]} is {c[5]}. Find the probability that it is {c[4]}.", f"asked {asked!r}")
            pa, pba, pbn = cd_pct(m1.group(1)), cd_pct(m2.group(1)), cd_pct(m2.group(2))
            label = "probability = "
        both = pa * pba
        total = both + (1 - pa) * pbn
        need(total >= sp.Rational(1, 10), "the given event is below 0.1")
        want, trap, wrongs = cd_set(q, label, both / total, {"reverse-conditional#0": pba, "reverse-conditional#1": both})
    elif u == "reverse-two-draws":
        mt = re.fullmatch(r"A bag holds (\d+) (\w+) and (\d+) (\w+) (\w+)\.", L[0])
        need(mt is not None and L[1] == "Two are drawn at random, without replacement.", f"can't read {L}")
        r, gg = int(mt.group(1)), int(mt.group(3))
        need((mt.group(2), mt.group(4)) in CD_COLOURS and mt.group(5) in CD_THINGS, "the colours or things")
        need(asked == f"Given that the two are the same colour, find the probability that both are {mt.group(2)}.", f"asked {asked!r}")
        t = r + gg
        rr = sp.Rational(r, t) * sp.Rational(r - 1, t - 1)
        same = rr + sp.Rational(gg, t) * sp.Rational(gg - 1, t - 1)
        want, trap, wrongs = cd_set(q, "probability = ", rr / same, {"reverse-conditional#1": rr}, False)
    elif u == "intersection-from-conditional":
        _, pb, pc, _ = cd_lines_rule(q, u)
        label = "P(A ∩ B) = " if rep == "equation" else "probability = "
        want, trap, wrongs = cd_set(q, label, pc * pb, {"multiplication-rule#0": pc / pb, "multiplication-rule#1": pc})
    elif u == "union-from-conditional":
        pa, pb, pc, _ = cd_lines_rule(q, u)
        need(pc * pb < pa, "the overlap is bigger than A")
        label = "P(A ∪ B) = " if rep == "equation" else "probability = "
        want, trap, wrongs = cd_set(q, label, pa + pb - pc * pb, {"multiplication-rule#1": pa + pb - pc})
    elif u == "marginal-from-union":
        pa, _, pc, pu = cd_lines_rule(q, u)
        x = sp.Symbol("x")
        sol = sp.solve(pa + x - pc * x - pu, x)
        need(len(sol) == 1 and 0 < sol[0] < 1, f"P(B) = {sol}")
        want, trap, wrongs = cd_set(q, "P(B) = ", sol[0], {})
    elif u == "conditional-normal":
        if rep == "words":
            c = NU_CONTEXTS[int(g["ctx"])]
            mt = re.fullmatch(rf"{re.escape(c[0])} are normally distributed with mean (\d+){c[1]} and standard deviation (\d+){c[1]}\.", L[0])
            ma = re.fullmatch(rf"Given that one of them is (below|above) (\d+){c[1]}, find the probability that it is (below|above) (\d+){c[1]}\.", asked)
            need(mt is not None and ma is not None, f"can't read {L[0]!r} or {asked!r}")
            mu, sg = int(mt.group(1)), int(mt.group(2))
            gv = ("<" if ma.group(1) == "below" else ">", int(ma.group(2)))
            wn = ("<" if ma.group(3) == "below" else ">", int(ma.group(4)))
        else:
            mt = re.fullmatch(r"X ~ N\((\d+), (\d+)²\)", L[0])
            ma = re.fullmatch(r"Find P\(X ([<>]) (\d+) \| X ([<>]) (\d+)\)\.", asked)
            need(mt is not None and ma is not None, f"can't read {L[0]!r} or {asked!r}")
            mu, sg = int(mt.group(1)), int(mt.group(2))
            wn, gv = (ma.group(1), int(ma.group(2))), (ma.group(3), int(ma.group(4)))
        lim = lambda v: nu_phi(mpmath.mpf(v - mu) / sg)
        below = lambda e: (0, lim(e[1])) if e[0] == "<" else (lim(e[1]), 1)
        l1, h1 = below(wn)
        l2, h2 = below(gv)
        lo, hi = max(l1, l2), min(h1, h2)
        need(hi > lo, "the two events don't overlap")
        num, den = hi - lo, h2 - l2
        need(den >= mpmath.mpf("0.1") and den <= mpmath.mpf("0.9") and num >= mpmath.mpf("0.02"), f"num {num} den {den}")
        v = nu_f(num / den)
        lv, hv = sorted((wn[1], gv[1]))
        between = lim(hv) - lim(lv)
        need(rg_clear(v), "on a rounding edge")
        want, trap, wrongs = cd_set(q, "probability = ", v, {"conditional-distributions#0": nu_f(num * den), "conditional-distributions#1": nu_f(between), "conditional-distributions#2": nu_f(num)})
        if rep == "diagram":
            shades = q["graph"]["shade"]
            need(len(shades) == 2 and abs(mpmath.mpf(q["graph"]["mu"]) - mu) < 1e-9, "the curve drawn")
            area = lambda sh: (nu_phi((mpmath.mpf(sh[1]) - mu) / sg) if sh[1] is not None else 1) - (nu_phi((mpmath.mpf(sh[0]) - mu) / sg) if sh[0] is not None else 0)
            need(abs(area(shades[0]) - den) < mpmath.mpf("1e-12") and abs(area(shades[1]) - num) < mpmath.mpf("1e-12"), "the shaded areas are not the given and the wanted")
    elif u == "conditional-binomial":
        if rep == "equation":
            mt = re.fullmatch(r"X ~ B\((\d+), (0\.\d+)\)", L[0])
            need(mt is not None, f"can't read {L[0]!r}")
            n, p = int(mt.group(1)), R(mt.group(2))
        else:
            mp_ = re.search(r"probability (0\.\d+)", L[0])
            mn = re.search(r"(\d+) [a-z]", L[0].split("others.")[1])
            need(mp_ is not None and mn is not None, f"can't read {L[0]!r}")
            n, p = int(mn.group(1)), R(mp_.group(1))
        ma = re.fullmatch(r"Find P\(X (≤|=|≥) (\d+) \| X ≥ (\d+)\)\.", asked)
        need(ma is not None, f"asked {asked!r}")
        k, j = int(ma.group(2)), int(ma.group(3))
        need(k < n and j >= 1, "the bounds")
        lo, hi = {"≤": (j, k), "=": (k, k), "≥": (k, n)}[ma.group(1)]
        num = bn_cdf(n, p, hi) - bn_cdf(n, p, lo - 1)
        den = bn_cdf(n, p, n) - bn_cdf(n, p, j - 1)
        need(sp.Rational(1, 10) <= den <= sp.Rational(97, 100) and num >= sp.Rational(1, 50), f"num {float(num)} den {float(den)}")
        need(rg_clear(num / den), "on a rounding edge")
        want, trap, wrongs = cd_set(q, "probability = ", num / den, {"conditional-distributions#0": num * den, "conditional-distributions#2": num})
    elif u == "conditional-discrete":
        rows = q["table"]["rows"]
        xs, ps = [int(v) for v in rows[0][1]], [R(v) for v in rows[1][1]]
        need(rows[0][0] == "x" and rows[1][0] == "P(X = x)" and sum(ps) == 1 and all(p > 0 for p in ps), "the distribution doesn't add to 1")
        ma = re.fullmatch(r"Find P\(X ≥ (\d+) \| X < (\d+)\)\.", asked)
        need(ma is not None, f"asked {asked!r}")
        a, b = int(ma.group(1)), int(ma.group(2))
        num = sum(p for x, p in zip(xs, ps) if a <= x < b)
        den = sum(p for x, p in zip(xs, ps) if x < b)
        need(den >= sp.Rational(1, 10), "the given event is below 0.1")
        want, trap, wrongs = cd_set(q, "probability = ", num / den, {"conditional-distributions#2": num})
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wrongs, trap)
    if u != "unknown-from-conditional":
        for o in q["choices"]:
            v = R(o["text"].split(" = ")[1].replace("−", "-"))
            need(0 < v < 1, f"option {o['text']!r} is not a probability")
    for sol in q["solutions"]:
        need(want in sol["steps"][-1], f"{sol['name']}: the last step {sol['steps'][-1]!r} doesn't state {want!r}")
    return None, None


# ── sampling (t4-sampling, FAL-726) ──────────────────────────
# The `sampling` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/sampling.gd. The technique is worked out from what the surveyor does, by
# the checklist (a fixed interval, groups filled, a random draw), never from the situation.

SM_T = "SL4.1.sampling-technique#"
SM_B = "SL4.1.bias-reliability#"
SM_CTX = [("settlers", "camp", ("farmers", "guards", "cooks"), "at the well", "the camp register", "how much water they use"),
          ("traders", "market", ("salt sellers", "fuel sellers", "scrap dealers"), "at the market gate", "the traders' ledger", "how far they travel"),
          ("scavengers", "depot", ("day crew", "night crew", "drivers"), "at the depot door", "the crew roster", "how many hours they work"),
          ("miners", "mine", ("diggers", "haulers", "blasters"), "at the pit head", "the pay book", "how often they fall ill"),
          ("drivers", "convoy", ("truck drivers", "bike riders", "tanker drivers"), "at the fuel pump", "the convoy log", "how much fuel they burn"),
          ("medics", "hospital", ("nurses", "surgeons", "porters"), "at the supply tent", "the duty rota", "how many hours they sleep"),
          ("farmers", "settlement", ("goat keepers", "bean growers", "fish farmers"), "at the grain store", "the land register", "how much they harvest"),
          ("mechanics", "workshop", ("welders", "wirers", "fitters"), "at the tool hatch", "the workshop roll", "how many repairs they finish")]
SM_NAMES = {"simple": "Simple random sampling", "systematic": "Systematic sampling", "convenience": "Convenience sampling",
            "quota": "Quota sampling", "stratified": "Stratified sampling"}
# A disadvantage is true of the techniques listed: anything else offered is false of the method.
SM_FLAWS = {"It needs a complete list of everyone in the {}.": {"simple", "systematic", "stratified"},
            "A repeating pattern in the list could match the interval.": {"systematic"},
            "The size of each group must be known before starting.": {"stratified", "quota"},
            "Those who come by first may differ from the rest of the {}.": {"convenience", "quota"},
            "Nobody is drawn at random within a group, so the surveyor's choices can skew it.": {"quota"},
            "Only the starting point is chosen at random.": {"systematic"}}
SM_MAIN = {"simple": "It needs a complete list of everyone in the {}.", "systematic": "A repeating pattern in the list could match the interval.",
           "stratified": "The size of each group must be known before starting.", "convenience": "Those who come by first may differ from the rest of the {}.",
           "quota": "Nobody is drawn at random within a group, so the surveyor's choices can skew it."}
# Where they were asked, and what a mean from those people does.
SM_LEAN = {"in the queue at the well": "Too high: people in that queue fetch more water than most.",
           "in the sick bay": "Too low: people in the sick bay walk less than most.",
           "in the line at the fuel pump": "Too high: people in that line burn more fuel than most.",
           "on the night watch": "Too low: people on the night watch sleep less than most.",
           "at the largest stalls": "Too high: people at the largest stalls take more than most.",
           "in the hunger ward": "Too low: people in the hunger ward eat less than most.",
           "at their benches at midnight": "Too high: people at their benches at midnight work longer than most.",
           "in the schoolroom": "Too low: people in the schoolroom are younger than most."}
SM_WHY = {"thank-you notes from": "He hears only from his own happy customers, and he gains if the figure is high.",
          "her own test of": "She tested her own jars, and she gains if the figure is high.",
          "letters from": "Buyers whose filters failed are unlikely to have written in.",
          "a show of hands from": "People may not say what they think in front of her guards.",
          "people who called the show": "Only people who feel strongly enough to call are counted.",
          "before the floods": "The survey is old, and the floods may have changed the ruins."}


def sm_ord(k):
    if 11 <= k % 100 <= 13:
        return f"{k}th"
    return f"{k}" + {1: "st", 2: "nd", 3: "rd"}.get(k % 10, "th")


def sm_cap(t):
    return t[0].upper() + t[1:]


def sm_camp(line, c):
    """N and the group sizes from "A camp has 240 settlers: 160 farmers and 80 guards."."""
    mt = re.fullmatch(rf"A {c[1]} has (\d+) {c[0]}: (.+)\.", line)
    need(mt is not None, f"can't read {line!r}")
    G = []
    for i, part in enumerate(re.split(r", | and (?=\d)", mt.group(2))):
        m2 = re.fullmatch(rf"(\d+) {c[2][i]}", part)
        need(m2 is not None, f"can't read the group {part!r}")
        G.append(int(m2.group(1)))
    need(sum(G) == int(mt.group(1)), "the groups don't add to the population")
    need(len(set(G)) == len(G), "two groups are the same size")
    return int(mt.group(1)), G


def sm_table(q, c, cols):
    """Columns of the groups table as ints, with the Total row checked."""
    rows = q["table"]["rows"]
    need(rows[0][0] == "group" and len(rows[0][1]) == cols, "table heads")
    need([r[0] for r in rows[1:-1]] == list(c[2][:len(rows) - 2]) and rows[-1][0] == "Total", "table groups")
    out = [[int(r[1][j]) for r in rows[1:-1]] for j in range(cols)]
    for j in range(cols):
        need(sum(out[j]) == int(rows[-1][1][j]), "a column doesn't add to its total")
    return out


def sm_scale(q, N, G, n=None):
    """The interval for a sample of n, with each group whole at that scale."""
    need(n is not None and n > 0 and N % n == 0, f"{N} is not a whole number of samples of {n}")
    k = N // n
    p1 = q["paper"] == 1
    need(k != n, "the interval is the sample size")
    need((4 if p1 else 6) <= k <= (20 if p1 else 40) and (10 if p1 else 40) <= n <= (40 if p1 else 150), f"n = {n}, k = {k} is outside the limits")
    for g in G:
        need(g % k == 0, f"the group of {g} isn't a whole multiple of {k}")
    return k


def sm_technique(line, c, G):
    """The checklist on a surveyor's method: (technique, sample size, interval)."""
    every = re.search(r"every (\d+)(?:st|nd|rd|th) name", line)
    random = "at random" in line or "random start" in line
    filled = re.search(rf"(\d+) {c[2][0]} and (\d+) {c[2][1]}", line)
    if every:
        k = int(every.group(1))
        need(random and f"among the first {k} names" in line and every.group(0) == f"every {sm_ord(k)} name", f"can't read the interval in {line!r}")
        return "systematic", sum(G) // k
    if filled:
        a, b = int(filled.group(1)), int(filled.group(2))
        need(a * G[1] == b * G[0], f"the groups in {line!r} are not in proportion")
        return ("stratified" if random else "quota"), a + b
    n = int(re.search(r"\b(\d+)\b", line).group(1))
    return ("simple" if random else "convenience"), n


def sm_size(line, N):
    mt = re.fullmatch(r"The surveyor wants a sample of (\d+)(%?) of them\.", line)
    need(mt is not None, f"can't read {line!r}")
    v = int(mt.group(1))
    if mt.group(2):
        need(N * v % 100 == 0, "the percentage isn't a whole number of people")
        return N * v // 100
    return v


def sm_arith(q):
    """The working's sums, wherever a step writes one."""
    for sol in q["solutions"]:
        for st in sol["steps"]:
            for a, b, r in re.findall(r"(\d+) ÷ (\d+) = (\d+)", st):
                need(int(a) == int(b) * int(r), f"{st!r}")
            for a, b, r in re.findall(r"(\d+) − (\d+) = (\d+)", st):
                need(int(a) - int(b) == int(r), f"{st!r}")


def check_sampling(q):
    g, u, L, rep, asked = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"], q["asked"]
    c = SM_CTX[int(g["ctx"])]
    who, place, names, spot, lst, topic = c
    a, b = names[0], names[1]
    wrongs, want = {}, None
    if u in ("name-technique", "technique-disadvantage", "is-it-random"):
        N, G = sm_camp(L[0], c)
        tech, n = sm_technique(L[1], c, G)
        sm_scale(q, N, G, n)
        if u == "name-technique":
            need(asked == "Which sampling technique is this?", f"asked {asked!r}")
            want = SM_NAMES[tech]
            wrongs = {"quota": {SM_T + "0": {SM_NAMES["stratified"]}}, "stratified": {SM_T + "0": {SM_NAMES["quota"]}},
                      "systematic": {SM_T + "1": {SM_NAMES["simple"]}}, "convenience": {SM_T + "2": {SM_NAMES["simple"]}}, "simple": {}}[tech]
            need(all(o["text"] in SM_NAMES.values() for o in q["choices"]), "an option is not a technique")
        elif u == "technique-disadvantage":
            want = SM_MAIN[tech].format(place)
            for o in q["choices"]:
                key = next((f for f in SM_FLAWS if f.format(place) == o["text"]), None)
                need(key is not None, f"{o['text']!r} is not a known flaw")
                need(o["correct"] or tech not in SM_FLAWS[key], f"{o['text']!r} is true of {tech}, so it is no wrong option")
        else:
            need(asked == "Is this a simple random sample?", f"asked {asked!r}")
            if tech == "systematic":
                want = "No: only the start is random, and the interval fixes every pick after it."
                wrongs = {SM_T + "1": {"Yes: the start is random, so the whole sample is random."}}
            elif tech == "convenience":
                want = "No: anyone who doesn't come by has no chance of being chosen."
                wrongs = {SM_T + "2": {"Yes: whoever comes by is a random person."}}
            else:
                need(tech == "simple", f"{tech} isn't asked here")
                want = f"Yes: every set of {n} people has the same chance."
                wrongs = {SM_T + "1": {"No: only the start is random."}}
    elif u == "best-technique":
        text = " ".join(L)
        if "There is no list. " in text:
            mt = re.fullmatch(rf"The (\d+) {who} come by {spot} one at a time during a shift\.", L[0])
            need(mt is not None, f"can't read {L[0]!r}")
            need("spread evenly along the line, from a random start" in L[1], f"{L[1]!r}")
            want, wrongs = SM_NAMES["systematic"], {SM_T + "1": {SM_NAMES["simple"]}}
        elif "There is no list," in text:
            sm_camp(L[0], c)
            need(f"can only reach people {spot}" in L[1], f"{L[1]!r}")
            want, wrongs = SM_NAMES["quota"], {SM_T + "0": {SM_NAMES["stratified"]}}
        elif "must have an equal chance" in text:
            sm_camp(L[0], c)
            want, wrongs = SM_NAMES["stratified"], {SM_T + "0": {SM_NAMES["quota"]}}
        else:
            need("The groups don't matter here" in text, f"{text!r}")
            want = SM_NAMES["simple"]
            wrongs = {SM_T + "1": {SM_NAMES["systematic"]}, SM_T + "2": {SM_NAMES["convenience"]}}
    elif u == "describe-systematic":
        N, G = sm_camp(L[0], c)
        n = sm_size(L[1], N)
        k = sm_scale(q, N, G, n)
        want = f"Go down {lst}, pick a random start among the first {k} names, then take every {sm_ord(k)} name."
        wrongs = {SM_T + "1": {f"Draw {n} names at random from {lst}."}}
    elif u == "systematic-interval":
        mt = re.fullmatch(rf"{re.escape(sm_cap(lst))} lists (\d+) {who}\.", L[0])
        need(mt is not None, f"can't read {L[0]!r}")
        N = int(mt.group(1))
        n = sm_size(L[1], N)
        k = sm_scale(q, N, [], n)
        want = f"interval = {k}"
    elif u == "systematic-member":
        mt = re.fullmatch(rf"{re.escape(sm_cap(lst))} numbers (\d+) {who} from 1 to (\d+)\.", L[0])
        m2 = re.fullmatch(r"A systematic sample starts at number (\d+) and takes every (\d+)(?:st|nd|rd|th) name\.", L[1])
        m3 = re.fullmatch(r"Find the number of the (\d+)(?:st|nd|rd|th) person chosen\.", asked)
        need(mt and m2 and m3 and mt.group(1) == mt.group(2), "can't read the sample")
        N, start, k, j = int(mt.group(1)), int(m2.group(1)), int(m2.group(2)), int(m3.group(1))
        v = start + (j - 1) * k
        need(1 <= start <= k and v <= N, "the pick is off the list")
        want = f"number {v}"
    elif u == "quota-number":
        mt = re.search(r"A (quota|stratified) sample of (\d+) must match", L[1])
        need(mt is not None, f"can't read {L[1]!r}")
        n = int(mt.group(2))
        if rep == "table":
            m2 = re.fullmatch(rf"The table shows the (\d+) {who} in a {place}\.", L[0])
            need(m2 is not None, f"can't read {L[0]!r}")
            G = sm_table(q, c, 1)[0]
            N = int(m2.group(1))
            need(N == sum(G), "the table's total isn't the population")
        else:
            N, G = sm_camp(L[0], c)
        sm_scale(q, N, G, n)
        m3 = re.fullmatch(r"Find how many (.+) go in the sample\.", asked)
        i = names.index(m3.group(1))
        v = sp.Rational(G[i] * n, N)
        need(v.q == 1, "the number isn't whole")
        want = f"number = {v}"
    elif u in ("fair-share", "under-represented"):
        if rep == "table":
            mt = re.fullmatch(rf"The table shows a {place} of (\d+) {who} and a sample of (\d+) of them\.", L[0])
            need(mt is not None, f"can't read {L[0]!r}")
            N, n = int(mt.group(1)), int(mt.group(2))
            G, got = sm_table(q, c, 2)
            need(sum(G) == N and sum(got) == n, "totals")
        else:
            N, G = sm_camp(L[0], c)
            mt = re.fullmatch(rf"A sample of (\d+) holds (\d+) {names[0]}, (\d+) {names[1]} and (\d+) {names[2]}\.", L[1])
            need(mt is not None, f"can't read {L[1]!r}")
            n, got = int(mt.group(1)), [int(mt.group(i)) for i in (2, 3, 4)]
            need(sum(got) == n, "the sample doesn't add up")
        sm_scale(q, N, G, n)
        fair = [sp.Rational(x * n, N) for x in G]
        need(all(f.q == 1 for f in fair), "a fair share isn't whole")
        if u == "fair-share":
            m3 = re.fullmatch(rf"By how many does the number of (.+) fall short of the mix of the {place}\?", asked)
            i = names.index(m3.group(1))
            need(got[i] < fair[i] and got[i] > 0, "the group doesn't fall short")
            want = f"number = {fair[i] - got[i]}"
        else:
            ratio = [sp.Rational(x, f) for x, f in zip(got, fair)]
            short = [f - x for x, f in zip(got, fair)]
            i = ratio.index(min(ratio))
            need(short[i] == max(short) and short.count(short[i]) == 1 and sorted(ratio)[1] > ratio[i], "no one group is clearly the most under-represented")
            need(got[i] != min(got), "the smallest count gives the answer away")
            want = sm_cap(names[i])
            wrongs = {SM_B + "1": {f"None: the sample matches the {place}."}}
    elif u in ("why-biased", "better-method"):
        N, G = sm_camp(L[0], c)
        mt = re.fullmatch(rf"To learn {topic} across the whole {place}, a surveyor draws (\d+) {a} at random and asks only them\.", L[1])
        need(mt is not None, f"can't read {L[1]!r}")
        n = int(mt.group(1))
        if u == "why-biased":
            want = f"Only {a} were asked, so the {b} had no chance of being chosen."
            wrongs = {SM_B + "0": {f"The sample is too small: with more {a} it would have no bias."},
                      SM_B + "1": {f"Nothing: a random draw always represents the whole {place}."}}
        else:
            want = f"Stratified sampling: draw at random from both the {a} and the {b}, in proportion to their numbers."
            wrongs = {SM_B + "0": {f"Keep to the {a}, and ask {2 * n} of them instead."},
                      SM_B + "1": {f"Change nothing: a random draw from the {a} is enough."},
                      SM_T + "2": {f"Ask the first {n} {who} who come by {spot}."}}
    elif u == "bias-direction":
        mt = re.fullmatch(r"She asks (\d+) of them, all (.+)\.", L[1])
        need(mt is not None and mt.group(2) in SM_LEAN, f"can't read {L[1]!r}")
        n, want = int(mt.group(1)), SM_LEAN[mt.group(2)]
        wrongs = {SM_B + "0": {f"Neither: asking {n} people cancels out any bias."}, SM_B + "1": {"Neither: a sample is always a fair picture of everyone."}}
    elif u == "bigger-sample":
        N, G = sm_camp(L[0], c)
        mt = re.fullmatch(rf"A surveyor asks (\d+) {a} about {topic}, and none of the {b}\.", L[1])
        need(mt is not None and L[2] == f"She plans to ask {3 * int(mt.group(1))} {a} instead.", f"can't read {L[1:]!r}")
        want = f"No: the result gets steadier, but the {b} are still left out."
        wrongs = {SM_B + "0": {"Yes: a larger sample removes bias."}}
    elif u == "random-not-perfect":
        if rep == "table":
            mt = re.fullmatch(rf"The table shows a {place} of (\d+) {who} and a simple random sample of (\d+) of them\.", L[0])
            need(mt is not None, f"can't read {L[0]!r}")
            N, n = int(mt.group(1)), int(mt.group(2))
            G, got = sm_table(q, c, 2)
        else:
            N, G = sm_camp(L[0], c)
            mt = re.fullmatch(rf"A simple random sample of (\d+) holds (\d+) {a} and (\d+) {b}\.", L[1])
            need(mt is not None, f"can't read {L[1]!r}")
            n, got = int(mt.group(1)), [int(mt.group(2)), int(mt.group(3))]
        need(sum(got) == n, "the sample doesn't add up")
        sm_scale(q, N, G, n)
        need(all(abs(sp.Rational(x * n, N) - y) >= 2 for x, y in zip(G, got)), "the sample doesn't miss the mix")
        want = "The draw can be fair and still miss the mix: chance alone moves a sample."
        wrongs = {SM_B + "1": {f"The draw can't have been random: a random sample always matches the {place}.", f"The {place}'s numbers must be wrong: a sample shows the true mix."}}
    elif u == "improve-reliability":
        mt = re.fullmatch(rf"A surveyor wants to learn {topic}, so she draws (\d+) of all the {who} at random\.", L[0])
        need(mt is not None and 5 <= int(mt.group(1)) <= 12, f"can't read {L[0]!r}")
        want = "Take a larger random sample, so that one person counts for less."
        wrongs = {SM_B + "1": {f"Keep the {mt.group(1)}: a random sample is always exact."}}
    elif u == "source-reliability":
        mt = re.fullmatch(r"The figure comes from (.+)\.", L[1])
        key = next((k for k in SM_WHY if k in mt.group(1)), None)
        need(key is not None, f"can't read {L[1]!r}")
        want = SM_WHY[key]
        wrongs = {SM_B + "0": {f"It is reliable: {re.search(r'[0-9]+', L[1]).group()} is enough to remove any bias."}}
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wrongs)
    sm_arith(q)
    for sol in q["solutions"]:
        need(want in sol["steps"][-1], f"{sol['name']}: the last step {sol['steps'][-1]!r} doesn't state {want!r}")
    return None, None


# ── cumulative-frequency (t4-cumulative-frequency, FAL-726) ──
# The `cumulative-frequency` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/cumulative_frequency.gd. A curve's readings come from the drawn curve in
# the question's figure, a table's from its written rows, never from the situation. Every reading
# must be a corner of the grid, so Paper 1 has one right value.

CF_Q = "SL4.2.cumfreq-quartiles#"
CF_C = "SL4.2.cumfreq-count#"
CF_B = "SL4.2.cumfreq-build#"
CF_SQUARES = 20
# (who, what the curve shows, the axis, the noun, letter, unit, more than, at most, square across, limit)
CF_CTX = [("scavengers", "the hours worked last week by {} scavengers", "hours worked", "hours worked", "h", "hours", "worked more than {} hours", "worked at most {} hours", 2, None),
          ("wells", "the depth of {} wells", "depth (m)", "depth", "d", "m", "are deeper than {} m", "are at most {} m deep", 1, None),
          ("crates", "the mass of {} salvage crates", "mass (kg)", "mass", "m", "kg", "are heavier than {} kg", "are at most {} kg", 5, None),
          ("drones", "the flight time of {} drones", "flight time (minutes)", "flight time", "t", "minutes", "flew for more than {} minutes", "flew for at most {} minutes", 10, None),
          ("patrols", "the distance walked by {} patrols", "distance (km)", "distance", "d", "km", "walked more than {} km", "walked at most {} km", 2, None),
          ("traders", "the takings of {} traders last week", "takings (caps)", "takings", "c", "caps", "took more than {} caps", "took at most {} caps", 20, None),
          ("bean plants", "the height of {} bean plants", "height (cm)", "height", "h", "cm", "are taller than {} cm", "are at most {} cm tall", 5, None),
          ("tanks", "the water held in {} tanks", "water (litres)", "water held", "w", "litres", "hold more than {} litres", "hold at most {} litres", 10, "Each tank holds at most {} litres."),
          ("trucks", "the load carried by {} trucks", "load (kg)", "load", "l", "kg", "carry more than {} kg", "carry at most {} kg", 20, "Each truck can carry at most {} kg.")]


def cf_curve(q, c):
    """(n, dx, dy, points): the figure, held to the grid its scale line describes."""
    who, of, axis, noun, sym, unit, more, most, dx0, _ = c
    gr = q["graph"]
    need(gr is not None and gr["kind"] == "cumfreq", "no cumulative frequency curve")
    mt = re.fullmatch(re.escape("The curve shows " + of).replace(r"\{\}", r"(\d+)") + r"\.", q["lines"][0])
    need(mt is not None, f"can't read {q['lines'][0]!r}")
    n = int(mt.group(1))
    m2 = re.fullmatch(rf"Each small square is (\d+) {unit} across and (\d+) {who} up\.", q["lines"][1])
    need(m2 is not None, f"can't read {q['lines'][1]!r}")
    dx, dy = int(m2.group(1)), int(m2.group(2))
    need(dx == dx0 and n % CF_SQUARES == 0 and dy * CF_SQUARES == n and 40 <= n <= 240, f"n = {n}, dy = {dy}")
    need(gr["dx"] == dx and gr["dy"] == dy and gr["y1"] == n and gr["x1"] == CF_SQUARES * dx, "the grid isn't the one the line describes")
    need(gr["x_name"] == axis and gr["y_name"] == "cumulative frequency", "the axes aren't labelled")
    pts = [(sp.Rational(str(a)), sp.Rational(str(b))) for a, b in gr["curve"]]
    need(pts[0][1] == 0 and pts[-1][1] == n, "the curve doesn't run from 0 to n")
    for (a, b), (e, f) in zip(pts, pts[1:]):
        need(e > a and f > b, "the curve isn't strictly rising")
    return n, dx, dy, pts


def cf_read_x(pts, y, dx, dy):
    """The value at height y: a point of the curve on a corner of the grid."""
    hit = [a for a, b in pts if b == y]
    need(len(hit) == 1, f"the curve has no point at height {y}")
    need(hit[0] % dx == 0 and sp.Rational(y) % dy == 0, f"({hit[0]}, {y}) is not on a corner of the grid")
    return hit[0]


def cf_read_y(pts, x, dx, dy):
    """The height at value x: a point of the curve on a corner of the grid."""
    hit = [b for a, b in pts if a == x]
    need(len(hit) == 1, f"the curve has no point at {x}")
    need(sp.Rational(x) % dx == 0 and hit[0] % dy == 0, f"({x}, {hit[0]}) is not on a corner of the grid")
    return hit[0]


def cf_val(v, c):
    return f"{dec_text(sp.Rational(v))} {c[5]}"


def cf_classes(rows, c, cum_col=None, freq_col=0):
    """Boundaries and the frequencies from a table's written rows; None for a hidden frequency."""
    bs, fs = [], []
    for row in rows[1:]:
        mt = re.fullmatch(rf"(\d+) < {c[4]} ≤ (\d+)", row[0])
        need(mt is not None, f"can't read the class {row[0]!r}")
        a, b = int(mt.group(1)), int(mt.group(2))
        need(not bs or bs[-1] == a, "the classes don't join up")
        bs += [a] if not bs else []
        bs.append(b)
        fs.append(row[1][freq_col])
    w = {bs[i + 1] - bs[i] for i in range(len(bs) - 1)}
    return bs, fs, w


def cf_running(fs):
    out, total = [], 0
    for f in fs:
        total += f
        out.append(total)
    return out


def cf_table(q, c):
    """(n, boundaries, frequencies, running totals) from a table with both columns shown."""
    rows = q["table"]["rows"]
    need(rows[0][1] == ["frequency", "cumulative"], "table heads")
    bs, fs, w = cf_classes(rows, c)
    need(len(w) == 1, "the classes aren't equal")
    fs = [int(f) for f in fs]
    run = cf_running(fs)
    need([r[1][1] for r in rows[1:]] == [str(x) for x in run], "the cumulative column isn't the running total")
    mt = re.fullmatch(re.escape("The table shows " + c[1]).replace(r"\{\}", r"(\d+)") + r"\.", q["lines"][0])
    need(mt is not None and int(mt.group(1)) == run[-1], "the table's total isn't n")
    return run[-1], bs, fs, run


def cf_interp(bs, fs, run, t):
    for j, r in enumerate(run):
        if t <= r:
            before = r - fs[j]
            return bs[j] + sp.Rational((t - before) * (bs[j + 1] - bs[j]), fs[j])
    raise Fail(f"{t} is above the table")


def cf_count(bs, fs, run, v):
    for j in range(len(fs)):
        if v <= bs[j + 1]:
            return run[j] - fs[j] + sp.Rational(fs[j] * (v - bs[j]), bs[j + 1] - bs[j])
    raise Fail(f"{v} is above the table")


def cf_clean(v):
    need((v * 10).q == 1, f"the estimate {v} has more than one decimal")
    return v


def cf_arith(q):
    """Every sum the working writes, worked again."""
    num = r"\d+(?:\.\d+)?"
    for sol in q["solutions"]:
        for st in sol["steps"]:
            for a, b, c, d, e, r in re.findall(rf"({num}) \+ \(({num}) − ({num})\) ÷ ({num}) × ({num}) = ({num})", st):
                need(R(a) + (R(b) - R(c)) / R(d) * R(e) == R(r), f"{st!r}")
            for a, b, r in re.findall(rf"(?<![÷×(] )\b({num}) − ({num}) = ({num})", st):
                need(R(a) - R(b) == R(r), f"{st!r}")
            for a, b, r in re.findall(rf"\b({num}) \+ ({num}) = ({num})", st):
                need(R(a) + R(b) == R(r), f"{st!r}")
            for a, b, r in re.findall(rf"\b({num}) ÷ ({num}) = ({num})", st):
                need(R(a) / R(b) == R(r), f"{st!r}")
            for a, b, r in re.findall(rf"\b({num}) ÷ ({num}) × 100 = ({num})", st):
                need(R(a) / R(b) * 100 == R(r), f"{st!r}")
            for a, b, r in re.findall(rf"\b({num}) × ({num}) = ({num})", st):
                if "÷" not in st:
                    need(R(a) * R(b) == R(r), f"{st!r}")


def cf_near_curve(curve, want):
    return any(abs(a - want[0]) < 1e-9 and abs(b - want[1]) < 1e-9 for a, b in curve)


def cf_pick(q, c):
    """Pick the curve: each card holds the points its mistake says, and only the right one is right."""
    rows = q["table"]["rows"]
    need(rows[0][1] == ["frequency"], "table heads")
    bs, fs, w = cf_classes(rows, c)
    fs = [int(f) for f in fs]
    run = cf_running(fs)
    sets = {"": [(bs[0], 0)] + [(bs[i + 1], run[i]) for i in range(len(fs))],
            "midpoints": [(bs[0], 0)] + [(sp.Rational(bs[i] + bs[i + 1], 2), run[i]) for i in range(len(fs))],
            "frequencies": [(bs[0], 0)] + [(bs[i + 1], fs[i]) for i in range(len(fs))],
            "lower": [(bs[i], run[i]) for i in range(len(fs))]}
    refs = {"": "", "midpoints": CF_B + "0", "frequencies": CF_B + "1", "lower": ""}
    need(sorted(o["mistake"] for o in q["choices"]) == sorted(sets), "the four cards aren't the four curves")
    want = None
    for o, gr in zip(q["choices"], q["graphs"]):
        need(o["ref"] == refs[o["mistake"]], f"the {o['mistake']} graph is mistagged")
        for p in sets[o["mistake"]]:
            need(cf_near_curve(gr["curves"][0], (float(p[0]), float(p[1]))), f"the {o['mistake']!r} card misses {p}")
        need(gr["x_name"] == c[4] and gr["y_name"] == "cf", "the card's axes aren't named")
        if o["correct"]:
            want = o["text"]
    need(q["answer_text"] == want and want is not None, "the right graph isn't the answer")
    return want


def check_cumulative_frequency(q):
    g, u, L, rep, asked = q["given"], q["view"]["unknown"], q["lines"], q["view"]["rep"], q["asked"]
    need(q["paper"] == 1, "cumulative frequency is Paper 1")
    c = CF_CTX[int(g["ctx"])]
    who, of, axis, noun, sym, unit, more, most, dx0, limit = c
    wrongs, want = {}, None
    spread = ", taking each class as evenly spread."
    if u == "pick-curve":
        want = cf_pick(q, c)
        gc_check_common(q, want, {CF_B + "0": {o["text"] for o in q["choices"]}, CF_B + "1": {o["text"] for o in q["choices"]}})
        return None, None
    if rep == "graph":
        n, dx, dy, pts = cf_curve(q, c)
        rx = lambda y: cf_read_x(pts, y, dx, dy)
        ry = lambda x: cf_read_y(pts, x, dx, dy)
        v_more = re.escape(more).replace(r"\{\}", r"(\d+)")
        if u == "median-from-graph":
            need(asked == f"Use the curve to estimate the median {noun}.", f"asked {asked!r}")
            med = rx(sp.Rational(n, 2))
            need(med != 10 * dx, "the median is at the middle of the axis")
            want = "median = " + cf_val(med, c)
            wrongs = {CF_Q + "0": {"median = " + cf_val(10 * dx, c)}}
        elif u == "quartile-from-graph":
            low = "lower quartile" in asked
            want = ("Q1 = " if low else "Q3 = ") + cf_val(rx(sp.Rational(n, 4) * (1 if low else 3)), c)
        elif u == "iqr-from-graph":
            want = "IQR = " + cf_val(rx(sp.Rational(3 * n, 4)) - rx(sp.Rational(n, 4)), c)
            wrongs = {CF_Q + "1": {"IQR = " + cf_val(sp.Rational(n, 2), c)}}
        elif u == "percentile-from-graph":
            k = int(re.match(r"Use the curve to estimate the (\d+)", asked).group(1))
            need(n != 100, "k and k% of n are the same when n is 100")
            want = "percentile = " + cf_val(rx(sp.Rational(k * n, 100)), c)
            wrongs = {CF_Q + "2": {"percentile = " + cf_val(rx(k), c)}}
        elif u == "range-from-graph":
            want = "range = " + cf_val(pts[-1][0] - pts[0][0], c)
        elif u in ("count-below", "count-above", "percent-above", "scale-to-population"):
            if u == "count-below":
                mt = re.fullmatch(rf"Estimate how many {who} " + re.escape(most).replace(r"\{\}", r"(\d+)") + r"\.", asked)
            elif u == "count-above":
                mt = re.fullmatch(rf"Estimate how many {who} {v_more}\.", asked)
            elif u == "percent-above":
                mt = re.fullmatch(rf"Estimate the percentage of the {who} that {v_more}\.", asked)
            else:
                mt = re.fullmatch(rf"Estimate how many of all \d+ {who} {v_more}\.", asked)
            need(mt is not None, f"can't read {asked!r}")
            f = ry(int(mt.group(1)))
            if u == "count-below":
                want = f"number = {f}"
            elif u == "count-above":
                want = f"number = {n - f}"
                wrongs = {CF_C + "0": {f"number = {f}"}}
            elif u == "percent-above":
                p = sp.Rational((n - f) * 100, n)
                need(p.q == 1, "the percentage isn't whole")
                want = f"percentage = {p}%"
                wrongs = {CF_C + "0": {f"percentage = {100 - p}%"}}
            else:
                m2 = re.fullmatch(rf"They were chosen at random from (\d+) {who}\.", L[2])
                need(m2 is not None, f"can't read {L[2]!r}")
                whole = int(m2.group(1))
                need(whole % n == 0 and f"all {whole} " in asked, "the whole group isn't a multiple of the sample")
                want = f"number = {(n - f) * whole // n}"
                wrongs = {CF_C + "0": {f"number = {f * whole // n}"}}
        elif u == "count-between":
            mt = re.fullmatch(rf"Estimate how many {who} are between (\d+) {unit} and (\d+) {unit}\.", asked)
            need(mt is not None, f"can't read {asked!r}")
            want = f"number = {ry(int(mt.group(2))) - ry(int(mt.group(1)))}"
        elif u == "percentile-of-value":
            mt = re.fullmatch(rf"Which percentile of the {noun} is (\d+) {unit}\?", asked)
            need(mt is not None, f"can't read {asked!r}")
            p = sp.Rational(ry(int(mt.group(1))) * 100, n)
            need(p.q == 1, "the percentile isn't whole")
            want = f"percentile = {p}"
        elif u == "cutoff-top":
            mt = re.fullmatch(rf"The (\d+) {who} with the highest {noun} are set aside\.", L[2])
            need(mt is not None, f"can't read {L[2]!r}")
            t = int(mt.group(1))
            want = f"{noun} = " + cf_val(rx(n - t), c)
            wrongs = {CF_C + "1": {f"{noun} = " + cf_val(rx(t), c)}}
        elif u == "cutoff-percent":
            mt = re.fullmatch(r"(\d+)% of the " + who + " " + re.escape(more).replace(r"\{\}", "k") + r"\. Find k\.", asked)
            need(mt is not None, f"can't read {asked!r}")
            t = sp.Rational(int(mt.group(1)) * n, 100)
            want = "k = " + cf_val(rx(n - t), c)
            wrongs = {CF_C + "1": {"k = " + cf_val(rx(t), c)}}
        elif u == "share-of-limit":
            need(limit is not None and L[2] == limit.format(gr_x1 := q["graph"]["x1"]), f"can't read {L[2]!r}")
            mt = re.fullmatch(rf"Estimate how many {who} are above (\d+)% of that limit\.", asked)
            need(mt is not None, f"can't read {asked!r}")
            f = ry(sp.Rational(int(mt.group(1)) * gr_x1, 100))
            need(0 < f < n, "nobody or everybody is above it")
            want = f"number = {n - f}"
            wrongs = {CF_C + "0": {f"number = {f}"}}
        elif u == "frequency-from-graph":
            mt = re.fullmatch(rf"Find the number of {who} in the class (\d+) < {sym} ≤ (\d+)\.", asked)
            need(mt is not None, f"can't read {asked!r}")
            a, b = ry(int(mt.group(1))), ry(int(mt.group(2)))
            want = f"number = {b - a}"
            wrongs = {CF_B + "1": {f"number = {b}"}}
        elif u == "p-q-from-graph":
            need(q["asked"] == "Use the curve to find p and q.", f"asked {asked!r}")
            rows = q["table"]["rows"]
            bs, fs, w = cf_classes(rows, c)
            need(sorted(x for x in fs if x in "pq") == ["p", "q"], "the table doesn't hide p and q")
            vals, tops = {}, {}
            for j, f in enumerate(fs):
                got = ry(bs[j + 1]) - (ry(bs[j]) if j else 0)
                if j == 0:
                    need(bs[0] == pts[0][0], "the first class doesn't start where the curve does")
                if f in "pq":
                    vals[f], tops[f] = got, ry(bs[j + 1])
                else:
                    need(int(f) == got, f"the table's {f} isn't what the curve gives ({got})")
            want = f"p = {vals['p']}, q = {vals['q']}"
            wrongs = {CF_B + "1": {f"p = {tops['p']}, q = {tops['q']}"}}
        else:
            raise Fail(f"no check for {u}")
    elif u == "frequency-from-cf":
        rows = q["table"]["rows"]
        vals = {}
        for row in rows[1:]:
            mt = re.fullmatch(rf"{sym} ≤ (\d+)", row[0])
            need(mt is not None, f"can't read {row[0]!r}")
            vals[int(mt.group(1))] = int(row[1][0])
        keys = list(vals)
        need(all(vals[a] < vals[b] for a, b in zip(keys, keys[1:])) and vals[keys[0]] == 0, "the totals don't rise from 0")
        mt = re.fullmatch(rf"Find the number of {who} in the class (\d+) < {sym} ≤ (\d+)\.", asked)
        a, b = vals[int(mt.group(1))], vals[int(mt.group(2))]
        need(a > 0, "the class is the first one")
        want = f"number = {b - a}"
        wrongs = {CF_B + "1": {f"number = {b}"}}
    elif u == "cf-entry":
        rows = q["table"]["rows"]
        need(asked == "Find the cumulative frequency marked ?.", f"asked {asked!r}")
        fs = [int(r[1][0]) for r in rows[1:]]
        cum = [r[1][1] for r in rows[1:]]
        j = cum.index("?")
        run = cf_running(fs)
        need(j >= 1 and all(cum[i] == str(run[i]) for i in range(j)) and all(x == "–" for x in cum[j + 1:]), "the shown totals are wrong")
        want = f"? = {run[j]}"
        wrongs = {CF_B + "1": {f"? = {fs[j]}"}}
    elif u == "last-frequency":
        rows = q["table"]["rows"]
        fs = [r[1][0] for r in rows[1:]]
        n = int(rows[-1][1][1])
        need(fs.count("p") == 1, "no p")
        want = f"p = {n - sum(int(f) for f in fs if f != 'p')}"
    else:
        n, bs, fs, run = cf_table(q, c)
        val_more = re.escape(more).replace(r"\{\}", r"(\d+)")
        if u == "median-from-table":
            need(asked == f"Estimate the median {noun}{spread}", f"asked {asked!r}")
            want = "median = " + cf_val(cf_clean(cf_interp(bs, fs, run, sp.Rational(n, 2))), c)
            wrongs = {CF_Q + "0": {"median = " + cf_val(sp.Rational(bs[0] + bs[-1], 2), c)}}
        elif u == "quartile-from-table":
            low = "lower quartile" in asked
            want = ("Q1 = " if low else "Q3 = ") + cf_val(cf_clean(cf_interp(bs, fs, run, sp.Rational(n, 4) * (1 if low else 3))), c)
        elif u == "iqr-from-table":
            a, b = cf_interp(bs, fs, run, sp.Rational(n, 4)), cf_interp(bs, fs, run, sp.Rational(3 * n, 4))
            want = "IQR = " + cf_val(cf_clean(b - a), c)
            wrongs = {CF_Q + "1": {"IQR = " + cf_val(sp.Rational(n, 2), c)}}
        elif u == "percentile-from-table":
            k = int(re.match(r"Estimate the (\d+)", asked).group(1))
            need(n != 100, "k and k% of n are the same when n is 100")
            want = "percentile = " + cf_val(cf_clean(cf_interp(bs, fs, run, sp.Rational(k * n, 100))), c)
            wrongs = {CF_Q + "2": {"percentile = " + cf_val(cf_interp(bs, fs, run, k), c)}}
        elif u == "count-below-table":
            mt = re.fullmatch(rf"Estimate how many {who} " + re.escape(most).replace(r"\{\}", r"(\d+)") + re.escape(spread), asked)
            need(mt is not None, f"can't read {asked!r}")
            f = cf_count(bs, fs, run, int(mt.group(1)))
            need(f.q == 1, "the count isn't whole")
            want = f"number = {f}"
        elif u == "count-above-table":
            mt = re.fullmatch(rf"Estimate how many {who} {val_more}" + re.escape(spread), asked)
            need(mt is not None, f"can't read {asked!r}")
            f = cf_count(bs, fs, run, int(mt.group(1)))
            need(f.q == 1, "the count isn't whole")
            want = f"number = {n - f}"
            wrongs = {CF_C + "0": {f"number = {f}"}}
        elif u == "count-between-table":
            mt = re.fullmatch(rf"Estimate how many {who} are between (\d+) {unit} and (\d+) {unit}" + re.escape(spread), asked)
            need(mt is not None, f"can't read {asked!r}")
            a, b = cf_count(bs, fs, run, int(mt.group(1))), cf_count(bs, fs, run, int(mt.group(2)))
            need(a.q == 1 and b.q == 1 and b > a, "the counts aren't whole")
            want = f"number = {b - a}"
        elif u == "cutoff-table":
            mt = re.match(rf"The (\d+) {who} with the highest {noun} are set aside\.", asked)
            need(mt is not None, f"can't read {asked!r}")
            t = int(mt.group(1))
            want = f"{noun} = " + cf_val(cf_clean(cf_interp(bs, fs, run, n - t)), c)
            wrongs = {CF_C + "1": {f"{noun} = " + cf_val(cf_interp(bs, fs, run, t), c)}}
        elif u == "plot-point":
            mt = re.fullmatch(rf"Which point is plotted on the curve for the class (\d+) < {sym} ≤ (\d+)\?", asked)
            need(mt is not None, f"can't read {asked!r}")
            a, b = int(mt.group(1)), int(mt.group(2))
            j = bs.index(b) - 1
            want = f"({b}, {run[j]})"
            wrongs = {CF_B + "0": {f"({dec_text(sp.Rational(a + b, 2))}, {run[j]})"}, CF_B + "1": {f"({b}, {fs[j]})"}}
        elif u == "curve-start":
            need(bs[0] > 0, "the curve starts at the origin, so (0, 0) is no wrong option")
            want = f"({bs[0]}, 0)"
        else:
            raise Fail(f"no check for {u}")
    gc_check_common(q, want, wrongs)
    cf_arith(q)
    return None, None


# ── arc-sector (t3-arc-sector, FAL-726) ──────────────────────
# The `arc-sector` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/arc_sector.gd. r, θ, the arc, the area and the perimeter are read back
# from the lines or the figure, and each answer is worked out from those alone, exactly, or to
# 40 digits where it holds a root. A figure is held to its real angle.

AS_SKILL = "SL3.4."
AS_EDGE = sp.Rational(29, 1000)         # the engine's is 0.03
AS_DEN = 24
AS_R1 = (2, 12)
AS_DEG_P1 = {30, 45, 60, 90, 120, 135, 150, 210, 225, 240, 270, 300}


def as_val(text):
    """An exact value as the game writes it: "12 + 3π", "9π − 4.5", "5π/6", "7.5", "1/6"."""
    t = text.strip().replace("−", "-")
    t = re.sub(r"(\d)π", r"\1*pi", t).replace("π", "pi")
    return sp.nsimplify(sp.sympify(t, rational=True), rational=True) if "pi" not in t else sp.sympify(t, rational=True)


def as_pair(v):
    """a and b of a + bπ."""
    e = sp.expand(v)
    b = e.coeff(sp.pi)
    a = e - b * sp.pi
    need(a.is_Rational and b.is_Rational, f"{v} is not a + bπ")
    return a, b


def as_pi(b):
    n, d = abs(b.p), b.q
    return ("−" if b < 0 else "") + ("π" if n == 1 else f"{n}π") + ("" if d == 1 else f"/{d}")


def as_exact(v):
    a, b = as_pair(v)
    if b == 0:
        return dec_text(a)
    if a == 0:
        return as_pi(b)
    if a < 0:
        return f"{as_pi(b)} − {dec_text(-a)}"
    return f"{dec_text(a)} + {as_pi(b)}"


def as_text(label, v, tail, paper):
    return label + (as_exact(v) if paper == 1 else rg_s(sp.N(v, 40))) + tail


def as_clear(x):
    v = abs(num(x))
    e = sp.floor(sp.log(v, 10))
    scaled = v / sp.Integer(10) ** (e - 2)
    return abs(scaled - sp.floor(scaled) - sp.Rational(1, 2)) >= AS_EDGE


def as_read(q):
    """r, θ in radians and as written, the arc, the area and the perimeter, and the unit."""
    L, rep = q["lines"], q["view"]["rep"]
    k = {"r": None, "th": None, "tt": None, "form": None, "l": None, "a": None, "p": None, "unit": " cm"}

    def angle(text, deg):
        k["tt"] = text
        k["form"] = "deg" if deg else ("pi" if "π" in text else "rad")
        v = as_val(text)
        k["th"] = v * sp.pi / 180 if deg else v
        if deg:
            k["deg"] = v

    def plain(text):
        return as_val(text)

    if rep == "equation":
        for ln in L:
            if ln == "Sector OAB has centre O.":
                continue
            m = re.fullmatch(r"r = (\S+) cm", ln)
            if m:
                k["r"] = plain(m.group(1))
                continue
            m = re.fullmatch(r"θ = (\S+?)(°| radians)", ln)
            if m:
                angle(m.group(1), m.group(2) == "°")
                continue
            m = re.fullmatch(r"(arc AB|area|perimeter) = (.+?) cm(²?)", ln)
            need(m is not None, f"can't read {ln!r}")
            k[{"arc AB": "l", "area": "a", "perimeter": "p"}[m.group(1)]] = plain(m.group(2))
        return k
    if rep == "words":
        text = " ".join(L)
        m = re.search(r"has a reach of ([\d.]+) (cm|km|m)\b", text)
        if m:
            k["r"] = plain(m.group(1))
            k["unit"] = " " + m.group(2)
        m = re.search(r"(?:with an angle of|a gap with an angle of) (\S+?)(°| radians) at the centre", text)
        if m:
            angle(m.group(1), m.group(2) == "°")
        for key, pat in (("l", r"The curved edge of the sector is (.+?) (cm|km|m) long\."), ("a", r"The area of the sector is (.+?) (cm|km|m)²\."),
                         ("p", r"The perimeter of the sector is (.+?) (cm|km|m)\.")):
            m = re.search(pat, text)
            if m:
                k[key] = plain(m.group(1))
                k["unit"] = " " + m.group(2)
        return k
    g = q["graph"]
    if q["view"]["unknown"] == "segments-theta":
        return k
    need(g is not None and g["kind"] == "sector", "no sector drawn")
    k["fig"] = g
    if g["r_label"] not in ("", "r"):
        k["r"] = plain(g["r_label"].removesuffix(" cm"))
    if g["angle_label"] not in ("", "θ"):
        t = g["angle_label"]
        angle(t.rstrip("°"), t.endswith("°"))
    if g["arc_label"]:
        k["l"] = plain(g["arc_label"].removesuffix(" cm"))
    for ln in L:
        m = re.fullmatch(r"The area of the sector is (.+) cm²\.", ln)
        if m:
            k["a"] = plain(m.group(1))
        m = re.fullmatch(r"The perimeter of the sector is (.+) cm\.", ln)
        if m:
            k["p"] = plain(m.group(1))
    return k


def as_figure(k, th):
    """The sector is drawn to the angle of the question."""
    g = k.get("fig")
    if g is not None:
        need(abs(sp.Float(g["theta"], 30) - sp.N(th, 30)) < sp.Rational(1, 10**6), f"the figure's angle {g['theta']} is not {th}")


def as_limits(q, k):
    """Paper 1 numbers are simple; Paper 2 numbers are to 1 or 2 places."""
    r, paper = k["r"], q["paper"]
    if r is not None:
        if paper == 1:
            need(r.q == 1 and AS_R1[0] <= r <= AS_R1[1], f"r = {r} on Paper 1")
        else:
            need((r * 10).q == 1, f"r = {r} is not to 1 d.p.")
    th = k["th"]
    if th is not None:
        need(0 < sp.N(th) < 2 * sp.pi, f"θ = {th}")
        if paper == 1 and k["form"] == "deg":
            need(k["deg"] in AS_DEG_P1, f"{k['deg']}° is no landmark")
        if paper == 2 and k["form"] == "deg":
            need(k["deg"] % 15 != 0, f"{k['deg']}° needs no calculator")


def as_eval(text):
    t = text.strip()
    if not t or not re.search(r"\d", t):
        return None
    t = t.replace("½", "(1/2)").replace("²", "**2").replace("×", "*").replace("÷", "/").replace("−", "-")
    t = re.sub(r"√(\d+(?:\.\d+)?)", r"sqrt(\1)", t)
    t = re.sub(r"(\d+(?:\.\d+)?)?π(?:/(\d+))?", lambda m: f"(({m.group(1) or 1})*pi/{m.group(2) or 1})", t)
    t = re.sub(r"(\d|\))\s*\(", r"\1*(", t)
    try:
        return sp.sympify(t, rational=True)
    except (sp.SympifyError, SyntaxError, TypeError):
        return None


def as_working(q):
    """Each "expr = value" whose two sides are plain numbers holds for the figures shown."""
    n = 0
    for sol in q["solutions"]:
        for st in sol["steps"]:
            parts = st.split(" = ")
            for left, right in zip(parts, parts[1:]):
                lm = re.search(r"[\d.π×÷+−/²()½√ °]+$", left)
                rm = re.match(r"[\d.π/ +−×÷²()½]+", right.strip())
                if lm is None or rm is None:
                    continue
                lt = lm.group().replace("°", "")
                if not re.search(r"[×÷+−/²½√π]", lt):
                    continue
                lv, rv = as_eval(lt), as_eval(rm.group().rstrip(" +−"))
                if lv is None or rv is None:
                    continue
                shown = rm.group().strip()
                if q["paper"] == 1 or re.search(r"[π/×÷²]", shown):
                    ok = abs(sp.N(lv - rv, 30)) < sp.Rational(1, 10**20)
                else:
                    d = len(shown.split(".")[1]) if "." in shown else 0
                    ok = abs(sp.N(lv - rv, 30)) <= sp.Rational(6, 10) * sp.Rational(1, 10**d)
                need(ok, f"{sol['name']}: in {st!r}, {lt.strip()} is {sp.N(lv, 10)}, not {shown}")
                n += 1
    return n


def as_plate_root(goal, deg=False):
    """θ with θ − sin θ = goal on (0, 2π), by halving (it only rises)."""
    lo, hi = mpmath.mpf(0), 2 * mpmath.pi
    for _ in range(140):
        mid = (lo + hi) / 2
        if mid - mpmath.sin(mpmath.radians(mid) if deg else mid) < goal:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def check_arc_sector(q):
    with mpmath.workdps(40):
        return as_check(q)


def as_check(q):
    u, L, rep, asked, paper = q["view"]["unknown"], q["lines"], q["view"]["rep"], q["asked"], q["paper"]
    k = as_read(q)
    r, th, l, a, p, un = k["r"], k["th"], k["l"], k["a"], k["p"], k["unit"]
    un2 = un + "²"
    wr = {}
    pi = sp.pi

    def W(ref, label, tail, v):
        if sp.N(v) > 0:
            wr.setdefault(AS_SKILL + ref, set()).add(as_text(label, v, tail, paper))

    label, tail, v = None, "", None
    if u == "deg-to-rad":
        d = k["deg"]
        label, v = "θ = ", d * pi / 180
        need(paper == 2 or (d % 30 == 0 or d % 45 == 0), f"{d}° is no landmark")
        if paper == 1:
            wr[AS_SKILL + "convert#0"] = {"θ = " + sig3(d * 180 / pi)}
            wr[AS_SKILL + "convert#2"] = {"θ = " + sig3(v)}
        else:
            W("convert#0", label, "", d * 180 / pi)
    elif u == "rad-to-deg":
        label, tail, v = "θ = ", "°", th * 180 / pi
        if paper == 1:
            need(k["form"] == "pi", "Paper 1 converts a multiple of π")
            wr[AS_SKILL + "convert#1"] = {f"θ = {sig3(th)}°"}
        else:
            wr[AS_SKILL + "convert#1"] = {f"θ = {sig3(th)}°"}
    elif u == "arc-length":
        label, tail, v = "l = ", un, r * th
        if k["form"] == "deg":
            W("arc-length#0", label, tail, r * k["deg"])
    elif u == "perimeter":
        label, tail, v = "P = ", un, 2 * r + r * th
        W("arc-length#1", label, tail, r * th)
        if k["form"] == "deg":
            W("arc-length#0", label, tail, 2 * r + r * k["deg"])
    elif u == "theta-from-arc":
        label, v = "θ = ", l / r
    elif u == "r-from-arc":
        label, tail, v = "r = ", un, l / th
    elif u == "r-from-perimeter":
        label, tail, v = "r = ", un, p / (2 + th)
        W("arc-length#1", label, tail, p / th)
    elif u == "theta-from-perimeter":
        label, v = "θ = ", (p - 2 * r) / r
        W("arc-length#1", label, "", p / r)
    elif u == "major-arc":
        label, tail, v = "l = ", un, r * (2 * pi - th)
        need(sp.N(th) < sp.N(pi), "the given angle is not the minor angle")
        W("arc-length#2", label, tail, r * th)
    elif u == "r-in-terms-of-theta":
        if rep == "words":
            mt = re.search(r"is ([\d.]+) (cm|km|m) long", L[0])
        else:
            mt = re.fullmatch(r"([\d.]+) (cm)", k["fig"]["arc_label"])
        need(mt is not None, "can't read the arc")
        ls = mt.group(1)
        want = f"r = {dec_text(R(ls))}/θ"
        gc_check_common(q, want, {})
        return None, None
    elif u == "theta-from-bent-strip":
        mt = re.fullmatch(r"A water trough is bent from a strip of tin ([\d.]+) cm wide\. Across the strip it has a straight side ([\d.]+) cm long, a curved part, then another straight side ([\d.]+) cm long\.", L[0])
        need(mt is not None and mt.group(2) == mt.group(3), f"can't read {L[0]!r}")
        mr = re.fullmatch(r"The curved part is an arc of a circle of radius ([\d.]+) cm\.", L[1])
        need(mr is not None, f"can't read {L[1]!r}")
        label, v = "θ = ", (R(mt.group(1)) - 2 * R(mt.group(2))) / R(mr.group(1))
    elif u == "sector-area":
        label, tail, v = "A = ", un2, r**2 * th / 2
        if k["form"] == "deg":
            W("sector-area#0", label, tail, r**2 * k["deg"] / 2)
        slip = r * th**2 / 2
        if paper == 2 or k["form"] == "rad":
            W("sector-area#1", label, tail, slip)
        else:
            b = sp.expand(slip / pi**2)
            wr[AS_SKILL + "sector-area#1"] = {f"A = {frac_text(b)}π²{un2}"}
    elif u == "theta-from-area":
        label, v = "θ = ", 2 * a / r**2
    elif u == "r-from-area":
        label, tail, v = "r = ", un, sp.sqrt(2 * a / th)
    elif u == "major-sector":
        label, tail, v = "A = ", un2, r**2 * (2 * pi - th) / 2
        need(sp.N(th) < sp.N(pi), "the given angle is not the minor angle")
        W("sector-area#2", label, tail, r**2 * th / 2)
    elif u == "area-from-arc":
        label, tail, v = "A = ", un2, r * l / 2
    elif u == "perimeter-from-area":
        rr = sp.sqrt(2 * a / th)
        label, tail, v = "P = ", un, rr * (2 + th)
    elif u == "major-from-perimeter":
        mt = re.fullmatch(r"The diagram shows a circle with centre O\. Angle AOB is ([\d.]+) radians, and the perimeter of the small shaded sector is ([\d.]+) cm\.", L[0])
        need(mt is not None, f"can't read {L[0]!r}")
        t0, per = R(mt.group(1)), R(mt.group(2))
        th = t0
        k["th"] = None
        rr = per / (2 + t0)
        label, tail, v = "A = ", un2, rr**2 * (2 * pi - t0) / 2
        W("sector-area#2", label, tail, rr**2 * t0 / 2)
    elif u == "cone-radius":
        if rep == "words":
            mt = re.fullmatch(r"A sheet of tin is cut into a sector of radius ([\d.]+) cm and angle (\S+?)(°| radians)\. Its two straight edges are joined to make a funnel, with the arc as the rim\.", L[0].replace(" m ", " cm ").replace(" km ", " cm "))
            need(mt is not None, f"can't read {L[0]!r}")
            r = R(mt.group(1))
            d = as_val(mt.group(2))
            th = d * pi / 180 if mt.group(3) == "°" else d
            un = re.search(r"radius [\d.]+( \w+) and", L[0]).group(1)
        else:
            need(k["fig"].get("cone") is True, "the cone isn't drawn")
        label, tail, v = "radius = ", un, r * th / (2 * pi)
        if paper == 1:
            need(v.is_Rational, f"radius {v}")
    elif u in ("ring-inner-radius", "ring-perimeter"):
        need(paper == 2, "a curved strip is Paper 2")
        g = q["graph"]
        need(g is not None and g["kind"] == "sector" and g["inner"] > 0, "no curved strip drawn")
        mt = re.search(r"The reflex angle at O is ([\d.]+) radians, the outer radius is ([\d.]+) cm and the inner radius is (r cm|[\d.]+ cm)\.", L[0])
        need(mt is not None, f"can't read {L[0]!r}")
        t0, big = R(mt.group(1)), R(mt.group(2))
        need(t0 > 3 and t0 < 2 * pi, "the angle is not reflex")
        need(g["angle_label"] == mt.group(1) and g["r_label"] == mt.group(2) + " cm", "the figure's labels")
        as_figure({"fig": g}, t0)
        if u == "ring-inner-radius":
            ma = re.fullmatch(r"The area of the strip is ([\d.]+) cm²\.", L[1])
            need(ma is not None, f"can't read {L[1]!r}")
            ar = R(ma.group(1))
            label, tail, v = "r = ", " cm", sp.sqrt(big**2 - 2 * ar / t0)
            need(0 < sp.N(v) < big, f"r = {sp.N(v)}")
        else:
            small = R(mt.group(3).removesuffix(" cm"))
            label, tail, v = "P = ", " cm", t0 * (big + small) + 2 * (big - small)
        th = None
    elif u == "segments-theta":
        need(paper == 2, "a plate is Paper 2")
        g = q["graph"]
        need(g is not None and g["kind"] == "plate", "no plate drawn")
        mt = re.fullmatch(r"A steel plate is a rectangle (\d+) cm by (\d+) cm\. An equal segment is cut from each of two opposite edges, as in the diagram\.", L[0])
        mr = re.fullmatch(r"Each segment is part of a circle of radius (\d+) cm, with angle θ at its centre O, where θ is in radians and 0 < θ < π\.", L[1])
        ma = re.fullmatch(r"The area of the plate that is left is ([\d.]+) cm²\.", L[2])
        need(mt and mr and ma, "can't read the plate")
        w, h, rho, ar = int(mt.group(1)), int(mt.group(2)), int(mr.group(1)), R(ma.group(1))
        need(g["w"] == w and g["h"] == h and g["rho"] == rho, "the plate drawn is another plate")
        goal = mpmath.mpf((w * h - ar).p) / (w * h - ar).q / rho**2
        root = as_plate_root(goal)
        need(0 < root < mpmath.pi, f"θ = {root}")
        chord = 2 * rho * mpmath.sin(root / 2)
        need(chord < h, "the cut is longer than the edge")
        need(abs(g["theta"] - float(root)) < 1e-6, "the figure's angle")
        v = nu_f(root)
        label = "θ = "
        wr[AS_SKILL + "segment-shaded#0"] = {"θ = " + rg_s(nu_f(as_plate_root(goal, True)))}
        th = None
    else:
        raise Fail(f"no check for {u}")
    # What the question drew or said matches the angle, once the angle is known.
    if u in ("theta-from-arc", "theta-from-perimeter", "theta-from-area"):
        as_figure(k, v)
    elif u == "area-from-arc":
        as_figure(k, l / r)
    elif u in ("r-from-arc", "r-from-perimeter", "r-from-area", "perimeter-from-area", "arc-length", "perimeter", "sector-area", "deg-to-rad", "rad-to-deg", "major-arc", "major-sector", "cone-radius"):
        if th is not None:
            as_figure(k, th)
    as_limits(q, k)
    trap = None
    if paper == 1:
        a0, b0 = as_pair(v)
        need(a0.q <= AS_DEN and b0.q <= AS_DEN, f"{v} has a big denominator")
        if b0 != 0:
            need(asked.endswith(" Give your answer in terms of π."), f"asked {asked!r}")
        if u in ("r-from-arc", "r-from-perimeter", "r-from-area"):
            need(v.is_integer, f"r = {v} is not whole on Paper 1")
    else:
        need(asked.endswith(" Give your answer to 3 significant figures."), f"asked {asked!r}")
        x = sp.N(v, 40)
        need(as_clear(x), f"{x} is on a rounding edge")
        t2 = bn_trap(label, x)
        trap = t2 + tail if t2 else None
    want = as_text(label, v, tail, paper)
    gc_check_common(q, want, wr, trap)
    as_working(q)
    return None, None


# ── bearings-elevation (t3-bearings-elevation, FAL-726) ──────
# Reads the distances, bearings and angles back from the lines and works each answer out again
# with mpmath at 40 digits. A sketch is held to the story: each length to one scale, each bearing
# and angle to the points drawn.

BE_SKILL = "SL3.3."
BE_EDGE = sp.Rational(29, 1000)         # the engine's is 0.03


def be_c(d):
    return mpmath.cos(mpmath.radians(d))


def be_s(d):
    return mpmath.sin(mpmath.radians(d))


def be_t(d):
    return mpmath.tan(mpmath.radians(d))


def be_mp(x):
    x = sp.Rational(x)
    return mpmath.mpf(x.p) / x.q


def be_text(label, x, tail=""):
    return label + rg_s(nu_f(x)) + tail


def be_bearing(b):
    return f"{int(b) % 360:03d}°"


def be_angle(p, a, b):
    """The angle at p between the directions to a and b, in degrees."""
    u = (a[0] - p[0], a[1] - p[1])
    v = (b[0] - p[0], b[1] - p[1])
    dot = u[0] * v[0] + u[1] * v[1]
    return mpmath.degrees(mpmath.acos(dot / (mpmath.hypot(*u) * mpmath.hypot(*v))))


def be_clear(x):
    v = abs(num(nu_f(x)))
    if v == 0:
        return True
    e = sp.floor(sp.log(v, 10))
    scaled = v / sp.Integer(10) ** (e - 2)
    return abs(scaled - sp.floor(scaled) - sp.Rational(1, 2)) >= BE_EDGE


def be_figure(q, to_scale=True):
    """Every label on the sketch says what the points drawn say."""
    g = q["graph"]
    need(g is not None and g["kind"] == "sketch", "no sketch")
    pts = {n: tuple(mpmath.mpf(c) for c in p) for n, p in g["pts"].items()}
    scale = None
    for ln in g["lines"]:
        m = re.fullmatch(r"([\d.]+) (km|m)", ln["label"])
        if m and to_scale:
            d = mpmath.hypot(pts[ln["a"]][0] - pts[ln["b"]][0], pts[ln["a"]][1] - pts[ln["b"]][1])
            ratio = d / be_mp(R(m.group(1)))
            scale = scale if scale is not None else ratio
            need(abs(ratio / scale - 1) < mpmath.mpf(10) ** -6, f"{ln['a']}{ln['b']} is not to scale")
    for a in g["arcs"]:
        if a["label"] == "?" or not to_scale:
            continue
        p, to = pts[a["at"]], pts[a["to"]]
        if a["from"] == "N":
            b = mpmath.degrees(mpmath.atan2(to[0] - p[0], to[1] - p[1])) % 360
            need(a["at"] in g["north"], f"no north line at {a['at']}")
            need(abs(b - int(a["label"].rstrip("°"))) < mpmath.mpf("1e-5"), f"the bearing {a['label']} isn't drawn ({b})")
        elif a["label"].endswith("°"):
            ang = be_angle(p, pts[a["from"]], to)
            need(abs(ang - be_mp(R(a["label"].rstrip("°")))) < mpmath.mpf("1e-5"), f"the angle {a['label']} isn't drawn ({ang})")
    return pts


def be_journey(L):
    m1 = re.fullmatch(r".+ leaves camp A and travels ([\d.]+) km on a bearing of (\d{3})° to a well at B\.", L[0])
    m2 = re.fullmatch(r"It then travels ([\d.]+) km on a bearing of (\d{3})° to a depot at C\.", L[1])
    need(m1 and m2, f"can't read {L[:2]!r}")
    return R(m1.group(1)), int(m1.group(2)), R(m2.group(1)), int(m2.group(2))


def be_angle_read(text):
    """An angle of elevation or depression in radians, and its size."""
    m = re.search(r"(?:elevation|depression)[^.]*? is ([\d.]+)(°| radians)", text)
    need(m is not None, f"can't read an angle in {text!r}")
    v = be_mp(R(m.group(1)))
    return (mpmath.radians(v), True) if m.group(2) == "°" else (v, False)


def check_bearings(q):
    with mpmath.workdps(40):
        return be_check(q)


def be_check(q):
    u, L, rep, asked = q["view"]["unknown"], q["lines"], q["view"]["rep"], q["asked"]
    need(q["paper"] == 2, "these are Paper 2")
    text = " ".join(L)
    wr = {}
    pi = mpmath.pi
    tan, sin, cos = mpmath.tan, mpmath.sin, mpmath.cos
    label, tail, x, want = None, "", None, None

    def W(ref, val):
        wr.setdefault(BE_SKILL + ref, set()).add(be_text(label, val, tail))

    if rep == "words":
        need(q["graph"] is None, "words have no sketch")
    scaled = True
    if u == "back-bearing":
        m = re.fullmatch(r"From a camp at A, a tower at B is on a bearing of (\d{3})°\.", L[0])
        need(m is not None and asked == "Find the bearing of A from B.", f"{L[0]!r}")
        b = int(m.group(1))
        want = "bearing = " + be_bearing(b + 180)
        wr[BE_SKILL + "bearings#1"] = {"bearing = " + be_bearing(b)}
        wr[BE_SKILL + "bearings#0"] = {"bearing = " + be_bearing(360 - b)}
    elif u == "angle-from-bearing":
        m = re.search(r"due east.*on a bearing of (\d{3})°\. Angle ABC is (\d+)°\.", text)
        need(m is not None, f"{text!r}")
        b, phi = int(m.group(1)), int(m.group(2))
        want = f"angle ACB = {180 - (90 - b) - phi}°"
        wr[BE_SKILL + "bearings#2"] = {f"angle ACB = {180 - b - phi}°"}
    elif u in ("two-leg-distance", "two-leg-bearing", "return-bearing"):
        d1, b1, d2, b2 = be_journey(L)
        need((d1 * 10).q == 1 and (d2 * 10).q == 1, "distances to 1 d.p.")
        d1m, d2m = be_mp(d1), be_mp(d2)
        e = d1m * be_s(b1) + d2m * be_s(b2)
        n = d1m * be_c(b1) + d2m * be_c(b2)
        if u == "two-leg-distance":
            label, tail, x = "distance = ", " km", mpmath.hypot(e, n)
            t = abs(b2 - b1)
            t = 360 - t if t > 180 else t
            need(30 <= t <= 150, f"the turn is {t}°")
            # The same distance from the cosine rule, with the angle inside.
            again = mpmath.sqrt(d1m**2 + d2m**2 - 2 * d1m * d2m * be_c(180 - t))
            need(abs(again - x) < mpmath.mpf(10) ** -25, "the cosine rule disagrees with the components")
            W("bearings#2", mpmath.sqrt(d1m**2 + d2m**2 - 2 * d1m * d2m * be_c(t)))
        else:
            there = mpmath.degrees(mpmath.atan2(e, n)) % 360
            label, tail = "bearing = ", "°"
            if u == "two-leg-bearing":
                x = there
                W("bearings#1", (there + 180) % 360)
                W("bearings#0", 360 - there)
            else:
                x = (there + 180) % 360
                W("bearings#1", there)
            need(100 <= x < 360, f"a bearing of {x} isn't three figures at 3 s.f.")
    elif u == "due-east-distance":
        m = re.search(r"An outpost B is ([\d.]+) km due east of a camp at A\. A signal fire at C is ([\d.]+) km from A, on a bearing of (\d{3})°\.", text)
        need(m is not None, f"{text!r}")
        ab, ac, b = be_mp(R(m.group(1))), be_mp(R(m.group(2))), int(m.group(3))
        label, tail = "BC = ", " km"
        x = mpmath.sqrt(ab**2 + ac**2 - 2 * ab * ac * be_c(90 - b))
        W("bearings#2", mpmath.sqrt(ab**2 + ac**2 - 2 * ab * ac * be_c(b)))
    elif u == "sine-rule-distance":
        m = re.search(r"An outpost B is ([\d.]+) km due east of a camp at A\. From A, a signal fire at C is on a bearing of (\d{3})°\. Angle ABC is (\d+)°\.", text)
        wh = re.fullmatch(r"Find the distance (AC|BC)\. Give your answer to 3 significant figures\.", asked)
        need(m and wh, f"{text!r} {asked!r}")
        ab, b, phi = be_mp(R(m.group(1))), int(m.group(2)), int(m.group(3))
        at_a = 90 - b
        c = 180 - at_a - phi
        opp = phi if wh.group(1) == "AC" else at_a
        label, tail = wh.group(1) + " = ", " km"
        x = ab * be_s(opp) / be_s(c)
        W("bearings#2", ab * be_s(phi if wh.group(1) == "AC" else b) / be_s(180 - b - phi))
    elif u == "due-west-side":
        m = re.search(r"AC = ([\d.]+) m, the bearing of B from A is (\d{3})° and angle BAC is (\d+)°\.", text)
        need(m is not None, f"{text!r}")
        ac, b, phi = be_mp(R(m.group(1))), int(m.group(2)), int(m.group(3))
        # From coordinates, not from the angle chase: A at the origin, BC on a line due west.
        c = (ac * be_s(b + phi), ac * be_c(b + phi))
        ab = c[1] / be_c(b)
        bpt = (ab * be_s(b), ab * be_c(b))
        need(abs(bpt[1] - c[1]) < mpmath.mpf(10) ** -25 and c[0] < bpt[0] and c[1] < 0, "C is not due west of B")
        label, tail, x = "BC = ", " m", bpt[0] - c[0]
    elif u == "height-from-elevation":
        m = re.search(r"([\d.]+) m from the foot", text)
        t, deg = be_angle_read(text)
        label, tail, x = "height = ", " m", be_mp(R(m.group(1))) * tan(t)
    elif u == "distance-from-depression":
        m = re.search(r"From the top T of a .+? ([\d.]+) m high", text)
        t, deg = be_angle_read(text)
        h = be_mp(R(m.group(1)))
        label, tail, x = "distance = ", " m", h / tan(t)
        W("elevation-depression#1", h * tan(t))
    elif u == "angle-of-depression":
        m = re.search(r"From the top T of a .+? ([\d.]+) m high", text)
        m2 = re.search(r"P is ([\d.]+) m from the foot", text)
        h, d = be_mp(R(m.group(1))), be_mp(R(m2.group(1)))
        label, tail, x = "angle = ", "°", mpmath.degrees(mpmath.atan(h / d))
        W("elevation-depression#0", mpmath.degrees(mpmath.atan(d / h)))
    elif u == "height-with-eye-level":
        m = re.search(r"eyes are ([\d.]+) m above the level ground stands ([\d.]+) m from", text)
        t, deg = be_angle_read(text)
        eye, d = be_mp(R(m.group(1))), be_mp(R(m.group(2)))
        label, tail, x = "height = ", " m", eye + d * tan(t)
        W("elevation-depression#2", d * tan(t))
    elif u == "chain-below-hook":
        m = re.search(r"([\d.]+) m from the foot of a crane", text)
        m2 = re.search(r"A guard ([\d.]+) m tall stands under it, and the hook on the chain is ([\d.]+) m above", text)
        t, deg = be_angle_read(text)
        d, eye, gp = be_mp(R(m.group(1))), be_mp(R(m2.group(1))), be_mp(R(m2.group(2)))
        label, tail, x = "length = ", " m", d * tan(t) - eye - gp
        need(x > 0, "the chain has no length")
        W("elevation-depression#2", d * tan(t) - gp)
    elif u == "time-from-depression":
        m = re.search(r"From the top of a .+? ([\d.]+) m high", text)
        m2 = re.search(r"at (\d+) km/h", text)
        t, deg = be_angle_read(text)
        h, v = be_mp(R(m.group(1))), int(m2.group(1))
        label, tail, x = "time = ", " minutes", h / tan(t) / 1000 / v * 60
        W("elevation-depression#1", h * tan(t) / 1000 / v * 60)
        scaled = False
    elif u == "route-time":
        m = re.search(r"PB = ([\d.]+) km\. A camp at A is ([\d.]+) km from P", text)
        m2 = re.search(r"at (\d+) km/h, and a truck drives along the road at (\d+) km/h", text)
        b, a = be_mp(R(m.group(1))), be_mp(R(m.group(2)))
        v1, v2 = int(m2.group(1)), int(m2.group(2))
        label, tail = "time = ", " hours"
        x = mpmath.hypot(a, b) / v1 if "straight across" in asked else a / v1 + b / v2
    elif u == "shared-side":
        m = re.search(r"AB = ([\d.]+) km, AD = ([\d.]+) km and angle BAD = 90°\. BC = ([\d.]+) km and angle DBC = (\d+)°", text)
        ab, ad, bc, phi = [be_mp(R(m.group(i))) for i in (1, 2, 3, 4)]
        bd = mpmath.hypot(ab, ad)
        label, tail, x = "CD = ", " km", mpmath.sqrt(bd**2 + bc**2 - 2 * bd * bc * mpmath.cos(mpmath.radians(phi)))
        rough = be_mp(R(sig3(nu_f(bd), 2)))
        W("multi-triangle#0", mpmath.sqrt(rough**2 + bc**2 - 2 * rough * bc * mpmath.cos(mpmath.radians(phi))))
        W("multi-triangle#1", mpmath.hypot(bd, bc))
    elif u == "quadrilateral-area":
        m = re.search(r"AB = ([\d.]+) km, AD = ([\d.]+) km and angle BAD = (\d+)°\. BC = ([\d.]+) km and angle DBC = (\d+)°", text)
        ab, ad, a0, bc, phi = [be_mp(R(m.group(i))) for i in range(1, 6)]
        bd = mpmath.sqrt(ab**2 + ad**2 - 2 * ab * ad * mpmath.cos(mpmath.radians(a0)))
        label, tail = "area = ", " km²"
        x = ab * ad * mpmath.sin(mpmath.radians(a0)) / 2 + bd * bc * mpmath.sin(mpmath.radians(phi)) / 2
    elif u == "perpendicular-split":
        m = re.search(r"to a depot B, ([\d.]+) km away\. A well at C is ([\d.]+) km from A, and angle BAC is (\d+)°\.", text)
        ab, ac, phi = be_mp(R(m.group(1))), be_mp(R(m.group(2))), int(m.group(3))
        label, tail = "BC = ", " km"
        x = mpmath.sqrt(ab**2 + ac**2 - 2 * ab * ac * be_c(phi))
        W("multi-triangle#1", mpmath.hypot(ab, ac))
        need(phi != 90, "the angle is a right angle")
    elif u == "rule-to-use":
        sas = re.fullmatch(r"In triangle PQR, PQ = \d+ km, PR = \d+ km and angle QPR = \d+°\.", L[0])
        sss = re.fullmatch(r"In triangle PQR, PQ = \d+ km, PR = \d+ km and QR = \d+ km\.", L[0])
        aas = re.fullmatch(r"In triangle PQR, PQ = \d+ km, angle QPR = \d+° and angle PQR = \d+°\.", L[0])
        rt = re.fullmatch(r"In triangle PQR, angle PQR = 90°, PQ = \d+ km and angle QPR = \d+°\.", L[0])
        need(sum(1 for z in (sas, sss, aas, rt) if z) == 1, f"can't read {L[0]!r}")
        want = "The sine rule" if aas else ("A right-angle ratio such as tan" if rt else "The cosine rule")
        if sas or sss:
            wr[BE_SKILL + "multi-triangle#2"] = {"The sine rule"}
    else:
        raise Fail(f"no check for {u}")
    trap = None
    if x is not None:
        need(x > 0 and be_clear(x), f"{x} is on a rounding edge")
        need(asked.endswith(" Give your answer to 3 significant figures."), f"asked {asked!r}")
        want = be_text(label, x, tail)
        t2 = bn_trap(label, nu_f(x))
        trap = t2 + tail if t2 else None
    gc_check_common(q, want, wr, trap)
    if rep == "diagram":
        be_figure(q, scaled)
    for sol in q["solutions"]:
        tri_working(q, sol)
    return None, None


# ── solid (t3-solid-volume-area, FAL-726) ────────────────────
# The `solid` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/solid.gd. Each question's measures are read back from its sketch or its
# sentences, the shape from its opening line, and every value is worked out again with exact
# rationals and π. The working's arithmetic is evaluated wherever a step is plain numbers.

SD_EDGE = sp.Rational(29, 1000)         # the engine's is 0.03
SD_V = "SL3.1.volume-solids#"
SD_S = "SL3.1.surface-area#"
SD_SHAPES = {"a right cone": "cone", "a right pyramid": "pyramid", "a solid sphere": "sphere", "a solid hemisphere": "hemisphere",
             "a solid made of a cone on a hemisphere with the same radius": "cone-hemisphere",
             "a solid made of a cone on a cylinder with the same radius": "cone-cylinder",
             "a solid made of a hemisphere on a cylinder with the same radius": "hemisphere-cylinder",
             "a solid cylinder with a hemisphere hollowed out of its top": "cylinder-minus-hemisphere",
             "a solid made of a cylinder with a hemisphere on each end": "capsule",
             "a solid cylinder with a smaller cylinder removed from its centre": "hollow",
             "a solid cylinder that fits exactly inside a hollow sphere": "inscribed"}
SD_NAMES = {"radius": "r", "diameter": "d", "height": "h", "slant height": "l", "slant height of each face": "t", "slant edge": "e",
            "base edge": "a", "other base edge": "b", "cone's height": "h", "cone's slant height": "l", "cylinder's height": "c",
            "cylinder's radius": "big", "hemisphere's radius": "r", "sphere's radius": "r", "sector's radius": "l", "sector's angle": "theta"}


def sd_shape(q):
    """The solid named in the opening line, the longest name that fits."""
    found = [v for k, v in SD_SHAPES.items() if f" is {k}" in q["lines"][0]]
    if not found:
        need("sector" in q["lines"][0] or "cone with no base" in q["lines"][0], f"can't read the solid in {q['lines'][0]!r}")
        return "sector"
    need(len(found) == 1, f"two solids in {q['lines'][0]!r}")
    if q["graph"] is not None:
        need(q["graph"]["shape"] == found[0], "the sketch is not the solid in the words")
    return found[0]


def sd_len(text):
    """"5.2 cm", "127°" as a Rational, or None for a letter."""
    mt = re.fullmatch(r"(\d+(?:\.\d+)?)(?: cm| m|°)", text)
    return sp.Rational(mt.group(1)) if mt else None


def sd_read(q):
    """The measures the student is shown, as Rationals, by key: r, h, l and so on."""
    out = {}
    if q["graph"] is not None:
        need(q["graph"]["kind"] == "solid", "not a solid sketch")
        for k, v in q["graph"].items():
            if k not in ("kind", "shape"):
                out[k] = sd_len(v)
    else:
        text = " ".join(q["lines"])
        for mt in re.finditer(r"[Tt]he ((?:(?! is )[a-z' ])+) is (\d+(?:\.\d+)?(?: cm| m|°))(?=[ ,.])", text):
            if mt.group(1) not in ("volume", "total surface area"):
                out[SD_NAMES[mt.group(1)]] = sd_len(mt.group(2))
    if "d" in out and out["d"] is not None:
        out["r"] = out["d"] / 2
    return out


def sd_given(q, name):
    """A total shown in a line: Rational, and whether it has π."""
    mt = re.search(rf"The {name} is (?:\((\d+/\d+)\)|(\d+))?(π)? ?(?:cm|m)", " ".join(q["lines"]))
    need(mt is not None, f"can't read the {name}")
    return sp.Rational(mt.group(1) or mt.group(2) or 1), mt.group(3) is not None


def sd_lead(c):
    """A coefficient as Fmt.lead writes it: (2/3), 5, and nothing for 1."""
    c = sp.Rational(c)
    return "" if c == 1 else (str(c.p) if c.q == 1 else f"({c.p}/{c.q})")


def sd_text(head, x, unit, paper, pi):
    """An answer x (times π where `pi`) as the game writes it."""
    if paper == 2:
        return head + rg_s(sp.N(x * (sp.pi if pi else 1), 40)) + unit
    x = sp.Rational(x)
    return head + (sd_lead(x) + "π" if pi else frac_text(x)) + unit


def sd_trap(head, x, unit, pi):
    v = sp.N(x * (sp.pi if pi else 1), 40)
    return head + dec_text(sp.Rational(sig3(v, 2))) + unit


def sd_set(q, head, x, unit, pi, table):
    """want, trap and wrongs for x; `table` is ref -> the values that mistake gives."""
    paper = q["paper"]
    wrongs = {ref: {sd_text(head, v, unit, paper, pi) for v in vals} for ref, vals in table.items()}
    return sd_text(head, x, unit, paper, pi), (sd_trap(head, x, unit, pi) if paper == 2 else None), wrongs


def sd_terms(head, terms, minus=False):
    return head + (" − " if minus else " + ").join(sd_lead(c) + body for c, body in terms)


def sd_edge(q, x):
    """On Paper 2 the answer is clear of a rounding edge and needs rounding."""
    if q["paper"] != 2:
        return
    v = abs(sp.N(x, 40))
    e = int(sp.floor(sp.log(v, 10)))
    scaled = v / sp.Integer(10) ** (e - 2)
    need(abs(scaled - sp.floor(scaled) - sp.Rational(1, 2)) >= SD_EDGE, f"{v} is too close to a rounding edge")
    need(sp.Rational(sig3(v)) != v, f"{v} needs no rounding")


def sd_measures(q, m):
    """Paper 1 measures are whole, Paper 2 measures have one decimal place."""
    for k, v in m.items():
        if v is None or (k == "r" and "d" in m):
            continue
        if q["paper"] == 1:
            need(v.q == 1 or k == "theta", f"{k} = {v} is not whole on Paper 1")
        else:
            need((v * 10).q == 1, f"{k} = {v} has more than one decimal place on Paper 2")


SD_UNIT = re.compile(r"(?:cm|m)(?:²|³)?(?![a-zA-Z])")


def sd_value(text):
    """A step's piece as a number, or None if it has letters or words in it."""
    t = SD_UNIT.sub("", text).strip().rstrip(".")
    if not t or not re.fullmatch(r"[0-9.()+−×÷/π²³√ ]+", t):
        return None
    t = t.replace("−", "-").replace("×", "*").replace("÷", "/").replace("²", "**2").replace("³", "**3")
    t = re.sub(r"(\d|\))π", r"\1*pi", t).replace("π", "pi")
    t = re.sub(r"√\(", "sqrt(", t)
    if "√" in t:
        return None
    return sp.N(sp.sympify(t, rational=True), 30)


def sd_steps(q):
    """Each pair of neighbouring plain-number sides of a step agree, to the figures shown. Returns
    how many pairs were read."""
    pairs = 0
    for sol in q["solutions"]:
        for st in sol["steps"]:
            sides = [sd_value(p) for p in re.split(r" = ", re.sub(r"^.*: ", "", st))]
            for a, b in zip(sides, sides[1:]):
                if a is None or b is None:
                    continue
                pairs += 1
                need(abs(a - b) <= max(abs(b) * sp.Rational(3, 10000), sp.Rational(6, 1000)), f"{sol['name']}: {st!r} doesn't add up ({a} and {b})")
    return pairs


def check_solid(q):
    u, paper, L = q["view"]["unknown"], q["paper"], q["lines"]
    shape = sd_shape(q)
    m = sd_read(q)
    sd_measures(q, m)
    unit = " " + ("m" if u == "paint-cost" else "cm")
    u2, u3 = unit + "²", unit + "³"
    V, S = SD_V, SD_S
    pi = True
    r, h, l, c = m.get("r"), m.get("h"), m.get("l"), m.get("c")
    if shape == "inscribed":
        h = h if h is not None else c
    if q["graph"] is None and u not in ("hollow-surface", "hollow-volume-from-surface", "surface-from-volume"):
        need(not any(x is None for x in m.values()), f"a letter in the words: {m}")
    table, want, trap, wrongs, x = {}, None, None, {}, None
    pyth = lambda a, b: sp.sqrt(a * a + b * b)
    leg = lambda hyp, a: sp.sqrt(hyp * hyp - a * a)
    if paper == 1 and u in ("cone-volume", "cone-curved", "cone-total", "cone-volume-from-slant", "height-from-slant"):
        have = [v for v in (r, h, l) if v is not None]
        need(len(have) == 2, "a cone shows two lengths")
    if u in ("cone-volume", "cone-volume-from-slant", "cone-volume-from-total", "sector-cone-volume", "height-from-slant", "slant-from-total"):
        if u in ("cone-volume-from-total", "slant-from-total"):
            A, has_pi = sd_given(q, "total surface area")
            need(has_pi == (paper == 1), "the area's form is not this paper's")
            l = A / r - r if paper == 1 else A / (sp.pi * r) - r
        if u == "sector-cone-volume":
            l, th = m["l"], m["theta"]
            r = l * th / 360
        if u != "cone-volume":
            need(l > r, "the slant height is not the longest side")
            h = leg(l, r)
        if paper == 1:
            need(sp.Rational(h).q == 1 if h.is_rational else False, f"h = {h} is not whole")
        x = r * r * h / 3
        if u == "cone-volume":
            table = {V + "1": [3 * x]}
            if "d" in m:
                table[V + "2"] = [4 * x]
            want, trap, wrongs = sd_set(q, "V = ", x, u3, True, table)
        elif u == "height-from-slant":
            x, pi = h, False
            want, trap, wrongs = sd_set(q, "h = ", h, unit, False, {})
        elif u == "slant-from-total":
            x, pi = l, False
            want, trap, wrongs = sd_set(q, "l = ", l, unit, False, {})
        else:
            want, trap, wrongs = sd_set(q, "V = ", x, u3, True, {V + "0": [r * r * l / 3], V + "1": [3 * x]})
    elif u in ("cone-curved", "cone-total"):
        if l is None:
            l = pyth(r, h)
        else:
            h = None
        need(paper == 2 or l.q == 1, "l is not whole")
        x = r * l + (r * r if u == "cone-total" else 0)
        table = {S + "0": [r * h + (r * r if u == "cone-total" else 0)]} if h is not None else {}
        want, trap, wrongs = sd_set(q, "area = ", x, u2, True, table)
    elif u == "pyramid-volume":
        a, b = m["a"], m.get("b", m["a"])
        x, pi = a * b * h / 3, False
        need(paper == 2 or x.q == 1, "a Paper 1 pyramid's volume is whole")
        want, trap, wrongs = sd_set(q, "V = ", x, u3, False, {V + "1": [3 * x]})
    elif u in ("pyramid-volume-from-slant", "pyramid-volume-from-edge"):
        a = m["a"]
        sl = m["t"] if "slant" in u else m["e"]
        h = leg(sl, a / 2) if "slant" in u else sp.sqrt(sl * sl - a * a / 2)
        need(paper == 2 or h.is_integer, f"h = {h} is not whole")
        x, pi = a * a * h / 3, False
        want, trap, wrongs = sd_set(q, "V = ", x, u3, False, {V + "0": [a * a * sl / 3], V + "1": [3 * x]})
    elif u == "pyramid-surface":
        a = m["a"]
        t = pyth(a / 2, h)
        need(paper == 2 or t.is_integer, f"t = {t} is not whole")
        x, pi = a * a + 2 * a * t, False
        want, trap, wrongs = sd_set(q, "area = ", x, u2, False, {S + "0": [a * a + 2 * a * h]})
    elif u in ("sphere-volume", "sphere-surface", "hemisphere-volume", "hemisphere-surface"):
        if u == "sphere-volume":
            x = 4 * r ** 3 / 3
        elif u == "sphere-surface":
            x = 4 * r * r
        elif u == "hemisphere-volume":
            x = 2 * r ** 3 / 3
        else:
            x = 3 * r * r
        table = {V + "2": [x * (8 if "volume" in u else 4)]} if "d" in m else {}
        if u == "hemisphere-volume":
            table[V + "1"] = [2 * x]
        if u == "hemisphere-surface":
            table[S + "1"] = [2 * r * r]
            table[S + "2"] = [4 * r * r]
        want, trap, wrongs = sd_set(q, "V = " if "volume" in u else "area = ", x, u3 if "volume" in u else u2, True, table)
    elif u == "radius-from-volume":
        Vv, has_pi = sd_given(q, "volume")
        need(has_pi == (paper == 1), "the volume's form is not this paper's")
        W = Vv * sp.pi if has_pi else Vv
        if shape == "sphere":
            x = sp.real_root(3 * W / (4 * sp.pi), 3)
        elif shape == "hemisphere":
            x = sp.real_root(3 * W / (2 * sp.pi), 3)
        else:
            x = sp.sqrt(3 * W / (sp.pi * h))
        x = sp.nsimplify(x) if paper == 1 else x
        pi = False
        need(paper == 2 or x.is_integer, f"r = {x} is not whole")
        table = {V + "2": [2 * x]}
        if paper == 2 and shape == "hemisphere":
            table[V + "1"] = [sp.real_root(3 * W / (4 * sp.pi), 3)]
        if paper == 2 and shape == "cone":
            table[V + "1"] = [sp.sqrt(W / (sp.pi * h))]
        want, trap, wrongs = sd_set(q, "r = ", x, unit, False, table)
    elif u == "height-from-volume":
        Vv, has_pi = sd_given(q, "volume")
        cone = shape == "cone"
        W = Vv * sp.pi if has_pi else Vv
        x = 3 * W / (sp.pi * r * r) if cone else 3 * W / (m["a"] ** 2)
        pi = False
        table = {V + "1": [x / 3]}
        if "d" in m:
            table[V + "2"] = [x / 4]
        want, trap, wrongs = sd_set(q, "h = ", x, unit, False, table)
    elif u in ("composite-volume", "composite-surface", "paint-cost"):
        big = m.get("big")
        if shape.startswith("cone"):
            if l is None:
                l = pyth(r, h)
            elif h is None:
                h = leg(l, r)
        shown_h = "h" in m
        cone_v = r * r * h / 3 if shape.startswith("cone") else 0
        dome_v = 2 * r ** 3 / 3
        cone_s = r * l if shape.startswith("cone") else 0
        if shape == "cone-hemisphere":
            vol, surf, base = cone_v + dome_v, cone_s + 2 * r * r, 0
        elif shape == "cone-cylinder":
            vol, surf, base = cone_v + r * r * c, cone_s + 2 * r * c + r * r, r * r
        elif shape == "hemisphere-cylinder":
            vol, surf, base = dome_v + r * r * c, 2 * r * r + 2 * r * c + r * r, r * r
        else:
            need(shape == "cylinder-minus-hemisphere", f"{shape} is not a composite")
            need(r <= big - sp.Rational(2, 5) and c >= r + sp.Rational(9, 10), "the hemisphere doesn't fit")
            vol, surf, base = big * big * c - dome_v, 2 * r * r + 2 * big * c + big * big + big * big - r * r, big * big
        if u == "composite-volume":
            x = vol
            table = {}
            if shape.startswith("cone"):
                table[V + "1"] = [x + 2 * cone_v]
                if "l" in m:
                    table.setdefault(V + "0", []).append(x + (l - h) * r * r / 3)
            if shape in ("cone-hemisphere", "hemisphere-cylinder"):
                table.setdefault(V + "1", []).append(x + dome_v)
            want, trap, wrongs = sd_set(q, "V = ", x, u3, True, table)
        elif u == "composite-surface":
            x = surf
            table = {S + "1": [x + (r * r if shape == "cylinder-minus-hemisphere" else 2 * r * r)]}
            if shape.startswith("cone") and shown_h:
                table[S + "0"] = [x + r * (h - l)]
            if shape != "cone-cylinder":
                table[S + "2"] = [x + 2 * r * r]
            want, trap, wrongs = sd_set(q, "area = ", x, u2, True, table)
        else:
            mt = re.fullmatch(r"Paint costs \$(\d+(?:\.\d\d)?) per m²\.", L[-1])
            need(mt is not None, f"can't read {L[-1]!r}")
            price = sp.Rational(mt.group(1))
            need(q["asked"] == "Find the cost of painting the outside of the tank. The base is not painted.", q["asked"])
            need(shape in ("cone-cylinder", "hemisphere-cylinder"), "a tank is a cone or hemisphere on a cylinder")
            op = surf - base
            x = op * price
            table = {S + "1": [surf * price]}
            if shape == "cone-cylinder" and shown_h:
                table[S + "0"] = [x + r * (h - l) * price]
            if shape == "hemisphere-cylinder":
                table[S + "2"] = [x + 2 * r * r * price]
            want, trap, wrongs = sd_set(q, "cost = $", x, "", True, table)
    elif u == "composite-volume-solve":
        need(paper == 2, "the GDC solver is Paper 2")
        need(q["asked"] == "Find r.", q["asked"])
        Vv, has_pi = sd_given(q, "volume")
        need(not has_pi, "a Paper 2 volume is a number")
        cone = shape == "cone-hemisphere"
        p23, p43 = sp.Rational(2, 3), sp.Rational(4, 3)
        b = sp.Rational(h) / 3 if cone else sp.Rational(c)
        roots = [sd_root(p23, b, Vv)]
        x = roots[0]
        pi = False
        slip = sd_root(p23, sp.Rational(h), Vv) if cone else sd_root(p43, sp.Rational(c), Vv)
        want, trap, wrongs = sd_set(q, "r = ", x, unit, False, {V + "1": [slip]})
    elif u == "volume-in-terms":
        need("in terms of x" in q["asked"], q["asked"])
        rx, hx, cc = sd_x_measures(q)
        v = {"cone": [(sp.Rational(rx * rx * (hx or 0), 3), "πx³")], "sphere": [(sp.Rational(4 * rx ** 3, 3), "πx³")],
             "hemisphere": [(sp.Rational(2 * rx ** 3, 3), "πx³")],
             "hemisphere-cylinder": [(sp.Rational(2 * rx ** 3, 3), "πx³"), (rx * rx * (cc or 0), "πx²")],
             "cone-cylinder": [(sp.Rational(rx * rx * (hx or 0), 3), "πx³"), (rx * rx * (cc or 0), "πx²")]}[shape]
        want = sd_terms("V = ", v)
        wrongs = {}
        if shape != "sphere":
            first = 2 if shape.startswith("hemi") else 3
            wrongs[V + "1"] = {sd_terms("V = ", [(v[0][0] * first, "πx³")] + v[1:])}
        q["_expr"] = True
    elif u == "surface-in-terms":
        rx, hx, cc = sd_x_measures(q)
        if shape == "cone":
            lx = sp.sqrt(rx * rx + hx * hx)
            need(lx.is_integer, "l is not a whole multiple of x")
            whole = "total" in q["asked"]
            base = rx * rx if whole else 0
            want = sd_terms("S = ", [(rx * lx + base, "πx²")])
            wrongs = {S + "0": {sd_terms("S = ", [(rx * hx + base, "πx²")])}}
        elif shape == "hemisphere":
            want = sd_terms("S = ", [(3 * rx * rx, "πx²")])
            wrongs = {S + "1": {sd_terms("S = ", [(2 * rx * rx, "πx²")])}, S + "2": {sd_terms("S = ", [(4 * rx * rx, "πx²")])}}
        else:
            need(shape == "hemisphere-cylinder", shape)
            wall = 2 * rx * cc
            want = sd_terms("S = ", [(3 * rx * rx, "πx²"), (wall, "πx")])
            wrongs = {S + "1": {sd_terms("S = ", [(2 * rx * rx, "πx²"), (wall, "πx")])}, S + "2": {sd_terms("S = ", [(5 * rx * rx, "πx²"), (wall, "πx")])}}
        q["_expr"] = True
    elif u in ("hollow-surface", "hollow-volume-from-surface"):
        need(shape == "hollow", shape)
        txt = q["graph"]["big"] if q["graph"] else re.search(r"outer radius is (\d+)r", " ".join(L)).group(1) + "r"
        k = int(txt[:-1])
        if u == "hollow-surface":
            r_s, h_s = sp.symbols("r h", positive=True)
            S_e = sp.expand(2 * sp.pi * k * r_s * h_s + 2 * sp.pi * r_s * h_s + 2 * sp.pi * ((k * r_s) ** 2 - r_s ** 2))
            a2, a1 = S_e.coeff(r_s, 2) / sp.pi, S_e.coeff(r_s, 1).coeff(h_s, 1) / sp.pi
            want = sd_terms("S = ", [(a2, "πr²"), (a1, "πrh")])
            wrongs = {S + "1": {sd_terms("S = ", [(2 * a2, "πr²"), (a1, "πrh")])}}
        else:
            mt = re.search(r"total surface area is (\d+)π cm²", " ".join(L))
            need(mt is not None, "can't read S")
            M_ = int(mt.group(1))
            r_s, h_s = sp.symbols("r h", positive=True)
            hh = sp.solve(2 * (k * k - 1) * r_s ** 2 + 2 * (k + 1) * r_s * h_s - M_, h_s)[0]
            Vx = sp.expand((k * k - 1) * r_s ** 2 * hh)
            want = "V = " + f"{sd_lead(Vx.coeff(r_s, 1))}πr − {sd_lead(-Vx.coeff(r_s, 3))}πr³"
            need(Vx.coeff(r_s, 1) > 0 and Vx.coeff(r_s, 3) < 0, "the expression's signs")
        q["_expr"] = True
    elif u == "surface-from-volume":
        mt = re.search(r"its volume is (\d+) cm³", " ".join(L))
        need(mt is not None, "can't read the volume")
        W = int(mt.group(1))
        need(shape in ("capsule", "hemisphere-cylinder"), shape)
        two = shape == "capsule"
        want = sd_terms("S = ", [(2 * W, "/x"), (4 if two else 3, "πx²")])
        wrongs = {S + "1": {sd_terms("S = ", [(2 * W, "/x"), (6 if two else 2, "πx²")])}}
        if not two:
            wrongs[S + "2"] = {sd_terms("S = ", [(2 * W, "/x"), (5, "πx²")])}
        q["_expr"] = True
    elif u in ("inscribed-volume", "inscribed-surface"):
        need(h < 2 * r, "the cylinder doesn't fit")
        R_ = leg(r, h / 2)
        need(paper == 2 or R_.is_integer, f"R = {R_} is not whole")
        if u == "inscribed-volume":
            x = R_ * R_ * h
            want, trap, wrongs = sd_set(q, "V = ", x, u3, True, {V + "0": [r * r * h], V + "1": [x / 3]})
        else:
            x = 2 * R_ * R_ + 2 * R_ * h
            want, trap, wrongs = sd_set(q, "area = ", x, u2, True, {S + "0": [2 * r * r + 2 * r * h], S + "1": [R_ * R_ + 2 * R_ * h]})
    elif u in ("sector-cone-radius", "sector-curved"):
        l, th = m["l"], m["theta"]
        need(60 <= th <= 300, f"θ = {th}")
        rr = l * th / 360
        if u == "sector-cone-radius":
            x, pi = rr, False
            need(paper == 2 or rr.q == 1, "r is not whole")
            want, trap, wrongs = sd_set(q, "r = ", rr, unit, False, {})
        else:
            x = th / 360 * l * l
            want, trap, wrongs = sd_set(q, "area = ", x, u2, True, {})
    elif u == "sector-angle":
        if q["graph"] is not None:
            need(q["graph"]["theta"] == "θ", "the angle is the unknown")
            l = sd_len(q["graph"]["l"])
            mt = re.search(r"base radius is (\S+ cm)\.", L[-1])
            rr = sd_len(mt.group(1))
        else:
            mt = re.search(r"has radius (\S+ cm) and slant height (\S+ cm)\.", L[0])
            rr, l = sd_len(mt.group(1)), sd_len(mt.group(2))
        x, pi = 360 * rr / l, False
        need(60 <= x <= 300, f"θ = {x}")
        need(paper == 2 or x.q == 1, "θ is not whole")
        want, trap, wrongs = sd_set(q, "θ = ", x, "°", False, {})
    else:
        raise Fail(f"no check for {u}")
    if x is not None:
        sd_edge(q, x * (sp.pi if pi else 1))
        if paper == 2:
            need(not trap or not q["answer"].get("exact", False), "a Paper 2 answer is not exact-only")
    expr_answer = q.pop("_expr", False)
    gc_check_common(q, want, wrongs, trap, steps=(2, 5))
    pairs = sd_steps(q)
    need(pairs > 0 or expr_answer or u in ("slant-from-total", "composite-volume-solve", "radius-from-volume", "height-from-volume"), "no working was read")
    return None, None


def sd_root(a, b, W):
    """The positive root of π(a r³ + b r²) = W, to 40 figures."""
    y = sp.Symbol("y")
    poly = sp.Poly(a * y ** 3 + b * y ** 2 - sp.Rational(W) / sp.pi, y)
    roots = [t for t in poly.nroots(n=40, maxsteps=200) if abs(sp.im(t)) < 1e-30 and sp.re(t) > 0]
    need(len(roots) == 1, f"{len(roots)} positive roots")
    return sp.re(roots[0])


def sd_x_measures(q):
    """rx, hx and the whole cylinder height of a solid given in terms of x."""
    if q["graph"] is not None:
        g = q["graph"]
        r_t, h_t, c_t = g["r"], g.get("h"), g.get("c")
    else:
        text = " ".join(q["lines"])
        find = lambda n: (lambda mt: mt.group(1) if mt else None)(re.search(rf"[Tt]he {n} is (\d*x? cm)", text))
        r_t = find("radius")
        h_t = find("height") or find("cone's height")
        c_t = find("cylinder's height")
    coef = lambda t: None if t is None else (lambda b: 1 if b == "" else int(b))(t.replace(" cm", "").replace("x", ""))
    need(r_t is not None and "x" in r_t, f"can't read r = {r_t!r}")
    return coef(r_t), coef(h_t), coef(c_t)


# ── standard-form (t1-standard-form, FAL-726) ────────────────
# The `standard-form` situation's clean limits, the checker's own copy: the engine's is in
# game/engine/situations/standard_form.gd. Numbers are read back from the question's text as exact
# Rationals, so a power of ten never has to fit a float, and each answer is normalised again here.

SF_EDGE = sp.Rational(59, 1000)         # the engine's is 0.06
SF_C = "SL1.1.convert#"
SF_M = "SL1.1.multiply-divide#"
SF_X = "SL1.1.context#"
SF_SUP = str.maketrans("⁰¹²³⁴⁵⁶⁷⁸⁹⁻", "0123456789-")
SF_NUM = re.compile(r"(?:(\d+(?:\.\d+)?) × )?10([⁰¹²³⁴⁵⁶⁷⁸⁹⁻]+)")
SF_PLAIN = re.compile(r"\d+(?: \d{3})*(?:\.\d+)?")


def sf_read(text):
    """Every a × 10^k in a piece of text, as [(a, k)]."""
    return [(sp.Rational(mt.group(1) or 1), int(mt.group(2).translate(SF_SUP))) for mt in SF_NUM.finditer(text)]


def sf_v(pair):
    return pair[0] * sp.Rational(10) ** pair[1]


def sf_norm(v):
    """v as (a, k) with 1 ≤ a < 10, without leaving exact numbers."""
    k = 0
    while v >= 10:
        v, k = v / 10, k + 1
    while v < 1:
        v, k = v * 10, k - 1
    return v, k


def sf_ten(k):
    return "10" + str(k).translate(str.maketrans("0123456789-", "⁰¹²³⁴⁵⁶⁷⁸⁹⁻"))


def sf_a(a, rounded, figs=3):
    a = sp.Rational(a)
    q = a.q
    for f in (2, 5):
        while q % f == 0:
            q //= f
    return sig3(a, figs) if rounded or q != 1 else dec_text(a)


def sf_text(a, k, rounded, head="", tail=""):
    return f"{head}{sf_a(a, rounded)} × {sf_ten(k)}{tail}"


def sf_answer(q, v, head="", tail=""):
    """want and trap for the value v: rounded on Paper 2, where it needs it."""
    a, k = sf_norm(v)
    rounded = q["paper"] == 2
    if q["paper"] == 1:
        need(sp.Rational(a * 1000).q == 1, f"a = {a} has too many figures for Paper 1")
    if abs(k) < 2:
        raise Fail(f"k = {k} is too small an answer power")
    if rounded:
        scaled = a * 100
        need(a < sp.Rational(99, 10), f"a = {a} is too near 10")
        need(abs(scaled - sp.floor(scaled) - sp.Rational(1, 2)) >= SF_EDGE, f"a = {a} is too close to a rounding edge")
    trap = None
    if rounded and sp.Rational(sig3(a)) != a:
        trap = f"{head}{sig3(a, 2)} × {sf_ten(k)}{tail}"
    return sf_text(a, k, rounded, head, tail), trap, a, k


def sf_raw(a, k):
    return f"{sig3(a)}E{str(k).replace('-', '−')}"


def sf_value(text):
    """A step's side as a number, or None if it has words or letters in it."""
    t = re.sub(r",.*$", "", text).strip().rstrip(".")
    t = re.sub(r"(?<=\d) (?=\d{3})", "", t)
    if not t or not re.fullmatch(r"[0-9.()+−×÷^ ⁰¹²³⁴⁵⁶⁷⁸⁹⁻²³]+", t):
        return None
    t = re.sub(r"([⁰¹²³⁴⁵⁶⁷⁸⁹⁻]+)", lambda mt: f"**({mt.group(1).translate(SF_SUP)})", t)
    t = t.replace("−", "-").replace("×", "*").replace("÷", "/").replace("^", "**")
    return sp.sympify(t, rational=True)


def sf_steps(q):
    pairs = 0
    for sol in q["solutions"]:
        for st in sol["steps"]:
            sides = [sf_value(p) for p in re.sub(r"^.*: ", "", st).split(" = ")]
            for a, b in zip(sides, sides[1:]):
                if a is None or b is None:
                    continue
                pairs += 1
                need(abs(a - b) <= abs(b) * sp.Rational(3, 10000), f"{sol['name']}: {st!r} doesn't add up ({a} and {b})")
    return pairs


def check_standard_form(q):
    u, paper, L, asked = q["view"]["unknown"], q["paper"], q["lines"], q["asked"]
    C, M, X = SF_C, SF_M, SF_X
    rounded = paper == 2
    text = " ".join(L)
    want, trap, wrongs = None, None, {}
    T = lambda a, k: sf_text(a, k, rounded)
    pq = sf_read(L[0]) + sf_read(L[1]) if u in ("multiply", "multiply-renormalise", "divide", "divide-renormalise", "power-product") else None
    if pq is not None:
        need(L[0].startswith("p = ") and L[1].startswith("q = "), "p and q")
        (a, m), (b, n) = pq
        need(m != 0 and n != 0, "a power of 0")
    if u in ("to-form-large", "to-form-small"):
        src = L[0] if L else asked
        mt = re.search(r"\d[\d ]*\d(?:\.\d+)?|0\.\d+|\d+", src.replace("10^k", "").replace("1 ≤ a < 10", ""))
        need(mt is not None, "can't read the number")
        v = sp.Rational(mt.group(0).replace(" ", ""))
        want, trap, a, k = sf_answer(q, v)
        need((v > 1) == (u == "to-form-large"), "the number is on the wrong side of 1")
        digit = k + 1 if k > 0 else k - 1
        wrongs = {C + "0": {T(a, -k)}, C + "1": {T(a, digit)}, C + "2": {T(a * 10, k - 1), T(a / 10, k + 1)}}
        if paper == 2:
            wrongs[X + "0"] = {sf_raw(a, k)}
    elif u in ("to-ordinary-large", "to-ordinary-small"):
        (a, k), = sf_read(text if L else asked)
        need((k > 0) == (u == "to-ordinary-large"), "the power is on the wrong side of 0")
        lab = "number = "
        want = lab + dec_text(a * sp.Rational(10) ** k)
        d = k + 1 if k > 0 else k - 1
        wrongs = {C + "0": {lab + dec_text(a * sp.Rational(10) ** -k)}, C + "1": {lab + dec_text(a * sp.Rational(10) ** d)}}
    elif u == "renormalise":
        rd = sf_read(asked)
        need(len(rd) == 1, "one number")
        a0, k0 = rd[0]
        need(not (1 <= a0 < 10), "the number is already in standard form")
        a, k = sf_norm(sf_v(rd[0]))
        want = sf_text(a, k, False)
        wrongs = {C + "2": {sf_text(a * 10 if a0 < 1 else a / 10, k - 1 if a0 < 1 else k + 1, False)}}
    elif u == "order-mixed":
        mt = re.fullmatch(r"The four numbers are (.+)\.", L[0])
        need(mt is not None, "can't read the list")
        items = mt.group(1).split(",  ")
        need(len(items) == 4, "four numbers")
        vals = {}
        for it in items:
            rd = sf_read(it)
            vals[it] = sf_v(rd[0]) if rd else sp.Rational(it.replace(" ", ""))
        need(len(set(vals.values())) == 4, "two numbers are equal")
        big = "largest" in asked
        best = (max if big else min)(vals, key=lambda i: vals[i])
        lab = "largest: " if big else "smallest: "
        want = lab + best
        tricks = {lab + it for it in items if it != best and sf_read(it) and ((sf_read(it)[0][0] < 1) if big else (sf_read(it)[0][0] >= 10))}
        wrongs = {C + "2": tricks}
    elif u == "display-to-form":
        need(paper == 2, "a display is Paper 2")
        mt = re.fullmatch(r"A GDC shows (\d\.\d+)E(−?\d+)\.", L[0])
        need(mt is not None, f"can't read {L[0]!r}")
        a, k = sp.Rational(mt.group(1)), int(mt.group(2).replace("−", "-"))
        want = sf_text(a, k, False)
        wrongs = {X + "0": {mt.group(1) + "E" + mt.group(2)}, C + "0": {sf_text(a, -k, False)}}
    elif u in ("multiply", "multiply-renormalise"):
        need(m * n != m + n and m != n, "the powers are a degenerate pair")
        want, trap, r, k = sf_answer(q, a * b * sp.Rational(10) ** (m + n))
        need((a * b >= 10) == (u == "multiply-renormalise"), "the product is on the wrong side of 10")
        wrongs = {M + "0": {T(r, k - m - n + m * n)}, M + "2": {T(r, k - m - n + m - n)}}
        if a * b >= 10:
            wrongs[M + "1"] = {T(a * b, m + n)}
    elif u in ("divide", "divide-renormalise"):
        need(m != n, "the powers are equal")
        want, trap, r, k = sf_answer(q, a / b * sp.Rational(10) ** (m - n))
        need((a < b) == (u == "divide-renormalise"), "the quotient is on the wrong side of 1")
        wrongs = {M + "2": {T(r, k - m + n + m + n)}}
        if a < b:
            wrongs[M + "1"] = {T(a / b, m - n)}
    elif u == "power-product":
        e = 2 * m + n
        want, trap, r, k = sf_answer(q, a * a * b * sp.Rational(10) ** e)
        wrongs = {M + "0": {T(r, k - e + m * m + n)}}
        if a * a * b >= 10:
            wrongs[M + "1"] = {T(a * a * b, e)}
    elif u in ("times-larger", "time-from-rate", "total-from-unit", "rate-unit-shift"):
        rd = sf_read(L[0])
        need(len(rd) == 2, "two numbers in the story")
        (a, m), (b, n) = rd
        if u == "times-larger":
            need(sf_v(rd[0]) > sf_v(rd[1]), "the first is not the larger")
            v = sf_v(rd[0]) / sf_v(rd[1])
            slip = sig_v2(a) / sig_v2(b) * sp.Rational(10) ** (m - n)
            fr, fk = sf_norm(1 / v)
            wrongs[X + "2"] = {T(fr, fk)}
        elif u == "total-from-unit":
            v = sf_v(rd[0]) * sf_v(rd[1])
            slip = sig_v2(a) * sig_v2(b) * sp.Rational(10) ** (m + n)
        else:
            need("m s⁻¹" in L[0] and ("kilometres away" if u == "rate-unit-shift" else "metres away") in L[0], "the units")
            shift = 3 if u == "rate-unit-shift" else 0
            v = sf_v((b, n + shift)) / sf_v((a, m))
            slip = sig_v2(b) / sig_v2(a) * sp.Rational(10) ** (n + shift - m)
        want, trap, r, k = sf_answer(q, v)
        if paper == 2:
            sr, sk = sf_norm(slip)
            wrongs[X + "1"] = {T(sr, sk)}
            wrongs[X + "0"] = {sf_raw(r, k)}
    elif u == "unit-shift":
        (a, m), = sf_read(L[0])
        pairs = [("grams", "kilograms", -3), ("kilometres", "metres", 3), ("millimetres", "metres", -3), ("kilowatts", "watts", 3), ("kilograms", "grams", 3), ("metres", "kilometres", -3)]
        found = [s for f, to, s in pairs if re.search(rf"\b{f}\b", L[0]) and f"in {to}." in asked]
        need(len(found) == 1, "can't read the units")
        want = sf_text(a, m + found[0], False)
        need(1 <= a < 10 and abs(m + found[0]) >= 2, "the amount's a or power")
    elif u == "scale-value":
        (a, m), = sf_read(L[0])
        mt = re.search(r" (\d) times ", L[0])
        need(mt is not None, "can't read the multiplier")
        f = int(mt.group(1))
        want, trap, r, k = sf_answer(q, a * f * sp.Rational(10) ** m)
        if a * f >= 10:
            wrongs[M + "1"] = {T(a * f, m)}
    elif u == "sphere-volume-pi":
        (d, m), = sf_read(L[0])
        need("diameter" in L[0], "a diameter")
        c = (d / 2) ** 3 * sp.Rational(4, 3)
        want, trap, r, k = sf_answer(q, c * sp.Rational(10) ** (3 * m), "V = π(", ") m³")
        if not (1 <= c < 10):
            wrongs[M + "1"] = {sf_text(c, 3 * m, rounded, "V = π(", ") m³")}
    else:
        raise Fail(f"no check for {u}")
    gc_check_common(q, want, wrongs, trap, steps=(2, 5))
    sf_steps(q)
    return None, None


def sig_v2(x):
    """x rounded early, to 2 s.f."""
    return sp.Rational(sig3(x, 2))


# ── Exact trig (t3-exact-values, t3-identity-values, t3-trig-equation, FAL-727) ──
# Exact values as the game writes them, read back and worked out again with SymPy from what the
# question shows. An angle in the export is the multiple of π.

TR_FN = {"sin": sp.sin, "cos": sp.cos, "tan": sp.tan}


def tr_read(text):
    """A value as the game writes it: "−√3/2", "(1 + √3)/2", "5√2/2", "7/2"."""
    t = text.strip().replace("−", "-")
    t = re.sub(r"(\d)√(\d+)", r"\1*sqrt(\2)", t)
    t = re.sub(r"√(\d+)", r"sqrt(\1)", t)
    return sp.sympify(t, rational=True)


def tr_text(v):
    """The checker's own writing of a + b√r, with the root on top."""
    v = sp.nsimplify(sp.radsimp(sp.expand(sp.simplify(v))))
    a, b, r = sp.Integer(0), sp.Integer(0), None
    for term in sp.Add.make_args(sp.expand(v)):
        if term.is_Rational:
            a += term
            continue
        c, rest = term.as_coeff_Mul()
        need(rest.is_Pow and rest.exp == sp.Rational(1, 2) and rest.base.is_Integer, f"{v} is not a + b√r")
        need(r is None or r == rest.base, f"{v} has two surds")
        b, r = c, rest.base
    if b == 0:
        return frac_text(a)
    d = sp.ilcm(a.q, b.q)
    ai, bi = int(a * d), int(b * d)
    unit = lambda n: ("" if n == 1 else str(n)) + f"√{r}"
    if ai == 0:
        return ("−" if bi < 0 else "") + unit(abs(bi)) + ("" if d == 1 else f"/{d}")
    two = f"{frac_text(sp.Integer(ai))} {'+' if bi > 0 else '−'} {unit(abs(bi))}"
    return two if d == 1 else f"({two})/{d}"


def tr_angle(t, form="pi"):
    t = R(t)
    if form == "deg":
        return dec_text(t * 180) + "°"
    return as_pi(t) if t != 0 else "0"


def tr_call(fn, t, form="pi"):
    return f"{fn} {tr_angle(t, form)}" if form == "deg" else f"{fn}({tr_angle(t, form)})"


def tr_of(fn, t):
    return TR_FN[fn](R(t) * sp.pi)


def tr_hyphens(q):
    for tx in [q["asked"]] + q["lines"] + [str(st) for sol in q["solutions"] for st in sol["steps"]] + [o["text"] for o in q["choices"]]:
        need(not re.search(r"(?<![A-Za-z])-\d", tx), f"a hyphen for a minus in {tx!r}")


def tr_common(q, label, v, wrongs, tail="", steps=(2, 10), read=None):
    """The answer is label + the value + tail. Every option is checked by value too, so a wrong
    option can't be the right value written another way."""
    want = label + tr_text(v) + tail
    tr_hyphens(q)
    gc_check_common(q, want, {k: {label + tr_text(w) + tail for w in vs} for k, vs in wrongs.items()}, steps=steps)
    for o in q["choices"]:
        body = o["text"]
        need(body.startswith(label) and body.endswith(tail), f"option {body!r} has another shape")
        x = tr_read(body[len(label):len(body) - len(tail) if tail else None])
        need(sp.simplify(x - v) == 0 if o["correct"] else sp.simplify(x - v) != 0, f"option {body!r} has the wrong value")


def tr_claim(q, right, wrongs, steps=(2, 6)):
    tr_hyphens(q)
    gc_check_common(q, right, wrongs, steps=steps)


TR_ROUND = {sp.Rational(*p) for p in [(2, 3), (3, 4), (5, 6), (7, 6), (5, 4), (4, 3), (5, 3), (7, 4), (11, 6)]}
TR_FAR = {sp.Rational(*p) for p in [(-1, 6), (-1, 4), (-1, 3), (-2, 3), (-3, 4), (-5, 6), (13, 6), (9, 4), (7, 3)]}
TR_ACUTE = {sp.Rational(1, 6), sp.Rational(1, 4), sp.Rational(1, 3)}
TR_SPECIAL = TR_ACUTE | {sp.Integer(0), sp.Rational(1, 2)}


def tr_quadrant(t):
    return int(sp.floor((R(t) % 2) * 2)) + 1


def tr_ref(t):
    """The angle to the nearest x-axis, worked from the unit circle's own folds."""
    u = R(t) % 2
    u = u if u <= 1 else u - 1
    return min(u, 1 - u)


def check_exact_trig(q):
    g, u, rep, L, asked = q["given"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    need(q["paper"] == 1, "every exact value is Paper 1")
    SW, TS, SF = "SL3.5.exact-special#0", "SL3.5.exact-special#1", "SL3.5.exact-special#2"
    SG, YA, NG = "SL3.5.related-angles#0", "SL3.5.related-angles#1", "SL3.5.related-angles#2"
    CO, CK, TZ = "SL3.5.unit-circle#0", "SL3.5.unit-circle#1", "SL3.5.unit-circle#2"

    def first_wrongs(fn, t, k=1):
        w = {}
        t = R(t)
        if fn != "tan" and t in (sp.Rational(1, 6), sp.Rational(1, 3)):
            w[SW] = [k * tr_of("cos" if fn == "sin" else "sin", t)]
        if fn == "tan" and t == sp.Rational(1, 6):
            w[TS] = [k * sp.sqrt(3)]
        if fn != "tan" and t == sp.Rational(1, 4):
            w[SF] = [k * sp.Rational(1, 2)]
        return w

    if u == "special-value":
        fn, t = g["fn"], R(g["t"])
        need(t in (TR_ACUTE if rep == "diagram" else TR_SPECIAL), f"{t} is no landmark")
        need(not (fn == "tan" and t == sp.Rational(1, 2)), "tan(π/2) has no value")
        name = tr_call(fn, t, g["form"])
        v = tr_of(fn, t)
        need(g["form"] == "pi" or rep == "equation", "degrees are in the written form")
        if rep == "diagram":
            d = q["diagram"]
            need(abs(math.atan2(d["vertices"]["C"][1], d["vertices"]["B"][0]) - float(t) * math.pi) < 1e-6, "the triangle has another angle")
            need(d["vertices"]["B"][1] == 0 and abs(d["vertices"]["C"][0] - d["vertices"]["B"][0]) < 1e-9, "the triangle isn't right-angled at B")
            labels = {sd["side"]: sd["label"] for sd in d["sides"]}
            a, b, c = tr_read(labels["a"]), tr_read(labels["b"]), tr_read(labels["c"])
            need(sp.simplify(a / c - sp.tan(t * sp.pi)) == 0 and sp.simplify(a**2 + c**2 - b**2) == 0, "the sides don't fit the angle")
            tr_common(q, f"{fn} θ = ", v, first_wrongs(fn, t))
            return None, None
        if rep == "table":
            rows = dict((r[0], r[1]) for r in q["table"]["rows"])
            need(rows["θ"] == ["0", "π/6", "π/4", "π/3", "π/2"], "the table's heads are wrong")
            need(rows[f"{fn} θ"][rows["θ"].index(tr_angle(t))] == "?", "the asked cell is not marked")
            for f, cells in rows.items():
                if f != "θ" and f != f"{fn} θ":
                    for h, c in zip(["0", "1/6", "1/4", "1/3", "1/2"], cells):
                        need(c == tr_text(tr_of(f[:3], h)), f"the table's {f} at {h}π is wrong")
        need(name in asked or rep == "table", f"the question doesn't ask {name}")
        tr_common(q, name + " = ", v, first_wrongs(fn, t))
    elif u == "scaled-value":
        fn, t, k = g["fn"], R(g["t"]), R(g["k"])
        need(t in TR_ACUTE and 2 <= k <= 12, "out of range")
        v = k * tr_of(fn, t)
        ang = tr_angle(t)
        if rep == "equation":
            need(L == [f"f(x) = {k} {fn} x"] and asked == f"Find the exact value of f({ang}).", f"can't read {L}")
            tr_common(q, f"f({ang}) = ", v, first_wrongs(fn, t, k))
        else:
            need(f"h = {k} {fn} θ metres" in L[0] and asked.endswith(f"θ = {ang}."), f"can't read {L}")
            tr_common(q, "h = ", v, first_wrongs(fn, t, k), " m")
    elif u == "special-sum":
        fn, t, fn2, t2, plus, first = g["fn"], R(g["t"]), g["fn2"], R(g["t2"]), g["plus"], R(g["first"])
        sg = 1 if plus else -1
        v = first * tr_of(fn, t)**2 + sg * tr_of(fn2, t2)
        need(L == [f"{'' if first == 1 else first}{fn}²({tr_angle(t)}) {'+' if plus else '−'} {tr_call(fn2, t2)}"], f"can't read {L}")
        w = {}
        if fn != "tan" and t == sp.Rational(1, 4):
            w[SF] = [first * sp.Rational(1, 4) + sg * tr_of(fn2, t2)]
        tr_common(q, "", v, w)
    elif u == "related-value":
        fn, t = g["fn"], R(g["t"])
        need(t in (TR_ROUND if rep == "graph" else TR_ROUND | TR_FAR), f"{t} is out of range")
        name = tr_call(fn, t)
        need(name in asked, f"the question doesn't ask {name}")
        v = tr_of(fn, t)
        w = {SG: [-v]}
        if t < 0:
            w[NG] = [tr_of(fn, -t)]
        r = tr_ref(t)
        need(sp.simplify(abs(v) - tr_of(fn, r)) == 0, "the reference angle doesn't give the size")
        if r != sp.Rational(1, 4):
            w[YA] = [sp.sign(v) * tr_of(fn, sp.Rational(1, 2) - r)]
        if rep == "diagram":
            p = q["graph"]["points"][0]
            need(abs(p["x"] - math.cos(float(t) * math.pi)) < 1e-9 and abs(p["y"] - math.sin(float(t) * math.pi)) < 1e-9, "P is drawn at another angle")
        elif rep == "graph":
            p = q["graph"]["points"][0]
            need(abs(p["x"] - float(t) * math.pi) < 1e-9 and abs(p["y"] - float(v)) < 1e-9, "P is drawn in another place")
            pts = q["graph"]["curves"][0]
            f = math.sin if fn == "sin" else math.cos
            need(all(abs(y - f(x)) < 1e-9 for x, y in pts), "the curve is another function")
        tr_common(q, name + " = ", v, w)
    elif u == "related-sum":
        fn, t, fn2, t2 = g["fn"], R(g["t"]), g["fn2"], R(g["t2"])
        need(t in TR_ROUND and t2 in TR_ROUND and t != t2, "out of range")
        need(L == [f"{tr_call(fn, t)} + {tr_call(fn2, t2)}"], f"can't read {L}")
        a, b = tr_of(fn, t), tr_of(fn2, t2)
        tr_common(q, "", a + b, {SG: [b - a]}, steps=(2, 10))
    elif u == "given-related":
        gv = sp.Rational(R(g["g"]), R(g["n"]))
        need(0 < gv < 1, "the given ratio is out of range")
        # A numeric acute angle stands in for θ: the sign must hold at any acute θ.
        fn, rule = g["fn"], g["rule"]
        if rep == "diagram":
            need(L[1] == f"sin CAD = {frac_text(gv)}", f"can't read {L}")
            th = q["graph"]["theta"]
            need(abs(math.sin(th) - float(gv)) < 1e-9 and th < math.pi / 2, "the figure has another angle")
            tr_common(q, "sin CAB = ", gv, {SG: [-gv]})
        else:
            need(L == [f"{fn} θ = {frac_text(gv)}, where θ is acute."], f"can't read {L}")
            ang = {"pi-minus": lambda x: sp.pi - x, "pi-plus": lambda x: sp.pi + x, "minus": lambda x: -x}[rule]
            name = {"pi-minus": "π − θ", "pi-plus": "π + θ", "minus": "−θ"}[rule]
            x = sp.Symbol("x", positive=True)
            sign = sp.simplify(TR_FN[fn](ang(x)) / TR_FN[fn](x))
            need(sign in (1, -1), f"{fn} at {name} is no multiple of {fn} θ")
            tr_common(q, f"{fn}({name}) = ", sign * gv, {SG: [-sign * gv]})
    elif u == "point-at-angle":
        t = R(g["t"])
        x, y = tr_of("cos", t), tr_of("sin", t)
        need(tr_angle(t) in L[0], f"can't read {L}")
        want = f"P = ({tr_text(x)}, {tr_text(y)})"
        pw = {CO: {f"P = ({tr_text(y)}, {tr_text(x)})"}, CK: {f"P = ({tr_text(x)}, {tr_text(-y)})"}}
        tr_hyphens(q)
        gc_check_common(q, want, pw)
    elif u in ("ratio-from-point", "tan-from-point"):
        x, y = R(g["x"]), R(g["y"])
        need(x**2 + y**2 == 1, "the point is not on the unit circle")
        need(f"({frac_text(x)}, {frac_text(y)})" in L[0], f"can't read {L}")
        if u == "ratio-from-point":
            fn = g["fn"]
            tr_common(q, f"{fn} θ = ", y if fn == "sin" else x, {CO: [x if fn == "sin" else y]})
        else:
            tr_common(q, "tan θ = ", y / x, {CO: [x / y]})
    elif u == "sign-in-quadrant":
        qd, fn, fn2 = g["q"], g["fn"], g["fn2"]
        th = sp.pi * sp.Rational(2 * qd - 1, 4)
        need(["0 < θ < π/2", "π/2 < θ < π", "π < θ < 3π/2", "3π/2 < θ < 2π"][qd - 1] in L[0], f"can't read {L}")
        text = lambda s1, s2: f"{fn} θ {'>' if s1 > 0 else '<'} 0 and {fn2} θ {'>' if s2 > 0 else '<'} 0"
        a, b = TR_FN[fn](th), TR_FN[fn2](th)
        ma, mb = TR_FN[fn](-th), TR_FN[fn2](-th)
        tr_claim(q, text(a, b), {CK: {text(ma, mb)}})
    elif u == "tan-undefined":
        t = R(g["t"])
        need(sp.cos(t * sp.pi) == 0, "tan has a value there")
        at = tr_angle(t)
        need(asked == f"Why does tan({at}) have no value?", asked)
        tr_claim(q, f"cos({at}) = 0, so sin ÷ cos divides by zero",
                 {TZ: {f"tan({at}) = 0, because the angle is on an axis", f"tan({at}) = 1, because sin and cos are equal there"}})
    else:
        need(False, f"no check for {u}")
    return None, None


def tr_mid(qd):
    """An angle in quadrant qd, to read signs from."""
    return sp.pi * sp.Rational(2 * qd - 1, 4)


def check_trig_identity(q):
    g, u, rep, L, asked = q["given"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    need(q["paper"] == 1, "every identity question is Paper 1")
    SG, DS, RT = "SL3.6.ratio-from-ratio#0", "SL3.6.ratio-from-ratio#1", "SL3.6.ratio-from-ratio#2"
    S2, C2, LS = "SL3.6.double-angle-values#0", "SL3.6.double-angle-values#1", "SL3.6.double-angle-values#2"
    EX, PR = "SL3.6.simplify#0", "SL3.6.simplify#1"

    def theta():
        """sin θ and cos θ from the shown ratio and quadrant alone."""
        qd = g["q"]
        size = sp.sqrt(R(g["top"])) / R(g["n"])
        need(size < 1, "the given ratio is out of range")
        mid = tr_mid(qd)
        rest = sp.sqrt(1 - size**2)
        if g["fn"] == "sin":
            sv, cv = sp.sign(sp.sin(mid)) * size, sp.sign(sp.cos(mid)) * rest
            shown = sv
        else:
            cv, sv = sp.sign(sp.cos(mid)) * size, sp.sign(sp.sin(mid)) * rest
            shown = cv
        tr_given(f"{g['fn']} θ = {tr_text(shown)}", qd, sv, cv)
        return sv, cv

    def tr_given(head, qd, sv, cv):
        if rep == "diagram":
            need(L[0].startswith(head + ". The point P"), f"can't read {L}")
            p = q["graph"]["points"][0]
            need(abs(p["x"] - float(cv)) < 1e-9 and abs(p["y"] - float(sv)) < 1e-9, "P is drawn in another place")
            need(q["graph"]["quadrant"] == qd, "another quadrant is shaded")
        else:
            need(L == [f"{head} and {['0 < θ < π/2', 'π/2 < θ < π', 'π < θ < 3π/2', '3π/2 < θ < 2π'][qd - 1]}."], f"can't read {L}")

    if u == "cos-from-sin":
        sv, cv = theta()
        tr_common(q, "cos θ = ", cv, {SG: [-cv], DS: [1 - sv]})
    elif u == "sin-from-cos":
        sv, cv = theta()
        tr_common(q, "sin θ = ", sv, {SG: [-sv], RT: [sp.sign(sv) * (1 - abs(cv))]})
    elif u == "tan-from-ratio":
        sv, cv = theta()
        tr_common(q, "tan θ = ", sv / cv, {SG: [-sv / cv]})
    elif u == "cos-from-tan":
        qd = g["q"]
        t = sp.sign(sp.tan(tr_mid(qd))) * sp.Rational(g["rise"], g["run"])
        cv = sp.sign(sp.cos(tr_mid(qd))) / sp.sqrt(1 + t**2)
        tr_given(f"tan θ = {frac_text(t)}", qd, t * cv, cv)
        tr_common(q, "cos θ = ", cv, {SG: [-cv]})
    elif u == "sin2-from-ratio":
        sv, cv = theta()
        w = {S2: [2 * sv]}
        if cv < 0:
            w[LS] = [2 * sv * abs(cv)]
        tr_common(q, "sin 2θ = ", 2 * sv * cv, w)
    elif u == "cos2-from-sin":
        sv, cv = theta()
        tr_common(q, "cos 2θ = ", cv**2 - sv**2, {C2: [1 - sv**2, 2 * cv]})
    elif u == "cos2-from-cos":
        sv, cv = theta()
        tr_common(q, "cos 2θ = ", cv**2 - sv**2, {C2: [2 * cv]})
    elif u == "cos-from-cos2":
        if rep == "diagram":
            a, b, c = R(g["a"]), R(g["b"]), R(g["c"])
            need(L == [f"In triangle ABC, AB = {c} cm, AC = {b} cm, BC = {a} cm and angle BAC = 2θ."], f"can't read {L}")
            need(a < b + c and b < a + c and c < a + b, "no such triangle")
            k = (b**2 + c**2 - a**2) / (2 * b * c)
            v = q["diagram"]["vertices"]
            need(abs(math.hypot(v["C"][0] - v["B"][0], v["C"][1] - v["B"][1]) - float(a)) < 1e-6, "the figure has another side")
        else:
            k = R(g["cos2"])
            need(L == [f"cos 2θ = {frac_text(k)} and 0 < θ < π/2."], f"can't read {L}")
        need(-1 < k < 1 and k != 0, "out of range")
        tr_common(q, "cos θ = ", sp.sqrt((1 + k) / 2), {C2: [k / 2]})
    elif u == "rewrite-in-sin":
        base, dbl, p, m, k = g["base"], g["src"] == "double", R(g["p"]), R(g["m"]), R(g["k"])
        x, y = sp.Symbol("x"), sp.Symbol("y")
        other = "cos" if base == "sin" else "sin"
        lead = f"{p} cos 2x" if dbl else f"{p} {other}²x"
        need(L[0].startswith(lead), f"can't read {L}")
        expr = p * (sp.cos(2 * x) if dbl else TR_FN[other](x)**2) + m * TR_FN[base](x) + k
        # The coefficients of the quadratic in u = sin x or cos x, from three values of x.
        a_, b_, c_ = sp.symbols("a_ b_ c_")
        eqs = [sp.Eq(a_ * TR_FN[base](t)**2 + b_ * TR_FN[base](t) + c_, expr.subs(x, t)) for t in (sp.pi / 6, sp.pi / 2, -sp.pi / 2, 0, sp.pi / 3)]
        sol = sp.solve(eqs[:3] if base == "sin" else [eqs[3], sp.Eq(a_ - b_ + c_, expr.subs(x, sp.pi)), eqs[4]], [a_, b_, c_])
        for e in eqs:
            need(sp.simplify(e.lhs.subs(sol) - e.rhs) == 0, "no quadratic fits")
        co = [int(sol[a_]), int(sol[b_]), int(sol[c_])]
        text = lambda c: tr_quad(c, base)
        w = {}
        if dbl:
            w[C2] = {text([int(-p), int(m), int(p + k)] if base == "sin" else [int(p), int(m), int(k)])}
        tr_hyphens(q)
        gc_check_common(q, text(co), w, steps=(2, 10))
    elif u == "single-cos":
        k, w_ = int(g["k"]), int(g["w"])
        inner = "" if w_ == 1 else str(w_)
        x = sp.Symbol("x")
        if g["from"] == "sin":
            need(L == [f"{k} − {2 * k} sin²{inner}x"], f"can't read {L}")
            e = k - 2 * k * sp.sin(w_ * x)**2
        else:
            need(L == [f"{2 * k} cos²{inner}x − {k}"], f"can't read {L}")
            e = 2 * k * sp.cos(w_ * x)**2 - k
        need(sp.simplify(e - k * sp.cos(2 * w_ * x)) == 0, "the identity fails")
        tr_hyphens(q)
        gc_check_common(q, f"{k} cos {2 * w_}x".replace("1 cos", "cos") if k > 1 else f"cos {2 * w_}x", {}, steps=(2, 10))
    elif u == "product-sine":
        k, w_ = int(g["k"]), int(g["w"])
        inner = "" if w_ == 1 else str(w_)
        need(L == [f"{2 * k} sin {inner}x cos {inner}x"], f"can't read {L}")
        x = sp.Symbol("x")
        need(sp.simplify(2 * k * sp.sin(w_ * x) * sp.cos(w_ * x) - k * sp.sin(2 * w_ * x)) == 0, "the identity fails")
        tr_hyphens(q)
        gc_check_common(q, f"{k} sin {2 * w_}x" if k > 1 else f"sin {2 * w_}x", {PR: {f"{2 * k} sin {2 * w_}x"}}, steps=(2, 10))
    elif u == "expand-square":
        k, minus = int(g["k"]), g["minus"]
        need(L == [f"{'' if k == 1 else k}(sin x {'−' if minus else '+'} cos x)²"], f"can't read {L}")
        x = sp.Symbol("x")
        b = -k if minus else k
        need(sp.simplify(k * (sp.sin(x) + (-1 if minus else 1) * sp.cos(x))**2 - (k + b * sp.sin(2 * x))) == 0, "the identity fails")
        tr_hyphens(q)
        gc_check_common(q, f"{k} {'−' if minus else '+'} {'' if k == 1 else str(k) + ' '}sin 2x", {EX: {str(k)}}, steps=(2, 10))
    elif u == "max-after-rewrite":
        k, w_, d = int(g["k"]), int(g["w"]), int(g["d"])
        x = sp.Symbol("x")
        top = sp.maximum(k * sp.sin(2 * w_ * x) + d, x, sp.Interval(0, sp.pi))
        tr_hyphens(q)
        gc_check_common(q, f"maximum = {frac_text(top)}", {PR: {f"maximum = {frac_text(2 * k + d)}"}}, steps=(2, 10))
    else:
        need(False, f"no check for {u}")
    return None, None


def tr_quad(c, fn):
    def term(v, body, first):
        size = "" if abs(v) == 1 else f"{abs(v)} "
        if first:
            return ("−" if v < 0 else "") + size + body
        return f" {'+' if v > 0 else '−'} {size}{body}"
    out = term(c[0], f"{fn}²x", True)
    if c[1]:
        out += term(c[1], f"{fn} x", False)
    if c[2]:
        out += f" {'+' if c[2] > 0 else '−'} {abs(c[2])}"
    return out


TQ_NS = {"pi": math.pi, "sqrt": math.sqrt}


def tq_python(text):
    """A side of an equation as the game writes it, as Python: the checker reads what is shown."""
    t = text.replace("−", "-").replace("π", "pi").replace("θ", "x").replace("°", "")
    t = re.sub(r"√(\d+)", r"sqrt(\1)", t)
    t = re.sub(r"(sin|cos|tan)²x", r"\1(x)**2", t)
    t = re.sub(r"(sin|cos|tan) (\d*)x", lambda m: f"{m.group(1)}({m.group(2) + '*' if m.group(2) else ''}x)", t)
    t = re.sub(r"(\d)(x|pi)", r"\1*\2", t)
    t = re.sub(r"(\d|\))\s*(sin|cos|tan|sqrt)", r"\1*\2", t)
    t = t.replace(")(", ")*(")
    return t


def tq_function(line, deg):
    """f(x) = left − right, from the shown equation, in radians or degrees."""
    left, right = [tq_python(p.strip()) for p in line.split(" = ")]
    ns = dict(TQ_NS)
    k = math.pi / 180 if deg else 1.0
    ns["sin"], ns["cos"], ns["tan"] = (lambda u: math.sin(u * k)), (lambda u: math.cos(u * k)), (lambda u: math.tan(u * k))
    code = compile(f"({left}) - ({right})", "shown", "eval")
    return lambda x: eval(code, ns, {"x": x})


def tq_roots(f, lo, hi, open_hi, deg, step):
    """Every root of f on the interval: on a grid of the angles that can come out exactly, and
    any sign change between those that isn't one of them is a failure."""
    n = round((hi - lo) / step)
    roots = []
    grid = [lo + i * step for i in range(n + 1)]
    for x in grid:
        if abs(f(x)) < 1e-9 and not (open_hi and x == grid[-1]):
            roots.append(x)
    fine = 900
    last = None
    limit = 1e6
    for i in range(fine + 1):
        x = lo + (hi - lo) * (i + 0.37) / (fine + 1)
        y = f(x)
        if last is not None and last * y < 0 and abs(y) < limit and abs(last) < limit and abs(y - last) < 3:
            need(any(abs(r - x) < 2 * (hi - lo) / fine for r in roots), f"the equation has a root near {x}")
        last = y
    return roots


def tq_names(roots, deg):
    if deg:
        return [dec_text(sp.Rational(round(x * 2), 2)) + "°" for x in roots]
    names = []
    for x in roots:
        m = sp.Rational(round(x / math.pi * 144), 144)
        need(abs(float(m) * math.pi - x) < 1e-9, f"{x} is no multiple of π")
        names.append(tr_angle(m))
    return names


def tq_list(names):
    if not names:
        return None
    return "x = " + (names[0] if len(names) == 1 else ", ".join(names[:-1]) + " or " + names[-1])


def tq_solve(fn, k, b, phi, lo, hi, open_hi=False, deg=False):
    """fn(bx + φ) = k on an interval given in the unit of x, the checker's own sweep."""
    u = 180.0 if deg else math.pi
    step = 2.5 if deg else math.pi / 144
    g = {"sin": math.sin, "cos": math.cos, "tan": math.tan}[fn]
    pi_ = math.pi
    f = (lambda x: g(b * x * (pi_ / 180) + phi * pi_) - k) if deg else (lambda x: g(b * x + phi * pi_) - k)
    n = round((hi - lo) / step)
    out = []
    for i in range(n + 1):
        x = lo + i * step
        if abs(f(x)) < 1e-9 and not (open_hi and i == n):
            out.append(x)
    return tq_names(out, deg)


def check_trig_equation(q):
    g, u, rep, L, asked = q["given"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"]
    need(q["paper"] == (2 if u in ("basic-decimal", "compound-decimal") else 1), f"paper {q['paper']} for {u}")
    tr_hyphens(q)
    B0, B1, B2 = "SL3.8.solve-basic#0", "SL3.8.solve-basic#1", "SL3.8.solve-basic#2"
    K0, K1, K2 = "SL3.8.compound-angle#0", "SL3.8.compound-angle#1", "SL3.8.compound-angle#2"
    F0, F1, F2 = "SL3.8.factorise-not-divide#0", "SL3.8.factorise-not-divide#1", "SL3.8.factorise-not-divide#2"
    Q1 = "SL3.8.quadratic-in-trig#1"
    deg = g["form"] == "deg"
    if u == "factor-reject":
        m = R(g["m"])
        side = {1: "sin θ cos θ", -1: "−sin θ cos θ"}.get(m, f"{frac_text(m)} sin θ cos θ")
        need(L == [f"sin²θ = {side}, for 0 < θ < π"], f"can't read {L}")
        f = tq_function(L[0].split(",")[0], False)
        t = math.atan2(float(m), 1.0)
        t = t if t > 0 else t + math.pi
        need(abs(f(t)) < 1e-9, "tan θ doesn't solve the equation")
        tr_common(q, "tan θ = ", m, {F1: [1 / m]})
        return None, None
    if u == "least-positive":
        f = tq_function(L[0], False)
        step = math.pi / 144
        roots = tq_roots(f, step, 8 * math.pi, False, False, step)
        need(len(roots) > 0, "no positive solution")
        want = tq_list(tq_names(roots[:1], False))
        phi, b = float(R(g["phi"])), float(R(g["b"]))
        w = tq_solve(g["fn"], tr_val_float(g["k"]), b, -phi, step, 8 * math.pi)
        gc_check_common(q, want, {K2: {tq_list(w[:1])}} if w else {}, steps=(2, 6))
        return None, None
    line = L[0]
    mt = re.fullmatch(r"(.+), for (.+) ≤ x (≤|<) (.+)", line)
    need(mt is not None, f"can't read {line!r}")
    open_hi = mt.group(3) == "<"
    read_end = lambda e: float(sp.sympify(tq_python(e), {"pi": sp.pi}))
    lo, hi = read_end(mt.group(2)), read_end(mt.group(4))
    need(lo == float(R(g["lo"]) * (180 if deg else sp.pi)) and hi == float(R(g["hi"]) * (180 if deg else sp.pi)), "the interval is another one")
    f = tq_function(mt.group(1), deg)
    if u in ("basic-decimal", "compound-decimal"):
        fn, k, b = g["fn"], R(g["k"]), int(R(g["b"]))
        ks = float(k)
        mpmath.mp.dps = 30
        need(abs(k) < 1 or fn == "tan", "k is out of range")
        base = {"sin": [mpmath.asin(ks), mpmath.pi - mpmath.asin(ks)], "cos": [mpmath.acos(ks), -mpmath.acos(ks)], "tan": [mpmath.atan(ks)]}[fn]
        period = mpmath.pi if fn == "tan" else 2 * mpmath.pi
        xs = sorted({round(float((u0 + n * period) / b), 9) for u0 in base for n in range(-6, 12) if -1e-9 <= (u0 + n * period) / b <= hi + 1e-9})
        need(all(abs(f(x)) < 1e-6 for x in xs), "the solutions don't solve the equation")
        vals = [sp.Float(str(x), 12) for x in xs]
        names = [gc_s(v) for v in vals]
        want = "x = " + (names[0] if len(names) == 1 else ", ".join(names[:-1]) + " or " + names[-1])
        w = {}
        if u == "basic-decimal" and len(xs) > 1:
            w[B0] = {f"x = {names[0]}"}
        if u == "compound-decimal":
            kept = [gc_s(v) for v, x in zip(vals, xs) if x * b <= hi + 1e-9]
            if len(kept) < len(names):
                w[K0] = {"x = " + (kept[0] if len(kept) == 1 else ", ".join(kept[:-1]) + " or " + kept[-1])}
        gc_check_common(q, want, w, gc_trap(vals, gc_xs2(vals)), steps=(2, 6))
        return None, None
    step = 2.5 if deg else math.pi / 144
    roots = tq_roots(f, lo, hi, open_hi, deg, step)
    need(1 <= len(roots) <= 8, f"{len(roots)} solutions")
    names = tq_names(roots, deg)
    want = tq_list(names)
    w = {}
    fn = g["fn"]
    b, phi = float(R(g["b"])), float(R(g["phi"]))
    ks = tr_val_float(g["k"]) if "k" in g else None
    sv = lambda fn_, k_, bb=1.0, ph=0.0: tq_solve(fn_, k_, bb, ph, lo, hi, open_hi, deg)
    d = math.degrees if deg else (lambda v: v)
    if u in ("basic-exact", "wide-interval", "basic-degrees"):
        need(ks is not None and abs(ks) <= 2, "k is out of range")
        al = {"sin": math.asin, "cos": math.acos, "tan": math.atan}[fn](ks)
        if len(roots) > 1:
            w[B0] = {tq_list(tq_names([d(al)], deg))}
        if fn == "cos":
            pair = sorted({round(v, 9) for v in (d(al), d(math.pi - al)) if lo - 1e-9 <= v <= hi + 1e-9})
            if pair:
                w[B1] = {tq_list(tq_names(pair, deg))}
        if u == "wide-interval" and lo < 0:
            pos = [r for r in roots if r >= -1e-9]
            if pos:
                w[B2] = {tq_list(tq_names(pos, deg))}
    elif u in ("multiple-angle", "shifted-angle", "degree-compound"):
        al = {"sin": math.asin, "cos": math.acos, "tan": math.atan}[fn](ks)
        ph_x = phi * (180 if deg else math.pi)
        if b > 1:
            kept = [r for r in roots if b * r <= hi + 1e-9]
            if kept and len(kept) < len(roots):
                w[K0] = {tq_list(tq_names(kept, deg))}
            w[K1] = {tq_list(tq_names([(d(al) - ph_x) / b], deg))}
        if phi != 0:
            alt = sv(fn, ks, b, -phi)
            if alt:
                w[K2] = {tq_list(alt)}
    elif u == "tan-compound":
        w[K1] = {tq_list(tq_names([math.atan(ks) / b], deg))}
    elif u == "k-cos-to-tan":
        w[F1] = {tq_list(sv("tan", 1 / ks))}
    elif u == "double-equals-cos":
        w[F0] = {tq_list(sv("sin", ks))}
    elif u == "double-equals-sin":
        w[F0] = {tq_list(sv("cos", ks))}
        if abs(ks - 0.5) < 1e-9:
            w[F2] = {"x = 0"}
    elif u == "product-zero":
        w[F0] = {tq_list(sv(g["f2"], ks))}
    elif u == "squares-to-tan":
        w[Q1] = {tq_list(sv("tan", ks))}
    else:
        need(False, f"no check for {u}")
    gc_check_common(q, want, w, steps=(2, 7))
    if rep == "graph" and u in ("basic-exact", "wide-interval", "multiple-angle", "shifted-angle"):
        need(abs(q["graph"]["hlines"][0]["at"] - ks) < 1e-9, "the dashed line is at another height")
    return None, None


def tr_val_float(v):
    """A value [a, b, r] of the export: a + b√r."""
    return float(R(v[0])) + float(R(v[1])) * math.sqrt(float(v[2]))


TM_CONTEXTS = [("D", "m", "hours"), ("T", "°C", "hours"), ("h", "m", "minutes"), ("L", "m", "days"), ("P", "kW", "minutes"), ("R", "m", "hours")]
TM_P2_ONLY = ("sum-as-cos", "tan-two-points", "wheel-model", "c-from-crossing", "level-from-duration")


def tm_f(v):
    """An exact value as gc_s takes it."""
    return v if isinstance(v, sp.Rational) else sp.Float(sp.N(v, 30), 30)


def tm_named(pairs, sf=True):
    return ", ".join(f"{n} = {gc_s(tm_f(v)) if sf else dec_text(v)}" for n, v in pairs)


def tm_x(paper, v):
    return as_pi(v) if paper == 1 else dec_text(v)


def tm_wave(q):
    """The wave's numbers from its turning points alone, and the figure held to them."""
    g, rep, L, paper = q["given"], q["view"]["rep"], q["lines"], q["paper"]
    top, low, xm, xn = R(g["top"]), R(g["low"]), R(g["xmax"]), R(g["xmin"])
    need(top > low and xn > xm, "the turning points are in the wrong order")
    a, d = (top - low) / 2, (top + low) / 2
    per = 2 * (xn - xm)
    if paper == 1:
        need(a.q == 1 and d.q == 1, "a and d are not whole on Paper 1")
        b = 1 / (per / 2)
        need(b.q == 1, "b is not whole on Paper 1")
        need(R(g["w"]) == b, "the given b is not the turning points' b")
    else:
        need(R(g["period"]) == per, "the given period is not the turning points' period")
        b = 2 * sp.pi / per
    tp = f"({tm_x(paper, xm)}, {dec_text(top)})"
    bp = f"({tm_x(paper, xn)}, {dec_text(low)})"
    if rep == "graph":
        gr = q["graph"]
        need([p["label"] for p in gr["points"]] == [f"max {tp}", f"min {bp}"], "the turning points are labelled wrongly")
        s = math.pi if paper == 1 else 1.0
        bf = float(b)
        pts = gr["curves"][0]
        for x, y in pts[::17]:
            need(abs(y - (float(a) * math.cos(bf * (x - float(xm) * s)) + float(d))) < 1e-6, "the curve is another wave")
    elif rep == "words":
        c = TM_CONTEXTS[g["ctx"]]
        need(L[1] == f"Its largest value is {dec_text(top)} {c[1]}, at t = {dec_text(xm)}, and its next smallest value is {dec_text(low)} {c[1]}, at t = {dec_text(xn)}.", f"can't read {L}")
    else:
        need(L[1] == f"A maximum is at {tp} and the next minimum at {bp}.", f"can't read {L}")
    return a, b, d, xm, xn, per


def tm_num(q, label, v, wrongs, steps=(2, 7)):
    v = tm_f(v)
    want = label + gc_s(v)
    gc_check_common(q, want, {k: {label + gc_s(tm_f(w)) for w in vs} for k, vs in wrongs.items()}, gc_trap([v], label + gc_s2(v)), steps=steps)


def tm_c_text(paper, v):
    return "c = " + (as_pi(v) if paper == 1 else dec_text(v))


def check_trig_model(q):
    g, u, rep, L, asked, paper = q["given"], q["view"]["unknown"], q["view"]["rep"], q["lines"], q["asked"], q["paper"]
    need(paper == (1 if u == "q-from-minimum" else 2) if u == "q-from-minimum" or u in TM_P2_ONLY else paper in (1, 2), f"paper {paper} for {u}")
    need(rep != "words" or paper == 2, "a story is Paper 2")
    PG, NH, CS = "SL3.7.equation-from-graph#0", "SL3.7.equation-from-graph#1", "SL3.7.equation-from-graph#2"
    SB, ST, RG = "SL3.7.transformations#0", "SL3.7.transformations#1", "SL3.7.transformations#2"
    DG, PB = "SL3.7.model-context#0", "SL3.7.model-context#2"
    tr_hyphens(q)
    if u == "amp-axis":
        a, b, d, *_ = tm_wave(q)
        gc_check_common(q, tm_named([("a", a), ("d", d)], False), {NH: {tm_named([("a", 2 * a), ("d", d)], False)}})
    elif u == "b-from-period":
        a, b, d, xm, xn, per = tm_wave(q)
        if paper == 1:
            gc_check_common(q, f"b = {dec_text(b)}", {PG: {f"b = {dec_text(2 * b)}"}})
        else:
            tm_num(q, "b = ", b, {PG: [2 * b], PB: [per]})
    elif u == "c-cos-from-max":
        a, b, d, xm, xn, per = tm_wave(q)
        need(0 < xm < per, "c is not the smallest positive")
        gc_check_common(q, tm_c_text(paper, xm), {CS: {tm_c_text(paper, -xm)}})
    elif u == "c-sine-shift":
        a, b, d, xm, xn, per = tm_wave(q)
        c = xm - per / 4
        need(0 < c < per, "c is not the smallest positive")
        gc_check_common(q, tm_c_text(paper, c), {CS: {tm_c_text(paper, -c)}})
    elif u == "all-four":
        a, b, d, xm, xn, per = tm_wave(q)
        if paper == 1:
            t = lambda a_, b_, c_, d_: f"a = {dec_text(a_)}, b = {dec_text(b_)}, c = {as_pi(c_)}, d = {dec_text(d_)}"
        else:
            t = lambda a_, b_, c_, d_: tm_named([("a", a_), ("b", b_), ("c", c_), ("d", d_)])
        gc_check_common(q, t(a, b, xm, d), {NH: {t(2 * a, b, xm, d)}, PG: {t(a, 2 * b, xm, d)}, CS: {t(a, b, -xm, d)}}, steps=(2, 6))
    elif u == "q-from-minimum":
        p, m, phi, fn = R(g["p"]), R(g["m"]), R(g["phi"]), g["fn"]
        need(L[0] == f"f(x) = {p} {fn}(x + {as_pi(phi)}) + q", f"can't read {L}")
        qv = m + p
        tr_common(q, "f(0) = ", p * tr_of(fn, phi) + qv, {NH: [p * tr_of(fn, phi) + m]})
    elif u == "sum-as-cos":
        p, q0, k = R(g["p"]), R(g["q0"]), R(g["k"])
        ks = "" if k == 1 else str(k)
        need(L[0] == f"g(x) = {p} sin {ks}x + {q0} cos {ks}x", f"can't read {L}")
        x = sp.Symbol("x")
        amp = sp.sqrt(p**2 + q0**2)
        c = sp.atan2(p, q0) / k
        need(sp.simplify(p * sp.sin(k * x) + q0 * sp.cos(k * x) - amp * sp.cos(k * (x - c))).equals(0) in (True, None), "the two forms differ")
        for t_ in (0.3, 1.1):
            need(abs(float(p) * math.sin(float(k) * t_) + float(q0) * math.cos(float(k) * t_) - float(amp) * math.cos(float(k) * (t_ - float(c)))) < 1e-9, "the two forms differ")
        t = lambda a_, c_: tm_named([("a", a_), ("b", k), ("c", c_)])
        gc_check_common(q, t(amp, c), {NH: {t(2 * amp, c)}, CS: {t(amp, -c)}}, steps=(2, 6))
    elif u == "tan-two-points":
        z, h, v = R(g["z"]), R(g["h"]), R(g["v"])
        need(h < z / 2, "the point is past the asymptote")
        b = sp.pi / z
        a = v / sp.tan(b * h)
        b2 = 2 * sp.pi / z
        t = lambda a_, b_: tm_named([("a", a_), ("b", b_)])
        gc_check_common(q, t(a, b), {PG: {t(v / sp.tan(b2 * h), b2)}}, steps=(2, 6))
    elif u == "shift-from-bracket":
        bw, phi, right = R(g["bw"]), R(g["phi"]), g["right"]
        c = phi / bw if right else -phi / bw
        phi_s = phi if right else -phi
        need(f"{bw}x {'−' if right else '+'} {tm_x(paper, phi)}" in L[0], f"can't read {L}")
        ct = lambda v: "c = " + tm_x(paper, v)
        gc_check_common(q, ct(c), {SB: {ct(phi_s)}, RG: {ct(-c)}})
    elif u == "image-equation":
        amp, bw, lift, fn = int(g["amp"]), int(g["bw"]), int(g["lift"]), g["fn"]
        need(L[0] == f"f(x) = {amp} {fn}({bw}x) {'+' if lift > 0 else '−'} {abs(lift)}", f"can't read {L}")
        tail = lambda v: "" if v == 0 else f" {'+' if v > 0 else '−'} {abs(v)}"
        if g["kind"] == "translate":
            c, up = R(g["mv"]), int(g["up"])
            need(f"({tm_x(paper, c)}, {frac_text(up)})" in L[1] or rep == "words", f"can't read {L}")
            img = lambda v: f"g(x) = {amp} {fn}({bw}(x {'−' if v > 0 else '+'} {tm_x(paper, abs(v))})){tail(lift + up)}"
            gc_check_common(q, img(c), {RG: {img(-c)}})
        else:
            sf = int(g["sf"])
            d = sp.Rational(bw, sf)
            dt = dec_text(d) if d.q == 1 else f"({frac_text(d)})"
            gc_check_common(q, f"g(x) = {amp} {fn}({bw * sf}x){tail(lift)}", {ST: {f"g(x) = {amp} {fn}({dt}x){tail(lift)}"}})
    elif u == "describe-transformations":
        amp, bw, lift, fn, phi, right = int(g["amp"]), int(g["bw"]), int(g["lift"]), g["fn"], R(g["phi"]), g["right"]
        need(L[0] == f"y = {amp} {fn}({bw}x {'−' if right else '+'} {tm_x(paper, phi)}) {'+' if lift > 0 else '−'} {abs(lift)}", f"can't read {L}")
        c = phi / bw if right else -phi / bw
        t = lambda sf, v: f"A vertical stretch with scale factor {amp}, a horizontal stretch with scale factor {sf}, then a translation by ({tm_x(paper, v)}, {frac_text(lift)})"
        # The image of a test point under the right chain must be on the graph.
        x0 = 0.4
        f0 = {"sin": math.sin, "cos": math.cos}[fn]
        s_ = math.pi if paper == 1 else 1.0
        need(abs(amp * f0(x0) + lift - (amp * f0(bw * (x0 / bw + float(c) * s_) - (float(phi) * s_ if right else -float(phi) * s_)) + lift)) < 1e-9, "the chain is not the graph")
        gc_check_common(q, t(f"1/{bw}", c), {SB: {t(f"1/{bw}", phi if right else -phi)}, ST: {t(str(bw), c)}, RG: {t(f"1/{bw}", -c)}})
    elif u == "pq-from-translation":
        amp, bw, up, fn, phi, right = int(g["amp"]), int(g["bw"]), int(g["up"]), g["fn"], R(g["phi"]), g["right"]
        p = phi / bw if right else -phi / bw
        t = lambda p_, q_: f"p = {tm_x(paper, p_)}, q = {frac_text(q_)}"
        need(L[0] == f"f(x) = {amp} {fn}({bw}x)", f"can't read {L}")
        gc_check_common(q, t(p, up), {SB: {t(phi if right else -phi, up)}, RG: {t(-p, up)}})
    elif u == "wheel-model":
        dia, base, per = R(g["dia"]), R(g["base"]), R(g["period"])
        if rep == "words":
            need(L[0] == f"A wheel of diameter {dia} m turns once every {dec_text(per)} minutes. Its lowest seat passes {base} m above the ground, and a seat starts at the lowest point at t = 0.", f"can't read {L}")
        else:
            pts = q["graph"]["points"]
            need(abs(pts[0]["y"] - float(base)) < 1e-9 and abs(pts[1]["y"] - float(base + dia)) < 1e-9 and abs(pts[1]["x"] - float(per) / 2) < 1e-9, "the figure has other numbers")
        a, b, d = -dia / 2, 2 * sp.pi / per, base + dia / 2
        t = lambda b_: tm_named([("a", a), ("b", b_), ("d", d)])
        gc_check_common(q, t(b), {PB: {t(per)}, PG: {t(2 * b)}})
    elif u == "c-from-crossing":
        top, low, t1, level, per = R(g["top"]), R(g["low"]), R(g["t1"]), R(g["level"]), R(g["period"])
        a, d = (top - low) / 2, (top + low) / 2
        with mpmath.workdps(40):
            r = sp.Rational(level - d) / a
            need(abs(r) < 1, "the level is out of range")
            b = 2 * sp.pi / per
            c = t1 - sp.asin(r) / b
            cd = t1 - (sp.asin(r) * 180 / sp.pi) / b
            need(abs(sp.N(a * sp.sin(b * (t1 - c)) + d - level)) < 1e-20, "the crossing is wrong")
            need(sp.N(sp.cos(b * (t1 - c))) > 0, "the model is not rising there")
            tm_num(q, "c = ", c, {DG: [cd]})
    elif u == "level-from-duration":
        top, low, width, per, xm = R(g["top"]), R(g["low"]), R(g["width"]), R(g["period"]), R(g["xmax"])
        a, d = (top - low) / 2, (top + low) / 2
        b = 2 * sp.pi / per
        need(0 < width < per, "the time above k is out of range")
        k = a * sp.cos(b * width / 2) + d
        kd = a * sp.cos(b * width / 2 * sp.pi / 180) + d
        tm_num(q, "k = ", k, {DG: [kd]})
    else:
        need(False, f"no check for {u}")
    return None, None


SITUATION_CHECKS = {"quadratic": check_quadratic, "triangle": check_triangle, "arithmetic-sequence": check_arithmetic,
                    "distribution": check_distribution, "cubic": check_cubic,
                    "quadratic-parameter": check_qparam, "curve-and-line": check_curve_line,
                    "quadratic-equation": check_qeq, "quadratic-inequality": check_qineq,
                    "fn-pre-expand": check_expand, "fn-pre-factorise": check_factorise,
                    "fn-pre-surds": check_surds, "fn-pre-linear-inequalities": check_lineq,
                    "quadratic-model": check_qmodel, "fn-link-equivalent-forms": check_eqforms,
                    "fn-link-symmetry": check_symmetry, "exp-model": check_exp_model, "exp-log-pair": check_exp_log_pair, "log-quadratic": check_log_quadratic, "log-function": check_log_function, "fn-pre-percent-multiplier": check_percent, "exp-growth-vs-linear": check_growth, "fn-link-multiplicative-growth": check_link_growth,
                    "gdc-curve": check_gdc_curve, "gdc-two-curves": check_gdc_two_curves,
                    "gdc-combined": check_gdc_combined,
                    "gdc-context-equation": check_gdc_context_equation,
                    "graph-from-features": check_graph_from_features,
                    "gdc-inequality": check_gdc_inequality,
                    "fn-pre-graph-reading": check_graph_reading,
                    "graph-match": check_graph_match,
                    "fn-link-extremes": check_link_extremes,
                    "fn-link-graph-vs-algebra": check_link_graph_algebra,
                    "binomial": check_binomial, "data-summary": check_data_summary, "regression": check_regression,
                    "composite-pair": check_composite, "inverse-rule": check_inverse, "composite-graph-table": check_graph_table, "fn-pre-rearrange": check_rearrange, "rational-function": check_rational, "fn-pre-algebraic-fractions": check_algfrac, "rational-asymptote-gallery": check_gallery, "rational-model": check_model,
                    "compound-interest": check_compound_interest,
                    "differentiation": check_differentiation, "derivative-meaning": check_derivative_meaning,
                    "monotonic": check_monotonic, "concavity": check_concavity,
                    "integration": check_integration, "definite-integral": check_definite_integral,
                    "motion": check_motion, "regression-x-on-y": check_regression_pair, "normal-unknown": check_normal_unknown, "venn": check_venn, "conditional": check_conditional,
                    "sampling": check_sampling, "cumulative-frequency": check_cumulative_frequency,
                    "arc-sector": check_arc_sector, "bearings-elevation": check_bearings, "exact-trig": check_exact_trig, "trig-identity": check_trig_identity, "trig-equation": check_trig_equation, "trig-model": check_trig_model,
                    "solid": check_solid, "standard-form": check_standard_form}


# ── Boss chains (FAL-415) ────────────────────────────────────

def check_chain(parts):
    """The parts of one mini-boss or boss: one situation, and each part carries the
    part before's right answer (IB follow-through). Each part is also checked on its
    own, so the carried value is the true value of the situation its givens describe."""
    parts = sorted(parts, key=lambda q: q["part"])
    need([q["part"] for q in parts] == list(range(len(parts))), "parts are not (a), (b), ... in order")
    need(len(parts) >= 2, "a chain of one part")
    for prev, q in zip(parts, parts[1:]):
        need(q["situation"] == parts[0]["situation"], f"part {q['part']} is on another situation")
        need(q["situation_id"] == parts[0]["situation_id"], f"part {q['part']} is on another kind of situation")
        c = q.get("carried")
        need(c is not None, f"part {q['part']} carries nothing on")
        need(c["values"] == prev["answer"]["values"], f"part {q['part']} carries {c['values']}, not the answer {prev['answer']['values']}")
        need(c["text"] == prev["answer_text"], f"part {q['part']} shows {c['text']!r}, not {prev['answer_text']!r}")
        need(c["part"] == "abcdefgh"[prev["part"]], f"part {q['part']} names the wrong part")


def check_questions(data):
    """Checks every question in an export. The summary is all the report needs."""
    qs = data["questions"]
    by_cell = defaultdict(lambda: [0, 0])
    by_type = defaultdict(lambda: [0, 0])
    failures = []
    for q in qs:
        cell = q["cell"]
        t = q["view"]["type"]
        ok = True
        try:
            check(q)
        except Fail as e:
            ok = False
            failures.append(f"{cell} seed {q['view']['seed']} ({q['format']}): {e}")
        except Exception as e:  # a checker crash on a question counts as a failure
            ok = False
            failures.append(f"{cell} seed {q['view']['seed']} ({q['format']}): checker error {type(e).__name__}: {e}")
        by_cell[cell][0] += 1
        by_type[t][0] += 1
        if not ok:
            by_cell[cell][1] += 1
            by_type[t][1] += 1

    chains = defaultdict(list)
    for q in qs:
        if "chain" in q:
            chains[q["chain"]].append(q)
    chain_failures = []
    for name, parts in chains.items():
        try:
            check_chain(parts)
        except Fail as e:
            chain_failures.append(f"{name}: {e}")
    failures += [f"chain {m}" for m in chain_failures]

    return {
        "shard": data.get("shard", [1, 1]),
        "by_cell": by_cell,
        "by_type": by_type,
        "failures": failures,
        "chains": len(chains),
        "chain_parts": sum(len(v) for v in chains.values()),
        "chain_failures": len(chain_failures),
        "problems": [f"export error: {e['view']}: {e['error']}" for e in data.get("errors", [])],
        "error_types": [e["view"]["type"] for e in data.get("errors", [])],
    }


def merged_summaries(root):
    """All the shards' summaries as one, with a problem for any shard not there once."""
    parts = [json.loads(p.read_text()) for p in sorted(Path(root).rglob("summary.json"))]
    if not parts:
        sys.exit(f"FAIL no summary.json under {root}")
    n = parts[0]["shard"][1]
    seen = sorted(p["shard"][0] for p in parts)
    out = {
        "shard": [1, 1],
        "by_cell": defaultdict(lambda: [0, 0]),
        "by_type": defaultdict(lambda: [0, 0]),
        "failures": [],
        "chains": 0,
        "chain_parts": 0,
        "chain_failures": 0,
        "problems": [],
        "error_types": [],
    }
    if seen != list(range(1, n + 1)) or any(p["shard"][1] != n for p in parts):
        out["problems"].append(f"shards: have {[p['shard'] for p in parts]}, want each of 1 to {n} once")
    for p in parts:
        for key in ("by_cell", "by_type"):
            for k, (made, bad) in p[key].items():
                out[key][k][0] += made
                out[key][k][1] += bad
        for key in ("failures", "problems", "error_types"):
            out[key] += p[key]
        for key in ("chains", "chain_parts", "chain_failures"):
            out[key] += p[key]
    return out


def report(s):
    """Prints the tables. Coverage only counts when the summary is the whole catalogue."""
    by_cell, by_type = s["by_cell"], s["by_type"]
    failures, problems = s["failures"], s["problems"]
    whole = s["shard"][1] == 1
    if not whole:
        print(f"Shard {s['shard'][0]} of {s['shard'][1]}: coverage is checked when the shards are merged")
        print()
    types = sorted(by_type)
    cat = catalogue_cells(set(types) | set(s["error_types"]))

    print("Per type")
    print(f"  {'type':34} {'questions':>9} {'failed':>7} {'cells':>13}")
    for t in sorted(cat):
        made = sum(1 for c in cat[t] if by_cell[c][0] > 0)
        print(f"  {t:34} {by_type[t][0]:>9} {by_type[t][1]:>7} {made:>6} of {len(cat[t]):<4}")
        if whole and by_type[t][0] < MIN_PER_TYPE:
            problems.append(f"{t}: {by_type[t][0]} questions, fewer than {MIN_PER_TYPE}")
    print()
    print("Per cell (type | unknown | representation | angle)")
    print(f"  {'cell':100} {'questions':>9} {'failed':>7}")
    for t in sorted(cat):
        for c in cat[t]:
            n, bad = by_cell[c]
            if whole or n:
                print(f"  {c:100} {n:>9} {bad:>7}")
            if whole and n < MIN_PER_CELL:
                problems.append(f"{c}: {n} questions, fewer than {MIN_PER_CELL}")
    extra = sorted(set(by_cell) - {c for cs in cat.values() for c in cs})
    for c in extra:
        problems.append(f"{c}: not a catalogue cell")
    print()
    total = sum(v[0] for v in by_type.values())
    print(f"Boss chains: {s['chains']}, {s['chain_parts']} parts, {s['chain_failures']} failed")
    print(f"{total} questions, {len(failures)} failed, {sum(len(v) for v in cat.values())} catalogue cells")
    for msg in failures[:40]:
        print("FAIL " + msg)
    if len(failures) > 40:
        print(f"... and {len(failures) - 40} more")
    for msg in problems:
        print("FAIL " + msg)
    return 1 if failures or problems else 0


def main():
    if sys.argv[1:2] == ["--merge"]:
        sys.exit(report(merged_summaries(sys.argv[2])))
    path = Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / "_scratch/check-answers/questions.json")
    summary = check_questions(json.loads(path.read_text()))
    path.with_name("summary.json").write_text(json.dumps(summary))
    sys.exit(report(summary))


if __name__ == "__main__":
    main()
