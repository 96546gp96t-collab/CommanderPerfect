extends "res://tests/test_case.gd"
## Tests for playing a Keen 2 level ([Keen2LevelSession], [Keen2Inventory],
## [Keen2Shot], [Keen2LevelPlay]) in small hand-made levels, without Keen
## 2's files. See tests/keen2_fixtures.gd for the level characters. The
## generic rules must work as in Keen 1; Keen 1's own things (its enemies,
## ship parts, statues, teleporters) must not happen. Keen 2's enemies are
## in tests/test_keen2_enemies.gd and tests/test_keen2_riding.gd.

const Fixtures := preload("res://tests/keen2_fixtures.gd")
const SETTLE_TICKS := 120
const WALK_TICKS := 240
const POGO_TICKS := 2

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
## Info values that are enemies in Keen 1, and bridge offsets of Keen 2's
## switches. In Keen 2, 1-6 are enemies (tests/test_keen2_enemies.gd).
const ENEMY_INFOS: PackedInt32Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const KEEN_2_ENEMY_INFOS := 7
const BRIDGE_INFOS: PackedInt32Array = [0x0102, 0xFF03, 0x01FE]


func test_inventory_starts_as_in_keen_2() -> void:
	var inventory := Keen2Inventory.new()
	assert_equal(inventory.lives, Inventory.START_LIVES, "4 lives")
	assert_equal(Inventory.START_LIVES, 4, "Keen 1's start lives are 4 too")
	assert_true(inventory.has_pogo, "the pogo stick from the start")
	assert_equal(inventory.charges, Keen2Inventory.START_CHARGES, "starting charges")
	assert_equal(inventory.next_extra_life(), 20000, "first extra life at 20,000")
	assert_true(not inventory.ship_parts.has(true), "no ship parts")


func test_points_match_keen_2() -> void:
	var expected := {
		TileProperties.Behavior.POINTS_500: 500,
		TileProperties.Behavior.POINTS_100: 100,
		TileProperties.Behavior.POINTS_200: 200,
		TileProperties.Behavior.POINTS_1000: 1000,
		TileProperties.Behavior.POINTS_5000: 5000,
	}
	assert_equal(LevelSession.POINTS, expected, "behaviours 6-10")


func test_walking_over_items_gives_points() -> void:
	var session := _session_with_items("....1.2.5.K.B.......")
	var changed: Array[Vector2i] = []
	session.tile_changed.connect(func(cell: Vector2i, _tile: int) -> void: changed.append(cell))
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.inventory.score, 100 + 200 + 500 + 1000 + 5000, "all five")
	assert_equal(changed.size(), 5, "five tiles changed")
	for cell in changed:
		assert_equal(session.level.tile_at(cell), LevelSession.BACKGROUND_TILE, "tile 143 left")


func test_high_item_leaves_its_own_background() -> void:
	var session := _session_with_items("....H...............")
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.inventory.score, 100, "points")
	var cell := Vector2i(4, FEET_ROW) + _border()
	assert_equal(session.level.tile_at(cell), LevelSession.HIGH_BACKGROUND_TILE, "tile 276")


func test_raygun_adds_charges() -> void:
	var session := _session_with_items("....g...............")
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(
		session.inventory.charges, Keen2Inventory.START_CHARGES + Inventory.RAYGUN_CHARGES, "+5"
	)


func test_keycards_are_picked_up() -> void:
	var session := _session_with_items("....y.k.n.b.........")
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_true(not session.inventory.keycards.has(false), "all four")


func test_keycard_opens_the_door() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW - 1] = "..........D..................."
	rows[FEET_ROW] = "......k...D..................."
	var session := _session(rows)
	var door_top := Vector2i(10, FEET_ROW - 1) + _border()
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.level.tile_at(door_top), LevelSession.BACKGROUND_TILE, "top tile 143")
	assert_equal(
		session.level.tile_at(door_top + Vector2i.DOWN), LevelSession.BACKGROUND_TILE, "bottom"
	)
	assert_true(not session.inventory.has_keycard(TileProperties.KeyColor.RED), "card used up")
	assert_true(session.keen.hitbox().position.x > _column_left(11), "walked through")


func test_door_stays_shut_without_the_keycard() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW - 1] = "..........D..................."
	rows[FEET_ROW] = "..........D..................."
	var session := _session(rows)
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.keen.hitbox().end.x, _column_left(10), "stopped at the door")


func test_deadly_tile_kills() -> void:
	var session := _session_with_items("....X...............")
	var inventory := session.inventory
	while session.outcome == LevelSession.Outcome.PLAYING:
		session.step(KeenInput.create(1))
	assert_equal(session.outcome, LevelSession.Outcome.DIED, "died")
	assert_equal(inventory.lives, Inventory.START_LIVES - 1, "one life less")


func test_exit_ends_the_level() -> void:
	var session := _session_with_items("......E.............")
	_run(session, KeenInput.create(1), WALK_TICKS)
	_run(session, KeenInput.create(0), KeenPhysics.EXIT_TICKS)
	assert_equal(session.outcome, LevelSession.Outcome.COMPLETED, "completed")


func test_pogo_works_from_the_first_tick() -> void:
	var session := _begin(FIELD)
	_run(session, KeenInput.create(0, false, true), POGO_TICKS)
	assert_true(session.keen.on_pogo, "on the pogo stick at once")


