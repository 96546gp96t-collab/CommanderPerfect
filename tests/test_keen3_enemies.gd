extends "res://tests/test_case.gd"
## Tests for Keen 3's enemies one by one ([Keen3Grunt], [Keen3Youth],
## [Keen3Mom] with [Keen3Fireball], [Keen3Meep] with [Keen3SoundWave],
## [Keen3Ninja], [Keen3Foob]) in small hand-made levels, without Keen 3's
## files: what spawns from each info value, walking and turning, touching
## Keen, the hits they take and their dying frames. The general rules (the
## stun, the ankh, points, waking and sleeping) are in
## tests/test_keen3_enemy_rules.gd; see tests/keen3_fixtures.gd for the
## level characters.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const SUB := KeenPhysics.SUBPIXEL
const TILE := EgaGraphics.TILE_SIZE
const LONG_TICKS := 600

## A floor in row 14, walls at both ends.
const FIELD: PackedStringArray = [
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"#..............................#",
	"################################",
]
const KEEN_CELL := Vector2i(2, 12)
## A ledge (row 10, columns 14-24) above the floor.
const LEDGE_ROW := 10
const LEDGE_FROM := 14
const LEDGE_TO := 24


func test_each_info_value_spawns_its_enemy() -> void:
	var kinds: Dictionary[int, Script] = {
		1: Keen3Grunt,
		2: Keen3Youth,
		3: Keen3Mom,
		4: Keen3Meep,
		5: Keen3Ninja,
		6: Keen3Foob,
		11: Keen3Grunt,
	}
	for info in kinds:
		var session := _session_with({Vector2i(10, 12): info})
		var spawned := session.enemies()
		assert_equal(spawned.size(), 1, "one enemy for info %d" % info)
		if spawned.size() == 1:
			assert_true(spawned[0].get_script() == kinds[info], "the right kind for %d" % info)
			assert_equal(spawned[0].facing, -1, "info %d sets off toward Keen" % info)


func test_grunt_walks_toward_keen_at_its_speeds() -> void:
	var session := _session_with({Vector2i(20, 12): 1})
	var grunt := session.enemies()[0] as Keen3Grunt
	var speeds := {}
	for tick in 120:
		var before := grunt.position.x
		var was_walking := grunt.mode == Keen3Grunt.Mode.WALKING and grunt.on_ground
		_step(session)
		if was_walking and grunt.mode == Keen3Grunt.Mode.WALKING and grunt.facing < 0:
			speeds[roundi((before - grunt.position.x) / SUB * 10)] = true
	assert_true(speeds.has(273), "walks 27.3/32 (90)")
	for speed in speeds:
		assert_true(speed == 273 or speed == 364, "only 90 or 120: %d" % speed)


func test_grunt_turns_at_a_wall() -> void:
	var session := _session_with({Vector2i(26, 12): 1}, Vector2i(28, 12))
	var grunt := session.enemies()[0] as Keen3Grunt
	grunt.facing = 1
	var turned := false
	var in_wall := false
	for tick in 150:
		_step(session)
		turned = turned or grunt.facing < 0
		in_wall = in_wall or grunt.hitbox().end.x > _cell_left(31) + 0.01
	assert_true(turned, "turned round at the right wall")
	assert_true(not in_wall, "never in the wall")


func test_grunt_looks_around_after_a_landing_then_goes_for_keen() -> void:
	var session := _session_with({Vector2i(20, LEDGE_ROW - 2): 1}, KEEN_CELL, _ledge_rows())
	var grunt := session.enemies()[0] as Keen3Grunt
	var looking := 0
	var frames := {}
	var saw_jumping := false
	for tick in LONG_TICKS:
		_step(session)
		saw_jumping = saw_jumping or grunt.mode == Keen3Grunt.Mode.JUMPING
		if grunt.mode == Keen3Grunt.Mode.LOOKING:
			looking += 1
			frames[grunt.sprite_index()] = true
		elif looking > 0:
			break
	assert_true(saw_jumping, "in the air after walking off or jumping")
	assert_true(looking == 33 or looking == 34, "looks around 33 ticks: %d" % looking)
	assert_true(frames.keys().all(func(f: int) -> bool: return f >= 71 and f <= 74), "71-74")
	assert_equal(grunt.facing, -1, "then walks toward Keen")


