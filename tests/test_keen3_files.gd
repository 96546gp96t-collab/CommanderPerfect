extends "res://tests/test_case.gd"
## Tests for reading Keen 3's files without the real files: finding the
## folder, the level numbers with .CK3, the tile table's stride (and that
## Keen 1 and Keen 2 read their tables as before), the search through a
## hand-made KEEN3.EXE image (tests/keen3_fixtures.gd), the versions, the
## start screen with three games, the --game=3 option with every older
## argument list unchanged, and the placeholder scene. Fake files go to a
## folder in the user folder, which is removed afterwards.

const Fixtures := preload("res://tests/keen3_fixtures.gd")
const Keen1Fixtures := preload("res://tests/fixtures.gd")

const TEST_DIRECTORY := "user://test_keen3_files"
const TEXT_WIDTH := 40
const KEEN_3_FILE_NAMES: PackedStringArray = [
	"egahead.ck3", "EgaLatch.CK3", "egasprit.ck3", "keen3.exe", "level01.ck3", "LEVEL80.CK3"
]
## Argument lists that worked before Keen 3, with the scene they started
## and whether they skipped the start screen.
const OLD_ARGUMENTS: Array[Array] = [
	[[], GameLaunch.KEEN_1_SCENE, false],
	[["--level=1"], GameLaunch.KEEN_1_SCENE, true],
	[["--level=80"], GameLaunch.KEEN_1_SCENE, true],
	[["--ending"], GameLaunch.KEEN_1_SCENE, true],
	[["--game=1"], GameLaunch.KEEN_1_SCENE, false],
	[["--game=2"], GameLaunch.KEEN_2_SCENE, true],
	[["--game=2", "--level=3"], GameLaunch.KEEN_2_SCENE, true],
	[["--level=3", "--game=2"], GameLaunch.KEEN_2_SCENE, true],
	[["--game=2", "--game=3"], GameLaunch.KEEN_2_SCENE, true],
	[["--data-dir=/x"], GameLaunch.KEEN_1_SCENE, false],
	[["--data-dir-keen2=/x"], GameLaunch.KEEN_1_SCENE, false],
]


func run_all() -> void:
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))
	super.run_all()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_keen3_files_finds_a_folder_whatever_the_case() -> void:
	var incomplete := _make_folder("incomplete", ["EGAHEAD.CK3", "EGALATCH.CK3"])
	var complete := _make_folder("complete", KEEN_3_FILE_NAMES)
	var files := Keen3Files.find_in([_folder("missing"), incomplete, complete])
	assert_true(files != null, "the complete folder is found")
	if files == null:
		return
	assert_equal(files.directory, complete, "the first complete folder")
	assert_equal(files.extension, "CK3", "Keen 3's extension")
	assert_true(not files.read("KEEN3.EXE").is_empty(), "read by its upper-case name")
	assert_equal(files.level_numbers(), PackedInt32Array([1, 80]), "only the .CK3 levels")
	assert_equal(files.level_file(3), "LEVEL03.CK3", "level file name")
	assert_true(Keen2Files.find_in([complete]) == null, "no Keen 2 files there")
	assert_true(GameFiles.first_complete([complete]) == null, "no Keen 1 files there")


func test_keen3_requires_its_own_files() -> void:
	assert_equal(
		Keen3Files.REQUIRED_FILES,
		PackedStringArray(["EGAHEAD.CK3", "EGALATCH.CK3", "EGASPRIT.CK3", "KEEN3.EXE"]),
		"the graphics and the executable"
	)
	var folder := _make_folder("no_exe", ["EGAHEAD.CK3", "EGALATCH.CK3", "EGASPRIT.CK3"])
	assert_true(not Keen3Files.open(folder).has_required_files(), "KEEN3.EXE is missing")
	assert_true(Keen3Files.find_in([folder]) == null, "so it is not used")
	var candidates := Keen3Files.candidate_directories()
	assert_true(candidates[-1].ends_with("game_data/keen3"), "looks in keen3")
	assert_equal(Keen3Files.DATA_DIR_OPTION, "--data-dir-keen3=", "its own option")


