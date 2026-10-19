extends "res://tests/test_case.gd"
## Tests for Mortimer's messages at the start of level 16 ([Keen3Mortimer],
## [Keen3TypedBoxes]) and the pieces of the screen that milestone C7 added
## ([Keen3Window.open_at], [Keen3BorderFlash]), without Keen 3's files:
## the sound first, the nine boxes in order with their sizes, places and
## pauses, typing at 6 retraces a letter, skipping, the windows on the
## cells of the 320x200 picture also in widescreen, the border flash's
## colours, time and frame. The ending is in tests/test_keen3_ending.gd;
## the start option --ending is checked here too.

const RETRACE := 1.0 / Keen3TypedBoxes.RETRACES_PER_SECOND
const SOUND_SECONDS := 2.0
const WIDE_VIEW := Vector2i(426, 200)


func test_typing_takes_6_retraces_a_letter() -> void:
	var boxes := Keen3TypedBoxes.new()
	boxes.add(PackedStringArray(["ab", "cd"]), Vector2i(1, 2), Vector2i(4, 2), 10)
	boxes.advance(5 * RETRACE)
	assert_equal(boxes.typed, 0, "nothing after 5 retraces")
	boxes.advance(RETRACE)
	assert_equal(boxes.visible_lines(), PackedStringArray(["a", ""]), "a letter after 6")
	boxes.advance(12 * RETRACE)
	assert_equal(boxes.visible_lines(), PackedStringArray(["ab", ""]), "a line end takes a letter")
	boxes.advance(12 * RETRACE)
	assert_equal(boxes.visible_lines(), PackedStringArray(["ab", "cd"]), "four letters after 30")
	assert_true(not boxes.is_pausing(), "the last line end still to come")
	boxes.advance(6 * RETRACE)
	assert_true(boxes.is_pausing(), "typed: the pause")
	boxes.advance(9 * RETRACE)
	assert_true(not boxes.is_finished(), "the pause lasts 10 retraces")
	boxes.advance(RETRACE)
	assert_true(boxes.is_finished(), "then the next box (none)")


func test_a_box_grows_with_its_text() -> void:
	var boxes := Keen3TypedBoxes.new()
	boxes.add(PackedStringArray(["longer than five"]), Vector2i.ZERO, Vector2i(5, 1), 0)
	assert_equal(boxes.current().size, Vector2i(16, 1), "as wide as the line")


func test_mortimer_waits_for_his_sound() -> void:
	var mortimer := Keen3Mortimer.create(_messages(), SOUND_SECONDS)
	mortimer.advance(SOUND_SECONDS - 0.1)
	assert_true(mortimer.current_box() == null, "no box while MORTIMER plays")
	mortimer.advance(0.1)
	var box := mortimer.current_box()
	assert_true(box != null, "then the first box")
	if box != null:
		assert_equal(box.lines, _messages()[0], "his first message")
		assert_equal(mortimer.boxes.typed, 0, "typed from the start")


func test_the_nine_boxes_in_order_with_their_sizes_and_places() -> void:
	var mortimer := Keen3Mortimer.create(_messages(), 0.0)
	var cells: Array[Vector2i] = [
		Vector2i(17, 20),
		Vector2i(13, 20),
		Vector2i(10, 20),
		Vector2i(0, 18),
		Vector2i(0, 18),
		Vector2i(4, 19),
		Vector2i(2, 16),
		Vector2i(2, 20),
		Vector2i(0, 17),
	]
	assert_equal(mortimer.boxes.boxes.size(), 9, "nine boxes")
	for index in mortimer.boxes.boxes.size():
		var box: Keen3TypedBoxes.Box = mortimer.boxes.boxes[index]
		assert_equal(box.size, Keen3Mortimer.BOX_SIZES[index], "box %d's size" % index)
		assert_equal(box.cell, cells[index], "box %d's place" % index)
		assert_equal(box.lines, _messages()[index], "box %d's text" % index)
		assert_equal(int(box.pause_retraces), Keen3Mortimer.PAUSE_RETRACES[index], "its pause")


func test_the_boxes_follow_each_other() -> void:
	var mortimer := Keen3Mortimer.create(_messages(), SOUND_SECONDS)
	var shown := []
	var steps := 0
	while not mortimer.is_finished() and steps < 100000:
		mortimer.advance(RETRACE)
		var box := mortimer.current_box()
		if box != null and (shown.is_empty() or shown[-1] != box):
			shown.append(box)
		steps += 1
	assert_equal(shown.size(), 9, "every box once, in order")
	var expected := SOUND_SECONDS + mortimer.boxes.total_seconds()
	assert_true(absf(steps * RETRACE - expected) < 2 * RETRACE, "sound, letters and pauses")


