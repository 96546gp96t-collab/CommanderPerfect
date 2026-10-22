extends "res://tests/test_case.gd"
## Tests for Keen 2's enemies in small hand-made levels, without Keen 2's
## files (tests/keen2_fixtures.gd): which info value spawns what, the grunt,
## the youth and its stun, the Elite, the Guard robot, the enemy shots and
## whether they hurt other enemies. Riding the platforms and Scrubs is in
## tests/test_keen2_riding.gd. Every session rolls its dice from the same
## seed, so the runs are the same every time.

const Fixtures := preload("res://tests/keen2_fixtures.gd")
const SETTLE_TICKS := 60
## Long enough for a random event of a few in 1000 per tick to happen.
const LONG_RUN := 1500

## Keen starts on the left, standing on the floor in row 14.
const FIELD := Fixtures.FIELD
## A closed pen in columns 11-19, rows 7-13, away from Keen.
const PEN: PackedStringArray = [
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
	"..........#.........#.........",
	"##############################",
]
const KEEN_CELL := Vector2i(2, 12)
const FLOOR_ROW := 14
const PEN_COLUMN := 15


## A session in which the lights are always off.
class DarkSession:
	extends Keen2LevelSession

	func is_dark() -> bool:
		return true


func test_info_values_spawn_keen_2_enemies() -> void:
	var values: PackedInt32Array = [1, 2, 3, 4, 5, 6, 7, 8, 0x0102, 0xFF03]
	var infos: Dictionary[Vector2i, int] = {}
	for index in values.size():
		infos[Vector2i(4 + 2 * index, 2)] = values[index]
	var session := Fixtures.begin_session(FIELD, KEEN_CELL, infos)
	var kinds: Array[Script] = []
	for enemy in session.enemies():
		kinds.append(enemy.get_script())
	var expected: Array[Script] = [
		Keen2Grunt, Keen2Youth, Keen2Elite, Keen2Scrub, Keen2GuardRobot, Keen2Platform, Keen2Spark
	]
	assert_equal(kinds, expected, "values 1-7, in order; 8 and bridges spawn nothing")
	if kinds != expected:
		return
	var enemies := session.enemies()
	assert_equal(enemies[0].position, Fixtures.cell_top_left(Vector2i(4, 2)), "grunt at its cell")
	assert_equal(
		enemies[5].position,
		Fixtures.cell_top_left(Vector2i(14, 2)) + Vector2(0, -Keen2Platform.RAISE),
		"platform 4 pixels above its cell"
	)
	assert_true(enemies[5].is_active and not enemies[0].is_active, "only the platform is awake")


func test_enemies_wait_until_they_are_in_view() -> void:
	var session := _session(FIELD)
	var grunt := Keen2Grunt.create(_on_floor(Keen2Grunt.BODY_BOX, 26))
	_add(session, grunt)
	var start := grunt.position
	_run(session, KeenInput.create(0), 30)
	assert_true(not grunt.is_active, "out of view")
	assert_equal(grunt.position, start, "has not moved")


func test_grunt_walks_turns_and_jumps() -> void:
	var session := _session(PEN)
	var grunt := Keen2Grunt.create(_on_floor(Keen2Grunt.BODY_BOX, PEN_COLUMN))
	_add(session, grunt, true)
	var seen := _watch_vorticon(session, grunt)
	assert_true(seen.facings.size() == 2, "turned around")
	assert_true(seen.moved, "walked")
	assert_true(seen.modes.has(Keen2Grunt.Mode.JUMPING), "jumped")
	assert_true(seen.highest < grunt.position.y, "rose")
	assert_true(_inside_pen(grunt), "stayed in the pen")
	assert_true(not session.keen.is_dead, "Keen is safe outside")


