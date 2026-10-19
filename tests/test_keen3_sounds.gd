extends "res://tests/test_case.gd"
## Tests for Keen 3's sounds without Keen 3's files (milestone C8): the
## shared sound rate of 145.65 Hz, Keen 3's own speaker ([Keen3Sounds]:
## priorities, lengths, giving way to the shared player as one speaker),
## and the sounds that Keen 3 plays where Keen 1's code plays another or
## none (a pogo bounce sounds as a jump, walking off a ledge, bumping a wall
## in the air, the mother's spit before its splash). The real sound block of
## KEEN3.EXE is checked in tests/test_keen3_menus_data.gd.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const TILE := EgaGraphics.TILE_SIZE
const SETTLE_TICKS := 30
## The original's numbers: the PC timer's clock and the divisor of the game.
const TIMER_CLOCK := 1193182.0
const GAME_DIVISOR := 8192.0
const PRIORITIES := {
	"ANKH": [255, 10],
	"MEEP": [200, 4],
	"MORTIMER": [255, 291],
	"FOOTSLAM": [250, 6],
	"SHOTHIT": [200, 3],
	"KEENSLEFT": [255, 40],
	"GOTITEMSND": [190, 5],
}
## A floor in row 9, a wall at column 6 from row 5 down, a step down from
## the ledge (rows 6-9, columns 10-15) to the floor.
const FIELD: PackedStringArray = [
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#..................#",
	"#.....#............#",
	"#.....#...######...#",
	"#.....#...######...#",
	"#.....#...######...#",
	"####################",
]


func test_sounds_play_at_145_65_hz() -> void:
	assert_true(
		is_equal_approx(SoundFile.STEPS_PER_SECOND, TIMER_CLOCK / GAME_DIVISOR), "1193182 / 8192"
	)
	assert_true(absf(SoundFile.STEPS_PER_SECOND - 145.65) < 0.01, "145.65 Hz")


func test_keen_3_sounds_know_priorities_and_lengths() -> void:
	var sounds := Keen3Sounds.new()
	sounds.load_sounds(Fixtures.sound_file(PRIORITIES))
	for sound_name in Keen3Sounds.NAMES:
		assert_true(sounds.has_sound(sound_name), sound_name)
	assert_equal(sounds.priority_of(Keen3Sounds.FOOTSLAM), 250, "FOOTSLAM")
	assert_equal(sounds.priority_of("SHOTHIT"), 200, "a shared sound")
	assert_equal(sounds.priority_of("NOSUCHSND"), -1, "none")
	var mortimer := 291 / SoundFile.STEPS_PER_SECOND
	assert_true(is_equal_approx(sounds.seconds(Keen3Sounds.MORTIMER), mortimer), "MORTIMER")
	var keens_left := 40 / SoundFile.STEPS_PER_SECOND
	assert_true(is_equal_approx(sounds.seconds_of("KEENSLEFT"), keens_left), "keensleft")
	assert_equal(sounds.seconds("KEENSLEFT"), 0.0, "not one of Keen 3's own")
	assert_true(sounds.give_way_to("GOTITEMSND"), "nothing plays: a shared sound may")
	sounds.free()


func test_without_files_keen_3_sounds_stay_silent() -> void:
	var sounds := Keen3Sounds.new()
	sounds.load_sounds(null)
	assert_true(not sounds.has_sound(Keen3Sounds.ANKH), "no ANKH")
	assert_equal(sounds.seconds(Keen3Sounds.MORTIMER), 0.0, "Mortimer does not wait")
	assert_equal(sounds.priority_of(Keen3Sounds.MEEP), -1, "no priority")
	assert_true(not sounds.play(Keen3Sounds.MEEP), "nothing starts")
	sounds.free()


func test_a_pogo_bounce_sounds_as_a_jump() -> void:
	assert_equal(Keen3Body.sound_for(Sound.Id.KEEN_POGO), Sound.Id.KEEN_JUMP, "KEENJUMPSND")
	assert_equal(Keen3Body.sound_for(Sound.Id.KEEN_LAND), Sound.Id.KEEN_LAND, "others stay")
	var session := Fixtures.start_session(FIELD, Vector2i(3, 7))
	var sounds := _sounds_of(session)
	_settle(session)
	sounds.clear()
	session.step(KeenInput.create(0, false, true, false))
	for tick in SETTLE_TICKS * 2:
		session.step(KeenInput.new())
	assert_true(not sounds.has(Sound.Id.KEEN_POGO), "never KEENPOGOSND")
	assert_true(sounds.has(Sound.Id.KEEN_JUMP), "KEENJUMPSND on each bounce")


