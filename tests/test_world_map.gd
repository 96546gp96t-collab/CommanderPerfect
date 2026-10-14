extends "res://tests/test_case.gd"
## Tests for Keen on the world map: walking, level entrances that block the
## way, entering levels, "done" signs, teleporters and the ship, on small
## hand-made maps (no game data needed). See tests/fixtures.gd for the
## characters.

const Fixtures := preload("res://tests/fixtures.gd")
const WALK_TICKS := 120
## Long enough for a teleporter: two flickers and the trip in between.
const TELEPORT_TICKS := 400

## An open field with walls around it; Keen starts at [constant START_CELL].
const FIELD: PackedStringArray = [
	"##############",
	"#............#",
	"#............#",
	"#............#",
	"#............#",
	"#............#",
	"##############",
]
const START_CELL := Vector2i(2, 3)


func test_keen_walks_until_a_wall() -> void:
	var session := _session(FIELD)
	_run(session, KeenInput.toward(Vector2i.RIGHT), WALK_TICKS)
	assert_equal(session.keen.hitbox().end.x, _left_of(13), "stops at the right wall")
	assert_equal(session.keen.facing, Vector2i.RIGHT, "looks right")
	_run(session, KeenInput.toward(Vector2i(-1, -1)), WALK_TICKS)
	assert_equal(session.keen.hitbox().position, Vector2(_left_of(1), _left_of(1)), "top left")
	assert_equal(session.keen.facing, Vector2i.UP, "up wins over left")


func test_keen_walks_with_the_walking_frames() -> void:
	var session := _session(FIELD)
	var frames := {}
	for tick in MapKeen.WALK_FRAME_TICKS * MapKeen.WALK_FRAMES:
		session.step(KeenInput.toward(Vector2i.DOWN))
		frames[session.keen.sprite_index()] = true
	assert_equal(frames.size(), MapKeen.WALK_FRAMES, "all four frames")
	assert_true(frames.has(MapKeen.SPRITE_DOWN), "the frames of walking down")


func test_entering_a_level() -> void:
	var session := _session(FIELD, {Vector2i(5, 3): 4})
	_run(session, KeenInput.toward(Vector2i.RIGHT), 20)
	assert_equal(session.cell_under_keen(), _cell(5, 3), "on the entrance")
	session.step(KeenInput.toward(Vector2i.ZERO, true))
	assert_equal(session.outcome, MapSession.Outcome.ENTER_LEVEL, "enters")
	assert_equal(session.chosen_level, 4, "level 4")
	assert_equal(session.progress.map_position, session.keen.position, "remembers where")


func test_walking_and_entering_make_sounds() -> void:
	var session := _session(FIELD, {Vector2i(5, 3): 4})
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	_run(session, KeenInput.toward(Vector2i.RIGHT), 20)
	assert_true(sounds.has(Sound.Id.MAP_WALK), "footsteps")
	session.step(KeenInput.toward(Vector2i.ZERO, true))
	assert_equal(sounds[-1], Sound.Id.MAP_ENTER_LEVEL, "entering")
	var blocked := _session(FIELD)
	sounds.clear()
	blocked.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	_run(blocked, KeenInput.toward(Vector2i.LEFT), WALK_TICKS)
	assert_true(sounds.has(Sound.Id.MAP_BLOCKED), "bumping into the wall")


func test_button_must_be_pressed_again() -> void:
	var session := _session(FIELD, {Vector2i(5, 3): 4})
	_run(session, KeenInput.toward(Vector2i.RIGHT, true), 20)
	assert_equal(session.outcome, MapSession.Outcome.PLAYING, "holding it does not count")


func test_completed_level_cannot_be_entered_and_shows_done() -> void:
	var game := GameProgress.new()
	game.complete_level(4)
	var session := _session(FIELD, {Vector2i(5, 3): 4}, game)
	assert_equal(session.level.tile_at(_cell(5, 3)), MapSession.DONE_TILE, "done sign")
	_run(session, KeenInput.toward(Vector2i.RIGHT), 20)
	session.step(KeenInput.toward(Vector2i.ZERO, true))
	assert_equal(session.outcome, MapSession.Outcome.PLAYING, "not entered")


func test_big_entrance_gets_big_done_sign() -> void:
	var game := GameProgress.new()
	game.complete_level(7)
	var infos := {Vector2i(5, 2): 7, Vector2i(6, 2): 7, Vector2i(5, 3): 7, Vector2i(6, 3): 7}
	var session := _session(FIELD, infos, game)
	var tiles := PackedInt32Array()
	for cell: Vector2i in infos:
		tiles.append(session.level.tile_at(_cell(cell.x, cell.y)))
	assert_equal(tiles, MapSession.BIG_DONE_TILES, "the four corners")


