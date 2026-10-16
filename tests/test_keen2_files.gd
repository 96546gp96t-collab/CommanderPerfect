extends "res://tests/test_case.gd"
## Tests for reading Keen 2's files without the real files: finding the
## folder, the level numbers with .CK2, Keen 1's unchanged defaults, the
## search through a hand-made KEEN2.EXE image, the start screen with two
## games and the --game=2 option. Fake files go to a folder in the user
## folder, which is removed afterwards.

const TEST_DIRECTORY := "user://test_keen2_files"
const FILLER := 0x01
const TEXT_END := 0x1A
const TEXT_PADDING := 8
const SOUND_UNKNOWN_WORD_OFFSET := 8
const SOUND_UNKNOWN_WORD := 60
const SOUND_PRIORITY := 2
const SOUND_UNKNOWN_BYTE := 8
const BEEP_DIVISOR := 0x0400
const FAKE_SOUNDS: PackedStringArray = ["TESTBEEP", "TESTBOOP"]
## Names of the right lengths; not the real cities.
const FAKE_CITIES: PackedStringArray = [
	"Abcdef", "Bcdef", "Cdefgh", "Def Ghij", "Efghi", "Fghi", "Ghijkl", "Hijklmnop"
]
const FAKE_TILE_COUNT := 10
const FAKE_DEADLY_TILE := 1
const FAKE_EXIT_TILE := 2
const FAKE_FLOOR_TILE := 3
const FAKE_ANIMATION_START := 4
const FAKE_ANIMATION_FRAMES := 4
const KEEN_2_FILE_NAMES: PackedStringArray = [
	"egahead.ck2", "EgaLatch.CK2", "egasprit.ck2", "keen2.exe", "level01.ck2", "LEVEL80.CK2"
]


func run_all() -> void:
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))
	super.run_all()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_keen2_files_finds_a_folder_whatever_the_case() -> void:
	var missing := _folder("missing")
	var incomplete := _make_folder("incomplete", ["EGAHEAD.CK2", "EGALATCH.CK2"])
	var complete := _make_folder("complete", KEEN_2_FILE_NAMES)
	var files := Keen2Files.find_in([missing, incomplete, complete])
	assert_true(files != null, "the complete folder is found")
	if files == null:
		return
	assert_equal(files.directory, complete, "the first complete folder")
	assert_equal(files.extension, "CK2", "Keen 2's extension")
	assert_true(files.has_file("EGALATCH.CK2"), "any case")
	assert_true(not files.read("KEEN2.EXE").is_empty(), "read by its upper-case name")
	assert_equal(files.level_numbers(), PackedInt32Array([1, 80]), "only the .CK2 levels")
	assert_equal(files.level_file(3), "LEVEL03.CK2", "level file name")
	assert_true(GameFiles.first_complete([complete]) == null, "no Keen 1 files there")


func test_keen2_requires_its_own_files() -> void:
	assert_equal(
		Keen2Files.REQUIRED_FILES,
		PackedStringArray(["EGAHEAD.CK2", "EGALATCH.CK2", "EGASPRIT.CK2", "KEEN2.EXE"]),
		"the graphics and the executable"
	)
	var folder := _make_folder("no_exe", ["EGAHEAD.CK2", "EGALATCH.CK2", "EGASPRIT.CK2"])
	var files := Keen2Files.open(folder)
	assert_true(files != null, "the folder opens")
	assert_true(not files.has_required_files(), "but KEEN2.EXE is missing")
	assert_true(Keen2Files.find_in([folder]) == null, "so it is not used")
	assert_true(
		Keen2Files.candidate_directories()[-1].ends_with("game_data/keen2"), "looks in keen2"
	)


func test_keen2_level_numbers() -> void:
	var numbers := Keen2Files.expected_level_numbers()
	assert_equal(numbers.size(), 19, "16 levels and three maps")
	assert_equal(numbers[0], 1, "first level")
	assert_equal(numbers[15], 16, "last level")
	assert_equal(numbers.slice(16), PackedInt32Array([80, 81, 90]), "map, space, title")


