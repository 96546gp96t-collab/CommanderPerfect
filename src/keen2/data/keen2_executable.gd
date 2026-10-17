class_name Keen2Executable
extends RefCounted
## The data inside KEEN2.EXE: Keen 2 has no SOUNDS, STORYTXT, HELPTEXT or
## ENDTEXT file, so the sounds and the texts are read from the unpacked
## program image (see [method DosExecutable.load_image]), together with the
## tile properties and the strings of the status screen and the ending.
##
## Only data is read; the program code is never looked at. Every piece is
## found by its content. The positions known for version 1.31 (from
## docs/keen2/research.md) are only tried first, and only used when the data
## there passes the same check, so other versions work as well.
## See docs/keen2/file-formats.md.

## The text blocks, in the order in which they follow each other in the
## image (version 1.31).
enum TextBlock { END_TEXT, HELP, PREVIEWS, STORY }

## Raw image positions in version 1.31, tried before searching.
const SOUND_OFFSET := 0x12730
const TEXT_OFFSETS: PackedInt32Array = [0x15840, 0x15BC0, 0x163A0, 0x16AC0]
const CITY_NAMES_OFFSET := 0x199AB
const TO_BE_CONTINUED_OFFSET := 0x1A434
## The two messages of the Vorticon Elders (version 1.31).
const ELDER_MESSAGE_OFFSETS: PackedInt32Array = [0x19FCC, 0x1A08C]
## An Elder message is a run of zero-terminated records of printable text,
## one per line, each ending in a line feed (like Keen 1's statue messages),
## at least this long in all. The record after the last line ("Press
## ENTER:") has no line feed and is not part of the message.
const MIN_ELDER_MESSAGE_SIZE := 32
## The tile property table in version 1.31 and 1.00.
const TILE_TABLE_OFFSETS: PackedInt32Array = [0x17828, 0x17938]

## The sound block has the layout of SOUNDS.CK1 (see [SoundFile]).
const SOUND_SIGNATURE: PackedByteArray = [0x53, 0x4E, 0x44, 0x00]  # "SND\0"
const SOUND_SIZE_OFFSET := 4

## A text block is at least this long, has lines ending in CR LF and ends
## with [constant TextDocument.END_MARK]; this keeps short strings and code
## from looking like one.
const MIN_TEXT_SIZE := 64
const CARRIAGE_RETURN := 0x0D
const TAB := 0x09
## Bytes from here on are pictures in the game font.
const FONT_PICTURES_START := 0x80

## The cities, one zero-terminated string each, in the order of their
## levels (4, 6, 7, 9, 11, 13, 15, 16). The lengths come from Commander
## Genius's string table; the names themselves are only in the file
## (version 1.31: London, Cairo, Sydney, New York, Paris, Rome, Moscow,
## Wash D.C.).
const CITY_COUNT := 8
const CITY_NAME_LENGTHS: PackedInt32Array = [6, 5, 6, 8, 5, 4, 6, 9]
const MAX_CITY_NAME_LENGTH := 16
## Besides letters, a city name may hold these ("New York", "Wash D.C.").
const CITY_NAME_MARKS := " ."
const TO_BE_CONTINUED := "TO BE CONTINUED"

## Sizes that tell the version. Commander Genius gives the size of the
## unpacked EXE including a 512-byte header (version 1.31's image is
## 118,160 bytes); both readings are accepted.
const UNPACKED_SIZES: Dictionary[String, int] = {"1.31": 118672, "1.00": 118626}
const POSSIBLE_HEADER_SIZE := 512
## The size of the LZEXE-packed KEEN2.EXE 1.31 on disk.
const PACKED_SIZE_V1_31 := 58335
const VERSION_1_31 := "1.31"
const UNKNOWN_VERSION := "unknown"

## The unpacked program image.
var image := PackedByteArray()
## "1.31", "1.00" or "unknown".
var version := UNKNOWN_VERSION


## Reads and unpacks KEEN2.EXE. Returns null when it is missing or cannot
## be unpacked.
static func load_from(files: GameFiles) -> Keen2Executable:
	var exe := files.read(Keen2Files.EXECUTABLE)
	if exe.is_empty():
		return null
	var unpacked := DosExecutable.load_image(exe)
	if unpacked.is_empty():
		push_error("%s could not be unpacked." % Keen2Files.EXECUTABLE)
		return null
	return from_image(unpacked, exe.size())


## Wraps an already unpacked [param program_image]. [param exe_size] is the
## size of the file on disk, when known.
static func from_image(program_image: PackedByteArray, exe_size := 0) -> Keen2Executable:
	var executable := Keen2Executable.new()
	executable.image = program_image
	executable.version = version_for(program_image.size(), exe_size)
	return executable


## The version that an image of [param image_size] bytes (and a file of
## [param exe_size] bytes on disk) belongs to, or "unknown".
static func version_for(image_size: int, exe_size := 0) -> String:
	if exe_size == PACKED_SIZE_V1_31:
		return VERSION_1_31
	for label in UNPACKED_SIZES:
		var size := UNPACKED_SIZES[label]
		if image_size == size or image_size + POSSIBLE_HEADER_SIZE == size:
			return label
	return UNKNOWN_VERSION


