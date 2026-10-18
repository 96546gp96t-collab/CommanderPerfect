extends "res://tests/test_case.gd"
## Tests for Mortimer's Mangling Machine ([Keen3Machine] and its parts) in a
## hand-made level 16 (tests/keen3_machine_fixtures.gd), without Keen 3's
## files: the arms' steps and turns, the legs' steps and FOOTSLAM with its
## wait, the sparks and the heart (+1000, the border flash), the sixth spark
## stopping the arms and its sweep taking away tile 611, the heart stopping
## the legs, removing every sprite, its sweep, and the level done 181 ticks
## after the shot.

const Machine := preload("res://tests/keen3_machine_fixtures.gd")
## Enough ticks for an arm to go down and up again.
const ARM_CYCLE_TICKS := 160
const SIDE_SWEEP_DONE_TICKS := 160
const BODY_SWEEP_DONE_TICKS := 140


func test_the_parts_are_found() -> void:
	var session := Machine.session()
	var machine := session.machine
	assert_true(machine != null, "the level has a machine")
	if machine == null:
		return
	assert_equal(machine.arms.size(), 2, "two arms")
	assert_equal(machine.legs.size(), 2, "two legs")
	assert_equal(_count(session, Keen3Spark), 6, "six sparks")
	assert_equal(_count(session, Keen3Heart), 1, "one heart")
	var heart := _first(session, Keen3Heart)
	assert_equal(heart.position, Vector2(Machine.HEART * 16), "the heart in its cell")
	assert_true(machine.legs[0].is_left and not machine.legs[1].is_left, "17 left, 18 right")


func test_sparks_and_heart_flicker() -> void:
	var session := Machine.session()
	var spark := _first(session, Keen3Spark) as Keen3Spark
	var heart := _first(session, Keen3Heart) as Keen3Heart
	var spark_frames := {}
	var heart_frames := []
	for tick in 40:
		spark_frames[spark.sprite_index()] = true
		heart_frames.append(heart.sprite_index())
		session.step(KeenInput.new())
	assert_equal(spark_frames.keys().size(), 4, "sprites 114-117")
	assert_true(spark_frames.has(114) and spark_frames.has(117), "from 114 to 117")
	assert_equal(heart_frames[0], 146, "HEART1 first")
	assert_equal(heart_frames[10], 147, "HEART2 after 9.9 ticks")
	assert_equal(heart_frames[20], 146, "and back")


func test_an_arm_goes_down_turns_and_comes_up() -> void:
	var session := Machine.session()
	var arm := session.machine.arms[0]
	var rows := _arm_rows(session, arm, ARM_CYCLE_TICKS)
	assert_equal(rows.slice(0, 7), [10, 11, 12, 13, 14, 15, 16], "down a tile at a time")
	assert_equal(rows.slice(7, 13), [15, 14, 13, 12, 11, 10], "then up to the top")
	assert_equal(rows[13], 11, "and down again")


func test_an_arm_moves_faster_down_than_up() -> void:
	var session := Machine.session()
	var arm := session.machine.arms[0]
	var times := _arm_move_ticks(session, arm, ARM_CYCLE_TICKS)
	# Down every 6.2 ticks (6 moves in 31 ticks), up every 16.5.
	assert_equal(times[0], 1, "the first move on the first tick")
	assert_equal(times[5] - times[0], 31, "five steps down take 31 ticks")
	var up_start: int = times[6]
	assert_equal(times[11] - up_start, 83, "five steps up take 82.5 ticks")
	assert_true(times[6] - times[5] >= 6 + 6, "the turn at the bottom takes a step")


