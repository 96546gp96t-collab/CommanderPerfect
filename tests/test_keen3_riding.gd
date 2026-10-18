extends "res://tests/test_case.gd"
## Tests for Keen 3's platforms ([Keen3Platform]) and for riding them
## ([Keen3Carrier], Keen 2's riding collision) in small hand-made levels,
## without Keen 3's files: the sideways platform waits at a wall, the
## up-and-down platform turns at once at a floor and waits at a ceiling,
## both always move and stop shots; Keen rides both, cannot walk out while
## riding, is never squeezed into a tile, is passed by a platform when the
## floor holds him and bumps his head from below. The
## ball, the jack and the guns are in tests/test_keen3_objects.gd.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const SUB := KeenPhysics.SUBPIXEL
const TILE := EgaGraphics.TILE_SIZE
const LONG_TICKS := 1200
const PLATFORM_SPEED := 22.8 * SUB
const KEEN_CELL := Vector2i(2, 12)
const ROWS := 15
const COLUMNS := 32
## Exit tiles in rows 6 and 7 of column 16, where a Keen riding a sideways
## platform of row 8 passes.
const EXIT_COLUMN := 16
const EXIT_ROWS: Array[int] = [6, 7]


func test_platforms_spawn_from_info_9_and_10() -> void:
	var session := _session_with({Vector2i(8, 8): 9, Vector2i(20, 8): 10})
	var sideways := session.enemies()[0] as Keen3Platform
	var up_down := session.enemies()[1] as Keen3Platform
	assert_true(sideways != null and up_down != null, "two platforms")
	assert_equal(sideways.position, Fixtures.cell_top_left(Vector2i(8, 8)) - Vector2(0, 4), "4 up")
	assert_equal(up_down.position, Fixtures.cell_top_left(Vector2i(20, 8)), "in its cell")
	assert_equal(sideways.velocity, Vector2(PLATFORM_SPEED, 0.0), "sets off right at 75")
	assert_equal(up_down.velocity, Vector2(0.0, PLATFORM_SPEED), "sets off down at 75")
	assert_equal(sideways.hitbox().size, Vector2(32, 8), "32x8")
	var frames := {}
	for tick in 30:
		frames[sideways.sprite_index()] = true
		_step(session)
	assert_equal(frames.keys(), [107, 108], "107 and 108")


func test_sideways_platform_waits_31_ticks_at_a_wall_then_goes_back() -> void:
	var session := _session_with({Vector2i(26, 8): 9})
	var platform := session.enemies()[0] as Keen3Platform
	var moves := _moves_x(session, platform, 300)
	var still := moves.count(0.0)
	assert_equal(still, Keen3Platform.WAIT_TICKS, "stands still 31 ticks")
	var first_still := moves.find(0.0)
	assert_true(is_equal_approx(moves[first_still + still], -PLATFORM_SPEED), "then goes back")
	assert_true(platform.hitbox().end.x <= _cell_left(31) + 0.001, "never in the wall")


func test_up_down_platform_turns_at_once_at_the_floor() -> void:
	var session := _session_with({Vector2i(10, 10): 10})
	var platform := session.enemies()[0] as Keen3Platform
	var turned_at := -1
	for tick in 300:
		var before := platform.position.y
		_step(session)
		var moved := platform.position.y - before
		if turned_at < 0 and moved < 0.0:
			turned_at = tick
		assert_true(turned_at >= 0 or moved > 0.0, "moving down until the floor: tick %d" % tick)
		if turned_at >= 0:
			break
	assert_true(turned_at > 0, "turned up")
	assert_true(not platform.is_waiting(), "without waiting")
	assert_true(platform.hitbox().end.y <= _cell_top(14) + 0.001, "never in the floor")


func test_up_down_platform_waits_31_ticks_at_the_ceiling() -> void:
	var session := _session_with({Vector2i(10, 3): 10})
	var platform := session.enemies()[0] as Keen3Platform
	platform.velocity = Vector2(0.0, -PLATFORM_SPEED)
	var moves := _moves_y(session, platform, 200)
	var still := moves.count(0.0)
	assert_equal(still, Keen3Platform.WAIT_TICKS, "stands still 31 ticks")
	var first_still := moves.find(0.0)
	assert_true(is_equal_approx(moves[first_still + still], PLATFORM_SPEED), "then goes down")
	assert_true(platform.top() >= _cell_top(1) - 0.001, "never in the ceiling")


