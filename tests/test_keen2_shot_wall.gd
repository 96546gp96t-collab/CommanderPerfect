extends "res://tests/test_case.gd"
## Tests for Keen 2's raygun shots fired close to a wall ([Keen2Shot],
## [Keen2EnemyShot]), in a small hand-made level without Keen 2's files.
## Keen stands (or jumps, or pogoes) with his front 0 to 16 px from a wall,
## faces it and fires: the shot splashes at the wall's near side with
## SHOTHIT and never shows inside the wall or behind it (the same rule as
## Keen 3's, tests/test_keen3_shot_wall.gd; decided by the user after C11).
## An Elite's and a Guard robot's shot do the same. Both a thin wall with
## open space behind it and a thick wall, both directions.

enum Move { STANDING, JUMPING, POGO }

const Fixtures := preload("res://tests/keen2_fixtures.gd")
const TILE := EgaGraphics.TILE_SIZE
const ROWS := 20
const COLUMNS := 30
## The wall: one column (thin) or three (thick), from the ceiling to the
## floor, in the middle of the level.
const WALL_COLUMN := 14
const THICK_WALL_WIDTH := 3
## Keen's start row (his sprite's top); he falls onto the floor.
const KEEN_ROW := ROWS - 4
## The floor row, under Keen and the enemies.
const FLOOR_ROW := ROWS - 1
const SETTLE_TICKS := 40
## Ticks after the jump or pogo button before he fires: a full crouch (or
## pogo wind-up), then a few ticks of rising.
const AIR_TICKS := 16
## Long enough for a shot to cross the whole level.
const FLY_TICKS := 120
## Keen's (or the enemy's) front this far from the wall, in pixels.
const DISTANCES: Array[float] = [0.0, 0.5, 1.0, 3.0, 4.0, 7.5, 8.0, 12.0, 15.0, 15.9, 16.0]
## An enemy's shot leaves a few pixels in front of it, so it reaches further.
const ENEMY_DISTANCES: Array[float] = [0.0, 1.0, 4.0, 8.0, 15.0, 16.0, 19.0]
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


func test_enemy_shots_fired_at_a_wall_splash_at_it() -> void:
	for wall_width in [1, THICK_WALL_WIDTH]:
		for facing in [1, -1]:
			for distance in ENEMY_DISTANCES:
				_check_enemy(Keen2Elite.create(Vector2.ZERO), wall_width, facing, distance)
				_check_enemy(Keen2GuardRobot.create(Vector2.ZERO), wall_width, facing, distance)


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
	var sounds := _sounds(session)
	_take_off(session, move)
	if move != Move.STANDING:
		var state := session.keen.state
		var airborne := state == KeenBody.State.RISING or state == KeenBody.State.FALLING
		assert_true(airborne, "%s: in the air" % what)
	session.step(KeenInput.create(0, false, false, true))
	var shot := _keen_shot(session)
	assert_true(shot != null, "%s: a shot" % what)
	if shot != null:
		_check_splash(session, shot, _near_side(wall_width, facing), sounds, what)


## [param enemy] faces the wall [param distance] px from it and fires; the
## shot must splash at the wall's near side.
func _check_enemy(enemy: Keen2Enemy, wall_width: int, facing: int, distance: float) -> void:
	var what := (
		"%s, wall %d, facing %+d, %.1f px"
		% [enemy.get_script().get_global_name(), wall_width, facing, distance]
	)
	var session := _session(wall_width)
	_settle(session)
	var sounds := _sounds(session)
	var near_side := _near_side(wall_width, facing)
	var box := enemy.hitbox()
	var front := near_side - distance * facing
	var left := front - box.size.x if facing > 0 else front
	# Created at the origin, so its box is its body box.
	enemy.position = Vector2(left - box.position.x, Fixtures.row_top(FLOOR_ROW) - box.end.y)
	enemy.facing = facing
	var shot := Keen2EnemyShot.fired_from(enemy, session, _enemy_shot_start(enemy))
	session.add_actor(shot)
	_check_splash(session, shot, near_side, sounds, what)