func test_an_arm_draws_its_shaft_and_claws() -> void:
	var session := Machine.session()
	var arm := session.machine.arms[0]
	session.step(KeenInput.new())
	var level := session.level
	assert_equal(arm.cell, Vector2i(6, 11), "one tile down")
	assert_equal(level.tile_at(Vector2i(6, 10)), Machine.SHAFT, "the shaft above")
	assert_equal(level.tile_at(Vector2i(6, 11)), Machine.SHAFT, "the shaft")
	for row in 3:
		assert_equal(level.tile_at(Vector2i(5, 11 + row)), Machine.CLAWS[row], "left claw")
		assert_equal(level.tile_at(Vector2i(7, 11 + row)), Machine.CLAWS[row], "right claw")
	assert_equal(level.tile_at(Vector2i(5, 10)), Machine.EMPTY, "cleared where it was")
	assert_equal(level.tile_at(Vector2i(6, 12)), Machine.EMPTY, "nothing under the shaft")


func test_the_right_arm_starts_at_the_bottom() -> void:
	var session := Machine.session()
	var arm := session.machine.arms[1]
	var rows := _arm_rows(session, arm, 60)
	assert_equal(rows[0], 16, "at the bottom")
	assert_equal(rows[1], 15, "so it turns up first")


func test_going_up_clears_below() -> void:
	var session := Machine.session()
	var arm := session.machine.arms[1]
	for tick in 40:
		if arm.cell.y != Machine.RIGHT_ARM.y:
			break
		session.step(KeenInput.new())
	var level := session.level
	assert_equal(arm.cell.y, Machine.RIGHT_ARM.y - 1, "one up")
	assert_equal(level.tile_at(Vector2i(18, 16)), Machine.EMPTY, "the old shaft cell is empty")
	assert_equal(level.tile_at(Vector2i(17, 18)), Machine.EMPTY, "the old claw bottom too")
	assert_equal(level.tile_at(Vector2i(17, 17)), Machine.CLAWS[2], "claws one higher")
	assert_equal(level.tile_at(Vector2i(18, 14)), Machine.SHAFT, "the shaft above stays")


func test_the_left_leg_starts_up() -> void:
	var session := Machine.session()
	var leg := session.machine.legs[0]
	session.step(KeenInput.new())
	assert_equal(leg.cell, Vector2i(11, 17), "one tile up")
	var level := session.level
	for index in 4:
		assert_equal(level.tile_at(Vector2i(8 + index, 17)), Machine.FOOT[index], "the foot")
		assert_equal(level.tile_at(Vector2i(8 + index, 18)), Machine.EMPTY, "cleared below")


func test_a_leg_steps_up_to_the_body_and_down_again() -> void:
	var session := Machine.session()
	var leg := session.machine.legs[0]
	var rows := [leg.cell.y]
	var moves := []
	for tick in range(1, 120):
		session.step(KeenInput.new())
		if leg.cell.y != rows[-1]:
			rows.append(leg.cell.y)
			moves.append(tick)
	assert_equal(rows.slice(0, 7), [18, 17, 16, 15, 16, 17, 18], "up to under the body and down")
	assert_equal(moves[2] - moves[0], 29, "a step every 14.4 ticks")
	assert_equal(moves[3] - moves[2], 29, "the turn under the body takes a step")
	var level := session.level
	assert_equal(level.tile_at(Vector2i(11, 16)), Machine.SHAFT, "the shaft is drawn again")


func test_footslam_and_the_wait() -> void:
	var session := Machine.session()
	var leg := session.machine.legs[1]
	var slams := []
	session.keen3_sound_played.connect(
		func(sound: String) -> void:
			if sound == Keen3Sounds.FOOTSLAM:
				slams.append(sound)
	)
	session.step(KeenInput.new())
	assert_equal(slams.size(), 1, "the right foot is on the floor: FOOTSLAM at once")
	assert_equal(leg.cell, Machine.RIGHT_LEG, "it stays")
	var waited := 1
	while leg.cell == Machine.RIGHT_LEG and waited < 200:
		session.step(KeenInput.new())
		waited += 1
	# The slam on tick 1, then 82 + 14.4 ticks: up on tick 98.
	assert_equal(waited, 98, "82 ticks and the turn's step, then up")
	assert_equal(leg.cell, Machine.RIGHT_LEG + Vector2i.UP, "one tile up")


