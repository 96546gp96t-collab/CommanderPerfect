extends "res://tests/test_case.gd"
## Tests for the Tantalus Ray machine and the Earth exploding, in small
## hand-made levels and a small hand-made map 81, without Keen 2's files
## (tests/keen2_fixtures.gd): shooting the spark wrecks the machine tile by
## tile and gives its points; the switch of a wrecked machine does nothing;
## the switch of an intact machine fires the Tantalus Ray, which ends the
## game whatever the lives; and the scene on map 81 ([Keen2EarthExplosion])
## runs to its end and leaves the Earth wrecked.

const Fixtures := preload("res://tests/keen2_fixtures.gd")
const SETTLE_TICKS := 60
## More than the beam and the wreck take, so that a bug cannot hang a test.
const MAX_TICKS := 1000
## The machine: its spark in (12, 6), its switch (a lever, info 0) three
## columns left and four rows down. Keen shoots from the ledge on the left,
## or stands at the switch.
const MACHINE_LEVEL: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"#####.........................",
	"..............................",
	"..............................",
	".........d....................",
	"##############################",
]
const SPARK_CELL := Vector2i(12, 6)
const SWITCH_CELL := Vector2i(9, 10)
const SHOOTER_CELL := Vector2i(2, 4)
const SWITCH_KEEN_CELL := Vector2i(9, 8)
## A map 81 just big enough: the beam's path and the Earth.
const SPACE_SIZE := Vector2i(60, 36)


func test_shooting_the_spark_wrecks_the_machine() -> void:
	var session := _session(SHOOTER_CELL)
	assert_equal(session.machine_count, 1, "one machine")
	var spark := session.enemies()[0] as Keen2Spark
	assert_true(spark != null, "the spark")
	assert_true(not spark.touches_keen(), "harmless")
	session.inventory.charges = 1
	session.step(KeenInput.create(0, false, false, true))
	_run_until(session, func() -> bool: return spark.is_dead)
	assert_true(spark.is_dead, "one shot")
	assert_equal(session.machines_destroyed, 1, "counted")
	assert_true(session.all_machines_destroyed(), "all destroyed")
	assert_equal(
		_tile(session, SWITCH_CELL), Keen2Tantalus.BROKEN_SWITCH, "the switch breaks at once"
	)
	_run_until(session, func() -> bool: return spark.removed)
	assert_true(spark.removed, "the wreck is over")
	_check_wreck(session)
	assert_equal(session.inventory.score, Keen2Tantalus.TOTAL_POINTS, "3 x 10,000 points")


func test_wreck_takes_its_steps_26_ticks_apart() -> void:
	var session := _session(SHOOTER_CELL)
	var spark := session.enemies()[0] as Keen2Spark
	spark.hit_by_shot(session)
	var purple := SPARK_CELL + Keen2Tantalus.PURPLE_OFFSET
	assert_true(_tile(session, purple) != Keen2Tantalus.BURNT_PURPLE, "not yet")
	_run(session, Keen2Tantalus.STEP_TICKS)
	assert_equal(_tile(session, purple), Keen2Tantalus.BURNT_PURPLE, "after 26 ticks")
	assert_equal(session.inventory.score, Keen2Tantalus.POINTS, "10,000")
	var splashes := session.actors.filter(func(actor: Actor) -> bool: return actor is Keen2Shot)
	assert_equal(splashes.size(), 1, "a splash")


func test_switch_of_a_wrecked_machine_does_nothing() -> void:
	var session := _session(SWITCH_KEEN_CELL)
	var spark := session.enemies()[0] as Keen2Spark
	spark.hit_by_shot(session)
	_run_until(session, func() -> bool: return spark.removed)
	session.step(KeenInput.create(0, false, true))
	assert_true(not session.tantalus_fired, "no Tantalus Ray")
	assert_true(session.keen.on_pogo, "the button takes out the pogo stick")


func test_switch_of_an_intact_machine_explodes_the_earth() -> void:
	var session := _session(SWITCH_KEEN_CELL)
	session.set_dark(true)
	var play := Keen2LevelPlay.create(null, session.properties, session.inventory)
	play.session = session
	play.level = session.level
	play.state = Keen2LevelPlay.State.PLAYING
	var events := {"exploded": 0, "game over": 0, "fired": 0}
	play.earth_exploded.connect(func() -> void: events["exploded"] += 1)
	play.game_over.connect(func() -> void: events["game over"] += 1)
	session.tantalus_ray_fired.connect(func() -> void: events["fired"] += 1)
	play.step(KeenInput.create(0, false, true))
	assert_true(session.tantalus_fired, "fired")
	assert_equal(events, {"exploded": 1, "game over": 0, "fired": 1}, "the Earth, once")
	assert_equal(play.state, Keen2LevelPlay.State.EARTH_EXPLODED, "the game is over")
	assert_equal(session.inventory.lives, Inventory.START_LIVES, "whatever the lives")
	assert_true(not session.is_dark(), "the lights come on")
	var position := session.keen.position
	play.step(KeenInput.create(1))
	session.step(KeenInput.create(1))
	assert_equal(session.keen.position, position, "nothing moves any more")
	assert_equal(events["exploded"], 1, "not again")


func test_enemy_shots_fly_through_the_spark() -> void:
	var session := _session(SHOOTER_CELL)
	var spark := session.enemies()[0] as Keen2Spark
	var start := Vector2(Fixtures.column_left(8), spark.position.y + 4)
	var shot := Keen2EnemyShot.fired_by(Keen2GuardRobot, start, 1)
	session.add_actor(shot)
	_run(session, 30)
	assert_true(not spark.is_dead, "only Keen destroys it")


