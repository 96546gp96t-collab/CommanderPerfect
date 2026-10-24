class_name Keen2Lights
extends RefCounted
## Which of Keen 2's tiles give light in the realistic lighting
## ([RealisticLights]): picked by eye from the tile sheet of the user's
## v1.31 (exported with tools/export_graphics.gd); every frame of an
## animated light is listed.

const BLUE_LAMP := 156
## The lamps that hang from the ceiling with a cone below.
const HANGING_LAMPS: Array[int] = [169, 170, 171, 172]
const EXIT_SIGN: Array[int] = [167, 168]
## Fire and torches.
const FIRE: Array[int] = [238, 239, 266, 267, 268, 269, 279, 280, 281, 282]
## The glowing floor (level 12's bottom row and elsewhere), animated.
const LAVA: Array[int] = [241, 242, 243, 244]
## The electric orbs and the blue beams.
const ENERGY: Array[int] = [342, 343, 344, 345, 481, 482, 483, 484, 494, 495, 496, 497]


static func tiles() -> Dictionary[int, RealisticLights.Kind]:
	var kinds: Dictionary[int, RealisticLights.Kind] = {BLUE_LAMP: RealisticLights.ceiling_lamp}
	for group: Array in [
		[HANGING_LAMPS, RealisticLights.ceiling_lamp],
		[EXIT_SIGN, RealisticLights.glowing_sign],
		[FIRE, RealisticLights.flames],
		[LAVA, RealisticLights.lava],
		[ENERGY, RealisticLights.energy],
	]:
		for tile: int in group[0]:
			kinds[tile] = group[1]
	return kinds
