extends "res://tests/test_case.gd"
## Tests for playing a level: items, doors, the exit, the raygun, dying and
## the inventory, in small hand-made levels (no game data needed). See
## tests/fixtures.gd for the level characters.

const Fixtures := preload("res://tests/fixtures.gd")
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


func test_items_are_picked_up() -> void:
	var session := _session_with_items("......o.p.g.J.......")
	var changed: Array[Vector2i] = []
	session.tile_changed.connect(func(cell: Vector2i, _tile: int) -> void: changed.append(cell))
	_run(session, KeenInput.create(1), WALK_TICKS)
	var inventory := session.inventory
	assert_equal(inventory.score, 100 + Inventory.SHIP_PART_POINTS, "lollipop and ship part points")
	assert_true(inventory.has_pogo, "pogo stick")
	assert_equal(inventory.charges, Inventory.RAYGUN_CHARGES, "raygun charges")
	assert_true(inventory.ship_parts[Inventory.ShipPart.JOYSTICK], "joystick")
	assert_equal(changed.size(), 4, "four tiles changed")
	assert_equal(
		session.level.tile_at(changed[0]), LevelSession.BACKGROUND_TILE, "background left behind"
	)


func test_found_pogo_stick_can_be_used() -> void:
	var session := _session_with_items("...p................")
	_run(session, KeenInput.create(1), 30)
	assert_true(session.inventory.has_pogo, "picked up")
	_run(session, KeenInput.create(0, false, true), 2)
	assert_true(session.keen.on_pogo, "takes it out")


func test_door_needs_the_keycard() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW - 1] = "..........D..................."
	rows[FEET_ROW] = "..........D..................."
	var session := _session(rows)
	_run(session, KeenInput.create(1), WALK_TICKS)
	assert_equal(session.keen.hitbox().end.x, _column_left(10), "stopped at the closed door")
	assert_true(session.actors.is_empty(), "nothing happened")


func test_keycard_opens_the_door() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW - 1] = "..........D..................."
	rows[FEET_ROW] = "......k...D..................."
	var session := _session(rows)
	var door_top := Vector2i(10, FEET_ROW - 1) + _border()
	var opened := false
	for tick in WALK_TICKS:
		session.step(KeenInput.create(1))
		opened = (
			opened or session.actors.any(func(actor: Actor) -> bool: return actor is OpeningDoor)
		)
	assert_true(opened, "the door slid open")
	assert_equal(session.level.tile_at(door_top), LevelSession.BACKGROUND_TILE, "top tile gone")
	assert_equal(
		session.level.tile_at(door_top + Vector2i.DOWN), LevelSession.BACKGROUND_TILE, "bottom too"
	)
	assert_true(not session.inventory.has_keycard(TileProperties.KeyColor.RED), "keycard used")
	assert_true(session.keen.hitbox().position.x > _column_left(11), "walked through")


func test_opening_door_sinks_and_disappears() -> void:
	var door := OpeningDoor.create(Vector2i(3, 4), PackedInt32Array([Fixtures.DOOR, Fixtures.DOOR]))
	var height := door.visible_height
	var top := door.position.y
	for tick in OpeningDoor.TICKS_PER_PIXEL * 10:
		door.step(null)
	assert_equal(door.visible_height, height - 10, "shrinks")
	assert_equal(door.position.y, top + 10, "sinks")
	for tick in OpeningDoor.TICKS_PER_PIXEL * height:
		door.step(null)
	assert_true(door.removed, "gone")


func test_keen_walks_through_the_exit_door() -> void:
	var session := _session_with_items("......E.............")
	var keen := session.keen
	while keen.state != KeenBody.State.EXITING:
		session.step(KeenInput.create(1))
	var x := keen.position.x
	_run(session, KeenInput.create(-1, true, true, true), 30)
	assert_true(keen.position.x > x, "keeps walking right, whatever the buttons")
	assert_equal(session.outcome, LevelSession.Outcome.PLAYING, "not done yet")
	keen.kill()
	assert_true(not keen.is_dead, "nothing can kill him now")
	_run(session, KeenInput.create(0), KeenPhysics.EXIT_TICKS)
	assert_equal(keen.visible_width(), 0.0, "hidden behind the door")
	assert_equal(session.outcome, LevelSession.Outcome.COMPLETED, "completed")


func test_exit_needs_keen_on_the_ground() -> void:
	var session := _session_with_items("......E.............")
	session.inventory.has_pogo = true
	_run(session, KeenInput.create(0, false, true), 2)
	_run(session, KeenInput.create(1), 60)
	assert_true(session.keen.state != KeenBody.State.EXITING, "not on the pogo stick")


