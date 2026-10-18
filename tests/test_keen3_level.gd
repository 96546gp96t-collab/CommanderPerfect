extends "res://tests/test_case.gd"
## Tests for playing a Keen 3 level ([Keen3LevelSession], [Keen3Shot],
## [Keen3LevelPlay]) in small hand-made levels, without Keen 3's files: the
## items and what they leave, keycards and doors, exits, deadly tiles,
## behaviour 22, the info values, the shots. Keen himself and the ankh are in
## tests/test_keen3_keen.gd; see tests/keen3_fixtures.gd for the level
## characters. The real files are tried in tests/test_keen3_play.gd.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const SETTLE_TICKS := 120
const WALK_TICKS := 240

## Keen starts on the left, standing on the floor in row 14.
const FIELD: PackedStringArray = [
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
	"..............................",
	"##############################",
]
const START_CELL := Vector2i(2, 12)
const FEET_ROW := 13
## The info values of level 16's machine (research.md §5), which spawn
## nothing until C7: the enemies (1-6, 11) came in C4, the ball, jack,
## platforms and guns (7-10, 14, 15) in C5.
const MACHINE_INFOS: Array[int] = [12, 13, 16, 17, 18]


func test_points_per_behaviour() -> void:
	var session := _session_with_items("....5.1.2.K.N.......")
	var changed: Dictionary[Vector2i, int] = {}
	session.tile_changed.connect(func(cell: Vector2i, tile: int) -> void: changed[cell] = tile)
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.inventory.score, 500 + 100 + 200 + 1000 + 5000, "all five")
	assert_equal(changed.size(), 5, "five tiles changed")
	for cell in changed:
		assert_equal(changed[cell], Fixtures.ITEM_ROW, "the first tile of the row is left")


func test_candy_bar_and_burger_follow_the_table() -> void:
	var candy := _session_with_items("....5...............")
	_run(candy, KeenInput.create(1), WALK_TICKS)
	assert_equal(candy.inventory.score, 500, "candy bar (behaviour 6): 500")
	var burger := _session_with_items("....1...............")
	_run(burger, KeenInput.create(1), WALK_TICKS)
	assert_equal(burger.inventory.score, 100, "burger (behaviour 7): 100")


func test_an_item_leaves_the_first_tile_of_its_row() -> void:
	var session := _session_with_items("....6...............")
	_run(session, KeenInput.create(1), WALK_TICKS)
	var cell := Vector2i(4, FEET_ROW) + _border()
	assert_equal(session.level.tile_at(cell), Fixtures.OTHER_ROW, "tile 182 for tile 183")
	assert_equal(Keen3LevelSession.row_background(149), 143, "the ankh of the first row")
	assert_equal(Keen3LevelSession.row_background(220), 208, "the last item")
	assert_equal(Keen3LevelSession.row_background(208), 208, "a background stays itself")


func test_raygun_adds_five_charges() -> void:
	var session := _session_with_items("....g...............")
	var sounds := _sounds(session)
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.inventory.charges, 5 + 5, "+5")
	assert_true(sounds.has(Sound.Id.GOT_ITEM), "GOTITEMSND")


func test_single_charge_adds_one() -> void:
	var session := _session_with_items("....c.c.............")
	var sounds := _sounds(session)
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.inventory.charges, 5 + 2, "+1 each")
	assert_equal(sounds.count(Sound.Id.GOT_ITEM), 2, "GOTITEMSND for each")
	assert_equal(session.inventory.score, 0, "no points")


func test_keycards_are_picked_up() -> void:
	var session := _session_with_items("....y.k.n.b.........")
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_true(not session.inventory.keycards.has(false), "all four")


func test_door_takes_the_tile_left_of_its_top() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW - 1] = ".........wD..................."
	rows[FEET_ROW] = "......k...D..................."
	var session := _session(rows)
	var door_top := Vector2i(10, FEET_ROW - 1) + _border()
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.level.tile_at(door_top), Fixtures.WALLPAPER, "top cell")
	assert_equal(session.level.tile_at(door_top + Vector2i.DOWN), Fixtures.WALLPAPER, "bottom")
	assert_true(not session.inventory.has_keycard(TileProperties.KeyColor.RED), "card used up")
	assert_true(session.keen.hitbox().position.x > _column_left(11), "walked through")


func test_door_sinks_as_in_keen_1() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW - 1] = ".........wD..................."
	rows[FEET_ROW] = "......k...D..................."
	var session := _session(rows)
	var doors: Array[OpeningDoor] = []
	for tick in WALK_TICKS:
		session.step(KeenInput.create(1))
		for actor in session.actors:
			if actor is OpeningDoor and not doors.has(actor):
				doors.append(actor)
	assert_equal(doors.size(), 1, "one door sank")
	if doors.size() == 1:
		assert_equal(
			doors[0].tiles, PackedInt32Array([Fixtures.RED_DOOR, Fixtures.RED_DOOR]), "tiles"
		)


func test_door_stays_shut_without_the_keycard() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW - 1] = "..........D..................."
	rows[FEET_ROW] = "..........D..................."
	var session := _session(rows)
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.keen.hitbox().end.x, _column_left(10), "stopped at the door")


func test_exit_ends_the_level() -> void:
	var session := _session_with_items("......E.............")
	_run(session, KeenInput.create(1), WALK_TICKS)
	_run(session, KeenInput.create(0), KeenPhysics.EXIT_TICKS)
	assert_equal(session.outcome, LevelSession.Outcome.COMPLETED, "completed")


