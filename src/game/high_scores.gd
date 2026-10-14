class_name HighScores
extends RefCounted
## The high score table: seven places, each with a name, a score and the
## ship parts that player had found. Kept as JSON in the user folder of
## Godot, like [SaveGames].
##
## A new table starts with the names of the original ([ScoreTexts]) and a
## score of [constant DEFAULT_SCORE] everywhere.

const PLACES := 7
## The original asks for a name of at most this many characters.
const MAX_NAME_LENGTH := 12
const DEFAULT_SCORE := 100  # estimate: still to compare with the original
const DEFAULT_PATH := "user://high_scores.json"

var path := DEFAULT_PATH
var entries: Array[Entry] = []


class Entry:
	extends RefCounted
	var name := ""
	var score := 0
	var ship_parts: Array[bool] = [false, false, false, false]


## The table stored at [param file_path], or a new table with
## [param default_names] at the top when there is none yet.
static func load_from(
	file_path := DEFAULT_PATH, default_names := PackedStringArray()
) -> HighScores:
	var table := HighScores.new()
	table.path = file_path
	table._fill_defaults(default_names)
	if FileAccess.file_exists(file_path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(file_path))
		if data is Array:
			table._read(data)
		else:
			push_error("%s is damaged; starting with a new table." % file_path)
	return table


## The place (0 is the top) a score of [param score] would take, or -1 when
## it is too low.
func place_for(score: int) -> int:
	for place in entries.size():
		if score > entries[place].score:
			return place
	return -1


## Puts a new entry at [param place]; the last one drops off.
func insert(place: int, name: String, score: int, ship_parts: Array[bool]) -> void:
	var entry := Entry.new()
	entry.name = name.left(MAX_NAME_LENGTH)
	entry.score = score
	entry.ship_parts = ship_parts.duplicate()
	entries.insert(place, entry)
	entries.resize(PLACES)


## Writes the table to its file. Returns false (and says why) when that fails.
func save() -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return false
	var data := []
	for entry in entries:
		data.append({"name": entry.name, "score": entry.score, "ship_parts": entry.ship_parts})
	file.store_string(JSON.stringify(data, "\t"))
	return true


func _fill_defaults(names: PackedStringArray) -> void:
	entries.clear()
	for place in PLACES:
		var entry := Entry.new()
		entry.name = names[place] if place < names.size() else ""
		entry.score = DEFAULT_SCORE
		entries.append(entry)


func _read(data: Array) -> void:
	for place in mini(data.size(), PLACES):
		var item: Variant = data[place]
		if not item is Dictionary:
			continue
		var entry := entries[place]
		entry.name = str(item.get("name", "")).left(MAX_NAME_LENGTH)
		entry.score = int(item.get("score", 0))
		var parts: Variant = item.get("ship_parts", [])
		for part in mini(parts.size() if parts is Array else 0, entry.ship_parts.size()):
			entry.ship_parts[part] = bool(parts[part])
