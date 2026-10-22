class_name Keen5Creatures
extends RefCounted
## Places Keen 5's creatures from a level's info plane (Omni
## `ck5_misc.c:CK5_ScanInfoLayer`, facts only; docs/keen5/research.md §6):
## most kinds have three values, one placed on every difficulty, one from
## Normal on and one only on Hard. The platforms are [Keen5Platforms]'s,
## the fuse counter and the QED (41) [Keen5Fuses]'s (E5); what a later
## milestone places (Keen on the world map and Korath III's arrival in E6)
## is listed in [constant LATER], so a test can tell a forgotten value
## from a planned one. [constant READ_ONLY] values place nothing: the
## B-block (straight Slicestars and platforms turn there), the path arrows
## (the Volteface and the GoPlats follow them), and 125 (the original only
## loads the lightning's pictures for it). A GoPlat's start arrow is
## written here, as the original does while it scans
## ([method place_info]).

enum Kind {
	SPARKY,
	MINE,
	SLICESTAR_UP,
	SLICESTAR_RIGHT,
	SLICESTAR_DIAGONAL,
	ROBO_RED,
	SPIROGRIP,
	AMPTON,
	TURRET_UP,
	TURRET_RIGHT,
	TURRET_DOWN,
	TURRET_LEFT,
	VOLTEFACE,
	SHELLEY,
	SPINDRED,
	MASTER,
	SHIKADI,
	SHOCKSHUND,
	SPHEREFUL,
	KORATH,
}

const EASY := GalaxyDifficulty.Level.EASY
const NORMAL := GalaxyDifficulty.Level.NORMAL
const HARD := GalaxyDifficulty.Level.HARD
## The kinds with an Easy / Normal / Hard value each, by the Easy one
## (Omni): value, value + 1 from Normal, value + 2 on Hard.
const TRIPLES: Dictionary[int, Kind] = {
	4: Kind.SPARKY,
	7: Kind.MINE,
	10: Kind.SLICESTAR_UP,
	13: Kind.ROBO_RED,
	16: Kind.SPIROGRIP,
	19: Kind.SLICESTAR_DIAGONAL,
	22: Kind.SLICESTAR_RIGHT,
	42: Kind.AMPTON,
	71: Kind.VOLTEFACE,
	74: Kind.SHELLEY,
	77: Kind.SPINDRED,
	88: Kind.MASTER,
	99: Kind.SHIKADI,
	102: Kind.SHOCKSHUND,
	105: Kind.SPHEREFUL,
}
## The turrets: four values (up, right, down, left) per difficulty, from
## these (Omni).
const TURRETS: Dictionary[int, GalaxyDifficulty.Level] = {45: EASY, 49: NORMAL, 53: HARD}
const TURRET_WAYS := 4
## The Korath: one value, every difficulty (Omni).
const KORATH_INFO := 124
## Values a later milestone places (Omni): Keen on the world map (3) and
## Korath III's arrival (26) in E6.
const LATER: PackedInt32Array = [3, 26]
## The GoPlats (red from 36, purple from 80: up, right, down, left):
## [Keen5Platforms] places them; their start arrow is written here, as the
## original does while it scans, so a Volteface on the same path finds it
## (level 13).
const GOPLAT_FIRSTS: PackedInt32Array = [36, 80]
const GOPLAT_WAYS := 4
## Values that place nothing: the B-block, the path arrows, 125 (Omni).
const READ_ONLY: PackedInt32Array = [31, 91, 92, 93, 94, 95, 96, 97, 98, 125]
## The sound names the creatures play, with their numbers in Keen 5's
## sound table (Omni EPISODE.CK5), for the sound milestone (E8).
const SOUNDS: Dictionary[StringName, int] = {
	&"keen_walk_1": 0,
	&"mine_explode": 5,
	&"slice_bump": 6,
	&"spindred_fly_up": 16,
	&"spiro_slam": 27,
	&"spindred_slam": 28,
	&"enemy_shoot": 29,
	&"enemy_shot_hit": 30,
	&"ampton_walk_1": 31,
	&"ampton_walk_2": 32,
	&"ampton_stun": 33,
	&"shelley_explode": 36,
	&"spindred_fly_down": 37,
	&"master_shot": 38,
	&"master_teleport": 39,
	&"pole_zap": 40,
	&"shockshund_bark": 42,
	&"bark_shot_die": 45,
	&"sparky_prepare_charge": 58,
	&"sphereful_ceiling": 59,
	&"spiro_fly": 61,
}


