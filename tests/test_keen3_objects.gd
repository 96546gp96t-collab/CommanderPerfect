extends "res://tests/test_case.gd"
## Tests for the ball ([Keen3Ball]), the jack ([Keen3Jack]) and the wall
## guns ([Keen3WallGun] with [Keen3GunShot]) of Keen 3 in small hand-made
## levels, without Keen 3's files: spawning, the diagonal flight and the
## bounces, riding the ball, the jack's touch, shots against both, the guns'
## one clock (also out of sight) and what their shots hit. The platforms and
## riding them are in tests/test_keen3_riding.gd; see tests/keen3_fixtures.gd
## for the level characters.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const SUB := KeenPhysics.SUBPIXEL
const TILE := EgaGraphics.TILE_SIZE
const LONG_TICKS := 600
const BALL_SPEED := 121 * SUB
const KEEN_CELL := Vector2i(2, 12)
## A box with a ceiling (row 0), a floor (row 14) and walls.
const ROWS := 15
const COLUMNS := 32
## Wide enough that a view at one end is far from guns at the other.
const WIDE_COLUMNS := 80
## How far in front of Keen's box a target for his shots stands.
const SHOT_GAP := 30.0
## Ticks between two of Keen's shots, so that he can fire again.
const SHOT_TICKS := 20


func test_ball_and_jack_spawn_and_set_off_toward_keen() -> void:
	var session := _session_with({Vector2i(10, 4): 7, Vector2i(14, 4): 8})
	var kinds := session.enemies().map(func(enemy: Enemy) -> Script: return enemy.get_script())
	assert_equal(kinds, [Keen3Ball, Keen3Jack], "info 7 is a ball, 8 a jack")
	for enemy in session.enemies():
		assert_equal(enemy.velocity, Vector2(-BALL_SPEED, BALL_SPEED), "toward Keen (left, down)")
	var keen_right := _session_with({Vector2i(1, 13): 7})
	var velocity: Vector2 = keen_right.enemies()[0].velocity
	assert_equal(velocity, Vector2(BALL_SPEED, -BALL_SPEED), "Keen is right of it and above")
	var keen_below := _session_with({Vector2i(20, 2): 7}, Vector2i(25, 12))
	assert_equal(keen_below.enemies()[0].velocity, Vector2(BALL_SPEED, BALL_SPEED), "right, down")


func test_ball_and_jack_fly_diagonally_without_gravity() -> void:
	var session := _session_with({Vector2i(10, 4): 7, Vector2i(20, 4): 8})
	var starts: Array[Vector2] = []
	for enemy in session.enemies():
		starts.append(enemy.position)
	_step(session)
	for index in starts.size():
		var moved: Vector2 = session.enemies()[index].position - starts[index]
		assert_true(moved.is_equal_approx(Vector2(-BALL_SPEED, BALL_SPEED)), "121/32 each axis")


func test_ball_and_jack_bounce_off_walls_floors_and_ceilings() -> void:
	var session := _session_with({Vector2i(10, 4): 7, Vector2i(20, 6): 8})
	session.set_invincible(true)
	var inside := Rect2(
		Fixtures.cell_top_left(Vector2i(1, 1)), Vector2(COLUMNS - 2, ROWS - 2) * TILE
	)
	for enemy in session.enemies():
		var flips := {}
		var last := enemy.velocity
		for tick in LONG_TICKS:
			_step(session)
			if enemy.velocity.x != last.x:
				flips["left" if last.x < 0 else "right"] = true
			if enemy.velocity.y != last.y:
				flips["floor" if last.y > 0 else "ceiling"] = true
			last = enemy.velocity
			assert_true(inside.encloses(enemy.hitbox()), "never in a tile")
		assert_equal(flips.size(), 4, "bounced on every side: %s" % [flips.keys()])
		assert_equal(absf(enemy.velocity.x), BALL_SPEED, "same speed after bouncing")


func test_ball_frame_and_jack_frames() -> void:
	var session := _session_with({Vector2i(10, 4): 7, Vector2i(20, 4): 8})
	var ball := session.enemies()[0]
	var jack := session.enemies()[1]
	var frames := {}
	for tick in 30:
		assert_equal(ball.sprite_index(), 109, "the ball has one picture")
		frames[jack.sprite_index()] = true
		_step(session)
	assert_equal(frames.keys().size(), 4, "the jack shows 110-113")
	assert_true(frames.keys().all(func(f: int) -> bool: return f >= 110 and f <= 113), "110-113")