func test_keen3_level_numbers() -> void:
	var numbers := Keen3Files.expected_level_numbers()
	assert_equal(numbers.size(), 19, "16 levels and three maps")
	assert_equal(numbers.slice(0, 16), PackedInt32Array(range(1, 17)), "levels 1-16")
	assert_equal(numbers.slice(16), PackedInt32Array([80, 81, 90]), "map, ending, title")


func test_stride_reads_longer_planes() -> void:
	var image := Fixtures.image()
	var count := Fixtures.TILE_COUNT
	var properties := TileProperties.find_in_image(
		image, count, PackedInt32Array(), Fixtures.TILE_STRIDE
	)
	assert_true(properties != null, "found with the stride")
	if properties == null:
		return
	assert_equal(properties.tile_count, count, "only the tiles are kept")
	assert_true(properties.is_deadly(Fixtures.DEADLY_TILE), "deadly tile")
	assert_true(properties.is_exit(Fixtures.EXIT_TILE), "exit tile")
	assert_true(properties.blocks_top(Fixtures.FLOOR_TILE), "floor tile")
	assert_equal(properties.behavior(Fixtures.ANKH_TILE), Keen3Behavior.ANKH, "the ankh")
	assert_true(properties.is_animated(Fixtures.ANIMATION_START), "animated tile")
	var plain := TileProperties.find_in_image(image, count, PackedInt32Array())
	var wrong := plain == null or not plain.is_exit(Fixtures.EXIT_TILE)
	assert_true(wrong, "without the stride the right table is not found")


func test_default_stride_reads_as_before() -> void:
	var table := Keen1Fixtures.create_table()
	var count := Keen1Fixtures.TILE_COUNT
	var plain := TileProperties.from_table(table, count)
	assert_true(_same(plain, TileProperties.from_table(table, count, count)), "stride = count")
	assert_true(_same(plain, TileProperties.from_table(table, count, -1)), "-1 is the default")
	assert_true(_matches_layout(plain, table, 0, count), "planes of count words, as before")
	var image := Fixtures.filler(Fixtures.PADDING)
	image.append_array(table)
	var found := TileProperties.find_in_image(image, count, PackedInt32Array())
	var explicit := TileProperties.find_in_image(image, count, PackedInt32Array(), count)
	assert_true(found != null and _same(found, explicit), "found the same way")
	if found != null:
		assert_true(_matches_layout(found, image, Fixtures.PADDING, count), "the same values")


## With the real Keen 1 and Keen 2 files (when present): the default reads
## the same table as an explicit stride of the tile count, and it is the
## plain table at one of the known positions.
func test_keen_1_and_keen_2_tables_are_read_as_before() -> void:
	var games: Array[Array] = [
		[GameFiles.locate(), GameFiles.EXECUTABLE, TileProperties.KNOWN_OFFSETS],
		[Keen2Files.locate(), Keen2Files.EXECUTABLE, Keen2Executable.TILE_TABLE_OFFSETS],
	]
	for game in games:
		var files: GameFiles = game[0]
		if files == null:
			continue
		var image := DosExecutable.load_image(files.read(game[1]))
		var count := EgaGraphics.load_from(files, files.extension).tiles.size()
		var found := TileProperties.find_in_image(image, count, game[2])
		var explicit := TileProperties.find_in_image(image, count, game[2], count)
		assert_true(found != null and _same(found, explicit), "%s: the same table" % game[1])
		var known := false
		for offset: int in game[2]:
			known = known or (found != null and _matches_layout(found, image, offset, count))
		assert_true(known, "%s: the plain table at a known position" % game[1])