func test_platforms_always_move_and_stop_shots() -> void:
	var session := _session_with({Vector2i(8, 8): 9})
	session.view_rects = [Rect2(Vector2(10000, 10000), LevelSession.DEFAULT_VIEW_SIZE)]
	var platform := session.enemies()[0] as Keen3Platform
	var start := platform.position.x
	_step(session)
	assert_true(platform.position.x > start, "moves far out of sight")
	var near := _session_with({Vector2i(5, 12): 9})
	var target := near.enemies()[0] as Keen3Platform
	target.velocity = Vector2.ZERO
	target.position.y = near.keen.hitbox().position.y + 4
	_step(near, KeenInput.create(0, false, false, true))
	var splashed := false
	for tick in 20:
		_step(near)
		for actor in near.actors:
			splashed = splashed or (actor is Keen3Shot and actor.is_splashing)
	assert_true(splashed, "Keen's shot splashes on it")
	assert_true(not target.is_dead and not target.removed, "never breaks")


func test_keen_rides_a_sideways_platform() -> void:
	var session := _session_with({Vector2i(10, 8): 9}, Vector2i(10, 4))
	var platform := session.enemies()[0] as Keen3Platform
	_put_on(session, platform)
	assert_true(session.is_riding(session.keen), "stands on it")
	assert_equal(session.keen.hitbox().end.y, platform.top(), "his feet on its top")
	var offset := session.keen.position.x - platform.position.x
	for tick in 100:
		_step(session)
	assert_true(is_equal_approx(session.keen.position.x - platform.position.x, offset), "along")
	assert_true(session.is_riding(session.keen) and not session.keen.is_dead, "still riding")


func test_keen_rides_an_up_down_platform_both_ways() -> void:
	var session := _session_with({Vector2i(10, 6): 10}, Vector2i(10, 2))
	var platform := session.enemies()[0] as Keen3Platform
	_put_on(session, platform)
	var lowest := platform.position.y
	for tick in 600:
		_step(session)
		lowest = maxf(lowest, platform.position.y)
		assert_true(session.is_riding(session.keen), "rides all the way: tick %d" % tick)
		if platform.velocity.y < 0.0 and platform.position.y < lowest - 2 * TILE:
			break
	assert_true(is_equal_approx(lowest + platform.hitbox().size.y, _cell_top(14)), "to the floor")
	assert_equal(session.keen.hitbox().end.y, platform.top(), "and up again on it")


func test_a_platform_carrying_keen_into_the_ceiling_stops_there() -> void:
	var session := _session_with({Vector2i(10, 6): 10}, Vector2i(10, 2))
	var platform := session.enemies()[0] as Keen3Platform
	_put_on(session, platform)
	platform.velocity = Vector2(0.0, -PLATFORM_SPEED)
	_run_until(session, func() -> bool: return platform.is_waiting())
	var keen := session.keen
	assert_true(platform.is_waiting(), "waits as at the ceiling")
	assert_true(is_equal_approx(keen.hitbox().position.y, _cell_top(1)), "Keen's head at it")
	assert_true(absf(keen.hitbox().end.y - platform.top()) < 0.001, "still on the platform")
	assert_true(not keen.is_dead, "not squeezed to death")
	_run_until(session, func() -> bool: return platform.velocity.y > 0.0)
	assert_true(platform.velocity.y > 0.0, "then goes down")


func test_a_platform_coming_down_on_keen_pushes_him_aside_or_passes_him() -> void:
	var session := _session_with({Vector2i(2, 7): 10})
	var platform := session.enemies()[0] as Keen3Platform
	var keen := session.keen
	var feet := keen.hitbox().end.y
	_run_until(session, func() -> bool: return platform.velocity.y < 0.0)
	assert_true(platform.velocity.y < 0.0, "turned up")
	assert_true(is_equal_approx(platform.hitbox().end.y, _cell_top(14)), "at the floor")
	assert_equal(keen.hitbox().end.y, feet, "Keen stayed on the floor")
	assert_true(not keen.is_dead, "harmless")
	assert_true(not platform.hitbox().intersects(keen.hitbox()), "pushed out of its way")
	var held := _session_with({Vector2i(1, 7): 10}, Vector2i(1, 12))
	var held_platform := held.enemies()[0] as Keen3Platform
	held.keen.position.x -= KeenPhysics.HITBOX.position.x
	var held_x := held.keen.position.x
	_run_until(held, func() -> bool: return held_platform.velocity.y < 0.0)
	assert_true(is_equal_approx(held_platform.hitbox().end.y, _cell_top(14)), "past him")
	assert_equal(held.keen.position.x, held_x, "a Keen held by the wall stays")
	assert_true(not held.keen.is_dead, "unharmed")


