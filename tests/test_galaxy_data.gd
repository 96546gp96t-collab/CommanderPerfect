extends "res://tests/test_case.gd"
## Tests for the Galaxy readers with hand-made data (tests/galaxy_fixtures.gd
## and tests/galaxy_file_fixtures.gd), so they run without Keen 4's files:
## Huffman, Carmack and RLEW, and the searches of the program for its
## headers (offset tables with the AUDIOHED gap, MAPHEAD, the dictionaries),
## the version, the random numbers and the texts.

const Fixtures := preload("res://tests/galaxy_fixtures.gd")
const FileFixtures := preload("res://tests/galaxy_file_fixtures.gd")
const SAMPLE := "Galaxy: a test, with many zeros after it."
const SAMPLE_ZEROS := 40

var _image := PackedByteArray()
var _at: Dictionary[String, int] = {}


func _init() -> void:
	var built := FileFixtures.program_image()
	_image = built[0]
	_at = built[1]


func test_huffman_tree_check() -> void:
	var tree := Fixtures.dictionary()
	assert_true(GalaxyHuffman.is_tree_at(tree, 0), "a complete tree")
	assert_true(GalaxyHuffman.from_bytes(tree) != null, "can be read")
	var twice := tree.duplicate()
	twice.encode_u16(0, twice.decode_u16(4))
	assert_true(not GalaxyHuffman.is_tree_at(twice, 0), "a value used twice")
	var root := tree.duplicate()
	root.encode_u16(0, GalaxyHuffman.BYTE_VALUES + GalaxyHuffman.ROOT)
	assert_true(not GalaxyHuffman.is_tree_at(root, 0), "a link back to the root")
	assert_true(not GalaxyHuffman.is_tree_at(tree, 8), "not at another place")
	assert_true(not GalaxyHuffman.is_tree_at(tree.slice(0, 100), 0), "too short")
	assert_true(not GalaxyHuffman.is_tree_at(Fixtures.filler(1100), 0), "filler")


func test_huffman_round_trip() -> void:
	var tree := Fixtures.dictionary()
	var huffman := GalaxyHuffman.from_bytes(tree)
	var data := SAMPLE.to_ascii_buffer()
	data.resize(data.size() + SAMPLE_ZEROS)
	var packed := Fixtures.compress(tree, data)
	var source := Fixtures.filler(5) + packed + Fixtures.filler(9)
	assert_equal(huffman.expand(source, 5, data.size()), data, "the same bytes again")
	assert_equal(huffman.bytes_needed(source, 5, data.size()), packed.size(), "all bytes read")
	var whole := huffman.expand_all(source, 5, 5 + packed.size())
	assert_equal(whole.slice(0, data.size()), data, "until the end: the bytes first")
	assert_true(whole.size() - data.size() < 8, "and at most a byte of padding after them")
	assert_equal(huffman.bytes_needed(packed, 0, data.size() * 4), -1, "past the end")
	assert_equal(huffman.expand(packed, 0, data.size() * 4).size() < data.size() * 4, true, "short")


func test_carmack_plain_words_and_markers() -> void:
	var words := PackedInt32Array([1, 0xA7FF, 0x1234, 0xA800, 0xA8A8, 9])
	assert_equal(GalaxyCarmack.expand(Fixtures.carmack(words), 0), words, "words come back")
	var shifted := Fixtures.filler(3) + Fixtures.carmack(words)
	assert_equal(GalaxyCarmack.expand(shifted, 3), words, "from any start")


func test_carmack_near_and_far_copies() -> void:
	# 1, 2, 3, then 2 words from 3 back (1, 2), then 3 words from word 1.
	var bytes := Fixtures.word_bytes([8 * 2, 1, 2, 3, GalaxyCarmack.NEAR << 8 | 2])
	bytes.append(3)
	bytes.append_array(Fixtures.word_bytes([GalaxyCarmack.FAR << 8 | 3, 1]))
	assert_equal(
		GalaxyCarmack.expand(bytes, 0), PackedInt32Array([1, 2, 3, 1, 2, 2, 3, 1]), "copies"
	)


