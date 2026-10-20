extends "res://tests/test_case.gd"
## Tests for Keen himself in a Keen 3 level ([Keen3Body], [Keen3Inventory],
## [Keen3AnkhShield], [Keen3LevelPlay]'s start) in small hand-made levels,
## without Keen 3's files: the start values, the pogo stick from the first
## tick, level 9's later start, dying, and the ankh with its halo. The items,
## doors and exits are in tests/test_keen3_level.gd; see
## tests/keen3_fixtures.gd for the level characters.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const SETTLE_TICKS := 120
const WALK_TICKS := 240
const POGO_TICKS := 2

## Keen starts on the left, standing on the floor in row 14.
const FIELD: PackedStringArray = [
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"##############################",
]
const START_CELL := Vector2i(2, 12)
const FEET_ROW := 13
const FLOOR_ROW := 14


func test_inventory_starts_as_in_keen_3() -> void:
	var inventory := Keen3Inventory.new()
	assert_equal(inventory.lives, 4, "4 lives")
	assert_equal(inventory.charges, 5, "5 charges")
	assert_equal(Keen3Inventory.START_CHARGES, 5, "the constant")
	assert_true(inventory.has_pogo, "the pogo stick from the start")
	assert_equal(inventory.score, 0, "no points")
	assert_equal(inventory.next_extra_life(), 20000, "first extra life at 20,000")


func test_dying_frames_are_22_and_23() -> void:
	var session := _session(FIELD)
	session.keen.kill()
	var frames := {}
	for tick in KeenPhysics.DIE_WAIT_TICKS:
		frames[session.keen.sprite_index()] = true
		session.step(KeenInput.new())
	assert_equal(frames.keys(), [22, 23], "KEENISDEAD1 and 2")


func test_getting_up_after_a_stun_is_frame_30() -> void:
	var keen := _session(FIELD).keen as Keen3Body
	keen.stun(1)
	var frames := {}
	while keen.is_stunned():
		frames[keen.sprite_index()] = true
		keen.step(KeenInput.new())
	assert_equal(frames.keys(), [28, 29, 30], "KEENSICLE1, 2 and KEENMELT")


func test_ankh_protects_from_a_deadly_tile() -> void:
	var session := _session_with_items("...A....XXX.........")
	var keen_3_sounds: PackedStringArray = []
	session.keen3_sound_played.connect(func(name: String) -> void: keen_3_sounds.append(name))
	_run(session, KeenInput.create(1), WALK_TICKS / 2)
	var keen := session.keen as Keen3Body
	assert_true(keen.is_protected(), "protected")
	assert_true(not keen.is_dead, "alive in the fire")
	assert_true(keen.hitbox().position.x > _column_left(11), "walked through the fire")
	assert_equal(keen_3_sounds, PackedStringArray([Keen3Sounds.ANKH]), "ANKH")
	assert_equal(
		session.level.tile_at(Vector2i(3, FEET_ROW) + _border()), Fixtures.ITEM_ROW, "gone"
	)
	assert_equal(session.outcome, LevelSession.Outcome.PLAYING, "still playing")


func test_ankh_does_not_protect_from_falling_out() -> void:
	var rows := FIELD.duplicate()
	rows[FLOOR_ROW] = "#######......#################"
	var session := _session(rows)
	(session.keen as Keen3Body).add_ankh()
	_run_until_over(session, KeenInput.create(1))
	assert_equal(session.outcome, LevelSession.Outcome.DIED, "fell out of the level")


func test_ankh_time_adds_up() -> void:
	var session := _session_with_items("....AA..............")
	_run(session, KeenInput.create(1), WALK_TICKS / 4)
	var keen := session.keen as Keen3Body
	assert_true(keen.ankh_ticks > Keen3Body.ANKH_TICKS, "two ankhs: more than one's time")
	assert_true(keen.ankh_ticks <= 2 * Keen3Body.ANKH_TICKS, "not more than two")
	var halos := session.actors.filter(func(a: Actor) -> bool: return a is Keen3AnkhShield)
	assert_equal(halos.size(), 1, "one halo")
	var body := Keen3Body.spawned(session.collision, Vector2.ZERO)
	body.add_ankh()
	body.add_ankh()
	assert_equal(body.ankh_ticks, 2 * 577, "577 ticks each (Choco: 1400 clock ticks)")


func test_ankh_is_reset_in_every_level() -> void:
	var inventory := Keen3Inventory.new()
	var first := Fixtures.start_session(FIELD, START_CELL, inventory)
	(first.keen as Keen3Body).add_ankh()
	var again := Fixtures.start_session(FIELD, START_CELL, inventory)
	assert_equal((again.keen as Keen3Body).ankh_ticks, 0, "no ankh in a new attempt")