func test_either_of_two_exits_ends_the_level() -> void:
	var items := "....E.........E....."
	for direction in [-1, 1]:
		var rows := FIELD.duplicate()
		rows[FEET_ROW] = items + rows[FEET_ROW].substr(items.length())
		var session := Fixtures.start_session(rows, Vector2i(9, 12))
		_run(session, KeenInput.create(0), SETTLE_TICKS)
		_run(session, KeenInput.create(direction), WALK_TICKS)
		_run(session, KeenInput.create(0), KeenPhysics.EXIT_TICKS)
		assert_equal(session.outcome, LevelSession.Outcome.COMPLETED, "exit %d" % direction)


func test_deadly_tile_kills() -> void:
	var session := _session_with_items("....X...............")
	var inventory := session.inventory
	_run_until_over(session, KeenInput.create(1))
	assert_equal(session.outcome, LevelSession.Outcome.DIED, "died")
	assert_equal(inventory.lives, 3, "one life less")


func test_extra_life_at_20000() -> void:
	var session := _session_with_items("....N.N.N.N.........")
	var sounds := _sounds(session)
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.inventory.score, 20000, "four stuffed ninjas")
	assert_equal(session.inventory.lives, 5, "an extra life")
	assert_true(sounds.has(Sound.Id.EXTRA_LIFE), "EXTRAMANSND")


func test_behaviour_22_only_becomes_143() -> void:
	var session := _session_with_items("....o...............")
	var hints := [0]
	session.hint_touched.connect(func() -> void: hints[0] += 1)
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.level.tile_at(Vector2i(4, FEET_ROW) + _border()), 143, "tile 143")
	assert_equal(hints[0], 0, "no message")
	assert_equal(session.inventory.score, 0, "no points")
	assert_equal(session.outcome, LevelSession.Outcome.PLAYING, "nothing else")


func test_the_machine_info_values_spawn_nothing_yet() -> void:
	var infos: Dictionary[Vector2i, int] = {}
	for value in MACHINE_INFOS:
		infos[Vector2i(value, FEET_ROW - 1)] = value
	var session := Keen3LevelSession.started(
		Fixtures.create_level(FIELD, infos),
		Fixtures.level_properties(),
		Keen3Inventory.new(),
		Fixtures.cell_top_left(START_CELL)
	)
	assert_true(session.actors.is_empty(), "nothing before C7")
	assert_true(session.keen is Keen3Body, "Keen 3's Keen")


func test_shots_use_keen_3_sprites() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW] = "..........#..................."
	var session := _session(rows)
	_run(session, KeenInput.create(0, false, false, true), 1)
	assert_equal(session.inventory.charges, 4, "a charge used")
	var shot := session.actors[0] as Keen3Shot if session.actors.size() == 1 else null
	assert_true(shot != null, "a Keen 3 shot")
	if shot == null:
		return
	assert_equal(shot.sprite_index(), 102, "KEENSHOT")
	_run(session, KeenInput.create(0), WALK_TICKS / 4)
	assert_true(shot.is_splashing, "hit the wall")
	assert_equal(shot.sprite_index(), 105, "SHOTSPLASHR")


func test_keycards_are_gone_after_the_level() -> void:
	var play := Keen3LevelPlay.create(null, Fixtures.level_properties())
	play.session = Fixtures.start_session(FIELD, START_CELL, play.inventory)
	play.level_number = Keen3Files.LAST_LEVEL
	play.state = Keen3LevelPlay.State.PLAYING
	play.inventory.keycards.fill(true)
	var done := [false]
	play.won.connect(func() -> void: done[0] = true)
	play.session.outcome = LevelSession.Outcome.COMPLETED
	play.step(KeenInput.new())
	assert_true(not play.inventory.keycards.has(true), "no keycards")
	assert_true(done[0], "level 16 done: the game is won")


func test_levels_1_to_16() -> void:
	assert_true(Keen3LevelPlay.is_playable(1) and Keen3LevelPlay.is_playable(16), "1 to 16")
	for number in [0, 17, 80, 81, 90]:
		assert_true(not Keen3LevelPlay.is_playable(number), "%d is not played in C3" % number)


func test_keen_3_scene_is_the_game_screen() -> void:
	var state := (load(GameLaunch.KEEN_3_SCENE) as PackedScene).get_state()
	var script: Script = null
	for index in state.get_node_property_count(0):
		if state.get_node_property_name(0, index) == &"script":
			script = state.get_node_property_value(0, index)
	assert_true(script != null and script.get_global_name() == &"Keen3View", "Keen3View")
	var base := script.get_base_script() if script != null else null
	while base != null and base.get_global_name() != &"GameScreen":
		base = base.get_base_script()
	assert_true(base != null, "on GameScreen")


## A session with [param items] in Keen's row, Keen standing at
## [constant START_CELL].
func _session_with_items(items: String) -> Keen3LevelSession:
	var rows := FIELD.duplicate()
	rows[FEET_ROW] = items + rows[FEET_ROW].substr(items.length())
	return _session(rows)


## A session with Keen standing on the floor.
func _session(rows: PackedStringArray) -> Keen3LevelSession:
	var session := Fixtures.start_session(rows, START_CELL)
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	return session


## The shared sounds that [param session] plays from now on.
func _sounds(session: LevelSession) -> Array[Sound.Id]:
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	return sounds


func _run(session: LevelSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


## Runs [param session] until the attempt is over (at most a long while).
func _run_until_over(session: LevelSession, input: KeenInput) -> void:
	for tick in WALK_TICKS * 4:
		if session.outcome != LevelSession.Outcome.PLAYING:
			return
		session.step(input)


func _border() -> Vector2i:
	return Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)


func _column_left(column: int) -> float:
	return (column + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
