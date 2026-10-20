extends "res://tests/test_case.gd"
## Tests for jumping off Keen 3's lifts ([Keen3Platform], [Keen3Ball]) in a
## small hand-made level, without Keen 3's files: Keen jumps (a long and a
## short jump, and the pogo) from the left end, the middle and the right
## end of a sideways platform going either way, an up-and-down platform
## going either way and a ball going up. He leaves from the spot where he
## stands: in the air the lift never moves him sideways, and on it he only
## goes along with it. Walking into a lift's side still pushes him out.
## Riding itself is in tests/test_keen3_riding.gd.

enum Spot { LEFT_END, MIDDLE, RIGHT_END }
enum Jump { LONG, SHORT, POGO }

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const PLATFORM_SPEED := 22.8 * KeenPhysics.SUBPIXEL
const BALL_SPEED := 121 * KeenPhysics.SUBPIXEL
const ROWS := 15
const COLUMNS := 32
## Where the lifts start; far from every wall, floor and ceiling.
const LIFT_CELL := Vector2i(12, 10)
## Keen's start, out of the way on the floor at the left.
const KEEN_CELL := Vector2i(2, 12)
## Long enough for a full jump or pogo bounce and the landing after it.
const JUMP_TICKS := 90
## Ticks a short jump holds the button: one crouch frame.
const SHORT_HOLD_TICKS := 1
const SLACK := 0.001
## How far above a lift Keen is dropped onto it: not a whole pixel.
const DROP_HEIGHT := 13.37


func test_jumping_off_a_sideways_platform_keeps_keen_in_place() -> void:
	for speed in [PLATFORM_SPEED, -PLATFORM_SPEED]:
		for spot in Spot.values():
			for jump in Jump.values():
				var session := _session_with(Keen3LevelSession.INFO_SIDEWAYS_PLATFORM)
				var lift := session.enemies()[0] as Keen3Platform
				lift.velocity = Vector2(speed, 0.0)
				_check_jump(session, lift, spot, jump, "sideways %+.2f" % speed)


func test_jumping_off_a_sideways_platform_after_landing_on_it_keeps_keen_in_place() -> void:
	for speed in [PLATFORM_SPEED, -PLATFORM_SPEED]:
		for jump in Jump.values():
			var session := _session_with(Keen3LevelSession.INFO_SIDEWAYS_PLATFORM)
			var lift := session.enemies()[0] as Keen3Platform
			lift.velocity = Vector2(speed, 0.0)
			_land_on(session, lift)
			_check_jump(session, lift, Spot.MIDDLE, jump, "landed, sideways %+.2f" % speed, false)


func test_jumping_off_an_up_down_platform_keeps_keen_in_place() -> void:
	for speed in [PLATFORM_SPEED, -PLATFORM_SPEED]:
		for spot in Spot.values():
			for jump in Jump.values():
				var session := _session_with(Keen3LevelSession.INFO_UP_DOWN_PLATFORM)
				var lift := session.enemies()[0] as Keen3Platform
				lift.velocity = Vector2(0.0, speed)
				_check_jump(session, lift, spot, jump, "up-down %+.2f" % speed)


func test_jumping_off_a_rising_ball_keeps_keen_in_place() -> void:
	for side in [BALL_SPEED, -BALL_SPEED]:
		for spot in Spot.values():
			for jump in Jump.values():
				var session := _session_with(Keen3LevelSession.INFO_BALL)
				var ball := session.enemies()[0] as Keen3Ball
				ball.is_active = true
				ball.velocity = Vector2(side, -BALL_SPEED)
				_check_rise(session, ball, spot, jump, "ball %+.2f" % side)


func test_landing_back_on_an_up_down_platform_keeps_keen_in_place() -> void:
	var session := _session_with(Keen3LevelSession.INFO_UP_DOWN_PLATFORM)
	var lift := session.enemies()[0] as Keen3Platform
	lift.velocity = Vector2(0.0, -PLATFORM_SPEED)
	_stand_on(session, lift, Spot.MIDDLE)
	var start_x := session.keen.position.x
	var left := false
	for tick in JUMP_TICKS:
		session.step(KeenInput.create(0, not left))
		left = left or not session.is_riding(session.keen)
		if left and session.is_riding(session.keen):
			break
	assert_true(left, "jumped off")
	assert_true(session.is_riding(session.keen), "landed back on it")
	assert_equal(session.keen.position.x, start_x, "on the same spot")


func test_walking_into_a_lifts_side_still_pushes_keen_out() -> void:
	var session := _session_with(Keen3LevelSession.INFO_UP_DOWN_PLATFORM)
	var lift := session.enemies()[0] as Keen3Platform
	lift.velocity = Vector2.ZERO
	var keen := session.keen
	# On the floor, with the platform's side at the height of his chest.
	lift.position.y = keen.hitbox().position.y + 4
	keen.position.x = lift.position.x - KeenPhysics.SPRITE_SIZE.x - 4
	for tick in 60:
		session.step(KeenInput.create(1))
		assert_true(not lift.hitbox().intersects(keen.hitbox()), "never inside: tick %d" % tick)
	assert_true(keen.hitbox().end.x <= lift.position.x + SLACK, "stopped at its side")


