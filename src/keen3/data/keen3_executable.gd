class_name Keen3Executable
extends RefCounted
## The data inside KEEN3.EXE: like Keen 2, Keen 3 has no SOUNDS, STORYTXT,
## HELPTEXT, PREVIEWS or ENDTEXT file, so the sounds and the texts are read
## from the unpacked program image (see [method DosExecutable.load_image]),
## together with the tile properties, the status screen's box, Mortimer's
## messages in level 16, the pages of the ending and the ship's messages on
## the map.
##
## Only data is read; the program code is never looked at. Every piece is
## found by its content. The positions known for version 1.00 (the player's
## files) and 1.31 (Chocolate Keen) are only tried first, and only used when
## the data there passes the same check as the search. The generic searches
## of [Keen2Executable] are called, not copied. See
## docs/keen3/file-formats.md.

## The text blocks, in the order in which they follow each other in the
## image. Keen 2 has the end text first; Keen 3 the help.
enum TextBlock { HELP, END_TEXT, PREVIEWS, STORY }
## The runs of line records that are searched for record by record.
enum RecordShape { STATUS_BOX, SHIP_MESSAGES }

## The words that the footer of the original's text reader starts with
## ("ESC to Exit / <up> <down> to Read", red on gray; seen in the original,
## C11).
const READER_FOOTER_WORDS := "ESC to Exit /"
## Raw image positions of the text blocks, in the order of [enum TextBlock].
const TEXT_OFFSETS_V1_00: PackedInt32Array = [0x17B00, 0x182D0, 0x18610, 0x18D00]
const TEXT_OFFSETS_V1_31: PackedInt32Array = [0x179D0, 0x181A0, 0x184E0, 0x18BD0]
## The tile property table (version 1.00, then 1.31). Its six planes are
## [constant TILE_TABLE_STRIDE] entries apart, more than the 624 tiles.
const TILE_TABLE_OFFSETS: PackedInt32Array = [0x199F8, 0x198C8]
const TILE_TABLE_STRIDE := 715
## The status screen's box (version 1.00): one record per line, the last
## without a line feed, every line at most as wide as the box, the first and
## the last exactly as wide.
const STATUS_BOX_OFFSET := 0x1BC38
const STATUS_BOX_LINES := 11
const STATUS_BOX_WIDTH := 28
## The points of the five point items, five words in a row. Mortimer's
## messages are the line records right after them.
const POINTS: PackedInt32Array = [500, 100, 200, 1000, 5000]
const POINT_BYTES := 2
## How many lines each of Mortimer's nine boxes has (the box heights of
## docs/keen3/research.md §9).
const MORTIMER_BOX_LINES: PackedInt32Array = [1, 1, 1, 5, 5, 2, 4, 1, 3]
## How many lines each of the four pages of the ending has. The pages are
## the line records right before the record naming the finale picture.
const ENDING_PAGE_LINES: PackedInt32Array = [4, 3, 3, 1]
## The ship's four messages (version 1.00): one record per line; the last
## line of each message has no line feed.
const SHIP_MESSAGES_OFFSET := 0x1CF00
const SHIP_MESSAGE_LINES: PackedInt32Array = [4, 3, 4, 4]
## The line under a ship's message is two records (the prompt and the word
## for a key).
const SHIP_PROMPT_RECORDS := 2
## No line of a message is wider than the screen.
const MAX_LINE_WIDTH := 40
const CARRIAGE_RETURN := 0x0D

## Sizes that tell the version. As in [Keen2Executable], the sizes from
## Commander Genius include a 512-byte header; both readings are accepted.
const UNPACKED_SIZES: Dictionary[String, int] = {"1.00": 127598, "1.31": 127616}
const POSSIBLE_HEADER_SIZE := 512
## The size of the LZEXE-packed KEEN3.EXE on disk.
const PACKED_SIZES: Dictionary[String, int] = {"1.00": 61619, "1.31": 61599}
const UNKNOWN_VERSION := "unknown"

## The unpacked program image.
var image := PackedByteArray()
## "1.00", "1.31" or "unknown".
var version := UNKNOWN_VERSION


## Reads and unpacks KEEN3.EXE. Returns null when it is missing or cannot
## be unpacked.
static func load_from(files: GameFiles) -> Keen3Executable:
	var exe := files.read(Keen3Files.EXECUTABLE)
	if exe.is_empty():
		return null
	var unpacked := DosExecutable.load_image(exe)
	if unpacked.is_empty():
		push_error("%s could not be unpacked." % Keen3Files.EXECUTABLE)
		return null
	return from_image(unpacked, exe.size())


