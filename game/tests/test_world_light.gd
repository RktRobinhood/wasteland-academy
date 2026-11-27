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