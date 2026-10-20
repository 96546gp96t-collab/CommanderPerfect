extends "res://tests/test_case.gd"
## Tests of level 16, Mortimer and the ending with the player's own Keen 3
## files (skipped without them): level 16 has its machine (six sparks, the
## heart, two arms, two legs, tile 611 beside the heart), the machine moves
## inside its own cells, the sixth spark's sweep opens the way to the heart
## and a real shot along the heart's row wins the game; Mortimer's
## messages, the ending's pages, its box and its end text load and fit
## their boxes; map 81 holds the tiles the camera flashes change back to.

const SPARK_CELLS: Array[Vector2i] = [
	Vector2i(11, 4),
	Vector2i(13, 4),
	Vector2i(9, 6),
	Vector2i(15, 6),
	Vector2i(9, 13),
	Vector2i(15, 13)
]
const HEART_CELL := Vector2i(12, 8)
const BLOCK_CELLS: Array[Vector2i] = [Vector2i(7, 8), Vector2i(17, 8)]
const BLOCK_TILE := 611
const RUN_TICKS := 600
const SWEEP_TICKS := 160
const SHOT_TICKS := 90
## The machine's own cells: the arms' and the body's columns.
const MACHINE_AREA := Rect2i(5, 3, 15, 16)

var _files: GameFiles
var _data: Keen3GameData


func run_all() -> void:
	_files = Keen3Files.locate()
	if _files == null:
		skip("no Keen 3 game data found")
		return
	_data = Keen3GameData.load_from(_files)
	super.run_all()


func test_level_16_has_its_machine() -> void:
	var play := _level_16()
	var machine := play.session.machine
	assert_true(machine != null, "a machine")
	if machine == null:
		return
	var sparks: Array[Vector2i] = []
	var hearts: Array[Vector2i] = []
	for actor in play.session.actors:
		var cell := Vector2i(actor.position / 16)
		if actor is Keen3Spark:
			sparks.append(cell)
		elif actor is Keen3Heart:
			hearts.append(cell)
	sparks.sort()
	var expected := SPARK_CELLS.duplicate()
	expected.sort()
	assert_equal(sparks, expected, "six sparks where research.md §6 has them")
	assert_equal(hearts, [HEART_CELL], "the heart at (12,8)")
	var arm_cells := machine.arms.map(func(arm: Keen3MachineArm) -> Vector2i: return arm.cell)
	assert_equal(arm_cells, [Vector2i(6, 10), Vector2i(18, 16)], "two arms")
	var leg_cells := machine.legs.map(func(leg: Keen3MachineLeg) -> Vector2i: return leg.cell)
	assert_equal(leg_cells, [Vector2i(11, 18), Vector2i(13, 18)], "two legs")
	assert_true(machine.legs[0].is_left and not machine.legs[1].is_left, "left and right")
	for cell in BLOCK_CELLS:
		assert_equal(play.level.tile_at(cell), BLOCK_TILE, "611 at %s" % cell)


func test_the_feet_are_drawn_as_the_machine_draws_them() -> void:
	var play := _level_16()
	for leg in play.session.machine.legs:
		var cells := leg.foot_cells()
		for index in cells.size():
			assert_equal(
				play.level.tile_at(cells[index]), Keen3MachineLeg.FOOT_TILES[index], "foot"
			)


func test_the_machine_moves_inside_its_cells() -> void:
	var play := _level_16()
	var session := play.session
	session.set_invincible(true)
	var outside := []
	session.tile_changed.connect(
		func(cell: Vector2i, _tile: int) -> void:
			if not MACHINE_AREA.has_point(cell):
				outside.append(cell)
	)
	var slams := [0]
	session.keen3_sound_played.connect(
		func(sound: String) -> void: slams[0] += int(sound == Keen3Sounds.FOOTSLAM)
	)
	var arm_rows := {}
	var leg_rows := {}
	for tick in RUN_TICKS:
		play.step(KeenInput.new())
		for arm in session.machine.arms:
			arm_rows[arm.cell.y] = true
		for leg in session.machine.legs:
			leg_rows[leg.cell.y] = true
	assert_equal(outside, [], "no tile outside the machine changes")
	assert_equal(_sorted(arm_rows.keys()), [10, 11, 12, 13, 14, 15, 16], "arms: rows 10-16")
	assert_equal(_sorted(leg_rows.keys()), [15, 16, 17, 18], "legs: rows 15-18")
	assert_true(slams[0] >= 2, "FOOTSLAM")


