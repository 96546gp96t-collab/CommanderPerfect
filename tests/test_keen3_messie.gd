extends "res://tests/test_case.gd"
## Tests for Messie on hand-made maps ([Keen3Messie], with
## [Keen3MapSession]): where she starts, how fast she swims, the loop she
## follows without going back, the wait before weed, her pictures, Keen
## getting on and off, the 30 frames before he can get on again, standing
## still while a teleporter works, and the view following her. Messie on the
## real map 80 is in tests/test_keen3_map_data.gd.

const Maps := preload("res://tests/keen3_map_fixtures.gd")
## An open field 16 cells wide: the map is 20 wide with its border, so its
## middle column is 10, column 8 of the rows.
const SIZE := Vector2i(16, 12)
## Her loop: the edge of the rectangle (3, 3)-(12, 8) without its four
## corners. With a square corner she would turn back to the cell before the
## one she came from (it is a neighbour in an earlier column); the real
## map's loop has none.
const LOOP := Rect2i(3, 3, 10, 6)
const MIDDLE := Vector2i(8, 3)
const KEEN_START := Vector2i(8, 6)
## Ticks per cell: 8 frames of the original.
const CELL_TICKS := 8.0 / 24.275 * 60.0
const WEED_TICKS := 122.0 / 24.275 * 60.0
const LOCK_TICKS := 30.0 / 24.275 * 60.0
## More than one round of her loop.
const ROUND_TICKS := 1000


func test_messie_starts_in_the_middle_column_heading_left() -> void:
	var session := _open({})
	assert_equal(session.messie.cell, Maps.map_cell(MIDDLE), "first row with path there")
	assert_equal(session.messie.direction, Vector2i.LEFT, "heading left")
	assert_equal(session.messie.position, Maps.top_left(MIDDLE), "on her cell")
	var empty := Maps.open_map(Maps.field_rows(SIZE), {}, KEEN_START)
	assert_true(empty.messie == null, "no path, no Messie")


func test_messie_swims_eight_frames_per_cell() -> void:
	var session := _open({})
	var start := session.messie.position
	Maps.run(session, KeenInput.new(), 10)
	var expected := 10 * 2.0 * 24.275 / 60.0
	assert_true(absf(start.x - session.messie.position.x - expected) < 0.01, "2 px per frame")
	Maps.run(session, KeenInput.new(), ceili(CELL_TICKS) - 10)
	assert_equal(session.messie.cell, Maps.map_cell(MIDDLE + Vector2i.LEFT), "a cell on")


func test_messie_follows_her_loop_without_going_back() -> void:
	var session := _open({})
	var cells: Array[Vector2i] = [session.messie.cell]
	for tick in ROUND_TICKS:
		session.step(KeenInput.new())
		if session.messie.cell != cells[-1]:
			cells.append(session.messie.cell)
		if cells.size() > 2 and cells[-1] == cells[0]:
			break
	assert_equal(cells[-1], cells[0], "back at her start")
	for index in range(1, cells.size()):
		var step := cells[index] - cells[index - 1]
		assert_true(absi(step.x) <= 1 and absi(step.y) <= 1, "one cell at a time")
		if index >= 2:
			assert_true(cells[index] != cells[index - 2], "never back where she came from")
		var on_path := session.level.info_at(cells[index]) == Keen3MapInfo.PATH
		assert_true(on_path, "%s is her path" % cells[index])
	assert_equal(cells.size() - 1, 2 * (LOOP.size.x + LOOP.size.y) - 4 - 4, "all 24 cells")


func test_messie_waits_before_weed() -> void:
	var weed := MIDDLE + Vector2i(-3, 0)
	var session := _open({weed: Keen3MapInfo.WEED})
	var waited := 0
	for tick in ROUND_TICKS:
		session.step(KeenInput.new())
		if session.messie.is_waiting():
			waited += 1
			assert_equal(session.messie.cell, Maps.map_cell(weed + Vector2i.RIGHT), "next to it")
			assert_equal(session.messie.direction, Vector2i.LEFT, "facing the weed")
		elif waited > 0:
			break
	assert_true(absf(waited - WEED_TICKS) <= 1.0, "122 frames, not %d ticks" % waited)
	Maps.run(session, KeenInput.new(), ceili(CELL_TICKS))
	assert_equal(session.messie.cell, Maps.map_cell(weed), "then into the weed")


