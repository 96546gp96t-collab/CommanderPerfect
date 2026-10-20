extends RefCounted
## Hand-made Galaxy data for the tests, so that every reader runs without
## the game's files: two Huffman dictionaries and an encoder for them,
## Carmack and RLEW planes, an EGAGRAPH with every kind of chunk (tables,
## a font, pictures, a masked picture, sprites, 8×8 tiles, 16×16 tiles with
## empty ones around the border between the two sets, misc, a text, a
## demo), a GAMEMAPS with two maps and an empty slot, tile information, an
## AUDIO with a block of bogus offsets like Keen 4 v1.0's digitised sounds,
## and a program image that holds all six headers, the sign-on text, the
## table of random numbers and texts, at other places than in Keen 4 v1.0
## or v1.4. None of it comes from the game.

const EXTENSION := "CKF"
const EXECUTABLE := "GAME.EXE"
const VERSION := "9.9"
const SIGN_ON_COLOR := 0x1F
const FILLER: PackedByteArray = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]
const PARAGRAPH := 16
## The tag of the hand-made maps (not Keen 4's 0xABCD).
const MAP_TAG := 0xFEED
const MAP_SLOTS := GalaxyHeaderSearch.MAP_SLOTS
## Counts no table gives, for the hand-made episode.
const FONT_COUNT := 1
const MISC_COUNT := 1
const TEXT_COUNT := 1
const DEMO_COUNT := 1
## 18 background tiles (the last two empty) and 4 foreground tiles (the
## first empty): the border lies in a run of three empty chunks.
const BACK_TILES := 18
const EMPTY_BACK_TILES: PackedInt32Array = [16, 17]
const FORE_TILES := 4
const EMPTY_FORE_TILES: PackedInt32Array = [0]
const TILE8_COUNT := 3
const MASKED_TILE8_COUNT := 2
## Picture sizes: width in bytes, height.
const PICTURE_SIZES: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 1)]
const MASKED_PICTURE_SIZES: Array[Vector2i] = [Vector2i(1, 1)]
## Sprite entries: width in bytes, height, origin x, y, box l, t, r, b, shifts.
const SPRITES: Array[Array] = [
	[1, 2, 0, 16, 16, 16, 96, 48, 4],
	[2, 1, -32, 0, 0, 0, 255, 15, 1],
]
const FONT_HEIGHT := 2
const FONT_CHARACTER := 65
const FONT_WIDTH := 3
const FONT_ROWS: PackedByteArray = [0b1010_0000, 0b0100_0000]
const MISC_BYTES := "MISC"
const TEXT_BYTES := "^P\r\nHello^E"
const DEMO_MAP := 2
const LEVEL_NAMES: PackedStringArray = ["Alpha Land", "Beta\nTown"]
const ENTRY_TEXTS: PackedStringArray = ["Keen walks into\nAlpha Land", "Keen runs to Beta\nTown"]
const MESSAGES := "council"
const MESSAGE_SHAPE: PackedInt32Array = [2, 1, 3]
const MESSAGE_TEXTS: PackedStringArray = ["One\nTwo", "Three\n", "Four\nFive\nSix"]
## A run with the wrong shape before the real one.
const DECOY_MESSAGES: PackedStringArray = ["Uno\nDos", "Tres\nQuatro", "Cinco"]
## The maps: slot -> [name, width, height]; slot 1 stays empty.
const MAPS: Dictionary[int, Array] = {0: ["Fixture A", 3, 2], 2: ["Fixture B", 2, 2]}
## Audio: four sounds, two bogus entries, one song.
const SOUNDS: PackedStringArray = ["PC-ONE", "PC-TWO-LONGER", "ADLIB-ONE", "ADLIB-TWO"]
const SONG := "SONG-DATA-0123456789"
const BOGUS_ENTRIES := 2
## A known place that holds nothing: the searches must not use it.
const WRONG_PLACE := 3
const WEIGHT_SPREAD := 13