func test_shooting_the_machine_wins_the_game() -> void:
	var play := _level_16()
	var session := play.session
	session.set_invincible(true)
	var won := [false]
	play.won.connect(func() -> void: won[0] = true)
	for actor in session.actors.duplicate():
		if actor is Keen3Spark:
			session.shoot_machine(actor)
	assert_equal(session.inventory.score, 6000, "six sparks")
	for tick in SWEEP_TICKS:
		play.step(KeenInput.new())
	for cell in BLOCK_CELLS:
		assert_equal(play.level.tile_at(cell), Keen3Machine.EMPTY_TILE, "611 is gone")
	var row_middle := HEART_CELL.y * 16 + 4
	session.add_actor(Keen3Shot.fired(Vector2(3 * 16, row_middle), 1))
	for tick in SHOT_TICKS:
		play.step(KeenInput.new())
	assert_true(session.machine.heart_destroyed, "a shot along row 8 reaches the heart")
	assert_equal(session.inventory.score, 7000, "+1000")
	for tick in Keen3Machine.WON_TICKS:
		play.step(KeenInput.new())
	assert_true(won[0], "won")
	assert_equal(play.state, Keen3LevelPlay.State.WON, "nothing more to play")


func test_mortimer_and_the_ending_texts_load() -> void:
	var messages := _data.mortimer_messages
	assert_equal(messages.size(), 9, "nine boxes")
	for index in mini(messages.size(), Keen3Mortimer.BOX_SIZES.size()):
		var size := Keen3Mortimer.BOX_SIZES[index]
		assert_true(_fits(messages[index], size), "box %d fits %s" % [index, size])
	var pages := _data.ending_pages
	assert_equal(pages.size(), 4, "four pages")
	for index in mini(pages.size(), Keen3Ending.PAGE_FRAME_STARTS.size()):
		var frame := Keen3Ending.frame_on_picture(
			Keen3Ending.PAGE_FRAME_STARTS[index], Keen3Ending.PAGE_FRAME_ENDS[index]
		)
		assert_true(_fits(pages[index], frame.size), "page %d fits" % index)
	var the_end := Keen3Ending.frame_on_picture(
		Keen3Ending.THE_END_FRAME_START, Keen3Ending.THE_END_FRAME_END
	)
	assert_true(_fits(_data.the_end, the_end.size), "the box over the picture fits")
	assert_true(not _data.end_text.is_empty(), "the end text")
	assert_true(_data.finale != null, "FINALE.CK3")


func test_mortimer_and_footslam_sounds() -> void:
	for sound_name in [Keen3Sounds.MORTIMER, Keen3Sounds.FOOTSLAM]:
		var entry := Keen2Sounds.find_entry(_data.sounds, sound_name)
		assert_true(entry != null and not entry.divisors.is_empty(), sound_name)


func test_map_81_for_the_ending() -> void:
	var hall := LevelData.parse(_files.read(_files.level_file(Keen3Files.ENDING_LEVEL)))
	assert_true(hall != null, "map 81")
	if hall == null:
		return
	assert_equal(hall.playable_rect().position, Keen3Ending.VIEW_CORNER, "the view's corner")
	for index in Keen3Ending.FLASH_CELLS.size():
		var cell := Keen3Ending.FLASH_CELLS[index]
		assert_equal(
			hall.tile_at(cell), Keen3Ending.AFTER_FLASH_TILES[index], "the camera at %s" % cell
		)


func test_the_ending_runs_to_its_end() -> void:
	var ending := Keen3Ending.create(_data.ending_pages, _data.the_end, _data.end_text)
	var steps := 0
	while ending.stage != Keen3Ending.Stage.PICTURE_BOX and steps < 100000:
		ending.advance(1.0 / 70.0)
		steps += 1
	ending.advance(10.0)
	ending.confirm()
	assert_equal(ending.stage, Keen3Ending.Stage.END_TEXT, "the end text")
	assert_true(ending.end_text.size() > Keen3Ending.TEXT_LINES, "longer than a page")
	ending.confirm()
	assert_true(ending.is_finished(), "the end")


func _level_16() -> Keen3LevelPlay:
	var play := Keen3LevelPlay.create(_files, _data.properties)
	play.start(Keen3Files.LAST_LEVEL)
	return play


static func _fits(lines: PackedStringArray, size: Vector2i) -> bool:
	if lines.size() > size.y:
		return false
	for line in lines:
		if line.length() > size.x:
			return false
	return true


static func _sorted(values: Array) -> Array:
	var copy := values.duplicate()
	copy.sort()
	return copy
