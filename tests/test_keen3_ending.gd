extends "res://tests/test_case.gd"
## Tests for Keen 3's ending ([Keen3Ending]), without Keen 3's files, in
## retraces (70.086 a second): the order of the stages, the fades, the four
## pages typed in their boxes with 120 retraces after each, the five camera
## flashes with their tiles, CLICKSND and waits, the picture with its wait
## of 400 and its box, the key, the end text (scrolling, MORTIMER) and the
## end.

const RETRACE := 1.0 / Keen3TypedBoxes.RETRACES_PER_SECOND
const PAGE_LINES: PackedInt32Array = [4, 3, 3, 1]
const LONG_RUN := 200000
const END_TEXT_BYTES := 1500

## A clock in seconds for the signals' times (an array, so that the lambdas
## change it).
var _time := [0.0]


func test_the_stages_in_order() -> void:
	var ending := _ending()
	var stages := [ending.stage]
	ending.changed.connect(
		func() -> void:
			if stages[-1] != ending.stage:
				stages.append(ending.stage)
	)
	_run_until(ending, Keen3Ending.Stage.PICTURE_BOX)
	_run_until_typed(ending)
	ending.confirm()
	ending.confirm()
	var order := Keen3Ending.Stage
	assert_equal(
		stages,
		[
			order.HALL_FADE_IN,
			order.HALL_BOXES,
			order.FLASHES,
			order.HALL_FADE_OUT,
			order.PICTURE_FADE_IN,
			order.PICTURE_WAIT,
			order.PICTURE_BOX,
			order.END_TEXT,
			order.FINISHED,
		],
		"hall, pages, flashes, picture, box, end text"
	)
	assert_true(ending.is_finished(), "finished")


func test_the_hall_fades_in() -> void:
	var ending := _ending()
	assert_equal(ending.brightness(), 0.0, "black at first")
	assert_true(ending.shows_hall(), "map 81")
	ending.advance(Keen3Ending.fade_retraces() / 2.0 * RETRACE)
	assert_equal(ending.brightness(), 0.5, "half way, in steps")
	ending.advance(Keen3Ending.fade_retraces() / 2.0 * RETRACE)
	assert_equal(ending.stage, Keen3Ending.Stage.HALL_BOXES, "then the pages")
	assert_equal(ending.brightness(), 1.0, "bright")


func test_the_four_pages_in_their_boxes() -> void:
	var ending := _ending()
	_run_until(ending, Keen3Ending.Stage.HALL_BOXES)
	var boxes := ending.boxes.boxes
	assert_equal(boxes.size(), 4, "four pages")
	var expected: Array[Rect2i] = [
		Rect2i(0, 14, 38, 4), Rect2i(0, 14, 38, 3), Rect2i(0, 14, 38, 3), Rect2i(13, 14, 12, 1)
	]
	for index in boxes.size():
		assert_equal(
			Rect2i(boxes[index].cell, boxes[index].size), expected[index], "box %d" % index
		)
		assert_equal(boxes[index].pause_retraces, 120.0, "120 retraces after it")
		assert_equal(boxes[index].lines.size(), PAGE_LINES[index], "its lines")


func test_the_pages_take_their_letters_and_pauses() -> void:
	var ending := _ending()
	_run_until(ending, Keen3Ending.Stage.HALL_BOXES)
	var expected := ending.boxes.total_seconds()
	var spent := _run_until(ending, Keen3Ending.Stage.FLASHES)
	assert_true(absf(spent - expected) < 2 * RETRACE, "6 a letter and 120 after each page")


func test_the_five_camera_flashes() -> void:
	var ending := _ending()
	var tiles := []
	var clicks := []
	ending.tile_changed.connect(
		func(cell: Vector2i, tile: int) -> void: tiles.append([cell, tile, _time[0]])
	)
	ending.flashed.connect(func() -> void: clicks.append(_time[0]))
	_run_until(ending, Keen3Ending.Stage.FLASHES, true)
	_run_until(ending, Keen3Ending.Stage.HALL_FADE_OUT, true)
	var cells := Keen3Ending.FLASH_CELLS
	var changes := []
	for index in cells.size():
		changes.append([cells[index], Keen3Ending.FLASH_TILES[index]])
		changes.append([cells[index], Keen3Ending.AFTER_FLASH_TILES[index]])
	var seen := []
	for change in tiles:
		seen.append([change[0], change[1]])
	assert_equal(seen, changes, "(19,5) 58 then 72, (3,8) 60 then 61, ...")
	assert_equal(clicks.size(), 5, "CLICKSND for each")
	var waits := [20, 10, 5, 10]
	for index in waits.size():
		var apart: float = (clicks[index + 1] - clicks[index]) / RETRACE
		assert_true(
			absf(apart - 2 - waits[index]) < 1.5, "flash %d: 2 + %d" % [index, waits[index]]
		)
	var lit: float = (tiles[1][2] - tiles[0][2]) / RETRACE
	assert_true(absf(lit - 2.0) < 1.5, "bright for 2 retraces")
	var last: float = (_time[0] - clicks[4]) / RETRACE
	assert_true(absf(last - (2 + 15 + 120)) < 1.5, "then 15 and 120 before the fade")