func test_grunt_jump_frames() -> void:
	var grunt := Keen3Grunt.spawned(Vector2.ZERO, 1)
	grunt.mode = Keen3Grunt.Mode.JUMPING
	assert_equal(grunt.sprite_index(), 73, "GRUNTJUMPL while moving right")
	grunt.facing = -1
	assert_equal(grunt.sprite_index(), 74, "GRUNTJUMPR while moving left")


func test_grunt_kills_keen() -> void:
	var session := _session_with({Vector2i(5, 12): 1})
	_run_until(session, func() -> bool: return session.keen.is_dead)
	assert_true(session.keen.is_dead, "the grunt kills Keen")


func test_grunt_dies_from_one_shot() -> void:
	var session := _session_with({Vector2i(9, 12): 1})
	var grunt := session.enemies()[0] as Keen3Grunt
	var sounds := _sounds_of(session)
	_fire(session)
	_run_until(session, func() -> bool: return grunt.is_dead)
	assert_true(grunt.is_dead, "one shot")
	assert_true(sounds.has(Sound.Id.VORTICON_SCREAM), "vortscream")
	_assert_dying_frames(session, grunt, [75, 76])


func test_youth_runs_toward_keen_and_stuns_him() -> void:
	var session := _session_with({Vector2i(12, 12): 2})
	var youth := session.enemies()[0] as Keen3Youth
	var before := youth.position.x
	_step(session)
	assert_true(
		is_equal_approx(before - youth.position.x, 76 * SUB) or not youth.on_ground,
		"runs 76/32 (250) toward Keen"
	)
	var keen := session.keen as Keen3Body
	_run_until(session, keen.is_stunned)
	assert_true(keen.is_stunned(), "stunned")
	assert_true(not keen.is_dead, "not killed")
	assert_true(keen.sprite_index() == 28 or keen.sprite_index() == 29, "KEENSICLE")


func test_youth_hop_frames_and_dying() -> void:
	var youth := Keen3Youth.spawned(Vector2.ZERO, -1)
	youth.on_ground = false
	assert_equal(youth.sprite_index(), 50, "YOUTHLEFT4 in the air")
	youth.facing = 1
	assert_equal(youth.sprite_index(), 54, "YOUTHRIGHT4 in the air")
	var session := _session_with({Vector2i(9, 12): 2})
	var shot_youth := session.enemies()[0] as Keen3Youth
	shot_youth.hit_by_shot(session)
	assert_true(shot_youth.is_dead, "one shot")
	_assert_dying_frames(session, shot_youth, [55, 56])


func test_mom_does_not_walk_off_a_ledge() -> void:
	var session := _session_with({Vector2i(20, LEDGE_ROW - 2): 3}, KEEN_CELL, _ledge_rows())
	var mom := session.enemies()[0] as Keen3Mom
	var height := mom.position.y
	for tick in LONG_TICKS:
		_step(session)
		assert_equal(mom.position.y, height, "stays on the ledge")
		if mom.position.y != height:
			return
	assert_true(mom.hitbox().end.x > _cell_left(LEDGE_FROM), "on the ledge on the left")
	assert_true(mom.hitbox().position.x < _cell_left(LEDGE_TO + 1), "on the ledge on the right")


