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
##
## Another episode uses the same search with its own folder, option,
## extension and required files ([method locate_in], [Keen2Files]); the
## defaults are Keen 1's.

const DATA_DIR_OPTION := "--data-dir="
const DEFAULT_SUBFOLDER := "game_data/keen1"
## The extension of Keen 1's data files (EGAHEAD.CK1, LEVEL01.CK1, ...).
const DEFAULT_EXTENSION := "CK1"
const MACOS_EXECUTABLE_DIR := ".app/Contents/MacOS"
const EXECUTABLE := "KEEN1.EXE"
## The text shown after the ending.
const END_TEXT := "ENDTEXT.CK1"
## The story, shown from the main menu.
const STORY_TEXT := "STORYTXT.CK1"
## The PC speaker sounds; the game stays silent without them.
const SOUNDS := "SOUNDS.CK1"
const REQUIRED_FILES: PackedStringArray = [
	"EGAHEAD.CK1", "EGALATCH.CK1", "EGASPRIT.CK1", EXECUTABLE
]
const WORLD_MAP_LEVEL := 80
const ENDING_LEVEL := 81
const BACKDROPS_LEVEL := 90
const FIRST_LEVEL := 1
const LAST_LEVEL := 16

var directory: String
## The extension of the episode's data files, without the dot.
var extension := DEFAULT_EXTENSION
## The files that must be present for the episode to be playable.
var required_files: PackedStringArray = REQUIRED_FILES
## Upper-case file name -> real file name on disk.
var _real_names: Dictionary[String, String] = {}


## Returns the game files in the first folder that holds all required files,
## or null when no such folder exists.
static func locate() -> GameFiles:
	return locate_in(DEFAULT_SUBFOLDER, REQUIRED_FILES)


## Like [method locate], for an episode whose files live in
## [param subfolder] (or in the folder given with [param option]), end in
## [param file_extension] and must include [param required].
static func locate_in(
	subfolder: String,
	required: PackedStringArray,
	option := DATA_DIR_OPTION,
	file_extension := DEFAULT_EXTENSION
) -> GameFiles:
	return first_complete(candidate_directories_in(subfolder, option), required, file_extension)


## The first of [param candidates] that holds all [param required] files,
## opened for [param file_extension]; null when none does.
static func first_complete(
	candidates: PackedStringArray,
	required: PackedStringArray = REQUIRED_FILES,
	file_extension := DEFAULT_EXTENSION
) -> GameFiles:
	for candidate in candidates:
		var files := GameFiles.open(candidate, file_extension, required)
		if files != null and files.has_required_files():
			return files
	return null


## Folders that are searched by [method locate], in order.
static func candidate_directories() -> PackedStringArray:
	return candidate_directories_in(DEFAULT_SUBFOLDER, DATA_DIR_OPTION)


## Folders that are searched for [param subfolder], in order: the folder
## given with [param option] on the command line, the project folder, next
## to the executable and next to a macOS app.
static func candidate_directories_in(subfolder: String, option: String) -> PackedStringArray:
	var candidates := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(option):
			candidates.append(argument.trim_prefix(option))
	candidates.append(ProjectSettings.globalize_path("res://" + subfolder))
	var executable_dir := OS.get_executable_path().get_base_dir()
	candidates.append(executable_dir.path_join(subfolder))
	# A macOS app keeps its executable in Name.app/Contents/MacOS; the game
	# files sit next to the app.
	if executable_dir.ends_with(MACOS_EXECUTABLE_DIR):
		var app_folder := executable_dir.trim_suffix(MACOS_EXECUTABLE_DIR).get_base_dir()
		candidates.append(app_folder.path_join(subfolder))
	return candidates


## Opens a folder; returns null when it does not exist. The episode's
## [param file_extension] and [param required] files default to Keen 1's.
static func open(
	path: String, file_extension := DEFAULT_EXTENSION, required: PackedStringArray = REQUIRED_FILES
) -> GameFiles:
	if not DirAccess.dir_exists_absolute(path):
		return null
	var files := GameFiles.new()
	files.directory = path
	files.extension = file_extension
	files.required_files = required
	for real_name in DirAccess.get_files_at(path):
		files._real_names[real_name.to_upper()] = real_name
	return files


func has_file(file_name: String) -> bool:
	return _real_names.has(file_name.to_upper())


func has_required_files() -> bool:
	return Array(required_files).all(has_file)


## Returns the contents of a file, or an empty array if it does not exist.
func read(file_name: String) -> PackedByteArray:
	if not has_file(file_name):
		push_error("Game file %s is missing in %s." % [file_name, directory])
		return PackedByteArray()
	return FileAccess.get_file_as_bytes(directory.path_join(_real_names[file_name.to_upper()]))


## Numbers of all LEVELxx files with this episode's [member extension]
## that are present, in ascending order.
func level_numbers() -> PackedInt32Array:
	var numbers := PackedInt32Array()
	var suffix := "." + extension.to_upper()
	for upper_name in _real_names:
		if upper_name.begins_with("LEVEL") and upper_name.ends_with(suffix):
			var number := upper_name.trim_prefix("LEVEL").trim_suffix(suffix)
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


## The file of level [param level_number] with this episode's
## [member extension], for example LEVEL03.CK2.
func level_file(level_number: int) -> String:
	return "LEVEL%02d.%s" % [level_number, extension]


## Name of a level for menus and status lines, e.g. "Level 3" or "World map",
## in the language in use.
static func level_title(level_number: int) -> String:
	match level_number:
		WORLD_MAP_LEVEL:
			return Lang.text("World map")
		ENDING_LEVEL:
			return Lang.text("Ending")
		BACKDROPS_LEVEL:
			return Lang.text("Backdrops")
	return Lang.text("Level %d") % level_number