func test_carmack_rejects_broken_data() -> void:
	var outside := Fixtures.word_bytes([4 * 2, 1, GalaxyCarmack.NEAR << 8 | 2])
	outside.append(5)
	assert_equal(GalaxyCarmack.expand(outside, 0).size(), 0, "a copy from before the start")
	var short := Fixtures.word_bytes([10 * 2, 1, 2])
	assert_equal(GalaxyCarmack.expand(short, 0).size(), 0, "ends too soon")


func test_rlew_runs_and_tag() -> void:
	var plane := PackedInt32Array([5, 5, 5, 5, 5, 7, Fixtures.MAP_TAG, 0, 0, 0, 0, 0, 0, 2])
	var words := Fixtures.rlew(plane, Fixtures.MAP_TAG)
	assert_true(words.size() < plane.size(), "the runs are shorter")
	assert_equal(GalaxyRlew.expand(words, Fixtures.MAP_TAG), plane, "the plane comes back")
	assert_true(GalaxyRlew.expand(words, 0xABCD) != plane, "another tag reads it differently")
	var too_long := PackedInt32Array([4 * 2, Fixtures.MAP_TAG, 9, 1])
	assert_equal(GalaxyRlew.expand(too_long, Fixtures.MAP_TAG).size(), 0, "a run too long")


func test_graphics_table_found_elsewhere() -> void:
	var size: int = FileFixtures.graphics()[0].size()
	var wrong := PackedInt32Array([Fixtures.WRONG_PLACE])
	assert_equal(
		GalaxyHeaderSearch.find_offset_table(_image, 3, size, wrong), _at["EGAHEAD"], "searched"
	)
	var known := PackedInt32Array([_at["EGAHEAD"]])
	assert_equal(
		GalaxyHeaderSearch.find_offset_table(_image, 3, size, known), _at["EGAHEAD"], "known"
	)
	var table := GalaxyHeaderSearch.offset_table(_image, _at["EGAHEAD"], 3, size)
	assert_equal(table, FileFixtures.graphics()[1], "every offset, -1 for the empty chunks")
	assert_equal(
		GalaxyHeaderSearch.find_offset_table(_image, 3, size + 1, known), -1, "another size"
	)


func test_audio_table_with_a_bogus_block() -> void:
	var size: int = FileFixtures.audio()[0].size()
	var offsets: PackedInt32Array = FileFixtures.audio()[1]
	assert_equal(
		GalaxyHeaderSearch.find_offset_table(_image, 4, size, PackedInt32Array()),
		_at["AUDIOHED"],
		"found although the bogus block is larger than the song's offset"
	)
	var cleaned := GalaxyHeaderSearch.without_bogus(offsets)
	var sounds := Fixtures.SOUNDS.size()
	for index in Fixtures.BOGUS_ENTRIES:
		assert_equal(cleaned[sounds + index], -1, "bogus entry %d is empty" % index)
	assert_equal(cleaned[0], 0, "the first sound stays")
	assert_equal(
		GalaxyHeaderSearch.chunk_end(cleaned, sounds - 1),
		offsets[sounds + Fixtures.BOGUS_ENTRIES],
		"the last sound ends where the song starts"
	)
	var two_values := FileFixtures._offset_bytes(offsets, 4)
	two_values.encode_u32((sounds + 1) * 4, offsets[sounds] + 1)
	assert_true(
		not GalaxyHeaderSearch.is_offset_table(two_values, 0, 4, size),
		"two different bogus values: not a table"
	)