func test_mom_pushes_keen_and_takes_five_shots() -> void:
	var session := _session_with({Vector2i(6, 12): 3})
	session.set_invincible(true)
	var mom := session.enemies()[0] as Keen3Mom
	for tick in 60:
		_step(session, KeenInput.create(1))
		assert_true(not session.keen.hitbox().intersects(mom.hitbox()), "pushed out")
	assert_true(not session.keen.is_dead, "never killed")
	for hit in 4:
		mom.hit_by_shot(session)
	assert_true(not mom.is_dead, "alive after 4 shots")
	mom.hit_by_shot(session)
	assert_true(mom.is_dead, "dead after 5")
	_assert_dying_frames(session, mom, [91, 92])


func test_mom_turns_and_spits_a_fireball() -> void:
	var session := _session_with({Vector2i(12, 12): 3})
	var mom := session.enemies()[0] as Keen3Mom
	var sounds := _sounds_of(session)
	mom.facing = 1
	mom.start_spitting()
	assert_equal(mom.facing, -1, "turned round")
	assert_equal(mom.sprite_index(), 89, "WOMANBL")
	var ticks := 0
	while _fireballs(session).is_empty() and ticks < 60:
		_step(session)
		ticks += 1
	assert_equal(ticks, 13, "the fireball after 12.4 ticks")
	assert_true(sounds.has(Sound.Id.TANK_FIRE), "TANKFIRE")
	var fireball := _fireballs(session)[0]
	assert_equal(fireball.position.y, mom.position.y + 12, "12 px below her top")
	assert_equal(fireball.direction, -1, "flies the new way")
	var x := fireball.position.x
	_step(session)
	ticks += 1
	assert_true(is_equal_approx(x - fireball.position.x, 45.5 * SUB), "45.5/32 (150)")
	assert_true(fireball.sprite_index() == 57 or fireball.sprite_index() == 58, "57-58")
	while mom.mode == Keen3Mom.Mode.SPITTING and ticks < 60:
		_step(session)
		ticks += 1
	assert_equal(ticks, 21, "walks on after 20.6 ticks")
	_run_until(session, func() -> bool: return session.keen.is_dead)
	assert_true(session.keen.is_dead, "the fireball kills Keen")


func test_fireball_passes_a_mother_and_kills_grunts_and_foobs() -> void:
	for info in [3, 1, 6]:
		var session := _session_with({Vector2i(10, 12): info}, Vector2i(28, 12))
		var enemy := session.enemies()[0]
		var start := Vector2(_cell_left(16), enemy.hitbox().position.y + 2)
		var fireball := Keen3Fireball.spat(session, start, -1)
		session.add_actor(fireball)
		_run_until(session, func() -> bool: return not fireball.is_flying())
		if info == 3:
			assert_true(fireball.position.x < enemy.hitbox().position.x, "through the mother")
			assert_true(not enemy.is_dead, "the mother unharmed")
		else:
			assert_true(enemy.is_dead, "kills info %d" % info)


func test_keen_shoots_a_fireball_down() -> void:
	var session := _session_with({})
	var start := Vector2(_cell_left(10), session.keen.position.y + KeenPhysics.SHOT_HEIGHT)
	var fireball := Keen3Fireball.spat(session, start, -1)
	session.add_actor(fireball)
	_fire(session)
	_run_until(session, func() -> bool: return not fireball.is_flying())
	assert_true(fireball.is_splashing, "the fireball splashed")
	assert_true(not session.keen.is_dead, "Keen alive")
	var keen_shots := session.actors.filter(
		func(a: Actor) -> bool: return a is Keen3Shot and a.from_keen
	)
	assert_true(keen_shots.all(func(s: Keen3Shot) -> bool: return s.is_splashing), "both")