## The sound block, ready for [method SoundFile.parse]; empty when the
## image has none.
func sound_data() -> PackedByteArray:
	var start := find_sound_block(image)
	if start < 0:
		push_error("No sound block found in %s." % Keen2Files.EXECUTABLE)
		return PackedByteArray()
	return image.slice(start, start + image.decode_u16(start + SOUND_SIZE_OFFSET))


## The PC speaker sounds; null when the image has none.
func sounds() -> SoundFile:
	var data := sound_data()
	return SoundFile.parse(data) if not data.is_empty() else null


## The tile properties for [param tile_count] tiles (from EGAHEAD.CK2);
## null when no table is found.
func tile_properties(tile_count: int) -> TileProperties:
	return TileProperties.find_in_image(image, tile_count, TILE_TABLE_OFFSETS)


## The bytes of a text block up to and including its end mark, ready for
## [method TextDocument.layout]; empty when it is not found.
func text(block: TextBlock) -> PackedByteArray:
	var start := find_text_block(image, block)
	if start < 0:
		push_error(
			"Text block %s not found in %s." % [TextBlock.keys()[block], Keen2Files.EXECUTABLE]
		)
		return PackedByteArray()
	return image.slice(start, text_end(image, start) + 1)


## The eight city names, in the order of their levels; empty when they are
## not found.
func city_names() -> PackedStringArray:
	var start := find_city_names(image)
	if start < 0:
		push_error("The city names were not found in %s." % Keen2Files.EXECUTABLE)
		return PackedStringArray()
	return _records_from(image, start, CITY_COUNT)


## The "TO BE CONTINUED...." record; empty when it is not found.
func to_be_continued() -> String:
	var start := find_to_be_continued(image)
	if start < 0:
		push_error("No %s text found in %s." % [TO_BE_CONTINUED, Keen2Files.EXECUTABLE])
		return ""
	return ExeStrings.record_at(image, start)


## The lines of Elder message [param index] (0 or 1); empty when it is not
## found. Not finding it is no error: only version 1.31's positions are
## known, and without the message the Elder stays silent.
func elder_message(index: int) -> PackedStringArray:
	var start := find_elder_message(image, index)
	if start < 0:
		return PackedStringArray()
	return message_lines(elder_message_text(image, start))


## Where Elder message [param index] starts in [param data], or -1. Only the
## known position is tried, and only used when a message of printable lines
## starts there.
static func find_elder_message(data: PackedByteArray, index: int) -> int:
	if index < 0 or index >= ELDER_MESSAGE_OFFSETS.size():
		return -1
	var start := ELDER_MESSAGE_OFFSETS[index]
	if start <= 0 or start >= data.size() or ExeStrings.is_printable(data[start - 1]):
		return -1
	return start if elder_message_text(data, start).length() >= MIN_ELDER_MESSAGE_SIZE else -1


## The text of the Elder message from [param start]: its line records one
## after the other. It ends before a record without a line feed, a record
## that is not printable text, or the start of the other message.
static func elder_message_text(data: PackedByteArray, start: int) -> String:
	var text := ""
	var position := start
	while position < data.size():
		var end := data.find(0, position)
		if end < 0 or not _is_message_record(data, position, end):
			break
		var record := data.slice(position, end).get_string_from_ascii()
		if not record.ends_with("\n"):
			break
		text += record
		position = end + 1
		if position in ELDER_MESSAGE_OFFSETS:
			break
	return text


## The lines of [param text]: split at the line ends, without carriage
## returns, trailing spaces and empty lines at the end.
static func message_lines(text: String) -> PackedStringArray:
	var lines := PackedStringArray()
	for line in text.replace("\r", "").split("\n"):
		lines.append(line.strip_edges(false, true))
	while not lines.is_empty() and lines[-1].is_empty():
		lines.remove_at(lines.size() - 1)
	return lines


## Where the sound block starts in [param data], or -1.
static func find_sound_block(data: PackedByteArray) -> int:
	if _is_sound_block(data, SOUND_OFFSET):
		return SOUND_OFFSET
	var position := ExeStrings.find(data, SOUND_SIGNATURE)
	while position >= 0:
		if _is_sound_block(data, position):
			return position
		position = ExeStrings.find(data, SOUND_SIGNATURE, position + 1)
	return -1


## Where [param block] starts in [param data], or -1. Without a valid block
## at the known position, the blocks found by their shape are counted:
## when there are exactly as many as [enum TextBlock] names, their order
## tells which is which.
static func find_text_block(data: PackedByteArray, block: TextBlock) -> int:
	var known := TEXT_OFFSETS[block]
	if _is_text_start(data, known) and _is_text_block(data, known):
		return known
	var blocks := text_blocks(data)
	return blocks[block] if blocks.size() == TextBlock.size() else -1


## The starts of all text blocks in [param data], in order.
static func text_blocks(data: PackedByteArray) -> PackedInt32Array:
	var starts := PackedInt32Array()
	var end := data.find(TextDocument.END_MARK)
	while end >= 0:
		var start := end
		while start > 0 and _is_text_byte(data[start - 1]):
			start -= 1
		if _is_text_block(data, start):
			starts.append(start)
		end = data.find(TextDocument.END_MARK, end + 1)
	return starts