func test_ball_carries_keen() -> void:
	var session := _session_with({Vector2i(10, 6): 7}, Vector2i(10, 2))
	var ball := session.enemies()[0] as Keen3Ball
	ball.velocity = Vector2.ZERO
	var keen := session.keen
	keen.position = Vector2(ball.position.x, ball.top() - KeenPhysics.SPRITE_SIZE.y - 2)
	_run_until(session, func() -> bool: return session.is_riding(keen))
	assert_true(session.is_riding(keen), "lands on the ball")
	ball.velocity = Vector2(BALL_SPEED, 0.0)
	var before := keen.position.x
	_step(session)
	assert_true(is_equal_approx(keen.position.x - before, BALL_SPEED), "goes along sideways")
	ball.velocity = Vector2(0.0, -BALL_SPEED)
	var height := keen.position.y
	for tick in 10:
		_step(session)
	assert_true(keen.position.y < height - 30, "goes up with it")
	assert_true(session.is_riding(keen) and not keen.is_dead, "still riding, harmless")


func test_ball_pushes_keen_aside() -> void:
	var session := _session_with({Vector2i(8, 12): 7}, Vector2i(4, 12))
	var ball := session.enemies()[0] as Keen3Ball
	ball.position.y = session.keen.hitbox().position.y + 4
	ball.velocity = Vector2(-BALL_SPEED, 0.0)
	var start := session.keen.position.x
	for tick in 20:
		_step(session)
		assert_true(not ball.hitbox().intersects(session.keen.hitbox()), "never inside Keen")
	assert_true(session.keen.position.x < start - 8, "pushed to the left")
	assert_true(not session.keen.is_dead, "harmless")


func test_ball_passes_a_keen_held_by_a_wall() -> void:
	var session := _session_with({Vector2i(8, 12): 7}, Vector2i(1, 12))
	var ball := session.enemies()[0] as Keen3Ball
	ball.position.y = session.keen.hitbox().position.y + 4
	ball.velocity = Vector2(-BALL_SPEED, 0.0)
	session.keen.position.x -= KeenPhysics.HITBOX.position.x
	var start := session.keen.position.x
	var wall := Fixtures.cell_top_left(Vector2i(1, 0)).x
	_run_until(session, func() -> bool: return ball.velocity.x > 0.0)
	assert_true(ball.velocity.x > 0.0, "bounced off the wall behind Keen")
	assert_true(is_equal_approx(ball.hitbox().position.x, wall), "went past him to the wall")
	assert_true(is_equal_approx(session.keen.position.x, start), "Keen stayed where he was")
	assert_true(not session.keen.is_dead, "harmless")


func test_jack_kills_keen_but_not_through_the_ankh() -> void:
	for protected in [false, true]:
		var session := _session_with({Vector2i(8, 12): 8}, Vector2i(4, 12))
		var jack := session.enemies()[0]
		jack.position.y = session.keen.hitbox().position.y + 4
		jack.velocity = Vector2(-BALL_SPEED, 0.0)
		var keen := session.keen as Keen3Body
		if protected:
			keen.add_ankh()
		for tick in 30:
			_step(session)
		assert_equal(keen.is_dead, not protected, "dead unless the ankh protects (%s)" % protected)
	var walk_into := _session_with({Vector2i(8, 12): 8}, Vector2i(4, 12))
	assert_true(not walk_into.enemies()[0] is Keen2Carrier, "nobody rides a jack")


func test_ball_and_jack_stop_shots_and_never_die() -> void:
	for info in [7, 8]:
		var session := _session_with({Vector2i(9, 12): info})
		var target := session.enemies()[0]
		target.velocity = Vector2.ZERO
		target.position = session.keen.hitbox().position + Vector2(SHOT_GAP, 0)
		session.keen.add_ankh()
		session.inventory.charges = 10
		var splashes := 0
		for shot in 10:
			_fire(session)
			for tick in SHOT_TICKS:
				_step(session)
				splashes += _take_splashes(session, target.position.x)
		assert_equal(splashes, 10, "every shot splashes on info %d" % info)
		assert_true(not target.is_dead and not target.removed, "info %d never dies" % info)


