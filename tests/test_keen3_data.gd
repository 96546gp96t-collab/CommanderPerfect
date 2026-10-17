extends "res://tests/test_case.gd"
## Checks the decoders against the player's real Keen 3 files. Skipped when
## they are not available: Keen 3 is not shareware, so this only runs where
## the player put their own files in game_data/keen3 (they are never part of
## the repository). The numbers come from docs/keen3/research.md (version
## 1.00); no text of the game is written here.

const TILE_COUNT := 624
const SPRITE_COUNT := 148
const BITMAP_COUNT := 14
const NAMED_SOUND_COUNT := 45
## SoundFile's name for the empty slots of the table.
const UNNAMED_SOUND := "__UNNAMED__"
const NEW_SOUNDS: PackedStringArray = ["ANKH", "MEEP", "MORTIMER", "FOOTSLAM"]
const TEXT_WIDTH := 40
## Where the four texts start in version 1.00, in Keen 3's order.
const TEXT_STARTS: PackedInt32Array = [0x17B00, 0x182D0, 0x18610, 0x18D00]
const SPRITE_NAMES: Dictionary[int, String] = {
	0: "KEENWALKR1",
	28: "KEENSICLE1",
	30: "KEENMELT",
	47: "YOUTHLEFT1",
	61: "GODHALO",
	63: "GRUNTLEFT1",
	77: "NINJAL1",
	85: "WOMANL1",
	93: "FOOBL1",
	102: "KEENSHOT",
	107: "PLATFORM1",
	118: "MEEPR1",
	130: "MESSIELD1",
	146: "HEART1",
}
## Collision boxes (left, top, right, bottom) from research.md §3.
const SPRITE_BOXES: Dictionary[int, Array] = {
	47: [1, 6, 14, 23],
	63: [2, 1, 21, 31],
	77: [4, 4, 27, 31],
	85: [2, 2, 21, 31],
	118: [2, 2, 13, 23],
}
const EXIT_TILE := 255
## The first item row and the behaviours of its items (research.md §4).
const ITEM_ROW_START := 143
const ANKH_COLUMN := 6
const SINGLE_CHARGE_COLUMN := 7
## The world map (research.md §8).
const WORLD_MAP_SIZE := Vector2i(70, 73)
const MAP_START := Vector2i(44, 47)
const TELEPORTER_MARK := 0x0F00
const TELEPORTER_COUNT := 16
const TELEPORTER_TILE := 134
## Slot → destination slot of two teleporters.
const TELEPORTER_LINKS: Dictionary[int, int] = {0: 2, 12: 0}
const MESSIE_PATH := 0x2000
const MESSIE_WEED := 0x2100
const MESSIE_LANDING := 0x2200
const MESSIE_CELLS: Dictionary[int, int] = {MESSIE_PATH: 252, MESSIE_WEED: 4, MESSIE_LANDING: 6}
const SHIP_INFO := 20
const SHIP_CELLS := 2
const BLOCKED_MARK := 0x8000
const HIGH_BYTE := 0xFF00
const NIBBLE := 0xF

var _files: GameFiles
var _executable: Keen3Executable


func run_all() -> void:
	_files = Keen3Files.locate()
	if _files == null:
		skip("no Keen 3 game data found")
		return
	_executable = Keen3Executable.load_from(_files)
	super.run_all()


func test_graphics_have_expected_counts() -> void:
	var graphics := EgaGraphics.load_from(_files, Keen3Files.EXTENSION)
	assert_true(graphics != null, "graphics should load")
	if graphics == null:
		return
	assert_equal(graphics.tiles.size(), TILE_COUNT, "tile count")
	assert_equal(graphics.sprites.size(), SPRITE_COUNT, "sprite count")
	assert_equal(graphics.bitmaps.size(), BITMAP_COUNT, "bitmap count")


func test_every_map_loads() -> void:
	for number in Keen3Files.expected_level_numbers():
		var file_name := _files.level_file(number)
		assert_true(_files.has_file(file_name), "%s is there" % file_name)
		assert_true(LevelData.parse(_files.read(file_name)) != null, "%s loads" % file_name)


