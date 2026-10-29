"""Reference answers for the calculator's graph tools (FAL-419), solved with SymPy.

Writes game/tests/fixtures/brent.json, which game/tests/test_brent.gd checks the
Brent-based tools (game/engine/graph_tools.gd) against, to 6 significant figures.
Each case is a function as the calculator reads it ("calc", Expr syntax) and the same
function written for SymPy ("sympy"), a window, and the tool. Rerun after changing
CASES:

    .venv/bin/python -I tools/brent_reference.py
"""
import json
import sys
from pathlib import Path

import sympy as sp

x = sp.Symbol("x", real=True)
NS = {"x": x, "E": sp.E, "pi": sp.pi, "log10": lambda v: sp.log(v, 10)}

# (tool, calc f, sympy f, calc g, sympy g, lo, hi)
CASES = [
    ("zeros", "x^3-2x-5", "x**3-2*x-5", None, None, -3, 4),
    ("zeros", "x^2-4x+1", "x**2-4*x+1", None, None, -2, 6),
    ("min", "2x^2-3x-7", "2*x**2-3*x-7", None, None, -3, 4),
    ("max", "-4.9x^2+19.6x+1.5", "-49*x**2/10+196*x/10+15/10", None, None, -1, 5),
    ("zeros", "-4.9x^2+19.6x+1.5", "-49*x**2/10+196*x/10+15/10", None, None, -1, 5),
    ("max", "x^3-6x^2+9x+1", "x**3-6*x**2+9*x+1", None, None, -1, 5),
    ("min", "x^3-6x^2+9x+1", "x**3-6*x**2+9*x+1", None, None, -1, 5),
    ("zeros", "e^x-3x", "exp(x)-3*x", None, None, -2, 3),
    ("min", "e^x-3x", "exp(x)-3*x", None, None, -2, 3),
    ("zeros", "ln(x)-x+2", "log(x)-x+2", None, None, 0.1, 5),
    ("max", "ln(x)-x+2", "log(x)-x+2", None, None, 0.1, 5),
    ("intersect", "100(1.05)^x", "100*(Rational(105,100))**x", "200", "200", 0, 30),
    ("intersect", "5000e^(-0.2x)", "5000*exp(-x/5)", "1000", "1000", 0, 20),
    ("zeros", "sin(x)", "sin(x)", None, None, -1, 7),
    ("intersect", "sin(x)", "sin(x)", "cos(x)", "cos(x)", 0, 7),
    ("intersect", "x^2", "x**2", "2x+3", "2*x+3", -3, 5),
    ("zeros", "(2x+1)/(x-3)", "(2*x+1)/(x-3)", None, None, -5, 8),
    ("zeros", "1/x-x", "1/x-x", None, None, -3, 3),
    ("zeros", "(x-1)^2", "(x-1)**2", None, None, -2, 4),
    ("min", "(x-1)^2", "(x-1)**2", None, None, -2, 4),
    ("zeros", "x^4-3x^2+1", "x**4-3*x**2+1", None, None, -2.5, 2.5),
    ("max", "x^4-3x^2+1", "x**4-3*x**2+1", None, None, -2.5, 2.5),
    ("min", "x^4-3x^2+1", "x**4-3*x**2+1", None, None, -2.5, 2.5),
    ("max", "3sin(2x)+1", "3*sin(2*x)+1", None, None, 0, 4),
    ("min", "3sin(2x)+1", "3*sin(2*x)+1", None, None, 0, 4),
    ("intersect", "20/(1+3e^(-0.5x))", "20/(1+3*exp(-x/2))", "15", "15", 0, 20),
    ("max", "xe^(-x)", "x*exp(-x)", None, None, 0, 5),
    ("zeros", "log(x+1)+x^2-3", "log10(x+1)+x**2-3", None, None, 0, 3),
    ("intersect", "x^3-x", "x**3-x", "x^2-1", "x**2-1", -2, 2),
    ("zeros", "tan(x)", "tan(x)", None, None, -1, 4),
    ("min", "x+4/x", "x+4/x", None, None, 0.2, 6),
    ("intersect", "2^x", "2**x", "x+2", "x+2", -3, 3),
]


def parse(s):
    return sp.sympify(s, locals=NS)


def real_solutions(expr, lo, hi):
    """Every real solution of expr = 0 in [lo, hi], each checked by evaluating."""
    dom = sp.Interval(sp.nsimplify(lo), sp.nsimplify(hi))
    sols = sp.solveset(sp.Eq(expr, 0), x, dom)
    if isinstance(sols, sp.FiniteSet):
        return sorted(float(sp.N(s, 30)) for s in sols)
    # Not in closed form (x^3 - 2x - 5 = 0 is, e^x = 3x isn't): numeric solutions from a
    # grid of starting points, kept when SymPy's own value of expr is ~0 there.
    out = []
    n = 400
    for i in range(n + 1):
        x0 = lo + (hi - lo) * i / n
        try:
            r = sp.nsolve(expr, x, x0, prec=30)
        except (ValueError, ZeroDivisionError, TypeError):
            continue
        r = complex(r)
        if abs(r.imag) > 1e-20:
            continue
        r = r.real
        if lo <= r <= hi and abs(float(expr.subs(x, r).evalf(30))) < 1e-12 and all(abs(r - o) > 1e-9 for o in out):
            out.append(r)
    return sorted(out)


def main():
    cases = []
    for tool, cf, sf, cg, sg, lo, hi in CASES:
        f = parse(sf)
        if tool == "zeros":
            want = [[v] for v in real_solutions(sp.together(f), lo, hi)]
            # A pole is not a zero: keep only where f itself is 0.
            want = [w for w in want if abs(float(f.subs(x, w[0]).evalf(30))) < 1e-12]
        elif tool in ("max", "min"):
            d1 = sp.diff(f, x)
            want = []
            for v in real_solutions(sp.together(d1), lo, hi):
                if not (lo < v < hi):
                    continue
                d2 = float(sp.diff(f, x, 2).subs(x, v).evalf(30))
                if (tool == "max" and d2 < 0) or (tool == "min" and d2 > 0):
                    want.append([v, float(f.subs(x, v).evalf(30))])
        else:
            g = parse(sg)
            want = [[v, float(f.subs(x, v).evalf(30))] for v in real_solutions(sp.together(f - g), lo, hi)]
        if not want:
            sys.exit(f"no reference answers for {tool} {sf} on [{lo}, {hi}]")
        cases.append({"tool": tool, "f": cf, "g": cg, "lo": lo, "hi": hi, "want": want})
    out = Path(__file__).resolve().parent.parent / "game/tests/fixtures/brent.json"
    out.write_text(json.dumps({"about": "Written by tools/brent_reference.py (SymPy). Don't edit.",
                               "cases": cases}, indent=1) + "\n")
    print(f"{len(cases)} cases, {len({c['f'] for c in cases})} functions -> {out}")


if __name__ == "__main__":
    main()