func test_walking_off_a_ledge_plummets() -> void:
	var session := Fixtures.start_session(FIELD, Vector2i(14, 4))
	var sounds := _sounds_of(session)
	_settle(session)
	assert_true(not sounds.has(Sound.Id.PLUMMET), "standing on the ledge")
	for tick in SETTLE_TICKS:
		session.step(KeenInput.create(1, false, false, false))
		if session.keen.state == KeenBody.State.FALLING:
			break
	assert_equal(session.keen.state, KeenBody.State.FALLING, "walked off")
	assert_equal(sounds.count(Sound.Id.PLUMMET), 1, "PLUMMETSND once")
	_settle(session)
	assert_equal(sounds.count(Sound.Id.PLUMMET), 1, "not again on landing")


func test_bumping_a_wall_in_the_air_sounds_every_32_clock_ticks() -> void:
	var session := Fixtures.start_session(FIELD, Vector2i(5, 7))
	var sounds := _sounds_of(session)
	_settle(session)
	sounds.clear()
	var bumps: Array[int] = []
	# A high jump (the button held) against the wall.
	for tick in SETTLE_TICKS * 2:
		var before := sounds.count(Sound.Id.KEEN_BLOCKED)
		session.step(KeenInput.create(1, true, false, false))
		if sounds.count(Sound.Id.KEEN_BLOCKED) > before:
			bumps.append(tick)
		if tick > 0 and session.keen.state == KeenBody.State.STANDING:
			break
	assert_true(bumps.size() >= 2, "bumps while in the air: %s" % [bumps])
	if bumps.size() >= 2:
		assert_equal(bumps[1] - bumps[0], ceili(Keen3Body.AIR_BUMP_TICKS), "13.2 ticks apart")


func test_no_plummet_while_riding_a_platform_down() -> void:
	var rows := PackedStringArray()
	for row in 15:
		rows.append("#".repeat(32) if row == 0 or row == 14 else "#" + ".".repeat(30) + "#")
	var session := _session_with(rows, {Vector2i(10, 6): 10}, Vector2i(10, 2))
	var platform := session.enemies()[0] as Keen3Platform
	session.keen.position = Vector2(
		platform.position.x + 8, platform.top() - KeenPhysics.SPRITE_SIZE.y - 1
	)
	var sounds := _sounds_of(session)
	for tick in 300:
		session.step(KeenInput.new())
	assert_true(session.is_riding(session.keen), "rides")
	assert_true(not sounds.has(Sound.Id.PLUMMET), "no PLUMMETSND on a platform")


func test_the_mother_spits_before_the_splash() -> void:
	# She stands against the wall at the left: her fireball starts in it.
	var session := _session_with(FIELD, {Vector2i(1, 7): 3}, Vector2i(4, 7))
	var mom := session.enemies()[0] as Keen3Mom
	_settle(session)
	var sounds := _sounds_of(session)
	mom.facing = 1
	mom.start_spitting()
	for tick in SETTLE_TICKS:
		session.step(KeenInput.new())
	var spit := sounds.find(Sound.Id.TANK_FIRE)
	var splash := sounds.find(Sound.Id.SHOT_HIT)
	assert_true(spit >= 0 and splash >= 0, "both: %s" % [sounds])
	assert_true(spit < splash, "TANKFIRE first, then the splash cuts it off")


## A session in [param rows] with the enemies of [param infos] and Keen at
## [param keen_cell]; the view is the whole level.
func _session_with(
	rows: PackedStringArray, infos: Dictionary, keen_cell: Vector2i
) -> Keen3LevelSession:
	var typed: Dictionary[Vector2i, int] = {}
	typed.assign(infos)
	var level := Fixtures.create_level(rows, typed)
	var session := Keen3LevelSession.started(
		level, Fixtures.level_properties(), Keen3Inventory.new(), Fixtures.cell_top_left(keen_cell)
	)
	var whole: Array[Rect2] = [Rect2(Vector2.ZERO, Vector2(level.width, level.height) * TILE)]
	session.view_rects = whole
	return session


## Every sound [param session] plays from now on.
func _sounds_of(session: LevelSession) -> Array[Sound.Id]:
	var sounds: Array[Sound.Id] = []
	session.sound_played.connect(func(sound: Sound.Id) -> void: sounds.append(sound))
	return sounds


func _settle(session: LevelSession) -> void:
	for tick in SETTLE_TICKS:
		session.step(KeenInput.new())
