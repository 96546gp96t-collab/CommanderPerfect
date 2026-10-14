extends "res://tests/test_case.gd"
## Tests for two players on one keyboard: two Keens in one level, the keys
## of each player and how they are combined on the world map. In small
## hand-made levels (no game data needed). The split screen has its own
## tests in test_split_screen.gd.

const Fixtures := preload("res://tests/fixtures.gd")
const SETTLE_TICKS := 120
const WALK_TICKS := 120

## Player 1 starts on the left, standing on the floor in row 14.
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
## Player 2 starts here in most tests, so that the two can be told apart.
const SECOND_CELL := Vector2i(10, 12)
const FEET_ROW := 13
const STAND := 0
const RIGHT := 1
const LEFT := -1


func run_all() -> void:
	super.run_all()
	KeyBindings.reset()


func test_second_keen_joins_where_player_1_is() -> void:
	var session := _session(FIELD)
	session.keen.facing = -1
	var second := session.add_player(session.keen.position)
	assert_equal(session.keens.size(), 2, "two Keens")
	assert_equal(session.keens[0], session.keen, "player 1 first")
	assert_equal(second.position, session.keen.position, "at player 1")
	assert_equal(second.facing, -1, "looking the same way")


func test_each_player_steers_his_own_keen() -> void:
	var session := _two_player_session(FIELD)
	var first_x := session.keens[0].position.x
	var second_x := session.keens[1].position.x
	_run_players(session, KeenInput.create(RIGHT), KeenInput.create(LEFT), 30)
	assert_true(session.keens[0].position.x > first_x, "player 1 walked right")
	assert_true(session.keens[1].position.x < second_x, "player 2 walked left")


func test_without_input_player_2_stands_still() -> void:
	var session := _two_player_session(FIELD)
	var second_x := session.keens[1].position.x
	_run(session, KeenInput.create(RIGHT), 30)
	assert_equal(session.keens[1].position.x, second_x, "stands")


func test_either_keen_picks_up_items_for_both() -> void:
	var session := _two_player_session(_with_items("............o.g"))
	_run_players(session, KeenInput.create(STAND), KeenInput.create(RIGHT), WALK_TICKS)
	assert_equal(session.inventory.score, 100, "lollipop for the team")
	assert_equal(session.inventory.charges, Inventory.RAYGUN_CHARGES, "raygun for the team")


func test_either_keen_fires_with_the_shared_charges() -> void:
	var session := _two_player_session(FIELD)
	session.inventory.charges = 2
	var fire := KeenInput.create(STAND, false, false, true)
	_run_players(session, fire, fire, 1)
	assert_equal(session.inventory.charges, 0, "both fired")
	assert_equal(session.actors.size(), 2, "two shots")


func test_one_keen_dying_ends_the_attempt() -> void:
	var session := _two_player_session(_with_items("............X"))
	var lives := session.inventory.lives
	_run_players(session, KeenInput.create(STAND), KeenInput.create(RIGHT), WALK_TICKS * 2)
	assert_true(not session.keens[0].is_dead, "player 1 is fine")
	assert_equal(session.outcome, LevelSession.Outcome.DIED, "back to the map")
	assert_equal(session.inventory.lives, lives - 1, "one life less")


func test_one_keen_through_the_exit_completes_the_level() -> void:
	var session := _two_player_session(_with_items("............E"))
	_run_players(session, KeenInput.create(STAND), KeenInput.create(RIGHT), 60)
	assert_equal(session.keens[1].state, KeenBody.State.EXITING, "player 2 walks out")
	session.keens[0].kill()
	_run(session, KeenInput.create(STAND), KeenPhysics.EXIT_TICKS)
	assert_equal(session.outcome, LevelSession.Outcome.COMPLETED, "completed for both")
	assert_equal(session.inventory.lives, Inventory.START_LIVES, "no life lost")


