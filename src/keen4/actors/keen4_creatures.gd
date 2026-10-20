class_name Keen4Creatures
extends RefCounted
## Places Keen 4's creatures and moving things from a level's info plane
## (Omni `ck4_misc.c:CK4_ScanInfoLayer`, facts only; docs/keen4/research.md
## §6): most kinds have three values, one placed on every difficulty, one
## from Normal on and one only on Hard. The land creatures came in D5; the
## platforms, the council members, Lindsey, the wetsuit and the creatures
## under water in D6. What only the world map places (D7) is listed in
## [constant LATER], so a test can tell a forgotten value from a planned
## one; [constant TURN_POINT] places nothing (the platforms read it).

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
	COUNCIL,
	LINDSEY,
	WETSUIT,
	PLATFORM_UP,
	PLATFORM_RIGHT,
	PLATFORM_DOWN,
	PLATFORM_LEFT,
	FALLING_PLATFORM,
	DOPEFISH,
	SCHOOLFISH,
	WATER_SPRITE,
	MINE_UP,
	MINE_RIGHT,
	MINE_DOWN,
	MINE_LEFT,
}

const EASY := GalaxyDifficulty.Level.EASY
const NORMAL := GalaxyDifficulty.Level.NORMAL
const HARD := GalaxyDifficulty.Level.HARD
## Info value: [kind, the lowest difficulty it is placed on] (Omni).
const PLACED: Dictionary[int, Array] = {
	4: [Kind.COUNCIL, EASY],
	5: [Kind.BERKELOID, EASY],
	6: [Kind.LINDSEY, EASY],
	7: [Kind.WORMMOUTH, EASY],
	8: [Kind.SKYPEST, EASY],
	9: [Kind.CLOUD, EASY],
	10: [Kind.FOOT, EASY],
	11: [Kind.INCHWORM, EASY],
	12: [Kind.BOUNDER, EASY],
	13: [Kind.EGG, EASY],
	14: [Kind.LICK, EASY],
	15: [Kind.DOPEFISH, EASY],
	16: [Kind.SCHOOLFISH, EASY],
	17: [Kind.WATER_SPRITE, EASY],
	18: [Kind.SMIRKY, EASY],
	19: [Kind.MIMROCK, EASY],
	20: [Kind.ARACHNUT, EASY],
	21: [Kind.MUSHROOM, EASY],
	22: [Kind.SLUG, EASY],
	23: [Kind.WATER_SPRITE, NORMAL],
	24: [Kind.WATER_SPRITE, HARD],
	27: [Kind.PLATFORM_UP, EASY],
	28: [Kind.PLATFORM_RIGHT, EASY],
	29: [Kind.PLATFORM_DOWN, EASY],
	30: [Kind.PLATFORM_LEFT, EASY],
	32: [Kind.FALLING_PLATFORM, EASY],
	35: [Kind.WETSUIT, EASY],
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
	69: [Kind.MINE_UP, EASY],
	70: [Kind.MINE_RIGHT, EASY],
	71: [Kind.MINE_DOWN, EASY],
	72: [Kind.MINE_LEFT, EASY],
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
	87: [Kind.DOPEFISH, NORMAL],
	88: [Kind.DOPEFISH, HARD],
}
## Info values of the world map (Omni): the map Keen 3 and Miragia 33
## (D7); 75 only loads the moon's sprites (nothing is placed).
const LATER: PackedInt32Array = [3, 33, 75]
## The turn point of platforms and mines: read where they move, placing
## nothing ([GalaxyPlatform]).
const TURN_POINT := GalaxyPlatform.TURN_POINT


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
		Kind.DART_GUN_UP, Kind.DART_GUN_RIGHT, Kind.DART_GUN_DOWN, Kind.DART_GUN_LEFT:
			return Keen4DartGun.spawn(world, cell, kind - Kind.DART_GUN_UP, sprites)
	return _place_d6(world, kind, cell, sprites)


## The kinds that came in D6: the moving things, the council, Lindsey, the
## wetsuit and the creatures under water.
static func _place_d6(
	world: GalaxyWorld, kind: Kind, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> GalaxyCreature:
	match kind:
		Kind.COUNCIL:
			return Keen4Council.spawn(world, cell, sprites)
		Kind.LINDSEY:
			return Keen4Lindsey.spawn(world, cell, sprites)
		Kind.WETSUIT:
			return Keen4Wetsuit.spawn(world, cell, sprites)
		Kind.PLATFORM_UP, Kind.PLATFORM_RIGHT, Kind.PLATFORM_DOWN, Kind.PLATFORM_LEFT:
			return Keen4Platform.spawn(world, cell, kind - Kind.PLATFORM_UP, sprites)
		Kind.FALLING_PLATFORM:
			return GalaxyFallingPlatform.spawn(world, cell, sprites)
		Kind.DOPEFISH:
			return Keen4Dopefish.spawn_dopefish(world, cell, sprites)
		Kind.SCHOOLFISH:
			return Keen4Schoolfish.spawn(world, cell, sprites)
		Kind.WATER_SPRITE:
			return Keen4WaterSprite.spawn(world, cell, sprites)
	return Keen4Mine.spawn(world, cell, kind - Kind.MINE_UP, sprites)