func test_ankh_counts_down_only_while_playing() -> void:
	var session := _session(FIELD)
	var keen := session.keen as Keen3Body
	keen.add_ankh()
	_run(session, KeenInput.new(), 100)
	assert_equal(keen.ankh_ticks, Keen3Body.ANKH_TICKS - 100, "one per tick")
	session.outcome = LevelSession.Outcome.COMPLETED
	_run(session, KeenInput.new(), 100)
	assert_equal(keen.ankh_ticks, Keen3Body.ANKH_TICKS - 100, "not after the level")
	session.outcome = LevelSession.Outcome.PLAYING
	_run(session, KeenInput.new(), Keen3Body.ANKH_TICKS)
	assert_equal(keen.ankh_ticks, 0, "over")
	assert_true(not keen.is_protected(), "no protection left")


func test_ankh_prevents_the_stun() -> void:
	var session := _session(FIELD)
	var keen := session.keen as Keen3Body
	keen.add_ankh()
	keen.stun(1)
	assert_true(not keen.is_stunned(), "not stunned with the ankh")
	var plain := _session(FIELD).keen as Keen3Body
	plain.stun(1)
	assert_true(plain.is_stunned(), "stunned without it")


func test_ankh_shows_seconds_as_the_status_screen() -> void:
	var body := Keen3Body.spawned(_session(FIELD).collision, Vector2.ZERO)
	body.add_ankh()
	assert_equal(body.ankh_seconds(), 9, "a fresh ankh shows 9 (Choco)")
	body.ankh_ticks = 0
	assert_equal(body.ankh_seconds(), 0, "none")


func test_halo_frames_and_blink() -> void:
	var session := _session(FIELD)
	var keen := session.keen as Keen3Body
	assert_equal(keen.halo_sprite(), -1, "no halo without the ankh")
	keen.add_ankh()
	var shield := Keen3AnkhShield.around(keen)
	session.add_actor(shield)
	var early := {}
	var late := {}
	while keen.is_protected():
		session.step(KeenInput.new())
		var frames := late if keen.ankh_ticks <= Keen3Body.ANKH_BLINK_TICKS else early
		frames[shield.sprite_index()] = true
		if keen.is_protected():
			assert_equal(shield.position, keen.position + Vector2(-8, -8), "8 px up and left")
	assert_equal(early.keys(), [61, 62], "GODHALO and BYEHALO in turn")
	assert_true(late.has(-1), "it blinks at the end")
	assert_true(shield.removed, "gone afterwards")
	assert_equal(keen.halo_sprite(), -1, "no halo afterwards")


func test_level_9_takes_the_later_start() -> void:
	var infos: Dictionary[Vector2i, int] = {Vector2i(1, 2): 255, Vector2i(20, 9): 255}
	var level := Fixtures.create_level(FIELD, infos)
	var later := Vector2i(20, 9) + _border()
	assert_equal(level.find_info(255), Vector2i(1, 2) + _border(), "find_info gives the first")
	assert_equal(Keen3LevelPlay.start_cell(level), later, "the last one row by row")
	assert_equal(
		Keen3LevelPlay.start_position(level), Vector2(later * 16) + Vector2(0, 8), "8 px down"
	)
	var plain := Fixtures.create_level(FIELD)
	assert_equal(Keen3LevelPlay.start_cell(plain), plain.playable_rect().position, "none")


func test_pogo_works_from_the_first_tick() -> void:
	var session := Fixtures.start_session(FIELD, START_CELL, Inventory.new())
	_run(session, KeenInput.create(0, false, true), POGO_TICKS)
	assert_true(session.inventory.has_pogo and session.keen.on_pogo, "on the pogo at once")


## A session with [param items] in Keen's row, Keen standing at
## [constant START_CELL].
func _session_with_items(items: String) -> Keen3LevelSession:
	var rows := FIELD.duplicate()
	rows[FEET_ROW] = items + rows[FEET_ROW].substr(items.length())
	return _session(rows)


## A session with Keen standing on the floor.
func _session(rows: PackedStringArray) -> Keen3LevelSession:
	var session := Fixtures.start_session(rows, START_CELL)
	_run(session, KeenInput.create(0), SETTLE_TICKS)
	return session


func _run(session: LevelSession, input: KeenInput, ticks: int) -> void:
	for tick in ticks:
		session.step(input)


## Runs [param session] until the attempt is over (at most a long while).
func _run_until_over(session: LevelSession, input: KeenInput) -> void:
	for tick in WALK_TICKS * 4:
		if session.outcome != LevelSession.Outcome.PLAYING:
			return
		session.step(input)


func _border() -> Vector2i:
	return Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)


func _column_left(column: int) -> float:
	return (column + LevelData.BORDER_CELLS) * EgaGraphics.TILE_SIZE