func test_keen_1_defaults_are_unchanged() -> void:
	assert_equal(GameFiles.new().extension, "CK1", "extension")
	assert_equal(GameFiles.new().required_files, GameFiles.REQUIRED_FILES, "required files")
	assert_equal(
		GameFiles.candidate_directories(),
		GameFiles.candidate_directories_in(GameFiles.DEFAULT_SUBFOLDER, GameFiles.DATA_DIR_OPTION),
		"the same folders"
	)
	var folder := _make_folder("mixed", ["LEVEL01.CK1", "level02.ck2", "LEVEL80.CK1"])
	var files := GameFiles.open(folder)
	assert_equal(files.level_numbers(), PackedInt32Array([1, 80]), "only the .CK1 levels")
	assert_equal(files.level_file(5), GameFiles.level_file_name(5), "level file name")
	assert_equal(Keen2Files.open(folder).level_numbers(), PackedInt32Array([2]), "Keen 2's")


func test_executable_finds_every_piece() -> void:
	var image := _make_image()
	var executable := Keen2Executable.from_image(image)
	var sounds := executable.sounds()
	assert_true(sounds != null, "the sound block parses")
	if sounds != null:
		assert_equal(sounds.sounds.size(), 2, "both sounds")
		assert_equal(sounds.sounds["TESTBOOP"].divisors.size(), 2, "the data of a sound")
	for block in Keen2Executable.TextBlock.size():
		var text := executable.text(block as Keen2Executable.TextBlock)
		var name: String = Keen2Executable.TextBlock.keys()[block]
		assert_true(not text.is_empty(), "%s is found" % name)
		if text.is_empty():
			continue
		assert_equal(text[-1], TEXT_END, "%s ends in its end mark" % name)
		var lines := TextDocument.layout(text, 40)
		assert_true(lines[0].contains("Block %d" % block), "%s is the right block" % name)
	assert_equal(executable.city_names(), FAKE_CITIES, "eight city names")
	assert_equal(executable.to_be_continued(), "TO BE CONTINUED....", "the last record")
	var properties := executable.tile_properties(FAKE_TILE_COUNT)
	assert_true(properties != null, "the tile table")
	if properties != null:
		assert_true(properties.is_deadly(FAKE_DEADLY_TILE), "deadly tile")
		assert_true(properties.is_exit(FAKE_EXIT_TILE), "exit tile")
		assert_true(properties.blocks_top(FAKE_FLOOR_TILE), "floor tile")
		assert_true(properties.is_animated(FAKE_ANIMATION_START), "animated tile")
	assert_equal(executable.version, "unknown", "no known size")


func test_executable_without_the_pieces_finds_nothing() -> void:
	for image: PackedByteArray in [PackedByteArray(), _filler(2048)]:
		assert_equal(Keen2Executable.find_sound_block(image), -1, "no sounds")
		assert_equal(Keen2Executable.text_blocks(image).size(), 0, "no texts")
		assert_equal(Keen2Executable.find_city_names(image), -1, "no cities")
		assert_equal(Keen2Executable.find_to_be_continued(image), -1, "no ending record")
		var executable := Keen2Executable.from_image(image)
		assert_true(executable.sounds() == null, "sounds are null")
		assert_true(executable.text(Keen2Executable.TextBlock.STORY).is_empty(), "no story")
		assert_equal(executable.city_names().size(), 0, "no names")
		assert_equal(executable.to_be_continued(), "", "no record")
		assert_true(executable.tile_properties(FAKE_TILE_COUNT) == null, "no tile table")


func test_text_blocks_ignore_short_and_unended_text() -> void:
	var image := _filler(16)
	image.append_array("short\r\n".to_ascii_buffer())
	image.append(TEXT_END)
	image.append_array(_filler(16))
	image.append_array(_text("Block 9").slice(0, -1))  # no end mark
	image.append_array(_filler(16))
	assert_equal(Keen2Executable.text_blocks(image).size(), 0, "nothing that looks like a block")


