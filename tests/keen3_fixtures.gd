extends RefCounted
## A hand-made KEEN3.EXE program image for the Keen 3 tests, so that they
## run without Keen 3's files. It has every piece that [Keen3Executable]
## looks for, in the order and shape of the real image (see
## docs/keen3/file-formats.md), but none of the real texts: a sound block
## whose size word is too large, a table of words ending in 0xFFFF right
## before the first text, the four text blocks in Keen 3's order, a tile
## table with planes longer than the tile count, the status box, the points
## table with Mortimer's boxes after it, the pages of the ending, the
## finale name, the box over the finale, the ship's messages and the high
## score records. Everything lies far below the known positions, so every
## piece is found by the search.

const FILLER := 0x01
const TEXT_END := 0x1A
const PADDING := 8
const SOUND_PRIORITY := 2
const SOUND_UNKNOWN_BYTE := 8
const BEEP_DIVISOR := 0x0400
const SOUND_NAMES: PackedStringArray = ["TESTBEEP", "TESTBOOP"]
## How much larger than the block the size word in its header says it is.
const SOUND_SIZE_SURPLUS := 64
## The words before the first text: a value and the 0xFFFF that ends it.
const WORD_TABLE_VALUE := 0x07D0
const WORD_TABLE_ENTRIES := 3
## The tile table: fewer tiles than entries per plane, as in KEEN3.EXE.
const TILE_COUNT := 10
const TILE_STRIDE := Keen3Executable.TILE_TABLE_STRIDE
const DEADLY_TILE := 1
const EXIT_TILE := 2
const FLOOR_TILE := 3
const ANKH_TILE := 4
const SINGLE_CHARGE_TILE := 5
const ANIMATION_START := 6
const ANIMATION_FRAMES := 4
## Every word of the filler part of each plane.
const FILLER_FRAMES := 1
const SCORE_MARKER := "SCORES."
const SCORE_NAMES: PackedStringArray = ["Abc", "Bcd", "Cde"]
const PLACE_WORDS: PackedStringArray = ["one", "two", "three", "four", "five", "six", "seven"]


## The whole image.
static func image() -> PackedByteArray:
	var data := filler(64)
	data.append_array(sound_block())
	data.append_array(_word_table())
	for block in Keen3Executable.TextBlock.size():
		data.append_array(text("Block %d" % block))
		data.append_array(PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0]))
	data.append_array(filler(PADDING + data.size() % TileProperties.BYTES_PER_ENTRY))
	data.append_array(tile_table())
	data.append(0)
	data.append_array(_records(status_box()))
	data.append_array(_points_and_mortimer())
	data.append_array(_records(ending_records()))
	data.append_array(_records([Keen3Files.FINALE.to_lower(), "Fin\n Fin\n"]))
	data.append_array(filler(PADDING))
	data.append(0)
	data.append_array(_records(ship_records()))
	data.append_array(_score_records())
	data.append_array(filler(PADDING))
	return data


## A sound block in the layout of SOUNDS.CK1 with two short sounds; the
## size word in its header is larger than the block.
static func sound_block() -> PackedByteArray:
	var count := SOUND_NAMES.size()
	var data := PackedByteArray()
	data.resize(SoundFile.HEADER_SIZE + count * SoundFile.ENTRY_SIZE)
	data.encode_u32(0, 0x00444E53)  # "SND\0"
	data.encode_u16(SoundFile.COUNT_OFFSET, count)
	for index in count:
		var entry := SoundFile.HEADER_SIZE + index * SoundFile.ENTRY_SIZE
		data[entry + 2] = SOUND_PRIORITY
		data[entry + 3] = SOUND_UNKNOWN_BYTE
		var name := SOUND_NAMES[index].to_ascii_buffer()
		for at in name.size():
			data[entry + 4 + at] = name[at]
		var sound := PackedByteArray()
		sound.resize(2 * (index + 2))
		for step in index + 1:
			sound.encode_u16(step * 2, BEEP_DIVISOR)
		sound.encode_u16(sound.size() - 2, SoundFile.END_MARK)
		data.encode_u16(entry, data.size())
		data.append_array(sound)
	data.encode_u16(Keen2Executable.SOUND_SIZE_OFFSET, data.size() + SOUND_SIZE_SURPLUS)
	return data


## A text in the layout of the .CK1 text files, ending in the end mark.
static func text(title: String) -> PackedByteArray:
	var content := "%s\r\n\r\nA paragraph that is long enough to be a text block,\r\n" % title
	content += "with a second line.\r\n"
	var bytes := content.to_ascii_buffer()
	bytes.append(TEXT_END)
	return bytes


