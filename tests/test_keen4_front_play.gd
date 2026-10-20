extends "res://tests/test_case.gd"
## Checks Keen 4's title loop, help, end and high scores with the player's
## own files (milestone D8; skipped without them): the texts' pages, the
## help's paging, the end's timed pictures, the original's high-score
## table, the five demos and the first seconds of demo 0 against Keen's
## places measured in the original, and the end's flow up to the name on
## the table.

const HELP_PAGES: PackedInt32Array = [13, 21, 9, 18, 2]
const END_PAGES := 16
## The pauses of the first end page (its ^T pictures), in tics.
const FIRST_END_PAUSES: PackedInt32Array = [100, 10, 140, 1, 10, 140, 10, 140]
const DEMO_MAPS: PackedInt32Array = [1, 9, 11, 15, 19]
const DEMO_FRAMES: PackedInt32Array = [744, 687, 749, 645, 271]
const LEFT_WORD_WIDTH := 1664
const RIGHT_WORD_WIDTH := 668
const SCROLL_TICS := 1864
## Demo 0 in the original (js-dos, the user's v1.0, D8): per frame of the
## demo, Keen's sprite and where it is on the screen (four numbers a row:
## a flat table, Godot reads a constant array of arrays back wrongly). The original draws a
## sprite at its x rounded down to 8 / (its shifts) pixels and scrolls the
## view in steps of 2 pixels; the test draws ours the same way.
const DEMO_0_SEEN: PackedInt32Array = [
	16,
	15,
	286,
	110,
	20,
	17,
	268,
	109,
	24,
	15,
	250,
	110,
	28,
	17,
	232,
	109,
	32,
	15,
	214,
	110,
	36,
	17,
	196,
	109,
	40,
	15,
	178,
	110,
	44,
	17,
	162,
	109,
	50,
	14,
	154,
	109,
	54,
	90,
	154,
	86,
	58,
	90,
	154,
	69,
	62,
	89,
	154,
	57,
	67,
	89,
	154,
	66,
	71,
	89,
	154,
	93,
	75,
	90,
	154,
	96,
	79,
	90,
	150,
	60,
	101,
	89,
	144,
	85,
	105,
	90,
	144,
	90,
	109,
	90,
	144,
	54,
	127,
	89,
	144,
	40,
	131,
	21,
	144,
	82,
	135,
	15,
	144,
	121,
	139,
	17,
	144,
	110,
	159,
	15,
	144,
	110,
]
const SEEN_ROW := 4
const VIEW_STEP := 2
const SHIFT_PIXELS := 8
const SCORES_PATH := "user://test_keen4_front/high_scores.json"
const NEW_SCORE := 20000

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_data = Keen4Episode.load_data(files)


func test_help_topics_have_their_pages() -> void:
	var counts := PackedInt32Array()
	for text in Keen4Help.TOPIC_TEXTS:
		counts.append(GalaxyTextPages.parse(_data.graphics.text(text)).page_count())
	assert_equal(counts, HELP_PAGES, "ComputerWrist, the game, the story, ordering, about Id")


func test_help_pages_go_back_and_on_but_not_past_the_ends() -> void:
	var help := Keen4Help.create(_data.graphics)
	assert_true(help.in_menu(), "it opens on its menu")
	help.act(Keen4Help.Action.UP)
	assert_equal(help.topic, 0, "not above the first topic")
	help.act(Keen4Help.Action.OPEN)
	help.act(Keen4Help.Action.BACK_PAGE)
	assert_equal(help.page, 0, "not before the first page")
	for step in 20:
		help.act(Keen4Help.Action.NEXT_PAGE)
	assert_equal(help.page, HELP_PAGES[0] - 1, "not past the last")
	var screen := help.screen()
	assert_equal(screen.get_size(), Vector2i(320, 200), "a whole screen")
	help.act(Keen4Help.Action.ESCAPE)
	assert_true(help.in_menu() and help.topic == 0, "Escape: back to the menu, on its topic")
	assert_true(not help.act(Keen4Help.Action.ESCAPE), "Escape again leaves the help")