func test_pogo_even_with_a_plain_inventory() -> void:
	var inventory := Inventory.new()
	var session := Keen2LevelSession.begin(
		Fixtures.create_level(FIELD), Fixtures.create_properties(), inventory, _start()
	)
	_run(session, KeenInput.create(0, false, true), POGO_TICKS)
	assert_true(inventory.has_pogo and session.keen.on_pogo, "Keen 2 always has it")


func test_extra_life_at_20000() -> void:
	var session := _session_with_items("....B.B.B.B.........")
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.inventory.score, 20000, "four bears")
	assert_equal(session.inventory.lives, Inventory.START_LIVES + 1, "an extra life")


func test_keen_1_specials_do_nothing() -> void:
	var session := _session_with_items("....V.T.J.L.........")
	var hints := [0]
	session.hint_touched.connect(func() -> void: hints[0] += 1)
	var changed := [0]
	session.tile_changed.connect(func(_cell: Vector2i, _tile: int) -> void: changed[0] += 1)
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.outcome, LevelSession.Outcome.PLAYING, "no teleporter")
	assert_equal(hints[0], 0, "no statue message")
	assert_equal(changed[0], 0, "no tile changed")
	assert_true(not session.inventory.ship_parts.has(true), "no ship part")
	assert_equal(session.inventory.score, 0, "no points")
	assert_true(session.keen.hitbox().position.x > _column_left(11), "walked past them all")


func test_only_enemy_info_values_spawn_something() -> void:
	var infos: Dictionary[Vector2i, int] = {}
	var column := 4
	for value in ENEMY_INFOS + BRIDGE_INFOS:
		infos[Vector2i(column, FEET_ROW - 1)] = value
		column += 2
	var level := Fixtures.create_level(FIELD, infos)
	var session := Keen2LevelSession.begin(
		level, Fixtures.create_properties(), Keen2Inventory.new(), _start()
	)
	assert_equal(session.actors.size(), KEEN_2_ENEMY_INFOS, "1-7 only (7 is the spark, B5)")


func test_shots_use_keen_2_sprites() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW] = "..........#..................."
	var session := _session(rows)
	session.inventory.charges = 1
	_run(session, KeenInput.create(0, false, false, true), 1)
	assert_equal(session.actors.size(), 1, "one shot")
	var shot := session.actors[0] as Keen2Shot
	assert_true(shot != null, "a Keen 2 shot")
	if shot == null:
		return
	assert_equal(shot.sprite_index(), Keen2Shot.KEEN_SHOT_SPRITE, "sprite 122")
	_run(session, KeenInput.create(0), WALK_TICKS / 4)
	assert_true(shot.is_splashing, "hit the wall")
	assert_true(
		shot.sprite_index() in [Keen2Shot.ZAP_SPRITE, Keen2Shot.ZOT_SPRITE], "splash 124 or 125"
	)


func test_icons_are_found_by_behaviour() -> void:
	var properties := Fixtures.create_properties()
	assert_equal(Keen2Icons.raygun(properties), Fixtures.RAYGUN, "the raygun tile")
	assert_equal(
		Keen2Icons.keycards(properties),
		PackedInt32Array(
			[Fixtures.YELLOW_CARD, Fixtures.RED_CARD, Fixtures.GREEN_CARD, Fixtures.BLUE_CARD]
		),
		"the keycard tiles"
	)
	assert_equal(
		Keen2Icons.first_tile_with(properties, TileProperties.Behavior.POGO), -1, "no pogo tile"
	)


func test_requested_level() -> void:
	assert_equal(Keen2LevelPlay.requested_level(["--game=2", "--level=7"]), 7, "level 7")
	assert_equal(Keen2LevelPlay.requested_level(["--game=2"]), 0, "none")
	assert_equal(Keen2LevelPlay.requested_level(["--level=x"]), 0, "not a number")
	assert_true(Keen2LevelPlay.is_playable(1) and Keen2LevelPlay.is_playable(16), "1 to 16")
	for number in [0, 17, 80, 81, 90]:
		assert_true(not Keen2LevelPlay.is_playable(number), "%d is not played in B3" % number)


func test_keen_2_scene_is_the_game_screen() -> void:
	var state := (load(GameLaunch.KEEN_2_SCENE) as PackedScene).get_state()
	var script: Script = null
	for index in state.get_node_property_count(0):
		if state.get_node_property_name(0, index) == &"script":
			script = state.get_node_property_value(0, index)
	assert_true(script != null and script.get_global_name() == &"Keen2View", "Keen2View")
	var base := script.get_base_script() if script != null else null
	while base != null and base.get_global_name() != &"GameScreen":
		base = base.get_base_script()
	assert_true(base != null, "on GameScreen")


## A session with [param items] in Keen's row, Keen standing at
## [constant START_CELL].
func _session_with_items(items: String) -> Keen2LevelSession:
	var rows := FIELD.duplicate()
	rows[FEET_ROW] = items + rows[FEET_ROW].substr(items.length())
	return _session(rows)


## A session with Keen standing on the floor.
func _session(rows: PackedStringArray) -> Keen2LevelSession:
	var session := _begin(rows)
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	return session


## A session that has not run a tick yet.
func _begin(rows: PackedStringArray) -> Keen2LevelSession:
	return Keen2LevelSession.begin(
		Fixtures.create_level(rows), Fixtures.create_properties(), Keen2Inventory.new(), _start()
	)


func _run(session: LevelSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


func _start() -> Vector2:
	return Vector2((START_CELL + _border()) * EgaGraphics.TILE_SIZE)


func _border() -> Vector2i:
	return Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)


func _column_left(column: int) -> float:
	return (column + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
