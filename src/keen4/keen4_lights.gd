class_name Keen4Lights
extends RefCounted
## Which of Keen 4's tiles give light in the realistic lighting
## ([RealisticLights]): picked by eye from the tile sheets of the user's
## v1.0 (exported with tools/export_graphics.gd); every frame of an
## animated light is listed.

## Foreground: the exit signs.
const EXIT_SIGNS: Array[int] = [1062, 1063, 1080, 1081]
## The campfire, the rocket's flames and the fire bowls on stands.
const FIRE: Array[int] = [1413, 1414, 1415, 1416, 1482, 1483, 1484, 1485, 2565, 2567, 2569]
## The fields of fire (the Isle of Fire), many tiles in a row.
const FIRE_FIELDS: Array[int] = [
	2808,
	2809,
	2810,
	2811,
	2812,
	2813,
	2814,
	2815,
	2826,
	2827,
	2828,
	2829,
	2830,
	2831,
	2832,
	2833,
	2844,
	2845,
	2846,
	2847,
	2862,
	2863,
	2864,
	2865,
]
## The lamps hanging from the ceiling and on poles.
const LAMPS: Array[int] = [981, 982, 983, 984, 1855, 1857, 1859, 1860, 1861, 1873, 1899, 1902]
## Background: the braziers.
const BRAZIERS: Array[int] = [638, 639, 640, 641]


static func foreground() -> Dictionary[int, RealisticLights.Kind]:
	return _kinds(
		[
			[EXIT_SIGNS, RealisticLights.glowing_sign],
			[FIRE, RealisticLights.flames],
			[FIRE_FIELDS, RealisticLights.lava],
			[LAMPS, RealisticLights.pole_lamp],
		]
	)


static func background() -> Dictionary[int, RealisticLights.Kind]:
	return _kinds([[BRAZIERS, RealisticLights.flames]])


static func _kinds(groups: Array) -> Dictionary[int, RealisticLights.Kind]:
	var kinds: Dictionary[int, RealisticLights.Kind] = {}
	for group: Array in groups:
		for tile: int in group[0]:
			kinds[tile] = group[1]
	return kinds
