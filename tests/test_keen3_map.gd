extends "res://tests/test_case.gd"
## Tests for Keen on Keen 3's world map ([Keen3MapSession], [Keen3MapKeen],
## [Keen3MapTeleport], [Keen3MapScroll], [Keen3MapInfo]) on small hand-made
## maps, without Keen 3's files: walking, entering levels with the jump or
## pogo button, entrances that block until done, the done signs (one cell,
## 2x2, 2x2 with three blocking cells), which info cell counts, the ship,
## the teleporters, the view. Messie is in tests/test_keen3_messie.gd, the
## real map 80 in tests/test_keen3_map_data.gd.

const Maps := preload("res://tests/keen3_map_fixtures.gd")
const START := Vector2i(20, 15)
const WALK_TICKS := 60
## Long enough for any teleporter: 16 tiles of 4.3 ticks.
const TELEPORT_TICKS := 80
const NEAR := 0.01


func test_keen_walks_four_pixels_per_frame() -> void:
	var session := Maps.open_map(Maps.field_rows(), {}, START)
	var start := session.keen.position
	Maps.run(session, KeenInput.toward(Vector2i.RIGHT), WALK_TICKS)
	# 4 px per frame of the original, 24.275 frames a second (Choco).
	var expected := 4.0 * 24.275
	assert_true(absf(session.keen.position.x - start.x - expected) < NEAR, "97 px in a second")
	start = session.keen.position
	Maps.run(session, KeenInput.toward(Vector2i(-1, 1)), WALK_TICKS)
	var moved := session.keen.position - start
	assert_true(absf(moved.x + expected) < NEAR and absf(moved.y - expected) < NEAR, "per axis")


func test_keen_3_map_sprites() -> void:
	var session := Maps.open_map(Maps.field_rows(), {}, START)
	assert_equal(session.keen.sprite_index(), 35, "looking down at the start")
	var firsts := {Vector2i.RIGHT: 31, Vector2i.DOWN: 35, Vector2i.LEFT: 39, Vector2i.UP: 43}
	for direction: Vector2i in firsts:
		var seen := {}
		for tick in 30:
			session.step(KeenInput.toward(direction))
			seen[session.keen.sprite_index()] = true
		var first: int = firsts[direction]
		var expected := {first: true, first + 1: true, first + 2: true, first + 3: true}
		assert_equal(seen, expected, "four frames for %s" % direction)
	session.step(KeenInput.toward(Vector2i(1, -1)))
	assert_true(session.keen.sprite_index() in range(43, 47), "up wins over right")
	session.step(KeenInput.new())
	assert_equal(session.keen.sprite_index(), 43, "standing: the first frame")


func test_a_step_sounds_every_other_frame() -> void:
	var session := Maps.open_map(Maps.field_rows(), {}, START)
	var sounds := Maps.sounds_of(session)
	Maps.run(session, KeenInput.toward(Vector2i.RIGHT), WALK_TICKS)
	# Frames last 6.6 ticks: 9 frame changes in 60 ticks, a step on 4 of them.
	assert_equal(sounds.count(Sound.Id.MAP_WALK), 4, "four steps")
	sounds.clear()
	Maps.run(session, KeenInput.toward(Vector2i.UP), WALK_TICKS * 4)
	assert_true(sounds.has(Sound.Id.MAP_BLOCKED), "bumping into the wall")


func test_jump_or_pogo_enters_a_level() -> void:
	for pogo in [false, true]:
		var session := Maps.open_map(Maps.field_rows(), {START + Vector2i.RIGHT: 4}, START)
		Maps.run(session, KeenInput.toward(Vector2i.RIGHT), 10)
		var sounds := Maps.sounds_of(session)
		Maps.press(session, pogo)
		assert_equal(session.outcome, MapSession.Outcome.ENTER_LEVEL, "enters (pogo %s)" % pogo)
		assert_equal(session.chosen_level, 4, "level 4")
		assert_equal(sounds, [Sound.Id.MAP_ENTER_LEVEL] as Array[Sound.Id], "WLDENTERSND")
	var held := Maps.open_map(Maps.field_rows(), {START + Vector2i.RIGHT: 4}, START)
	Maps.run(held, KeenInput.toward(Vector2i.RIGHT, true), 10)
	assert_equal(held.outcome, MapSession.Outcome.PLAYING, "a held button does not count")


