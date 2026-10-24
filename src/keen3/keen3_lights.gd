class_name Keen3Lights
extends RefCounted
## Which of Keen 3's tiles give light in the realistic lighting
## ([RealisticLights]): picked by eye from the tile sheet of the user's
## v1.00 (exported with tools/export_graphics.gd); every frame of an
## animated light is listed.

## The burning balls of fire.
const FIRE: Array[int] = [130, 131, 132, 133]
## The glowing magenta pods and the white spark.
const ENERGY: Array[int] = [225, 226, 227, 228, 521]
const EXIT_SIGN: Array[int] = [283, 284]
## The red dome lamp.
const RED_LAMP := 342


static func tiles() -> Dictionary[int, RealisticLights.Kind]:
	var kinds: Dictionary[int, RealisticLights.Kind] = {RED_LAMP: RealisticLights.indicator}
	for group: Array in [
		[FIRE, RealisticLights.flames],
		[ENERGY, RealisticLights.energy],
		[EXIT_SIGN, RealisticLights.glowing_sign],
	]:
		for tile: int in group[0]:
			kinds[tile] = group[1]
	return kinds
