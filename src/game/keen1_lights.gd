class_name Keen1Lights
extends RefCounted
## Which of Keen 1's tiles give light in the realistic look
## ([RealisticLights]): picked by eye from the tile sheet; every frame of an
## animated light is listed.

const BLUE_LAMP := 156
const EXIT_SIGN: Array[int] = [167, 168]
const FIRE: Array[int] = [266, 267, 268, 269, 279, 280, 281, 282]
## The electric orbs (the zappers of the castle and the Tantalus rooms).
const ELECTRIC: Array[int] = [338, 339, 340, 341, 342, 343, 344, 345]
## The blue beams of light.
const BEAMS: Array[int] = [481, 482, 483, 484, 494, 495, 496, 497]
## The white lamps on poles.
const POLE_LAMPS: Array[int] = [485, 486, 487, 488]


static func tiles() -> Dictionary[int, RealisticLights.Kind]:
	var kinds: Dictionary[int, RealisticLights.Kind] = {BLUE_LAMP: RealisticLights.ceiling_lamp}
	for group: Array in [
		[EXIT_SIGN, RealisticLights.glowing_sign],
		[FIRE, RealisticLights.flames],
		[ELECTRIC, RealisticLights.energy],
		[BEAMS, RealisticLights.energy],
		[POLE_LAMPS, RealisticLights.pole_lamp],
	]:
		for tile: int in group[0]:
			kinds[tile] = group[1]
	return kinds