func test_a_blocking_cell_belongs_to_its_entrance() -> void:
	var cell := START + Vector2i(3, 0)
	var session := Maps.open_map(Maps.field_rows(), {cell: MapInfo.BLOCKING_FLAG | 7}, START)
	# As the original's god mode can: Keen stands on the blocking cell.
	session.keen.position = Maps.top_left(cell)
	Maps.press(session)
	assert_equal(session.chosen_level, 7, "0x8007 enters level 7")


func test_entrance_blocks_until_done_then_opens() -> void:
	var infos: Dictionary[Vector2i, int] = {}
	for y in range(1, Maps.FIELD_SIZE.y - 1):
		infos[Vector2i(25, y)] = MapInfo.BLOCKING_FLAG | 1
	var session := Maps.open_map(Maps.field_rows(), infos, START)
	Maps.run(session, KeenInput.toward(Vector2i.RIGHT), WALK_TICKS * 3)
	assert_equal(session.keen.hitbox().end.x, Maps.top_left(Vector2i(25, 0)).x, "blocked")
	var game := Keen3Progress.new()
	game.complete_level(1)
	session = Maps.open_map(Maps.field_rows(), infos, START, game)
	Maps.run(session, KeenInput.toward(Vector2i.RIGHT), WALK_TICKS * 3)
	assert_true(session.keen.hitbox().end.x > Maps.top_left(Vector2i(26, 0)).x, "open")


func test_done_sign_on_one_cell() -> void:
	var cell := START + Vector2i(3, 0)
	var game := Keen3Progress.new()
	game.complete_level(3)
	var session := Maps.open_map(Maps.field_rows(), {cell: 3}, START, game)
	assert_equal(session.level.tile_at(Maps.map_cell(cell)), 56, "tile 56")
	assert_equal(session.level.info_at(Maps.map_cell(cell)), 0, "info cleared")


func test_done_sign_on_two_by_two() -> void:
	var blocking := MapInfo.BLOCKING_FLAG
	# Level 2's shape (right column blocks) and level 5's (top row blocks).
	var shapes: Dictionary[int, Array] = {
		2: [2, blocking | 2, 2, blocking | 2], 5: [blocking | 5, blocking | 5, 5, 5]
	}
	for number in shapes:
		var game := Keen3Progress.new()
		game.complete_level(number)
		var session := _big_entrance(shapes[number], game)
		assert_equal(_big_tiles(session), PackedInt32Array([52, 53, 54, 55]), "level %d" % number)
		assert_equal(_big_infos(session), PackedInt32Array([0, 0, 0, 0]), "cleared %d" % number)


func test_done_sign_with_three_blocking_cells() -> void:
	var blocking := MapInfo.BLOCKING_FLAG | 15
	var game := Keen3Progress.new()
	game.complete_level(15)
	var session := _big_entrance([blocking, blocking, 15, blocking], game)
	assert_equal(_big_tiles(session), PackedInt32Array([52, 53, 54, 55]), "level 15's 2x2")
	assert_equal(_big_infos(session), PackedInt32Array([0, 0, 0, 0]), "all four cleared")
	var open := _big_entrance([blocking, blocking, 15, blocking], Keen3Progress.new())
	assert_equal(_big_infos(open)[0], blocking, "not done: untouched")


func test_done_level_cannot_be_entered() -> void:
	var game := Keen3Progress.new()
	game.complete_level(4)
	var session := Maps.open_map(Maps.field_rows(), {START + Vector2i.RIGHT: 4}, START, game)
	Maps.run(session, KeenInput.toward(Vector2i.RIGHT), 10)
	Maps.press(session)
	assert_equal(session.outcome, MapSession.Outcome.PLAYING, "not entered")


func test_the_last_info_under_keen_counts() -> void:
	var left := START + Vector2i(4, 0)
	var right := left + Vector2i.RIGHT
	var session := Maps.open_map(Maps.field_rows(), {left: 3, right: 4}, START)
	# His box (x + 2 to x + 10) over both cells.
	session.keen.position = Maps.top_left(left) + Vector2(10, 0)
	assert_equal(session.info_under_keen(), 4, "column by column: the right one is last")
	var start_last := Maps.open_map(Maps.field_rows(), {left: 3}, right)
	start_last.keen.position = Maps.top_left(left) + Vector2(10, 0)
	assert_equal(start_last.info_under_keen(), 0, "Keen's start last: nothing")


