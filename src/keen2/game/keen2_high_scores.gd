class_name Keen2HighScores
extends RefCounted
## Keen 2's high score table: seven places, each with a name, a score and the
## number of cities that player saved. Kept as JSON in Keen 2's own user
## folder, apart from Keen 1's table ([HighScores], which stores ship parts).
##
## A new table starts with the names of the original (in KEEN2.EXE, read by
## [ScoreTexts]) and a score of [constant DEFAULT_SCORE] everywhere.

const PLACES := HighScores.PLACES
const MAX_NAME_LENGTH := HighScores.MAX_NAME_LENGTH
## As Keen 1's new table. estimate: still to compare with the original.
const DEFAULT_SCORE := HighScores.DEFAULT_SCORE
const DEFAULT_PATH := "user://keen2/high_scores.json"

var path := DEFAULT_PATH
var entries: Array[Entry] = []


class Entry:
	extends RefCounted
	var name := ""
	var score := 0
	var cities := 0


## The table stored at [param file_path], or a new table with
## [param default_names] at the top when there is none yet.
static func load_from(
	file_path := DEFAULT_PATH, default_names := PackedStringArray()
) -> Keen2HighScores:
	var table := Keen2HighScores.new()
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
func insert(place: int, name: String, score: int, cities: int) -> void:
	var entry := Entry.new()
	entry.name = name.left(MAX_NAME_LENGTH)
	entry.score = score
	entry.cities = cities
	entries.insert(place, entry)
	entries.resize(PLACES)


## Writes the table to its file. Returns false (and says why) when that fails.
func save() -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return false
	var data := []
	for entry in entries:
		data.append({"name": entry.name, "score": entry.score, "cities": entry.cities})
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
		entry.cities = clampi(int(item.get("cities", 0)), 0, Keen2Progress.CITY_LEVELS.size())