## The kind info value [param info] places and the lowest difficulty it
## is placed on, as [kind, difficulty]; empty when it places no creature.
static func entry_of(info: int) -> Array:
	for first in TRIPLES:
		if info >= first and info < first + 3:
			return [TRIPLES[first], info - first]
	for first in TURRETS:
		if info >= first and info < first + TURRET_WAYS:
			return [Kind.TURRET_UP + info - first, TURRETS[first]]
	if info == KORATH_INFO:
		return [Kind.KORATH, EASY]
	return []


## The arrow (0-3) a GoPlat of info value [param info] starts on, or -1.
static func goplat_arrow(info: int) -> int:
	for first in GOPLAT_FIRSTS:
		if info >= first and info < first + GOPLAT_WAYS:
			return info - first
	return -1


## The creature info value [param info] places at [param cell] on
## [param difficulty], or null (none, or not on this difficulty). A
## GoPlat's value only writes its arrow here ([method goplat_arrow]).
static func place_info(
	world: GalaxyWorld,
	info: int,
	cell: Vector2i,
	difficulty: GalaxyDifficulty.Level,
	sprites: Dictionary[StringName, int]
) -> GalaxyCreature:
	var arrow := goplat_arrow(info)
	if arrow >= 0:
		GalaxyPathArrows.start_at(world, cell, arrow)
		return null
	var entry := entry_of(info)
	if entry.is_empty() or not GalaxyDifficulty.includes(difficulty, entry[1]):
		return null
	return place(world, entry[0], cell, sprites)


## One creature of [param kind] at [param cell].
static func place(
	world: GalaxyWorld, kind: Kind, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> GalaxyCreature:
	match kind:
		Kind.SPARKY:
			return Keen5Sparky.spawn(world, cell, sprites)
		Kind.MINE:
			return Keen5Mine.spawn(world, cell, sprites)
		Kind.SLICESTAR_UP:
			return Keen5Slicestar.spawn_straight(world, cell, Keen5Slicestar.UP, sprites)
		Kind.SLICESTAR_RIGHT:
			return Keen5Slicestar.spawn_straight(world, cell, Keen5Slicestar.RIGHT, sprites)
		Kind.SLICESTAR_DIAGONAL:
			return Keen5Slicestar.spawn_diagonal(world, cell, sprites)
		Kind.ROBO_RED:
			return Keen5RoboRed.spawn(world, cell, sprites)
		Kind.SPIROGRIP:
			return Keen5Spirogrip.spawn(world, cell, sprites)
		Kind.AMPTON:
			return Keen5Ampton.spawn(world, cell, sprites)
		Kind.TURRET_UP, Kind.TURRET_RIGHT, Kind.TURRET_DOWN, Kind.TURRET_LEFT:
			return Keen5Turret.spawn(world, cell, kind - Kind.TURRET_UP, sprites)
	return _place_more(world, kind, cell, sprites)


static func _place_more(
	world: GalaxyWorld, kind: Kind, cell: Vector2i, sprites: Dictionary[StringName, int]
) -> GalaxyCreature:
	match kind:
		Kind.VOLTEFACE:
			return Keen5Volteface.spawn(world, cell, sprites)
		Kind.SHELLEY:
			return Keen5Shelley.spawn(world, cell, sprites)
		Kind.SPINDRED:
			return Keen5Spindred.spawn(world, cell, sprites)
		Kind.MASTER:
			return Keen5Master.spawn(world, cell, sprites)
		Kind.SHIKADI:
			return Keen5Shikadi.spawn(world, cell, sprites)
		Kind.SHOCKSHUND:
			return Keen5Shockshund.spawn(world, cell, sprites)
		Kind.SPHEREFUL:
			return Keen5Sphereful.spawn(world, cell, sprites)
	return Keen5Korath.spawn(world, cell, sprites)
