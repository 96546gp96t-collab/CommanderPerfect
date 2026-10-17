extends "res://tests/test_case.gd"
## Tests for the rules that all of Keen 3's enemies share, in small
## hand-made levels without Keen 3's files: Keen 3's stun ([Keen3Body]),
## the ankh against enemies and their shots, no points for enemies, dying
## frames, waking and sleeping ([Keen3ActiveArea]), Keen's shot and the
## waves, the chances, and the HUD's item pictures ([Keen3Hud]). The
## enemies one by one are in tests/test_keen3_enemies.gd.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const SUB := KeenPhysics.SUBPIXEL
const TILE := EgaGraphics.TILE_SIZE
const LONG_TICKS := 600
const ORIGINAL_VIEW := Vector2(320, 200)

## A floor in row 14, walls at both ends; 60 columns.
const FIELD: PackedStringArray = [
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"#..........................................................#",
	"############################################################",
]
const KEEN_CELL := Vector2i(4, 12)


func test_stun_lies_165_ticks_then_gets_up_for_16_5() -> void:
	var keen := _session_with({}).keen as Keen3Body
	keen.stun(1)
	var lying := 0
	var getting_up := 0
	var frames := {}
	while keen.is_stunned() and lying + getting_up < LONG_TICKS:
		var sprite := keen.sprite_index()
		frames[sprite] = true
		if sprite == Keen3Body.SPRITE_MELT:
			getting_up += 1
		else:
			lying += 1
		keen.step(KeenInput.create(1, true, true, true))
	assert_equal(lying, 165, "lies 165 ticks (400 clock ticks)")
	assert_true(getting_up == 16 or getting_up == 17, "gets up 16.5 ticks: %d" % getting_up)
	assert_equal(frames.keys(), [28, 29, 30], "KEENSICLE1, 2, KEENMELT")
	assert_true(not keen.fired, "no shot while stunned")
	assert_equal(keen.state, KeenBody.State.STANDING, "standing again")


func test_stunned_keen_slides_to_a_stop() -> void:
	var keen := _session_with({}).keen as Keen3Body
	var x := keen.position.x
	keen.stun_with(Vector2(-76 * SUB, 0))
	assert_true(is_equal_approx(keen.velocity.x, -66.7 * SUB), "cut to 120")
	var ticks := 0
	while keen.velocity.x != 0.0 and ticks < 60:
		keen.step(KeenInput.new())
		ticks += 1
	assert_true(ticks == 16 or ticks == 17, "stops after ~16.5 ticks: %d" % ticks)
	var slid := x - keen.position.x
	assert_true(slid > 15.0 and slid < 20.0, "slides ~17 px: %f" % slid)


func test_a_shot_kills_a_stunned_keen() -> void:
	var session := _session_with({})
	var keen := session.keen as Keen3Body
	keen.stun(1)
	_step(session)
	var start := Vector2(keen.position.x + 40, keen.position.y + 6)
	session.add_actor(Keen3Fireball.spat(session, start, -1))
	_run_until(session, func() -> bool: return keen.is_dead)
	assert_true(keen.is_dead, "the fireball kills him")


func test_a_grunt_kills_a_stunned_keen() -> void:
	var session := _session_with({Vector2i(8, 12): 1})
	var keen := session.keen as Keen3Body
	keen.stun(1)
	_run_until(session, func() -> bool: return keen.is_dead)
	assert_true(keen.is_dead, "still deadly")


func test_ankh_blocks_the_stun_and_every_enemy_death() -> void:
	for info in [1, 2, 5]:
		var session := _session_with({Vector2i(7, 12): info})
		var keen := session.keen as Keen3Body
		keen.add_ankh()
		for tick in 120:
			_step(session)
		assert_true(not keen.is_dead, "alive with the ankh (info %d)" % info)
		assert_true(not keen.is_stunned(), "not stunned with the ankh (info %d)" % info)
	var session := _session_with({})
	var keen := session.keen as Keen3Body
	keen.add_ankh()
	var start := Vector2(keen.position.x + 40, keen.position.y + 6)
	var fireball := Keen3Fireball.spat(session, start, -1)
	session.add_actor(fireball)
	session.add_actor(Keen3SoundWave.sent(start, -1))
	for tick in 60:
		_step(session)
	assert_true(not keen.is_dead, "fireball and wave do not kill him")
	assert_true(fireball.is_splashing or fireball.removed, "the fireball splashed on him")


func test_enemies_give_no_points() -> void:
	for info in [1, 2, 3, 4, 5, 6]:
		var session := _session_with({Vector2i(8, 12): info})
		session.set_invincible(true)
		var enemy := session.enemies()[0]
		for hit in 5:
			enemy.hit_by_shot(session)
		for tick in 60:
			_step(session)
		assert_true(enemy.is_dead, "info %d dead" % info)
		assert_equal(session.inventory.score, 0, "no points for info %d" % info)


