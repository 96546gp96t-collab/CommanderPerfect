extends RefCounted
## Small hand-made world maps for the Keen 3 map tests
## (tests/test_keen3_map.gd, tests/test_keen3_messie.gd): the level
## characters and tile table of tests/keen3_fixtures.gd ("." open, "#"
## wall), info values at cells counted without the border, and a
## [Keen3MapSession] with Keen's start (info 255) at a cell.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const CELL := EgaGraphics.TILE_SIZE

## An open field, 40x30 cells, with walls around it: big enough for the
## view (20x12.5 cells) to scroll.
const FIELD_SIZE := Vector2i(40, 30)


## The rows of an open field of [param size] cells with walls around it.
static func field_rows(size := FIELD_SIZE) -> PackedStringArray:
	var rows := PackedStringArray()
	for y in size.y:
		if y == 0 or y == size.y - 1:
			rows.append("#".repeat(size.x))
		else:
			rows.append("#" + ".".repeat(size.x - 2) + "#")
	return rows


## A map of [param rows] with [param infos] and Keen's start at
## [param start] (cells without the border).
static func create_map(
	rows: PackedStringArray, infos: Dictionary[Vector2i, int], start: Vector2i
) -> LevelData:
	var all_infos: Dictionary[Vector2i, int] = {}
	all_infos.assign(infos)
	all_infos[start] = LevelData.PLAYER_START_INFO
	return Fixtures.create_level(rows, all_infos)


## Keen on a map of [param rows] with [param infos], starting at
## [param start]; a new game unless [param game] is given.
static func open_map(
	rows: PackedStringArray,
	infos: Dictionary[Vector2i, int],
	start: Vector2i,
	game: Keen3Progress = null
) -> Keen3MapSession:
	var level := create_map(rows, infos, start)
	var progress := game if game != null else Keen3Progress.new()
	return Keen3MapSession.opened(level, Fixtures.level_properties(), progress)


## [param cell] (counted without the border) in map cells.
static func map_cell(cell: Vector2i) -> Vector2i:
	return cell + Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)


## The top left of [param cell] (counted without the border), in pixels.
static func top_left(cell: Vector2i) -> Vector2:
	return Vector2(map_cell(cell) * CELL)


static func run(session: Keen3MapSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


## Presses the jump button once (after a tick without it).
static func press(session: Keen3MapSession, pogo := false) -> void:
	session.step(KeenInput.new())
	var input := KeenInput.new()
	input.jump = not pogo
	input.pogo = pogo
	session.step(input)


## Every sound [param session] plays from now on.
static func sounds_of(session: Keen3MapSession) -> Array[Sound.Id]:
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	return sounds
