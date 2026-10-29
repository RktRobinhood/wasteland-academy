class_name Brent
extends RefCounted
## Brent's methods for the calculator's graph tools (FAL-419): a root finder and a
## minimiser, ported from SciPy. engine/graph_tools.gd uses them for the zero, maximum,
## minimum and intersection tools.
##
## root() is a port of SciPy's brentq (scipy/optimize/Zeros/brentq.c, by Charles
## Harris). minimize() is a port of the core of SciPy's Brent minimiser (the Brent
## class in scipy/optimize/_optimize.py). Both are altered only to be GDScript and to
## take a Callable.
##
## Copyright (c) 2001-2002 Enthought, Inc. 2003, SciPy Developers.
## All rights reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions
## are met:
##
## 1. Redistributions of source code must retain the above copyright
##    notice, this list of conditions and the following disclaimer.
##
## 2. Redistributions in binary form must reproduce the above
##    copyright notice, this list of conditions and the following
##    disclaimer in the documentation and/or other materials provided
##    with the distribution.
##
## 3. Neither the name of the copyright holder nor the names of its
##    contributors may be used to endorse or promote products derived
##    from this software without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
## "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
## LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
## A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
## OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
## SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
## LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
## DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
## THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
## (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
## OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## brentq's defaults: xtol 2e-12, rtol 4 × machine epsilon, 100 iterations.
const XTOL := 2e-12
const RTOL := 4.0 * 2.220446049250313e-16
const ROOT_ITER := 100
## Brent's defaults: tol 1.48e-8, mintol 1e-11, the golden ratio's cg, 500 iterations.
const TOL := 1.48e-8
const MINTOL := 1.0e-11
const CG := 0.3819660
const MIN_ITER := 500


## A root of f between xa and xb, where f(xa) and f(xb) have opposite signs.
## Returns {"ok": true, "x", "iterations"} or {"ok": false, "error"}.
static func root(f: Callable, xa: float, xb: float, xtol: float = XTOL, rtol: float = RTOL,
		maxiter: int = ROOT_ITER) -> Dictionary:
	var xpre := xa
	var xcur := xb
	var xblk := 0.0
	var fblk := 0.0
	var spre := 0.0
	var scur := 0.0
	var fpre: float = f.call(xpre)
	var fcur: float = f.call(xcur)
	if fpre == 0.0:
		return {"ok": true, "x": xpre, "iterations": 0}
	if fcur == 0.0:
		return {"ok": true, "x": xcur, "iterations": 0}
	if not is_finite(fpre) or not is_finite(fcur):
		return {"ok": false, "error": "f has no value at an end"}
	if signf(fpre) == signf(fcur):
		return {"ok": false, "error": "f must have opposite signs at the ends"}
	for i in maxiter:
		if fpre != 0.0 and fcur != 0.0 and signf(fpre) != signf(fcur):
			xblk = xpre
			fblk = fpre
			spre = xcur - xpre
			scur = spre
		if absf(fblk) < absf(fcur):
			xpre = xcur
			xcur = xblk
			xblk = xpre
			fpre = fcur
			fcur = fblk
			fblk = fpre
		var delta := (xtol + rtol * absf(xcur)) / 2.0
		var sbis := (xblk - xcur) / 2.0
		if fcur == 0.0 or absf(sbis) < delta:
			return {"ok": true, "x": xcur, "iterations": i + 1}
		if absf(spre) > delta and absf(fcur) < absf(fpre):
			var stry: float
			if xpre == xblk:
				# interpolate
				stry = -fcur * (xcur - xpre) / (fcur - fpre)
			else:
				# extrapolate
				var dpre := (fpre - fcur) / (xpre - xcur)
				var dblk := (fblk - fcur) / (xblk - xcur)
				stry = -fcur * (fblk * dblk - fpre * dpre) / (dblk * dpre * (fblk - fpre))
			if 2.0 * absf(stry) < minf(absf(spre), 3.0 * absf(sbis) - delta):
				# good short step
				spre = scur
				scur = stry
			else:
				# bisect
				spre = sbis
				scur = sbis
		else:
			# bisect
			spre = sbis
			scur = sbis
		xpre = xcur
		fpre = fcur
		if absf(scur) > delta:
			xcur += scur
		else:
			xcur += delta if sbis > 0.0 else -delta
		fcur = f.call(xcur)
	return {"ok": false, "error": "did not converge", "x": xcur}


## A minimum of f inside the bracket xa, xb, xc: xb lies between the other two and
## f(xb) is below f(xa) and f(xc). Returns {"x", "fx", "iterations"}.
static func minimize(f: Callable, xa: float, xb: float, xc: float, tol: float = TOL,
		maxiter: int = MIN_ITER) -> Dictionary:
	var fb: float = f.call(xb)
	var x := xb
	var w := xb
	var v := xb
	var fw := fb
	var fv := fb
	var fx := fb
	var a := minf(xa, xc)
	var b := maxf(xa, xc)
	var deltax := 0.0
	var rat := 0.0
	var iter := 0
	while iter < maxiter:
		var tol1 := tol * absf(x) + MINTOL
		var tol2 := 2.0 * tol1
		var xmid := 0.5 * (a + b)
		# check for convergence
		if absf(x - xmid) < (tol2 - 0.5 * (b - a)):
			break
		if absf(deltax) <= tol1:
			# do a golden section step
			deltax = a - x if x >= xmid else b - x
			rat = CG * deltax
		else:
			# do a parabolic step
			var tmp1 := (x - w) * (fx - fv)
			var tmp2 := (x - v) * (fx - fw)
			var p := (x - v) * tmp2 - (x - w) * tmp1
			tmp2 = 2.0 * (tmp2 - tmp1)
			if tmp2 > 0.0:
				p = -p
			tmp2 = absf(tmp2)
			var dx_temp := deltax
			deltax = rat
			# check parabolic fit
			if p > tmp2 * (a - x) and p < tmp2 * (b - x) and absf(p) < absf(0.5 * tmp2 * dx_temp):
				# if parabolic step is useful
				rat = p / tmp2
				var u0 := x + rat
				if (u0 - a) < tol2 or (b - u0) < tol2:
					rat = tol1 if xmid - x >= 0.0 else -tol1
			else:
				# if it's not, do a golden section step
				deltax = a - x if x >= xmid else b - x
				rat = CG * deltax
		var u: float
		if absf(rat) < tol1:
			# update by at least tol1
			u = x + tol1 if rat >= 0.0 else x - tol1
		else:
			u = x + rat
		var fu: float = f.call(u)
		if fu > fx:
			if u < x:
				a = u
			else:
				b = u
			if fu <= fw or w == x:
				v = w
				w = u
				fv = fw
				fw = fu
			elif fu <= fv or v == x or v == w:
				v = u
				fv = fu
		else:
			if u >= x:
				a = x
			else:
				b = x
			v = w
			w = x
			x = u
			fv = fw
			fw = fx
			fx = fu
		iter += 1
	return {"x": x, "fx": fx, "iterations": iter}