func test_map_head_found_elsewhere() -> void:
	var maps: PackedByteArray = Fixtures.gamemaps()[0]
	var wrong := PackedInt32Array([Fixtures.WRONG_PLACE])
	assert_equal(GalaxyHeaderSearch.find_map_head(_image, maps, wrong), _at["MAPHEAD"], "found")
	assert_true(GalaxyHeaderSearch.is_map_head(_image, _at["MAPHEAD"], maps), "passes")
	assert_true(not GalaxyHeaderSearch.is_map_head(_image, _at["MAPHEAD"] + 2, maps), "not +2")


func test_dictionaries_found_in_the_whole_image() -> void:
	var found := GalaxyHeaderSearch.find_dictionaries(_image)
	assert_equal(found, PackedInt32Array([_at["AUDIODCT"], _at["EGADICT"]]), "the two trees")
	var known := GalaxyHeaderSearch.known_dictionaries(
		_image, PackedInt32Array([Fixtures.WRONG_PLACE, _at["EGADICT"]])
	)
	assert_equal(known, PackedInt32Array([_at["EGADICT"]]), "only the known place that passes")


func test_headers_found_and_told_apart() -> void:
	var folder := _folder("search")
	FileFixtures.write_folder(folder)
	var files := GameFiles.open(folder, Fixtures.EXTENSION)
	var headers := GalaxyHeaders.find(_image, files, Fixtures.episode())
	assert_true(headers != null, "all six found")
	if headers == null:
		return
	for piece in GalaxyEpisode.Header.values():
		var name: String = GalaxyEpisode.Header.keys()[piece]
		assert_equal(headers.found_at[piece], _at[name], "%s where it was put" % name)
	assert_equal(headers.map_tag, Fixtures.MAP_TAG, "the RLEW tag")
	_remove(folder)


func test_header_files_next_to_the_game_win() -> void:
	var folder := _folder("header_files")
	FileFixtures.write_folder(folder, Fixtures.filler(2000), true)
	var files := GameFiles.open(folder, Fixtures.EXTENSION)
	var data := GalaxyData.load_from(files, Fixtures.episode())
	assert_true(data != null, "loads from the header files")
	if data != null:
		for piece in GalaxyEpisode.Header.values():
			assert_equal(data.headers.found_at[piece], GalaxyHeaders.FROM_FILE, "from a file")
		assert_equal(data.maps.load_map(0).name, Fixtures.MAPS[0][0], "the maps read")
	_remove(folder)


func test_missing_headers_give_null() -> void:
	var folder := _folder("no_headers")
	FileFixtures.write_folder(folder, Fixtures.filler(2000))
	var files := GameFiles.open(folder, Fixtures.EXTENSION)
	assert_true(GalaxyData.load_from(files, Fixtures.episode()) == null, "nothing to read")
	_remove(folder)


func test_version_from_the_sign_on_text() -> void:
	assert_equal(GalaxyExecutable.sign_on_version(_image), Fixtures.VERSION, "two bytes apart")
	var plain := ("Hello (v1.4) world").to_ascii_buffer()
	assert_equal(GalaxyExecutable.sign_on_version(plain), "1.4", "one byte apart")
	var none := ("(v) (vx.y) (1.0)").to_ascii_buffer()
	assert_equal(GalaxyExecutable.sign_on_version(none), GalaxyExecutable.UNKNOWN_VERSION, "none")
	var episode := Fixtures.episode()
	episode.executable_sizes = {"7.7": 1234}
	var by_size := GalaxyExecutable.from_image(Fixtures.filler(100), episode, 1234)
	assert_equal(by_size.version, "7.7", "from the size when the text is missing")


func test_random_numbers() -> void:
	assert_equal(GalaxyExecutable.find_random_table(_image), _at["random"], "found")
	var executable := GalaxyExecutable.from_image(_image, Fixtures.episode())
	var table := executable.random_table()
	assert_equal(table.size(), GalaxyExecutable.RANDOM_TABLE_SIZE, "256 numbers")
	assert_equal(table.slice(0, 7), GalaxyExecutable.RANDOM_TABLE_START, "from its start")