func test_keen_bumps_his_head_on_a_platform_from_below() -> void:
	var session := _session_with({Vector2i(2, 9): 9})
	var platform := session.enemies()[0] as Keen3Platform
	platform.velocity = Vector2.ZERO
	var keen := session.keen
	var highest := keen.hitbox().position.y
	_step(session, KeenInput.create(0, true))
	for tick in 60:
		_step(session, KeenInput.create(0, true))
		highest = minf(highest, keen.hitbox().position.y)
	assert_true(highest < keen.hitbox().position.y, "jumped")
	assert_true(highest >= platform.hitbox().end.y - 0.001, "not through the platform")


func test_no_exit_while_riding() -> void:
	var rows := _box()
	for row in EXIT_ROWS:
		rows[row] = rows[row].substr(0, EXIT_COLUMN) + "E" + rows[row].substr(EXIT_COLUMN + 1)
	var session := _session_with({Vector2i(10, 8): 9}, Vector2i(10, 4), rows)
	var platform := session.enemies()[0] as Keen3Platform
	_put_on(session, platform)
	var touched_exit := false
	for tick in LONG_TICKS:
		_step(session)
		assert_true(session.keen.state != KeenBody.State.EXITING, "no exit while riding")
		for cell in LevelCollision.cells_under(session.keen.hitbox()):
			touched_exit = touched_exit or cell.x == EXIT_COLUMN + LevelData.BORDER_CELLS
	assert_true(touched_exit, "rode past the exit")
	assert_true(session.is_riding(session.keen), "still riding")


## A session in [param rows] (a plain box when empty) with the platforms
## of [param infos] and Keen at [param keen_cell]; the view is the whole
## level.
func _session_with(
	infos: Dictionary, keen_cell := KEEN_CELL, rows := PackedStringArray()
) -> Keen3LevelSession:
	var typed: Dictionary[Vector2i, int] = {}
	for cell in infos:
		typed[cell] = infos[cell]
	var level := Fixtures.create_level(rows if not rows.is_empty() else _box(), typed)
	var session := Keen3LevelSession.started(
		level, Fixtures.level_properties(), Keen3Inventory.new(), Fixtures.cell_top_left(keen_cell)
	)
	var whole: Array[Rect2] = [Rect2(Vector2.ZERO, Vector2(level.width, level.height) * TILE)]
	session.view_rects = whole
	return session


## A box with a ceiling (row 0), a floor (the last row) and walls.
static func _box() -> PackedStringArray:
	var rows := PackedStringArray()
	for row in ROWS:
		var solid := row == 0 or row == ROWS - 1
		rows.append("#".repeat(COLUMNS) if solid else "#" + ".".repeat(COLUMNS - 2) + "#")
	return rows


## Puts Keen just above [param platform] and lets him land on it.
func _put_on(session: Keen3LevelSession, platform: Keen3Platform) -> void:
	var keen := session.keen
	keen.position = Vector2(platform.position.x + 8, platform.top() - KeenPhysics.SPRITE_SIZE.y - 1)
	keen.velocity = Vector2.ZERO
	_run_until(session, func() -> bool: return session.is_riding(keen))


## How far [param platform] moves sideways in each of [param ticks] ticks.
func _moves_x(session: Keen3LevelSession, platform: Keen3Platform, ticks: int) -> Array[float]:
	var moves: Array[float] = []
	for tick in ticks:
		var before := platform.position.x
		_step(session)
		moves.append(platform.position.x - before)
	return moves


## How far [param platform] moves down in each of [param ticks] ticks.
func _moves_y(session: Keen3LevelSession, platform: Keen3Platform, ticks: int) -> Array[float]:
	var moves: Array[float] = []
	for tick in ticks:
		var before := platform.position.y
		_step(session)
		moves.append(platform.position.y - before)
	return moves


func _cell_left(column: int) -> float:
	return Fixtures.cell_top_left(Vector2i(column, 0)).x


func _cell_top(row: int) -> float:
	return Fixtures.cell_top_left(Vector2i(0, row)).y


func _step(session: Keen3LevelSession, input: KeenInput = null) -> void:
	session.step(input if input != null else KeenInput.new())


## Steps until [param done] says so, at most [constant LONG_TICKS] ticks.
func _run_until(session: Keen3LevelSession, done: Callable) -> void:
	for tick in LONG_TICKS:
		if done.call():
			return
		_step(session)
