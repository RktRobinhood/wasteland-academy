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
any type fewer than 1,000.

    tools/check-answers            (exports, then runs this)
    python3 tools/check_answers.py questions.json
"""

import json
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

def check(q):
    """Routes a question to its situation's checks, then checks the answer, the
    options and the worked solutions the same way for every situation. A question in
    an extra format (FAL-459) has its own four options checked first, then the
    question it is built on, with that question's own options."""
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


def check_triangle(q):
    g = q["given"]
    u = q["view"]["unknown"]
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
    "log(aⁿ) = n log a": lambda a, b: (sp.log(a**3, 10), 3 * sp.log(a, 10)),
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
            m = re.fullmatch(r"ⁿC(\d+) = ⁿC(\d+), and \d+ ≠ \d+\.", L[0]) if rep == "words" else None
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
        say = lambda asym, a_, b_, up_: el_m_text(f"asymptote y = {asym}, through {a_} and {b_}, {'increasing' if up_ else 'decreasing'}")
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
def tc_crossings(f, g, lo, hi, open_left):
    a = lo + sp.Rational(1, 1000) if open_left else lo
    ff = gc_f(f)
    return tuple((x, ff(x)) for x in gc_zeros(f - g, a, hi))


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
                    "graph-from-features": check_graph_from_features}


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


def main():
    path = Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / "_scratch/check-answers/questions.json")
    data = json.loads(path.read_text())
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

    types = sorted(by_type)
    cat = catalogue_cells(set(types) | {e["view"]["type"] for e in data.get("errors", [])})
    problems = [f"export error: {e['view']}: {e['error']}" for e in data.get("errors", [])]

    print("Per type")
    print(f"  {'type':34} {'questions':>9} {'failed':>7} {'cells':>13}")
    for t in sorted(cat):
        made = sum(1 for c in cat[t] if by_cell[c][0] > 0)
        print(f"  {t:34} {by_type[t][0]:>9} {by_type[t][1]:>7} {made:>6} of {len(cat[t]):<4}")
        if by_type[t][0] < MIN_PER_TYPE:
            problems.append(f"{t}: {by_type[t][0]} questions, fewer than {MIN_PER_TYPE}")
    print()
    print("Per cell (type | unknown | representation | angle)")
    print(f"  {'cell':100} {'questions':>9} {'failed':>7}")
    for t in sorted(cat):
        for c in cat[t]:
            n, bad = by_cell[c]
            print(f"  {c:100} {n:>9} {bad:>7}")
            if n < MIN_PER_CELL:
                problems.append(f"{c}: {n} questions, fewer than {MIN_PER_CELL}")
    extra = sorted(set(by_cell) - {c for cs in cat.values() for c in cs})
    for c in extra:
        problems.append(f"{c}: not a catalogue cell")
    print()
    total = sum(v[0] for v in by_type.values())
    print(f"Boss chains: {len(chains)}, {sum(len(v) for v in chains.values())} parts, {len(chain_failures)} failed")
    print(f"{total} questions, {len(failures)} failed, {sum(len(v) for v in cat.values())} catalogue cells")
    for msg in failures[:40]:
        print("FAIL " + msg)
    if len(failures) > 40:
        print(f"... and {len(failures) - 40} more")
    for msg in problems:
        print("FAIL " + msg)
    sys.exit(1 if failures or problems else 0)


if __name__ == "__main__":
    main()