func test_meep_sings_a_wave_through_a_wall() -> void:
	var rows := FIELD.duplicate()
	for row in range(10, 14):
		rows[row] = rows[row].substr(0, 6) + "#" + rows[row].substr(7)
	var session := _session_with({Vector2i(10, 12): 4}, KEEN_CELL, rows)
	var meep := session.enemies()[0] as Keen3Meep
	var sounds := _keen3_sounds_of(session)
	meep.start_singing()
	assert_equal(meep.sprite_index(), 123, "MEEPSINGL")
	var ticks := 0
	while _waves(session).is_empty() and ticks < 60:
		_step(session)
		ticks += 1
	assert_equal(ticks, 25, "the wave after 24.7 ticks")
	assert_equal(sounds, PackedStringArray([Keen3Sounds.MEEP]), "MEEP")
	var wave := _waves(session)[0]
	assert_equal(wave.position, meep.position + Vector2(0, 4), "from its left side, 4 px down")
	assert_true(wave.sprite_index() == 128 or wave.sprite_index() == 129, "128-129")
	_run_until(session, func() -> bool: return session.keen.is_dead)
	assert_true(session.keen.is_dead, "through the wall, it kills Keen")


func test_meep_sings_in_the_air_at_a_ledge() -> void:
	var session := _session_with({Vector2i(16, LEDGE_ROW - 2): 4}, KEEN_CELL, _ledge_rows())
	var meep := session.enemies()[0] as Keen3Meep
	var sang_in_air := false
	var height := 0.0
	for tick in LONG_TICKS:
		_step(session)
		if meep.mode == Keen3Meep.Mode.SINGING and not meep.on_ground:
			if sang_in_air:
				assert_equal(meep.position.y, height, "hangs while it sings")
				break
			sang_in_air = true
			height = meep.position.y
	assert_true(sang_in_air, "sings in the air (the original's bug)")


func test_ninja_jumps_at_keen_when_he_is_near() -> void:
	var session := _session_with({Vector2i(12, 11): 5})
	session.set_invincible(true)
	var ninja := session.enemies()[0] as Keen3Ninja
	assert_true(ninja.sprite_index() == 77 or ninja.sprite_index() == 78, "faces Keen: 77-78")
	var x := ninja.position.x
	_run_until(session, func() -> bool: return ninja.mode == Keen3Ninja.Mode.JUMPING)
	assert_equal(ninja.mode, Keen3Ninja.Mode.JUMPING, "jumps")
	assert_equal(ninja.sprite_index(), 81, "NINJAJUMPL")
	_step(session)
	assert_true(ninja.position.x < x, "toward Keen")
	_run_until(session, func() -> bool: return ninja.mode == Keen3Ninja.Mode.STANDING)
	assert_equal(ninja.mode, Keen3Ninja.Mode.STANDING, "stands again when it lands")


func test_ninja_stays_when_keen_is_far_above_and_takes_four_shots() -> void:
	var rows := FIELD.duplicate()
	rows[4] = "#####" + rows[4].substr(5)
	var session := _session_with({Vector2i(12, 11): 5}, Vector2i(2, 2), rows)
	var ninja := session.enemies()[0] as Keen3Ninja
	for tick in LONG_TICKS:
		_step(session)
	assert_true(ninja.is_active, "awake")
	assert_equal(ninja.mode, Keen3Ninja.Mode.STANDING, "never jumped")
	for hit in 3:
		ninja.hit_by_shot(session)
	assert_true(not ninja.is_dead, "alive after 3 shots")
	ninja.hit_by_shot(session)
	assert_true(ninja.is_dead, "dead after 4")
	_assert_dying_frames(session, ninja, [83, 84])


func test_foob_gets_scared_and_flees_to_a_wall() -> void:
	var session := _session_with({Vector2i(10, 13): 6})
	var foob := session.enemies()[0] as Keen3Foob
	var sounds := _sounds_of(session)
	_run_until(session, func() -> bool: return foob.mode == Keen3Foob.Mode.SCARED)
	assert_equal(foob.mode, Keen3Foob.Mode.SCARED, "scared on screen")
	assert_true(sounds.has(Sound.Id.YORP_SCREAM), "YORPSCREAM")
	assert_true(foob.sprite_index() == 97 or foob.sprite_index() == 98, "97-98")
	var scared := 0
	while foob.mode == Keen3Foob.Mode.SCARED and scared < 60:
		_step(session)
		scared += 1
	assert_true(scared == 10 or scared == 11, "yells ~10 ticks: %d" % scared)
	assert_equal(foob.facing, 1, "runs away from Keen")
	var x := foob.position.x
	_step(session)
	assert_true(is_equal_approx(foob.position.x - x, 76 * SUB), "at 76/32 (250)")
	_run_until(session, func() -> bool: return foob.speed == 0.0)
	assert_true(foob.hitbox().end.x > _cell_left(31) - 1.0, "stopped at the wall")
	assert_equal(foob.facing, 1, "facing the wall")


