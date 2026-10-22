extends RefCounted
## The hand-made Galaxy files for the tests, built from the pieces in
## tests/galaxy_fixtures.gd: EGAGRAPH, AUDIO, GAMEMAPS and a program whose
## image holds the six headers, the sign-on text, the random numbers and the
## texts, each after filler and never where Keen 4 v1.0 or v1.4 keeps them.
## [method write_folder] puts them in a folder, as a player's game folder.

const Fixtures := preload("res://tests/galaxy_fixtures.gd")

## The colour planes of picture 0 (8×2): row 0 has the colours 1, 2, 4 and
## 8 in its first four pixels, row 1 colour 1 in its last.
const PICTURE_PLANES: Array[Array] = [[0x80, 0x01], [0x40, 0x00], [0x20, 0x00], [0x10, 0x00]]
const BOGUS_OFFSET_SURPLUS := 5
const DOS_HEADER_PARAGRAPHS := 2
const GRAPHICS_TREE_WEIGHT := 1000
const AUDIO_TREE_WEIGHT := 20
const AUDIO_TREE_STEP := 5


## The expanded contents of every EGAGRAPH chunk, in order; an empty array
## is an empty chunk. Element 1 of each pair says whether the chunk starts
## with its length.
static func graphics_contents() -> Array[Array]:
	var chunks: Array[Array] = []
	chunks.append([_sizes(Fixtures.PICTURE_SIZES), true])
	chunks.append([_sizes(Fixtures.MASKED_PICTURE_SIZES), true])
	var sprite_table := PackedByteArray()
	for entry: Array in Fixtures.SPRITES:
		for value: int in entry:
			sprite_table.append(value & 0xFF)
			sprite_table.append((value >> 8) & 0xFF)
	chunks.append([sprite_table, true])
	chunks.append([_font(), true])
	chunks.append([_planes(PICTURE_PLANES), true])
	chunks.append([_planes([[0xFF, 0xFF], [0, 0], [0, 0], [0, 0]]), true])
	chunks.append([_planes([[0xF0], [0xFF], [0], [0xFF], [0]]), true])
	chunks.append([_planes([[0x0F, 0x00], [0xFF, 0xFF], [0, 0], [0, 0], [0xFF, 0xFF]]), true])
	chunks.append([_planes([[0, 0], [0, 0], [0xFF, 0xFF], [0, 0], [0, 0]]), true])
	var tiles8 := PackedByteArray()
	for tile in Fixtures.TILE8_COUNT:
		for plane in 4:
			tiles8.append_array(_repeat(0xFF if plane == tile % 4 else 0, 8))
	chunks.append([tiles8, false])
	var masked8 := _repeat(0, 8) + _repeat(0xFF, 8) + _repeat(0, 24)
	masked8.append_array(_repeat(0xFF, 40))
	chunks.append([masked8, false])
	for tile in Fixtures.BACK_TILES:
		var empty := tile in Fixtures.EMPTY_BACK_TILES
		chunks.append([PackedByteArray() if empty else _repeat(tile, 32) + _repeat(0, 96), false])
	for tile in Fixtures.FORE_TILES:
		var empty := tile in Fixtures.EMPTY_FORE_TILES
		var data := _repeat(0, 96) + _repeat(0xFF, 32) + _repeat(0, 32)
		chunks.append([PackedByteArray() if empty else data, false])
	chunks.append([Fixtures.MISC_BYTES.to_ascii_buffer(), true])
	chunks.append([Fixtures.TEXT_BYTES.to_ascii_buffer(), true])
	chunks.append([_planes([[Fixtures.DEMO_MAP, 0, 2, 0, 9, 9]]), true])
	return chunks


## EGAGRAPH and its offsets: [the file, the offsets with -1 for an empty
## chunk and the file size last].
static func graphics() -> Array:
	var tree := Fixtures.dictionary(GRAPHICS_TREE_WEIGHT)
	var data := PackedByteArray()
	var offsets := PackedInt32Array()
	for content in graphics_contents():
		var bytes: PackedByteArray = content[0]
		if bytes.is_empty():
			offsets.append(-1)
			continue
		offsets.append(data.size())
		data.append_array(Fixtures.chunk(tree, bytes, content[1]))
	offsets.append(data.size())
	return [data, offsets]