func test_a_dying_frame_lasts_16_5_ticks_and_the_corpse_falls() -> void:
	var session := _session_with({Vector2i(10, 6): 6})
	var foob := session.enemies()[0] as Keen3Foob
	var y := foob.position.y
	foob.die()
	var changes := []
	var sprite := foob.sprite_index()
	for tick in 60:
		_step(session)
		if foob.sprite_index() != sprite:
			sprite = foob.sprite_index()
			changes.append(tick + 1)
	assert_equal(changes, [17, 33], "99, then 100 and 101 every 16.5 ticks")
	assert_true(foob.position.y > y, "the corpse falls")


func test_enemies_wake_and_sleep_by_the_original_rule() -> void:
	var view := Rect2(Vector2(0, 0), ORIGINAL_VIEW)
	var views: Array[Rect2] = [view]
	assert_true(Keen3ActiveArea.wakes(views, _cell(22, 11)), "wakes 22 tiles right")
	assert_true(not Keen3ActiveArea.wakes(views, _cell(23, 0)), "not 23")
	assert_true(not Keen3ActiveArea.wakes(views, _cell(5, 12)), "not 12 down")
	assert_true(not Keen3ActiveArea.wakes(views, _cell(-2, 5)), "not 2 left")
	assert_true(Keen3ActiveArea.wakes(views, _cell(-1, -1)), "1 left and up")
	assert_true(Keen3ActiveArea.keeps_awake(views, _cell(28, 18)), "stays at 28, 18")
	assert_true(not Keen3ActiveArea.keeps_awake(views, _cell(29, 0)), "sleeps at 29")
	assert_true(not Keen3ActiveArea.keeps_awake(views, _cell(0, 19)), "and at 19 down")
	assert_true(Keen3ActiveArea.keeps_awake(views, _cell(-8, -8)), "stays at -8")
	assert_true(not Keen3ActiveArea.keeps_awake(views, _cell(-9, 0)), "sleeps at -9")
	assert_true(Keen3ActiveArea.on_screen(views, _cell(18, 11)), "on screen")
	assert_true(not Keen3ActiveArea.on_screen(views, _cell(0, 5)), "not in the first column")


func test_widescreen_keeps_the_margins() -> void:
	var views: Array[Rect2] = [Rect2(Vector2(0, 0), Vector2(426, 240))]
	assert_true(Keen3ActiveArea.wakes(views, _cell(29, 14)), "27 tiles + 3, 15 rows")
	assert_true(not Keen3ActiveArea.wakes(views, _cell(30, 0)), "not further")
	assert_true(Keen3ActiveArea.keeps_awake(views, _cell(35, 21)), "stays 27 + 8")
	assert_true(not Keen3ActiveArea.keeps_awake(views, _cell(36, 0)), "sleeps beyond")
	var two: Array[Rect2] = [
		Rect2(Vector2.ZERO, ORIGINAL_VIEW), Rect2(Vector2(800, 0), ORIGINAL_VIEW)
	]
	assert_true(Keen3ActiveArea.wakes(two, Vector2(1000, 50)), "either view of two")


func test_a_sleeping_enemy_does_nothing_and_a_far_corpse_goes() -> void:
	var session := _session_with({Vector2i(40, 12): 1})
	var grunt := session.enemies()[0] as Keen3Grunt
	var far_view := Rect2(Vector2(0, 100), ORIGINAL_VIEW)
	_use_view(session, far_view)
	var x := grunt.position.x
	for tick in 30:
		_step(session)
	assert_true(not grunt.is_active and grunt.position.x == x, "asleep, it stays put")
	_use_view(session, Rect2(Vector2(grunt.position.x - 160, 100), ORIGINAL_VIEW))
	_step(session)
	assert_true(grunt.is_active, "wakes in view")
	grunt.die()
	_use_view(session, far_view)
	_step(session)
	assert_true(grunt.removed, "a corpse far away is deleted")


func test_shots_and_waves_far_away_are_deleted() -> void:
	var session := _session_with({})
	_use_view(session, Rect2(Vector2.ZERO, ORIGINAL_VIEW))
	var wave := Keen3SoundWave.sent(Vector2(28 * TILE, 5 * TILE), 1)
	var shot := Keen3Shot.fired(Vector2(20 * TILE, 5 * TILE), 1)
	session.add_actor(wave)
	session.add_actor(shot)
	for tick in 80:
		_step(session)
	assert_true(not session.actors.has(wave), "the wave is gone")
	assert_true(not session.actors.has(shot), "the shot is gone")


func test_a_wave_goes_when_it_leaves_the_playable_area() -> void:
	var session := _session_with({})
	var left := float(LevelMap.playable_pixels(session.level).position.x)
	var wave := Keen3SoundWave.sent(Vector2(left + 3, 5 * TILE), -1)
	session.add_actor(wave)
	_step(session)
	assert_true(session.actors.has(wave), "still inside")
	_step(session)
	assert_true(not session.actors.has(wave), "gone at the edge, never over the border")