func test_foob_dies_when_keen_touches_it() -> void:
	var session := _session_with({Vector2i(2, 13): 6})
	var foob := session.enemies()[0] as Keen3Foob
	var sounds := _sounds_of(session)
	_run_until(session, func() -> bool: return foob.is_dead)
	assert_true(foob.is_dead, "the Foob died")
	assert_true(not session.keen.is_dead, "Keen did not")
	assert_true(sounds.has(Sound.Id.YORP_SCREAM), "YORPSCREAM")
	_assert_dying_frames(session, foob, [99, 100, 101])


## The field with a ledge in row [constant LEDGE_ROW].
func _ledge_rows() -> PackedStringArray:
	var rows := FIELD.duplicate()
	var row := rows[LEDGE_ROW]
	var length := LEDGE_TO - LEDGE_FROM + 1
	rows[LEDGE_ROW] = row.substr(0, LEDGE_FROM) + "#".repeat(length) + row.substr(LEDGE_TO + 1)
	return rows


## A session in [param rows] with the enemies of [param infos] and Keen at
## [param keen_cell], standing on the floor. The view is the whole level,
## so every enemy is awake.
func _session_with(
	infos: Dictionary, keen_cell := KEEN_CELL, rows: PackedStringArray = FIELD
) -> Keen3LevelSession:
	var typed: Dictionary[Vector2i, int] = {}
	for cell in infos:
		typed[cell] = infos[cell]
	var level := Fixtures.create_level(rows, typed)
	var session := Keen3LevelSession.started(
		level, Fixtures.level_properties(), Keen3Inventory.new(), Fixtures.cell_top_left(keen_cell)
	)
	var whole: Array[Rect2] = [Rect2(Vector2.ZERO, Vector2(level.width, level.height) * TILE)]
	session.view_rects = whole
	return session


func _step(session: Keen3LevelSession, input: KeenInput = null) -> void:
	session.step(input if input != null else KeenInput.new())


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


## The pixel x of the left side of [param column] (counted without the
## border).
func _cell_left(column: int) -> float:
	return Fixtures.cell_top_left(Vector2i(column, 0)).x


func _fireballs(session: Keen3LevelSession) -> Array[Keen3Fireball]:
	var found: Array[Keen3Fireball] = []
	for actor in session.actors:
		if actor is Keen3Fireball:
			found.append(actor)
	return found


func _waves(session: Keen3LevelSession) -> Array[Keen3SoundWave]:
	var found: Array[Keen3SoundWave] = []
	for actor in session.actors:
		if actor is Keen3SoundWave:
			found.append(actor)
	return found


func _sounds_of(session: Keen3LevelSession) -> Array[Sound.Id]:
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	return sounds


func _keen3_sounds_of(session: Keen3LevelSession) -> PackedStringArray:
	var sounds := PackedStringArray()
	session.keen3_sound_played.connect(func(name: String) -> void: sounds.append(name))
	return sounds


## [param enemy] (just killed) shows [param frames] in turn and keeps the
## last.
func _assert_dying_frames(session: Keen3LevelSession, enemy: Keen3Enemy, frames: Array) -> void:
	var seen := []
	for tick in 60:
		var sprite := enemy.sprite_index()
		if seen.is_empty() or seen[-1] != sprite:
			seen.append(sprite)
		_step(session)
	assert_equal(seen, frames, "dying frames")
