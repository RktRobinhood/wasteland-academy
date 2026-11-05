class_name StandardFormViews
extends ExtensionViews
## The views on the `standard-form` situation: one builder per unknown of t1-standard-form
## (FAL-726). An answer a × 10^k is a `form` answer with a and k typed, so a wrong option such as
## 64 × 10⁵ can be typed too and is marked wrong. A Paper 2 a is typed to 3 s.f. and carries the
## rounding trap, which views set themselves as no shared kind writes a power of ten. An ordinary
## number is a `number` written as a decimal, and order-mixed is a `choice`.
##
## Representations: "equation" (the numbers alone) and "words" (a story).

const SC := "SL1.1.convert#"
const SM := "SL1.1.multiply-divide#"
const SX := "SL1.1.context#"
const R_POSITIVE := SC + "0"
const R_DIGITS := SC + "1"
const R_OUTSIDE := SC + "2"
const R_POWERS := SM + "0"
const R_NO_NORM := SM + "1"
const R_SIGN := SM + "2"
const R_DISPLAY := SX + "0"
const R_EARLY := SX + "1"
const R_WRONG_WAY := SX + "2"

const UNKNOWNS := ["to-form-large", "to-form-small", "to-ordinary-large", "to-ordinary-small", "renormalise", "order-mixed", "display-to-form",
	"multiply", "multiply-renormalise", "divide", "divide-renormalise", "power-product",
	"times-larger", "time-from-rate", "total-from-unit", "unit-shift", "rate-unit-shift", "scale-value", "sphere-volume-pi"]
const FORM := "Give your answer in the form a × 10^k, where 1 ≤ a < 10 and k is an integer."
const THREE := " Give a to 3 significant figures."

const BIG := ["The old reservoir holds %s litres of water.", "The depot's ledger lists %s rounds of ammunition.", "The buried archive stores %s bytes.",
	"The salt flat covers %s square metres.", "The camp's scrap heap weighs %s kilograms.", "The dam's turbines turned %s times before they stopped."]
const SMALL := ["A filter's pores are %s metres wide.", "A speck of ash has a mass of %s kilograms.", "A scanner's wire is %s metres thick.",
	"A drop of the medic's serum holds %s litres.", "A spore has a mass of %s grams.", "A flake of rust is %s metres thick."]
const LARGER := [
	["The old reactor produces %s watts and a camp generator produces %s watts.", "How many times greater is the reactor's output than the generator's?"],
	["The great dam holds %s litres and a camp cistern holds %s litres.", "How many times more does the dam hold than the cistern?"],
	["The buried archive stores %s bytes and a scavenged drive stores %s bytes.", "How many times larger is the archive than the drive?"],
	["A convoy hauls %s kilograms and a handcart hauls %s kilograms.", "How many times heavier is the convoy's load than the handcart's?"],
	["The salt flat covers %s square metres and the camp covers %s square metres.", "How many times larger is the salt flat than the camp?"],
	["A storm drops %s litres of rain and a rain tank catches %s litres.", "How many times more rain falls than the tank catches?"],
]
const SIGNALS := ["A radio pulse", "A laser ping", "A repeater's signal", "A satellite's beacon", "A relay's burst", "A scanner's pulse"]
const PROBES := ["an old probe", "a dead satellite", "a far relay", "a lost drone carrier", "a drifting beacon", "a survey craft"]
const UNITS := [
	["Each grain of salt has a mass of %s kilograms. A silo holds %s grains.", "Find the total mass, in kilograms."],
	["Each seed has a mass of %s kilograms. A vault holds %s seeds.", "Find the total mass, in kilograms."],
	["Each rivet costs %s dollars to cast. The foundry casts %s rivets.", "Find the total cost, in dollars."],
	["Each water drop holds %s litres. A leak loses %s drops.", "Find the total water lost, in litres."],
	["Each cell of a solar panel gives %s watts. A field has %s cells.", "Find the total power, in watts."],
	["Each spore has a mass of %s grams. A sample holds %s spores.", "Find the total mass, in grams."],
]
const SHIFTS := [
	["A tanker's load has a mass of %s grams.", "Write this mass in kilograms.", "1 kilogram is 10³ grams"],
	["The salt road is %s kilometres long.", "Write this length in metres.", "1 kilometre is 10³ metres"],
	["A wire is %s millimetres thick.", "Write this thickness in metres.", "1 metre is 10³ millimetres"],
	["The dam's turbines gave %s kilowatts.", "Write this power in watts.", "1 kilowatt is 10³ watts"],
	["A drone's frame has a mass of %s kilograms.", "Write this mass in grams.", "1 kilogram is 10³ grams"],
	["A spore is carried %s metres.", "Write this distance in kilometres.", "1 kilometre is 10³ metres"],
]
const SCALES := [
	"A filter lets through %s grams of dust each hour. A worn filter lets through %d times as much.",
	"A sensor reads a signal of %s units. An amplified signal is %d times as strong.",
	"A patch of mould has a mass of %s grams. A second patch has %d times the mass.",
	"A camp burns %s litres of fuel a year. The depot burns %d times as much.",
	"A leak loses %s litres a second. A burst pipe loses %d times as much.",
	"A battery stores %s units of charge. A bank of them stores %d times as much.",
]
const CLOUDS := ["A storm cell", "A dust cloud", "A pocket of marsh gas", "A cloud of ash", "A swarm of drones", "A fog bank"]


