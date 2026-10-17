extends "res://tests/test_case.gd"
## Tests for Keen 2's switches in small hand-made levels, without Keen 2's
## files (tests/keen2_fixtures.gd): the pogo button presses a switch near
## Keen instead of taking out the pogo stick, bridges are laid and taken in
## tile by tile, the light switch makes the level dark (and the Vorticons
## stop jumping), and the Vorticon Elder speaks once, only with its light
## below. Also the finders of the Elder messages in a hand-made KEEN2.EXE
## image. The Tantalus Ray machine is in tests/test_keen2_tantalus.gd.

const Fixtures := preload("res://tests/keen2_fixtures.gd")
const SETTLE_TICKS := 60
## Long enough for a random event of a few in 1000 per tick to happen.
const LONG_RUN := 1500
const KEEN_CELL := Vector2i(2, 12)
const FLOOR_ROW := 14
## Keen stands in front of the lever in column 2; its bridge starts in the
## gap of the floor (column 5) and runs right to the wall in column 15.
const BRIDGE_LEVEL: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..d...........................",
	"#####----------#####..........",
]
const SWITCH_CELL := Vector2i(2, 13)
## From the switch to the start of the bridge: 3 right, 1 down.
const BRIDGE_INFO := 0x0103
const BRIDGE_START := Vector2i(5, 14)
const BRIDGE_LENGTH := 10
## From the switch to column 14: the tile right of it is a wall, so the
## bridge runs left, to the wall in column 4.
const LEFT_BRIDGE_INFO := 0x010C
const LEFT_BRIDGE_START := Vector2i(14, 14)
## A light switch next to Keen, and a pen for the Vorticons.
const LIGHT_LEVEL: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..........###########.........",
	"..........#.........#.........",
	"..........#.........#.........",
	"..........#.........#.........",
	"..........#.........#.........",
	"..........#.........#.........",
	"..........#.........#.........",
	"..L.......#.........#.........",
	"##############################",
]
const PEN_COLUMN := 15
## Elders at the height of Keen's head: the first with its light below.
const ELDER_LEVEL: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"....V.....V...................",
	"....o.........................",
	"##############################",
]
const ELDER_CELL := Vector2i(4, 12)
const SILENT_ELDER_CELL := Vector2i(10, 12)
const ELDER_MESSAGE_1 := "You hear in your mind:\n\nIn the dark the Vorticons\ncannot jump!\n"
const ELDER_MESSAGE_2 := "Hear:\r\n\r\nBeware the evil belts   \r\nof the Vorticons."
const IMAGE_SIZE := 0x1A400
const FILLER := 0x01


func test_pogo_button_on_a_switch_flips_it_and_keeps_the_pogo_away() -> void:
	var session := _session(BRIDGE_LEVEL, {SWITCH_CELL: BRIDGE_INFO})
	var sounds := _sounds(session)
	_press(session)
	_run(session, KeenInput.create(0, false, true), 10)
	assert_equal(session.level.tile_at(_cell(SWITCH_CELL)), Fixtures.LEVER_UP, "493 became 480")
	assert_true(not session.keen.on_pogo, "no pogo while the button is held")
	assert_true(sounds.has(Sound.Id.CLICK), "click")
	_run(session, KeenInput.create(0), 1)
	_press(session)
	assert_equal(session.level.tile_at(_cell(SWITCH_CELL)), Fixtures.LEVER_DOWN, "and back")


func test_pogo_button_elsewhere_takes_out_the_pogo() -> void:
	var session := _session(Fixtures.FIELD)
	_press(session)
	assert_true(session.keen.on_pogo, "on the pogo stick")


func test_pogo_on_a_switch_is_put_away() -> void:
	var session := _session(BRIDGE_LEVEL, {SWITCH_CELL: BRIDGE_INFO})
	session.keen.on_pogo = true
	_press(session)
	assert_true(not session.keen.on_pogo, "put away")
	assert_equal(session.level.tile_at(_cell(SWITCH_CELL)), Fixtures.LEVER_UP, "pressed")


func test_bridge_extends_a_tile_every_4_ticks_to_the_right() -> void:
	var session := _session(BRIDGE_LEVEL, {SWITCH_CELL: BRIDGE_INFO})
	_press(session)
	_run(session, KeenInput.create(0), Keen2Bridge.TICKS_PER_TILE - 2)
	assert_equal(_bridge_tiles(session), 0, "nothing before the 4th tick")
	_run(session, KeenInput.create(0), 1)
	assert_equal(_bridge_tiles(session), 1, "one tile after 4 ticks")
	assert_equal(session.level.tile_at(_cell(BRIDGE_START)), Fixtures.BRIDGE, "at the start")
	_run(session, KeenInput.create(0), Keen2Bridge.TICKS_PER_TILE)
	assert_equal(_bridge_tiles(session), 2, "two after 8")
	var next := _cell(BRIDGE_START + Vector2i.RIGHT)
	assert_equal(session.level.tile_at(next), Fixtures.BRIDGE, "to the right")


