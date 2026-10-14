extends "res://tests/test_case.gd"
## Tests for Keen's movement and his collisions with tiles, in small
## hand-made levels (no game data needed). See tests/fixtures.gd for the
## level characters.

const Fixtures := preload("res://tests/fixtures.gd")
const SETTLE_TICKS := 120

## Fourteen rows of air above a floor, so that even the highest pogo bounce
## does not reach the top.
const OPEN_FIELD: PackedStringArray = [
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


func test_keen_lands_on_the_floor() -> void:
	var keen := _settled_keen(OPEN_FIELD)
	assert_equal(keen.state, KeenBody.State.STANDING, "state")
	assert_equal(keen.hitbox().end.y, _row_top(OPEN_FIELD.size() - 1), "feet on the floor")


func test_walking_reaches_full_speed() -> void:
	var keen := _settled_keen(OPEN_FIELD)
	var start_x := keen.position.x
	_run(keen, KeenInput.create(1), 60)
	assert_equal(keen.velocity.x, KeenPhysics.WALK_MAX_SPEED, "speed")
	assert_true(keen.position.x > start_x, "moved right")
	assert_equal(keen.facing, 1, "looks right")


func test_keen_stops_quickly_without_input() -> void:
	var keen := _settled_keen(OPEN_FIELD, Vector2i(25, 12))
	_run(keen, KeenInput.create(-1), 60)
	assert_equal(keen.velocity.x, -KeenPhysics.WALK_MAX_SPEED, "speed before letting go")
	_run(keen, KeenInput.create(0), ceili(KeenPhysics.WALK_MAX_SPEED / KeenPhysics.GROUND_FRICTION))
	assert_equal(keen.velocity.x, 0.0, "speed")
	assert_equal(keen.facing, -1, "still looks left")


func test_walls_stop_keen() -> void:
	var rows := OPEN_FIELD.duplicate()
	rows[13] = ".........#...................."
	var keen := _settled_keen(rows)
	_run(keen, KeenInput.create(1), 200)
	assert_equal(keen.hitbox().end.x, _column_left(9), "stopped at the wall")


func test_doors_are_solid() -> void:
	var rows := OPEN_FIELD.duplicate()
	rows[12] = ".........D...................."
	rows[13] = ".........D...................."
	var keen := _settled_keen(rows)
	_run(keen, KeenInput.create(1), 200)
	assert_equal(keen.hitbox().end.x, _column_left(9), "stopped at the door")


func test_full_jump_reaches_known_height() -> void:
	var keen := _settled_keen(OPEN_FIELD)
	var floor_y := keen.hitbox().end.y
	var height := _highest_jump(keen, KeenInput.create(0, true), 90)
	# Rising from JUMP_SPEED down to 0 in steps of JUMP_DECELERATION.
	var rising_ticks := roundi(KeenPhysics.JUMP_SPEED / KeenPhysics.JUMP_DECELERATION)
	var expected := (
		rising_ticks * KeenPhysics.JUMP_SPEED
		- KeenPhysics.JUMP_DECELERATION * rising_ticks * (rising_ticks - 1) / 2.0
	)
	assert_equal(height, expected, "jump height")
	_run(keen, KeenInput.create(0), SETTLE_TICKS)
	assert_equal(keen.hitbox().end.y, floor_y, "back on the floor")


func test_tapping_jump_gives_a_lower_jump() -> void:
	var keen := _settled_keen(OPEN_FIELD)
	_run(keen, KeenInput.create(0, true), 3)
	var height := _highest_jump(keen, KeenInput.create(0), 60)
	assert_true(height > 0.0, "still jumps")
	assert_true(height < 20.0, "short hop, got %.2f" % height)


func test_keen_bumps_his_head() -> void:
	var rows := OPEN_FIELD.duplicate()
	rows[10] = "##############################"
	var keen := _settled_keen(rows)
	var start_y := keen.hitbox().position.y
	var height := _highest_jump(keen, KeenInput.create(0, true), 60)
	assert_equal(start_y - height, _row_top(11), "stopped under the ceiling")
	_run(keen, KeenInput.create(0), SETTLE_TICKS)
	assert_equal(keen.state, KeenBody.State.STANDING, "lands again")


func test_keen_jumps_through_a_platform_from_below() -> void:
	var rows := OPEN_FIELD.duplicate()
	rows[11] = "--------......................"
	var keen := _settled_keen(rows)
	_run(keen, KeenInput.create(0, true), 12)
	_run(keen, KeenInput.create(0), SETTLE_TICKS)
	assert_equal(keen.hitbox().end.y, _row_top(11), "standing on the platform")


func test_pogo_bounces_higher_than_a_jump() -> void:
	var keen := _settled_keen(OPEN_FIELD)
	keen.step(KeenInput.create(0, false, true))
	assert_true(keen.on_pogo, "pogo stick taken out")
	var first_bounce := _bounce(keen, KeenInput.create(0, true))
	var high_bounce := _bounce(keen, KeenInput.create(0, true))
	var low_bounce := _bounce(keen, KeenInput.create(0))
	assert_true(first_bounce > high_bounce, "first bounce is the highest")
	assert_true(high_bounce > low_bounce, "holding jump bounces higher")
	assert_true(low_bounce > 50.0, "even a low bounce is a full jump")


func test_pogo_button_puts_the_stick_away() -> void:
	var keen := _settled_keen(OPEN_FIELD)
	keen.step(KeenInput.create(0, false, true))
	keen.step(KeenInput.create(0, false, true))
	assert_true(keen.on_pogo, "holding the button does not toggle again")
	keen.step(KeenInput.create(0))
	keen.step(KeenInput.create(0, false, true))
	assert_true(not keen.on_pogo, "second press puts it away")


func test_ice_keeps_keen_sliding() -> void:
	var rows := OPEN_FIELD.duplicate()
	rows[14] = "IIIIIIIIIIIIIIIIIIIIIIIIIIIIII"
	var keen := _settled_keen(rows)
	var start_x := keen.position.x
	_run(keen, KeenInput.create(0), 30)
	assert_equal(keen.velocity.x, KeenPhysics.WALK_MAX_SPEED, "sliding at full speed")
	assert_true(keen.position.x > start_x, "slid right")
	_run(keen, KeenInput.create(-1), 10)
	assert_equal(keen.velocity.x, KeenPhysics.WALK_MAX_SPEED, "cannot turn on ice")


func test_slippery_floor_keeps_speed() -> void:
	var rows := OPEN_FIELD.duplicate()
	rows[14] = "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS"
	var keen := _settled_keen(rows)
	_run(keen, KeenInput.create(1), 30)
	var speed := keen.velocity.x
	_run(keen, KeenInput.create(0), 10)
	assert_equal(keen.velocity.x, speed, "no friction")


func test_fire_kills_keen() -> void:
	var rows := OPEN_FIELD.duplicate()
	rows[13] = "........X....................."
	var keen := _settled_keen(rows)
	_run(keen, KeenInput.create(1), 100)
	assert_true(keen.is_dead, "dead")


func test_falling_out_of_the_level_kills_keen() -> void:
	var rows := OPEN_FIELD.duplicate()
	rows[14] = "......................########"
	var keen := _keen_at(rows, START_CELL)
	_run(keen, KeenInput.create(0), SETTLE_TICKS)
	assert_true(keen.is_dead, "dead")


func test_collision_stops_at_tile_edges() -> void:
	var collision := Fixtures.create_collision(["....", "..#.", "...."])
	var wall_left := _column_left(2)
	var box := Rect2(wall_left - 10.0, _row_top(1), 8, 8)
	assert_equal(collision.sweep_x(box, 5.0), 2.0, "stops at the wall")
	assert_equal(collision.sweep_x(box, -5.0), -5.0, "free to the left")
	var above := Rect2(wall_left, _row_top(1) - 12.0, 8, 8)
	assert_equal(collision.sweep_y(above, 10.0), 4.0, "lands on the wall")
	assert_equal(
		collision.floor_under(Rect2(wall_left, _row_top(1) - 8.0, 8, 8)),
		TileProperties.Floor.SOLID,
		"floor under a box on top"
	)


func test_outside_the_playable_area_is_a_wall() -> void:
	var collision := Fixtures.create_collision(["....", "...."])
	var box := Rect2(_column_left(0) + 1.0, _row_top(0) + 1.0, 8, 8)
	assert_equal(collision.sweep_x(box, -5.0), -1.0, "left edge")
	assert_equal(collision.sweep_y(box, -5.0), -1.0, "top edge")
	assert_equal(collision.sweep_y(box, 40.0), 40.0, "open at the bottom")


## Keen standing still on the floor below [param cell].
func _settled_keen(rows: PackedStringArray, cell := START_CELL) -> KeenBody:
	var keen := _keen_at(rows, cell)
	_run(keen, KeenInput.create(0), SETTLE_TICKS)
	return keen


func _keen_at(rows: PackedStringArray, cell: Vector2i) -> KeenBody:
	var border := Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)
	return KeenBody.create(
		Fixtures.create_collision(rows), Vector2((cell + border) * EgaGraphics.TILE_SIZE)
	)


