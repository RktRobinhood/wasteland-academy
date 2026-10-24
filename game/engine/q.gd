class_name Q
extends RefCounted
## An exact rational number n/d (d > 0, lowest terms). Every quantity the engine
## generates is a Q, so Paper 1 answers stay exact (a can be ±1/2).

var n: int
var d: int


func _init(num: int = 0, den: int = 1) -> void:
	assert(den != 0, "Q: zero denominator")
	if den < 0:
		num = -num
		den = -den
	var g := Q.gcd(absi(num), den)
	n = num / g
	d = den / g


static func gcd(x: int, y: int) -> int:
	while y != 0:
		var t := x % y
		x = y
		y = t
	return maxi(x, 1)


## Makes a Q from an int, a Q or a float that is a whole number or a half.
static func of(v: Variant, den: int = 1) -> Q:
	if v is Q:
		return v
	if v is float:
		return Q.new(roundi(v * 2.0), 2 * den)
	return Q.new(int(v), den)


func add(o: Variant) -> Q:
	var b := Q.of(o)
	return Q.new(n * b.d + b.n * d, d * b.d)


func sub(o: Variant) -> Q:
	var b := Q.of(o)
	return Q.new(n * b.d - b.n * d, d * b.d)


func mul(o: Variant) -> Q:
	var b := Q.of(o)
	return Q.new(n * b.n, d * b.d)


func div(o: Variant) -> Q:
	var b := Q.of(o)
	assert(b.n != 0, "Q: divide by zero")
	return Q.new(n * b.d, d * b.n)


func neg() -> Q:
	return Q.new(-n, d)


func abs_q() -> Q:
	return Q.new(absi(n), d)


func sq() -> Q:
	return mul(self)


func eq(o: Variant) -> bool:
	var b := Q.of(o)
	return n == b.n and d == b.d


func lt(o: Variant) -> bool:
	var b := Q.of(o)
	return n * b.d < b.n * d


func sign() -> int:
	return signi(n)


func is_int() -> bool:
	return d == 1


func is_zero() -> bool:
	return n == 0


func to_float() -> float:
	return float(n) / float(d)


## Plain ASCII form for the answer export and the checker: "3", "-3/2".
func key() -> String:
	return str(n) if d == 1 else "%d/%d" % [n, d]


## Display form with a true minus sign: "3", "−3/2".
func text() -> String:
	var s := str(absi(n)) if d == 1 else "%d/%d" % [absi(n), d]
	return ("−" if n < 0 else "") + s


func _to_string() -> String:
	return key()