func test_guns_fire_together_every_165_ticks() -> void:
	var session := _session_with({Vector2i(3, 6): 14, Vector2i(20, 1): 15, Vector2i(25, 1): 15})
	assert_true(session.enemies().all(func(gun: Enemy) -> bool: return gun is Keen3WallGun), "guns")
	assert_equal(session.enemies()[0].sprite_index(), -1, "invisible")
	var sounds := _sounds_of(session)
	var volleys: Array[int] = []
	for tick in 2 * Keen3WallGun.PERIOD_TICKS:
		var shots_before := _gun_shots(session).size()
		_step(session)
		if _gun_shots(session).size() > shots_before:
			volleys.append(tick + 1)
			assert_equal(_gun_shots(session).size() - shots_before, 3, "all three at once")
	assert_equal(volleys, [165, 330], "every 165 ticks from the start")
	assert_equal(sounds.count(Sound.Id.TANK_FIRE), 2, "one TANKFIRE per volley")
	var sprites := _gun_shots(session).map(
		func(shot: Keen3GunShot) -> int: return shot.sprite_index()
	)
	assert_true(sprites.has(103) and sprites.has(104), "sideways 103, down 104")


func test_gun_shot_starts_at_the_original_place() -> void:
	var session := _session_with({Vector2i(3, 6): 14, Vector2i(20, 1): 15})
	_run_ticks(session, Keen3WallGun.PERIOD_TICKS)
	var shots := _gun_shots(session)
	assert_equal(shots.size(), 2, "two shots")
	var sideways := shots[0] if not shots[0].downward else shots[1]
	var downward := shots[1] if not shots[0].downward else shots[0]
	var right := Fixtures.cell_top_left(Vector2i(3, 6)) + Vector2(0, 3)
	var down := Fixtures.cell_top_left(Vector2i(20, 1)) + Vector2(4, 0)
	assert_equal(sideways.position, right, "(x, y + 3) to the right")
	assert_equal(downward.position, down, "(x + 4, y) down")
	assert_equal(downward.hitbox().size, Vector2(8, 16), "the downward shot is 8x16")
	_step(session)
	assert_true(is_equal_approx(sideways.position.x - right.x, BALL_SPEED), "121/32")
	assert_true(is_equal_approx(downward.position.y - down.y, BALL_SPEED), "121/32 down")


func test_guns_far_away_are_heard_but_their_shots_are_not_made() -> void:
	var session := _session_with({Vector2i(WIDE_COLUMNS - 4, 6): 14}, KEEN_CELL, WIDE_COLUMNS)
	session.view_rects = [Rect2(Vector2.ZERO, LevelSession.DEFAULT_VIEW_SIZE)]
	var sounds := _sounds_of(session)
	_run_ticks(session, Keen3WallGun.PERIOD_TICKS)
	assert_equal(sounds.count(Sound.Id.TANK_FIRE), 1, "heard from far away")
	assert_true(_gun_shots(session).is_empty(), "the shot is deleted at once")
	assert_true(not sounds.has(Sound.Id.SHOT_HIT), "and never splashes out of sight")


func test_gun_shot_splashes_on_a_wall() -> void:
	var session := _session_with({Vector2i(20, 1): 15})
	_run_ticks(session, Keen3WallGun.PERIOD_TICKS)
	var shot := _gun_shots(session)[0]
	var sounds := _sounds_of(session)
	_run_until(session, func() -> bool: return shot.is_splashing)
	assert_true(shot.is_splashing, "splashes on the floor")
	assert_true(sounds.has(Sound.Id.SHOT_HIT), "SHOTHIT")
	assert_true(shot.hitbox().end.y <= Fixtures.cell_top_left(Vector2i(0, 14)).y + 16, "at it")
	assert_equal(shot.sprite_index(), Keen3Shot.SPLASH_RIGHT_SPRITE, "a splash")


func test_gun_shot_kills_keen_and_flies_on() -> void:
	var session := _session_with({}, Vector2i(10, 12))
	var shot := _shoot_at(session, session.keen.hitbox())
	_run_ticks(session, 4)
	assert_true(session.keen.is_dead, "Keen dies")
	assert_true(shot.is_flying(), "the shot flies on")


func test_gun_shot_kills_a_stunned_keen_not_a_protected_one() -> void:
	var stunned := _session_with({}, Vector2i(10, 12))
	(stunned.keen as Keen3Body).stun(1)
	_shoot_at(stunned, stunned.keen.hitbox())
	_run_ticks(stunned, 4)
	assert_true(stunned.keen.is_dead, "a stunned Keen dies")
	var protected := _session_with({}, Vector2i(10, 12))
	(protected.keen as Keen3Body).add_ankh()
	_shoot_at(protected, protected.keen.hitbox())
	_run_ticks(protected, 4)
	assert_true(not protected.keen.is_dead, "the ankh protects")


