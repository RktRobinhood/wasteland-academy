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
from pathlib import Path

import sympy as sp
from sympy.parsing.sympy_parser import (implicit_multiplication_application, parse_expr,
                                        standard_transformations)

ROOT = Path(__file__).resolve().parent.parent
X = sp.Symbol("x")
LETTERS = {n: sp.Symbol(n) for n in ["a", "b", "c"]}
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

FORM_KINDS = {"vertex_form", "vertex_form_a", "general", "general_a", "factorised"}


class Fail(Exception):
    pass


def R(s):
    return sp.Rational(str(s))


def need(cond, msg):
    if not cond:
        raise Fail(msg)


def parse(text, letters=()):
    """Parses an equation side the way the game writes it."""
    s = text.replace("−", "-").replace("²", "**2").replace("½", "(1/2)").replace("×", "*")
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
        out[k] = v if k in ("var", "rel", "kind") else R(v)
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
    nums = [R(n) for n in re.findall(r"-?\d+(?:/\d+)?", t)]
    if kind == "roots":
        return ("roots", tuple(sorted(nums)))
    if kind in ("point",):
        return (("x", nums[0]), ("y", nums[1]))
    if kind == "yint":
        need(nums[0] == 0, "y-intercept text without x = 0")
        return (("y", nums[1]),)
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
    options and the worked solutions the same way for every situation."""
    sit = q.get("situation_id", "quadratic")
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
        area = R(g["area"])
        need(set(S) == {Y} and set(A) == {X}, "area-side givens are not the area, a side and an angle")
        S[Z] = 2 * area / (S[Y] * deg_sin(A[X]))
        S[X] = sp.sqrt(S[Y]**2 + S[Z]**2 - 2 * S[Y] * S[Z] * deg_cos(A[X]))
        A[Y] = to_deg(sp.acos((S[X]**2 + S[Z]**2 - S[Y]**2) / (2 * S[X] * S[Z])))
    elif kind == "area-angle":
        area = R(g["area"])
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
        need(close(area, R(g["area"])), "the given area is not this triangle's area")
    for L in LETTERS3:
        need(TRI_ANGLE[0] <= num(A[L]) <= TRI_ANGLE[1], f"angle {L} = {num(A[L]):.4} is outside 20° to 140°")
    need(close(sum(A.values()), 180), "the angles don't add up to 180°")
    for L in LETTERS3:  # the sine rule holds all round
        need(close(S[L] / deg_sin(A[L]), k), "the sides and angles are not one triangle")
    return {"X": X, "Y": Y, "Z": Z, "S": S, "A": A, "area": area}


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
        return {"SL3.2.area-sine#2": [R(g["area"]) / (y * deg_sin(A[X]))]}
    if u == "angle-from-area":
        acute = to_deg(sp.asin(2 * R(g["area"]) / (y * z)))
        half = to_deg(sp.asin(R(g["area"]) / (y * z)))
        return {"SL3.2.area-sine#1": [acute], "SL3.2.area-sine#2": [180 - half if g["obtuse"] else half]}
    raise Fail(f"no misconceptions known for {u}")


def tri_shown(q, g):
    """What the student sees says exactly the givens: the words line, or the diagram
    and its caption."""
    rep = q["view"]["rep"]
    text = " ".join(q["lines"])
    sides = {m[1]: m[2] for m in re.finditer(r"\b([ABC]{2}) = (\d+) cm", text)}
    angles = {m[1][1]: m[2] for m in re.finditer(r"angle ([ABC]{3}) = (\d+)°", text)}
    m = re.search(r"area (?:of|is) (\d+) cm²", text)
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
    t = tri_solve(g)
    tri_shown(q, g)
    if q["diagram"] is not None:
        tri_diagram(q, t)
    exp, label, unit = tri_measure(q, t)
    need(not on_edge(exp), f"the answer {num(exp):.8} is on a 3 s.f. rounding edge")

    # The situation the engine exported is the same triangle.
    sit = q["situation"]
    for L in LETTERS3:
        need(close(R(sit["angles"][L]), t["A"][L]), f"situation angle {L} differs")
        need(close(R(sit["sides"][L.lower()]), t["S"][L]), f"situation side {L.lower()} differs")
    need(close(R(sit["area"]), t["area"]), "situation area differs")

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


def formula_values(line):
    """The values of x and P(X = x) from 'P(X = x) = k(x + 1), for x = 0, 1, 2.'"""
    m = re.fullmatch(r"P\(X = x\) = (.+), for x = ([\d, ]+)\.", line)
    need(m, f"formula line {line!r}")
    rhs_text = re.sub(r"k(?=[x(])", "k*", m[1])
    s = rhs_text.replace("−", "-").replace("²", "**2")
    f = sp.sympify(parse_expr(s, local_dict={"x": X, "k": KSYM}, transformations=TRANSFORMS))
    xs = [int(v) for v in m[2].split(",")]
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
        if rep == "words":
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
        xs, ps = formula_values(lines[1])
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


def dist_clean(u, d, style):
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
            need(DIST_P[0] <= p <= DIST_P[1] and (p * 20).q == 1, f"probability {p} is not a step of 0.05 from 0.05 to 0.6")


def dist_event_prob(xs, ps, ev):
    return sum((p for x, p in zip(xs, ps) if event_holds(ev, x)), sp.Integer(0))


def dist_show(u, style):
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
    d = dist_read(q)
    xs, ps = d["xs"], d["ps"]
    free = set().union(*[sp.sympify(p).free_symbols for p in ps])
    ev = None
    wrongs = {}
    exp_pq = None

    if u == "k-from-sum":
        need(free == {KSYM}, f"k-from-sum shows unknowns {free}")
        sol = sp.solve(sp.Eq(sum(ps), 1), KSYM)
        need(len(sol) == 1, "the sum doesn't fix k")
        exp = sol[0]
        need(DIST_K[0] <= exp <= DIST_K[1], f"k = {exp} is outside 1/60 to 1/6")
        coef = [sp.Poly(p, KSYM).coeff_monomial(KSYM) for p in ps]
        sxc = sum(x * c for x, c in zip(xs, coef))
        wrongs["SL4.7.find-k#0"] = [sp.Rational(1, v) for v in (sxc, sum(xs)) if v > 0]
        ps = [p.subs(KSYM, exp) for p in ps]
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
            need(DIST_P[0] <= v <= DIST_P[1] and (v * 20).q == 1, f"{v} is not a step of 0.05 from 0.05 to 0.6")
        bad = sp.solve([sp.Eq(sum(ps), 1), sp.Eq(sum(x * p for x, p in zip(xs, ps)), 1)], [PSYM, QSYM], dict=True)
        wrongs["SL4.7.unknowns-from-mean#1"] = [(b[PSYM], b[QSYM]) for b in bad]
        ps = [p.subs(sol[0]) for p in ps]
        exp = None
        label = None
    else:
        need(not free, f"{u} shows unknowns {free}")
        if u == "fair-stake":
            exp = sum(x * p for x, p in zip(xs, ps))
            need((exp * 100).q == 1 and exp >= DIST_STAKE_MIN, f"the stake {exp} is not whole cents from $0.50")
            win = sum(x * p for x, p in zip(xs, ps) if x > 0)
            wrongs["SL4.7.fair-game#0"] = [sp.Rational(sp.floor(win / ps[0] * 100 + sp.Rational(1, 2)), 100)]
            need(asked == "Find the stake that makes the game fair.", f"asked {asked!r}")
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
                need((exp * 2).q == 1 and exp >= 1, f"expected number {exp} is not whole or .5")
                wrongs["SL4.5.expected-occurrences#0"] = [] if exp.q == 1 else [sp.floor(exp + sp.Rational(1, 2))]
                wrongs["SL4.5.expected-occurrences#1"] = [pe]
                label = "Expected number = "
            elif u == "trials-for-count":
                count = sp.Rational(g["count"])
                m = re.search(r"is expected to happen ([\d.]+) times", asked)
                need(m and sp.Rational(m[1]) == count, "the expected number is not shown")
                exp = count / pe
                need(exp.q == 1 and DIST_TRIALS[0] <= exp <= DIST_TRIALS[1], f"n = {exp}")
                need((count * 2).q == 1 and count >= 1, f"expected number {count} is not whole or .5")
                label = "n = "
            else:
                raise Fail(f"the checker has no solver for {u}")
    dist_clean(u, {**d, "ps": ps}, style)
    show = dist_show(u, style)
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


SITUATION_CHECKS = {"quadratic": check_quadratic, "triangle": check_triangle, "arithmetic-sequence": check_arithmetic,
                    "distribution": check_distribution}

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
