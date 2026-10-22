class_name Keen5Platforms
extends RefCounted
## Places Keen 5's platforms from a level's info plane (Omni
## `ck5_misc.c:CK5_ScanInfoLayer`, facts only; docs/keen5/research.md §6,
## §7): the red and purple axis platforms ([Keen5Platform]), the falling
## platform ([GalaxyFallingPlatform], as Keen 4's), the standing and sneak
## platforms ([Keen5StillPlatform]) and the red and purple GoPlats
## ([Keen5GoPlat]). The standing platform's difficulty is **reversed**: 33
## only on Easy, 34 on Easy and Normal, 35 always. A GoPlat's start arrow
## is written by [Keen5Creatures] while the level is scanned; this only
## places the platform.

## The first value of each kind; four in a row (up, right, down, left)
## for the moving ones (Omni).
const RED_AXIS := 27
const FALLING := 32
const RED_GO := 36
const SNEAK := 40
const PURPLE_GO := 80
const PURPLE_AXIS := 84
const WAYS := 4
## The standing platforms and the hardest difficulty each is placed on
## (Omni: reversed).
const STANDING: Dictionary[int, GalaxyDifficulty.Level] = {
	33: GalaxyDifficulty.Level.EASY,
	34: GalaxyDifficulty.Level.NORMAL,
	35: GalaxyDifficulty.Level.HARD,
}


## Whether info value [param info] is a platform's.
static func is_platform(info: int) -> bool:
	return (
		_way(info, RED_AXIS) >= 0
		or _way(info, RED_GO) >= 0
		or _way(info, PURPLE_GO) >= 0
		or _way(info, PURPLE_AXIS) >= 0
		or info in [FALLING, SNEAK]
		or STANDING.has(info)
	)


## The platform info value [param info] places at [param cell] on
## [param difficulty], or null (none, or not on this difficulty).
static func place_info(
	world: GalaxyWorld,
	info: int,
	cell: Vector2i,
	difficulty: GalaxyDifficulty.Level,
	sprites: Dictionary[StringName, int]
) -> GalaxyPlatform:
	if _way(info, RED_AXIS) >= 0:
		return Keen5Platform.spawn_red(world, cell, _way(info, RED_AXIS), sprites)
	if _way(info, PURPLE_AXIS) >= 0:
		return Keen5Platform.spawn_purple(world, cell, _way(info, PURPLE_AXIS), sprites)
	if _way(info, RED_GO) >= 0:
		return Keen5GoPlat.spawn(world, cell, _way(info, RED_GO), false, sprites)
	if _way(info, PURPLE_GO) >= 0:
		return Keen5GoPlat.spawn(world, cell, _way(info, PURPLE_GO), true, sprites)
	if info == FALLING:
		return GalaxyFallingPlatform.spawn(world, cell, sprites)
	if info == SNEAK:
		return Keen5StillPlatform.spawn_sneak(world, cell, sprites)
	if STANDING.has(info) and difficulty <= STANDING[info]:
		return Keen5StillPlatform.spawn_standing(world, cell, sprites)
	return null


## The way (0-3) of [param info] in the four values from [param first], or
## -1.
static func _way(info: int, first: int) -> int:
	return info - first if info >= first and info < first + WAYS else -1