## A complete Huffman tree built from weights: the more [param zero_weight],
## the shorter the code of byte 0; [param step] mixes up the weights of the
## other bytes, so two trees differ. Each merge makes the next node, so the
## last (254) is the root, as in the real dictionaries.
static func dictionary(zero_weight := 1000, step := 1) -> PackedByteArray:
	var items: Array[Vector2i] = []
	for byte in GalaxyHuffman.BYTE_VALUES:
		var weight := zero_weight if byte == 0 else 1 + (byte * step) % WEIGHT_SPREAD
		items.append(Vector2i(weight, byte))
	var data := PackedByteArray()
	data.resize(GalaxyHuffman.STORED_SIZE)
	for node in GalaxyHuffman.NODE_COUNT:
		items.sort()
		var first: Vector2i = items.pop_front()
		var second: Vector2i = items.pop_front()
		data.encode_u16(node * 4, first.y)
		data.encode_u16(node * 4 + 2, second.y)
		items.append(Vector2i(first.x + second.x, GalaxyHuffman.BYTE_VALUES + node))
	return data


## [param data] packed with [param tree] (as from [method dictionary]):
## the bits of each code from the root down, lowest bit of a byte first.
static func compress(tree: PackedByteArray, data: PackedByteArray) -> PackedByteArray:
	var links: Dictionary[int, Vector2i] = {}
	for node in GalaxyHuffman.NODE_COUNT:
		for bit in 2:
			links[tree.decode_u16(node * 4 + bit * 2)] = Vector2i(node, bit)
	var out := PackedByteArray()
	var written := 0
	for byte in data:
		var bits: Array[int] = []
		var value := byte
		while true:
			var link: Vector2i = links[value]
			bits.push_front(link.y)
			if link.x == GalaxyHuffman.ROOT:
				break
			value = GalaxyHuffman.BYTE_VALUES + link.x
		for bit in bits:
			if written % 8 == 0:
				out.append(0)
			if bit:
				out[-1] |= 1 << (written % 8)
			written += 1
	return out


## A chunk: the expanded length (unless [param with_length] is false), then
## [param data] packed with [param tree].
static func chunk(
	tree: PackedByteArray, data: PackedByteArray, with_length := true
) -> PackedByteArray:
	var bytes := PackedByteArray()
	if with_length:
		bytes.resize(4)
		bytes.encode_u32(0, data.size())
	bytes.append_array(compress(tree, data))
	return bytes