func _run(keen: KeenBody, input: KeenInput, ticks: int) -> void:
	for i in ticks:
		keen.step(input)


## Runs [param ticks] ticks and returns how far Keen rose above where he was.
func _highest_jump(keen: KeenBody, input: KeenInput, ticks: int) -> float:
	var start_y := keen.hitbox().position.y
	var highest := start_y
	for i in ticks:
		keen.step(input)
		highest = minf(highest, keen.hitbox().position.y)
	return start_y - highest


## Waits until Keen is compressed on the pogo stick, then returns the height of
## the next bounce.
func _bounce(keen: KeenBody, input: KeenInput) -> float:
	var ticks_left := SETTLE_TICKS * 3
	while keen.state != KeenBody.State.POGO_COMPRESSED and ticks_left > 0:
		keen.step(input)
		ticks_left -= 1
	var ground_y := keen.hitbox().position.y
	var highest := ground_y
	while keen.state == KeenBody.State.POGO_COMPRESSED and ticks_left > 0:
		keen.step(input)
		ticks_left -= 1
	while keen.state != KeenBody.State.POGO_COMPRESSED and ticks_left > 0:
		keen.step(input)
		highest = minf(highest, keen.hitbox().position.y)
		ticks_left -= 1
	return ground_y - highest


## Pixel y of the top of row [param row] of a fixture level.
func _row_top(row: int) -> float:
	return (row + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE


func _column_left(column: int) -> float:
	return (column + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
