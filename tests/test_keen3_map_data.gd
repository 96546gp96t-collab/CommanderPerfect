extends "res://tests/test_case.gd"
## Keen 3's world map (map 80) from the player's real files
## ([Keen3MapSession], [Keen3LevelPlay]): every entrance 1-16 and its done
## sign, the 16 teleporters and their routes (docs/keen3/research.md §8),
## the start and its view, the ship, Messie's start, closed loop, timing
## (seen in js-dos) and her two landings, riding her to level 16's island
## and to the Hidden City (level 13), and the course from the map into a
## level and back. Skipped when the Keen 3 files are not there.

const START := Vector2i(44, 47)
const START_CORNER := Vector2i(35, 44)
const ENTRANCES: Dictionary[int, Vector2i] = {
	1: Vector2i(45, 43),
	2: Vector2i(48, 45),
	3: Vector2i(52, 37),
	4: Vector2i(58, 36),
	5: Vector2i(21, 36),
	6: Vector2i(13, 35),
	7: Vector2i(11, 33),
	8: Vector2i(15, 32),
	9: Vector2i(39, 27),
	10: Vector2i(38, 23),
	11: Vector2i(45, 24),
	12: Vector2i(43, 28),
	13: Vector2i(24, 58),
	14: Vector2i(48, 19),
	15: Vector2i(25, 12),
	16: Vector2i(33, 13),
}
const BIG_ENTRANCES: PackedInt32Array = [2, 4, 5, 10, 12, 13, 14, 15]
## Each slot's cell and the slot it sends Keen to.
const TELEPORTERS: Dictionary[int, Array] = {
	0: [Vector2i(51, 25), 2],
	1: [Vector2i(46, 41), 3],
	2: [Vector2i(51, 44), 5],
	3: [Vector2i(55, 41), 1],
	4: [Vector2i(60, 35), 7],
	5: [Vector2i(16, 40), 2],
	6: [Vector2i(20, 34), 11],
	7: [Vector2i(13, 37), 3],
	8: [Vector2i(17, 30), 12],
	9: [Vector2i(9, 32), 4],
	10: [Vector2i(12, 25), 14],
	11: [Vector2i(14, 28), 9],
	12: [Vector2i(18, 25), 0],
	13: [Vector2i(56, 24), 15],
	14: [Vector2i(37, 28), 8],
	15: [Vector2i(24, 18), 14],
}
const MESSIE_START := Vector2i(35, 8)
const LOOP_CELLS := 256
## Where Messie passes next to a landing: near level 16 and near level 13.
const LANDING_STOPS: Array[Vector2i] = [Vector2i(34, 16), Vector2i(27, 55)]
## Seen in js-dos: Messie first shows in the view of a new game 35.82 s
## after "Keens Left" closes (our ticks: 2151, 35.85 s).
const FIRST_SEEN_TICKS := 2149
const TIMING_TOLERANCE := 6
const MAX_TICKS := 20000
const CELL := EgaGraphics.TILE_SIZE

var _files: GameFiles
var _data: Keen3GameData


func run_all() -> void:
	_files = Keen3Files.locate()
	if _files == null:
		skip("no Keen 3 game data found")
		return
	_data = Keen3GameData.load_from(_files)
	super.run_all()


func test_every_entrance_is_found() -> void:
	var session := _open()
	for number in ENTRANCES:
		assert_equal(session.entrance_of(number), ENTRANCES[number], "level %d" % number)


func test_done_signs_on_every_entrance() -> void:
	var game := Keen3Progress.new()
	for number in ENTRANCES:
		game.complete_level(number)
	var session := _open(game)
	for number in ENTRANCES:
		var cell: Vector2i = ENTRANCES[number]
		if number in BIG_ENTRANCES:
			var tiles := PackedInt32Array()
			for offset in Keen3MapSession.BIG_ENTRANCE_CELLS:
				tiles.append(session.level.tile_at(cell + offset))
			assert_equal(tiles, PackedInt32Array([52, 53, 54, 55]), "2x2 sign of %d" % number)
		else:
			assert_equal(session.level.tile_at(cell), 56, "sign of level %d" % number)
	for info in session.level.infos:
		assert_equal(MapInfo.level_of(info), 0, "no entrance left (0x%x)" % info)


func test_teleporters_route_as_in_the_research() -> void:
	var level := _map()
	var found := Keen3MapSession.find_teleporters(level)
	assert_equal(found.size(), TELEPORTERS.size(), "16 slots")
	for slot in TELEPORTERS:
		var cell: Vector2i = TELEPORTERS[slot][0]
		assert_equal(found.get(slot), cell, "slot %d" % slot)
		var info := level.info_at(cell)
		assert_equal(Keen3MapInfo.destination_slot(info), TELEPORTERS[slot][1], "%d leads" % slot)
		assert_equal(level.tile_at(cell), Keen3MapTeleport.RESTING_TILE, "tile 134")


