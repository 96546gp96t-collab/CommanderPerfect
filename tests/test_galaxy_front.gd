extends "res://tests/test_case.gd"
## Tests for what Galaxy shows around its games (milestone D8) with
## hand-made data, so they run without Keen 4's files: the text mark-up,
## demo input and two-button firing, the high-score table (ranking, ties,
## defaults found by their shape, saving), the intro's words and timing,
## the story's letters and rows, Keen 4's title loop order and cheats.

const PAGES := "^P\r\nfirst page\r\n^G 8,16,6\r\n^c4red\r\n^P\r\nsecond\r\n^E\r\nafter the end"
const DEMO_MAP := 9
const SAVE_PATH := "user://test_galaxy_front/high_scores.json"


func test_text_pages_are_cut_at_their_page_marks() -> void:
	var pages := GalaxyTextPages.parse(PAGES.to_ascii_buffer())
	assert_equal(pages.page_count(), 2, "two ^P before ^E")
	var first := pages.bytes.slice(pages.page_starts[0], pages.page_end(0)).get_string_from_ascii()
	assert_true(first.begins_with("first page"), "a page starts after its ^P line")
	assert_true(first.ends_with("red\r\n"), "and stops before the next ^P")
	var second := pages.bytes.slice(pages.page_starts[1], pages.page_end(1)).get_string_from_ascii()
	assert_equal(second, "second\r\n", "the last page stops at ^E")


func test_command_numbers_are_read_past_any_separator() -> void:
	var text := "^G 8,16,6\r\n".to_ascii_buffer()
	var found := GalaxyTextPages.numbers_at(text, 2, 3)
	assert_equal(found.slice(0, 3), PackedInt32Array([8, 16, 6]), "y, x, chunk")
	assert_equal(GalaxyTextPages.command_at("^g".to_ascii_buffer(), 0), 0x47, "lower case")
	assert_equal(GalaxyTextPages.line_end(text, 2), text.size(), "after the newline")


func test_a_demo_is_its_map_and_runs_of_input() -> void:
	# Two frames right with jump, three frames up-left with pogo.
	var bytes := PackedByteArray([DEMO_MAP, 0, 4, 0, 2, 0x19, 3, 0x20])
	var demo := GalaxyDemo.parse(bytes)
	assert_equal(demo.map_number, DEMO_MAP, "the map")
	assert_equal(demo.frame_count(), 5, "2 + 3 frames")
	var first := demo.controls_at(1)
	assert_equal([first.direction, first.vertical, first.jump, first.pogo], [1, 0, true, false])
	var later := demo.controls_at(4)
	assert_equal([later.direction, later.vertical, later.jump, later.pogo], [-1, -1, false, true])
	assert_equal(demo.input_at(5), -1, "nothing after the end")


func test_a_demo_shorter_than_it_says_is_refused() -> void:
	assert_true(GalaxyDemo.parse(PackedByteArray([1, 0, 9, 0, 1])) == null, "too short")


func test_both_buttons_fire_and_nothing_else() -> void:
	var firing := GalaxyTwoButtonFiring.new()
	var seen := firing.convert(_held(true, true), 3)
	assert_equal([seen.fire, seen.jump, seen.pogo], [true, false, false])
	seen = firing.convert(_held(true, false), 3)
	assert_equal([seen.fire, seen.jump, seen.pogo], [false, true, false], "jump alone")


func test_pogo_counts_after_more_than_8_tics_or_when_let_go() -> void:
	var firing := GalaxyTwoButtonFiring.new()
	var pogo: Array[bool] = []
	for frame in 4:
		pogo.append(firing.convert(_held(false, true), 3).pogo)
	assert_equal(pogo, [false, false, false, true], "3, 6, 9 tics held: then it counts")
	var tap := GalaxyTwoButtonFiring.new()
	tap.convert(_held(false, true), 3)
	assert_true(tap.convert(_held(false, false), 3).pogo, "let go early: one frame of pogo")
	assert_true(not tap.convert(_held(false, false), 3).pogo, "and then no more")