func test_version_from_the_sizes() -> void:
	assert_equal(Keen2Executable.version_for(118672), "1.31", "size with header")
	assert_equal(Keen2Executable.version_for(118672 - 512), "1.31", "image size")
	assert_equal(Keen2Executable.version_for(118626), "1.00", "1.00 with header")
	assert_equal(Keen2Executable.version_for(118626 - 512), "1.00", "1.00 image size")
	assert_equal(Keen2Executable.version_for(0, 58335), "1.31", "packed file size")
	assert_equal(Keen2Executable.version_for(99762), "unknown", "Keen 1's size")


func test_catalog_lists_keen_1_then_keen_2() -> void:
	var games := GameCatalog.games()
	assert_equal(games.size(), 2, "two games")
	assert_equal(games[0].title, "Keen 1", "Keen 1 first")
	assert_equal(games[0].scene, GameLaunch.KEEN_1_SCENE, "plays Keen 1")
	assert_equal(games[0].data_folder, "game_data/keen1", "Keen 1's folder")
	assert_equal(games[1].title, "Keen 2", "then Keen 2")
	assert_equal(games[1].scene, GameLaunch.KEEN_2_SCENE, "plays Keen 2")
	assert_equal(games[1].data_folder, "game_data/keen2", "Keen 2's folder")
	assert_true(ResourceLoader.exists(GameLaunch.KEEN_2_SCENE), "the Keen 2 scene exists")


func test_missing_keen_2_says_where_the_files_go() -> void:
	var launcher := Launcher.new()
	var game := GameCatalog.Game.new()
	game.title = "Keen 2"
	game.data_folder = Keen2Files.SUBFOLDER
	launcher._start(game)
	assert_true(launcher.message().contains("game_data/keen2"), "Keen 2's folder")
	assert_true(not GameLaunch.take_menu_request(), "nothing starts")
	var keen_1 := GameCatalog.Game.new()
	keen_1.title = "Keen 1"
	launcher._start(keen_1)
	assert_equal(
		launcher.message(),
		(
			"The files of Keen 1 were not found. Put them in game_data/keen1 "
			+ "(see game_data/README.md), next to the app."
		),
		"Keen 1's text as before"
	)
	# Without _ready these are not children of the launcher yet.
	launcher._picture.free()
	launcher._message.free()
	launcher.free()


func test_game_option_starts_keen_2() -> void:
	assert_true(GameLaunch.skips_launcher(["--game=2"]), "Keen 2 alone")
	assert_true(GameLaunch.skips_launcher(["--game=2", "--level=3"]), "a Keen 2 level")
	assert_equal(GameLaunch.scene_for(["--game=2"]), GameLaunch.KEEN_2_SCENE, "Keen 2")
	assert_equal(
		GameLaunch.scene_for(["--level=3", "--game=2"]), GameLaunch.KEEN_2_SCENE, "any order"
	)
	assert_equal(GameLaunch.scene_for(["--level=3"]), GameLaunch.KEEN_1_SCENE, "Keen 1")
	assert_equal(GameLaunch.scene_for([]), GameLaunch.KEEN_1_SCENE, "Keen 1 by default")
	assert_true(not GameLaunch.skips_launcher(["--game=1"]), "Keen 1 alone: the start screen")
	assert_true(not GameLaunch.skips_launcher(["--data-dir-keen2=/x"]), "other options")


func test_keen_2_placeholder() -> void:
	var view: Keen2View = load(GameLaunch.KEEN_2_SCENE).instantiate()
	view._build()  # The tests run outside the scene tree.
	assert_true(view.message().contains("coming soon"), "says Keen 2 is coming")
	view.free()
	assert_true(Keen2View.is_back_event(_key(KEY_ESCAPE)), "Escape goes back")
	assert_true(Keen2View.is_back_event(_key(KEY_ENTER)), "Enter goes back")
	assert_true(not Keen2View.is_back_event(_key(KEY_LEFT)), "other keys do not")