## Wraps an already unpacked [param program_image]. [param exe_size] is the
## size of the file on disk, when known.
static func from_image(program_image: PackedByteArray, exe_size := 0) -> Keen3Executable:
	var executable := Keen3Executable.new()
	executable.image = program_image
	executable.version = version_for(program_image.size(), exe_size)
	return executable


## The version that an image of [param image_size] bytes (and a file of
## [param exe_size] bytes on disk) belongs to, or "unknown".
static func version_for(image_size: int, exe_size := 0) -> String:
	for label in PACKED_SIZES:
		if exe_size == PACKED_SIZES[label]:
			return label
	for label in UNPACKED_SIZES:
		var size := UNPACKED_SIZES[label]
		if image_size == size or image_size + POSSIBLE_HEADER_SIZE == size:
			return label
	return UNKNOWN_VERSION


## The sound block, ready for [method SoundFile.parse]; empty when the
## image has none. It ends after the data of its last sound: the size word
## in its header is larger than the block in KEEN3.EXE.
func sound_data() -> PackedByteArray:
	var start := find_sound_block(image)
	var end := sound_block_end(image, start)
	if end < 0:
		push_error("No sound block found in %s." % Keen3Files.EXECUTABLE)
		return PackedByteArray()
	return image.slice(start, end)


## The PC speaker sounds; null when the image has none.
func sounds() -> SoundFile:
	var data := sound_data()
	return SoundFile.parse(data) if not data.is_empty() else null


## The tile properties for [param tile_count] tiles (from EGAHEAD.CK3);
## null when no table is found.
func tile_properties(tile_count: int) -> TileProperties:
	return TileProperties.find_in_image(image, tile_count, TILE_TABLE_OFFSETS, TILE_TABLE_STRIDE)


## The bytes of a text block up to and including its end mark, ready for
## [method TextDocument.layout]; empty when it is not found.
func text(block: TextBlock) -> PackedByteArray:
	var start := find_text_block(image, block)
	if start < 0:
		push_error(
			"Text block %s not found in %s." % [TextBlock.keys()[block], Keen3Files.EXECUTABLE]
		)
		return PackedByteArray()
	return image.slice(start, Keen2Executable.text_end(image, start) + 1)


## The lines of the status screen's box, with their spaces (they lay out
## the labels), without line feeds; empty when they are not found.
func status_box_lines() -> PackedStringArray:
	var start := find_status_box(image)
	if start < 0:
		return PackedStringArray()
	var lines := PackedStringArray()
	for record in _records(image, start, STATUS_BOX_LINES):
		lines.append(record.trim_suffix("\n"))
	return lines


## Mortimer's nine boxes in level 16, each as its lines ([method
## typed_lines]), in the order of [constant MORTIMER_BOX_LINES]; empty when
## they are not found.
func mortimer_messages() -> Array[PackedStringArray]:
	var start := find_mortimer_messages(image)
	if start < 0:
		return []
	var records := _records(image, start, _total(MORTIMER_BOX_LINES))
	return _grouped(records, MORTIMER_BOX_LINES, true)


## The four pages of the ending, each as its lines ([method typed_lines]);
## empty when they are not found.
func ending_pages() -> Array[PackedStringArray]:
	var finale := find_finale_name(image)
	if finale < 0:
		return []
	var lines := ExeStrings.lines_before(image, finale)
	if lines.size() != _total(ENDING_PAGE_LINES):
		return []
	var records := PackedStringArray()
	for line in lines:
		records.append(line + "\n")
	return _grouped(records, ENDING_PAGE_LINES, true)


## The lines of the box over the finale picture ([method typed_lines]);
## empty when not found.
func the_end() -> PackedStringArray:
	var start := find_the_end(image)
	if start < 0:
		return PackedStringArray()
	return typed_lines(ExeStrings.record_at(image, start))


## The footer of the text reader (the end text), as stored with its
## spaces; empty when not found.
func reader_footer() -> String:
	var start := find_reader_footer(image)
	return ExeStrings.record_at(image, start) if start >= 0 else ""


## The ship's four messages on the world map, each as its lines; empty when
## they are not found.
func ship_messages() -> Array[PackedStringArray]:
	var start := find_ship_messages(image)
	if start < 0:
		return []
	return _grouped(_records(image, start, _total(SHIP_MESSAGE_LINES)), SHIP_MESSAGE_LINES)


## The line under each of the ship's messages (asking for a key): the two
## records right after the messages, the first starting with a line feed;
## empty when they are not found.
func ship_prompt() -> String:
	var start := find_ship_messages(image)
	if start < 0:
		return ""
	var count := _total(SHIP_MESSAGE_LINES)
	var records := _records(image, start, count + SHIP_PROMPT_RECORDS)
	if records.size() != count + SHIP_PROMPT_RECORDS:
		return ""
	var prompt := "".join(records.slice(count))
	if not prompt.begins_with("\n") or prompt.count("\n") != 1:
		return ""
	return prompt.trim_prefix("\n")


