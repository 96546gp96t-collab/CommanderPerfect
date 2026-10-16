extends "res://tests/test_case.gd"
## Checks the decoders against the player's real Keen 2 files. Skipped when
## they are not available: Keen 2 is not shareware, so this only runs where
## the player put their own files in game_data/keen2 (they are never part of
## the repository). The numbers come from docs/keen2/research.md.

const TILE_COUNT := 689
const SPRITE_COUNT := 134
const CITY_COUNT := 8
const NEW_SOUND := "EARTHPOW"
const TEXT_WIDTH := 40

var _files: GameFiles
var _executable: Keen2Executable


func run_all() -> void:
	_files = Keen2Files.locate()
	if _files == null:
		skip("no Keen 2 game data found")
		return
	_executable = Keen2Executable.load_from(_files)
	super.run_all()


func test_graphics_have_expected_counts() -> void:
	var graphics := EgaGraphics.load_from(_files, Keen2Files.EXTENSION)
	assert_true(graphics != null, "graphics should load")
	if graphics == null:
		return
	assert_equal(graphics.tiles.size(), TILE_COUNT, "tile count")
	assert_equal(graphics.sprites.size(), SPRITE_COUNT, "sprite count")


func test_every_map_loads() -> void:
	for number in Keen2Files.expected_level_numbers():
		var file_name := _files.level_file(number)
		assert_true(_files.has_file(file_name), "%s is there" % file_name)
		assert_true(LevelData.parse(_files.read(file_name)) != null, "%s loads" % file_name)


func test_finale_loads() -> void:
	assert_true(FinaleImage.load_from(_files, Keen2Files.FINALE) != null, "FINALE.CK2")


func test_executable_has_a_known_version() -> void:
	assert_true(_executable != null, "KEEN2.EXE unpacks")
	if _executable != null:
		assert_true(_executable.version != Keen2Executable.UNKNOWN_VERSION, "a known version")


func test_tile_properties_are_found() -> void:
	if _executable == null:
		return
	assert_true(_executable.tile_properties(TILE_COUNT) != null, "the tile table")


func test_sounds_include_the_earth_exploding() -> void:
	if _executable == null:
		return
	var sounds := _executable.sounds()
	assert_true(sounds != null, "the sound block parses")
	if sounds != null:
		assert_true(sounds.sounds.has(NEW_SOUND), "Keen 2's new sound")


func test_texts_are_found() -> void:
	if _executable == null:
		return
	for block in Keen2Executable.TextBlock.size():
		var text := _executable.text(block as Keen2Executable.TextBlock)
		var name: String = Keen2Executable.TextBlock.keys()[block]
		assert_true(not text.is_empty(), "%s is found" % name)
		if not text.is_empty():
			assert_true(TextDocument.layout(text, TEXT_WIDTH).size() > 1, "%s has lines" % name)


func test_eight_city_names() -> void:
	if _executable == null:
		return
	var names := _executable.city_names()
	assert_equal(names.size(), CITY_COUNT, "eight cities")
	assert_true(_executable.to_be_continued().begins_with("TO BE CONTINUED"), "the last record")