func test_statue_speaks_once() -> void:
	var session := _session_with_items("......Y.............")
	var count := [0]
	session.hint_touched.connect(func() -> void: count[0] += 1)
	_run(session, KeenInput.create(1), 60)
	_run(session, KeenInput.create(-1), 60)
	assert_equal(count[0], 1, "one message")
	var cell := Vector2i(6, FEET_ROW) + _border()
	assert_equal(session.level.tile_at(cell), LevelSession.SILENT_YORP_STATUE, "stopped glowing")


func test_item_cheat_gives_everything() -> void:
	var inventory := Inventory.new()
	inventory.give_everything()
	assert_true(inventory.has_pogo, "pogo stick")
	assert_equal(inventory.charges, Inventory.CHEAT_CHARGES, "charges")
	assert_true(not inventory.keycards.has(false), "all keycards")


func test_firing_without_charges_does_nothing() -> void:
	var session := _session(FIELD)
	_run(session, KeenInput.create(0, false, false, true), 1)
	assert_true(session.actors.is_empty(), "no shot")


func test_shot_flies_until_a_wall() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW] = "...................#.........."
	var session := _session(rows)
	session.inventory.charges = 2
	_run(session, KeenInput.create(0, false, false, true), 1)
	assert_equal(session.inventory.charges, 1, "one charge used")
	assert_equal(session.actors.size(), 1, "one shot")
	var shot := session.actors[0] as RaygunShot
	var start_x := shot.position.x
	_run(session, KeenInput.create(0), 3)
	assert_equal(shot.position.x, start_x + 3 * KeenPhysics.SHOT_SPEED, "flies right")
	_run(session, KeenInput.create(0), 120)
	assert_true(shot.removed, "hit the wall and is gone")
	assert_true(session.actors.is_empty(), "removed from the session")


func test_shot_splashes_at_the_wall() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW] = "........#....................."
	var session := _session(rows)
	var shot := RaygunShot.create(Vector2(_column_left(5), _row_top(FEET_ROW)), 1)
	while not shot.is_splashing:
		shot.step(session)
	assert_equal(shot.position.x + KeenPhysics.SHOT_SIZE.x, _column_left(8), "stopped at the wall")
	assert_true(
		(
			shot.sprite_index() == RaygunShot.SPRITE_ZAP
			or shot.sprite_index() == RaygunShot.SPRITE_ZOT
		),
		"splash sprite"
	)


func test_dying_costs_a_life_and_the_new_ship_part() -> void:
	var rows := FIELD.duplicate()
	rows[FEET_ROW] = ".....J......X................."
	var session := _session(rows)
	var lives := session.inventory.lives
	_run(session, KeenInput.create(1), WALK_TICKS * 2)
	assert_equal(session.outcome, LevelSession.Outcome.DIED, "died")
	assert_equal(session.inventory.lives, lives - 1, "one life less")
	assert_true(not session.inventory.ship_parts[Inventory.ShipPart.JOYSTICK], "part lost")
	assert_equal(session.inventory.score, Inventory.SHIP_PART_POINTS, "points kept")


func test_ship_parts_from_earlier_levels_are_kept() -> void:
	var inventory := Inventory.new()
	inventory.add_ship_part(Inventory.ShipPart.BATTERY)
	inventory.enter_level()
	inventory.lose_life()
	assert_true(inventory.ship_parts[Inventory.ShipPart.BATTERY], "kept")


func test_extra_life_every_20000_points() -> void:
	var inventory := Inventory.new()
	inventory.add_points(Inventory.EXTRA_LIFE_EVERY - 1)
	assert_equal(inventory.lives, Inventory.START_LIVES, "not yet")
	inventory.add_points(1)
	assert_equal(inventory.lives, Inventory.START_LIVES + 1, "first extra life")
	inventory.add_points(Inventory.EXTRA_LIFE_EVERY * 2)
	assert_equal(inventory.lives, Inventory.START_LIVES + 3, "two more at once")


func test_game_over_after_the_last_life() -> void:
	var inventory := Inventory.new()
	for life in Inventory.START_LIVES:
		inventory.lose_life()
	assert_true(not inventory.is_game_over(), "the last life is still there")
	inventory.lose_life()
	assert_true(inventory.is_game_over(), "game over")


func test_keycards_do_not_carry_over_to_the_next_level() -> void:
	var inventory := Inventory.new()
	inventory.keycards[TileProperties.KeyColor.BLUE] = true
	inventory.enter_level()
	assert_true(not inventory.has_keycard(TileProperties.KeyColor.BLUE), "gone")


## A session in [constant FIELD] with [param items] in the row of Keen's feet.
func _session_with_items(items: String) -> LevelSession:
	var rows := FIELD.duplicate()
	rows[FEET_ROW] = items + rows[FEET_ROW].substr(items.length())
	return _session(rows)


## A session with Keen standing at [constant START_CELL].
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
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	return session


func _run(session: LevelSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


func _border() -> Vector2i:
	return Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)


func _row_top(row: int) -> float:
	return (row + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE


func _column_left(column: int) -> float:
	return (column + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