func test_teleporter_1_takes_keen_to_slot_3() -> void:
	var session := _open()
	session.keen.position = Vector2(TELEPORTERS[1][0] * CELL)
	session.step(KeenInput.new())
	session.step(KeenInput.toward(Vector2i.ZERO, true))
	for tick in 100:
		session.step(KeenInput.new())
	assert_equal(session.keen.position, Vector2(TELEPORTERS[3][0] * CELL), "on (55,41)")
	# Seen in js-dos: the view shows cell (45,35) top left.
	assert_equal(session.scroll.corner, Vector2(Vector2i(45, 35) * CELL), "the view")


func test_new_game_start_and_view() -> void:
	var session := _open()
	assert_equal(session.keen.position, Vector2(START * CELL), "on the start cell")
	assert_equal(session.scroll.corner, Vector2(START_CORNER * CELL), "(35,44) top left")


func test_the_ship_is_next_to_the_start() -> void:
	var session := _open()
	var used := [false]
	session.ship_used.connect(func() -> void: used[0] = true)
	session.keen.position = Vector2(Vector2i(43, 48) * CELL)
	session.step(KeenInput.new())
	session.step(KeenInput.toward(Vector2i.ZERO, true))
	assert_true(used[0], "a message")
	assert_equal(_data.ship_messages.size(), 4, "four messages")
	assert_true(_data.ship_prompt.begins_with("         "), "and the line under them")


func test_messie_starts_and_swims_a_closed_loop() -> void:
	var session := _open()
	var messie := session.messie
	assert_equal(messie.cell, MESSIE_START, "the middle column, first row")
	assert_equal(messie.direction, Vector2i.LEFT, "heading left")
	var cells: Array[Vector2i] = [messie.cell]
	for tick in MAX_TICKS:
		messie.swim(session.level)
		if messie.cell != cells[-1]:
			cells.append(messie.cell)
			if messie.cell == MESSIE_START:
				break
	assert_equal(cells[-1], MESSIE_START, "back at her start")
	assert_equal(cells.size() - 1, LOOP_CELLS, "256 cells")
	for stop in LANDING_STOPS:
		assert_true(cells.has(stop), "she passes %s" % stop)


func test_messie_shows_up_when_the_original_does() -> void:
	var session := _open()
	var view := Rect2(Vector2(START_CORNER * CELL), Vector2(320, 200))
	var ticks := 0
	while ticks < MAX_TICKS and not view.intersects(session.messie.hitbox()):
		session.step(KeenInput.new())
		ticks += 1
	assert_true(absi(ticks - FIRST_SEEN_TICKS) <= TIMING_TOLERANCE, "%d ticks" % ticks)


func test_riding_messie_to_level_16() -> void:
	var session := _ride(LANDING_STOPS[0], Vector2i(-1, -1))
	assert_true(not session.is_riding(), "off at (33,15)")
	_walk_and_enter(session, Vector2i.UP, 20)
	assert_equal(session.chosen_level, 16, "Mortimer's castle")


func test_riding_messie_to_the_hidden_city() -> void:
	var session := _ride(LANDING_STOPS[1], Vector2i.DOWN)
	assert_true(not session.is_riding(), "off at (27,56)")
	_walk_and_enter(session, Vector2i(-1, 1), 30)
	assert_equal(session.chosen_level, 13, "level 13")


func test_the_course_from_the_map_and_back() -> void:
	var play := Keen3LevelPlay.create(_files, _data.properties)
	assert_true(play.start_map(), "the map")
	assert_equal(play.map_session.scroll.corner, Vector2(START_CORNER * CELL), "new game view")
	play.map_session.keen.position = Vector2(ENTRANCES[1] * CELL)
	play.step(KeenInput.new())
	play.step(KeenInput.toward(Vector2i.ZERO, true))
	assert_equal(play.state, Keen3LevelPlay.State.PLAYING, "in a level")
	assert_equal(play.level_number, 1, "level 1")
	play.session.outcome = LevelSession.Outcome.COMPLETED
	play.step(KeenInput.new())
	assert_equal(play.state, Keen3LevelPlay.State.MAP, "back on the map")
	assert_equal(play.level.tile_at(ENTRANCES[1]), 56, "its done sign")
	assert_equal(play.map_session.keen.position, Vector2(ENTRANCES[1] * CELL), "where he was")


func _map() -> LevelData:
	return LevelData.parse(_files.read(_files.level_file(Keen3Files.WORLD_MAP_LEVEL)))


func _open(game: Keen3Progress = null) -> Keen3MapSession:
	var progress := game if game != null else Keen3Progress.new()
	return Keen3MapSession.opened(_map(), _data.properties, progress)


## Keen gets on Messie at her start and off toward [param toward] when her
## cell is [param stop].
func _ride(stop: Vector2i, toward: Vector2i) -> Keen3MapSession:
	var session := _open()
	session.keen.position = session.messie.position
	for tick in MAX_TICKS:
		if session.is_riding() and Vector2i((session.messie.position / CELL).floor()) == stop:
			break
		session.step(KeenInput.new())
	session.step(KeenInput.toward(toward))
	return session


func _walk_and_enter(session: Keen3MapSession, toward: Vector2i, ticks: int) -> void:
	for tick in ticks:
		session.step(KeenInput.toward(toward))
	session.step(KeenInput.new())
	session.step(KeenInput.toward(Vector2i.ZERO, true))
