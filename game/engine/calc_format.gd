class_name CalcFormat
extends RefCounted
## How the calculator writes numbers (FAL-419): results to 6 significant figures, like a
## GDC, so a student still rounds to 3 s.f. themselves (Q7). 1.41421, 0.5, 512,
## −0.0012, 1.23457E12. Trailing zeros are dropped, as a TI does.


static func sf6(v: float) -> String:
	return sig(v, 6)


## v to n significant figures, trailing zeros dropped; E notation from 10^10 up and
## below 10^-4.
static func sig(v: float, n: int) -> String:
	if not is_finite(v):
		return "Error"
	if v == 0.0:
		return "0"
	var sign := "−" if v < 0.0 else ""
	var a := absf(v)
	var e := floori(log(a) / log(10.0) + 1e-12)
	var m := roundf(a / pow(10.0, e - n + 1))
	if m >= pow(10.0, n):
		e += 1
		m = roundf(a / pow(10.0, e - n + 1))
	if e >= 10 or e < -4:
		var mant := _strip("%.*f" % [n - 1, m / pow(10.0, n - 1)])
		return "%s%sE%s%d" % [sign, mant, "−" if e < 0 else "", absi(e)]
	var places := maxi(0, n - 1 - e)
	return sign + _strip("%.*f" % [places, m * pow(10.0, e - n + 1)])


## An axis label: 4 significant figures.
static func short(v: float) -> String:
	return sig(v, 4)


static func _strip(s: String) -> String:
	if not s.contains("."):
		return s
	s = s.rstrip("0")
	return s.rstrip(".")