func test_the_flash_tiles_match_map_81() -> void:
	assert_equal(Keen3Ending.FLASH_CELLS[0], Vector2i(19, 5), "the first at (19,5)")
	assert_equal(Array(Keen3Ending.FLASH_WAITS), [20, 10, 5, 10, 15], "waits of research.md §9")


func test_the_picture_waits_400_then_its_box() -> void:
	var ending := _ending()
	_run_until(ending, Keen3Ending.Stage.PICTURE_FADE_IN)
	assert_true(ending.shows_picture() and not ending.shows_hall(), "the picture")
	_run_until(ending, Keen3Ending.Stage.PICTURE_WAIT)
	var waited := _run_until(ending, Keen3Ending.Stage.PICTURE_BOX) / RETRACE
	assert_true(absf(waited - 400.0) < 1.5, "400 retraces")
	var box := ending.boxes.current()
	assert_equal(Rect2i(box.cell, box.size), Rect2i(14, 16, 10, 3), "the box over the picture")
	assert_equal(box.lines, PackedStringArray(["The End?", "Not yet"]), "its lines")
	ending.confirm()
	assert_equal(ending.stage, Keen3Ending.Stage.PICTURE_BOX, "a key only once it is typed")
	_run_until_typed(ending)
	ending.advance(10.0)
	assert_equal(ending.stage, Keen3Ending.Stage.PICTURE_BOX, "then it waits for a key")
	ending.confirm()
	assert_equal(ending.stage, Keen3Ending.Stage.END_TEXT, "the end text")


func test_the_end_text_scrolls_with_mortimer() -> void:
	var ending := _ending()
	var played := [0]
	ending.end_text_started.connect(func() -> void: played[0] += 1)
	_run_until(ending, Keen3Ending.Stage.PICTURE_BOX)
	_run_until_typed(ending)
	ending.confirm()
	assert_equal(played[0], 1, "MORTIMER plays")
	assert_equal(ending.end_text_lines().size(), Keen3Ending.TEXT_LINES, "23 lines")
	assert_true(ending.end_text_lines()[0].length() <= Keen3Ending.TEXT_WIDTH, "38 wide")
	ending.advance(RETRACE, 1)
	assert_equal(ending.text_offset, 1, "down a line")
	ending.advance(RETRACE, -1)
	ending.advance(1.0, 0)
	ending.advance(RETRACE, -1)
	assert_equal(ending.text_offset, 0, "and up")
	ending.confirm()
	assert_true(ending.is_finished(), "a key ends it")


func test_without_texts_the_ending_still_ends() -> void:
	var ending := Keen3Ending.create([], PackedStringArray(), PackedByteArray())
	_run_until(ending, Keen3Ending.Stage.PICTURE_BOX)
	ending.confirm()
	assert_true(ending.is_finished(), "no pages, no box, no end text")


func test_the_hall_and_the_sprites() -> void:
	assert_equal(Keen3Ending.VIEW_CORNER, Vector2i(2, 2), "the view's corner")
	assert_equal(Keen3Ending.VORTICON_SPRITE, 67, "a Vorticon")
	assert_equal(Keen3Ending.KEEN_CELL * 16, Vector2(248, 104), "Keen at (15.5, 6.5)")
	var frame := Keen3Ending.frame_on_picture(Vector2i(4, 18), Vector2i(43, 23))
	assert_equal(frame, Rect2i(0, 14, 38, 4), "Choco's cells less the view's corner")


## Runs the ending a retrace at a time until [param stage]; returns the
## seconds it took. With [param keep_time] the clock in [member _time] goes
## on from where it was.
func _run_until(ending: Keen3Ending, stage: Keen3Ending.Stage, keep_time := false) -> float:
	if not keep_time:
		_time[0] = 0.0
	var start: float = _time[0]
	var steps := 0
	while ending.stage != stage and steps < LONG_RUN:
		ending.advance(RETRACE)
		_time[0] += RETRACE
		steps += 1
	return _time[0] - start


func _run_until_typed(ending: Keen3Ending) -> void:
	var steps := 0
	while not ending.boxes.is_pausing() and steps < LONG_RUN:
		ending.advance(RETRACE)
		steps += 1


func _ending() -> Keen3Ending:
	var pages: Array[PackedStringArray] = []
	for count in PAGE_LINES:
		var lines := PackedStringArray()
		for line in count:
			lines.append("page line %d" % line)
		pages.append(lines)
	var text := ("word ".repeat(END_TEXT_BYTES / 5)).to_ascii_buffer()
	text.append(0x1A)
	return Keen3Ending.create(pages, PackedStringArray(["The End?", "Not yet"]), text)
