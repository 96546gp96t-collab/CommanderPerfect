extends RefCounted
## Hand-made world maps for the world-map tests (milestone D7): the mini
## levels of [code]galaxy_keen_fixtures.gd[/code] with the map Keen (M,
## info 3) and water tiles (n, e, s, w: misc 11-14, the side of the water),
## played as Keen 4's world map ([Keen4MapSession]). Nothing comes from the
## game files.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")
const Creatures := preload("res://tests/keen4_creature_fixtures.gd")

const TILE := 256
const FRAME_TICS := 2
const FIRST_FRAME_TICS := 3
## The water tiles, after the fixture's own.
const WATER_FIRST := 52
const WATER: Dictionary[String, int] = {"n": 0, "e": 1, "s": 2, "w": 3}
const WATER_NORTH_MISC := 11
const MAP_KEEN := "M"


## A map of [param rows] with the map Keen at M and the water tiles.
static func map(rows: PackedStringArray) -> GalaxyMap:
	var level := Fixtures.level(rows)
	for y in rows.size():
		for x in rows[y].length():
			var character := rows[y][x]
			var cell := Vector2i(x, y)
			if character == MAP_KEEN:
				Fixtures.put_info(level, cell, Keen4Episode.MAP_KEEN_INFO)
			elif WATER.has(character):
				put_fore(level, cell, WATER_FIRST + WATER[character])
	return level


## Puts foreground [param tile] at [param cell] of the rows.
static func put_fore(level: GalaxyMap, cell: Vector2i, tile: int) -> void:
	var at := cell + Vector2i(2, 2)
	level.planes[GalaxyMap.Layer.FOREGROUND][at.y * level.width + at.x] = tile


## The fixture's tile information with the water tiles.
static func tile_info() -> GalaxyTileInfo:
	var data := PackedByteArray()
	var back := GalaxyTileInfo.BACK_TABLES * Fixtures.BACK_TILES
	data.resize(back + GalaxyTileInfo.FORE_TABLES * Fixtures.FORE_TILES)
	var sides: Array[Array] = Fixtures._tile_sides()
	for side in WATER.size():
		sides.append([GalaxyTileInfo.Fore.MISC, WATER_FIRST + side, WATER_NORTH_MISC + side])
	for entry in sides:
		data[back + entry[0] * Fixtures.FORE_TILES + entry[1]] = entry[2] & 0xFF
	return GalaxyTileInfo.parse(data, Fixtures.BACK_TILES, Fixtures.FORE_TILES)


## The world map of [param rows] for a game at [param progress].
static func session(rows: PackedStringArray, progress := Keen4Progress.new()) -> Keen4MapSession:
	return session_of(map(rows), progress)


static func session_of(level: GalaxyMap, progress: Keen4Progress) -> Keen4MapSession:
	var infos := Fixtures.sprite_infos()
	var on_map := Keen4MapSession.create(
		level, tile_info(), infos, Creatures.random_table(), progress
	)
	var tic := FIRST_FRAME_TICS
	on_map.run_frame(KeenInput.new(), FIRST_FRAME_TICS, tic)
	on_map.set_meta(&"tic", tic)
	return on_map


## Runs [param frames] frames of 2 tics with [param held].
static func hold(on_map: Keen4MapSession, frames: int, held := KeenInput.new()) -> void:
	var tic: int = on_map.get_meta(&"tic", 0)
	for frame in frames:
		tic += FRAME_TICS
		on_map.run_frame(held, FRAME_TICS, tic)
	on_map.set_meta(&"tic", tic)


## The stick held toward [param way] (x and y), nothing else.
static func stick(way: Vector2i) -> KeenInput:
	var input := KeenInput.new()
	input.direction = way.x
	input.vertical = way.y
	return input


## Jump held, the stick in the middle.
static func jump() -> KeenInput:
	var input := KeenInput.new()
	input.jump = true
	return input