func test_executable_finds_every_piece() -> void:
	var executable := Keen3Executable.from_image(Fixtures.image())
	var sounds := executable.sounds()
	assert_true(sounds != null, "the sound block parses")
	if sounds != null:
		assert_equal(sounds.sounds.size(), Fixtures.SOUND_NAMES.size(), "both sounds")
	var data := executable.sound_data()
	assert_equal(data.decode_u16(data.size() - 2), SoundFile.END_MARK, "ends after the last sound")
	var properties := executable.tile_properties(Fixtures.TILE_COUNT)
	assert_true(properties != null and properties.is_exit(Fixtures.EXIT_TILE), "the tile table")
	assert_equal(executable.status_box_lines().size(), 11, "eleven lines in the box")
	assert_equal(
		executable.status_box_lines()[0].length(), Keen3Executable.STATUS_BOX_WIDTH, "box width"
	)
	assert_equal(_sizes(executable.mortimer_messages()), [1, 1, 1, 5, 5, 2, 4, 1, 3], "Mortimer")
	assert_equal(executable.mortimer_messages()[3][4], "Mortimer 3.4", "his fourth box")
	assert_equal(_sizes(executable.ending_pages()), [4, 3, 3, 1], "the ending's pages")
	assert_equal(executable.ending_pages()[2][0], "Page 2.0", "the third page")
	assert_equal(executable.the_end(), PackedStringArray(["Fin", " Fin"]), "over the finale")
	assert_equal(_sizes(executable.ship_messages()), [4, 3, 4, 4], "the ship's messages")
	assert_equal(executable.ship_messages()[1][2], "Ship 1.2", "the second message")
	var scores := executable.score_texts()
	assert_true(scores != null, "the high score texts")
	if scores != null:
		assert_equal(scores.default_names, Fixtures.SCORE_NAMES, "the names")
	assert_equal(executable.version, "unknown", "no known size")


func test_texts_come_in_keen_3_order() -> void:
	var image := Fixtures.image()
	var executable := Keen3Executable.from_image(image)
	assert_equal(Keen3Executable.text_blocks(image).size(), 4, "four blocks")
	var first := Keen3Executable.find_text_block(image, Keen3Executable.TextBlock.HELP)
	assert_true(first > 0 and image[first] < Keen2Executable.FONT_PICTURES_START, "not on 0xFFFF")
	assert_equal(Keen2Executable.text_blocks(image)[0], first - 2, "Keen 2's starts 2 too early")
	for block in Keen3Executable.TextBlock.size():
		var text := executable.text(block as Keen3Executable.TextBlock)
		var name: String = Keen3Executable.TextBlock.keys()[block]
		assert_true(not text.is_empty(), "%s is found" % name)
		if text.is_empty():
			continue
		assert_equal(text[-1], Fixtures.TEXT_END, "%s ends in its end mark" % name)
		var lines := TextDocument.layout(text, TEXT_WIDTH)
		assert_true(lines[0].begins_with("Block %d" % block), "%s is the right block" % name)
	assert_equal(
		Keen3Executable.TextBlock.keys(), ["HELP", "END_TEXT", "PREVIEWS", "STORY"], "the order"
	)


func test_executable_without_the_pieces_finds_nothing() -> void:
	for image: PackedByteArray in [PackedByteArray(), Fixtures.filler(2048)]:
		assert_equal(Keen3Executable.find_sound_block(image), -1, "no sounds")
		assert_equal(Keen3Executable.text_blocks(image).size(), 0, "no texts")
		assert_equal(Keen3Executable.find_status_box(image), -1, "no status box")
		assert_equal(Keen3Executable.find_mortimer_messages(image), -1, "no Mortimer")
		assert_equal(Keen3Executable.find_the_end(image), -1, "no finale box")
		assert_equal(Keen3Executable.find_ship_messages(image), -1, "no ship")
		var executable := Keen3Executable.from_image(image)
		assert_true(executable.sounds() == null, "sounds are null")
		assert_true(executable.text(Keen3Executable.TextBlock.HELP).is_empty(), "no help")
		assert_equal(executable.status_box_lines().size(), 0, "no box lines")
		assert_equal(executable.mortimer_messages().size(), 0, "no boxes")
		assert_equal(executable.ending_pages().size(), 0, "no pages")
		assert_equal(executable.the_end().size(), 0, "no finale box")
		assert_equal(executable.ship_messages().size(), 0, "no messages")
		assert_true(executable.tile_properties(Fixtures.TILE_COUNT) == null, "no tile table")