func test_blocking_entrance_lets_keen_through_when_done() -> void:
	var blocking := MapInfo.BLOCKING_FLAG | 1
	var infos := {Vector2i(5, 1): blocking, Vector2i(5, 2): blocking, Vector2i(5, 3): blocking}
	infos[Vector2i(5, 4)] = blocking
	infos[Vector2i(5, 5)] = blocking
	var session := _session(FIELD, infos)
	_run(session, KeenInput.toward(Vector2i.RIGHT), WALK_TICKS)
	assert_equal(session.keen.hitbox().end.x, _left_of(5), "blocked")

	var game := GameProgress.new()
	game.complete_level(1)
	session = _session(FIELD, infos, game)
	_run(session, KeenInput.toward(Vector2i.RIGHT), WALK_TICKS)
	assert_equal(session.keen.hitbox().end.x, _left_of(13), "through once level 1 is done")


func test_teleporter_takes_keen_to_its_destination() -> void:
	var rows := FIELD.duplicate()
	rows[3] = "#...T........#"
	var session := _session(rows, {Vector2i(4, 3): 38, Vector2i(11, 1): 41})
	var tiles_shown := {}
	session.tile_changed.connect(func(_cell: Vector2i, tile: int) -> void: tiles_shown[tile] = true)
	_run(session, KeenInput.toward(Vector2i.RIGHT), 15)
	assert_equal(session.cell_under_keen(), _cell(4, 3), "on the teleporter")
	session.step(KeenInput.toward(Vector2i.ZERO, true))
	assert_true(session.is_teleporting(), "teleporting")
	_run(session, KeenInput.toward(Vector2i.ZERO), TELEPORT_TICKS)
	assert_true(not session.is_teleporting(), "arrived")
	assert_equal(session.keen.position, Vector2(_cell(11, 1) * EgaGraphics.TILE_SIZE), "there")
	for frame in MapTeleport.FLICKER_FRAMES:
		assert_true(tiles_shown.has(MapTeleport.GROUND_FLICKER_TILE + frame), "flicker %d" % frame)
	assert_equal(session.level.tile_at(_cell(4, 3)), Fixtures.TELEPORTER, "tile is back")
	assert_true(not session.keen.hidden, "Keen is seen again")


func test_secret_teleporter_from_a_level() -> void:
	var session := _session(FIELD, {Vector2i(11, 5): MapSession.SECRET_DESTINATION})
	session.teleport_to_secret_place()
	assert_true(session.keen.hidden, "Keen travels unseen")
	_run(session, KeenInput.toward(Vector2i.ZERO), TELEPORT_TICKS)
	assert_equal(session.keen.position, Vector2(_cell(11, 5) * EgaGraphics.TILE_SIZE), "arrived")


func test_ship_is_used() -> void:
	var session := _session(FIELD, {Vector2i(3, 3): MapInfo.SHIP})
	var used := [false]
	session.ship_used.connect(func() -> void: used[0] = true)
	_run(session, KeenInput.toward(Vector2i.RIGHT), 8)
	session.step(KeenInput.toward(Vector2i.ZERO, true))
	assert_true(used[0], "ship used")
	assert_equal(session.outcome, MapSession.Outcome.PLAYING, "still on the map")


func test_keen_starts_where_he_entered_the_last_level() -> void:
	var game := GameProgress.new()
	game.map_position = Vector2(100, 40)
	var session := _session(FIELD, {}, game)
	assert_equal(session.keen.position, Vector2(100, 40), "back where he was")


func test_map_info_values() -> void:
	assert_equal(MapInfo.level_of(16), 16, "level 16")
	assert_equal(MapInfo.level_of(MapInfo.BLOCKING_FLAG | 7), 7, "blocking level 7")
	assert_true(MapInfo.is_blocking(MapInfo.BLOCKING_FLAG | 7), "blocks")
	assert_true(not MapInfo.is_blocking(7), "does not block")
	assert_equal(MapInfo.level_of(MapInfo.SHIP), 0, "the ship is no level")
	assert_true(MapInfo.is_teleporter(41), "teleporter")
	assert_true(not MapInfo.is_teleporter(LevelData.PLAYER_START_INFO), "the start")


## A map from [param rows] with the info values in [param infos] (cell
## inside the border -> value) and Keen at [constant START_CELL].
func _session(rows: PackedStringArray, infos := {}, game: GameProgress = null) -> MapSession:
	var level := Fixtures.create_level(rows)
	level.infos[_index(level, START_CELL)] = LevelData.PLAYER_START_INFO
	for cell: Vector2i in infos:
		level.infos[_index(level, cell)] = infos[cell]
	return MapSession.create(
		level, Fixtures.create_properties(), game if game != null else GameProgress.new()
	)


func _run(session: MapSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


func _index(level: LevelData, cell: Vector2i) -> int:
	var map_cell := _cell(cell.x, cell.y)
	return map_cell.y * level.width + map_cell.x


## A cell of the rows, in map coordinates (with the border).
func _cell(x: int, y: int) -> Vector2i:
	return Vector2i(x, y) + Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)


func _left_of(column: int) -> float:
	return (column + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
