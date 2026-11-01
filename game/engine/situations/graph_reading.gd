class_name GraphReadingSituation
extends RefCounted
## The `fn-pre-graph-reading` situation: prior learning for the Graphs and key features
## region (FAL-420): reading a point off a grid, a value off a scaled axis, plotting a
## table, and rounding to significant figures or decimal places. Paper 1.
##
## generate() returns:
##   px, py     a grid point (whole numbers, −5 to 5, neither 0)
##   scale      units per grid square on the scaled axis (2, 5 or 10), and squares, the
##              marked point's height in squares
##   xs, ys     a table of four points (whole numbers) for plotting
##   v          a number to round (a Q with five or six significant figures), v_small one
##              below 0.01, and dp the places to round to (1 or 2)
##   bound      a 3 s.f. value, for the interval of values that round to it
##   paper      1


static func generate(rng: Seeded, _need: Dictionary = {}) -> Dictionary:
	# The stream's first draw leans low (FAL-460), so it is spent first.
	rng.int_in(0, 1)
	var nz := func() -> int: return [-5, -4, -3, -2, -1, 1, 2, 3, 4, 5][rng.int_in(0, 9)]
	var s := {"paper": 1}
	s.px = nz.call()
	s.py = nz.call()
	while absi(s.py) == absi(s.px):
		s.py = nz.call()
	s.scale = [2, 5, 10][rng.int_in(0, 2)]
	s.squares = rng.int_in(2, 7)
	var xs: Array = []
	var ys: Array = []
	var x := rng.int_in(-3, -1)
	for i in 4:
		xs.append(x)
		var y: int = nz.call()
		while y == x:
			y = nz.call()
		ys.append(y)
		x += rng.int_in(1, 2)
	s.xs = xs
	s.ys = ys
	# A number whose 3 s.f. rounding is not 2 s.f. and whose 4th figure isn't 5 (no tie).
	while true:
		var digits := rng.int_in(10000, 99999)
		if digits % 100 / 10 == 5 or (digits / 100) % 10 == 0:
			continue
		var e := rng.int_in(-1, 1)
		s.v = Q.new(digits, [10000, 1000, 100][e + 1])
		break
	while true:
		var d := rng.int_in(1000, 9999)
		if d % 10 == 5 or d % 10 == 0 or (d / 10) % 10 == 0:
			continue
		s.v_small = Q.new(d, 1000000)
		break
	s.dp = rng.int_in(1, 2)
	var b := rng.int_in(101, 999)
	if b % 10 == 0:
		b += 1
	s.bound = Q.new(b, 100)
	return s


## x rounded to n significant figures, exactly.
static func sf_q(v: Q, n: int) -> Q:
	return Answer.parse_number(Fmt.sf(v, n).replace("−", "-")).q


## x rounded to n decimal places, exactly (half up).
static func dp_q(v: Q, n: int) -> Q:
	var scale := int(pow(10, n))
	# floor((2·v·scale + 1) / 2) in whole numbers, so a value like 12.345 isn't lost to floats.
	var num := v.n * scale
	return Q.new(floori(float(2 * num + v.d) / float(2 * v.d)), scale)


static func export(s: Dictionary) -> Dictionary:
	return ExtensionViews.export(s)
