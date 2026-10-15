extends "res://tests/test_case.gd"
## Checks the sounds, the texts, the screens of the menus and what online
## play needs (the fingerprint of the levels) against the real Keen 1 files.
## Skipped when the game data is not available.


func run_all() -> void:
	if GameFiles.locate() == null:
		skip("no Keen 1 game data found")
		return
	super.run_all()


func test_every_sound_is_in_the_sound_file() -> void:
	var file := SoundFile.load_from(GameFiles.locate())
	assert_true(file != null, "SOUNDS.CK1")
	if file == null:
		return
	for id: Sound.Id in Sound.FILE_NAMES:
		var name := Sound.FILE_NAMES[id]
		assert_true(file.sounds.has(name), name)
		if file.sounds.has(name):
			assert_true(not file.sounds[name].divisors.is_empty(), "%s has data" % name)


func test_high_score_texts_are_found() -> void:
	var texts := ScoreTexts.load_from(GameFiles.locate())
	assert_true(texts != null, "found")
	if texts != null:
		assert_equal(texts.default_names[0], "Yorpy", "first name")
		assert_equal(texts.place_names[0], "first", "first place")
		assert_equal(texts.place_names[-1], "last", "last place")


func test_title_and_high_score_screens_are_complete() -> void:
	var files := GameFiles.locate()
	var graphics := EgaGraphics.load_from(files)
	for bitmap_name in ["TITLE", "HIGHSCOR", "NAME", "SCORE", "PARTS", "GAMEOVER"]:
		assert_true(graphics.find_bitmap(bitmap_name) != null, "bitmap " + bitmap_name)
	var backdrops := LevelData.parse(
		GameFiles.locate().read(GameFiles.level_file_name(GameFiles.BACKDROPS_LEVEL))
	)
	var title := Backdrops.screen(backdrops, Backdrops.TITLE_SCREEN)
	assert_equal(
		title.playable_rect().size * EgaGraphics.TILE_SIZE,
		Vector2i(DisplaySettings.ORIGINAL_SIZE.x, 208),
		"the title screen is one screen wide"
	)
	var scores := Backdrops.screen(backdrops, Backdrops.HIGH_SCORE_SCREEN)
	var frame_tile := scores.tile_at(scores.playable_rect().position + Vector2i(0, 1))
	assert_equal(frame_tile, scores.tile_at(scores.playable_rect().end - Vector2i(1, 2)), "frame")
	assert_true(frame_tile != title.tile_at(title.playable_rect().position), "a red edge")


func test_story_fits_the_window() -> void:
	var data := GameFiles.locate().read(GameFiles.STORY_TEXT)
	assert_true(not data.is_empty(), "STORYTXT.CK1")
	var lines := TextDocument.layout(data, MenuController.TEXT_WIDTH)
	assert_true(lines.size() > MenuController.TEXT_LINES, "longer than one page")
	for line in lines:
		assert_true(line.length() <= MenuController.TEXT_WIDTH, "fits: " + line)


func test_level_fingerprint_is_short_and_stable() -> void:
	var files := GameFiles.locate()
	var fingerprint := LevelFingerprint.of(files)
	assert_equal(fingerprint.length(), LevelFingerprint.LENGTH, "short")
	assert_equal(LevelFingerprint.of(files), fingerprint, "the same every time")


func test_a_fresh_map_has_no_changed_tiles() -> void:
	var files := GameFiles.locate()
	var data := files.read(GameFiles.level_file_name(GameFiles.WORLD_MAP_LEVEL))
	var map := LevelData.parse(data)
	assert_equal(OnlinePlay.changed_tiles(map, LevelData.parse(data)).size(), 0, "nothing to send")