func test_the_end_has_16_pages_and_times_its_pictures() -> void:
	var pages := GalaxyTextPages.parse(_data.graphics.text(Keen4Ending.END_TEXT))
	assert_equal(pages.page_count(), END_PAGES, "16 pages")
	var stages := GalaxyPageLayout.create(_data.graphics, 0).lay_out(pages, 0)
	var pauses := PackedInt32Array()
	for stage in stages.slice(0, stages.size() - 1):
		pauses.append(stage.tics)
	assert_equal(pauses, FIRST_END_PAUSES, "seen in the original: the same pauses")


func test_the_end_waits_for_its_pictures_then_blinks_and_goes_on() -> void:
	var ending := Keen4Ending.create(_data.graphics)
	assert_true(not ending.press(), "a key during the pictures does nothing")
	for frame in 300:
		ending.advance(2)
	assert_true(ending.waits(), "the page is whole")
	var dim := ending.screen()
	ending.advance(Keen4Ending.ARROW_TICS)
	assert_true(ending.screen().get_data() != dim.get_data(), "the arrow blinks")
	var presses := 0
	while not ending.is_done() and presses < 100:
		for frame in 400:
			ending.advance(2)
		ending.press()
		presses += 1
	assert_equal(presses, END_PAGES, "one key per page")


func test_the_original_high_scores_are_found() -> void:
	var defaults := Keen4FrontScreen.default_high_scores(_data)
	assert_equal(defaults.size(), Keen4Episode.HIGH_SCORE_COUNT, "eight places")
	assert_equal(defaults[0].name, "Id Software - '91", "the first name (files, v1.0)")
	assert_equal(defaults[1].name, "", "the second is empty")
	var scores: Array = defaults.map(func(entry: GalaxyHighScores.Entry) -> int: return entry.score)
	assert_equal(scores, [10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000])


func test_the_table_is_printed_with_xor_at_its_rows() -> void:
	var map := _data.maps.load_map(Keen4Episode.HIGH_SCORE_MAP)
	var table := GalaxyHighScores.load_from(
		SCORES_PATH + ".none", Keen4FrontScreen.default_high_scores(_data)
	)
	table.insert(0, "", NEW_SCORE, 3)
	var board := Keen4HighScoreBoard.create(_data.graphics, table, map, Vector2i(32, 32))
	var overlay := board.overlay()
	assert_true(overlay.get_pixel(152, 52).a > 0.5, "the first rescued icon")
	assert_true(overlay.get_pixel(176, 52).a == 0.0, "only three")
	board.start_typing(0)
	board.type_character("K")
	assert_equal(table.entries[0].name, "K", "typed")
	board.edit(KEY_BACKSPACE)
	assert_equal(table.entries[0].name, "", "and taken back")
	assert_equal(Keen4HighScoreBoard.score_text(10), String.chr(0x82) + String.chr(0x81))


func test_the_five_demos_and_their_maps() -> void:
	var maps := PackedInt32Array()
	var frames := PackedInt32Array()
	for index in DEMO_MAPS.size():
		var demo := GalaxyDemo.parse(_data.graphics.demo(index))
		maps.append(demo.map_number)
		frames.append(demo.frame_count())
	assert_equal(maps, DEMO_MAPS, "files, v1.0")
	assert_equal(frames, DEMO_FRAMES, "frames of 3 tics")


func test_demo_0_plays_as_in_the_original() -> void:
	var demo := GalaxyDemo.parse(_data.graphics.demo(0))
	var inventory := Keen4Inventory.new_game()
	inventory.extra_lives_for_points = false
	var map := _data.maps.load_map(demo.map_number)
	var session := Keen4LevelSession.start(_data, map, inventory, 0, GalaxyDifficulty.DEFAULT, 1)
	session.world.random_index = 0
	var clock := GalaxyClock.new()
	clock.start_level()
	clock.tics_per_frame = GalaxyClock.DEMO_TICS
	var firing := GalaxyTwoButtonFiring.new()
	var seen: Dictionary[int, PackedInt32Array] = {}
	for frame in DEMO_0_SEEN[-SEEN_ROW] + 1:
		var tics := clock.run_frame()
		session.run_frame(firing.convert(demo.controls_at(frame), tics), tics, clock.tic)
		seen[frame] = _as_drawn(session)
	var different: Array = []
	for at in range(0, DEMO_0_SEEN.size(), SEEN_ROW):
		var ours := seen[DEMO_0_SEEN[at]]
		if ours != DEMO_0_SEEN.slice(at + 1, at + SEEN_ROW):
			different.append([DEMO_0_SEEN[at], ours])
	assert_equal(different, [], "Keen's sprite and place in every measured frame")