## AUDIO and its offsets: four sounds, then a block of entries larger than
## the one after them (the absent digitised sounds), then a song.
static func audio() -> Array:
	var tree := Fixtures.dictionary(AUDIO_TREE_WEIGHT, AUDIO_TREE_STEP)
	var data := PackedByteArray()
	var offsets := PackedInt32Array()
	for sound in Fixtures.SOUNDS:
		offsets.append(data.size())
		data.append_array(Fixtures.chunk(tree, sound.to_ascii_buffer()))
	var song_start := data.size()
	for index in Fixtures.BOGUS_ENTRIES:
		offsets.append(song_start + BOGUS_OFFSET_SURPLUS)
	offsets.append(song_start)
	data.append_array(Fixtures.chunk(tree, Fixtures.SONG.to_ascii_buffer()))
	offsets.append(data.size())
	return [data, offsets]


## The program image with every piece. Returns [the image, a dictionary
## from piece name to where it starts].
static func program_image() -> Array:
	var image := Fixtures.filler(37)
	var at: Dictionary[String, int] = {}
	at["sign_on"] = image.size()
	for character in "Copyright (v%s) " % Fixtures.VERSION:
		image.append_array([character.unicode_at(0), Fixtures.SIGN_ON_COLOR])
	image.append_array(Fixtures.filler(11))
	at["random"] = image.size()
	image.append_array(GalaxyExecutable.RANDOM_TABLE_START)
	image.append_array(Fixtures.filler(GalaxyExecutable.RANDOM_TABLE_SIZE - 7))
	# A list whose entry texts do not end with the names: not the one.
	var decoy := PackedStringArray(Fixtures.LEVEL_NAMES)
	decoy.append_array(["Keen leaves", "Keen goes"])
	_append_records(image, decoy, true)
	image.append_array(Fixtures.filler(9))
	var level_texts := PackedStringArray(Fixtures.LEVEL_NAMES)
	level_texts.append_array(Fixtures.ENTRY_TEXTS)
	at["level_names"] = _append_records(image, level_texts, true)
	image.append_array(Fixtures.filler(13))
	_append_records(image, Fixtures.DECOY_MESSAGES, false)
	image.append_array(Fixtures.filler(5))
	at["messages"] = _append_records(image, Fixtures.MESSAGE_TEXTS, false)
	image.append_array(Fixtures.filler(17))
	at["AUDIOHED"] = image.size()
	image.append_array(_offset_bytes(audio()[1], 4))
	image.append_array(PackedByteArray([0, 0, 0, 0]))
	at["EGAHEAD"] = image.size()
	image.append_array(_offset_bytes(graphics()[1], 3))
	image.append_array(Fixtures.filler(23))
	at["MAPHEAD"] = image.size()
	image.append_array(map_head())
	at["TILEINFO"] = image.size()
	image.append_array(Fixtures.tile_info())
	image.append_array(Fixtures.filler(31))
	at["AUDIODCT"] = image.size()
	image.append_array(Fixtures.dictionary(AUDIO_TREE_WEIGHT, AUDIO_TREE_STEP))
	at["EGADICT"] = image.size()
	image.append_array(Fixtures.dictionary(GRAPHICS_TREE_WEIGHT))
	image.append_array(Fixtures.filler(19))
	return [image, at]


## MAPHEAD: the tag, then the offset of every map slot.
static func map_head() -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(GalaxyHeaderSearch.MAP_HEAD_SIZE)
	bytes.encode_u16(0, Fixtures.MAP_TAG)
	var offsets: PackedInt32Array = Fixtures.gamemaps()[1]
	for slot in offsets.size():
		bytes.encode_u32(GalaxyHeaderSearch.TAG_SIZE + slot * 4, offsets[slot])
	return bytes


