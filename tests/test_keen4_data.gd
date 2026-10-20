extends "res://tests/test_case.gd"
## Checks the Galaxy readers against the player's real Keen 4 files.
## Skipped when they are not available: they are never part of the
## repository. The numbers come from docs/keen4/research.md (v1.0, the
## user's, and what holds for v1.4 too); no text of the game is written
## here: names are compared with each other and with GAMEMAPS.

const SPRITE_COUNT := 397
const BACK_TILE_COUNT := 1296
const FORE_TILE_COUNT := 2916
const TILE8_COUNT := 104
const MASKED_TILE8_COUNT := 20
const MAP_COUNT := 20
const PICTURE_COUNTS: Dictionary[String, int] = {"1.0": 107, "1.4": 115}
## Where v1.0 keeps its headers (research.md §1).
const HEADERS_V1_0: Dictionary[GalaxyEpisode.Header, int] = {
	GalaxyEpisode.Header.AUDIOHED: 0x1FB80,
	GalaxyEpisode.Header.EGAHEAD: 0x1FE10,
	GalaxyEpisode.Header.MAPHEAD: 0x235B0,
	GalaxyEpisode.Header.TILEINFO: 0x23742,
	GalaxyEpisode.Header.AUDIODCT: 0x33FF6,
	GalaxyEpisode.Header.EGADICT: 0x343F6,
}
const CHUNK_COUNT_V1_0 := 4743
## Map 0, the world map (research.md §6, §8): Keen on the map, Miragia,
## the entrances to levels 1-18, the fences of levels 1 and 2 and the flags.
const MAP_KEEN := 3
const MIRAGIA := 33
const ENTRANCE := 0xC000
const FENCE := 0xD000
const FLAG := 0xF000
const ENTRANCES := 18
const FENCES := 2
const FLAGS := 17
const WORLD_MAP_SIZE := Vector2i(61, 66)
## Tile information counts in v1.0 (research.md §1).
const ANIMATED_BACK_TILES := 79
const ANIMATED_FORE_TILES := 247
const IN_FRONT_TILES := 535
const DEMO_MAPS: PackedInt32Array = [1, 9, 11, 15, 19]
## Sprite 10's hit box (research.md §1).
const SPRITE_10_BOX: Array[int] = [64, 48, 304, 496]
const AUDIO_CHUNKS := 162
const DIGITISED_SOUNDS := Vector2i(104, 156)
const SONGS := Vector2i(156, 162)
const COUNCIL_MESSAGES := 17
const JANITOR_MESSAGES := 4

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_data = Keen4Episode.load_data(files)


func test_version_and_headers() -> void:
	if _data == null:
		return
	var version := _data.executable.version
	assert_true(PICTURE_COUNTS.has(version), "a known version (%s)" % version)
	if version == "1.0":
		for piece in HEADERS_V1_0:
			assert_equal(_data.headers.found_at[piece], HEADERS_V1_0[piece], "where 1.0 keeps it")
		assert_equal(_data.graphics.file.chunk_count(), CHUNK_COUNT_V1_0, "chunks in 1.0")
	assert_equal(_data.headers.map_tag, 0xABCD, "the RLEW tag")


func test_headers_found_without_the_known_places() -> void:
	if _data == null:
		return
	var episode := Keen4Episode.create()
	episode.known_offsets = {}
	var files := Keen4Files.locate()
	var searched := GalaxyHeaders.find(_data.executable.image, files, episode)
	assert_true(searched != null, "found by content alone")
	if searched != null:
		assert_equal(searched.found_at, _data.headers.found_at, "at the same places")


func test_counts() -> void:
	if _data == null:
		return
	var ranges := _data.graphics.ranges
	assert_equal(ranges.picture_count, PICTURE_COUNTS.get(_data.executable.version, -1), "pictures")
	assert_equal(ranges.masked_picture_count, 3, "masked pictures")
	assert_equal(ranges.sprite_count, SPRITE_COUNT, "sprites")
	assert_equal(ranges.back_tile_count, BACK_TILE_COUNT, "background tiles")
	assert_equal(ranges.fore_tile_count, FORE_TILE_COUNT, "foreground tiles")
	assert_equal(ranges.tile8_count, TILE8_COUNT, "8×8 tiles")
	assert_equal(ranges.masked_tile8_count, MASKED_TILE8_COUNT, "masked 8×8 tiles")
	assert_equal(ranges.font_count, 3, "fonts")
	assert_equal(_data.maps.map_count(), MAP_COUNT, "maps")
	assert_equal(_data.tile_info.back_count, BACK_TILE_COUNT, "tile info for the background")


func test_every_map_decodes() -> void:
	if _data == null:
		return
	for number in MAP_COUNT:
		var map := _data.maps.load_map(number)
		assert_true(map != null, "map %d" % number)
		if map != null:
			for plane in map.planes:
				assert_equal(plane.size(), map.width * map.height, "plane of map %d" % number)


