extends RefCounted
## A hand-made KEEN3.EXE program image for the Keen 3 tests, so that they
## run without Keen 3's files. It has every piece that [Keen3Executable]
## looks for, in the order and shape of the real image (see
## docs/keen3/file-formats.md), but none of the real texts: a sound block
## whose size word is too large, a table of words ending in 0xFFFF right
## before the first text, the four text blocks in Keen 3's order, a tile
## table with planes longer than the tile count, the status box, the points
## table with Mortimer's boxes after it, the pages of the ending, the
## finale name, the box over the finale, the ship's messages with the line
## under them and the high score records. Everything lies far below the known positions, so every
## piece is found by the search.
##
## Also small hand-made levels for the level tests (tests/test_keen3_level.gd):
## a tile table with Keen 3's item rows (each row starts with its own
## background), its doors, its exit and its border tile, levels drawn with
## the characters of [constant LEGEND], and a session with Keen at a cell.

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
## The line under a ship's message, in two records as in KEEN3.EXE.
const SHIP_PROMPT_RECORDS: PackedStringArray = ["\n   Hit any ", "thing:"]
const SHIP_PROMPT := "   Hit any thing:"

## The tile table of the hand-made levels: long enough for the border tile
## and the exit, with Keen 3's tile numbers.
const LEVEL_TILE_COUNT := 260
const AIR := 0
const WALL := 1
const FIRE := 2
## Behaviour 22: becomes tile 143 when touched, nothing else.
const ODD_22 := 3
## An item row of the tile table: its first tile is its background.
const ITEM_ROW := 156
const CANDY := 157
const BURGER := 158
const COLA := 159
const CAKE := 160
const STUFFED_NINJA := 161
const ANKH := 162
const SINGLE_CHARGE := 163
const RAYGUN := 164
const YELLOW_CARD := 165
const RED_CARD := 166
const GREEN_CARD := 167
const BLUE_CARD := 168
## A candy bar of another row, with another background.
const OTHER_ROW := 182
const OTHER_CANDY := 183
## A plain tile that is not empty air: what stands left of a door.
const WALLPAPER := 195
const YELLOW_DOOR := 234
const RED_DOOR := 236
const BORDER := 245
const EXIT := 255
const LEVEL_LEGEND := {
	".": AIR,
	"#": WALL,
	"X": FIRE,
	"o": ODD_22,
	"5": CANDY,
	"1": BURGER,
	"2": COLA,
	"K": CAKE,
	"N": STUFFED_NINJA,
	"A": ANKH,
	"c": SINGLE_CHARGE,
	"g": RAYGUN,
	"y": YELLOW_CARD,
	"k": RED_CARD,
	"n": GREEN_CARD,
	"b": BLUE_CARD,
	"6": OTHER_CANDY,
	"w": WALLPAPER,
	"Y": YELLOW_DOOR,
	"D": RED_DOOR,
	"E": EXIT,
}
const LEVEL_BEHAVIORS: Dictionary[int, int] = {
	FIRE: TileProperties.Behavior.DEADLY,
	ODD_22: TileProperties.Behavior.HINT,
	CANDY: TileProperties.Behavior.POINTS_500,
	BURGER: TileProperties.Behavior.POINTS_100,
	COLA: TileProperties.Behavior.POINTS_200,
	CAKE: TileProperties.Behavior.POINTS_1000,
	STUFFED_NINJA: TileProperties.Behavior.POINTS_5000,
	ANKH: Keen3Behavior.ANKH,
	SINGLE_CHARGE: Keen3Behavior.SINGLE_CHARGE,
	RAYGUN: TileProperties.Behavior.RAYGUN,
	YELLOW_CARD: TileProperties.Behavior.KEYCARD_YELLOW,
	RED_CARD: TileProperties.Behavior.KEYCARD_RED,
	GREEN_CARD: TileProperties.Behavior.KEYCARD_GREEN,
	BLUE_CARD: TileProperties.Behavior.KEYCARD_BLUE,
	OTHER_CANDY: TileProperties.Behavior.POINTS_500,
	YELLOW_DOOR: TileProperties.Behavior.DOOR_YELLOW,
	YELLOW_DOOR + 1: TileProperties.Behavior.DOOR_YELLOW,
	RED_DOOR: TileProperties.Behavior.DOOR_RED,
	RED_DOOR + 1: TileProperties.Behavior.DOOR_RED,
	EXIT: TileProperties.Behavior.EXIT,
}


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
	data.append_array(_records(SHIP_PROMPT_RECORDS))
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


## The tile properties of the hand-made levels: walls are solid on every
## side; doors are solid by their behaviour, as in the real table.
static func level_properties() -> TileProperties:
	var planes: Array[PackedInt32Array] = []
	for plane in TileProperties.PLANE_COUNT:
		var values := PackedInt32Array()
		values.resize(LEVEL_TILE_COUNT)
		values.fill(1 if plane == TileProperties.Field.ANIMATION else 0)
		planes.append(values)
	for side in range(TileProperties.Field.TOP, TileProperties.PLANE_COUNT):
		planes[side][WALL] = 1
	for tile in LEVEL_BEHAVIORS:
		planes[TileProperties.Field.BEHAVIOR][tile] = LEVEL_BEHAVIORS[tile]
	var table := PackedByteArray()
	for plane in planes:
		for value in plane:
			var bytes := PackedByteArray([0, 0])
			bytes.encode_s16(0, value)
			table.append_array(bytes)
	return TileProperties.from_table(table, LEVEL_TILE_COUNT)


## A level from rows of [constant LEVEL_LEGEND] characters, surrounded by a
## border of [constant LevelData.BORDER_CELLS] cells of the border tile, as
## in Keen 3's levels. [param infos] puts values into the info layer, at
## cells counted without the border.
static func create_level(
	rows: PackedStringArray, infos: Dictionary[Vector2i, int] = {}
) -> LevelData:
	var border := LevelData.BORDER_CELLS
	var level := LevelData.new()
	level.width = rows[0].length() + border * 2
	level.height = rows.size() + border * 2
	level.tiles.resize(level.width * level.height)
	level.tiles.fill(BORDER)
	level.infos.resize(level.width * level.height)
	for y in rows.size():
		for x in rows[y].length():
			level.tiles[(y + border) * level.width + x + border] = LEVEL_LEGEND[rows[y][x]]
	for cell in infos:
		level.infos[(cell.y + border) * level.width + cell.x + border] = infos[cell]
	return level


## A Keen 3 session in [param rows] with Keen's sprite at the top left of
## [param keen_cell] (counted without the border), before its first tick.
static func start_session(
	rows: PackedStringArray, keen_cell: Vector2i, inventory: Inventory = null
) -> Keen3LevelSession:
	return Keen3LevelSession.started(
		create_level(rows),
		level_properties(),
		inventory if inventory != null else Keen3Inventory.new(),
		cell_top_left(keen_cell)
	)


## The top left of [param cell] (counted without the border), in level
## pixels.
static func cell_top_left(cell: Vector2i) -> Vector2:
	var border := Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)
	return Vector2((cell + border) * EgaGraphics.TILE_SIZE)