func test_grunt_does_not_jump_in_the_dark() -> void:
	var session := DarkSession.new()
	session._set_up(
		Fixtures.create_level(PEN),
		Fixtures.create_properties(),
		Keen2Inventory.new(),
		Fixtures.cell_top_left(KEEN_CELL)
	)
	assert_true(Keen2Enemy.is_dark(session), "dark")
	var grunt := Keen2Grunt.create(_on_floor(Keen2Grunt.BODY_BOX, PEN_COLUMN))
	_add(session, grunt, true)
	var seen := _watch_vorticon(session, grunt)
	assert_true(not seen.modes.has(Keen2Grunt.Mode.JUMPING), "never jumped")
	assert_true(seen.facings.size() == 2, "still walks and turns")


func test_one_shot_kills_a_grunt() -> void:
	var session := _session(FIELD)
	var sounds := _sounds(session)
	session.inventory.charges = 1
	var grunt := Keen2Grunt.create(_on_floor(Keen2Grunt.BODY_BOX, 8))
	_add(session, grunt)
	_run(session, KeenInput.create(0, false, false, true), 1)
	_run_until(session, func() -> bool: return grunt.is_dead, 60)
	assert_true(grunt.is_dead, "dead")
	assert_true(sounds.has(Sound.Id.VORTICON_SCREAM), "screams")
	assert_equal(grunt.sprite_index(), Keen2Grunt.SPRITE_DYING, "frame 86")
	_run(session, KeenInput.create(0), Keen2Grunt.DYING_TICKS)
	assert_equal(grunt.sprite_index(), Keen2Grunt.SPRITE_DEAD, "corpse 87")
	assert_true(not grunt.touches_keen() and not grunt.stops_shots(), "harmless corpse")


func test_grunt_kills_keen() -> void:
	var session := _session(FIELD)
	var grunt := Keen2Grunt.create(_on_floor(Keen2Grunt.BODY_BOX, 4))
	_add(session, grunt, true)
	_run_until(session, func() -> bool: return session.keen.is_dead, 200)
	assert_true(session.keen.is_dead, "deadly to touch")


func test_youth_stuns_keen() -> void:
	var session := _session(FIELD)
	var keen := session.keen as Keen2Body
	var youth := Keen2Youth.create(_on_floor(Keen2Youth.BODY_BOX, 4), -1)
	_add(session, youth, true)
	_run_until(session, keen.is_stunned, 200)
	assert_true(keen.is_stunned() and not keen.is_dead, "stunned, not dead")
	assert_equal(keen.facing, youth.facing, "faces the way the youth runs")
	assert_equal(keen.velocity.y, -Keen2Body.STUN_JUMP_SPEED, "knocked up a full jump")
	assert_true(not keen.on_pogo, "no pogo stick")
	assert_equal(keen.sprite_index(), Keen2Body.SPRITE_STUNNED, "frame 28")
	youth.removed = true
	session.inventory.charges = 1
	var x := keen.position.x
	_run(session, KeenInput.create(1, true, true, true), Keen2Body.STUN_FRAME_TICKS)
	assert_equal(keen.sprite_index(), Keen2Body.SPRITE_STUNNED + 1, "frame 29")
	var left := Keen2Body.STUN_TICKS - Keen2Body.STUN_FRAME_TICKS - Keen2Body.GETTING_UP_TICKS
	_run(session, KeenInput.create(1, true, true, true), left)
	assert_equal(keen.sprite_index(), Keen2Body.SPRITE_GETTING_UP, "gets up: frame 31")
	_run(session, KeenInput.create(1), Keen2Body.GETTING_UP_TICKS - 1)
	assert_true(keen.is_stunned(), "still stunned one tick before the end")
	assert_equal(keen.position.x, x, "the buttons did nothing")
	assert_equal(session.inventory.charges, 1, "no shot fired")
	_run(session, KeenInput.create(1), 1)
	assert_true(not keen.is_stunned(), "up again after 250 ticks")
	_run(session, KeenInput.create(1), 10)
	assert_true(keen.position.x > x, "walks again")


func test_enemy_shot_shortens_a_stun() -> void:
	var session := _session(FIELD)
	var keen := session.keen as Keen2Body
	keen.stun(1)
	session.add_actor(Keen2EnemyShot.fired_by(Keen2GuardRobot, keen.hitbox().position, -1))
	_run(session, KeenInput.create(0), 1)
	assert_true(not keen.is_dead, "not killed")
	assert_true(keen.is_stunned(), "still stunned")
	_run(session, KeenInput.create(0), Keen2Body.STUN_SHORTENED_TICKS)
	assert_true(not keen.is_stunned(), "up after 20 ticks")