func test_world_map_info_values() -> void:
	if _data == null:
		return
	var map := _data.maps.load_map(0)
	assert_equal(Vector2i(map.width, map.height), WORLD_MAP_SIZE, "its size")
	var info := map.planes[GalaxyMap.Layer.INFO]
	assert_equal(info.count(MAP_KEEN), 1, "Keen once")
	assert_true(info.has(MIRAGIA), "Miragia")
	for level in range(1, ENTRANCES + 1):
		assert_true(info.has(ENTRANCE + level), "the entrance to level %d" % level)
	for level in range(1, FENCES + 1):
		assert_true(info.has(FENCE + level), "the fence of level %d" % level)
	for level in range(1, FLAGS + 1):
		assert_true(info.has(FLAG + level), "the flag of level %d" % level)


func test_level_names_and_texts() -> void:
	if _data == null:
		return
	var names := _data.executable.level_names()
	var entries := _data.executable.entry_texts()
	assert_equal(names.size(), Keen4Episode.LEVEL_NAME_COUNT, "maps 0-18 have a name")
	assert_equal(entries.size(), names.size(), "and an entry text")
	var same := 0
	for index in names.size():
		if names[index] == _data.maps.map_name(index):
			same += 1
	assert_true(same >= 5, "many names equal GAMEMAPS's (%d)" % same)
	var council := _data.executable.messages(Keen4Episode.COUNCIL_MESSAGES)
	assert_equal(council.size(), COUNCIL_MESSAGES, "Lindsey, Keen and the council")
	var janitor := _data.executable.messages(Keen4Episode.JANITOR_MESSAGES)
	assert_equal(janitor.size(), JANITOR_MESSAGES, "the janitor")
	var random := _data.executable.random_table()
	assert_equal(random.size(), GalaxyExecutable.RANDOM_TABLE_SIZE, "the random numbers")


func test_tile_info_counts() -> void:
	if _data == null:
		return
	var info := _data.tile_info
	var animated_back := 0
	for tile in info.back_count:
		if info.back(GalaxyTileInfo.Back.ANIMATION_TIME, tile) != 0:
			animated_back += 1
	var animated_fore := 0
	var in_front := 0
	for tile in info.fore_count:
		if info.fore(GalaxyTileInfo.Fore.ANIMATION_TIME, tile) != 0:
			animated_fore += 1
		if info.is_in_front(tile):
			in_front += 1
	assert_equal(animated_back, ANIMATED_BACK_TILES, "animated background tiles")
	assert_equal(animated_fore, ANIMATED_FORE_TILES, "animated foreground tiles")
	assert_equal(in_front, IN_FRONT_TILES, "tiles in front of the sprites")
	for tile in info.back_count:
		if info.back(GalaxyTileInfo.Back.ANIMATION_TIME, tile) != 0:
			var next := info.next_back_tile(tile)
			assert_true(next >= 0 and next < info.back_count, "an animation stays in the set")


func test_graphics_decode() -> void:
	if _data == null:
		return
	var graphics := _data.graphics
	var info := graphics.sprite_infos[10]
	assert_equal(
		[info.box_left, info.box_top, info.box_right, info.box_bottom], SPRITE_10_BOX, "the box"
	)
	assert_equal(graphics.sprite(10).get_size(), Vector2i(info.width, info.height), "its picture")
	var keen := graphics.sprite(Keen4Episode.KEEN_WALK_RIGHT_SPRITE)
	assert_true(keen != null and keen.get_height() <= 32, "the icon's Keen")
	for index in graphics.ranges.picture_count:
		var picture := graphics.picture(index)
		assert_true(picture != null, "picture %d" % index)
		if picture != null:
			assert_equal(picture.get_size(), graphics.picture_size(index), "its size")
	assert_true(graphics.back_tile(0) != null, "the first background tile")
	assert_equal(graphics.font(0).height > 0, true, "a font")
	for index in DEMO_MAPS.size():
		assert_equal(graphics.demo(index).decode_u16(0), DEMO_MAPS[index], "demo %d" % index)
	for index in graphics.ranges.text_count:
		assert_true(graphics.text(index).size() > 0, "text %d" % index)


func test_audio_chunks() -> void:
	if _data == null:
		return
	var audio := _data.audio
	assert_equal(audio.chunk_count(), AUDIO_CHUNKS, "chunks")
	for index in range(DIGITISED_SOUNDS.x, DIGITISED_SOUNDS.y):
		assert_true(audio.is_empty(index), "digitised sound %d is absent" % index)
	for index in range(SONGS.x, SONGS.y):
		var song := audio.chunk(index)
		assert_true(song.size() > 0, "song %d" % index)
		if song.size() > 2:
			assert_equal(song.decode_u16(0) + 2, song.size(), "starts with its length")
	assert_true(audio.chunk(0).size() > 0, "the first PC sound")
