class_name GalaxyHighScores
extends RefCounted
## The high-score table of a Galaxy episode: a number of places, each with
## a name, a score and one more number the episode shows (Keen 4: the
## council members rescued). Higher scores go first; at an equal score the
## higher number wins, otherwise the older entry stays above (Omni
## `ck_inter.c`: CK_SubmitHighScore; facts only).
##
## A new table is the original's own: its records lie in the program as
## [constant RECORD_SIZE]-byte records (a name of [constant NAME_BYTES]
## bytes ending in zeros, a 32-bit score, a 16-bit number), found by that
## shape ([method find_defaults]). The table is kept as JSON in the episode's
## own user folder.

const RECORD_SIZE := 64
const NAME_BYTES := 58
const SCORE_AT := 58
const COUNT_AT := 62
## A score in a default record is at most this (the original's are 10,000).
const MAX_DEFAULT_SCORE := 1000000
## The extra number of a default record is at most this.
const MAX_DEFAULT_COUNT := 99
const PRINTABLE_FIRST := 0x20
const PRINTABLE_LAST := 0x7E

var path := ""
var places := 0
var entries: Array[Entry] = []


class Entry:
	extends RefCounted
	var name := ""
	var score := 0
	## The episode's extra number (Keen 4: council members rescued).
	var count := 0

	static func create(entry_name: String, entry_score: int, entry_count: int) -> Entry:
		var entry := Entry.new()
		entry.name = entry_name
		entry.score = entry_score
		entry.count = entry_count
		return entry


## The table at [param file_path]; when there is none (or it is damaged)
## [param defaults], which also fill missing places.
static func load_from(file_path: String, defaults: Array[Entry]) -> GalaxyHighScores:
	var table := GalaxyHighScores.new()
	table.path = file_path
	table.places = defaults.size()
	for entry in defaults:
		table.entries.append(Entry.create(entry.name, entry.score, entry.count))
	if FileAccess.file_exists(file_path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(file_path))
		if data is Array:
			table._read(data)
		else:
			push_error("%s is damaged; starting with the original table." % file_path)
	return table


## The place (0 is the top) that [param score] with [param count] takes,
## or -1 when it does not make the table.
func place_for(score: int, count: int) -> int:
	for place in entries.size():
		var entry := entries[place]
		if entry.score > score or (entry.score == score and entry.count >= count):
			continue
		return place
	return -1


## Puts a new entry at [param place]; the last one drops off.
func insert(place: int, entry_name: String, score: int, count: int) -> void:
	entries.insert(place, Entry.create(entry_name, score, count))
	entries.resize(places)


## Writes the table to [member path]; returns whether that worked.
func save() -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write %s." % path)
		return false
	var rows: Array = []
	for entry in entries:
		rows.append({"name": entry.name, "score": entry.score, "count": entry.count})
	file.store_string(JSON.stringify(rows))
	return true


## Where [param count] default records start in [param image], or -1;
## [param known] places are tried first.
static func find_defaults(image: PackedByteArray, count: int, known: PackedInt32Array) -> int:
	for place in known:
		if _are_defaults(image, place, count):
			return place
	for place in image.size() - count * RECORD_SIZE:
		if _are_defaults(image, place, count):
			return place
	return -1


## The [param count] default entries at [param start] of [param image].
static func defaults_at(image: PackedByteArray, start: int, count: int) -> Array[Entry]:
	var found: Array[Entry] = []
	for index in count:
		var at := start + index * RECORD_SIZE
		var name_bytes := image.slice(at, at + NAME_BYTES)
		var end := name_bytes.find(0)
		found.append(
			Entry.create(
				name_bytes.slice(0, end).get_string_from_ascii(),
				image.decode_u32(at + SCORE_AT),
				image.decode_u16(at + COUNT_AT)
			)
		)
	return found


static func _are_defaults(image: PackedByteArray, start: int, count: int) -> bool:
	if start < 0 or start + count * RECORD_SIZE > image.size():
		return false
	# The numbers first: they rule out most places at once.
	for index in count:
		var at := start + index * RECORD_SIZE
		var score := image.decode_u32(at + SCORE_AT)
		if score <= 0 or score > MAX_DEFAULT_SCORE:
			return false
		if image.decode_u16(at + COUNT_AT) > MAX_DEFAULT_COUNT:
			return false
	var named := 0
	for index in count:
		var length := _name_length(image, start + index * RECORD_SIZE)
		if length < 0:
			return false
		if length > 0:
			named += 1
	return named > 0


## How long the name at [param at] is, or -1 when the bytes are no name: a
## run of printable characters, then only zeros.
static func _name_length(image: PackedByteArray, at: int) -> int:
	var length := 0
	while length < NAME_BYTES and image[at + length] != 0:
		var character := image[at + length]
		if character < PRINTABLE_FIRST or character > PRINTABLE_LAST:
			return -1
		length += 1
	for rest in range(length, NAME_BYTES):
		if image[at + rest] != 0:
			return -1
	return length


func _read(data: Array) -> void:
	for index in mini(data.size(), places):
		var row: Variant = data[index]
		if not row is Dictionary:
			continue
		entries[index] = Entry.create(
			str(row.get("name", "")), int(row.get("score", 0)), int(row.get("count", 0))
		)
