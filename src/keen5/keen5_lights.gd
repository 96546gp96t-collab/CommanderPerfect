class_name Keen5Lights
extends RefCounted
## Which of Keen 5's tiles give light in the realistic lighting
## ([RealisticLights]): picked by eye from the tile sheets of the user's
## v1.4 (exported with tools/export_graphics.gd); every frame of an
## animated light is listed.

## Foreground: the exit signs (top and bottom, every variant).
const EXIT_SIGNS: Array[int] = [
	1634, 1635, 1638, 1639, 1640, 1641, 1642, 1643, 1650, 1651, 1652, 1653
]
## The computers with a yellow screen.
const COMPUTERS: Array[int] = [1746, 1747, 1748, 1749, 1764, 1765, 1766, 1767]
## The bulbs that run along the rails.
const BULBS: Array[int] = [1141, 1142, 1148, 1161, 1180, 1181, 1182]
## Electric sparks and arcs.
const SPARKS: Array[int] = [19, 20, 21, 1126, 1127, 1128, 1129, 1130, 1131, 1132, 1133]
## The small blinking red lights.
const INDICATORS: Array[int] = [7, 8, 9]
## Background: the red lamp of the pods on the station's outer wall.
const WALL_LAMPS: Array[int] = [155, 156]


static func foreground() -> Dictionary[int, RealisticLights.Kind]:
	return _kinds(
		[
			[EXIT_SIGNS, RealisticLights.glowing_sign],
			[COMPUTERS, RealisticLights.screen],
			[BULBS, RealisticLights.pole_lamp],
			[SPARKS, RealisticLights.energy],
			[INDICATORS, RealisticLights.indicator],
		]
	)


static func background() -> Dictionary[int, RealisticLights.Kind]:
	return _kinds([[WALL_LAMPS, RealisticLights.indicator]])


static func _kinds(groups: Array) -> Dictionary[int, RealisticLights.Kind]:
	var kinds: Dictionary[int, RealisticLights.Kind] = {}
	for group: Array in groups:
		for tile: int in group[0]:
			kinds[tile] = group[1]
	return kinds