func test_keen_shot_splashes_on_a_wave_that_flies_on() -> void:
	var session := _session_with({})
	session.set_invincible(true)
	var keen := session.keen
	var wave := Keen3SoundWave.sent(Vector2(keen.position.x + 80, keen.position.y + 4), -1)
	session.add_actor(wave)
	_step(session, KeenInput.create(0, false, false, true))
	var shot: Keen3Shot = null
	for actor in session.actors:
		if actor is Keen3Shot:
			shot = actor
	_run_until(session, func() -> bool: return shot.is_splashing)
	assert_true(shot.is_splashing, "Keen's shot splashed")
	var x := wave.position.x
	_step(session)
	assert_true(is_equal_approx(x - wave.position.x, 60.7 * SUB), "the wave flies on at 200")


func test_keen_shot_speed_and_splash() -> void:
	var session := _session_with({})
	var shot := Keen3Shot.fired(session.keen.position + Vector2(20, 9), 1)
	session.add_actor(shot)
	var x := shot.position.x
	_step(session)
	assert_true(is_equal_approx(shot.position.x - x, 121 * SUB), "121/32 (400)")
	shot.splash()
	var ticks := 0
	while not shot.removed and ticks < 30:
		shot.step(session)
		ticks += 1
	assert_equal(ticks, Keen3Shot.SPLASH_TICKS_KEEN_3, "the splash stays 8 ticks")


func test_enemy_shots_hurt_only_grunts_and_foobs() -> void:
	for info in [2, 4, 5]:
		var session := _session_with({Vector2i(10, 12): info}, Vector2i(40, 12))
		var enemy := session.enemies()[0]
		var start := Vector2(enemy.hitbox().end.x - 2, enemy.hitbox().position.y + 2)
		var fireball := Keen3Fireball.spat(session, start, -1)
		session.add_actor(fireball)
		_run_until(session, func() -> bool: return not fireball.is_flying())
		assert_true(not enemy.is_dead, "info %d unharmed" % info)
		assert_true(fireball.position.x > _cell_left(2), "the fireball splashed on info %d" % info)
	var session := _session_with({Vector2i(10, 13): 6}, Vector2i(40, 12))
	var foob := session.enemies()[0] as Keen3Foob
	session.add_actor(Keen3SoundWave.sent(foob.position + Vector2(4, 0), -1))
	for tick in 40:
		_step(session)
	assert_true(not foob.is_dead, "a wave does not kill a Foob")


func test_meep_starts_8_pixels_down_in_its_cell() -> void:
	var meep := Keen3Meep.spawned(Vector2(32, 48), 1)
	assert_equal(meep.position, Vector2(32, 56), "8 px below the top of its cell")


func test_chance_per_tick() -> void:
	var session := _session_with({})
	var hits := 0
	var rolls := 100000
	for roll in rolls:
		if Keen3Enemy.chance(session, 2):
			hits += 1
	var rate := hits / float(rolls)
	assert_true(absf(rate - 0.019) < 0.002, "chance 2 is ~19 in 1000 per tick: %f" % rate)


func test_hud_leaves_out_the_row_background() -> void:
	var background := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	background.fill(Color.CYAN)
	var tile := background.duplicate() as Image
	tile.fill_rect(Rect2i(4, 4, 8, 8), Color.RED)
	tile.fill_rect(Rect2i(6, 6, 4, 4), Color.CYAN)
	var cleared := Keen3Hud.without_row_background(tile, background)
	assert_equal(cleared.get_pixel(0, 0).a, 0.0, "the row's colour at the edge is gone")
	assert_equal(cleared.get_pixel(5, 5), Color.RED, "the item stays")
	assert_equal(cleared.get_pixel(7, 7), Color.CYAN, "the colour inside the item stays")


func _session_with(infos: Dictionary, keen_cell := KEEN_CELL) -> Keen3LevelSession:
	var typed: Dictionary[Vector2i, int] = {}
	for cell in infos:
		typed[cell] = infos[cell]
	var level := Fixtures.create_level(FIELD, typed)
	var session := Keen3LevelSession.started(
		level, Fixtures.level_properties(), Keen3Inventory.new(), Fixtures.cell_top_left(keen_cell)
	)
	_use_view(session, Rect2(Vector2.ZERO, Vector2(level.width, level.height) * TILE))
	return session


func _use_view(session: Keen3LevelSession, view: Rect2) -> void:
	var views: Array[Rect2] = [view]
	session.view_rects = views


func _step(session: Keen3LevelSession, input: KeenInput = null) -> void:
	session.step(input if input != null else KeenInput.new())


func _run_until(session: Keen3LevelSession, done: Callable) -> void:
	for tick in LONG_TICKS:
		if done.call():
			return
		_step(session)


## The top left of [param column], [param row] in level pixels.
func _cell(column: int, row: int) -> Vector2:
	return Vector2(column, row) * TILE


func _cell_left(column: int) -> float:
	return Fixtures.cell_top_left(Vector2i(column, 0)).x
