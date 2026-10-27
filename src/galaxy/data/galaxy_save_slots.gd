class_name GalaxySaveSlots
extends RefCounted
## The saved games of a Galaxy episode: like the original six slots, each
## with the name the player typed (Omni `ck_us_2.c`, US_Savefile: a name of
## up to 32 characters). Each slot is a small JSON file in the episode's
## own folder (Keen 4: `user://keen4/saves`, apart from Keen 1-3's):
## [code]{"version": 1, "name": "...", "game": {...}}[/code]; what the game
## part holds is the episode's ([Keen4SavedGame]).
##
## Our own format, not the original's SAVEGAMn.CK4 files.

const SLOT_COUNT := 6
const DEFAULT_DIRECTORY := "user://keen4/saves"
## Bumped when the format changes, so that old files are recognised.
const FORMAT_VERSION := 1
## The name shown for a slot whose file cannot be read (in the language in
## use).
const DAMAGED_NAME := "(damaged)"

var directory := DEFAULT_DIRECTORY
var count := SLOT_COUNT


static func in_directory(path: String, slots := SLOT_COUNT) -> GalaxySaveSlots:
	var saves := GalaxySaveSlots.new()
	saves.directory = path
	saves.count = slots
	return saves


## Whether slot [param slot] (1 to [member count]) holds a game.
func exists(slot: int) -> bool:
	return slot >= 1 and slot <= count and FileAccess.file_exists(_path(slot))


## The name of the game in slot [param slot]; "" when it is empty.
func name_of(slot: int) -> String:
	if not exists(slot):
		return ""
	var data := _read_file(slot)
	return str(data.get("name", "")) if not data.is_empty() else Lang.text(DAMAGED_NAME)


## Writes [param game] with [param saved_name] to slot [param slot].
## Returns false (and says why) when that fails.
func write(slot: int, saved_name: String, game: Dictionary) -> bool:
	if slot < 1 or slot > count:
		push_error("There is no save slot %d." % slot)
		return false
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(_path(slot), FileAccess.WRITE)
	if file == null:
		push_error(
			"Could not save to %s: %s" % [_path(slot), error_string(FileAccess.get_open_error())]
		)
		return false
	var data := {"version": FORMAT_VERSION, "name": saved_name, "game": game}
	file.store_string(JSON.stringify(data, "\t"))
	return true


## The game part of slot [param slot]; empty when there is none or it
## cannot be read (and says why).
func read(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var data := _read_file(slot)
	var game: Variant = data.get("game")
	if not game is Dictionary:
		push_error("%s is damaged." % _path(slot))
		return {}
	return game


## The whole file of slot [param slot]; empty (and says why) when it is
## not a saved game of this version.
func _read_file(slot: int) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path(slot)))
	if not (data is Dictionary and data.get("version") == FORMAT_VERSION):
		push_error("%s is not a saved game of this version." % _path(slot))
		return {}
	return data


func _path(slot: int) -> String:
	return directory.path_join("slot%d.json" % slot)