func test_no_way_out_while_the_other_keen_is_dying() -> void:
	var session := _two_player_session(_with_items("............E"))
	session.keens[0].kill()
	_run_players(session, KeenInput.create(STAND), KeenInput.create(RIGHT), 60)
	assert_true(session.keens[1].state != KeenBody.State.EXITING, "the exit stays shut")


func test_enemies_go_after_the_nearest_living_keen() -> void:
	var session := _two_player_session(FIELD)
	var near_second := session.keens[1].hitbox().get_center() + Vector2(20, 0)
	assert_equal(session.nearest_keen(near_second), session.keens[1], "player 2 is nearer")
	session.keens[1].kill()
	assert_equal(session.nearest_keen(near_second), session.keens[0], "not a dead one")


func test_enemy_kills_the_second_keen() -> void:
	var session := _two_player_session(FIELD)
	var garg := Garg.create(session.keens[1].position)
	garg.is_active = true
	session.add_actor(garg)
	_run(session, KeenInput.create(STAND), 1)
	assert_true(session.keens[1].is_dead, "player 2 killed")
	assert_true(not session.keens[0].is_dead, "player 1 alive")


func test_enemy_shot_hits_the_second_keen() -> void:
	var session := _two_player_session(FIELD)
	var second := session.keens[1].hitbox()
	var shot := RaygunShot.create(Vector2(second.end.x + 2, second.position.y + 8), -1, false)
	session.add_actor(shot)
	_run(session, KeenInput.create(STAND), 5)
	assert_true(session.keens[1].is_dead, "player 2 shot")


func test_enemies_wake_up_in_either_half_of_the_screen() -> void:
	var session := _two_player_session(FIELD)
	var garg := Garg.create(Vector2(_column_left(25), _row_top(11)))
	session.add_actor(garg)
	var near := Rect2(Vector2(_column_left(0), _row_top(0)), Vector2(160, 200))
	session.view_rects = [near, near]
	_run(session, KeenInput.create(STAND), 1)
	assert_true(not garg.is_active, "out of both views")
	session.view_rects = [near, Rect2(Vector2(_column_left(20), _row_top(0)), Vector2(160, 200))]
	_run(session, KeenInput.create(STAND), 1)
	assert_true(garg.is_active, "in player 2's view")


func test_player_2_leaves() -> void:
	var session := _two_player_session(FIELD)
	session.remove_player(session.keen)
	assert_equal(session.keens.size(), 2, "player 1 cannot leave")
	session.remove_player(session.keens[1])
	assert_equal(session.keens, [session.keen] as Array[KeenBody], "player 1 alone")


func test_god_mode_goes_for_a_keen_that_joins() -> void:
	var session := _session(FIELD)
	session.set_invincible(true)
	var second := session.add_player(session.keen.position)
	assert_true(second.invincible, "invincible")
	session.set_invincible(false)
	assert_true(not second.invincible, "and back")


func test_map_input_combines_both_players() -> void:
	var walk_and_jump := KeenInput.combine(
		[KeenInput.create(RIGHT), KeenInput.create(STAND, true)] as Array[KeenInput]
	)
	assert_equal(walk_and_jump.direction, RIGHT, "walks")
	assert_true(walk_and_jump.jump, "jumps")
	var both_ways := KeenInput.combine(
		[KeenInput.create(RIGHT), KeenInput.create(LEFT)] as Array[KeenInput]
	)
	assert_equal(both_ways.direction, STAND, "left and right cancel out")
	var up := KeenInput.combine(
		[KeenInput.toward(Vector2i.UP), KeenInput.new()] as Array[KeenInput]
	)
	assert_equal(up.vertical, -1, "up")