func test_bridge_stops_at_a_wall() -> void:
	var session := _session(BRIDGE_LEVEL, {SWITCH_CELL: BRIDGE_INFO})
	_press(session)
	_run(session, KeenInput.create(0), Keen2Bridge.TICKS_PER_TILE * (BRIDGE_LENGTH + 5))
	assert_equal(_bridge_tiles(session), BRIDGE_LENGTH, "columns 5-14")
	var wall := _cell(BRIDGE_START + Vector2i(BRIDGE_LENGTH, 0))
	assert_equal(session.level.tile_at(wall), Fixtures.WALL, "the wall stays")


func test_bridge_runs_left_when_a_wall_is_on_its_right() -> void:
	var session := _session(BRIDGE_LEVEL, {SWITCH_CELL: LEFT_BRIDGE_INFO})
	_press(session)
	_run(session, KeenInput.create(0), Keen2Bridge.TICKS_PER_TILE * 2 - 1)
	var second := _cell(LEFT_BRIDGE_START + Vector2i.LEFT)
	assert_equal(session.level.tile_at(second), Fixtures.BRIDGE, "the second tile is left")
	_run(session, KeenInput.create(0), Keen2Bridge.TICKS_PER_TILE * BRIDGE_LENGTH)
	assert_equal(_bridge_tiles(session), BRIDGE_LENGTH, "to the wall in column 4")


func test_bridge_retracts_from_the_far_end_and_restores_the_background() -> void:
	var session := _session(BRIDGE_LEVEL, {SWITCH_CELL: BRIDGE_INFO})
	_press(session)
	_run(session, KeenInput.create(0), Keen2Bridge.TICKS_PER_TILE * (BRIDGE_LENGTH + 1))
	var changed: Array[Vector2i] = []
	session.tile_changed.connect(func(cell: Vector2i, _tile: int) -> void: changed.append(cell))
	_press(session)
	_run(session, KeenInput.create(0), Keen2Bridge.TICKS_PER_TILE - 1)
	var far_end := _cell(BRIDGE_START + Vector2i(BRIDGE_LENGTH - 1, 0))
	assert_equal(session.level.tile_at(far_end), Fixtures.GRAY, "the far end goes first")
	assert_equal(_bridge_tiles(session), BRIDGE_LENGTH - 1, "one tile less")
	_run(session, KeenInput.create(0), Keen2Bridge.TICKS_PER_TILE * BRIDGE_LENGTH)
	assert_equal(_bridge_tiles(session), 0, "gone")
	for x in BRIDGE_LENGTH:
		var cell := _cell(BRIDGE_START + Vector2i(x, 0))
		assert_equal(session.level.tile_at(cell), Fixtures.GRAY, "background at %d" % x)
	assert_true(changed.has(_cell(BRIDGE_START)), "every change is announced")


func test_keen_stands_on_the_bridge_as_it_extends() -> void:
	var session := _session(BRIDGE_LEVEL, {SWITCH_CELL: BRIDGE_INFO})
	var feet := session.keen.hitbox().end.y
	_press(session)
	var lowest := feet
	for tick in 60:
		session.step(KeenInput.create(1))
		lowest = maxf(lowest, session.keen.hitbox().end.y)
	assert_true(session.keen.hitbox().position.x > Fixtures.column_left(8), "walked out")
	assert_equal(lowest, feet, "never sank below the floor")
	assert_equal(session.keen.state, KeenBody.State.STANDING, "stands on the bridge")


func test_bridge_offsets_are_signed_bytes() -> void:
	assert_equal(Keen2Switches.bridge_offset(0x0103), Vector2i(3, 1), "3 right, 1 down")
	assert_equal(Keen2Switches.bridge_offset(0xFF03), Vector2i(3, -1), "1 up")
	assert_equal(Keen2Switches.bridge_offset(0x01FE), Vector2i(-2, 1), "2 left")


func test_nothing_spawns_at_a_switch() -> void:
	var infos: Dictionary[Vector2i, int] = {SWITCH_CELL: Keen2LevelSession.INFO_ELITE}
	var session := _session(BRIDGE_LEVEL, infos)
	assert_true(session.enemies().is_empty(), "the info value is the bridge's")


func test_a_new_session_starts_lit() -> void:
	var session := Fixtures.begin_session(LIGHT_LEVEL, KEEN_CELL)
	assert_true(not session.is_dark(), "lit")


func test_light_switch_toggles_darkness() -> void:
	var session := _session(LIGHT_LEVEL)
	var changes: Array[bool] = []
	session.lights_changed.connect(func(dark: bool) -> void: changes.append(dark))
	_press(session)
	assert_true(session.is_dark(), "dark")
	assert_true(Keen2Enemy.is_dark(session), "the enemies see it")
	assert_true(not session.keen.on_pogo, "no pogo")
	_run(session, KeenInput.create(0), 1)
	_press(session)
	assert_true(not session.is_dark(), "lit again")
	assert_equal(changes, [true, false] as Array[bool], "announced")