func test_finale_loads() -> void:
	assert_true(FinaleImage.load_from(_files, Keen3Files.FINALE) != null, "FINALE.CK3")


func test_executable_is_version_1_00() -> void:
	assert_true(_executable != null, "KEEN3.EXE unpacks")
	if _executable != null:
		assert_equal(_executable.image.size(), 127086, "the image size")
		assert_equal(_executable.version, "1.00", "the player's version")


func test_tile_table_has_a_stride_of_715() -> void:
	if _executable == null:
		return
	var properties := _executable.tile_properties(TILE_COUNT)
	assert_true(properties != null, "the tile table")
	if properties == null:
		return
	assert_true(properties.is_exit(EXIT_TILE), "the exit")
	var ankh := ITEM_ROW_START + ANKH_COLUMN
	assert_equal(properties.behavior(ankh), Keen3Behavior.ANKH, "the ankh")
	var charge := ITEM_ROW_START + SINGLE_CHARGE_COLUMN
	assert_equal(properties.behavior(charge), Keen3Behavior.SINGLE_CHARGE, "a single charge")
	var scanned := TileProperties.find_in_image(
		_executable.image, TILE_COUNT, PackedInt32Array(), Keen3Executable.TILE_TABLE_STRIDE
	)
	assert_true(scanned != null and scanned.is_exit(EXIT_TILE), "the search finds it too")
	var plain := TileProperties.find_in_image(
		_executable.image, TILE_COUNT, Keen3Executable.TILE_TABLE_OFFSETS
	)
	assert_true(plain == null or not plain.is_exit(EXIT_TILE), "624/624 reads a wrong table")


func test_sounds_include_keen_3s_own() -> void:
	if _executable == null:
		return
	var sounds := _executable.sounds()
	assert_true(sounds != null, "the sound block parses")
	if sounds == null:
		return
	for name in NEW_SOUNDS:
		assert_true(sounds.sounds.has(name), "%s is there" % name)
	var named := sounds.sounds.keys().filter(
		func(name: String) -> bool: return name != UNNAMED_SOUND
	)
	assert_equal(named.size(), NAMED_SOUND_COUNT, "45 named sounds")
	var start := Keen3Executable.find_sound_block(_executable.image)
	var size_word := _executable.image.decode_u16(start + Keen2Executable.SOUND_SIZE_OFFSET)
	assert_true(_executable.sound_data().size() < size_word, "the block is smaller than its word")


func test_texts_start_where_research_says() -> void:
	if _executable == null:
		return
	for block in Keen3Executable.TextBlock.size():
		var start := Keen3Executable.find_text_block(_executable.image, block)
		var name: String = Keen3Executable.TextBlock.keys()[block]
		assert_equal(start, TEXT_STARTS[block], "%s starts at its place" % name)
		var text := _executable.text(block as Keen3Executable.TextBlock)
		assert_true(TextDocument.layout(text, TEXT_WIDTH).size() > 1, "%s has lines" % name)
	var keen_2_first := Keen2Executable.text_blocks(_executable.image)[0]
	assert_equal(keen_2_first, TEXT_STARTS[0] - 2, "Keen 2's search starts two bytes early")


func test_messages_are_found_at_their_places() -> void:
	if _executable == null:
		return
	var image := _executable.image
	var status := Keen3Executable.find_status_box(image)
	assert_equal(status, Keen3Executable.STATUS_BOX_OFFSET, "the status box")
	assert_equal(_executable.status_box_lines().size(), 11, "eleven lines")
	assert_equal(Keen3Executable.find_points_table(image), 0x1C1A9, "the points table")
	assert_equal(Keen3Executable.find_mortimer_messages(image), 0x1C1B3, "Mortimer's boxes")
	assert_equal(_sizes(_executable.mortimer_messages()), [1, 1, 1, 5, 5, 2, 4, 1, 3], "boxes")
	assert_equal(_sizes(_executable.ending_pages()), [4, 3, 3, 1], "the ending's pages")
	assert_equal(_executable.the_end().size(), 2, "two lines over the finale")
	assert_equal(Keen3Executable.find_ship_messages(image), 0x1CF00, "the ship's messages")
	assert_equal(_sizes(_executable.ship_messages()), [4, 3, 4, 4], "four messages")
	assert_true(_executable.score_texts() != null, "the high score texts")