func test_level_texts_and_messages() -> void:
	var executable := GalaxyExecutable.from_image(_image, Fixtures.episode())
	assert_equal(executable.level_texts_start(), _at["level_names"], "past the wrong list")
	assert_equal(executable.level_names(), Fixtures.LEVEL_NAMES, "the names")
	assert_equal(executable.entry_texts(), Fixtures.ENTRY_TEXTS, "the entry texts")
	assert_equal(executable.messages(Fixtures.MESSAGES), Fixtures.MESSAGE_TEXTS, "the messages")
	assert_equal(executable.messages("other").size(), 0, "no shape, no messages")
	var known := Fixtures.episode()
	known.known_level_name_offsets = PackedInt32Array([_at["level_names"]])
	var at_known := GalaxyExecutable.from_image(_image, known)
	assert_equal(at_known.level_texts_start(), _at["level_names"], "the known place")
	assert_equal(GalaxyExeTexts.line_count("a\nb\n"), 2, "a last newline adds no line")
	assert_equal(GalaxyExeTexts.one_line("a\nb"), "a b", "newlines as spaces")


func test_keen_4_files_need_one_program() -> void:
	var folder := _folder("keen4")
	DirAccess.make_dir_recursive_absolute(folder)
	for name in Keen4Files.REQUIRED_FILES:
		_touch(folder, name)
	assert_true(Keen4Files.find_in([folder]) == null, "no program")
	_touch(folder, "keen4.exe")
	var files := Keen4Files.find_in([folder])
	assert_true(files != null, "KEEN4.EXE will do")
	if files != null:
		assert_equal(Keen4Files.executable_in(files), "KEEN4.EXE", "the program")
	_touch(folder, "KEEN4E.EXE")
	assert_equal(Keen4Files.executable_in(Keen4Files.open(folder)), "KEEN4E.EXE", "KEEN4E first")
	_remove(folder)


func test_game_option_starts_keen_4() -> void:
	assert_equal(GameLaunch.game_number(["--game=4"]), 4, "game 4")
	assert_equal(GameLaunch.scene_for(["--game=4"]), GameLaunch.KEEN_4_SCENE, "Keen 4")
	assert_equal(
		GameLaunch.scene_for(["--level=3", "--game=4"]), GameLaunch.KEEN_4_SCENE, "with a level"
	)
	assert_true(GameLaunch.skips_launcher(["--game=4"]), "skips the start screen")
	assert_equal(GameLaunch.game_number(["--game=3", "--game=4"]), 3, "an older game wins")
	assert_equal(GameLaunch.game_number(["--game=2", "--game=3"]), 2, "as before")
	assert_equal(GameLaunch.game_number(["--level=4"]), 1, "a level alone is Keen 1")


func test_keen_4_is_the_fourth_icon() -> void:
	var games := GameCatalog.games()
	assert_equal(games[3].title, "Keen 4", "the name on the icon")
	assert_equal(games[3].scene, GameLaunch.KEEN_4_SCENE, "plays Keen 4")
	assert_equal(games[3].data_folder, Keen4Files.SUBFOLDER, "its folder")
	assert_true(not OnlineProtocol.GAME_IDS.has(games[3].game_id), "not online yet")
	assert_true(GameCatalog.for_game_id("") == null, "no game for an unknown lobby")
	assert_true(games[3].icon_picture.is_valid(), "its own picture")
	for index in 3:
		assert_true(not games[index].icon_picture.is_valid(), "Keen %d as before" % (index + 1))
	var launcher := Launcher.new()
	var missing := GameCatalog.Game.new()
	missing.title = "Keen 4"
	missing.data_folder = Keen4Files.SUBFOLDER
	launcher._start(missing)
	assert_true(launcher.message().contains("game_data/keen4"), "where the files go")
	launcher._picture.free()
	launcher._message.free()
	launcher.free()


func _folder(name: String) -> String:
	return ProjectSettings.globalize_path("user://test_galaxy_data").path_join(name)


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
	DirAccess.remove_absolute(path.get_base_dir())