func test_vorticons_do_not_jump_in_the_dark() -> void:
	var session := _session(LIGHT_LEVEL)
	_press(session)
	var grunt := Keen2Grunt.create(_on_floor(Keen2Grunt.BODY_BOX, PEN_COLUMN - 2))
	var elite := Keen2Elite.create(_on_floor(Keen2Elite.BODY_BOX, PEN_COLUMN + 2))
	for enemy: Enemy in [grunt, elite]:
		session.add_actor(enemy)
		enemy.settle(session)
		enemy.is_active = true
	var jumped := {}
	for tick in LONG_RUN:
		session.step(KeenInput.create(0))
		if grunt.mode == Keen2Grunt.Mode.JUMPING:
			jumped[grunt] = true
		if elite.mode == Keen2Elite.Mode.JUMPING:
			jumped[elite] = true
	assert_true(jumped.is_empty(), "nobody jumped in the dark")
	_press(session)
	for tick in LONG_RUN:
		session.step(KeenInput.create(0))
		if grunt.mode == Keen2Grunt.Mode.JUMPING:
			jumped[grunt] = true
	assert_true(jumped.has(grunt), "the grunt jumps again in the light")


func test_elder_speaks_once_with_its_light_below() -> void:
	var session := Fixtures.begin_session(ELDER_LEVEL, KEEN_CELL)
	var spoken := [0]
	session.elder_message_touched.connect(func() -> void: spoken[0] += 1)
	_run(session, KeenInput.create(1), 50)
	assert_equal(spoken[0], 1, "spoke once")
	var light := _cell(ELDER_CELL + Vector2i.DOWN)
	assert_equal(session.level.tile_at(light), Keen2LevelSession.ELDER_LIGHT_OFF, "light out")
	_run(session, KeenInput.create(-1), 50)
	_run(session, KeenInput.create(1), 120)
	assert_true(session.keen.hitbox().position.x > Fixtures.column_left(11), "passed both")
	assert_equal(spoken[0], 1, "never again, and not without a light")


func test_elder_messages_are_found_at_their_known_places() -> void:
	var image := _image_with_messages()
	var executable := Keen2Executable.from_image(image)
	for index in 2:
		var expected := Keen2Executable.ELDER_MESSAGE_OFFSETS[index]
		assert_equal(Keen2Executable.find_elder_message(image, index), expected, "%d" % index)
	var first := executable.elder_message(0)
	assert_equal(first[0], "You hear in your mind:", "first line")
	assert_equal(first.size(), 4, "ending line breaks dropped")
	var second := executable.elder_message(1)
	assert_equal(second[2], "Beware the evil belts", "carriage returns and spaces dropped")
	assert_equal(Keen2LevelPlay.elder_message_index(8), 0, "level 8 has the first")
	assert_equal(Keen2LevelPlay.elder_message_index(10), 1, "another has the second")


func test_elder_messages_missing_or_damaged_are_not_found() -> void:
	var image := _filler(IMAGE_SIZE)
	var executable := Keen2Executable.from_image(image)
	assert_true(executable.elder_message(0).is_empty(), "not in a filler image")
	image = _image_with_messages()
	image[Keen2Executable.ELDER_MESSAGE_OFFSETS[1] + 5] = 0x07
	assert_equal(Keen2Executable.find_elder_message(image, 1), -1, "a control byte")
	assert_equal(Keen2Executable.find_elder_message(image, 2), -1, "only two messages")
	assert_true(Keen2Executable.from_image(PackedByteArray()).elder_message(0).is_empty(), "empty")


## A session with Keen standing on the floor at [constant KEEN_CELL].
func _session(rows: PackedStringArray, infos: Dictionary[Vector2i, int] = {}) -> Keen2LevelSession:
	var session := Fixtures.begin_session(rows, KEEN_CELL, infos)
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	return session


## One tick with the pogo button down (it was up before).
func _press(session: LevelSession) -> void:
	session.step(KeenInput.create(0, false, true))


func _run(session: LevelSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


func _sounds(session: LevelSession) -> Array[Sound.Id]:
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	return sounds


func _bridge_tiles(session: LevelSession) -> int:
	var count := 0
	for x in session.level.width:
		if (
			session.level.tile_at(_cell(Vector2i(x - LevelData.BORDER_CELLS, FLOOR_ROW)))
			== Fixtures.BRIDGE
		):
			count += 1
	return count


func _cell(cell: Vector2i) -> Vector2i:
	return cell + Vector2i.ONE * LevelData.BORDER_CELLS


func _on_floor(box: Rect2, column: int) -> Vector2:
	return Fixtures.on_floor(box, column, FLOOR_ROW)


func _image_with_messages() -> PackedByteArray:
	var image := _filler(IMAGE_SIZE)
	var messages: PackedStringArray = [ELDER_MESSAGE_1, ELDER_MESSAGE_2]
	for index in messages.size():
		var start := Keen2Executable.ELDER_MESSAGE_OFFSETS[index]
		var bytes := messages[index].to_ascii_buffer()
		bytes.append(0)
		for offset in bytes.size():
			image[start + offset] = bytes[offset]
		image[start - 1] = 0
	return image


func _filler(size: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(size)
	bytes.fill(FILLER)
	return bytes