## Six planes of [constant TILE_STRIDE] words; the words after
## [constant TILE_COUNT] in each plane are filler.
static func tile_table() -> PackedByteArray:
	var table := PackedByteArray()
	table.resize(TILE_STRIDE * TileProperties.PLANE_COUNT * TileProperties.BYTES_PER_ENTRY)
	for tile in TILE_STRIDE:
		var frames := FILLER_FRAMES
		if tile >= ANIMATION_START and tile < ANIMATION_START + ANIMATION_FRAMES:
			frames = ANIMATION_FRAMES
		_set_word(table, TileProperties.Field.ANIMATION, tile, frames)
	_set_word(table, TileProperties.Field.BEHAVIOR, DEADLY_TILE, TileProperties.Behavior.DEADLY)
	_set_word(table, TileProperties.Field.BEHAVIOR, EXIT_TILE, TileProperties.Behavior.EXIT)
	_set_word(table, TileProperties.Field.BEHAVIOR, ANKH_TILE, Keen3Behavior.ANKH)
	_set_word(table, TileProperties.Field.BEHAVIOR, SINGLE_CHARGE_TILE, Keen3Behavior.SINGLE_CHARGE)
	_set_word(table, TileProperties.Field.TOP, FLOOR_TILE, TileProperties.Floor.SOLID)
	return table


## The status box: as many records as the real one, the first and the last
## exactly as wide as the box.
static func status_box() -> PackedStringArray:
	var width := Keen3Executable.STATUS_BOX_WIDTH
	var records := PackedStringArray()
	for index in Keen3Executable.STATUS_BOX_LINES:
		if index == 0 or index == Keen3Executable.STATUS_BOX_LINES - 1:
			records.append(("Row %d" % index).rpad(width))
		else:
			records.append(" ")
		if index < Keen3Executable.STATUS_BOX_LINES - 1:
			records[index] += "\n"
	return records


## Mortimer's boxes: line records named after their box and line.
static func mortimer_records() -> PackedStringArray:
	return _box_records("Mortimer", Keen3Executable.MORTIMER_BOX_LINES, false)


## The pages of the ending: every record ends in a line feed.
static func ending_records() -> PackedStringArray:
	return _box_records("Page", Keen3Executable.ENDING_PAGE_LINES, true)


## The ship's messages: the last line of each has no line feed.
static func ship_records() -> PackedStringArray:
	return _box_records("Ship", Keen3Executable.SHIP_MESSAGE_LINES, false)


static func filler(size: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(size)
	bytes.fill(FILLER)
	return bytes


## Records "NAME b.l" for line l of box b; with [param all_lines] every
## record ends in a line feed, otherwise all but the last of each box.
static func _box_records(
	box_name: String, sizes: PackedInt32Array, all_lines: bool
) -> PackedStringArray:
	var records := PackedStringArray()
	for box in sizes.size():
		for line in sizes[box]:
			var record := "%s %d.%d" % [box_name, box, line]
			if all_lines or line < sizes[box] - 1:
				record += "\n"
			records.append(record)
	return records


## Words that end in 0xFFFF; the last one runs right into the first text.
static func _word_table() -> PackedByteArray:
	var words := PackedByteArray()
	words.resize(WORD_TABLE_ENTRIES * 4)
	for index in WORD_TABLE_ENTRIES:
		words.encode_u16(index * 4, WORD_TABLE_VALUE)
		words.encode_u16(index * 4 + 2, SoundFile.END_MARK)
	return words


static func _points_and_mortimer() -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(Keen3Executable.POINTS.size() * Keen3Executable.POINT_BYTES)
	for index in Keen3Executable.POINTS.size():
		data.encode_u16(index * Keen3Executable.POINT_BYTES, Keen3Executable.POINTS[index])
	data.append_array(_records(mortimer_records()))
	return data


static func _score_records() -> PackedByteArray:
	var data := SCORE_MARKER.to_ascii_buffer()
	data.append(0)
	data.append_array(_records(SCORE_NAMES))
	data.append_array(filler(PADDING))
	data.append_array(SCORE_MARKER.to_ascii_buffer())
	data.append(0)
	data.append_array(_records(PLACE_WORDS))
	return data


## Each record followed by its zero byte.
static func _records(records: PackedStringArray) -> PackedByteArray:
	var data := PackedByteArray()
	for record in records:
		data.append_array(record.to_ascii_buffer())
		data.append(0)
	return data


static func _set_word(table: PackedByteArray, field: int, tile: int, value: int) -> void:
	var position := (field * TILE_STRIDE + tile) * TileProperties.BYTES_PER_ENTRY
	table.encode_s16(position, value)