func test_broken_pieces_are_not_used() -> void:
	var image := Fixtures.image()
	var points := Keen3Executable.find_points_table(image)
	image[points + Keen3Executable.POINTS.size() * Keen3Executable.POINT_BYTES] = 0x02
	assert_equal(Keen3Executable.find_mortimer_messages(image), -1, "Mortimer's first box broken")
	var finale := Keen3Executable.find_finale_name(image)
	image[finale - 2] = 0x02  # the last page's last record is no longer text
	assert_equal(Keen3Executable.from_image(image).ending_pages().size(), 0, "pages broken")


func test_version_from_the_sizes() -> void:
	assert_equal(Keen3Executable.version_for(127086), "1.00", "the player's image")
	assert_equal(Keen3Executable.version_for(127598), "1.00", "with a header")
	assert_equal(Keen3Executable.version_for(127104), "1.31", "1.31 image")
	assert_equal(Keen3Executable.version_for(127616), "1.31", "1.31 with a header")
	assert_equal(Keen3Executable.version_for(0, 61619), "1.00", "1.00 packed")
	assert_equal(Keen3Executable.version_for(0, 61599), "1.31", "1.31 packed")
	assert_equal(Keen3Executable.version_for(118160), "unknown", "Keen 2's size")


func test_catalog_lists_three_games() -> void:
	var games := GameCatalog.games()
	assert_equal(games.size(), 3, "three games")
	assert_equal(games[0].title, "Keen 1", "Keen 1 first")
	assert_equal(games[0].scene, GameLaunch.KEEN_1_SCENE, "plays Keen 1")
	assert_equal(games[0].game_id, OnlineProtocol.GAME_ID, "Keen 1's id")
	assert_equal(games[1].title, "Keen 2", "then Keen 2")
	assert_equal(games[1].data_folder, "game_data/keen2", "Keen 2's folder")
	assert_equal(games[1].game_id, OnlineProtocol.GAME_ID_KEEN_2, "Keen 2's id")
	assert_equal(games[2].title, "Keen 3", "then Keen 3")
	assert_equal(games[2].scene, GameLaunch.KEEN_3_SCENE, "plays Keen 3")
	assert_equal(games[2].data_folder, "game_data/keen3", "Keen 3's folder")
	assert_equal(games[2].game_id, OnlineProtocol.GAME_ID_KEEN_3, "Keen 3's id")
	assert_true(not OnlineProtocol.GAME_ID_KEEN_3 in OnlineProtocol.GAME_IDS, "not online yet")
	assert_true(ResourceLoader.exists(GameLaunch.KEEN_3_SCENE), "the Keen 3 scene exists")


func test_missing_keen_3_says_where_the_files_go() -> void:
	var launcher := Launcher.new()
	var game := GameCatalog.Game.new()
	game.title = "Keen 3"
	game.data_folder = Keen3Files.SUBFOLDER
	launcher._start(game)
	assert_true(launcher.message().contains("game_data/keen3"), "Keen 3's folder")
	assert_true(not GameLaunch.take_menu_request(), "nothing starts")
	var keen_2 := GameCatalog.Game.new()
	keen_2.title = "Keen 2"
	keen_2.data_folder = Keen2Files.SUBFOLDER
	launcher._start(keen_2)
	assert_equal(
		launcher.message(),
		(
			"The files of Keen 2 were not found. Put them in game_data/keen2 "
			+ "(see game_data/README.md), next to the app."
		),
		"Keen 2's text as before"
	)
	# Without _ready these are not children of the launcher yet.
	launcher._picture.free()
	launcher._message.free()
	launcher.free()


