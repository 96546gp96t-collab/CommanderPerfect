extends "res://tests/test_case.gd"
## Checks the decoders against the real Keen 1 files. Skipped when the game
## data is not available (the files are never part of the repository).


func run_all() -> void:
	if GameFiles.locate() == null:
		skip("no Keen 1 game data found")
		return
	super.run_all()


func test_graphics_have_expected_counts() -> void:
	var graphics := EgaGraphics.load_from(GameFiles.locate())
	assert_true(graphics != null, "graphics should load")
	if graphics == null:
		return
	assert_equal(graphics.tiles.size(), 611, "tile count")
	assert_equal(graphics.font_chars.size(), 256, "font character count")
	assert_equal(graphics.sprites.size(), 119, "sprite count")
	assert_equal(graphics.bitmaps.size(), 18, "bitmap count")
	assert_equal(graphics.header.sprites[0].name, "KEENWALKR1", "first sprite name")
	assert_equal(graphics.find_bitmap("TITLE").get_size(), Vector2i(264, 112), "title size")


func test_every_level_can_be_read() -> void:
	var files := GameFiles.locate()
	for number in files.level_numbers():
		var level := LevelData.parse(files.read(GameFiles.level_file_name(number)))
		assert_true(level != null, "level %d should load" % number)


func test_first_level_has_known_size() -> void:
	var files := GameFiles.locate()
	var level := LevelData.parse(files.read(GameFiles.level_file_name(1)))
	assert_equal(Vector2i(level.width, level.height), Vector2i(120, 21), "level 1 size")


## The original screen shows 320x200 pixels and never scrolls past the border,
## so every map must be at least that big.
func test_playable_areas_fill_the_original_screen() -> void:
	var files := GameFiles.locate()
	for number in files.level_numbers():
		var level := LevelData.parse(files.read(GameFiles.level_file_name(number)))
		var size := LevelMap.playable_pixels(level).size
		assert_true(
			size.x >= DisplaySettings.ORIGINAL_SIZE.x and size.y >= DisplaySettings.ORIGINAL_SIZE.y,
			"level %d is only %s pixels" % [number, size]
		)


func test_every_level_has_one_player_start() -> void:
	var files := GameFiles.locate()
	for number in range(1, 17) + [GameFiles.WORLD_MAP_LEVEL]:
		var level := LevelData.parse(files.read(GameFiles.level_file_name(number)))
		assert_equal(
			level.infos.count(LevelData.PLAYER_START_INFO), 1, "starts in level %d" % number
		)


func test_first_level_starts_at_known_cell() -> void:
	var files := GameFiles.locate()
	var level := LevelData.parse(files.read(GameFiles.level_file_name(1)))
	assert_equal(level.find_info(LevelData.PLAYER_START_INFO), Vector2i(3, 15), "level 1 start")