## [param words] as Carmack data with only plain words: a word whose high
## byte is a copy marker is written as the marker with count 0 and its low
## byte after it.
static func carmack(words: PackedInt32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	_append_u16(bytes, words.size() * 2)
	for word in words:
		var marker := word >> 8
		if marker == GalaxyCarmack.NEAR or marker == GalaxyCarmack.FAR:
			_append_u16(bytes, marker << 8)
			bytes.append(word & 0xFF)
		else:
			_append_u16(bytes, word)
	return bytes


## [param plane] as RLEW words: its length in bytes, then runs of four or
## more equal words (and every word equal to [param tag]) as repeats.
static func rlew(plane: PackedInt32Array, tag: int) -> PackedInt32Array:
	var words := PackedInt32Array([plane.size() * 2])
	var index := 0
	while index < plane.size():
		var run := 1
		while index + run < plane.size() and plane[index + run] == plane[index]:
			run += 1
		if run >= 4 or plane[index] == tag:
			words.append_array([tag, run, plane[index]])
			index += run
		else:
			words.append(plane[index])
			index += 1
	return words


## The 16-bit words of [param words] as bytes.
static func word_bytes(words: PackedInt32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	for word in words:
		_append_u16(bytes, word)
	return bytes


## The planes of fixture map [param slot]: background, foreground, info.
## The foreground has a run (RLEW) and the info plane a word with a
## Carmack marker as its high byte.
static func map_planes(slot: int) -> Array[PackedInt32Array]:
	var size: int = MAPS[slot][1] * MAPS[slot][2]
	var back := PackedInt32Array()
	var fore := PackedInt32Array()
	var info := PackedInt32Array()
	for cell in size:
		back.append(cell + 1 + slot)
		fore.append(0 if cell < size - 1 else 3)
		info.append(0)
	info[0] = 0xA712
	info[size - 1] = 0xA8 << 8 | slot
	return [back, fore, info]


## GAMEMAPS: "TED5v1.0", then per map its planes and its header. Returns
## [the file, the 100 header offsets].
static func gamemaps() -> Array:
	var data := "TED5v1.0".to_ascii_buffer()
	var offsets := PackedInt32Array()
	offsets.resize(MAP_SLOTS)
	for slot in MAPS:
		var starts := PackedInt32Array()
		var lengths := PackedInt32Array()
		for plane in map_planes(slot):
			var bytes := carmack(rlew(plane, MAP_TAG))
			starts.append(data.size())
			lengths.append(bytes.size())
			data.append_array(bytes)
		offsets[slot] = data.size()
		var header := PackedByteArray()
		header.resize(GalaxyMapFile.NAME_START + GalaxyMapFile.NAME_SIZE)
		for plane in 3:
			header.encode_u32(plane * 4, starts[plane])
			header.encode_u16(GalaxyMapFile.PLANE_LENGTHS_START + plane * 2, lengths[plane])
		header.encode_u16(GalaxyMapFile.SIZE_START, MAPS[slot][1])
		header.encode_u16(GalaxyMapFile.SIZE_START + 2, MAPS[slot][2])
		var name: PackedByteArray = String(MAPS[slot][0]).to_ascii_buffer()
		for index in name.size():
			header[GalaxyMapFile.NAME_START + index] = name[index]
		data.append_array(header)
		data.append_array(GalaxyHeaderSearch.MAP_SIGNATURE.to_ascii_buffer())
	return [data, offsets]


## The tile information: the background tables, then the seven foreground
## tables. Background tile 1 animates to 2 and back after 8 tics;
## foreground tile 2 is a kind-5 tile drawn in front, tile 1 a slope top.
static func tile_info() -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(2 * BACK_TILES + 7 * FORE_TILES)
	data[GalaxyTileInfo.Back.ANIMATION_TIME * BACK_TILES + 1] = 8
	data[GalaxyTileInfo.Back.ANIMATION_OFFSET * BACK_TILES + 1] = 1
	data[GalaxyTileInfo.Back.ANIMATION_OFFSET * BACK_TILES + 2] = 0xFF
	var fore_start := 2 * BACK_TILES
	data[fore_start + GalaxyTileInfo.Fore.TOP * FORE_TILES + 1] = 3
	data[fore_start + GalaxyTileInfo.Fore.LEFT * FORE_TILES + 1] = 1
	data[fore_start + GalaxyTileInfo.Fore.MISC * FORE_TILES + 2] = 0x80 | 5
	data[fore_start + GalaxyTileInfo.Fore.ANIMATION_TIME * FORE_TILES + 3] = 10
	return data


## The hand-made episode, with places for every piece that hold nothing.
static func episode() -> GalaxyEpisode:
	var result := GalaxyEpisode.new()
	result.extension = EXTENSION
	result.executables = PackedStringArray([EXECUTABLE])
	for piece in GalaxyEpisode.Header.values():
		result.known_offsets[piece] = PackedInt32Array([WRONG_PLACE])
	result.font_count = FONT_COUNT
	result.misc_count = MISC_COUNT
	result.text_count = TEXT_COUNT
	result.demo_count = DEMO_COUNT
	result.level_name_count = LEVEL_NAMES.size()
	result.known_level_name_offsets = PackedInt32Array([WRONG_PLACE])
	result.message_shapes = {MESSAGES: MESSAGE_SHAPE}
	result.known_message_offsets = {MESSAGES: PackedInt32Array([WRONG_PLACE])}
	return result


static func _append_u16(bytes: PackedByteArray, value: int) -> void:
	bytes.append(value & 0xFF)
	bytes.append((value >> 8) & 0xFF)


## Repeats [constant FILLER] to [param length] bytes: never zero, never
## printable, so it is neither a text nor an offset.
static func filler(length: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	for index in length:
		bytes.append(FILLER[index % FILLER.size()])
	return bytes