## The position of the end mark of the text that starts at [param start],
## or -1 when a byte that is not text comes first.
static func text_end(data: PackedByteArray, start: int) -> int:
	var position := start
	while position < data.size() and _is_text_byte(data[position]):
		position += 1
	if position < data.size() and data[position] == TextDocument.END_MARK:
		return position
	return -1


## Where the first of the eight city names starts in [param data], or -1.
static func find_city_names(data: PackedByteArray) -> int:
	if _are_city_names(data, CITY_NAMES_OFFSET, false):
		return CITY_NAMES_OFFSET
	var zero := data.find(0)
	while zero >= 0:
		if _are_city_names(data, zero + 1, true):
			return zero + 1
		zero = data.find(0, zero + 1)
	return -1


## Where the "TO BE CONTINUED" record starts in [param data], or -1.
static func find_to_be_continued(data: PackedByteArray) -> int:
	var needle := TO_BE_CONTINUED.to_ascii_buffer()
	if _bytes_at(data, TO_BE_CONTINUED_OFFSET, needle.size()) == needle:
		return TO_BE_CONTINUED_OFFSET
	return ExeStrings.find(data, needle)


static func _is_sound_block(data: PackedByteArray, start: int) -> bool:
	if start < 0 or start + SoundFile.HEADER_SIZE > data.size():
		return false
	if _bytes_at(data, start, SOUND_SIGNATURE.size()) != SOUND_SIGNATURE:
		return false
	var size := data.decode_u16(start + SOUND_SIZE_OFFSET)
	var count := data.decode_u16(start + SoundFile.COUNT_OFFSET)
	return (
		count > 0
		and start + size <= data.size()
		and SoundFile.HEADER_SIZE + count * SoundFile.ENTRY_SIZE <= size
	)


## Whether the bytes from [param start] up to [param end] are printable
## text and line ends.
static func _is_message_record(data: PackedByteArray, start: int, end: int) -> bool:
	for position in range(start, end):
		var byte := data[position]
		if not ExeStrings.is_printable(byte) and byte not in [CARRIAGE_RETURN, ExeStrings.NEWLINE]:
			return false
	return true


## Whether a text block can start at [param start]: nothing that is text
## runs into it from before.
static func _is_text_start(data: PackedByteArray, start: int) -> bool:
	if start < 0 or start >= data.size():
		return false
	return start == 0 or not _is_text_byte(data[start - 1])


## Whether the text from [param start] is long enough, has lines and ends
## in the end mark.
static func _is_text_block(data: PackedByteArray, start: int) -> bool:
	if start < 0 or start >= data.size():
		return false
	var end := text_end(data, start)
	if end - start < MIN_TEXT_SIZE:
		return false
	var line_end := PackedByteArray([CARRIAGE_RETURN, ExeStrings.NEWLINE])
	return ExeStrings.find(data.slice(start, end), line_end) >= 0


## Printable characters, line ends, tabs, the break mark and font pictures.
static func _is_text_byte(byte: int) -> bool:
	return (
		ExeStrings.is_printable(byte)
		or byte >= FONT_PICTURES_START
		or byte in [CARRIAGE_RETURN, ExeStrings.NEWLINE, TAB, TextDocument.BREAK_MARK]
	)


## Whether eight city names start at [param start]. With
## [param exact_lengths] each must have its known length; otherwise any
## short name of letters and spaces will do.
static func _are_city_names(data: PackedByteArray, start: int, exact_lengths: bool) -> bool:
	if start <= 0 or start >= data.size() or data[start - 1] != 0:
		return false
	var position := start
	for index in CITY_COUNT:
		var name := ExeStrings.record_at(data, position)
		if exact_lengths and name.length() != CITY_NAME_LENGTHS[index]:
			return false
		if not _looks_like_city(name):
			return false
		position += name.length() + 1
	return position <= data.size()


static func _looks_like_city(name: String) -> bool:
	if name.is_empty() or name.length() > MAX_CITY_NAME_LENGTH:
		return false
	if not _is_letter(name.unicode_at(0)):
		return false
	for index in name.length():
		var code := name.unicode_at(index)
		if not _is_letter(code) and not CITY_NAME_MARKS.contains(String.chr(code)):
			return false
	return true


static func _is_letter(code: int) -> bool:
	var upper := String.chr(code).to_upper().unicode_at(0)
	return upper >= "A".unicode_at(0) and upper <= "Z".unicode_at(0)


static func _records_from(data: PackedByteArray, start: int, count: int) -> PackedStringArray:
	var records := PackedStringArray()
	var position := start
	for index in count:
		var record := ExeStrings.record_at(data, position)
		records.append(record)
		position += record.length() + 1
	return records


## [param length] bytes from [param start], or fewer at the end of the data.
static func _bytes_at(data: PackedByteArray, start: int, length: int) -> PackedByteArray:
	if start < 0 or start >= data.size():
		return PackedByteArray()
	return data.slice(start, start + length)