## Where [param enemy]'s shot starts: in front of it, as the enemy places
## it ([constant Keen2Elite.SHOT_GAP], [constant Keen2GuardRobot.SHOT_GAP]).
func _enemy_shot_start(enemy: Keen2Enemy) -> Vector2:
	var elite := enemy is Keen2Elite
	var gap := Keen2Elite.SHOT_GAP if elite else Keen2GuardRobot.SHOT_GAP
	var height := Keen2Elite.SHOT_HEIGHT if elite else Keen2GuardRobot.SHOT_HEIGHT
	var box := enemy.hitbox()
	var y := enemy.position.y + height
	if enemy.facing > 0:
		return Vector2(box.end.x + gap, y)
	return Vector2(box.position.x - gap - KeenPhysics.SHOT_SIZE.x, y)


## Runs [param shot] until it is gone: it must stay before [param near_side]
## and splash right against it, with SHOTHIT.
func _check_splash(
	session: Keen2LevelSession,
	shot: RaygunShot,
	near_side: float,
	sounds: Array[Sound.Id],
	what: String
) -> void:
	for tick in FLY_TICKS:
		if not _in_front(shot.hitbox(), shot.direction, near_side):
			_fail("%s: inside or behind the wall at tick %d (%s)" % [what, tick, shot.hitbox()])
			return
		if shot.removed:
			break
		session.step(KeenInput.create(0))
	assert_true(shot.is_splashing or shot.removed, "%s: splashed" % what)
	var gap := absf(_front(shot.hitbox(), shot.direction) - near_side)
	assert_true(gap < SLACK, "%s: splashed at the wall (gap %.2f)" % [what, gap])
	assert_true(sounds.has(Sound.Id.SHOT_HIT), "%s: SHOTHIT" % what)


## A closed room with a wall [param wall_width] columns wide in the middle
## and room on both sides of it; every cell is in view.
func _session(wall_width: int) -> Keen2LevelSession:
	var rows := PackedStringArray()
	for row in ROWS:
		if row == 0 or row == FLOOR_ROW:
			rows.append("#".repeat(COLUMNS))
			continue
		var line := "#" + ".".repeat(COLUMNS - 2) + "#"
		line = (
			line.substr(0, WALL_COLUMN)
			+ "#".repeat(wall_width)
			+ line.substr(WALL_COLUMN + wall_width)
		)
		rows.append(line)
	var session := Fixtures.begin_session(rows, Vector2i(2, KEEN_ROW))
	var level := session.level
	var whole: Array[Rect2] = [Rect2(Vector2.ZERO, Vector2(level.width, level.height) * TILE)]
	session.view_rects = whole
	return session


## Puts Keen [param distance] px before the wall, facing it ([param facing]
## 1: the wall is on his right).
func _place_keen(session: Keen2LevelSession, facing: int, distance: float) -> void:
	var keen := session.keen
	var near_side := _near_side(_wall_width(session), facing)
	if facing > 0:
		keen.position.x = near_side - distance - KeenPhysics.HITBOX.end.x
	else:
		keen.position.x = near_side + distance - KeenPhysics.HITBOX.position.x
	keen.facing = facing


func _settle(session: Keen2LevelSession) -> void:
	for tick in SETTLE_TICKS:
		session.step(KeenInput.create(0))


## Jumps (holding the button) or pogoes straight up for
## [constant AIR_TICKS] ticks; nothing when standing.
func _take_off(session: Keen2LevelSession, move: Move) -> void:
	if move == Move.STANDING:
		return
	var jumping := move == Move.JUMPING
	for tick in AIR_TICKS:
		session.step(KeenInput.create(0, jumping, not jumping and tick == 0))


## Every sound [param session] plays from now on.
func _sounds(session: LevelSession) -> Array[Sound.Id]:
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	return sounds


func _keen_shot(session: Keen2LevelSession) -> Keen2Shot:
	for actor in session.actors:
		if actor is Keen2Shot and (actor as Keen2Shot).from_keen:
			return actor
	return null


## The wall's side that faces the shooter, in level pixels.
func _near_side(wall_width: int, facing: int) -> float:
	if facing > 0:
		return Fixtures.column_left(WALL_COLUMN)
	return Fixtures.column_left(WALL_COLUMN + wall_width)


func _wall_width(session: Keen2LevelSession) -> int:
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