func test_enemy_shot_kills_keen() -> void:
	var session := _session(FIELD)
	var start := Vector2(Fixtures.column_left(8), session.keen.position.y + 9)
	var shot := Keen2EnemyShot.fired_by(Keen2Elite, start, -1)
	session.add_actor(shot)
	assert_equal(shot.sprite_index(), Keen2Shot.ENEMY_SHOT_SPRITE, "sprite 123")
	var x := shot.position.x
	_run(session, KeenInput.create(0), 1)
	assert_equal(shot.position.x, x - Keen2EnemyShot.SPEED, "108/32 per tick")
	_run_until(session, func() -> bool: return session.keen.is_dead, 60)
	assert_true(session.keen.is_dead, "dead")


func test_elite_charges_when_keen_is_close() -> void:
	var session := _session(FIELD)
	session.set_invincible(true)
	var elite := Keen2Elite.create(_on_floor(Keen2Elite.BODY_BOX, 6))
	_add(session, elite, true)
	var x := elite.position.x
	_run(session, KeenInput.create(0), 1)
	assert_true(elite.is_charging, "charges")
	assert_equal(elite.position.x, x - Keen2Elite.CHARGE_SPEED, "at 62/32 towards Keen")
	var far := Keen2Elite.create(_on_floor(Keen2Elite.BODY_BOX, 14))
	_add(session, far, true)
	x = far.position.x
	_run(session, KeenInput.create(0), 1)
	assert_true(not far.is_charging, "walks when Keen is further away")
	assert_equal(absf(far.position.x - x), Keen2Elite.WALK_SPEED, "at 31/32")


func test_elite_fires() -> void:
	var session := _session(PEN)
	session.view_rects = [Rect2(Vector2.ZERO, Vector2(2000, 2000))]
	var sounds := _sounds(session)
	var elite := Keen2Elite.create(_on_floor(Keen2Elite.BODY_BOX, PEN_COLUMN))
	_add(session, elite, true)
	var shots := _run_until_shot(session)
	assert_true(not shots.is_empty(), "fired")
	if shots.is_empty():
		return
	assert_equal(shots[0].shooter, Keen2Elite, "an Elite's shot")
	assert_true(sounds.has(Sound.Id.KEEN_FIRE), "KEENFIRESND")
	assert_equal(elite.mode, Keen2Elite.Mode.FIRED, "holds the gun out")
	assert_true(
		elite.sprite_index() in [Keen2Elite.SPRITE_FIRE_LEFT, Keen2Elite.SPRITE_FIRE_RIGHT],
		"frame 96 or 97"
	)


func test_elite_takes_four_shots() -> void:
	var session := _session(FIELD)
	var elite := Keen2Elite.create(_on_floor(Keen2Elite.BODY_BOX, 9))
	_add(session, elite)
	for shot in Keen2Elite.HEALTH - 1:
		elite.hit_by_shot(session)
	assert_true(not elite.is_dead, "alive after three")
	elite.hit_by_shot(session)
	assert_true(elite.is_dead, "dead after four")
	_run(session, KeenInput.create(0), Keen2Elite.DYING_TICKS)
	assert_equal(elite.sprite_index(), Keen2Elite.SPRITE_DEAD, "corpse 101")