## The names of a new high score table and the words for the places, as in
## Keen 1's executable; null when not found.
func score_texts() -> ScoreTexts:
	return ScoreTexts.find_in_image(image)


## Where the sound block starts in [param data], or -1 (the search of
## [method Keen2Executable.find_sound_block]: "SND\0" and a table that fits).
static func find_sound_block(data: PackedByteArray) -> int:
	return Keen2Executable.find_sound_block(data)


## Where the data of the last sound of the block at [param start] ends (one
## past its end mark), or -1 when there is no block or a sound runs past the
## end of [param data].
static func sound_block_end(data: PackedByteArray, start: int) -> int:
	if start < 0:
		return -1
	var count := data.decode_u16(start + SoundFile.COUNT_OFFSET)
	var end := start + SoundFile.HEADER_SIZE + count * SoundFile.ENTRY_SIZE
	for index in count:
		var position := (
			start + data.decode_u16(start + SoundFile.HEADER_SIZE + index * SoundFile.ENTRY_SIZE)
		)
		while position + 1 < data.size() and data.decode_u16(position) != SoundFile.END_MARK:
			position += 2
		if position + 1 >= data.size():
			return -1
		end = maxi(end, position + 2)
	return end


## The starts of all text blocks in [param data], in order. They are the
## blocks of [method Keen2Executable.text_blocks], but a block never starts
## with a font picture (0x80 and up): in KEEN3.EXE the 0xFFFF that ends the
## words before the help text would otherwise count as its first two bytes.
static func text_blocks(data: PackedByteArray) -> PackedInt32Array:
	var starts := PackedInt32Array()
	for start in Keen2Executable.text_blocks(data):
		var end := Keen2Executable.text_end(data, start)
		var first := start
		while first < end and data[first] >= Keen2Executable.FONT_PICTURES_START:
			first += 1
		if end - first >= Keen2Executable.MIN_TEXT_SIZE:
			starts.append(first)
	return starts


## Where [param block] starts in [param data], or -1. A known position is
## used when a block starts there; otherwise, when there are exactly as many
## blocks as [enum TextBlock] names, their order tells which is which.
static func find_text_block(data: PackedByteArray, block: TextBlock) -> int:
	var blocks := text_blocks(data)
	for known in [TEXT_OFFSETS_V1_00[block], TEXT_OFFSETS_V1_31[block]]:
		if known in blocks:
			return known
	return blocks[block] if blocks.size() == TextBlock.size() else -1


## Where the status screen's box starts in [param data], or -1.
static func find_status_box(data: PackedByteArray) -> int:
	if _is_status_box(data, STATUS_BOX_OFFSET):
		return STATUS_BOX_OFFSET
	return _find_record_start(data, RecordShape.STATUS_BOX)


## Where the five words of [constant POINTS] start in [param data], or -1.
static func find_points_table(data: PackedByteArray) -> int:
	var words := PackedByteArray()
	words.resize(POINTS.size() * POINT_BYTES)
	for index in POINTS.size():
		words.encode_u16(index * POINT_BYTES, POINTS[index])
	return ExeStrings.find(data, words)


## Where Mortimer's first box starts in [param data] (right after the points
## table), or -1 when the records there are not his boxes.
static func find_mortimer_messages(data: PackedByteArray) -> int:
	var points := find_points_table(data)
	if points < 0:
		return -1
	var start := points + POINTS.size() * POINT_BYTES
	var records := _records(data, start, _total(MORTIMER_BOX_LINES))
	return start if records.size() == _total(MORTIMER_BOX_LINES) else -1


## Where the record naming the finale picture (FINALE.CK3, in any case)
## starts in [param data], or -1.
static func find_finale_name(data: PackedByteArray) -> int:
	for name in [Keen3Files.FINALE.to_lower(), Keen3Files.FINALE]:
		var position := ExeStrings.find(data, name.to_ascii_buffer())
		if position > 0 and data[position - 1] == 0:
			return position
	return -1


## Where the record with the text reader's footer starts in [param data]
## (the record that holds [constant READER_FOOTER_WORDS]), or -1.
static func find_reader_footer(data: PackedByteArray) -> int:
	var position := ExeStrings.find(data, READER_FOOTER_WORDS.to_ascii_buffer())
	if position < 0:
		return -1
	while position > 0 and data[position - 1] != 0:
		position -= 1
	return position


## Where the box over the finale picture starts in [param data] (the record
## after the finale name), or -1.
static func find_the_end(data: PackedByteArray) -> int:
	var finale := find_finale_name(data)
	if finale < 0:
		return -1
	var start := finale + Keen3Files.FINALE.length() + 1
	return start if _records(data, start, 1).size() == 1 else -1


