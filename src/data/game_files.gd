class_name GameFiles
extends RefCounted
## Finds and reads the original Keen 1 data files supplied by the player.
##
## The files are searched for in this order:
##   1. the folder given with the command-line option --data-dir=PATH
##   2. game_data/keen1 inside the project folder (handy while developing)
##   3. game_data/keen1 next to the exported game executable
##
## File names are matched case-insensitively, because depending on where the
## files come from they are called EGAHEAD.CK1 or egahead.ck1.

const DATA_DIR_OPTION := "--data-dir="
const DEFAULT_SUBFOLDER := "game_data/keen1"
const EXECUTABLE := "KEEN1.EXE"
const REQUIRED_FILES: PackedStringArray = [
	"EGAHEAD.CK1", "EGALATCH.CK1", "EGASPRIT.CK1", EXECUTABLE
]
const WORLD_MAP_LEVEL := 80
const ENDING_LEVEL := 81
const BACKDROPS_LEVEL := 90
const FIRST_LEVEL := 1
const LAST_LEVEL := 16

var directory: String
## Upper-case file name -> real file name on disk.
var _real_names: Dictionary[String, String] = {}


## Returns the game files in the first folder that holds all required files,
## or null when no such folder exists.
static func locate() -> GameFiles:
	for candidate in candidate_directories():
		var files := GameFiles.open(candidate)
		if files != null and files.has_required_files():
			return files
	return null


## Folders that are searched by [method locate], in order.
static func candidate_directories() -> PackedStringArray:
	var candidates := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(DATA_DIR_OPTION):
			candidates.append(argument.trim_prefix(DATA_DIR_OPTION))
	candidates.append(ProjectSettings.globalize_path("res://" + DEFAULT_SUBFOLDER))
	candidates.append(OS.get_executable_path().get_base_dir().path_join(DEFAULT_SUBFOLDER))
	return candidates


## Opens a folder; returns null when it does not exist.
static func open(path: String) -> GameFiles:
	if not DirAccess.dir_exists_absolute(path):
		return null
	var files := GameFiles.new()
	files.directory = path
	for real_name in DirAccess.get_files_at(path):
		files._real_names[real_name.to_upper()] = real_name
	return files


func has_file(file_name: String) -> bool:
	return _real_names.has(file_name.to_upper())


func has_required_files() -> bool:
	return Array(REQUIRED_FILES).all(has_file)


## Returns the contents of a file, or an empty array if it does not exist.
func read(file_name: String) -> PackedByteArray:
	if not has_file(file_name):
		push_error("Game file %s is missing in %s." % [file_name, directory])
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(directory.path_join(_real_names[file_name.to_upper()]))


## Numbers of all LEVELxx.CK1 files that are present, in ascending order.
func level_numbers() -> PackedInt32Array:
	var numbers := PackedInt32Array()
	for upper_name in _real_names:
		if upper_name.begins_with("LEVEL") and upper_name.ends_with(".CK1"):
			var number := upper_name.trim_prefix("LEVEL").trim_suffix(".CK1")
			if number.is_valid_int():
				numbers.append(number.to_int())
	numbers.sort()
	return numbers


## Whether [param level_number] is a level that Keen plays in (not the world
## map or one of the special maps).
static func is_playable_level(level_number: int) -> bool:
	return level_number >= FIRST_LEVEL and level_number <= LAST_LEVEL


static func level_file_name(level_number: int) -> String:
	return "LEVEL%02d.CK1" % level_number


## Name of a level for menus and status lines, e.g. "Level 3" or "World map".
static func level_title(level_number: int) -> String:
	match level_number:
		WORLD_MAP_LEVEL:
			return "World map"
		ENDING_LEVEL:
			return "Ending"
		BACKDROPS_LEVEL:
			return "Backdrops"
	return "Level %d" % level_number