func test_default_keys_for_two_players() -> void:
	KeyBindings.reset()
	var left_shift := KeyBindings.make_code(KEY_SHIFT, KEY_LOCATION_LEFT)
	var right_shift := KeyBindings.make_code(KEY_SHIFT, KEY_LOCATION_RIGHT)
	var expected := {
		"p1_left": [KEY_A],
		"p1_right": [KEY_D],
		"p1_jump": [left_shift],
		"p1_pogo": [KEY_QUOTELEFT],
		"p1_fire": [KEY_Z],
		"p2_left": [KEY_LEFT],
		"p2_right": [KEY_RIGHT],
		"p2_jump": [KEY_PERIOD],
		"p2_pogo": [KEY_SLASH],
		"p2_fire": [right_shift],
	}
	for action: String in expected:
		assert_equal(Array(KeyBindings.keys_of(action)), expected[action], action)
	assert_equal(Array(KeyBindings.keys_of("jump")), [KEY_CTRL, KEY_Z], "one player keeps his")


func test_left_and_right_shift_are_different_keys() -> void:
	KeyBindings.reset()
	var right := InputEventKey.new()
	right.physical_keycode = KEY_SHIFT
	right.location = KEY_LOCATION_RIGHT
	right.pressed = true
	assert_true(right.is_action("p2_fire"), "player 2 fires")
	assert_true(not right.is_action("p1_jump"), "player 1 does not jump")
	assert_equal(KeyBindings.key_name(KeyBindings.code_of(right)), "RIGHT SHIFT", "name")
	assert_equal(KeyBindings.key_name(KEY_QUOTELEFT), "`", "a sign")
	assert_equal(KeyBindings.key_name(KEY_PERIOD), ".", "another")


func test_keys_of_two_players_are_apart_from_one_player() -> void:
	KeyBindings.reset()
	KeyBindings.bind("p2_jump", KEY_Z)
	assert_equal(KeyBindings.keys_of("p2_jump")[0], KEY_Z, "player 2 jumps with Z")
	assert_true(not KeyBindings.keys_of("p1_fire").has(KEY_Z), "taken from player 1")
	assert_true(KeyBindings.keys_of("jump").has(KEY_Z), "one player keeps it")
	KeyBindings.bind("status", KEY_PERIOD)
	assert_true(not KeyBindings.keys_of("p2_jump").has(KEY_PERIOD), "status is in both")
	KeyBindings.reset()


func test_side_of_a_key_survives_the_settings() -> void:
	KeyBindings.reset()
	var path := "user://test_two_players_settings.cfg"
	var settings := UserSettings.load_from(path)
	var left_shift := KeyBindings.make_code(KEY_SHIFT, KEY_LOCATION_LEFT)
	KeyBindings.bind("p2_fire", left_shift)
	assert_true(settings.save(), "saved")
	KeyBindings.reset()
	UserSettings.load_from(path)
	assert_equal(KeyBindings.keys_of("p2_fire")[0], left_shift, "left shift")
	assert_true(KeyBindings.keys_of("p1_jump").is_empty(), "taken from player 1")
	KeyBindings.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## A session with player 1 at [constant START_CELL] and player 2 at
## [constant SECOND_CELL], both on the floor.
func _two_player_session(rows: PackedStringArray) -> LevelSession:
	var session := _session(rows)
	session.add_player(Vector2((SECOND_CELL + _border()) * EgaGraphics.TILE_SIZE))
	_run(session, KeenInput.create(STAND), SETTLE_TICKS)
	return session


func _session(rows: PackedStringArray) -> LevelSession:
	var session := (
		LevelSession
		. create(
			Fixtures.create_level(rows),
			Fixtures.create_properties(),
			Inventory.new(),
			Vector2((START_CELL + _border()) * EgaGraphics.TILE_SIZE),
		)
	)
	_run(session, KeenInput.create(STAND), SETTLE_TICKS)
	return session


## [constant FIELD] with [param items] in the row of the Keens' feet.
func _with_items(items: String) -> PackedStringArray:
	var rows := FIELD.duplicate()
	rows[FEET_ROW] = items + rows[FEET_ROW].substr(items.length())
	return rows


func _run(session: LevelSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


func _run_players(session: LevelSession, first: KeenInput, second: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step_players([first, second])


func _border() -> Vector2i:
	return Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)


func _row_top(row: int) -> float:
	return (row + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE


func _column_left(column: int) -> float:
	return (column + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
