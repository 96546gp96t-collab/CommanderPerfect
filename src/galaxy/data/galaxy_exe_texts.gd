class_name GalaxyExeTexts
extends RefCounted
## Finds texts in the unpacked program of a Galaxy episode by their shape,
## never by their words: the texts belong to the game and stay in the
## player's files. A text is a zero-terminated record of printable
## characters and newlines; records follow each other, some with zeros in
## between to fill up to a 16-byte boundary.
##
## - The level names and the "Keen enters ..." texts: one record per map in
##   each list, the second list right after the first, and every entry text
##   ends with the level's name (newlines read as spaces).
## - A run of messages: records whose numbers of lines match a shape given
##   by the episode ([member GalaxyEpisode.message_shapes]).
## - A run of short texts: records whose lengths match the episode's
##   ([member GalaxyEpisode.text_lengths]).
##
## Places a known version uses are tried first, and only used when the
## records there pass the same check.

const NUL := 0
const NEWLINE := "\n"
## A record shorter than this is not a text.
const MIN_RECORD_LENGTH := 2


## The start of the level names: [param count] names, then [param count]
## entry texts; -1 when there are none.
static func find_level_texts(image: PackedByteArray, count: int, known: PackedInt32Array) -> int:
	if count <= 0:
		return -1
	for offset in known:
		if _are_level_texts(records_from(image, offset, count * 2), count):
			return offset
	for start in record_starts(image):
		var first := records_from(image, start, 1)
		if first.is_empty():
			continue
		if _are_level_texts(records_from(image, start, count * 2), count):
			return start
	return -1


## The start of a run of records with [param shape] lines each; -1 when
## there is none.
static func find_messages(
	image: PackedByteArray, shape: PackedInt32Array, known: PackedInt32Array
) -> int:
	if shape.is_empty():
		return -1
	for offset in known:
		if _has_shape(records_from(image, offset, shape.size()), shape):
			return offset
	for start in record_starts(image):
		if line_count(ExeStrings.record_at(image, start)) != shape[0]:
			continue
		if _has_shape(records_from(image, start, shape.size()), shape):
			return start
	return -1


## The start of a run of records of [param lengths] characters each; -1
## when there is none.
static func find_by_lengths(
	image: PackedByteArray, lengths: PackedInt32Array, known: PackedInt32Array
) -> int:
	if lengths.is_empty():
		return -1
	for offset in known:
		if _has_lengths(records_from(image, offset, lengths.size()), lengths):
			return offset
	for start in record_starts(image):
		if ExeStrings.record_at(image, start).length() != lengths[0]:
			continue
		if _has_lengths(records_from(image, start, lengths.size()), lengths):
			return start
	return -1


## [param count] text records from [param start] on, skipping the zeros
## between them; empty when one of them is not a text.
static func records_from(image: PackedByteArray, start: int, count: int) -> PackedStringArray:
	var records := PackedStringArray()
	var position := start
	if start < 0 or start >= image.size():
		return records
	while records.size() < count:
		while position < image.size() and image[position] == NUL and not records.is_empty():
			position += 1
		var end := image.find(NUL, position)
		if end < 0 or end - position < MIN_RECORD_LENGTH:
			return PackedStringArray()
		for index in range(position, end):
			if not _is_text_byte(image[index]):
				return PackedStringArray()
		records.append(image.slice(position, end).get_string_from_ascii())
		position = end + 1
	return records


## Where every text record of [param image] starts: runs of at least
## [constant MIN_RECORD_LENGTH] printable characters or newlines that end
## in a zero.
static func record_starts(image: PackedByteArray) -> PackedInt32Array:
	var starts := PackedInt32Array()
	var run_start := -1
	for index in image.size():
		var byte := image[index]
		if _is_text_byte(byte):
			if run_start < 0:
				run_start = index
			continue
		if byte == NUL and run_start >= 0 and index - run_start >= MIN_RECORD_LENGTH:
			starts.append(run_start)
		run_start = -1
	return starts


## How many lines [param record] has; a newline at its end does not start
## another.
static func line_count(record: String) -> int:
	return record.trim_suffix(NEWLINE).split(NEWLINE).size()


## [param record] on one line: newlines read as spaces.
static func one_line(record: String) -> String:
	return record.replace(NEWLINE, " ")


static func _are_level_texts(records: PackedStringArray, count: int) -> bool:
	if records.size() != count * 2:
		return false
	for index in count:
		var name := one_line(records[index])
		if not one_line(records[count + index]).ends_with(name):
			return false
	return true


static func _has_shape(records: PackedStringArray, shape: PackedInt32Array) -> bool:
	if records.size() != shape.size():
		return false
	for index in shape.size():
		if line_count(records[index]) != shape[index]:
			return false
	return true


static func _has_lengths(records: PackedStringArray, lengths: PackedInt32Array) -> bool:
	if records.size() != lengths.size():
		return false
	for index in lengths.size():
		if records[index].length() != lengths[index]:
			return false
	return true


static func _is_text_byte(byte: int) -> bool:
	return ExeStrings.is_printable(byte) or byte == ExeStrings.NEWLINE
