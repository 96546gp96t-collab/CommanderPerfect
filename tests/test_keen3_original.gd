extends "res://tests/test_case.gd"
## Tests for milestone C11: what was measured in the original Keen 3 in
## js-dos. Typed boxes take a letter's time for every stored character
## (trailing spaces too) and every line end; the ending's boxes stand on
## Choco's rows; a ball spins under the box over the picture; the end text
## has the original's reader (highlighted lines, kept spaces, 21 lines, the
## footer); a new high score table fills its seven places with the three
## names in turn; the ankh lasts 9.6 s. With Keen 3's files, the real texts
## are checked too.

const RETRACE := 1.0 / Keen3TypedBoxes.RETRACES_PER_SECOND
const NAMES: PackedStringArray = ["Yorpy", "Gargile", "Zzapp!"]
## Letter times of the ending's first page in KEEN3.EXE 1.00: 31 letters
## and 7 trailing spaces, 36, 38 and 38, and four line ends (seen: ~13.1 s).
const FIRST_PAGE_LETTERS := 154
## "The End..." and " For now!" with their two line ends.
const THE_END_LETTERS := 21

var _data: Keen3GameData


func run_all() -> void:
	var files := Keen3Files.locate()
	_data = Keen3GameData.load_from(files) if files != null else null
	super.run_all()


func test_trailing_spaces_and_line_ends_take_a_letter_each() -> void:
	var boxes := Keen3TypedBoxes.new()
	boxes.add(PackedStringArray(["ab  ", "c"]), Vector2i.ZERO, Vector2i(2, 2), 0)
	assert_equal(boxes.current().letter_count(), 7, "4 + 1 + 1 + 1")
	assert_equal(boxes.current().size, Vector2i(2, 2), "trailing spaces do not widen it")
	boxes.advance(30 * RETRACE)
	assert_equal(boxes.visible_lines(), PackedStringArray(["ab  ", ""]), "5 letter times")
	boxes.advance(6 * RETRACE)
	assert_equal(boxes.visible_lines(), PackedStringArray(["ab  ", "c"]), "then the next line")


func test_typed_lines_keep_their_trailing_spaces() -> void:
	var lines := Keen3Executable.typed_lines("With   \nend\n")
	assert_equal(lines, PackedStringArray(["With   ", "end"]), "spaces kept, no empty last line")


func test_the_boxes_of_the_ending_stand_on_chocos_rows() -> void:
	assert_equal(Keen3Ending.SCREEN_ORIGIN, Vector2i(4, 0), "4 cells left, the same rows")
	var page := Keen3Ending.frame_on_picture(Vector2i(4, 18), Vector2i(43, 23))
	assert_equal(page.position * EgaGraphics.FONT_CHAR_SIZE, Vector2i(0, 144), "the first page")
	var the_end := Keen3Ending.frame_on_picture(
		Keen3Ending.THE_END_FRAME_START, Keen3Ending.THE_END_FRAME_END
	)
	assert_equal(the_end, Rect2i(14, 20, 10, 3), "x 112-207, y 160-199")


func test_a_ball_spins_under_the_typed_box_over_the_picture() -> void:
	var ending := Keen3Ending.create([], PackedStringArray(["ab"]), PackedByteArray())
	var steps := 0
	while ending.stage != Keen3Ending.Stage.PICTURE_BOX and steps < 200000:
		ending.advance(RETRACE)
		steps += 1
	while not ending.boxes.is_pausing() and steps < 200000:
		ending.advance(RETRACE)
		steps += 1
	assert_equal(ending.cursor_char(), -1, "not at once")
	var seen := PackedInt32Array()
	for retrace in 30:
		ending.advance(RETRACE)
		if ending.cursor_char() >= 0 and (seen.is_empty() or seen[-1] != ending.cursor_char()):
			seen.append(ending.cursor_char())
	assert_equal(
		seen, PackedInt32Array([9, 10, 11, 12, 9]), "font characters 9-12, 5 retraces each"
	)


func test_the_end_text_has_the_readers_layout() -> void:
	var text := "~\r\n~   TITLE\u001f\r\n\tOne.  Two three four\r\n\r\nx".to_ascii_buffer()
	var lines := Keen3EndText.layout(text, 12)
	assert_equal(lines[0], Keen3Window.label_text(" ".repeat(12)), "a gray bar")
	assert_equal(lines[1], Keen3Window.label_text("   TITLE    "), "red on gray, not centred")
	assert_equal(lines[2], "\tOne.  Two", "two spaces kept, the tab too")
	assert_equal(lines[3], "three four", "wrapped at 12")
	assert_equal(lines[4], "", "the paragraph's end")
	assert_equal(Keen3Ending.TEXT_LINES, 21, "21 lines above the footer")
	assert_equal(Keen3Ending.READER_SIZE, Vector2i(38, 23), "the window fills the picture")


func test_a_new_table_has_seven_names_in_turn() -> void:
	var names := Keen3Screens.default_names(NAMES)
	assert_equal(names.size(), Keen2HighScores.PLACES, "every place")
	assert_equal(names[3], "Yorpy", "from the start again")
	assert_equal(names[6], "Yorpy", "the seventh")
	assert_equal(Keen3Screens.default_names(PackedStringArray()).size(), 0, "no names, none")


func test_the_ankh_lasts_9_6_seconds() -> void:
	assert_true(absf(Keen3Body.ANKH_TICKS / 60.0 - 9.6) < 0.05, "577 ticks")


func test_the_real_texts_take_the_measured_time() -> void:
	if _data == null:
		skip("no Keen 3 game data found")
		return
	var ending := Keen3Ending.create(_data.ending_pages, _data.the_end, _data.end_text)
	ending.advance(Keen3Ending.fade_retraces() * RETRACE + RETRACE)
	assert_equal(ending.boxes.current().letter_count(), FIRST_PAGE_LETTERS, "the first page")
	var boxes := Keen3TypedBoxes.new()
	boxes.add(_data.the_end, Vector2i.ZERO, Vector2i.ONE, 0)
	assert_equal(boxes.current().letter_count(), THE_END_LETTERS, "the box over FINALE.CK3")
	assert_true(_data.reader_footer.contains("ESC to Exit /"), "the reader's footer")
	assert_equal(_data.reader_footer.length(), Keen3Ending.TEXT_WIDTH, "as wide as the text")
	assert_true(ending.end_text[1].unicode_at(0) >= Keen3Window.LABEL_FONT_OFFSET, "a red title")