func test_a_spark_shot_gives_1000_and_a_border_flash() -> void:
	var session := Machine.session()
	var flashes := [0]
	session.border_flashed.connect(func() -> void: flashes[0] += 1)
	var spark := _spark_at(session, Vector2i(9, 6))
	_shoot_at(session, spark.position, 30)
	assert_true(spark.removed, "the spark is gone")
	assert_equal(_count(session, Keen3Spark), 5, "five left")
	assert_equal(session.inventory.score, 1000, "+1000")
	assert_equal(flashes[0], 1, "the border flashes")
	assert_true(not session.machine.arms_stopped(), "the arms go on")


func test_the_sixth_spark_stops_the_arms_and_sweeps() -> void:
	var session := Machine.session()
	for tick in 20:
		session.step(KeenInput.new())
	_destroy_sparks(session)
	var machine := session.machine
	assert_equal(machine.sparks_destroyed, 6, "six sparks")
	assert_equal(session.inventory.score, 6000, "6 x 1000")
	assert_true(machine.arms_stopped(), "both arms stop")
	var stopped_at := machine.arms[0].cell
	var splashes := [0]
	var hits := [0]
	session.sound_played.connect(
		func(sound: Sound.Id) -> void: hits[0] += int(sound == Sound.Id.SHOT_HIT)
	)
	for tick in SIDE_SWEEP_DONE_TICKS:
		session.step(KeenInput.new())
		splashes[0] = maxi(splashes[0], _count(session, Keen3Shot))
	assert_equal(machine.arms[0].cell, stopped_at, "where they stood")
	for cell in Machine.BLOCKS:
		assert_equal(session.level.tile_at(cell), Machine.EMPTY, "611 is gone at %s" % cell)
	for column in Keen3Machine.SIDE_SWEEP_COLUMNS:
		for row in range(7, 19):
			assert_equal(session.level.tile_at(Vector2i(column, row)), Machine.EMPTY, "swept")
	assert_true(splashes[0] > 0, "with splashes")
	assert_true(hits[0] > 0, "and SHOTHIT")


func test_the_side_sweep_takes_a_row_every_12_4_ticks() -> void:
	var sweep := Keen3MachineSweep.across(
		Keen3Machine.SIDE_SWEEP_COLUMNS, Keen3Machine.SIDE_SWEEP_ROWS, Keen3Machine.SIDE_SWEEP_TICKS
	)
	var session := Machine.session()
	var ticks := 0
	while not sweep.is_finished():
		sweep.step(session)
		ticks += 1
	assert_equal(ticks, 149, "12 rows (7-18) in 12 x 12.4 ticks")


func test_611_stops_shots_to_the_heart_until_the_sweep() -> void:
	var session := Machine.session()
	var heart := _first(session, Keen3Heart)
	_shoot_at(session, heart.position, 160)
	assert_true(not heart.removed, "tile 611 stops the shot")
	_destroy_sparks(session)
	for tick in SIDE_SWEEP_DONE_TICKS:
		session.step(KeenInput.new())
	_shoot_at(session, heart.position, 160)
	assert_true(heart.removed, "now the shot reaches the heart")


func test_the_heart_ends_the_machine() -> void:
	var session := Machine.session()
	var flashes := [0]
	session.border_flashed.connect(func() -> void: flashes[0] += 1)
	var heart := _first(session, Keen3Heart)
	for tick in 5:
		session.step(KeenInput.new())
	session.add_actor(Keen3Shot.fired(Vector2(40, 40), 1))
	session.add_actor(Keen3Meep.spawned(Vector2(12, 10) * 16, 1))
	session.shoot_machine(heart)
	var machine := session.machine
	assert_true(machine.heart_destroyed, "the heart is destroyed")
	assert_equal(session.inventory.score, 1000, "+1000")
	assert_equal(flashes[0], 1, "the border flashes")
	assert_true(
		machine.legs.all(func(leg: Keen3MachineLeg) -> bool: return leg.stopped), "legs stop"
	)
	assert_true(not machine.arms_stopped(), "the arms are not stopped by the heart")
	session.step(KeenInput.new())
	assert_equal(_count(session, Keen3Spark), 0, "the sparks are gone")
	assert_equal(_count(session, Keen3Meep), 0, "the Meep too")
	assert_true(session.actors.is_empty(), "every sprite but Keen")