## Where the first of the ship's four messages starts in [param data], or -1.
static func find_ship_messages(data: PackedByteArray) -> int:
	if _are_ship_messages(data, SHIP_MESSAGES_OFFSET):
		return SHIP_MESSAGES_OFFSET
	return _find_record_start(data, RecordShape.SHIP_MESSAGES)


## The first record start in [param data] (right after a zero byte) where
## records of [param shape] start, or -1.
static func _find_record_start(data: PackedByteArray, shape: RecordShape) -> int:
	var zero := data.find(0)
	while zero >= 0:
		if _has_shape(data, zero + 1, shape):
			return zero + 1
		zero = data.find(0, zero + 1)
	return -1


static func _has_shape(data: PackedByteArray, start: int, shape: RecordShape) -> bool:
	if shape == RecordShape.STATUS_BOX:
		return _is_status_box(data, start)
	return _are_ship_messages(data, start)


static func _is_status_box(data: PackedByteArray, start: int) -> bool:
	if not _is_record_start(data, start):
		return false
	# The quick test first: the first line is exactly as wide as the box.
	if data.find(0, start) != start + STATUS_BOX_WIDTH + 1:
		return false
	var sizes := PackedInt32Array([STATUS_BOX_LINES])
	if not _has_message_shape(data, start, sizes, STATUS_BOX_WIDTH):
		return false
	var records := _records(data, start, STATUS_BOX_LINES)
	return records[-1].length() == STATUS_BOX_WIDTH


static func _are_ship_messages(data: PackedByteArray, start: int) -> bool:
	return (
		_is_record_start(data, start)
		and _has_message_shape(data, start, SHIP_MESSAGE_LINES, MAX_LINE_WIDTH)
	)


## Whether the records from [param start] are messages of [param sizes]
## lines each: every line but the last of a message ends in a line feed, the
## last does not, and no line is wider than [param width].
static func _has_message_shape(
	data: PackedByteArray, start: int, sizes: PackedInt32Array, width: int
) -> bool:
	var position := start
	for size in sizes:
		for line in size:
			var end := data.find(0, position)
			if end <= position or not _is_text_record(data, position, end):
				return false
			var has_line_feed := data[end - 1] == ExeStrings.NEWLINE
			if has_line_feed != (line < size - 1):
				return false
			if end - position - int(has_line_feed) > width:
				return false
			position = end + 1
	return true


## [param count] non-empty text records from [param start]; empty when
## there are fewer.
static func _records(data: PackedByteArray, start: int, count: int) -> PackedStringArray:
	var records := PackedStringArray()
	var position := start
	while records.size() < count:
		if position < 0 or position >= data.size():
			return PackedStringArray()
		var end := data.find(0, position)
		if end <= position or not _is_text_record(data, position, end):
			return PackedStringArray()
		records.append(data.slice(position, end).get_string_from_ascii())
		position = end + 1
	return records


## The lines of a typed text ([Keen3TypedBoxes]): as
## [method Keen2Executable.message_lines], but a line keeps its trailing
## spaces, because the original takes a letter's time for each of them
## (seen in the original, C11).
static func typed_lines(text: String) -> PackedStringArray:
	var lines := text.replace("\r", "").split("\n")
	while not lines.is_empty() and lines[-1].strip_edges().is_empty():
		lines.remove_at(lines.size() - 1)
	return lines


## The [param records] in groups of [param sizes], each group as the lines
## of one message; with [param typed] as [method typed_lines].
static func _grouped(
	records: PackedStringArray, sizes: PackedInt32Array, typed := false
) -> Array[PackedStringArray]:
	var groups: Array[PackedStringArray] = []
	if records.size() != _total(sizes):
		return groups
	var first := 0
	for size in sizes:
		var group := records.slice(first, first + size)
		var text := "".join(group)
		groups.append(typed_lines(text) if typed else Keen2Executable.message_lines(text))
		first += size
	return groups


static func _total(sizes: PackedInt32Array) -> int:
	var total := 0
	for size in sizes:
		total += size
	return total


## Whether a record can start at [param start]: right after a zero byte.
static func _is_record_start(data: PackedByteArray, start: int) -> bool:
	return start > 0 and start < data.size() and data[start - 1] == 0


## Whether the bytes from [param start] up to [param end] are printable
## text and line ends.
static func _is_text_record(data: PackedByteArray, start: int, end: int) -> bool:
	for position in range(start, end):
		var byte := data[position]
		if not ExeStrings.is_printable(byte) and byte not in [CARRIAGE_RETURN, ExeStrings.NEWLINE]:
			return false
	return true