func test_gun_shot_kills_grunts_and_foobs_and_passes_the_rest() -> void:
	var dies := {1: true, 6: true, 2: false, 3: false, 4: false, 5: false, 7: false, 8: false}
	for info in dies:
		var session := _session_with({Vector2i(20, 12): info}, Vector2i(2, 12))
		session.keen.add_ankh()
		var enemy := session.enemies()[0]
		var shot := _shoot_at(session, enemy.hitbox())
		_run_ticks(session, 3)
		assert_equal(enemy.is_dead, dies[info], "info %d dies: %s" % [info, dies[info]])
		assert_true(shot.is_flying(), "the shot flies on through info %d" % info)


func test_keen_shot_splashes_on_a_gun_shot_that_flies_on() -> void:
	var session := _session_with({}, Vector2i(2, 12))
	var box := session.keen.hitbox()
	var gun_shot := Keen3GunShot.fired_from(Vector2(box.end.x + 40, box.position.y - 20), true)
	session.add_actor(gun_shot)
	_fire(session)
	var keen_shot: Keen3Shot = null
	for actor in session.actors:
		if actor is Keen3Shot and actor.from_keen:
			keen_shot = actor
	keen_shot.position = gun_shot.hitbox().position + Vector2(-12, 4)
	_step(session)
	assert_true(keen_shot.is_splashing, "Keen's shot splashes")
	assert_true(gun_shot.is_flying(), "the gun's shot flies on")


## A session in a closed box of [param columns] with the objects of
## [param infos] and Keen at [param keen_cell]. The view is the whole level,
## so everything is awake.
func _session_with(
	infos: Dictionary, keen_cell := KEEN_CELL, columns := COLUMNS
) -> Keen3LevelSession:
	var typed: Dictionary[Vector2i, int] = {}
	for cell in infos:
		typed[cell] = infos[cell]
	var level := Fixtures.create_level(_box(columns), typed)
	var session := Keen3LevelSession.started(
		level, Fixtures.level_properties(), Keen3Inventory.new(), Fixtures.cell_top_left(keen_cell)
	)
	var whole: Array[Rect2] = [Rect2(Vector2.ZERO, Vector2(level.width, level.height) * TILE)]
	session.view_rects = whole
	return session


## Rows of a box [param columns] wide with walls all round.
static func _box(columns: int) -> PackedStringArray:
	var rows := PackedStringArray()
	for row in ROWS:
		var solid := row == 0 or row == ROWS - 1
		rows.append("#".repeat(columns) if solid else "#" + ".".repeat(columns - 2) + "#")
	return rows


## A gun's shot flying right at the middle of [param target], just left of
## it.
func _shoot_at(session: Keen3LevelSession, target: Rect2) -> Keen3GunShot:
	var start := Vector2(target.position.x - 12, target.get_center().y - 4)
	var shot := Keen3GunShot.fired_from(start, false)
	session.add_actor(shot)
	return shot


## Removes the splashing shots left of [param x] and returns how many.
func _take_splashes(session: Keen3LevelSession, x: float) -> int:
	var count := 0
	for actor in session.actors:
		if actor is Keen3Shot and actor.is_splashing and actor.position.x < x:
			count += 1
			actor.removed = true
	return count


func _gun_shots(session: Keen3LevelSession) -> Array[Keen3GunShot]:
	var found: Array[Keen3GunShot] = []
	for actor in session.actors:
		if actor is Keen3GunShot:
			found.append(actor)
	return found


func _step(session: Keen3LevelSession, input: KeenInput = null) -> void:
	session.step(input if input != null else KeenInput.new())


func _run_ticks(session: Keen3LevelSession, ticks: int) -> void:
	for tick in ticks:
		_step(session)


## Steps until [param done] says so, at most [constant LONG_TICKS] ticks.
func _run_until(session: Keen3LevelSession, done: Callable) -> void:
	for tick in LONG_TICKS:
		if done.call():
			return
		_step(session)


## Keen fires once (a press and a release).
func _fire(session: Keen3LevelSession) -> void:
	_step(session, KeenInput.create(0, false, false, true))
	_step(session)


func _sounds_of(session: Keen3LevelSession) -> Array[Sound.Id]:
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	return sounds