func test_guard_robot_hovers_and_fires_volleys_of_four() -> void:
	var session := _session(FIELD)
	session.view_rects = [Rect2(Vector2.ZERO, Vector2(2000, 2000))]
	var sounds := _sounds(session)
	var robot := Keen2GuardRobot.create(Fixtures.cell_top_left(Vector2i(3, 4)))
	_add(session, robot, true)
	var y := robot.position.y
	var fired_at: Array[int] = []
	var seen := {}
	var pause := Keen2GuardRobot.PAUSE_TICKS
	var volley := Keen2GuardRobot.VOLLEY_SHOTS * Keen2GuardRobot.SHOT_INTERVAL
	# Ends before the next volley can start.
	for tick in Keen2GuardRobot.FIRST_VOLLEY_TICKS + pause + volley + pause:
		session.step(KeenInput.create(0))
		for actor in session.actors:
			if actor is Keen2EnemyShot and not seen.has(actor):
				seen[actor] = true
				fired_at.append(tick)
	assert_equal(robot.position.y, y, "does not fall")
	assert_equal(fired_at.size(), Keen2GuardRobot.VOLLEY_SHOTS, "one volley of four")
	for index in range(1, fired_at.size()):
		assert_equal(fired_at[index] - fired_at[index - 1], Keen2GuardRobot.SHOT_INTERVAL, "apart")
	assert_true(fired_at.size() > 0 and fired_at[0] > Keen2GuardRobot.FIRST_VOLLEY_TICKS, "late")
	assert_equal(sounds.count(Sound.Id.TANK_FIRE), Keen2GuardRobot.VOLLEY_SHOTS, "TANKFIRE")


## 112-115 show the gun on the right, 116-119 on the left (the EGAHEAD
## names say the opposite): the picture faces the way it floats and fires.
func test_guard_robot_faces_the_way_it_floats_and_fires() -> void:
	var session := _session(FIELD)
	session.view_rects = [Rect2(Vector2.ZERO, Vector2(2000, 2000))]
	var robot := Keen2GuardRobot.create(Fixtures.cell_top_left(Vector2i(3, 4)))
	_add(session, robot, true)
	var x := robot.position.x
	var shot: Keen2EnemyShot = null
	for tick in Keen2GuardRobot.FIRST_VOLLEY_TICKS + Keen2GuardRobot.PAUSE_TICKS + 2:
		session.step(KeenInput.create(0))
		for actor in session.actors:
			if actor is Keen2EnemyShot and shot == null:
				shot = actor
	assert_true(robot.position.x > x, "floats to the right")
	var frame := robot.sprite_index()
	assert_true(frame >= 112 and frame <= 115, "right frames 112-115, got %d" % frame)
	assert_true(shot != null and shot.direction == 1, "fires to the right")
	robot.facing = -1
	frame = robot.sprite_index()
	assert_true(frame >= 116 and frame <= 119, "left frames 116-119, got %d" % frame)


func test_guard_robot_is_invincible() -> void:
	var session := _session(FIELD)
	session.inventory.charges = 1
	var robot := Keen2GuardRobot.create(_on_floor(Keen2GuardRobot.BODY_BOX, 9))
	_add(session, robot)
	_run(session, KeenInput.create(0, false, false, true), 1)
	var shot := _keen_shot(session)
	_run_until(session, func() -> bool: return shot.is_splashing, 60)
	assert_true(shot.is_splashing, "stopped the shot")
	assert_true(shot.position.x < robot.hitbox().end.x, "at the robot")
	assert_true(not robot.is_dead, "unharmed")


func test_guard_robot_kills_keen() -> void:
	var session := _session(FIELD)
	var robot := Keen2GuardRobot.create(_on_floor(Keen2GuardRobot.BODY_BOX, 6))
	robot.facing = -1
	_add(session, robot, true)
	_run_until(session, func() -> bool: return session.keen.is_dead, 200)
	assert_true(session.keen.is_dead, "deadly to touch")


func test_enemy_shots_hurt_other_enemies() -> void:
	var session := _session(FIELD)
	assert_true(session.enemy_shots_hurt_enemies, "on, as in Commander Genius")
	var grunt := _shoot_at_grunt(session)
	assert_true(grunt.is_dead, "a Guard robot's shot kills a grunt")
	session = _session(FIELD)
	session.enemy_shots_hurt_enemies = false
	grunt = _shoot_at_grunt(session)
	assert_true(not grunt.is_dead, "switched off: the grunt lives")


