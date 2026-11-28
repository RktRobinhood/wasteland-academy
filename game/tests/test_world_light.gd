extends "res://tests/test_case.gd"


func test_device_light_has_four_distinct_reads() -> void:
	var night: Dictionary = WorldLight.palette(120.0)
	var morning: Dictionary = WorldLight.palette(420.0)
	var noon: Dictionary = WorldLight.palette(720.0)
	var sunset: Dictionary = WorldLight.palette(1080.0)
	check_eq(noon.grade, Color.WHITE)
	check(night.grade.b > night.grade.r, "night has cool fill")
	check(morning.grade.r > morning.grade.b and sunset.grade.r > sunset.grade.b, "low sun is warm")
	check(morning.grade != sunset.grade, "dawn is not the same grade as sunset")
	check(night.local_light > sunset.local_light and sunset.local_light > noon.local_light, "fixtures stand out as daylight falls")


func test_device_light_is_cyclic_and_has_no_step_jump() -> void:
	check_eq(WorldLight.palette(-5.0), WorldLight.palette(1435.0))
	check_eq(WorldLight.palette(0.0), WorldLight.palette(1440.0))
	for key in WorldLight.KEYS:
		var before: Color = WorldLight.palette(float(key[0]) - 0.1).grade
		var after: Color = WorldLight.palette(float(key[0]) + 0.1).grade
		check(absf(before.r - after.r) < 0.002 and absf(before.g - after.g) < 0.002 and absf(before.b - after.b) < 0.002, "no light jump at a phase boundary")

func test_current_view_catches_up_only_after_the_prompt() -> void:
	var minute := [720.0]
	var grade := WorldLight.SceneGrade.new()
	grade.clock = func() -> float: return minute[0]
	grade.advance(0.0)
	check_eq(grade.grade, Color.WHITE)
	minute[0] = 1080.0
	grade.advance(4.0, true)
	check_eq(grade.grade, Color.WHITE)
	check_eq(grade.local_light, 0.10)
	for i in 12:
		grade.advance(0.25)
	check(grade.grade.g < 0.80 and grade.grade.g > 0.70, "sunset appeared without changing the scene")
	check(grade.local_light > 0.39, "light source warmed without a flash")


func test_fixture_motion_separates_heat_sweeps_and_steady_doors() -> void:
	var prior := WorldLight.fixture_motion("heat", 0.0)
	var low := prior.x
	var high := prior.x
	for i in range(1, 241):
		var now := WorldLight.fixture_motion("heat", float(i) / 60.0)
		check(now.x > 0.69 and now.x < 1.07 and now.y == 0.0, "continuous hot light, no moving bulb")
		check(absf(now.x - prior.x) < 0.014, "per-frame exposure cannot jump")
		low = minf(low, now.x)
		high = maxf(high, now.x)
		prior = now
	check(high - low > 0.23, "visible heat, not a barely detectable fade")
	check(WorldLight.fixture_motion("search", 3.0).y > 0.20)
	check(WorldLight.fixture_motion("search", 9.0).y < -0.20)
	check_eq(WorldLight.fixture_motion("", 99.0), Vector2(1.0, 0.0))
