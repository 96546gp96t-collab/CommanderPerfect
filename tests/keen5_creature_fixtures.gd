extends RefCounted
## Helpers for the tests of Keen 5's creatures (milestone E4): a hand-made
## mini level ([code]galaxy_keen_fixtures.gd[/code], with Keen 5's own
## tiles from [code]keen5_level_fixtures.gd[/code] and a computer tile)
## with Keen 5's Keen in it, creatures put on its info plane and placed as
## Keen 5's level session does ([Keen5Creatures]), frames run with Keen
## standing still, and stunner shots fired at a creature. Nothing comes
## from the game files.

const Keen := preload("res://tests/galaxy_keen_fixtures.gd")
const Level := preload("res://tests/keen5_level_fixtures.gd")
const Creatures4 := preload("res://tests/keen4_creature_fixtures.gd")

const TILE := 256
const FRAME_TICS := 2
## A tile with misc 31, the Little Ampton's computer (none of the shared
## fixtures' tiles).
const COMPUTER := 62
const COMPUTER_MISC := 31
## Made-up hit boxes for the creatures' sprites, by the start of their
## names (the first that fits): left, top, right, bottom in units. Each
## creature placed by its info value stands on the floor under its tile
## (its rise + 255, or + 511 for those placed without a rise). Close to the
## game's own, not taken from it.
const BOXES: Array = [
	["SPARKY", [48, 48, 448, 511]],
	["AMPTONGRAB", [64, 64, 432, 383]],
	["AMPTON", [64, 64, 304, 383]],
	["SLICESTARBOOM", [0, 0, 496, 496]],
	["SLICESTAR", [128, 128, 368, 368]],
	["SHELLEYPIECE", [32, 48, 208, 240]],
	["SHELLEYBOOM", [48, 16, 320, 368]],
	["SHELLEY", [48, 16, 192, 255]],
	["VOLTEFACE", [96, 96, 400, 272]],
	["SHIKADIMINEEYE", [0, 0, 112, 112]],
	["SHIKADIMINEPIECE", [16, 16, 96, 96]],
	["SHIKADIMINE", [0, 0, 624, 496]],
	["ROBOSHOT", [64, 64, 176, 176]],
	["ROBORED", [256, 128, 752, 1279]],
	["SPIRO", [128, 64, 368, 432]],
	["SPINDRED", [64, 64, 304, 304]],
	["MASTERFLOORSPARK", [64, 32, 432, 112]],
	["MASTERSHOT", [48, 48, 192, 192]],
	["MASTER", [128, 64, 368, 639]],
	["SHIKADIPOLESPARK", [48, 32, 192, 336]],
	["SHIKADI", [128, 64, 368, 511]],
	["PETSPARK", [64, 64, 176, 176]],
	["PET", [48, 128, 320, 383]],
	["SPHEREGUARD", [0, 16, 80, 112]],
	["SPHEREFUL", [48, 48, 448, 448]],
	["KORATH", [96, 64, 272, 383]],
	["LASER", [80, 80, 160, 160]],
]
const OTHER_BOX: Array[int] = [32, 32, 240, 255]


## A world of [param rows] (Keen 5's Keen at K or k) with info value
## [param info] put at each cell of [param cells] (cells of the rows), and
## the creatures placed for [param difficulty] row by row, as the level
## session scans. The sounds played are appended to [param sounds].
static func world(
	rows: PackedStringArray,
	info: int,
	cells: Array[Vector2i],
	difficulty := GalaxyDifficulty.DEFAULT,
	sounds: Array[StringName] = []
) -> GalaxyWorld:
	var map := Keen.level(rows)
	for cell in cells:
		Keen.put_info(map, cell, info)
	return world_of(map, difficulty, sounds)