func test_elite_is_immune_to_guard_robot_shots() -> void:
	var session := _session(FIELD)
	var elite := Keen2Elite.create(_on_floor(Keen2Elite.BODY_BOX, 16))
	_add(session, elite)
	var shot := _fire_at(session, Keen2GuardRobot, elite)
	assert_true(shot.is_splashing, "stops the shot")
	assert_equal(elite.health, Keen2Elite.HEALTH, "unharmed")
	session = _session(FIELD)
	elite = Keen2Elite.create(_on_floor(Keen2Elite.BODY_BOX, 16))
	_add(session, elite)
	shot = _fire_at(session, Keen2Elite, elite)
	assert_true(shot.position.x > elite.hitbox().end.x, "an Elite's shot flies through an Elite")
	assert_equal(elite.health, Keen2Elite.HEALTH, "unharmed by its own kind")


## Fires a Guard robot's shot at a grunt that stands at column 16.
func _shoot_at_grunt(session: Keen2LevelSession) -> Keen2Grunt:
	var grunt := Keen2Grunt.create(_on_floor(Keen2Grunt.BODY_BOX, 16))
	_add(session, grunt)
	_fire_at(session, Keen2GuardRobot, grunt)
	return grunt


## Fires a shot of [param shooter] from column 10 at [param target] and
## runs until it hit something or flew past.
func _fire_at(session: Keen2LevelSession, shooter: Script, target: Enemy) -> Keen2EnemyShot:
	var start := Vector2(Fixtures.column_left(10), target.position.y + Keen2Elite.SHOT_HEIGHT)
	var shot := Keen2EnemyShot.fired_by(shooter, start, 1)
	session.add_actor(shot)
	var past := target.hitbox().end.x + EgaGraphics.TILE_SIZE
	_run_until(session, func() -> bool: return shot.is_splashing or shot.position.x > past, 60)
	return shot


## Runs [param vorticon] for a long time and notes what it did.
func _watch_vorticon(session: LevelSession, vorticon: Keen2Grunt) -> Dictionary:
	var seen := {"facings": {}, "modes": {}, "moved": false, "highest": vorticon.position.y}
	var start := vorticon.position
	for tick in LONG_RUN:
		session.step(KeenInput.create(0))
		seen.facings[vorticon.facing] = true
		seen.modes[vorticon.mode] = true
		seen.moved = seen.moved or vorticon.position.x != start.x
		seen.highest = minf(seen.highest, vorticon.position.y)
	return seen


## Runs until an enemy shot appears; returns the enemy shots then.
func _run_until_shot(session: LevelSession) -> Array[Keen2EnemyShot]:
	var shots: Array[Keen2EnemyShot] = []
	for tick in LONG_RUN * 2:
		session.step(KeenInput.create(0))
		for actor in session.actors:
			if actor is Keen2EnemyShot:
				shots.append(actor)
		if not shots.is_empty():
			break
	return shots


func _inside_pen(enemy: Enemy) -> bool:
	var pen := Rect2(Fixtures.cell_top_left(Vector2i(11, 7)), Vector2(9, 7) * EgaGraphics.TILE_SIZE)
	return pen.encloses(enemy.hitbox())


## A session with Keen standing on the floor.
func _session(rows: PackedStringArray) -> Keen2LevelSession:
	var session := Fixtures.begin_session(rows, KEEN_CELL)
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	return session


## Puts [param enemy] into [param session], on the floor below it, awake
## at once when [param awake].
func _add(session: LevelSession, enemy: Enemy, awake := false) -> void:
	session.add_actor(enemy)
	enemy.settle(session)
	enemy.is_active = enemy.is_active or awake


func _on_floor(box: Rect2, column: int) -> Vector2:
	return Fixtures.on_floor(box, column, FLOOR_ROW)


## Every sound [param session] plays from now on.
func _sounds(session: LevelSession) -> Array[Sound.Id]:
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	return sounds


## The first shot in [param session].
func _keen_shot(session: LevelSession) -> Keen2Shot:
	for actor in session.actors:
		if actor is Keen2Shot:
			return actor
	return null


func _run(session: LevelSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


## Runs until [param done] returns true, at most [param ticks] ticks.
func _run_until(session: LevelSession, done: Callable, ticks: int) -> void:
	for tick in ticks:
		if done.call():
			return
		session.step(KeenInput.create(0))