func test_earth_explosion_ends_with_the_earth_wrecked() -> void:
	var space := _space_map()
	var scene := Keen2EarthExplosion.create(space)
	var changed := {}
	var hits := [0]
	var sounds: Array[Sound.Id] = []
	scene.tile_changed.connect(func(cell: Vector2i, tile: int) -> void: changed[cell] = tile)
	scene.earth_hit.connect(func() -> void: hits[0] += 1)
	scene.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	var seen := {}
	var chunk_velocities := {}
	var ticks := 0
	while not scene.finished and ticks < MAX_TICKS:
		scene.step()
		ticks += 1
		for actor: Keen2SpaceSprite in scene.actors:
			seen[actor.sprite_index()] = true
			if actor.velocity != Vector2.ZERO and not actor.frames.has(58):
				chunk_velocities[actor.velocity] = true
	assert_true(scene.finished, "the scene ends")
	var explosion_ticks := Keen2EarthExplosion.LAST_STEP * Keen2EarthExplosion.STEP_TICKS + 1
	assert_true(ticks > explosion_ticks, "after the beam and 33 steps")
	assert_equal(hits[0], 1, "the beam hits once")
	assert_equal(sounds, [Sound.Id.KEEN_FIRE] as Array[Sound.Id], "the beam fires")
	for y in Keen2EarthExplosion.EARTH_SIZE:
		for x in Keen2EarthExplosion.EARTH_SIZE:
			var cell := Keen2EarthExplosion.EARTH_CELL + Vector2i(x, y)
			assert_equal(space.tile_at(cell), Keen2EarthExplosion.WRECKED_EARTH, "%s" % cell)
			assert_equal(changed.get(cell), Keen2EarthExplosion.WRECKED_EARTH, "announced")
	for sprite in [58, 59, 60, 63]:
		assert_true(seen.has(sprite), "sprite %d shown" % sprite)
	assert_true(seen.has(64) or seen.has(66), "big chunks")
	assert_true(seen.has(68) and seen.has(70), "small chunks both ways")
	assert_true(chunk_velocities.size() >= 8, "chunks fly apart in many directions")


func test_beam_flies_right_and_down_to_column_47() -> void:
	var scene := Keen2EarthExplosion.create(_space_map())
	var start := scene.view_center()
	scene.step()
	var moved := scene.view_center() - start
	assert_equal(moved, Keen2EarthExplosion.BEAM_VELOCITY, "252/32 right, 108/32 down")
	while scene.is_beam_flying():
		scene.step()
	assert_equal(scene.view_center(), Keen2EarthExplosion.earth_center(), "then the Earth")


func _session(keen_cell: Vector2i) -> Keen2LevelSession:
	var infos: Dictionary[Vector2i, int] = {SPARK_CELL: Keen2LevelSession.INFO_SPARK}
	var session := Fixtures.begin_session(MACHINE_LEVEL, keen_cell, infos)
	_run(session, SETTLE_TICKS)
	return session


func _run(session: LevelSession, ticks: int) -> void:
	for tick in ticks:
		session.step(KeenInput.create(0))


func _run_until(session: LevelSession, done: Callable) -> void:
	for tick in MAX_TICKS:
		if done.call():
			return
		session.step(KeenInput.create(0))


func _tile(session: LevelSession, cell: Vector2i) -> int:
	return session.level.tile_at(cell + Vector2i.ONE * LevelData.BORDER_CELLS)


func _check_wreck(session: LevelSession) -> void:
	for index in Keen2Tantalus.BROKEN_GLASS.size():
		var glass := SPARK_CELL + Vector2i(Keen2Tantalus.GLASS_LEFT + index, 0)
		assert_equal(_tile(session, glass), Keen2Tantalus.BROKEN_GLASS[index], "glass %d" % index)
	var dome := SPARK_CELL + Vector2i(0, Keen2Tantalus.DOME_ROW)
	assert_equal(_tile(session, dome), Keen2Tantalus.EMPTY_TILE, "the dome is gone")
	for index in Keen2Tantalus.PURPLE_STEPS:
		var purple := SPARK_CELL + Keen2Tantalus.PURPLE_OFFSET + Vector2i(0, index)
		assert_equal(_tile(session, purple), Keen2Tantalus.BURNT_PURPLE, "purple %d" % index)
	for column in Keen2Tantalus.GLOW_STEPS:
		for row in Keen2Tantalus.GLOW_ROWS:
			var glow := SPARK_CELL + Keen2Tantalus.GLOW_OFFSET + Vector2i(column, row)
			assert_equal(_tile(session, glow), Keen2Tantalus.DARK_GLOW, "glow %s" % glow)
	for y in Keen2Tantalus.DISPLAY_SIZE:
		for x in Keen2Tantalus.DISPLAY_SIZE:
			var display := SPARK_CELL + Keen2Tantalus.DISPLAY_OFFSET + Vector2i(x, y)
			assert_equal(_tile(session, display), Keen2Tantalus.STILL_DISPLAY, "display")


func _space_map() -> LevelData:
	var space := LevelData.new()
	space.width = SPACE_SIZE.x
	space.height = SPACE_SIZE.y
	space.tiles.resize(space.width * space.height)
	space.infos.resize(space.width * space.height)
	return space