func test_messages_are_found_by_their_content() -> void:
	if _executable == null:
		return
	# Shifted by a few bytes, no known place holds them any more.
	var shift := 4
	var image := PackedByteArray([1, 1, 1, 1])
	image.append_array(_executable.image)
	var status := Keen3Executable.STATUS_BOX_OFFSET + shift
	assert_equal(Keen3Executable.find_status_box(image), status, "the status box")
	var ship := Keen3Executable.SHIP_MESSAGES_OFFSET + shift
	assert_equal(Keen3Executable.find_ship_messages(image), ship, "the ship's messages")
	for block in Keen3Executable.TextBlock.size():
		var start := Keen3Executable.find_text_block(image, block)
		assert_equal(start, TEXT_STARTS[block] + shift, "text %d" % block)


func test_sprite_names_fit_the_enemies() -> void:
	var header := EgaHeader.parse(_files.read(Keen3Files.HEADER))
	assert_true(header != null, Keen3Files.HEADER)
	if header == null:
		return
	for sprite in SPRITE_NAMES:
		assert_equal(header.sprites[sprite].name, SPRITE_NAMES[sprite], "sprite %d" % sprite)
	for sprite in SPRITE_BOXES:
		var box: Array = SPRITE_BOXES[sprite]
		var expected := Rect2i(box[0], box[1], box[2] - box[0], box[3] - box[1])
		assert_equal(header.sprites[sprite].hitbox, expected, "box of sprite %d" % sprite)


func test_world_map_info_values() -> void:
	var map := LevelData.parse(_files.read(_files.level_file(Keen3Files.WORLD_MAP_LEVEL)))
	assert_true(map != null, "map 80 loads")
	if map == null:
		return
	assert_equal(Vector2i(map.width, map.height), WORLD_MAP_SIZE, "its size")
	assert_equal(map.find_info(LevelData.PLAYER_START_INFO), MAP_START, "Keen's start")
	var levels := {}
	var teleporters: Dictionary[int, int] = {}
	var messie: Dictionary[int, int] = {}
	var ship := 0
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			var info := map.info_at(cell)
			if info & HIGH_BYTE == TELEPORTER_MARK:
				teleporters[(info >> 4) & NIBBLE] = info & NIBBLE
				assert_equal(map.tile_at(cell), TELEPORTER_TILE, "teleporter tile at %s" % cell)
			elif info & HIGH_BYTE in MESSIE_CELLS:
				messie[info & HIGH_BYTE] = messie.get(info & HIGH_BYTE, 0) + 1
			elif info == SHIP_INFO:
				ship += 1
			elif info & ~BLOCKED_MARK >= 1 and info & ~BLOCKED_MARK <= Keen3Files.LAST_LEVEL:
				levels[info & ~BLOCKED_MARK] = true
	assert_equal(levels.size(), Keen3Files.LAST_LEVEL, "an entrance for every level")
	assert_equal(teleporters.size(), TELEPORTER_COUNT, "sixteen teleporter slots")
	for slot in TELEPORTER_LINKS:
		assert_equal(teleporters.get(slot, -1), TELEPORTER_LINKS[slot], "slot %d" % slot)
	assert_equal(messie, MESSIE_CELLS, "Messie's path, weed and landings")
	assert_equal(ship, SHIP_CELLS, "the ship")


## The number of lines of each message.
func _sizes(messages: Array[PackedStringArray]) -> Array:
	return messages.map(func(lines: PackedStringArray) -> int: return lines.size())