func test_the_ship_shows_a_message() -> void:
	var session := Maps.open_map(Maps.field_rows(), {START: MapInfo.SHIP}, START + Vector2i.UP)
	session.keen.position = Maps.top_left(START)
	var used := [0]
	session.ship_used.connect(func() -> void: used[0] += 1)
	Maps.press(session)
	assert_equal(used[0], 1, "one message")
	assert_equal(session.outcome, MapSession.Outcome.PLAYING, "nothing entered")


func test_messie_cells_and_the_start_do_nothing() -> void:
	for info in [Keen3MapInfo.PATH, Keen3MapInfo.WEED, Keen3MapInfo.LANDING, 0]:
		var cell := START + Vector2i(5, 0)
		var session := Maps.open_map(Maps.field_rows(), {cell: info}, START)
		session.keen.position = Maps.top_left(cell)
		var used := [false]
		session.ship_used.connect(func() -> void: used[0] = true)
		Maps.press(session)
		var idle: bool = session.outcome == MapSession.Outcome.PLAYING and not used[0]
		assert_true(idle and not session.is_teleporting(), "0x%x does nothing" % info)


func test_teleporter_goes_to_its_destination_slot() -> void:
	var a := START
	var b := Vector2i(30, 20)
	var session := Maps.open_map(Maps.field_rows(), {a: 0x0F12, b: 0x0F21}, START + Vector2i.UP)
	session.keen.position = Maps.top_left(a)
	_teleport(session)
	assert_equal(session.keen.position, Maps.top_left(b), "slot 1 to slot 2")
	_teleport(session)
	assert_equal(session.keen.position, Maps.top_left(a), "and back")


func test_teleporters_can_be_one_way() -> void:
	var cells: Array[Vector2i] = [Vector2i(5, 5), Vector2i(20, 10), Vector2i(30, 20)]
	var infos: Dictionary[Vector2i, int] = {cells[0]: 0x0F02, cells[1]: 0x0F23, cells[2]: 0x0F32}
	var session := Maps.open_map(Maps.field_rows(), infos, START)
	session.keen.position = Maps.top_left(cells[0])
	_teleport(session)
	assert_equal(session.keen.position, Maps.top_left(cells[1]), "slot 0 to slot 2")
	_teleport(session)
	assert_equal(session.keen.position, Maps.top_left(cells[2]), "slot 2 to slot 3, not back")
	_teleport(session)
	assert_equal(session.keen.position, Maps.top_left(cells[1]), "slot 3 to slot 2")


func test_teleporter_animation_and_view() -> void:
	var a := START
	var b := Vector2i(30, 20)
	var session := Maps.open_map(Maps.field_rows(), {a: 0x0F12, b: 0x0F21}, START + Vector2i.UP)
	session.keen.position = Maps.top_left(a)
	var shown: Dictionary[Vector2i, Array] = {Maps.map_cell(a): [], Maps.map_cell(b): []}
	session.tile_changed.connect(func(cell: Vector2i, tile: int) -> void: shown[cell].append(tile))
	var sounds := Maps.sounds_of(session)
	Maps.press(session)
	var ticks := 0
	var hidden := true
	while session.is_teleporting():
		hidden = hidden and session.keen.hidden
		session.step(KeenInput.toward(Vector2i.RIGHT))
		ticks += 1
	var cycle := [130, 131, 132, 133, 130, 131, 132, 133, 134]
	assert_equal(shown[Maps.map_cell(a)], cycle, "the source: twice 130-133, then 134")
	assert_equal(shown[Maps.map_cell(b)], cycle, "the destination the same")
	assert_equal(sounds.count(Sound.Id.TELEPORT), 4, "TELEPORTSND at each cycle")
	assert_true(hidden and not session.keen.hidden, "Keen hidden until he arrives")
	# 16 tiles of 5 retraces each (seen in js-dos: 1.14 s).
	assert_true(absi(ticks - 69) <= 1, "about 69 ticks, not %d" % ticks)
	var corner := Maps.top_left(b) - Vector2(160, 96)
	assert_equal(session.scroll.corner, corner, "the destination 10 cells right, 6 down")


