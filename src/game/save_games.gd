class_name SaveGames
extends RefCounted
## The saved games: like the original there are nine slots, and a game can
## only be saved on the world map. Each slot is a small JSON file with the
## [GameProgress] in the user folder of Godot (on the Mac:
## ~/Library/Application Support/Godot/app_userdata/CommanderPerfect).
##
## Our own format, not the SAVEDn.CK1 files of the original game.

const SLOT_COUNT := 9
const DEFAULT_DIRECTORY := "user://saves"
## Bumped when the format changes, so that old files are recognised.
const FORMAT_VERSION := 1

var directory := DEFAULT_DIRECTORY


static func in_directory(path: String) -> SaveGames:
	var saves := SaveGames.new()
	saves.directory = path
	return saves


## Whether slot [param slot] (1-9) holds a game.
func exists(slot: int) -> bool:
	return FileAccess.file_exists(_path(slot))


## Writes [param progress] to slot [param slot]. Returns false (and says why)
## when that fails.
func write(slot: int, progress: GameProgress) -> bool:
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(_path(slot), FileAccess.WRITE)
	if file == null:
		push_error(
			"Could not save to %s: %s" % [_path(slot), error_string(FileAccess.get_open_error())]
		)
		return false
	var data := {"version": FORMAT_VERSION, "game": progress.to_dict()}
	file.store_string(JSON.stringify(data, "\t"))
	return true


## The game in slot [param slot], or null when there is none or it cannot
## be read.
func read(slot: int) -> GameProgress:
	if not exists(slot):
		return null
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path(slot)))
	if not (data is Dictionary and data.get("version") == FORMAT_VERSION):
		push_error("%s is not a saved game of this version." % _path(slot))
		return null
	var game: Variant = data.get("game")
	var progress := GameProgress.from_dict(game) if game is Dictionary else null
	if progress == null:
		push_error("%s is damaged." % _path(slot))
	return progress


## A short description of the game in slot [param slot] for the menu, or
## "" when the slot is empty.
func summary(slot: int) -> String:
	if not exists(slot):
		return ""
	var game := read(slot)
	if game == null:
		return "(damaged)"
	return "Score %d, %d levels" % [game.inventory.score, game.completed_levels().size()]


func _path(slot: int) -> String:
	return directory.path_join("slot%d.json" % slot)
