extends RefCounted
## Hand-made world maps for Keen 5's world-map tests (milestone E6): the
## mini levels of [code]galaxy_keen_fixtures.gd[/code] with the map Keen
## (M, info 3), a teleporter (T, misc 20), an elevator's two halves (<
## misc 33, > misc 34) and the six door pictures of 2 × 2 tiles in the
## map's top-left corner (picture n at (2n, 0)-(2n + 1, 1); the open one,
## 5, has the elevator halves in its lower row, as in the real map),
## played as Keen 5's world map ([Keen5MapSession]) with Keen 5's rules
## (code: its sprite names and numbers). Nothing comes from the game files.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")

const TILE := 256
const FRAME_TICS := 2
const FIRST_FRAME_TICS := 3
const FORE_TILES := 96
## The ride tiles and their misc kinds.
const TELEPORTER := 52
const ELEVATOR_LEFT := 53
const ELEVATOR_RIGHT := 54
const TELEPORTER_MISC := 20
const LEFT_MISC := 33
const RIGHT_MISC := 34
## Door picture n: tiles DOOR_FIRST + 4n … + 3 (top left, top right,
## bottom left, bottom right), but the open one's lower row is the
## elevator.
const DOOR_FIRST := 64
const DOOR_PICTURES := 6
const MAP_KEEN := "M"
const RIDE_TILES: Dictionary[String, int] = {
	"T": TELEPORTER, "<": ELEVATOR_LEFT, ">": ELEVATOR_RIGHT
}


## A map of [param rows] with the map Keen at M, the ride tiles and the
## door pictures in its corner.
static func map(rows: PackedStringArray) -> GalaxyMap:
	var level := Fixtures.level(rows)
	for y in rows.size():
		for x in rows[y].length():
			var character := rows[y][x]
			var cell := Vector2i(x, y)
			if character == MAP_KEEN:
				Fixtures.put_info(level, cell, Keen5Episode.MAP_KEEN_INFO)
			elif RIDE_TILES.has(character):
				put_fore(level, cell, RIDE_TILES[character])
	for picture in DOOR_PICTURES:
		for y in 2:
			for x in 2:
				set_fore(level, Vector2i(2 * picture + x, y), door_tile(picture, Vector2i(x, y)))
	return level


## The tile of door picture [param picture] at [param at] (0-1, 0-1).
static func door_tile(picture: int, at: Vector2i) -> int:
	if picture == DOOR_PICTURES - 1 and at.y == 1:
		return ELEVATOR_LEFT if at.x == 0 else ELEVATOR_RIGHT
	return DOOR_FIRST + 4 * picture + 2 * at.y + at.x


## Puts foreground [param tile] at [param cell] of the rows.
static func put_fore(level: GalaxyMap, cell: Vector2i, tile: int) -> void:
	set_fore(level, cell + Vector2i(2, 2), tile)


## Puts foreground [param tile] at map cell [param cell] (with the border).
static func set_fore(level: GalaxyMap, cell: Vector2i, tile: int) -> void:
	level.planes[GalaxyMap.Layer.FOREGROUND][cell.y * level.width + cell.x] = tile


## Puts [param value] on the info plane at map cell [param cell].
static func set_info(level: GalaxyMap, cell: Vector2i, value: int) -> void:
	level.planes[GalaxyMap.Layer.INFO][cell.y * level.width + cell.x] = value


## The info word that sends a ride to map cell [param cell] (the column in
## the high byte, the row in the low byte).
static func target_word(cell: Vector2i) -> int:
	return (cell.x << 8) | cell.y


## The fixture's tile information with the ride tiles, and room for the
## door pictures.
static func tile_info() -> GalaxyTileInfo:
	var data := PackedByteArray()
	var back := GalaxyTileInfo.BACK_TABLES * Fixtures.BACK_TILES
	data.resize(back + GalaxyTileInfo.FORE_TABLES * FORE_TILES)
	var sides: Array[Array] = Fixtures._tile_sides()
	var misc := GalaxyTileInfo.Fore.MISC
	sides.append([misc, TELEPORTER, TELEPORTER_MISC])
	sides.append([misc, ELEVATOR_LEFT, LEFT_MISC])
	sides.append([misc, ELEVATOR_RIGHT, RIGHT_MISC])
	for entry in sides:
		data[back + entry[0] * FORE_TILES + entry[1]] = entry[2] & 0xFF
	return GalaxyTileInfo.parse(data, Fixtures.BACK_TILES, FORE_TILES)


## The world map [param level] for a game at [param progress], after its
## first frame.
static func session(level: GalaxyMap, progress := Keen5Progress.new()) -> Keen5MapSession:
	var on_map := Keen5MapSession.new()
	var made := on_map.begin(
		Keen5Episode.game_rules(),
		level,
		tile_info(),
		Fixtures.sprite_infos(),
		_random_table(),
		progress
	)
	if not made:
		return null
	var tic := FIRST_FRAME_TICS
	on_map.run_frame(KeenInput.new(), FIRST_FRAME_TICS, tic)
	on_map.set_meta(&"tic", tic)
	return on_map


## Runs [param frames] frames of 2 tics with [param held].
static func hold(on_map: Keen5MapSession, frames: int, held := KeenInput.new()) -> void:
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


## A table of random numbers (0-255 in order; not the game's).
static func _random_table() -> PackedByteArray:
	var table := PackedByteArray()
	for value in GalaxyWorld.RANDOM_RANGE:
		table.append(value)
	return table
