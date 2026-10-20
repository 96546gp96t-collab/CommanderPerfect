class_name Keen4Creatures
extends RefCounted
## Places Keen 4's creatures from a level's info plane (Omni
## `ck4_misc.c:CK4_ScanInfoLayer`, facts only; docs/keen4/research.md §6):
## most kinds have three values, one placed on every difficulty, one from
## Normal on and one only on Hard. What D5 does not place yet (platforms,
## the council, Lindsey, the wetsuit, the creatures under water: D6; the
## world map's: D7) is listed in [constant LATER], so a test can tell a
## forgotten value from a planned one.

enum Kind {
	SLUG,
	MUSHROOM,
	EGG,
	BIRD,
	ARACHNUT,
	SKYPEST,
	WORMMOUTH,
	CLOUD,
	BERKELOID,
	LICK,
	MIMROCK,
	BOUNDER,
	SMIRKY,
	INCHWORM,
	FOOT,
	DART_GUN_UP,
	DART_GUN_RIGHT,
	DART_GUN_DOWN,
	DART_GUN_LEFT,
}

const EASY := GalaxyDifficulty.Level.EASY
const NORMAL := GalaxyDifficulty.Level.NORMAL
const HARD := GalaxyDifficulty.Level.HARD
## Info value: [kind, the lowest difficulty it is placed on] (Omni).
const PLACED: Dictionary[int, Array] = {
	5: [Kind.BERKELOID, EASY],
	7: [Kind.WORMMOUTH, EASY],
	8: [Kind.SKYPEST, EASY],
	9: [Kind.CLOUD, EASY],
	10: [Kind.FOOT, EASY],
	11: [Kind.INCHWORM, EASY],
	12: [Kind.BOUNDER, EASY],
	13: [Kind.EGG, EASY],
	14: [Kind.LICK, EASY],
	18: [Kind.SMIRKY, EASY],
	19: [Kind.MIMROCK, EASY],
	20: [Kind.ARACHNUT, EASY],
	21: [Kind.MUSHROOM, EASY],
	22: [Kind.SLUG, EASY],
	43: [Kind.SLUG, NORMAL],
	44: [Kind.SLUG, HARD],
	45: [Kind.SKYPEST, NORMAL],
	46: [Kind.SKYPEST, HARD],
	47: [Kind.LICK, NORMAL],
	48: [Kind.LICK, HARD],
	49: [Kind.BERKELOID, NORMAL],
	50: [Kind.BERKELOID, HARD],
	51: [Kind.WORMMOUTH, NORMAL],
	52: [Kind.WORMMOUTH, HARD],
	53: [Kind.DART_GUN_UP, EASY],
	54: [Kind.DART_GUN_RIGHT, EASY],
	55: [Kind.DART_GUN_DOWN, EASY],
	56: [Kind.DART_GUN_LEFT, EASY],
	73: [Kind.ARACHNUT, NORMAL],
	74: [Kind.ARACHNUT, HARD],
	77: [Kind.BIRD, NORMAL],
	78: [Kind.BIRD, HARD],
	79: [Kind.DART_GUN_UP, NORMAL],
	80: [Kind.DART_GUN_RIGHT, NORMAL],
	81: [Kind.DART_GUN_DOWN, NORMAL],
	82: [Kind.DART_GUN_LEFT, NORMAL],
	83: [Kind.DART_GUN_UP, HARD],
	84: [Kind.DART_GUN_RIGHT, HARD],
	85: [Kind.DART_GUN_DOWN, HARD],
	86: [Kind.DART_GUN_LEFT, HARD],
}
## Info values of later milestones (Omni): the council member 4, Lindsey 6,
## the Dopefish 15/87/88, school fish 16, the sprite under water 17/23/24,
## platforms 27-30, their turn points 31, the falling platform 32, the
## wetsuit 35, mines 69-72, the swimming Keen 42 (D6); the map Keen 3 and
## Miragia 33 (D7); 75 only loads the moon's sprites.
const LATER: PackedInt32Array = [
	3, 4, 6, 15, 16, 17, 23, 24, 27, 28, 29, 30, 31, 32, 33, 35, 42, 69, 70, 71, 72, 75, 87, 88
]


## Places the creatures of [param world]'s map for [param difficulty];
## returns them in the order placed (row by row, as the original scans).
static func place_all(
	world: GalaxyWorld, difficulty: GalaxyDifficulty.Level, sprites: Dictionary[StringName, int]
) -> Array[GalaxyCreature]:
	var placed: Array[GalaxyCreature] = []
	var map := world.map
	for y in map.height:
		for x in map.width:
			var info := map.tile(GalaxyMap.Layer.INFO, x, y)
			var creature := place_info(world, info, Vector2i(x, y), difficulty, sprites)
			if creature != null:
				placed.append(creature)
	return placed


## The creature info value [param info] places at [param cell] on
## [param difficulty], or null (none, or not on this difficulty).
static func place_info(
	world: GalaxyWorld,
	info: int,
	cell: Vector2i,
	difficulty: GalaxyDifficulty.Level,
	sprites: Dictionary[StringName, int]
) -> GalaxyCreature:
	var entry: Array = PLACED.get(info, [])
	if entry.is_empty() or not GalaxyDifficulty.includes(difficulty, entry[1]):
		return null
	return place(world, entry[0], cell, sprites)


## One creature of [param kind] at [param cell].
static func place(
	world: GalaxyWorld, kind: Kind, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> GalaxyCreature:
	match kind:
		Kind.SLUG:
			return Keen4Slug.spawn(world, cell, sprites)
		Kind.MUSHROOM:
			return Keen4Mushroom.spawn(world, cell, sprites)
		Kind.EGG:
			return Keen4Egg.spawn(world, cell, sprites)
		Kind.BIRD:
			return Keen4Bird.spawn(world, cell, sprites)
		Kind.ARACHNUT:
			return Keen4Arachnut.spawn(world, cell, sprites)
		Kind.SKYPEST:
			return Keen4Skypest.spawn(world, cell, sprites)
		Kind.WORMMOUTH:
			return Keen4Wormmouth.spawn(world, cell, sprites)
		Kind.CLOUD:
			return Keen4Cloud.spawn(world, cell, sprites)
		Kind.BERKELOID:
			return Keen4Berkeloid.spawn(world, cell, sprites)
		Kind.LICK:
			return Keen4Lick.spawn(world, cell, sprites)
		Kind.MIMROCK:
			return Keen4Mimrock.spawn(world, cell, sprites)
		Kind.BOUNDER:
			return Keen4Bounder.spawn(world, cell, sprites)
		Kind.SMIRKY:
			return Keen4Smirky.spawn(world, cell, sprites)
		Kind.INCHWORM:
			return Keen4Inchworm.spawn(world, cell, sprites)
		Kind.FOOT:
			return Keen4Inchworm.spawn_foot(world, cell, sprites)
	return Keen4DartGun.spawn(world, cell, kind - Kind.DART_GUN_UP, sprites)