func test_frames_by_direction() -> void:
	var expected := {
		Vector2i(-1, -1): 136,
		Vector2i(0, -1): 136,
		Vector2i(1, -1): 134,
		Vector2i(-1, 0): 130,
		Vector2i.ZERO: 130,
		Vector2i(1, 0): 132,
		Vector2i(-1, 1): 130,
		Vector2i(0, 1): 132,
		Vector2i(1, 1): 132,
	}
	for heading: Vector2i in expected:
		var messie := Keen3Messie.at_cell(Vector2i(5, 5), heading)
		assert_equal(messie.sprite_index(), expected[heading], "heading %s" % heading)
		messie.take_on()
		assert_equal(messie.sprite_index(), expected[heading] + 8, "with Keen, %s" % heading)
	var swimmer := Keen3Messie.at_cell(Vector2i(5, 5), Vector2i.ZERO)
	var pictures: Array[int] = []
	for tick in 20:
		swimmer.swim(null)
		pictures.append(swimmer.sprite_index())
	# The second picture every other two frames: 4.9 ticks each.
	assert_equal(pictures.slice(0, 10), [130, 130, 130, 130, 131, 131, 131, 131, 131, 130], "")


func test_keen_gets_on_by_walking_into_her() -> void:
	var session := _open({})
	var sounds := Maps.sounds_of(session)
	session.keen.position = session.messie.position + Vector2(20, 26)
	session.step(KeenInput.new())
	assert_true(not session.is_riding(), "below her picture: not yet")
	session.step(KeenInput.toward(Vector2i.UP))
	session.step(KeenInput.toward(Vector2i.UP))
	assert_true(session.is_riding(), "his top left inside her picture")
	assert_true(session.keen.hidden, "hidden")
	assert_equal(sounds.count(Sound.Id.CRYSTAL), 1, "CRYSTALSND")
	assert_true(session.messie.sprite_index() >= 138, "her pictures with Keen")


func test_keen_on_messie_cannot_use_anything() -> void:
	var session := _open({KEEN_START: 4})
	session.keen.position = session.messie.position
	session.step(KeenInput.new())
	var held_at := session.keen.position
	session.keen.position = Maps.top_left(KEEN_START)
	Maps.press(session)
	assert_equal(session.outcome, MapSession.Outcome.PLAYING, "no level entered")
	session.keen.position = held_at
	Maps.run(session, KeenInput.toward(Vector2i.DOWN), 10)
	assert_equal(session.keen.position, held_at, "he does not walk")


func test_keen_gets_off_at_a_landing() -> void:
	var landing := MIDDLE + Vector2i(-3, -1)
	var session := _ride_to(landing + Vector2i.DOWN, {landing: Keen3MapInfo.LANDING})
	var at := session.messie.position
	session.step(KeenInput.toward(Vector2i.UP))
	assert_true(not session.is_riding(), "off")
	assert_true(not session.keen.hidden, "visible again")
	# She swims on and he walks in the same tick: a few pixels at most.
	assert_true(session.keen.position.distance_to(at + Vector2(0, -16)) < 3.0, "a cell up")


func test_no_getting_off_away_from_a_landing() -> void:
	var landing := MIDDLE + Vector2i(-3, -1)
	var session := _ride_to(landing + Vector2i.DOWN, {landing: Keen3MapInfo.LANDING})
	session.step(KeenInput.toward(Vector2i.DOWN))
	assert_true(session.is_riding(), "no landing below her")
	session.step(KeenInput.new())
	assert_true(session.is_riding(), "no direction pressed")