## [param image] as an uncompressed DOS program: a small MZ header first.
static func executable(image: PackedByteArray) -> PackedByteArray:
	var exe := PackedByteArray()
	exe.resize(DOS_HEADER_PARAGRAPHS * DosExecutable.PARAGRAPH_SIZE)
	exe.encode_u16(0, DosExecutable.MZ_SIGNATURE)
	exe.encode_u16(DosExecutable.HEADER_PARAGRAPHS_OFFSET, DOS_HEADER_PARAGRAPHS)
	exe.append_array(image)
	return exe


## Writes the program (with [param image], or the full one) and the three
## data files to [param path]; with [param header_files] also the five
## header files a mod would have.
static func write_folder(path: String, image := PackedByteArray(), header_files := false) -> void:
	DirAccess.make_dir_recursive_absolute(path)
	var program := image if not image.is_empty() else PackedByteArray(program_image()[0])
	_write(path, Fixtures.EXECUTABLE, executable(program))
	_write(path, "EGAGRAPH." + Fixtures.EXTENSION, graphics()[0])
	_write(path, "AUDIO." + Fixtures.EXTENSION, audio()[0])
	_write(path, "GAMEMAPS." + Fixtures.EXTENSION, Fixtures.gamemaps()[0])
	if not header_files:
		return
	_write(path, "EGAHEAD." + Fixtures.EXTENSION, _offset_bytes(graphics()[1], 3))
	_write(path, "AUDIOHED." + Fixtures.EXTENSION, _offset_bytes(audio()[1], 4))
	_write(path, "MAPHEAD." + Fixtures.EXTENSION, map_head() + Fixtures.tile_info())
	_write(path, "EGADICT." + Fixtures.EXTENSION, Fixtures.dictionary(GRAPHICS_TREE_WEIGHT))
	_write(
		path,
		"AUDIODCT." + Fixtures.EXTENSION,
		Fixtures.dictionary(AUDIO_TREE_WEIGHT, AUDIO_TREE_STEP)
	)


## Appends [param records] as zero-terminated texts; with [param aligned]
## each starts on a 16-byte boundary (zeros in between). Returns where the
## first starts.
static func _append_records(
	image: PackedByteArray, records: PackedStringArray, aligned: bool
) -> int:
	if aligned:
		image.append_array(PackedByteArray([0]))
		while image.size() % Fixtures.PARAGRAPH != 0:
			image.append(0)
	var first := image.size()
	for record in records:
		image.append_array(record.to_ascii_buffer())
		image.append(0)
		while aligned and image.size() % Fixtures.PARAGRAPH != 0:
			image.append(0)
	return first


static func _offset_bytes(offsets: PackedInt32Array, entry_size: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	for offset in offsets:
		var value := offset if offset >= 0 else GalaxyHeaderSearch.EMPTY_3
		for index in entry_size:
			bytes.append((value >> (index * 8)) & 0xFF)
	return bytes


static func _sizes(sizes: Array[Vector2i]) -> PackedByteArray:
	var bytes := PackedByteArray()
	for size in sizes:
		for value in [size.x, 0, size.y, 0]:
			bytes.append(value)
	return bytes


static func _font() -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(GalaxyFont.HEADER_SIZE)
	data.encode_u16(0, Fixtures.FONT_HEIGHT)
	data.encode_u16(2 + Fixtures.FONT_CHARACTER * 2, GalaxyFont.HEADER_SIZE)
	data[GalaxyFont.WIDTHS_START + Fixtures.FONT_CHARACTER] = Fixtures.FONT_WIDTH
	data.append_array(Fixtures.FONT_ROWS)
	return data


static func _planes(planes: Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	for plane: Array in planes:
		for value: int in plane:
			bytes.append(value)
	return bytes


static func _repeat(value: int, count: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(count)
	bytes.fill(value)
	return bytes


static func _write(folder: String, name: String, data: PackedByteArray) -> void:
	var file := FileAccess.open(folder.path_join(name), FileAccess.WRITE)
	file.store_buffer(data)
	file.close()
