extends RefCounted
## Helpers for the tests of Keen 5's machinery (milestone E5): the mini
## levels of [code]keen5_creature_fixtures.gd[/code] with a fuse tile (top
## 57) and made-up boxes for the platforms' sprites, its info plane placed
## as Keen 5's level session does (creatures, platforms and the fuse
## counter, [Keen5LevelSession._place_info]). Nothing comes from the game
## files.

const Keen := preload("res://tests/galaxy_keen_fixtures.gd")
const Creatures := preload("res://tests/keen5_creature_fixtures.gd")
const Level := preload("res://tests/keen5_level_fixtures.gd")

const TILE := 256
## A fuse: a tile whose top is 57 (the last of the fixtures' tiles).
const FUSE := 63
## The rubble a broken fuse becomes: the tiles at the map's (0, 0) and
## (0, 1), here put empty in the border so Keen falls through.
const RUBBLE := 0
## Made-up hit boxes (left, top, right, bottom in units), close to the
## game's own: the red platform 33 pixels wide, the purple one 20 from
## 12 pixels left of its position (its place is 0x40 into its tile).
const PLATFORM_BOX: Array[int] = [32, 128, 560, 240]
const PURPLE_BOX: Array[int] = [-192, 128, 128, 208]
const FLASH_BOX: Array[int] = [128, 128, 368, 240]


## A world of [param rows] (Keen 5's Keen at K or k; F a fuse) with info
## [param info] at each of [param cells], placed for [param difficulty];
## the sounds played go to [param sounds].
static func world(
	rows: PackedStringArray,
	info: int,
	cells: Array[Vector2i],
	difficulty := GalaxyDifficulty.DEFAULT,
	sounds: Array[StringName] = []
) -> GalaxyWorld:
	var map := level(rows)
	for cell in cells:
		Keen.put_info(map, cell, info)
	return world_of(map, difficulty, sounds)


## The map of [param rows]: F is a fuse, and the corner tiles (0, 0) and
## (0, 1) are the empty rubble.
static func level(rows: PackedStringArray) -> GalaxyMap:
	var plain := PackedStringArray()
	var fuses: Array[Vector2i] = []
	for y in rows.size():
		plain.append(rows[y].replace("F", "."))
		for x in rows[y].length():
			if rows[y][x] == "F":
				fuses.append(Vector2i(x, y))
	var map := Keen.level(plain)
	for cell in fuses:
		_put(map, cell + Vector2i(2, 2), FUSE)
	_put(map, Vector2i(0, 0), RUBBLE)
	_put(map, Vector2i(0, 1), RUBBLE)
	return map


## The world of [param map] as map [param number] of the episode, its
## info plane placed as the level session does: info 41 counts the fuses
## into Keen's inventory (on map 12 the QED), the rest places creatures and
## platforms.
static func world_of(
	map: GalaxyMap,
	difficulty := GalaxyDifficulty.DEFAULT,
	sounds: Array[StringName] = [],
	number := -1
) -> GalaxyWorld:
	var infos := map.planes[GalaxyMap.Layer.INFO].duplicate()
	map.planes[GalaxyMap.Layer.INFO].fill(0)
	_keep_keen(map, infos)
	var world := Creatures.world_of(map, difficulty, sounds)
	world.tile_info = tile_info()
	world.clip.tile_info = world.tile_info
	give_boxes(world)
	world.map_number = number
	map.planes[GalaxyMap.Layer.INFO] = infos
	var carried := keen(world).inventory as Keen5Inventory
	var sprites := Keen5Sprites.all()
	for y in map.height:
		for x in map.width:
			var value := map.tile(GalaxyMap.Layer.INFO, x, y)
			var cell := Vector2i(x, y)
			if value == Keen5Fuses.COUNTER_INFO:
				Keen5Fuses.count_info(world, cell, carried, sprites)
			elif value > 2:
				Keen5Creatures.place_info(world, value, cell, difficulty, sprites)
				Keen5Platforms.place_info(world, value, cell, difficulty, sprites)
	return world


## The creature fixtures' tiles with the fuse.
static func tile_info() -> GalaxyTileInfo:
	var back := Keen.BACK_TILES
	var fore := Keen.FORE_TILES
	var data := PackedByteArray()
	data.resize(GalaxyTileInfo.BACK_TABLES * back + GalaxyTileInfo.FORE_TABLES * fore)
	var start := GalaxyTileInfo.BACK_TABLES * back
	var sides := Keen._tile_sides()
	sides.append([GalaxyTileInfo.Fore.MISC, Level.SECURITY_DOOR, Level.SECURITY_MISC])
	sides.append([GalaxyTileInfo.Fore.MISC, Creatures.COMPUTER, Creatures.COMPUTER_MISC])
	# As the game's fuse (tile 1948): top 57, bottom 1, no walls.
	sides.append([GalaxyTileInfo.Fore.TOP, FUSE, Keen5Fuses.FUSE_TOP])
	sides.append([GalaxyTileInfo.Fore.BOTTOM, FUSE, 1])
	for entry in sides:
		data[start + entry[0] * fore + entry[1]] = entry[2] & 0xFF
	return GalaxyTileInfo.parse(data, back, fore)


## Gives the machinery's sprites the boxes above.
static func give_boxes(world: GalaxyWorld) -> void:
	for name in Keen5Sprites.MACHINERY:
		var rect := FLASH_BOX
		if name == &"PLATFORM":
			rect = PLATFORM_BOX
		elif String(name).begins_with("PURPLEPLAT"):
			rect = PURPLE_BOX
		var info := GalaxySpriteInfo.new()
		info.box_left = rect[0]
		info.box_top = rect[1]
		info.box_right = rect[2]
		info.box_bottom = rect[3]
		world.sprite_infos[Keen5Sprites.MACHINERY[name]] = info


## The player's Keen of [param world].
static func keen(world: GalaxyWorld) -> Keen5Keen:
	return world.player() as Keen5Keen


## The first object of [param world] that is a [param type] (and not gone).
static func first(world: GalaxyWorld, type: Script) -> GalaxyObject:
	return Creatures.first(world, type)


## How many objects of [param type] are in [param world].
static func count(world: GalaxyWorld, type: Script) -> int:
	return Creatures.count(world, type)


## Runs [param frames] frames with Keen standing still.
static func wait(world: GalaxyWorld, frames: int) -> void:
	Keen.run(world, frames, Keen.nothing)


## Puts Keen of [param world] in the air over the column of map cell
## [param cell], his feet [param height] units over its top, on the pogo
## falling at [param speed].
static func pogo_down_onto(world: GalaxyWorld, cell: Vector2i, height: int, speed: int) -> void:
	var walker := keen(world)
	walker.set_action(walker.actions[&"pogo_2"])
	walker.reset_box()
	var bottom := walker.box.bottom - walker.position.y
	var middle := walker.box.middle - walker.position.x
	walker.position = Vector2i(
		cell.x * TILE + TILE / 2 - middle, cell.y * TILE - height - 1 - bottom
	)
	walker.reset_box()
	walker.jump_timer = 0
	walker.velocity = Vector2i(0, speed)


static func _keep_keen(map: GalaxyMap, infos: PackedInt32Array) -> void:
	for index in infos.size():
		if infos[index] in [1, 2]:
			map.planes[GalaxyMap.Layer.INFO][index] = infos[index]


static func _put(map: GalaxyMap, cell: Vector2i, tile: int) -> void:
	map.planes[GalaxyMap.Layer.FOREGROUND][cell.y * map.width + cell.x] = tile