## A program image with a sound block, four text blocks, the city names,
## the ending record and a tile table (on a word boundary, as in the real
## executables), with filler in between.
func _make_image() -> PackedByteArray:
	var image := _filler(64)
	image.append_array(_sound_block())
	image.append_array(_filler(16))
	for block in Keen2Executable.TextBlock.size():
		image.append_array(_text("Block %d" % block))
		image.append_array(PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0]))
	for city in FAKE_CITIES:
		image.append_array(city.to_ascii_buffer())
		image.append(0)
	image.append_array("TO BE CONTINUED....".to_ascii_buffer())
	image.append(0)
	image.append_array(_filler(TEXT_PADDING + image.size() % TileProperties.BYTES_PER_ENTRY))
	image.append_array(_tile_table())
	image.append_array(_filler(TEXT_PADDING))
	return image


## A sound block in the layout of SOUNDS.CK1 with two short sounds.
func _sound_block() -> PackedByteArray:
	var count := FAKE_SOUNDS.size()
	var table_end := SoundFile.HEADER_SIZE + count * SoundFile.ENTRY_SIZE
	var data := PackedByteArray()
	data.resize(table_end)
	data.encode_u32(0, 0x00444E53)  # "SND\0"
	data.encode_u16(SoundFile.COUNT_OFFSET, count)
	data.encode_u16(SOUND_UNKNOWN_WORD_OFFSET, SOUND_UNKNOWN_WORD)
	for index in count:
		var entry := SoundFile.HEADER_SIZE + index * SoundFile.ENTRY_SIZE
		data[entry + 2] = SOUND_PRIORITY
		data[entry + 3] = SOUND_UNKNOWN_BYTE
		var name := FAKE_SOUNDS[index].to_ascii_buffer()
		for at in name.size():
			data[entry + 4 + at] = name[at]
		var sound := PackedByteArray()
		sound.resize(2 * (index + 2))
		for step in index + 1:
			sound.encode_u16(step * 2, BEEP_DIVISOR)
		sound.encode_u16(sound.size() - 2, SoundFile.END_MARK)
		# The data of each sound follows the table and the sounds before it.
		data.encode_u16(entry, data.size())
		data.append_array(sound)
	data.encode_u16(Keen2Executable.SOUND_SIZE_OFFSET, data.size())
	return data


## A text in the layout of the .CK1 text files, ending in the end mark.
func _text(title: String) -> PackedByteArray:
	var text := "%s\r\n\r\nA paragraph that is long enough to be a text block,\r\n" % title
	text += "with a second line.\r\n"
	var bytes := text.to_ascii_buffer()
	bytes.append(TEXT_END)
	return bytes


## A tile table of [constant FAKE_TILE_COUNT] tiles in the layout of
## KEEN1.EXE: six planes of one word per tile.
func _tile_table() -> PackedByteArray:
	var table := PackedByteArray()
	table.resize(FAKE_TILE_COUNT * TileProperties.PLANE_COUNT * TileProperties.BYTES_PER_ENTRY)
	for tile in FAKE_TILE_COUNT:
		var frames := 1
		if tile >= FAKE_ANIMATION_START and tile < FAKE_ANIMATION_START + FAKE_ANIMATION_FRAMES:
			frames = FAKE_ANIMATION_FRAMES
		_set_word(table, TileProperties.Field.ANIMATION, tile, frames)
	_set_word(
		table, TileProperties.Field.BEHAVIOR, FAKE_DEADLY_TILE, TileProperties.Behavior.DEADLY
	)
	_set_word(table, TileProperties.Field.BEHAVIOR, FAKE_EXIT_TILE, TileProperties.Behavior.EXIT)
	_set_word(table, TileProperties.Field.TOP, FAKE_FLOOR_TILE, TileProperties.Floor.SOLID)
	return table


func _set_word(table: PackedByteArray, field: int, tile: int, value: int) -> void:
	var position := (field * FAKE_TILE_COUNT + tile) * TileProperties.BYTES_PER_ENTRY
	table.encode_s16(position, value)


func _filler(size: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(size)
	bytes.fill(FILLER)
	return bytes


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event


func _folder(folder_name: String) -> String:
	return ProjectSettings.globalize_path(TEST_DIRECTORY).path_join(folder_name)


## A folder with an empty-ish file for each of [param file_names].
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