## Keen stands at [param spot] on [param lift] and jumps ([param jump]); on
## every tick he moves sideways no more than the lift carries him, and not
## at all while he is in the air.
func _check_jump(
	session: Keen3LevelSession,
	lift: Keen3Carrier,
	spot: Spot,
	jump: Jump,
	what: String,
	place := true,
) -> void:
	if place:
		_stand_on(session, lift, spot)
	var keen := session.keen
	var label := "%s, %s, %s" % [what, Spot.keys()[spot], Jump.keys()[jump]]
	var was_airborne := false
	for tick in JUMP_TICKS:
		var before := keen.position.x
		var stood := _stands(keen)
		session.step(_input(jump, tick))
		var moved := absf(keen.position.x - before)
		var allowed := absf(lift.last_move.x) if stood or _stands(keen) else 0.0
		if moved > allowed + SLACK:
			_fail("%s: moved %.2f sideways at tick %d" % [label, moved, tick])
			return
		was_airborne = was_airborne or not _stands(keen)
		if was_airborne and _stands(keen) and jump != Jump.POGO:
			return
	assert_true(was_airborne, "%s: jumped" % label)


## As [method _check_jump], but only while Keen rises: a ball that bounces
## about may well come at his side later.
func _check_rise(
	session: Keen3LevelSession, ball: Keen3Carrier, spot: Spot, jump: Jump, what: String
) -> void:
	_stand_on(session, ball, spot)
	var keen := session.keen
	var label := "%s, %s, %s" % [what, Spot.keys()[spot], Jump.keys()[jump]]
	var start_x := keen.position.x
	var rose := false
	for tick in JUMP_TICKS:
		var stood := _stands(keen)
		var before := keen.position.x
		session.step(_input(jump, tick))
		if stood:
			start_x = keen.position.x
			assert_true(
				absf(keen.position.x - before) <= absf(ball.last_move.x) + SLACK,
				"%s: carried along only, tick %d" % [label, tick]
			)
			continue
		if keen.state != KeenBody.State.RISING:
			break
		rose = true
		if absf(keen.position.x - start_x) > SLACK:
			_fail("%s: moved %.2f sideways at tick %d" % [label, keen.position.x - start_x, tick])
			return
	assert_true(rose, "%s: rose" % label)


## Puts Keen on [param lift] at [param spot], standing, and lets one tick
## pass so that he rides it.
func _stand_on(session: Keen3LevelSession, lift: Keen3Carrier, spot: Spot) -> void:
	var keen := session.keen
	var surface := lift.hitbox()
	var hit_left := surface.position.x
	match spot:
		Spot.MIDDLE:
			hit_left = surface.get_center().x - KeenPhysics.HITBOX.size.x / 2.0
		Spot.RIGHT_END:
			hit_left = surface.end.x - KeenPhysics.HITBOX.size.x
	keen.position = Vector2(
		hit_left - KeenPhysics.HITBOX.position.x, surface.position.y - KeenPhysics.SPRITE_SIZE.y
	)
	keen.velocity = Vector2.ZERO
	keen.state = KeenBody.State.STANDING
	session.step(KeenInput.new())
	assert_true(session.is_riding(keen), "rides at %s" % Spot.keys()[spot])


## Drops Keen onto the middle of [param lift] from a little above it (an
## odd height, as after a jump in the game) and lets him land.
func _land_on(session: Keen3LevelSession, lift: Keen3Carrier) -> void:
	var keen := session.keen
	var surface := lift.hitbox()
	keen.position = Vector2(
		surface.get_center().x - KeenPhysics.SPRITE_SIZE.x / 2.0,
		surface.position.y - KeenPhysics.SPRITE_SIZE.y - DROP_HEIGHT
	)
	keen.velocity = Vector2.ZERO
	keen.state = KeenBody.State.FALLING
	for tick in JUMP_TICKS:
		session.step(KeenInput.new())
		if session.is_riding(keen):
			return
	_fail("never landed on it")


## The buttons on tick [param tick] of [param jump]: a long jump holds the
## jump button, a short one taps it, the pogo is pressed once.
static func _input(jump: Jump, tick: int) -> KeenInput:
	match jump:
		Jump.LONG:
			return KeenInput.create(0, true)
		Jump.SHORT:
			return KeenInput.create(0, tick < SHORT_HOLD_TICKS)
	return KeenInput.create(0, false, tick == 0)


static func _stands(keen: KeenBody) -> bool:
	return keen.state in Keen2LevelSession.STANDING_STATES


## A plain box with one lift (info [param info]) at [constant LIFT_CELL];
## the view is the whole level.
func _session_with(info: int) -> Keen3LevelSession:
	var rows := PackedStringArray()
	for row in ROWS:
		var solid := row == 0 or row == ROWS - 1
		rows.append("#".repeat(COLUMNS) if solid else "#" + ".".repeat(COLUMNS - 2) + "#")
	var infos: Dictionary[Vector2i, int] = {LIFT_CELL: info}
	var level := Fixtures.create_level(rows, infos)
	var session := Keen3LevelSession.started(
		level, Fixtures.level_properties(), Keen3Inventory.new(), Fixtures.cell_top_left(KEEN_CELL)
	)
	var whole: Array[Rect2] = [
		Rect2(Vector2.ZERO, Vector2(level.width, level.height) * EgaGraphics.TILE_SIZE)
	]
	session.view_rects = whole
	return session