func needs() -> Dictionary:
	var out := {}
	for u in UNKNOWNS:
		out[u] = {"ask": u}
	return out


## The GDC methods are Paper 2. The by-hand arithmetic is Paper 1.
func papers(unknown: String, _rep: String, angle: String) -> Array:
	if not has(unknown):
		return []
	if angle.begins_with("gdc-"):
		return [2]
	return [1] if angle in ["group-and-index", "ordinary-numbers"] else [1, 2]


func build(unknown: String, rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var out := super.build(unknown, rep, s, rng)
	out.given = StandardFormSituation.export(s)
	# A rounded a: the trap writes it to 2 s.f.
	if out.answer.kind == "form" and not out.answer.exact and Answer.needs_rounding(out.answer.values.a):
		var two: Q = Answer.parse_number(Fmt.sf(out.answer.values.a, 2)).q
		# 5.2 for 5.2013 is right to 3 s.f., so it is no trap.
		if not Answer.number_right(two, out.answer.values.a):
			out.trap = form_ans(two, s.k, true, _head(out.answer), _tail(out.answer), 2).values
	return out


# ── Writing things ───────────────────────────────────────────

## 10⁵, 10⁻⁴, 10¹: Fmt.sup leaves a power of 1 out.
static func ten(k: int) -> String:
	if k == 1:
		return "10¹"
	return "10" + Fmt.sup(k) if k != 0 else "10⁰"


## a as an option writes it. A wrong a that doesn't end is rounded, even on Paper 1.
static func written(a: Q, rounded: bool, figs: int = 3) -> String:
	return Fmt.sf(a, figs) if rounded or Fmt.dec(a).contains("/") else Fmt.dec(a)


## "3.2 × 10⁵", or 10⁵ for a = 1, as the question writes a number.
static func sci(a: Q, k: int) -> String:
	return ten(k) if a.eq(1) else "%s × %s" % [Fmt.dec(a), ten(k)]


static func _head(ans: Dictionary) -> String:
	return ans.template[0]


static func _tail(ans: Dictionary) -> String:
	return ans.template[-1] if ans.template[-1] is String else ""


## The answer a × 10^k, with a typed to 3 s.f. if rounded.
static func form_ans(a: Q, k: int, rounded: bool, head: String = "", tail: String = "", figs: int = 3) -> Dictionary:
	var text := "%s%s × %s%s" % [head, written(a, rounded, figs), ten(k), tail]
	var ans := DifferentiationViews.form(text, [head, {"slot": "a"}, " × 10^", {"slot": "k"}, tail], {"a": a, "k": Q.new(k)})
	ans.exact = not rounded
	return ans


## A wrong option in the answer's shape: [a, k], or [a, k, ref]. The a may be outside 1 to 10.
static func options(ans: Dictionary, list: Array) -> Array:
	var rounded: bool = not ans.exact
	var out: Array = []
	for w in list:
		out.append(wrong(form_ans(w[0], w[1], rounded, _head(ans), _tail(ans)).values, w[2] if w.size() > 2 else ""))
	return out


## The standard answer: exact on Paper 1, to 3 s.f. on Paper 2.
static func res(s: Dictionary, head: String = "", tail: String = "") -> Dictionary:
	return form_ans(s.r, s.k, s.paper == 2, head, tail)


## Near misses, for a fourth option.
static func spares(s: Dictionary) -> Array:
	return [[s.r, s.k + 1], [s.r, s.k - 1], [s.r, s.k + 2], [s.r, s.k - 2]]


static func say(ans: Dictionary) -> String:
	return "So the answer is " + Answer.text(ans) + "."


## The number as the GDC shows it: 3.24E−5.
static func display(a: Q, k: int) -> String:
	return "%sE%s" % [Fmt.sf(a), str(k).replace("-", "−")]


## A display that isn't a final answer, from the same numbers.
static func raw(s: Dictionary) -> Dictionary:
	return DifferentiationViews.alt(display(s.r, s.k), R_DISPLAY)


## a × 10^k written out, with spaces between thousands: 6 400 000, 0.000307.
static func plain(a: Q, k: int, spaced: bool = true) -> String:
	var r: Q = a
	var places := 0
	while not r.is_int():
		r = r.mul(10)
		places += 1
	var digits := str(r.n)
	var point := digits.length() - places + k
	var body: String
	if point <= 0:
		body = "0." + "0".repeat(-point) + digits
	elif point >= digits.length():
		body = digits + "0".repeat(point - digits.length())
	else:
		body = digits.left(point) + "." + digits.substr(point)
	if not spaced or body.contains("."):
		return body
	var out := ""
	for i in body.length():
		if i > 0 and (body.length() - i) % 3 == 0:
			out += " "
		out += body[i]
	return out


## a × 10^k as a Q, for a number that fits.
static func q_of(a: Q, k: int) -> Q:
	return a.mul(Q.new(int(pow(10.0, k)))) if k >= 0 else a.div(Q.new(int(pow(10.0, -k))))


# ── Converting ───────────────────────────────────────────────

## "Move the point 6 places left to get 6.4."
static func moved(s: Dictionary, from_big: bool) -> String:
	return "Move the point %d places %s, which gives a = %s." % [absi(s.k), "left" if from_big else "right", Fmt.dec(s.r)]


func u_to_form_large(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _to_form(rep, s, true)


func u_to_form_small(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _to_form(rep, s, false)


func _to_form(rep: String, s: Dictionary, big: bool) -> Dictionary:
	var number := plain(s.r, s.k)
	var ans := res(s)
	var out := {"answer": ans, "table": null}
	var story: String = (BIG if big else SMALL)[s.ctx] % number
	out.lines = [story] if rep == "words" else []
	out.asked = ("Write this number" if rep == "words" else "Write %s" % number) + " in the form a × 10^k, where 1 ≤ a < 10 and k is an integer."
	if s.paper == 2:
		out.asked += THREE
	var k: int = s.k
	var a: Q = s.r
	var digits: int = k + 1 if big else k - 1
	out.wrongs = options(ans, [[a, -k, R_POSITIVE], [a, digits, R_DIGITS], [a.mul(10), k - 1, R_OUTSIDE], [a.div(10), k + 1, R_OUTSIDE]])
	if s.paper == 2:
		out.wrongs.append(DifferentiationViews.alt(display(a, k), R_DISPLAY))
	out.generic = options(ans, spares(s)).map(func(w): return w.values)
	var tail: Array = [say(ans)]
	var round_it: Array = ["To 3 s.f., a = %s." % Fmt.sf(a)] if s.paper == 2 else []
	out.methods = {"place-shift": method([moved(s, big), "Each place %s k by 1, so k = %s." % ["left raises" if big else "right lowers", N(k)]] + round_it + tail, ans.values),
		"factor-powers": method(["%s = %s × %s" % [number, Fmt.dec(a), ten(k)]] + round_it + tail, ans.values)}
	out.methods["gdc-sci"] = method(["In SCI mode the GDC shows %s." % display(a, k), "The display is not a final answer: write it as a × 10^k."] + tail, ans.values)
	return out


func u_to_ordinary_large(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _to_ordinary(rep, s, true)


func u_to_ordinary_small(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _to_ordinary(rep, s, false)


func _to_ordinary(rep: String, s: Dictionary, big: bool) -> Dictionary:
	var a: Q = s.r
	var k: int = s.k
	var ans := Answer.make("number", {"v": q_of(a, k)}, {}, "number = ")
	ans.show = "dec"
	ans.exact = true
	var out := {"answer": ans, "table": null}
	var shown := sci(a, k)
	out.lines = [(BIG if big else SMALL)[s.ctx] % shown] if rep == "words" else []
	out.asked = "Write this number in full." if rep == "words" else "Write %s as an ordinary number." % shown
	var flip := q_of(a, -k)
	out.wrongs = [wrong({"v": flip}, R_POSITIVE), wrong({"v": q_of(a, k + 1 if big else k - 1)}, R_DIGITS)]
	out.generic = [{"v": q_of(a, k - 1 if big else k + 1)}, {"v": q_of(a, k + 2 if big else k - 2)}, {"v": q_of(a, k - 2 if big else k + 2)}]
	out.methods = {"place-shift": method(["The power is %s, so the point moves %d places %s." % [N(k), absi(k), "right" if big else "left"], say(ans)], ans.values),
		"factor-powers": method(["%s = %s" % [ten(k), plain(Q.new(1), k)], "%s × %s = %s" % [Fmt.dec(a), plain(Q.new(1), k), plain(a, k)], say(ans)], ans.values)}
	return out


func u_renormalise(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := form_ans(s.r, s.k, false)
	var out := {"answer": ans, "table": null, "lines": []}
	var j: int = s.j
	var shown: Q = q_of(s.r, j)
	var shown_k: int = s.k - j
	out.asked = "Write %s × %s correctly in standard form, a × 10^k, where 1 ≤ a < 10 and k is an integer." % [Fmt.dec(shown), ten(shown_k)]
	var other: int = 1 if j < 0 else -1
	out.wrongs = options(ans, [[q_of(s.r, other), s.k - other, R_OUTSIDE], [s.r, shown_k - j]])
	out.generic = options(ans, [[s.r, shown_k]] + spares(s)).map(func(w): return w.values)
	var f := "%s = %s × %s" % [Fmt.dec(shown), Fmt.dec(s.r), ten(j)]
	out.methods = {"factor-powers": method([f, "%s × %s = %s" % [ten(j), ten(shown_k), ten(s.k)], say(ans)], ans.values),
		"place-shift": method(["Move the point %d place%s %s to bring a between 1 and 10: a = %s." % [absi(j), "" if absi(j) == 1 else "s", "left" if j > 0 else "right", Fmt.dec(s.r)],
			"k goes %s by %d to balance it: k = %s" % ["up" if j > 0 else "down", absi(j), N(s.k)], say(ans)], ans.values)}
	return out


## A number of order-mixed, as it is written.
static func listed(row: Array) -> String:
	match row[2]:
		"plain":
			return plain(row[0], row[1])
		"over":
			return "%s × %s" % [Fmt.dec(row[0].mul(10)), ten(row[1] - 1)]
		"under":
			return "%s × %s" % [Fmt.dec(row[0].div(10)), ten(row[1] + 1)]
	return sci(row[0], row[1])


func u_order_mixed(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var texts: Array = s.list.map(func(row): return listed(row))
	var right := ""
	for row in s.list:
		if row[0].eq(s.r):
			right = listed(row)
	var head := "largest: " if s.big else "smallest: "
	var ans := Answer.make("choice", {"v": right}, {"options": texts}, head)
	ans.exact = true
	var out := {"answer": ans, "table": null, "lines": ["The four numbers are " + ",  ".join(texts) + "."]}
	out.asked = "Which number is the %s?" % ("largest" if s.big else "smallest")
	out.wrongs = []
	out.generic = []
	for row in s.list:
		if not row[0].eq(s.r):
			# The one that looks largest by its power alone.
			var ref: String = R_OUTSIDE if row[2] == ("under" if s.big else "over") else ""
			out.wrongs.append(wrong({"v": listed(row)}, ref))
	var rows: Array = s.list.map(func(row): return "%s = %s" % [listed(row), sci(row[0], row[1])])
	var steps: Array = ["Write each in standard form: " + "; ".join(rows.slice(0, 2)), "and " + "; ".join(rows.slice(2)),
		"All have the same power, so compare a: the %s is %s." % ["largest" if s.big else "smallest", Fmt.dec(s.r)], say(ans)]
	out.methods = {"place-shift": method(steps, ans.values)}
	return out


func u_display_to_form(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := form_ans(s.r, s.k, false)
	var out := {"answer": ans, "table": null, "lines": ["A GDC shows %s." % display(s.r, s.k)]}
	out.asked = "Write this number in the form a × 10^k, where 1 ≤ a < 10 and k is an integer."
	out.wrongs = [DifferentiationViews.alt(display(s.r, s.k), R_DISPLAY)] + options(ans, [[s.r, -s.k, R_POSITIVE]])
	out.generic = options(ans, spares(s)).map(func(w): return w.values)
	out.methods = {"gdc-sci": method(["E%s means × %s." % [str(s.k).replace("-", "−"), ten(s.k)], say(ans)], ans.values)}
	return out


# ── Multiplying and dividing ─────────────────────────────────

static func pq_lines(s: Dictionary) -> Array:
	return ["p = " + sci(s.a, s.m), "q = " + sci(s.b, s.n)]


func u_multiply(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _times(rep, s)


func u_multiply_renormalise(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _times(rep, s)


func u_divide(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _over(rep, s)


func u_divide_renormalise(rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	return _over(rep, s)


## The step that brings v × 10^e into standard form, if it needs one.
static func tidy(v: Q, e: int, r: Q, k: int) -> Array:
	return [] if v.eq(r) and e == k else ["%s × %s = %s × %s, so that 1 ≤ a < 10" % [Fmt.dec(v), ten(e), Fmt.dec(r), ten(k)]]


## Adds the GDC's working. The GDC cells are Paper 2, but every suited method has its working.
static func gdc(out: Dictionary, s: Dictionary, entry: String) -> void:
	out.methods["gdc-ee"] = method(["Enter %s with the EE key, in brackets." % entry, "The GDC shows %s." % display(s.r, s.k),
		"Write the display as a × 10^k" + (", to 3 s.f." if s.paper == 2 else "."), say(out.answer)], out.answer.values)


## The answer as an ordinary number. A Paper 2 answer needn't end, so it is cut to 5 s.f.
static func whole(s: Dictionary) -> String:
	return plain(s.r if s.paper == 1 else Answer.parse_number(Fmt.sf(s.r, 5)).q, s.k)


func _times(_rep: String, s: Dictionary) -> Dictionary:
	var ans := res(s)
	var v: Q = s.a.mul(s.b)
	var e: int = s.m + s.n
	var out := {"answer": ans, "table": null, "lines": pq_lines(s)}
	out.asked = "Find p × q. " + FORM + (THREE if s.paper == 2 else "")
	var list: Array = []
	if s.m * s.n != e:
		list.append([s.r, s.k - e + s.m * s.n, R_POWERS])
	if not v.eq(s.r):
		list.append([v, e, R_NO_NORM])
	list.append([s.r, s.k - e + s.m - s.n, R_SIGN])
	out.wrongs = options(ans, list)
	if not v.eq(s.r):
		out.wrongs += options(ans, [[s.r, e]])
	out.generic = options(ans, spares(s)).map(func(w): return w.values)
	var group := ["(%s × %s) × (%s × %s) = %s × %s" % [Fmt.dec(s.a), Fmt.dec(s.b), ten(s.m), ten(s.n), Fmt.dec(v), ten(e)]]
	out.methods = {"group-and-index": method(["Multiply the a-values and add the powers of ten."] + group + tidy_sf(s, v, e) + [say(ans)], ans.values)}
	gdc(out, s, "(%s) × (%s)" % [sci(s.a, s.m), sci(s.b, s.n)])
	out.methods["ordinary-numbers"] = method(["%s × %s = %s" % [plain(s.a, s.m), plain(s.b, s.n), whole(s)], say(ans)], ans.values)
	return out


func _over(_rep: String, s: Dictionary) -> Dictionary:
	var ans := res(s)
	var v: Q = s.a.div(s.b)
	var e: int = s.m - s.n
	var out := {"answer": ans, "table": null, "lines": pq_lines(s)}
	out.asked = "Find p/q. " + FORM + (THREE if s.paper == 2 else "")
	var list: Array = [[s.r, s.k - e + s.m + s.n, R_SIGN]]
	if not v.eq(s.r):
		list.append([v, e, R_NO_NORM])
	out.wrongs = options(ans, list)
	out.wrongs += options(ans, [[s.r, e + 1 if v.lt(Q.new(1)) else e - 1]])
	out.generic = options(ans, spares(s)).map(func(w): return w.values)
	var group := "(%s ÷ %s) × 10^(%s − %s) = %s × %s" % [Fmt.dec(s.a), Fmt.dec(s.b), N(s.m), P(s.n), Fmt.work(v, 5) if s.paper == 2 or Fmt.dec(v).contains("/") else Fmt.dec(v), ten(e)]
	out.methods = {"group-and-index": method(["Divide the a-values and subtract the powers of ten.", group] + tidy_sf(s, v, e) + [say(ans)], ans.values)}
	gdc(out, s, "(%s) ÷ (%s)" % [sci(s.a, s.m), sci(s.b, s.n)])
	out.methods["ordinary-numbers"] = method(["%s ÷ %s = %s" % [plain(s.a, s.m), plain(s.b, s.n), whole(s)], say(ans)], ans.values)
	return out


func u_power_product(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := res(s)
	var sq: Q = s.a.mul(s.a)
	var v: Q = sq.mul(s.b)
	var e: int = 2 * s.m + s.n
	var out := {"answer": ans, "table": null, "lines": pq_lines(s)}
	out.asked = "Find p²q. " + FORM + (THREE if s.paper == 2 else "")
	var list: Array = [[s.r, s.k - e + s.m * s.m + s.n, R_POWERS], [s.r, s.k - e + s.m + s.n]]
	if not v.eq(s.r):
		list.insert(1, [v, e, R_NO_NORM])
	out.wrongs = options(ans, list)
	out.generic = options(ans, spares(s)).map(func(w): return w.values)
	out.methods = {"group-and-index": method(["p² = %s² × (%s)² = %s × %s" % [Fmt.dec(s.a), ten(s.m), Fmt.dec(sq), ten(2 * s.m)],
		"p²q = (%s × %s) × %s = %s × %s" % [Fmt.dec(sq), Fmt.dec(s.b), ten(2 * s.m + s.n), Fmt.dec(v), ten(e)]] + tidy_sf(s, v, e) + [say(ans)], ans.values)}
	gdc(out, s, "(%s)² × (%s)" % [sci(s.a, s.m), sci(s.b, s.n)])
	return out


# ── Stories ──────────────────────────────────────────────────

## The two numbers rounded to 2 s.f. before the sum, as Q.
static func early(x: Q) -> Q:
	return Answer.parse_number(Fmt.sf(x, 2)).q


## Paper 2's two slips, in either order so each gets a turn beside the trap: the sum v × 10^e
## done from early figures, and the display left as it is.
static func slips(s: Dictionary, ans: Dictionary, v: Q, e: int, rng: Seeded) -> Array:
	if s.paper == 1:
		return []
	var pair := StandardFormSituation.norm(v, e)
	var list: Array = [raw(s)]
	# Early figures that land on the answer are no slip: typed, they would be marked right.
	if pair[1] != s.k or not Answer.number_right(pair[0], s.r):
		list += options(ans, [[pair[0], pair[1], R_EARLY]])
	return rng.shuffled(list)


func u_times_larger(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := res(s)
	var story: Array = LARGER[s.ctx]
	var out := {"answer": ans, "table": null, "lines": [story[0] % [sci(s.a, s.m), sci(s.b, s.n)]]}
	out.asked = story[1] + " " + FORM + (THREE if s.paper == 2 else "")
	var flip := StandardFormSituation.norm(s.b.div(s.a), s.n - s.m)
	out.wrongs = options(ans, [[flip[0], flip[1], R_WRONG_WAY]]) + slips(s, ans, early(s.a).div(early(s.b)), s.m - s.n, rng)
	out.generic = options(ans, spares(s)).map(func(w): return w.values)
	var v: Q = s.a.div(s.b)
	var e: int = s.m - s.n
	out.methods = {"form-expression": method(["How many times larger means divide the larger by the smaller: (%s) ÷ (%s)" % [sci(s.a, s.m), sci(s.b, s.n)],
		"(%s ÷ %s) × %s = %s × %s" % [Fmt.dec(s.a), Fmt.dec(s.b), ten(e), written(v, s.paper == 2, 5), ten(e)]] + tidy_sf(s, v, e) + [say(ans)], ans.values)}
	gdc(out, s, "(%s) ÷ (%s)" % [sci(s.a, s.m), sci(s.b, s.n)])
	return out


## tidy(), when the figures are rounded and it can't read as an equal sum.
static func tidy_sf(s: Dictionary, v: Q, e: int) -> Array:
	if s.paper == 1:
		return tidy(v, e, s.r, s.k)
	return ["In standard form that is %s × %s." % [Fmt.work(s.r, 5), ten(s.k)]]


func u_time_from_rate(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := res(s)
	var out := {"answer": ans, "table": null}
	out.lines = ["%s travels at %s m s⁻¹. It has to reach %s, %s metres away." % [SIGNALS[s.ctx], sci(s.a, s.m), PROBES[s.ctx], sci(s.b, s.n)]]
	out.asked = "Find the time it takes, in seconds. " + FORM + (THREE if s.paper == 2 else "")
	var flip := StandardFormSituation.norm(s.a.div(s.b), s.m - s.n)
	var times := StandardFormSituation.norm(s.a.mul(s.b), s.m + s.n)
	out.wrongs = slips(s, ans, early(s.b).div(early(s.a)), s.n - s.m, rng) + options(ans, [[flip[0], flip[1]], [times[0], times[1]]])
	out.generic = options(ans, spares(s)).map(func(w): return w.values)
	var v: Q = s.b.div(s.a)
	var e: int = s.n - s.m
	out.methods = {"form-expression": method(["Time = distance ÷ speed = (%s) ÷ (%s)" % [sci(s.b, s.n), sci(s.a, s.m)],
		"(%s ÷ %s) × %s = %s × %s" % [Fmt.dec(s.b), Fmt.dec(s.a), ten(e), written(v, s.paper == 2, 5), ten(e)]] + tidy_sf(s, v, e) + [say(ans)], ans.values)}
	gdc(out, s, "(%s) ÷ (%s)" % [sci(s.b, s.n), sci(s.a, s.m)])
	return out


func u_total_from_unit(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := res(s)
	var story: Array = UNITS[s.ctx]
	var out := {"answer": ans, "table": null, "lines": [story[0] % [sci(s.b, s.n), sci(s.a, s.m)]]}
	out.asked = story[1] + " " + FORM + (THREE if s.paper == 2 else "")
	var flip := StandardFormSituation.norm(s.a.div(s.b), s.m - s.n)
	out.wrongs = slips(s, ans, early(s.a).mul(early(s.b)), s.m + s.n, rng) + options(ans, [[flip[0], flip[1]]])
	out.generic = options(ans, spares(s)).map(func(w): return w.values)
	var v: Q = s.a.mul(s.b)
	var e: int = s.m + s.n
	out.methods = {"form-expression": method(["The total is the number times each one: (%s) × (%s)" % [sci(s.a, s.m), sci(s.b, s.n)],
		"(%s × %s) × %s = %s × %s" % [Fmt.dec(s.a), Fmt.dec(s.b), ten(e), Fmt.dec(v), ten(e)]] + tidy_sf(s, v, e) + [say(ans)], ans.values)}
	gdc(out, s, "(%s) × (%s)" % [sci(s.a, s.m), sci(s.b, s.n)])
	return out


func u_unit_shift(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := form_ans(s.r, s.k, false)
	var story: Array = SHIFTS[s.ctx]
	var out := {"answer": ans, "table": null, "lines": [story[0] % sci(s.a, s.m)]}
	out.asked = story[1] + " " + FORM
	out.wrongs = options(ans, [[s.r, s.m - s.shift]])
	out.generic = options(ans, [[s.r, s.m]] + spares(s)).map(func(w): return w.values)
	out.methods = {"unit-shift": method([story[2] + ", so the power of ten changes by %s." % signed(s.shift), "%s + %s = %s" % [N(s.m), P(s.shift), N(s.k)], say(ans)], ans.values)}
	return out


func u_rate_unit_shift(_rep: String, s: Dictionary, rng: Seeded) -> Dictionary:
	var ans := res(s)
	var out := {"answer": ans, "table": null}
	out.lines = ["%s travels at %s m s⁻¹. It has to reach %s, %s kilometres away." % [SIGNALS[s.ctx], sci(s.a, s.m), PROBES[s.ctx], sci(s.b, s.n)]]
	out.asked = "Find the time it takes, in seconds. " + FORM + (THREE if s.paper == 2 else "")
	var same := StandardFormSituation.norm(s.b.div(s.a), s.n - s.m)
	out.wrongs = slips(s, ans, early(s.b).div(early(s.a)), s.n + 3 - s.m, rng) + options(ans, [[same[0], same[1]]])
	out.generic = options(ans, spares(s)).map(func(w): return w.values)
	var metres := "%s metres" % sci(s.b, s.n + 3)
	var v: Q = s.b.div(s.a)
	var e: int = s.n + 3 - s.m
	out.methods = {"unit-shift": method(["Change km to m first: 1 km = 10³ m, so the distance is " + metres + ".", "Time = (%s) ÷ (%s)" % [sci(s.b, s.n + 3), sci(s.a, s.m)],
		"(%s ÷ %s) × %s = %s × %s" % [Fmt.dec(s.b), Fmt.dec(s.a), ten(e), written(v, s.paper == 2, 5), ten(e)]] + tidy_sf(s, v, e) + [say(ans)], ans.values)}
	gdc(out, s, "(%s) ÷ (%s)" % [sci(s.b, s.n + 3), sci(s.a, s.m)])
	return out


func u_scale_value(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := res(s)
	var out := {"answer": ans, "table": null, "lines": [SCALES[s.ctx] % [sci(s.a, s.m), s.f]]}
	out.asked = "Find the new amount. " + FORM + (THREE if s.paper == 2 else "")
	var v: Q = s.a.mul(s.f)
	var list: Array = []
	if not v.eq(s.r):
		list.append([v, s.m, R_NO_NORM])
	list.append([s.a, s.m + s.f if s.a.eq(1) else s.m])
	out.wrongs = options(ans, list)
	out.generic = options(ans, spares(s)).map(func(w): return w.values)
	out.methods = {"form-expression": method(["%d times as much: %d × %s = %s × %s" % [s.f, s.f, sci(s.a, s.m), Fmt.dec(v), ten(s.m)]] + tidy_sf(s, v, s.m) + [say(ans)], ans.values)}
	return out


func u_sphere_volume_pi(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var ans := form_ans(s.r, s.k, s.paper == 2, "V = π(", ") m³")
	var r: Q = s.a.div(2)
	var out := {"answer": ans, "table": null}
	out.lines = ["%s is about a sphere, with a diameter of %s metres." % [CLOUDS[s.ctx], sci(s.a, s.m)]]
	out.asked = "Find its volume in the form π(a × 10^k) m³, where 1 ≤ a < 10 and k is an integer." + (THREE if s.paper == 2 else "")
	var cube: Q = r.mul(r).mul(r).mul(Q.new(4, 3))
	var e: int = 3 * s.m
	var wrong_d := StandardFormSituation.norm(s.a.mul(s.a).mul(s.a).mul(Q.new(4, 3)), e)
	var list: Array = [[wrong_d[0], wrong_d[1]], [s.r, s.m + 3]]
	if not cube.eq(s.r):
		list.insert(0, [cube, e, R_NO_NORM])
	out.wrongs = options(ans, list)
	out.generic = options(ans, spares(s)).map(func(w): return w.values)
	out.methods = {"form-expression": method(["The radius is half the diameter: %s × %s" % [Fmt.dec(r), ten(s.m)], "V = (4/3)πr³, and r³ = %s × %s" % [written(r.mul(r).mul(r), s.paper == 2, 5), ten(e)],
		"(4/3) × %s = %s, so V = π(%s × %s)" % [written(r.mul(r).mul(r), s.paper == 2, 5), written(cube, s.paper == 2, 5), written(cube, s.paper == 2, 5), ten(e)], say(ans)], ans.values)}
	return out