func test_high_scores_rank_by_score_then_by_rescues() -> void:
	var table := GalaxyHighScores.load_from(SAVE_PATH + ".none", _defaults())
	assert_equal(table.place_for(20000, 0), 1, "a higher score goes above lower ones")
	assert_equal(table.place_for(10000, 3), 2, "an equal score with more rescues goes above")
	assert_equal(table.place_for(10000, 2), 3, "with as many it goes below")
	assert_equal(table.place_for(500, 8), -1, "too low")
	table.insert(2, "New", 10000, 3)
	assert_equal(table.entries.size(), 4, "the last one drops off")
	assert_equal(table.entries[2].name, "New", "in its place")
	assert_equal(table.entries[3].name, "Two", "the others move down")


func test_high_scores_are_saved_and_read_back() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	var table := GalaxyHighScores.load_from(SAVE_PATH, _defaults())
	table.insert(0, "Saved", 99999, 8)
	assert_true(table.save(), "written")
	var again := GalaxyHighScores.load_from(SAVE_PATH, _defaults())
	assert_equal(
		[again.entries[0].name, again.entries[0].score, again.entries[0].count], ["Saved", 99999, 8]
	)
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SAVE_PATH.get_base_dir())


func test_default_high_scores_are_found_by_their_shape() -> void:
	var image := PackedByteArray()
	image.resize(300)
	image.fill(0xCC)
	var start := image.size()
	for name in ["Alpha", "", "Gamma"]:
		var record := PackedByteArray()
		record.resize(GalaxyHighScores.RECORD_SIZE)
		record.fill(0)
		for index in name.length():
			record[index] = name.unicode_at(index)
		record.encode_u32(GalaxyHighScores.SCORE_AT, 10000)
		record.encode_u16(GalaxyHighScores.COUNT_AT, 2)
		image.append_array(record)
	image.append_array(PackedByteArray([0xCC, 0xCC]))
	assert_equal(GalaxyHighScores.find_defaults(image, 3, PackedInt32Array([7])), start)
	var found := GalaxyHighScores.defaults_at(image, start, 3)
	assert_equal(
		[found[0].name, found[1].name, found[2].score, found[2].count], ["Alpha", "", 10000, 2]
	)


func test_intro_words_are_runs_dark_then_light() -> void:
	var bitmap := GalaxyIntroBitmap.parse(_intro_chunk(10, [2, 3, 5]))
	assert_equal([bitmap.width, bitmap.height], [10, 200])
	assert_equal(bitmap.light_runs(0), PackedInt32Array([2, 5]), "dark 2, light 3, dark 5")
	var image := bitmap.image(Color.WHITE)
	assert_true(image.get_pixel(1, 0).a == 0.0 and image.get_pixel(2, 0) == Color.WHITE, "light")


func test_intro_scroll_ends_with_the_first_word_right_edge_at_120() -> void:
	var intro := GalaxyIntroCredits.create(
		GalaxyIntroBitmap.parse(_intro_chunk(400, [10, 380, 10])),
		GalaxyIntroBitmap.parse(_intro_chunk(100, [20, 60, 20])),
		[]
	)
	var total := intro.scroll_tics()
	assert_equal(total, 600, "|120 - 400 - 320|")
	assert_equal([intro.left_word_x(), intro.right_word_x()], [320, -100], "at the start")
	intro.advance(total)
	assert_equal(intro.left_word_x(), 120 - 400, "its right edge at 120")
	assert_equal(intro.right_word_x(), 200, "the second word 200 from the left")
	intro.advance(2)
	assert_equal(intro.phase, GalaxyIntroCredits.Phase.ZOOM, "then the zoom")