func test_the_pauses_are_180_or_240_retraces() -> void:
	assert_equal(
		Keen3Mortimer.PAUSE_RETRACES,
		PackedInt32Array([180, 180, 240, 240, 240, 180, 180, 180, 240]),
		"research.md §9"
	)


func test_skipping_ends_mortimer() -> void:
	var mortimer := Keen3Mortimer.create(_messages(), SOUND_SECONDS)
	mortimer.advance(SOUND_SECONDS + 1.0)
	assert_true(mortimer.current_box() != null, "a box")
	mortimer.skip()
	assert_true(mortimer.is_finished(), "everything left is skipped")
	assert_true(mortimer.current_box() == null, "no box")
	var early := Keen3Mortimer.create(_messages(), SOUND_SECONDS)
	early.skip()
	assert_true(early.is_finished(), "also while the sound plays")


func test_without_messages_only_the_sound() -> void:
	var mortimer := Keen3Mortimer.create([], SOUND_SECONDS)
	mortimer.advance(SOUND_SECONDS)
	assert_true(mortimer.is_finished(), "done after the sound")


func test_a_placed_window_sits_on_its_cell() -> void:
	var window := Keen3Window.new()
	window.view_size = Vector2i(320, 200)
	window.open_at(Vector2i(17, 20), Vector2i(5, 1))
	var frame := window._frame_origin() + window.placement_offset()
	assert_equal(frame, Vector2(136, 160), "cell (17,20) of the picture")
	window.view_size = WIDE_VIEW
	frame = window._frame_origin() + window.placement_offset()
	assert_equal(frame, Vector2(136 + 53, 160), "in the middle of a wider view")
	window.open(Vector2i(5, 1))
	assert_equal(window.placement_offset(), Vector2.ZERO, "an ordinary window stays centred")
	window.free()


func test_the_border_flash_blinks_yellow_and_cyan() -> void:
	var flash := Keen3BorderFlash.new()
	assert_true(not flash.is_flashing(), "still at first")
	flash.flash()
	assert_true(flash.is_flashing(), "flashing")
	assert_equal(flash.current_color(), Keen3BorderFlash.COLORS[0], "yellow (EGA 14) first")
	flash._process(Keen3BorderFlash.PHASE_SECONDS + 0.01)
	assert_equal(flash.current_color(), Keen3BorderFlash.COLORS[1], "then cyan (EGA 3)")
	flash._process(Keen3BorderFlash.FLASH_SECONDS)
	assert_true(not flash.is_flashing(), "over after 124 ticks")
	assert_true(absf(Keen3BorderFlash.FLASH_SECONDS - 124.0 / 60.0) < 0.001, "2.07 s")
	flash.free()


func test_the_frame_lies_around_the_picture_or_on_its_edge() -> void:
	var picture := Rect2(160, 0, 960, 600)
	var window := Rect2(0, 0, 1280, 600)
	var bars := Keen3BorderFlash.frame_bars(picture, window, 6)
	assert_equal(bars[2], Rect2(154, 6, 6, 588), "left: in the black bar")
	assert_equal(bars[3], Rect2(1120, 6, 6, 588), "right: in the black bar")
	assert_equal(bars[0], Rect2(154, 0, 972, 6), "top: on the picture's edge (no room)")
	bars = Keen3BorderFlash.frame_bars(window, window, 6)
	assert_equal(bars[2].position.x, 0.0, "a filling picture: on its own edge")


func test_the_ending_option_picks_keen_3_only_with_game_3() -> void:
	assert_equal(GameLaunch.scene_for(["--game=3", "--ending"]), GameLaunch.KEEN_3_SCENE, "Keen 3")
	assert_true(GameLaunch.skips_launcher(["--game=3", "--ending"]), "straight to it")
	assert_equal(GameLaunch.scene_for(["--ending"]), GameLaunch.KEEN_1_SCENE, "else Keen 1's")


## Nine messages of the sizes of research.md §9 (made up).
func _messages() -> Array[PackedStringArray]:
	var messages: Array[PackedStringArray] = []
	for size in Keen3Mortimer.BOX_SIZES:
		var lines := PackedStringArray()
		for row in size.y:
			lines.append("m".repeat(size.x - row))
		messages.append(lines)
	return messages