func test_game_option_starts_keen_3() -> void:
	assert_true(GameLaunch.skips_launcher(["--game=3"]), "Keen 3 alone")
	assert_true(GameLaunch.skips_launcher(["--game=3", "--level=3"]), "a Keen 3 level")
	assert_equal(GameLaunch.scene_for(["--game=3"]), GameLaunch.KEEN_3_SCENE, "Keen 3")
	assert_equal(
		GameLaunch.scene_for(["--level=3", "--game=3"]), GameLaunch.KEEN_3_SCENE, "any order"
	)
	assert_equal(GameLaunch.game_number(["--game=3"]), 3, "game 3")
	assert_equal(GameLaunch.game_number(["--game=2"]), 2, "game 2")
	assert_equal(GameLaunch.game_number([]), 1, "game 1 by default")
	assert_true(not GameLaunch.skips_launcher(["--data-dir-keen3=/x"]), "other options")


func test_older_arguments_give_the_same_answer() -> void:
	for case in OLD_ARGUMENTS:
		var arguments := PackedStringArray(case[0])
		var label := " ".join(arguments)
		assert_equal(GameLaunch.scene_for(arguments), case[1], "scene for [%s]" % label)
		assert_equal(GameLaunch.skips_launcher(arguments), case[2], "skips for [%s]" % label)
		assert_equal(
			GameLaunch.wants_keen_2(arguments),
			case[1] == GameLaunch.KEEN_2_SCENE,
			"Keen 2 for [%s]" % label
		)


func test_keen3_behaviors() -> void:
	assert_true(Keen3Behavior.is_keen3_item(Keen3Behavior.ANKH), "the ankh")
	assert_true(Keen3Behavior.is_keen3_item(Keen3Behavior.SINGLE_CHARGE), "a single charge")
	assert_true(not Keen3Behavior.is_keen3_item(TileProperties.Behavior.RAYGUN), "not Keen 1's")
	assert_equal(TileProperties.Behavior.size(), 27, "the shared enum is unchanged")


## The number of lines of each message.
func _sizes(messages: Array[PackedStringArray]) -> Array:
	return messages.map(func(lines: PackedStringArray) -> int: return lines.size())


## Whether [param a] and [param b] say the same about every tile.
func _same(a: TileProperties, b: TileProperties) -> bool:
	if a.tile_count != b.tile_count:
		return false
	for tile in a.tile_count:
		if _tile_values(a, tile) != _tile_values(b, tile):
			return false
	return true


## Whether [param properties] holds the words of a table at [param offset]
## of [param data] with planes of [param count] words: the old layout.
func _matches_layout(
	properties: TileProperties, data: PackedByteArray, offset: int, count: int
) -> bool:
	var bytes := TileProperties.BYTES_PER_ENTRY
	if offset + count * TileProperties.PLANE_COUNT * bytes > data.size():
		return false
	for tile in count:
		var words := []
		for field in TileProperties.PLANE_COUNT:
			words.append(data.decode_s16(offset + (field * count + tile) * bytes))
		words[0] = maxi(1, words[0])
		for field in range(TileProperties.Field.RIGHT, TileProperties.PLANE_COUNT):
			words[field] = words[field] != 0
		if _tile_values(properties, tile) != words:
			return false
	return true


func _tile_values(properties: TileProperties, tile: int) -> Array:
	return [
		properties.animation_frames(tile),
		properties.behavior(tile),
		int(properties.floor_type(tile)),
		properties.blocks_right(tile),
		properties.blocks_bottom(tile),
		properties.blocks_left(tile),
	]


func _folder(folder_name: String) -> String:
	return ProjectSettings.globalize_path(TEST_DIRECTORY).path_join(folder_name)


## A folder with a tiny file for each of [param file_names].
func _make_folder(folder_name: String, file_names: PackedStringArray) -> String:
	var path := _folder(folder_name)
	DirAccess.make_dir_recursive_absolute(path)
	for file_name in file_names:
		var file := FileAccess.open(path.path_join(file_name), FileAccess.WRITE)
		file.store_buffer(PackedByteArray([1, 2, 3]))
		file.close()
	return path


func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	for file_name in directory.get_files():
		directory.remove(file_name)
	DirAccess.remove_absolute(path)