func test_new_game_view() -> void:
	var session := Maps.open_map(Maps.field_rows(), {}, START)
	var corner := Maps.top_left(START) - Vector2(144, 48)
	assert_equal(session.scroll.corner, corner, "Keen 9 cells from the left, 3 from the top")
	var edge := Maps.open_map(Maps.field_rows(), {}, Vector2i(1, 1))
	assert_equal(edge.scroll.corner, Maps.top_left(Vector2i.ZERO), "never past the border")


func test_view_moves_with_keen_past_the_free_stretch() -> void:
	var session := Maps.open_map(Maps.field_rows(), {}, START)
	var corner := session.scroll.corner
	Maps.run(session, KeenInput.toward(Vector2i.RIGHT), 15)
	assert_equal(session.scroll.corner, corner, "free from 9 to 11 cells")
	Maps.run(session, KeenInput.toward(Vector2i.RIGHT), WALK_TICKS)
	var relative := session.keen.position.x - session.scroll.corner.x
	# The view moves as far as Keen once he would pass 11 cells (seen in
	# js-dos: he stays at x 176 on the screen).
	assert_true(relative > 174.0 and relative <= 176.0, "then the view moves along")
	Maps.run(session, KeenInput.toward(Vector2i.UP), 5)
	relative = session.keen.position.y - session.scroll.corner.y
	assert_true(absf(relative - 48.0) < NEAR, "3 cells from the top going up")


func test_map_remembers_keen_and_view_after_a_level() -> void:
	var game := Keen3Progress.new()
	var entrance := START + Vector2i(6, 6)
	var session := Maps.open_map(Maps.field_rows(), {entrance: 6}, START, game)
	Maps.run(session, KeenInput.toward(Vector2i(1, 1)), 60)
	Maps.press(session)
	assert_equal(session.chosen_level, 6, "entered")
	var position := session.keen.position
	var corner := session.scroll.corner
	var back := Maps.open_map(Maps.field_rows(), {entrance: 6}, START, game)
	assert_equal(back.keen.position, position, "where he entered")
	assert_equal(back.scroll.corner, corner, "the same view")


func test_info_values() -> void:
	assert_true(Keen3MapInfo.is_teleporter(0x0F12), "0x0F12 is a teleporter")
	assert_equal(Keen3MapInfo.own_slot(0x0FAE), 10, "its own slot")
	assert_equal(Keen3MapInfo.destination_slot(0x0FAE), 14, "where it leads")
	for info in [0x2000, 0x2100, 0x2200, 0x8001, 20, 255]:
		assert_true(not Keen3MapInfo.is_teleporter(info), "0x%x is none" % info)
	assert_true(Keen3MapInfo.is_messie_cell(0x2200), "a landing is Messie's")
	assert_true(not Keen3MapInfo.is_messie_cell(0x0F22), "a teleporter is not")
	assert_true(absf(Keen3MapInfo.ticks_for_frames(24.275) - 60.0) < NEAR, "a second")


## A 2x2 entrance with [param values] (top left, top right, bottom left,
## bottom right) at cells (8, 8)-(9, 9).
func _big_entrance(values: Array, game: Keen3Progress) -> Keen3MapSession:
	var infos: Dictionary[Vector2i, int] = {}
	for corner in Keen3MapSession.BIG_ENTRANCE_CELLS.size():
		infos[Vector2i(8, 8) + Keen3MapSession.BIG_ENTRANCE_CELLS[corner]] = values[corner]
	return Maps.open_map(Maps.field_rows(), infos, START, game)


func _big_tiles(session: Keen3MapSession) -> PackedInt32Array:
	var tiles := PackedInt32Array()
	for offset in Keen3MapSession.BIG_ENTRANCE_CELLS:
		tiles.append(session.level.tile_at(Maps.map_cell(Vector2i(8, 8) + offset)))
	return tiles


func _big_infos(session: Keen3MapSession) -> PackedInt32Array:
	var infos := PackedInt32Array()
	for offset in Keen3MapSession.BIG_ENTRANCE_CELLS:
		infos.append(session.level.info_at(Maps.map_cell(Vector2i(8, 8) + offset)))
	return infos


## Presses the button and waits until the teleporter is done.
func _teleport(session: Keen3MapSession) -> void:
	Maps.press(session)
	Maps.run(session, KeenInput.new(), TELEPORT_TICKS)