func test_thirty_frames_before_getting_on_again() -> void:
	var landing := MIDDLE + Vector2i(-3, -1)
	var session := _ride_to(landing + Vector2i.DOWN, {landing: Keen3MapInfo.LANDING})
	session.step(KeenInput.toward(Vector2i.UP))
	var ticks := 0
	while not session.is_riding() and ticks < ROUND_TICKS:
		# Keep Keen inside her picture, as if he walked after her.
		session.keen.position = session.messie.position + Vector2(4, 4)
		session.step(KeenInput.new())
		ticks += 1
	assert_true(absf(ticks - LOCK_TICKS) <= 1.0, "30 frames, not %d ticks" % ticks)


func test_messie_stands_still_while_a_teleporter_works() -> void:
	var a := Vector2i(6, 6)
	var b := Vector2i(10, 6)
	var session := _open({a: 0x0F01, b: 0x0F10})
	session.keen.position = Maps.top_left(a)
	Maps.press(session)
	var at := session.messie.position
	session.step(KeenInput.new())
	assert_true(session.is_teleporting(), "teleporting")
	assert_equal(session.messie.position, at, "Messie waits")


func test_messie_is_kept_while_keen_plays_a_level() -> void:
	var game := Keen3Progress.new()
	var session := _open({}, game)
	Maps.run(session, KeenInput.new(), 50)
	var at := session.messie.position
	var back := _open({}, game)
	assert_equal(back.messie.position, at, "where she was")


func test_the_view_follows_her_with_keen_on_her_back() -> void:
	var big := Vector2i(44, 30)
	var loop := {}
	for x in range(3, 40):
		loop[Vector2i(x, 3)] = Keen3MapInfo.PATH
	var rows := Maps.field_rows(big)
	var session := Maps.open_map(rows, _typed(loop), Vector2i(30, 6))
	session.keen.position = session.messie.position
	Maps.run(session, KeenInput.new(), 2)
	# She is left of the free stretch: the view goes along at once.
	var corner := session.scroll.corner
	var relative := session.messie.position.x - corner.x
	Maps.run(session, KeenInput.new(), 200)
	assert_true(session.scroll.corner.x < corner.x - 100.0, "the view goes left with her")
	var now := session.messie.position.x - session.scroll.corner.x
	assert_true(absf(now - relative) < 0.01, "as far as she swims")


## A map with her loop, [param infos] and Keen inside the loop.
func _open(infos: Dictionary, game: Keen3Progress = null) -> Keen3MapSession:
	var all := {}
	for x in range(LOOP.position.x, LOOP.end.x):
		all[Vector2i(x, LOOP.position.y)] = Keen3MapInfo.PATH
		all[Vector2i(x, LOOP.end.y - 1)] = Keen3MapInfo.PATH
	for y in range(LOOP.position.y, LOOP.end.y):
		all[Vector2i(LOOP.position.x, y)] = Keen3MapInfo.PATH
		all[Vector2i(LOOP.end.x - 1, y)] = Keen3MapInfo.PATH
	for corner in [LOOP.position, LOOP.end - Vector2i.ONE]:
		all.erase(corner)
	all.erase(Vector2i(LOOP.end.x - 1, LOOP.position.y))
	all.erase(Vector2i(LOOP.position.x, LOOP.end.y - 1))
	all.merge(infos, true)
	return Maps.open_map(Maps.field_rows(SIZE), _typed(all), KEEN_START, game)


## Keen on her back until her cell (the cell of her top left) is
## [param cell].
func _ride_to(cell: Vector2i, infos: Dictionary) -> Keen3MapSession:
	var session := _open(infos)
	session.keen.position = session.messie.position
	session.step(KeenInput.new())
	for tick in ROUND_TICKS:
		if Vector2i((session.messie.position / Maps.CELL).floor()) == Maps.map_cell(cell):
			break
		session.step(KeenInput.new())
	return session


static func _typed(infos: Dictionary) -> Dictionary[Vector2i, int]:
	var typed: Dictionary[Vector2i, int] = {}
	typed.assign(infos)
	return typed
