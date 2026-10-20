extends "res://tests/test_case.gd"
## Tests for Keen 3's raygun shot fired close to a wall ([Keen3Shot]), in a
## small hand-made level without Keen 3's files. Keen stands (or jumps, or
## pogoes) with his front 0 to 16 px from a wall, faces it and fires: the
## shot splashes at the wall's near side with SHOTHIT and never shows inside
## the wall or behind it (Choco: a shot that starts against a wall splashes
## at once). Both a thin wall with open space behind it and a thick wall,
## both directions.

enum Move { STANDING, JUMPING, POGO }

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const TILE := EgaGraphics.TILE_SIZE
const ROWS := 20
const COLUMNS := 30
## The wall: one column (thin) or three (thick), from the ceiling to the
## floor, in the middle of the level.
const WALL_COLUMN := 14
const THICK_WALL_WIDTH := 3
## Keen's start row (his sprite's top); he falls onto the floor.
const KEEN_ROW := ROWS - 4
const SETTLE_TICKS := 40
## Ticks after the jump or pogo button before he fires: a full crouch (or
## pogo wind-up), then a few ticks of rising.
const AIR_TICKS := 16
## Long enough for a shot to cross the whole level.
const FLY_TICKS := 120
## Keen's front this far from the wall, in pixels.
const DISTANCES: Array[float] = [0.0, 0.5, 1.0, 3.0, 4.0, 7.5, 8.0, 12.0, 15.0, 15.9, 16.0]
const SLACK := 0.001


func test_a_shot_fired_at_a_thin_wall_splashes_at_it() -> void:
	_check_all(1)


func test_a_shot_fired_at_a_thick_wall_splashes_at_it() -> void:
	_check_all(THICK_WALL_WIDTH)


func test_a_shot_with_room_before_the_wall_still_flies() -> void:
	var session := _session(1)
	_place_keen(session, 1, 2.0 * TILE)
	_settle(session)
	session.step(KeenInput.create(0, false, false, true))
	var shot := _keen_shot(session)
	assert_true(shot != null and not shot.is_splashing, "flying after the first tick")


func _check_all(wall_width: int) -> void:
	for facing in [1, -1]:
		for move in Move.values():
			for distance in DISTANCES:
				var what := (
					"wall %d, facing %+d, %s, %.1f px"
					% [wall_width, facing, Move.keys()[move], distance]
				)
				_check(wall_width, facing, move, distance, what)


## Keen faces the wall [param distance] px from it and fires while doing
## [param move]; the shot must splash at the wall's near side.
func _check(wall_width: int, facing: int, move: Move, distance: float, what: String) -> void:
	var session := _session(wall_width)
	_place_keen(session, facing, distance)
	_settle(session)
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	_take_off(session, move)
	if move != Move.STANDING:
		var state := session.keen.state
		var airborne := state == KeenBody.State.RISING or state == KeenBody.State.FALLING
		assert_true(airborne, "%s: in the air" % what)
	var near_side := _near_side(wall_width, facing)
	session.step(KeenInput.create(0, false, false, true))
	var shot := _keen_shot(session)
	assert_true(shot != null, "%s: a shot" % what)
	if shot == null:
		return
	for tick in FLY_TICKS:
		if not _in_front(shot.hitbox(), facing, near_side):
			_fail("%s: inside or behind the wall at tick %d (%s)" % [what, tick, shot.hitbox()])
			return
		if shot.removed:
			break
		session.step(KeenInput.create(0))
	assert_true(shot.is_splashing or shot.removed, "%s: splashed" % what)
	var gap := absf(_front(shot.hitbox(), facing) - near_side)
	assert_true(gap < SLACK, "%s: splashed at the wall (gap %.2f)" % [what, gap])
	assert_true(sounds.has(Sound.Id.SHOT_HIT), "%s: SHOTHIT" % what)


## A closed room with a wall [param wall_width] columns wide in the middle
## and room on both sides of it; every cell is in view.
func _session(wall_width: int) -> Keen3LevelSession:
	var rows := PackedStringArray()
	for row in ROWS:
		if row == 0 or row == ROWS - 1:
			rows.append("#".repeat(COLUMNS))
			continue
		var line := "#" + ".".repeat(COLUMNS - 2) + "#"
		line = (
			line.substr(0, WALL_COLUMN)
			+ "#".repeat(wall_width)
			+ line.substr(WALL_COLUMN + wall_width)
		)
		rows.append(line)
	var level := Fixtures.create_level(rows)
	var session := Keen3LevelSession.started(
		level,
		Fixtures.level_properties(),
		Keen3Inventory.new(),
		Fixtures.cell_top_left(Vector2i(2, KEEN_ROW))
	)
	var whole: Array[Rect2] = [Rect2(Vector2.ZERO, Vector2(level.width, level.height) * TILE)]
	session.view_rects = whole
	session.inventory.has_pogo = true
	return session


## Puts Keen [param distance] px before the wall, facing it ([param facing]
## 1: the wall is on his right).
func _place_keen(session: Keen3LevelSession, facing: int, distance: float) -> void:
	var keen := session.keen
	var wall_width := _wall_width(session)
	var near_side := _near_side(wall_width, facing)
	if facing > 0:
		keen.position.x = near_side - distance - KeenPhysics.HITBOX.end.x
	else:
		keen.position.x = near_side + distance - KeenPhysics.HITBOX.position.x
	keen.facing = facing


func _settle(session: Keen3LevelSession) -> void:
	for tick in SETTLE_TICKS:
		session.step(KeenInput.create(0))


## Jumps (holding the button) or pogoes straight up for
## [constant AIR_TICKS] ticks; nothing when standing.
func _take_off(session: Keen3LevelSession, move: Move) -> void:
	if move == Move.STANDING:
		return
	var jumping := move == Move.JUMPING
	for tick in AIR_TICKS:
		session.step(KeenInput.create(0, jumping, not jumping and tick == 0))


func _keen_shot(session: Keen3LevelSession) -> Keen3Shot:
	for actor in session.actors:
		if actor is Keen3Shot and (actor as Keen3Shot).from_keen:
			return actor
	return null


## The wall's side that faces Keen, in level pixels.
func _near_side(wall_width: int, facing: int) -> float:
	var border := LevelData.BORDER_CELLS
	if facing > 0:
		return (WALL_COLUMN + border) * TILE
	return (WALL_COLUMN + border + wall_width) * TILE


func _wall_width(session: Keen3LevelSession) -> int:
	var border := LevelData.BORDER_CELLS
	var width := 0
	while session.collision.is_solid(
		Vector2i(WALL_COLUMN + border + width, KEEN_ROW + border), LevelCollision.Edge.LEFT
	):
		width += 1
	return width


func _front(box: Rect2, facing: int) -> float:
	return box.end.x if facing > 0 else box.position.x


func _in_front(box: Rect2, facing: int, near_side: float) -> bool:
	if facing > 0:
		return box.end.x <= near_side + SLACK
	return box.position.x >= near_side - SLACK