func test_a_credit_rises_waits_and_leaves() -> void:
	var picture := Image.create_empty(16, 20, false, Image.FORMAT_RGBA8)
	picture.fill(Color8(0, 0, 170))
	var intro := GalaxyIntroCredits.create(
		GalaxyIntroBitmap.parse(_intro_chunk(2000, [10, 1980, 10])),
		GalaxyIntroBitmap.parse(_intro_chunk(100, [20, 60, 20])),
		[picture]
	)
	assert_equal(intro.credit_corner(), Vector2i(152, 230), "starts with its middle at 240")
	for frame in 35:
		intro.advance(2)
	assert_equal(intro.credit_y, 100, "70 tics later in the middle")
	for frame in 101:
		intro.advance(2)
	assert_equal(intro.credit_y, 100, "it waits 200 tics")
	intro.advance(2)
	intro.advance(2)
	assert_equal(intro.credit_y, 96, "then flies on, two pixels a tic")


func test_story_letters_are_the_fonts_own_numbers() -> void:
	assert_equal(GalaxyStoryScroller.translate("Aa .!"), String.chr(32) + String.chr(58) + "XTY")
	var rows := GalaxyStoryScroller.row_table()
	assert_equal(int(rows.get_pixel(0, 199).r), 320, "the bottom row is 320 wide")
	assert_true(rows.get_pixel(0, 0).r < 60.0, "the top row is narrow")
	assert_equal(GalaxyStoryScroller.distance_after(9), 2, "a row every 4 tics")


func test_the_title_loop_order() -> void:
	var loop := Keen4TitleLoop.new()
	var shown: Array = []
	for step in 8:
		var kind := loop.next()
		shown.append(loop.demo() if kind != Keen4TitleLoop.Step.INTRO else -9)
	assert_equal(shown, [-9, 0, -1, 1, 4, 2, 3, -9], "intro, demo 0, story, 1, scores (4), 2, 3")


func test_cheats_count_once_while_held() -> void:
	var cheats := Keen4Cheats.new()
	var held: Array[Key] = [KEY_E, KEY_N, KEY_D]
	var is_held := func(key: Key) -> bool: return key in held
	assert_equal(cheats.check(is_held), Keen4Cheats.Cheat.END, "E+N+D")
	assert_equal(cheats.check(is_held), Keen4Cheats.Cheat.NONE, "not again while held")
	held.assign([KEY_B, KEY_A, KEY_T])
	assert_equal(cheats.check(is_held), Keen4Cheats.Cheat.ITEMS, "B+A+T")
	var inventory := Keen4Inventory.new_game()
	Keen4Cheats.give_items(inventory)
	assert_equal(
		[inventory.shots, inventory.lives, inventory.gems], [99, 4, PackedInt32Array([1, 1, 1, 1])]
	)


func test_demos_give_no_extra_life_for_points() -> void:
	var inventory := Keen4Inventory.new_game()
	inventory.extra_lives_for_points = false
	assert_true(not inventory.add_score(30000), "no life at 20,000 in a demo")
	assert_equal(inventory.lives, Keen4Inventory.START_LIVES, "still 3")


static func _held(jump: bool, pogo: bool) -> KeenInput:
	return KeenInput.create(0, jump, pogo)


static func _defaults() -> Array[GalaxyHighScores.Entry]:
	var entries: Array[GalaxyHighScores.Entry] = []
	for row in [["Zero", 30000, 0], ["One", 10000, 5], ["Two", 10000, 2], ["Three", 5000, 0]]:
		entries.append(GalaxyHighScores.Entry.create(row[0], row[1], row[2]))
	return entries


## An intro word of [param width] pixels whose every row has [param runs].
static func _intro_chunk(width: int, runs: Array) -> PackedByteArray:
	var chunk := PackedByteArray()
	chunk.resize(4 + GalaxyIntroBitmap.ROW_COUNT * 2)
	chunk.encode_u16(0, GalaxyIntroBitmap.ROW_COUNT)
	chunk.encode_u16(2, width)
	var row_at := chunk.size()
	for run in runs:
		chunk.append_array(PackedByteArray([run & 0xFF, run >> 8]))
	chunk.append_array(PackedByteArray([0xFF, 0xFF]))
	for row in GalaxyIntroBitmap.ROW_COUNT:
		chunk.encode_u16(4 + row * 2, row_at)
	return chunk