## The world of [param map], placed as [method world] does.
static func world_of(
	map: GalaxyMap, difficulty := GalaxyDifficulty.DEFAULT, sounds: Array[StringName] = []
) -> GalaxyWorld:
	var world := Level.world(map, sounds)
	world.tile_info = tile_info()
	world.clip.tile_info = world.tile_info
	world.sleep_margin = Keen5LevelSession.SLEEP_MARGIN
	world.random_table = Creatures4.random_table()
	give_boxes(world)
	for y in map.height:
		for x in map.width:
			var value := map.tile(GalaxyMap.Layer.INFO, x, y)
			Keen5Creatures.place_info(world, value, Vector2i(x, y), difficulty, Keen5Sprites.all())
	return world


## Keen 5's fixture tiles with a computer.
static func tile_info() -> GalaxyTileInfo:
	var back := Keen.BACK_TILES
	var fore := Keen.FORE_TILES
	var data := PackedByteArray()
	data.resize(GalaxyTileInfo.BACK_TABLES * back + GalaxyTileInfo.FORE_TABLES * fore)
	var start := GalaxyTileInfo.BACK_TABLES * back
	var sides := Keen._tile_sides()
	sides.append([GalaxyTileInfo.Fore.MISC, Level.SECURITY_DOOR, Level.SECURITY_MISC])
	sides.append([GalaxyTileInfo.Fore.MISC, COMPUTER, COMPUTER_MISC])
	for entry in sides:
		data[start + entry[0] * fore + entry[1]] = entry[2] & 0xFF
	return GalaxyTileInfo.parse(data, back, fore)


## Gives the creatures' sprites the boxes above.
static func give_boxes(world: GalaxyWorld) -> void:
	var sprites := Keen5CreatureSprites.SPRITES
	for name in sprites:
		var rect: Array = OTHER_BOX
		for entry in BOXES:
			if String(name).begins_with(entry[0]):
				rect = entry[1]
				break
		var info := GalaxySpriteInfo.new()
		info.box_left = rect[0]
		info.box_top = rect[1]
		info.box_right = rect[2]
		info.box_bottom = rect[3]
		world.sprite_infos[sprites[name]] = info


## Puts foreground [param tile] at [param cell] (a cell of the rows).
static func put_tile(world: GalaxyWorld, cell: Vector2i, tile: int) -> void:
	world.set_fore_tile(cell + Vector2i(2, 2), tile)


## The first object of [param world] that is a [param type] (and not gone).
static func first(world: GalaxyWorld, type: Script) -> GalaxyObject:
	return Creatures4.first(world, type)


## How many objects of [param type] are in [param world].
static func count(world: GalaxyWorld, type: Script) -> int:
	return Creatures4.count(world, type)


## Runs [param frames] frames with Keen standing still.
static func wait(world: GalaxyWorld, frames: int) -> void:
	Keen.run(world, frames, Keen.nothing)


## Runs frames until [param done] (a Callable on nothing) is true, at most
## [param limit]; returns the frames run.
static func run_until(world: GalaxyWorld, done: Callable, limit: int) -> int:
	return Creatures4.run_until(world, done, limit)


## A stunner shot fired right at [param creature] from just left of its box
## (it hits within a frame or two); its actions are kept in [param keep].
static func shoot(world: GalaxyWorld, creature: GalaxyObject, keep: Array) -> GalaxyStunnerShot:
	var actions := GalaxyStunnerShot.actions_for(Keen5Sprites.all())
	keep.append(actions)
	var at := Vector2i(
		creature.box.left - Creatures4.SHOT_LEAD, creature.box.bottom - Creatures4.SHOT_BOTTOM
	)
	return GalaxyStunnerShot.fire(world, at, Vector2i.RIGHT, actions)


## The player's Keen of [param world].
static func keen(world: GalaxyWorld) -> Keen5Keen:
	return world.player() as Keen5Keen


## Whether Keen of [param world] is dying.
static func keen_dies(world: GalaxyWorld) -> bool:
	return keen(world).is_dying()
