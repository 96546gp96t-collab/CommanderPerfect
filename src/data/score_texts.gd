class_name ScoreTexts
extends RefCounted
## The texts of the high score table, read from KEEN1.EXE: the names in a
## new table, and the words for each place ("first" to "last").
##
## Both follow the file name "SCORES." in the program image: the first time
## come the three default names, each padded with zeros; the second time,
## further on, the seven words for the places.

const MARKER := "SCORES."
const NAME_COUNT := 3
const PLACE_COUNT := 7
## How far after the marker the names may lie, in bytes.
const NAME_SEARCH_BYTES := 64

var default_names := PackedStringArray()
var place_names := PackedStringArray()


static func find_in_image(image: PackedByteArray) -> ScoreTexts:
	var marker := MARKER.to_ascii_buffer()
	var first := ExeStrings.find(image, marker)
	var second := ExeStrings.find(image, marker, first + 1) if first >= 0 else -1
	if second < 0:
		push_error("The high score texts were not found in the executable.")
		return null
	var texts := ScoreTexts.new()
	texts.default_names = _records_after(image, first + marker.size(), NAME_COUNT)
	texts.place_names = _records_after(image, second + marker.size(), PLACE_COUNT)
	if texts.default_names.size() != NAME_COUNT or texts.place_names.size() != PLACE_COUNT:
		push_error("The high score texts in the executable are not as expected.")
		return null
	return texts


static func load_from(files: GameFiles) -> ScoreTexts:
	var image := DosExecutable.load_image(files.read(GameFiles.EXECUTABLE))
	if image.is_empty():
		return null
	return find_in_image(image)


## The first [param count] non-empty printable records from [param start],
## skipping the zeros between them. Stops at anything else.
static func _records_after(image: PackedByteArray, start: int, count: int) -> PackedStringArray:
	var records := PackedStringArray()
	var position := start
	var limit := mini(image.size(), start + NAME_SEARCH_BYTES * count)
	while records.size() < count and position < limit:
		if image[position] == 0:
			position += 1
			continue
		var record := ExeStrings.record_at(image, position)
		if not _is_printable(record):
			break
		records.append(record)
		position += record.length() + 1
	return records


static func _is_printable(text: String) -> bool:
	if text.is_empty():
		return false
	for index in text.length():
		var code := text.unicode_at(index)
		if code < ExeStrings.FIRST_PRINTABLE or code > ExeStrings.LAST_PRINTABLE:
			return false
	return true