func test_the_body_sweep_and_the_end() -> void:
	var session := Machine.session()
	session.shoot_machine(_first(session, Keen3Heart))
	var ticks := 0
	while session.outcome == LevelSession.Outcome.PLAYING and ticks < 400:
		session.step(KeenInput.new())
		ticks += 1
	assert_equal(ticks, Keen3Machine.WON_TICKS, "done 181 ticks after the shot")
	assert_equal(session.outcome, LevelSession.Outcome.COMPLETED, "the level is done")
	for column in range(8, 17):
		for row in range(3, 19):
			assert_equal(session.level.tile_at(Vector2i(column, row)), Machine.EMPTY, "body swept")


func test_the_body_sweep_takes_a_row_every_8_2_ticks() -> void:
	var session := Machine.session()
	session.shoot_machine(_first(session, Keen3Heart))
	var cleared_rows := {}
	session.tile_changed.connect(
		func(cell: Vector2i, _tile: int) -> void:
			if cell.x >= 8 and cell.x <= 16 and not cleared_rows.has(cell.y):
				cleared_rows[cell.y] = true
	)
	for tick in 9:
		session.step(KeenInput.new())
	assert_equal(cleared_rows.keys(), [3], "row 3 after 8.2 ticks")
	for tick in BODY_SWEEP_DONE_TICKS:
		session.step(KeenInput.new())
	assert_true(cleared_rows.has(18), "down to row 18")


func test_level_16_won_through_the_course() -> void:
	var play := Keen3LevelPlay.create(null, Machine.properties())
	play.session = Machine.session()
	play.level_number = Keen3Files.LAST_LEVEL
	play.state = Keen3LevelPlay.State.PLAYING
	var won := [false]
	play.won.connect(func() -> void: won[0] = true)
	play.session.shoot_machine(_first(play.session, Keen3Heart))
	for tick in Keen3Machine.WON_TICKS:
		play.step(KeenInput.new())
	assert_true(won[0], "the game is won")


## The rows the arm stands in, in order, over [param ticks].
func _arm_rows(session: Keen3LevelSession, arm: Keen3MachineArm, ticks: int) -> Array:
	var rows := [arm.cell.y]
	for tick in ticks:
		session.step(KeenInput.new())
		if arm.cell.y != rows[-1]:
			rows.append(arm.cell.y)
	return rows


## The ticks on which the arm moved.
func _arm_move_ticks(session: Keen3LevelSession, arm: Keen3MachineArm, ticks: int) -> Array:
	var times := []
	var row := arm.cell.y
	for tick in range(1, ticks + 1):
		session.step(KeenInput.new())
		if arm.cell.y != row:
			row = arm.cell.y
			times.append(tick)
	return times


## Fires Keen's shot from the far left of [param target]'s row towards it,
## then runs [param ticks].
func _shoot_at(session: Keen3LevelSession, target: Vector2, ticks: int) -> void:
	var start := Vector2(3 * 16, target.y + 4)
	session.add_actor(Keen3Shot.fired(start, 1))
	for tick in ticks:
		session.step(KeenInput.new())


func _destroy_sparks(session: Keen3LevelSession) -> void:
	for actor in session.actors.duplicate():
		if actor is Keen3Spark:
			session.shoot_machine(actor)


func _spark_at(session: Keen3LevelSession, cell: Vector2i) -> Actor:
	for actor in session.actors:
		if actor is Keen3Spark and actor.position == Vector2(cell * 16):
			return actor
	return null


func _first(session: LevelSession, kind: Script) -> Actor:
	for actor in session.actors:
		if is_instance_of(actor, kind):
			return actor
	return null


func _count(session: LevelSession, kind: Script) -> int:
	var count := 0
	for actor in session.actors:
		if is_instance_of(actor, kind) and not actor.removed:
			count += 1
	return count
