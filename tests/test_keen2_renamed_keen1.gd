extends "res://tests/test_case.gd"
## Proves that Keen 2's files are read through the Keen 2 path with data in
## the real format: the Keen 1 shareware files are copied to a folder in the
## user folder under Keen 2's names (KEEN1.EXE becomes KEEN2.EXE, *.CK1
## becomes *.CK2) and read with [Keen2Files], [EgaGraphics], [LevelData],
## [FinaleImage] and [Keen2Executable]. The copy is removed afterwards.
## Skipped when the Keen 1 data is not available.

const TEST_DIRECTORY := "user://test_keen2_renamed_keen1"
const KEEN_1_TILE_COUNT := 611

var _keen_1: GameFiles
var _keen_2: GameFiles


func run_all() -> void:
	_keen_1 = GameFiles.locate()
	if _keen_1 == null:
		skip("no Keen 1 game data found")
		return
	var folder := ProjectSettings.globalize_path(TEST_DIRECTORY)
	_remove_recursive(folder)
	_copy_renamed(_keen_1.directory, folder)
	_keen_2 = Keen2Files.find_in([folder])
	super.run_all()
	_remove_recursive(folder)


func test_the_copy_is_found_as_keen_2() -> void:
	assert_true(_keen_2 != null, "the renamed folder has all Keen 2 files")
	if _keen_2 == null:
		return
	assert_equal(_keen_2.extension, Keen2Files.EXTENSION, "read as Keen 2")
	assert_equal(_keen_2.level_numbers(), _keen_1.level_numbers(), "the same levels")


func test_graphics_load_through_the_keen_2_names() -> void:
	if _keen_2 == null:
		return
	var graphics := EgaGraphics.load_from(_keen_2, Keen2Files.EXTENSION)
	assert_true(graphics != null, "EGAHEAD.CK2 and the others load")
	if graphics == null:
		return
	assert_equal(graphics.tiles.size(), KEEN_1_TILE_COUNT, "the tiles of the copy")
	var keen_1 := EgaGraphics.load_from(_keen_1)
	assert_equal(graphics.sprites.size(), keen_1.sprites.size(), "the same sprites")
	assert_true(graphics.tiles[1].get_data() == keen_1.tiles[1].get_data(), "the same pictures")


func test_levels_and_finale_load_through_the_keen_2_names() -> void:
	if _keen_2 == null:
		return
	for number in _keen_2.level_numbers():
		var file_name := _keen_2.level_file(number)
		assert_true(file_name.ends_with(".CK2"), "%s is a Keen 2 name" % file_name)
		assert_true(LevelData.parse(_keen_2.read(file_name)) != null, "%s loads" % file_name)
	assert_true(FinaleImage.load_from(_keen_2, Keen2Files.FINALE) != null, "FINALE.CK2 loads")


func test_executable_loads_through_the_keen_2_name() -> void:
	if _keen_2 == null:
		return
	var executable := Keen2Executable.load_from(_keen_2)
	assert_true(executable != null, "KEEN2.EXE unpacks")
	if executable == null:
		return
	assert_equal(executable.version, "unknown", "a Keen 1 executable is no Keen 2 version")
	var properties := executable.tile_properties(KEEN_1_TILE_COUNT)
	assert_true(properties != null, "the tile table is found by searching")
	if properties == null:
		return
	var keen_1 := TileProperties.load_from(_keen_1, KEEN_1_TILE_COUNT)
	for tile in KEEN_1_TILE_COUNT:
		if properties.behavior(tile) != keen_1.behavior(tile):
			assert_true(false, "tile %d behaves the same" % tile)
			return


## Copies every file of [param from] into [param to] under its Keen 2 name.
func _copy_renamed(from: String, to: String) -> void:
	DirAccess.make_dir_recursive_absolute(to)
	for file_name in DirAccess.get_files_at(from):
		var upper := file_name.to_upper()
		var renamed := upper.replace(GameFiles.EXECUTABLE, Keen2Files.EXECUTABLE)
		renamed = renamed.trim_suffix(".CK1") + (".CK2" if upper.ends_with(".CK1") else "")
		DirAccess.copy_absolute(from.path_join(file_name), to.path_join(renamed))


func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	for file_name in directory.get_files():
		directory.remove(file_name)
	DirAccess.remove_absolute(path)