func test_story_text_and_cheat_box_are_found() -> void:
	var story := _data.executable.messages(Keen4Episode.STORY_MESSAGES)
	assert_equal(GalaxyExeTexts.line_count(story[0]), 30, "the story's 30 lines")
	var cheat := _data.executable.texts(Keen4Episode.CHEAT_TEXTS)
	assert_true(cheat[0].begins_with("Cheat Option!"), "the box of B+A+T")


func test_intro_words_and_scroll() -> void:
	var left := GalaxyIntroBitmap.parse(_data.graphics.misc(Keen4FrontScreen.LEFT_WORD_MISC))
	var right := GalaxyIntroBitmap.parse(_data.graphics.misc(Keen4FrontScreen.RIGHT_WORD_MISC))
	assert_equal([left.width, right.width], [LEFT_WORD_WIDTH, RIGHT_WORD_WIDTH], "files, v1.0")
	var intro := GalaxyIntroCredits.create(left, right, [])
	assert_equal(intro.scroll_tics(), SCROLL_TICS, "about 26.6 s")


func test_the_end_flow_after_the_eighth_rescue() -> void:
	# The view's flow needs a running scene tree (the screenshots check it);
	# here its pieces: the eighth answer, the end, the place on the table.
	var messages := Keen4Messages.create(_data)
	var screens := messages.council(Keen4Episode.WORLD_MAP, Keen4Progress.COUNCIL_COUNT - 1)
	assert_equal(screens.size(), 3, "the elder, Keen's answer, his thumb up (seen)")
	assert_true(messages.texts[1].begins_with("You're the last one"), "the eighth answer")
	DirAccess.remove_absolute(SCORES_PATH)
	var table := GalaxyHighScores.load_from(
		SCORES_PATH, Keen4FrontScreen.default_high_scores(_data)
	)
	assert_equal(table.place_for(0, 8), -1, "no points: no place (seen in the original)")
	assert_equal(table.place_for(10000, 8), 0, "a tie goes above on its rescues")
	table.insert(0, "", 10000, 8)
	var board := Keen4HighScoreBoard.create(
		_data.graphics, table, _data.maps.load_map(Keen4Episode.HIGH_SCORE_MAP), Vector2i.ZERO
	)
	board.start_typing(0)
	for character in "Keen":
		board.type_character(character)
	board.finish(true)
	assert_true(table.save(), "saved")
	var again := GalaxyHighScores.load_from(
		SCORES_PATH, Keen4FrontScreen.default_high_scores(_data)
	)
	assert_equal([again.entries[0].name, again.entries[0].count], ["Keen", 8], "read back")
	assert_equal(again.entries[1].name, "Id Software - '91", "the others one lower")
	DirAccess.remove_absolute(SCORES_PATH)
	DirAccess.remove_absolute(SCORES_PATH.get_base_dir())


## Keen's sprite and screen place, drawn the way the original draws.
func _as_drawn(session: Keen4LevelSession) -> PackedInt32Array:
	var keen := session.player
	var info := _data.graphics.sprite_infos[keen.sprite]
	var pixel := GalaxyObjectLayer.pixel_of(info, keen.position)
	var view := session.camera.view_pixels()
	var step := SHIFT_PIXELS / maxi(info.shifts, 1)
	var x := floori(float(pixel.x) / step) * step - floori(float(view.x) / VIEW_STEP) * VIEW_STEP
	return PackedInt32Array([keen.sprite, x, pixel.y - view.y])
