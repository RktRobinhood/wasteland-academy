class_name ComplexNumberAiViews
extends ComplexNumberViews
## The views on the `complex-number-ai` situation (FAL-1004): t1-ai-complex-cartesian (AI-AHL1.12)
## on ComplexNumberViews' builders. Every question is Paper 2, as every AI paper allows a GDC, so
## an argument is in radians to 3 s.f.; a power may go to the sixth; the type adds a real
## quadratic with complex roots. The refs are the AI map's and the type's own.

const AI := "AI-AHL1.12."
const TI := "t1-ai-complex-cartesian#"
const AI_UNKNOWNS := ["power-of-i", "product", "quotient", "solve-linear", "power", "modulus", "argument", "argand-read",
	"distance", "quadratic-roots"]


## slip key -> the type's misconception ref (t1-ai-complex-cartesian's list, in order).
func slips() -> Dictionary:
	return {
		"i2plus": AI + "add-multiply#0", "pairwise": AI + "add-multiply#1", "part-by-part": AI + "divide-conjugate#0",
		"diff-squares": AI + "divide-conjugate#1", "denom-only": AI + "divide-conjugate#2", "quadrant": AI + "modulus-argument#0",
		"no-root": AI + "modulus-argument#1", "mod-diff": AI + "modulus-argument#2", "power-parts": AI + "powers-technology#0",
		"no-brackets": AI + "powers-technology#1", "swap-axes": AI + "argand-diagram#0", "conj-imag-axis": AI + "argand-diagram#1",
		"conj-neg": AI + "argand-diagram#2", "not-halved": AI + "complex-quadratic-roots#0", "no-solution": AI + "complex-quadratic-roots#1",
		"real-roots": AI + "complex-quadratic-roots#2", "i3": TI + "16", "times": TI + "17", "arctan-swap": TI + "18",
		"clockwise": TI + "19", "add-not-sub": TI + "20", "h-sign": TI + "21", "coef": TI + "22",
	}


func unknowns() -> Array:
	return AI_UNKNOWNS


func needs() -> Dictionary:
	var out := super.needs()
	out["power"]["n_max"] = 6
	return out


## Every AI paper allows a GDC: every cell is Paper 2.
func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []
