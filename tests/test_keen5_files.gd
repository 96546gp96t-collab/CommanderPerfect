extends "res://tests/test_case.gd"
## Tests for Keen 5's place beside Keen 1-4, with hand-made data only
## (tests/keen5_fixtures.gd): the two additions to [GalaxyEpisode] that
## Keen 5 needs (the number of background tiles given, the texts before
## the misc chunks) and that Keen 4's files read as before without them;
## finding the files; the --game=5 option; the fifth icon; the online id
## (last of our games since E11); and the map the game screen is asked for (since
## E3 the game itself: test_keen5_view.gd).

const Fixtures := preload("res://tests/galaxy_fixtures.gd")
const FileFixtures := preload("res://tests/galaxy_file_fixtures.gd")
const Keen5Fixtures := preload("res://tests/keen5_fixtures.gd")
const TEST_DIRECTORY := "user://test_keen5_files"


func test_given_border_and_texts_before_misc() -> void:
	var file := Keen5Fixtures.graphics_file()
	var ranges := GalaxyChunkRanges.from_file(file, Keen5Fixtures.episode())
	assert_true(ranges != null, "the ranges add up")
	if ranges == null:
		return
	var first_tile := Keen5Fixtures.FIRST_TILE_CHUNK
	assert_equal(ranges.back_tile_start, first_tile, "background tiles")
	assert_equal(ranges.back_tile_count, Keen5Fixtures.BACK_TILES, "as many as the episode says")
	assert_equal(ranges.fore_tile_start, first_tile + Keen5Fixtures.BACK_TILES, "then foreground")
	assert_equal(ranges.fore_tile_count, Keen5Fixtures.FORE_TILES, "the rest")
	var after_tiles := ranges.fore_tile_start + ranges.fore_tile_count
	assert_equal(ranges.text_start, after_tiles, "the texts first")
	assert_equal(ranges.misc_start, after_tiles + Fixtures.TEXT_COUNT, "then the misc chunks")
	assert_equal(ranges.demo_start, ranges.misc_start + Fixtures.MISC_COUNT, "the demos last")
	assert_equal(ranges.demo_start + Fixtures.DEMO_COUNT, file.chunk_count(), "up to the end")
	var expected_info := (
		GalaxyTileInfo.BACK_TABLES * Keen5Fixtures.BACK_TILES
		+ GalaxyTileInfo.FORE_TABLES * Keen5Fixtures.FORE_TILES
	)
	assert_equal(ranges.tile_info_size(), expected_info, "the tile info for both sets")


func test_the_right_chunks_are_read() -> void:
	var graphics := GalaxyGraphics.create(Keen5Fixtures.graphics_file(), Keen5Fixtures.episode())
	assert_true(graphics != null, "the graphics read")
	if graphics == null:
		return
	assert_equal(graphics.text(0).get_string_from_ascii(), Fixtures.TEXT_BYTES, "the text")
	assert_equal(graphics.misc(0).get_string_from_ascii(), Fixtures.MISC_BYTES, "the misc chunk")
	assert_equal(graphics.demo(0).decode_u16(0), Fixtures.DEMO_MAP, "the demo")
	var last_drawn := Keen5Fixtures.DRAWN_BACK_TILES - 1
	assert_true(graphics.back_tile(last_drawn) != null, "the last drawn background tile")
	assert_true(graphics.back_tile(last_drawn + 1) == null, "then empty ones")
	assert_true(graphics.fore_tile(0) == null, "the first foreground tile is empty")
	assert_true(graphics.fore_tile(1) != null, "the next one is drawn")


func test_without_the_fields_the_border_is_worked_out() -> void:
	var episode := Keen5Fixtures.episode()
	episode.back_tile_count = 0
	var ranges := GalaxyChunkRanges.from_file(Keen5Fixtures.graphics_file(), episode)
	assert_equal(ranges.back_tile_count, Keen5Fixtures.WORKED_OUT_BACK_TILES, "the first whole row")
	var as_keen_4 := Fixtures.episode()
	assert_equal(as_keen_4.back_tile_count, 0, "worked out by default")
	assert_true(not as_keen_4.texts_before_misc, "misc chunks first by default")
	var misc_first := GalaxyChunkRanges.from_file(Keen5Fixtures.graphics_file(), as_keen_4)
	assert_equal(misc_first.text_start, misc_first.misc_start + 1, "read in Keen 4's order")


func test_keen_4_layout_reads_as_before() -> void:
	var folder := ProjectSettings.globalize_path(TEST_DIRECTORY)
	FileFixtures.write_folder(folder)
	var data := GalaxyData.load_from(GameFiles.open(folder, Fixtures.EXTENSION), Fixtures.episode())
	_remove(folder)
	assert_true(data != null, "the shared fixtures load")
	if data == null:
		return
	var ranges := data.graphics.ranges
	assert_equal(ranges.back_tile_count, Fixtures.BACK_TILES, "the border worked out")
	assert_equal(ranges.fore_tile_count, Fixtures.FORE_TILES, "the foreground tiles")
	assert_equal(ranges.misc_start, Keen5Fixtures.SHARED_MISC, "misc")
	assert_equal(ranges.text_start, Keen5Fixtures.SHARED_TEXT, "texts")
	assert_equal(ranges.demo_start, Keen5Fixtures.SHARED_DEMO, "demos")


func test_a_border_beyond_the_tiles_is_refused() -> void:
	var episode := Keen5Fixtures.episode()
	episode.back_tile_count = Keen5Fixtures.BACK_TILES + Keen5Fixtures.FORE_TILES + 1
	assert_true(
		GalaxyChunkRanges.from_file(Keen5Fixtures.graphics_file(), episode) == null,
		"more background tiles than tile chunks"
	)


func test_keen_5_episode_numbers() -> void:
	var episode := Keen5Episode.create()
	assert_equal(episode.extension, "CK5", "the extension")
	assert_equal(episode.file_name("EGAGRAPH"), "EGAGRAPH.CK5", "a data file")
	assert_equal(episode.back_tile_count, Keen5Episode.BACK_TILE_COUNT, "the border")
	assert_true(episode.texts_before_misc, "texts before misc chunks")
	assert_equal(episode.level_name_count, Keen5Episode.LEVEL_NAME_COUNT, "maps 0-15")
	assert_equal(episode.executable_sizes.get("1.4"), 106417, "the user's packed 1.4")
	for piece in [GalaxyEpisode.Header.AUDIOHED, GalaxyEpisode.Header.EGADICT]:
		assert_true(episode.known_offsets.has(piece), "a known place for %d" % piece)
	var named := GalaxyExecutable.from_image(Fixtures.filler(100), episode, 106417)
	assert_equal(named.version, "1.4", "named by its size")


func test_keen_5_files_need_one_program() -> void:
	var folder := ProjectSettings.globalize_path(TEST_DIRECTORY).path_join("keen5")
	DirAccess.make_dir_recursive_absolute(folder)
	for name in Keen5Files.REQUIRED_FILES:
		_touch(folder, name)
	assert_true(Keen5Files.find_in([folder]) == null, "no program")
	_touch(folder, "keen5.exe")
	var files := Keen5Files.find_in([folder])
	assert_true(files != null, "KEEN5.EXE will do")
	if files != null:
		assert_equal(Keen5Files.executable_in(files), "KEEN5.EXE", "the program")
	_touch(folder, "KEEN5E.EXE")
	assert_equal(Keen5Files.executable_in(Keen5Files.open(folder)), "KEEN5E.EXE", "KEEN5E first")
	assert_equal(Keen5Files.SUBFOLDER, "game_data/keen5", "its folder")
	assert_equal(Keen5Files.DATA_DIR_OPTION, "--data-dir-keen5=", "its option")
	_remove(folder)
	DirAccess.remove_absolute(folder.get_base_dir())


func test_game_option_starts_keen_5() -> void:
	assert_equal(GameLaunch.game_number(["--game=5"]), 5, "game 5")
	assert_equal(GameLaunch.scene_for(["--game=5"]), GameLaunch.KEEN_5_SCENE, "Keen 5")
	assert_equal(
		GameLaunch.scene_for(["--level=3", "--game=5"]), GameLaunch.KEEN_5_SCENE, "with a level"
	)
	assert_true(GameLaunch.skips_launcher(["--game=5"]), "skips the start screen")
	assert_equal(GameLaunch.game_number(["--game=4", "--game=5"]), 4, "an older game wins")
	assert_equal(GameLaunch.game_number(["--game=5", "--game=2"]), 2, "the lowest")
	assert_equal(GameLaunch.game_number(["--game=3", "--game=4"]), 3, "as before")
	assert_equal(GameLaunch.game_number(["--game=6"]), 1, "no sixth game yet")


func test_keen_5_is_the_fifth_icon() -> void:
	var games := GameCatalog.games()
	assert_equal(games.size(), 5, "five games")
	var keen_5 := games[4]
	assert_equal(keen_5.title, "Keen 5", "the name on the icon")
	assert_equal(keen_5.scene, GameLaunch.KEEN_5_SCENE, "plays Keen 5")
	assert_equal(keen_5.data_folder, Keen5Files.SUBFOLDER, "its folder")
	assert_true(keen_5.icon_picture.is_valid(), "its own picture")
	assert_true(keen_5.icon_title.is_valid(), "its own font")
	assert_equal(games[3].title, "Keen 4", "after Keen 4")
	var launcher := Launcher.new()
	var missing := GameCatalog.Game.new()
	missing.title = "Keen 5"
	missing.data_folder = Keen5Files.SUBFOLDER
	launcher._start(missing)
	assert_true(launcher.message().contains("game_data/keen5"), "where the files go")
	assert_true(not GameLaunch.take_menu_request(), "nothing starts")
	launcher._picture.free()
	launcher._message.free()
	launcher.free()


func test_icon_without_files_is_empty() -> void:
	assert_true(Keen5Icon.picture(null) == null, "no picture without files")
	assert_true(Keen5Icon.title(null, "Keen 5") == null, "no title without files")


func test_online_id_is_the_last_one() -> void:
	assert_equal(Keen5Files.GAME_ID, "commanderperfect-keen5", "its id")
	assert_equal(OnlineProtocol.GAME_IDS[-1], Keen5Files.GAME_ID, "online since E11, last")
	assert_equal(GameCatalog.games()[4].game_id, Keen5Files.GAME_ID, "on the icon")


func test_the_map_asked_for() -> void:
	assert_equal(Keen5View.requested_map(["--game=5", "--level=7"]), 7, "the map asked for")
	assert_equal(Keen5View.requested_map(["--game=5"]), -1, "none")


func _touch(folder: String, name: String) -> void:
	var file := FileAccess.open(folder.path_join(name), FileAccess.WRITE)
	file.store_buffer(PackedByteArray([1]))
	file.close()


func _remove(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		directory.remove(file_name)
	DirAccess.remove_absolute(path)
