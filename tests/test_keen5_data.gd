extends "res://tests/test_case.gd"
## Checks the Galaxy readers against the player's real Keen 5 files.
## Skipped when they are not available: Keen 5 was never shareware and its
## files are never part of the repository. The numbers come from
## docs/keen5/file-formats.md and research.md (v1.4, the user's); no text
## of the game is written here: names are compared with each other, with
## GAMEMAPS and by their shape.

const VERSION := "1.4"
const PICTURE_COUNT := 93
const MASKED_PICTURE_COUNT := 3
const SPRITE_COUNT := 346
const BACK_TILE_COUNT := 1512
const FORE_TILE_COUNT := 2952
const TILE8_COUNT := 104
const MASKED_TILE8_COUNT := 20
const FONT_COUNT := 3
const MAP_COUNT := 16
const CHUNK_COUNT := 4931
## Where v1.4 keeps its headers (file-formats.md).
const HEADERS_V1_4: Dictionary[GalaxyEpisode.Header, int] = {
	GalaxyEpisode.Header.AUDIOHED: 0x21C80,
	GalaxyEpisode.Header.EGAHEAD: 0x21FC0,
	GalaxyEpisode.Header.MAPHEAD: 0x25990,
	GalaxyEpisode.Header.TILEINFO: 0x25B22,
	GalaxyEpisode.Header.AUDIODCT: 0x35EC4,
	GalaxyEpisode.Header.EGADICT: 0x362C4,
}
## The world map (research.md §8): Keen on the map, his arrival on Korath
## III, the entrances to levels 1-13 and their flags.
const MAP_KEEN := 3
const KORATH_ARRIVAL := 26
const ENTRANCE := 0xC000
const FLAG := 0xF000
const LEVELS := 13
const WORLD_MAP_SIZE := Vector2i(52, 114)
## Map 1 (research.md §6): Keen facing left once, the exit door's pair of
## targets, and no value between the objects and the targets.
const LEVEL_1 := 1
const LEVEL_1_SIZE := Vector2i(58, 88)
const KEEN_LEFT := 2
const EXIT_DOOR := 0xB1B1
const EXIT_DOOR_WORDS := 2
const LAST_OBJECT := 107
const FIRST_TARGET := 0x100
## Tile information (files, v1.4).
const ANIMATED_BACK_TILES := 123
const ANIMATED_FORE_TILES := 415
const IN_FRONT_TILES := 962
## The maps the five demos play (files).
const DEMO_MAPS: PackedInt32Array = [1, 3, 10, 11, 15]
## The last misc chunk is a whole screen: 320 × 200 in four planes.
const SCREEN_BYTES := 32000
const AUDIO_CHUNKS := 206
const DIGITISED_SOUNDS := Vector2i(128, 192)
const SONGS := Vector2i(192, 206)
## Runs of texts and their sizes.
const STORY_LINES := 37
const STATUS_LABELS := 12
const GAME_TEXTS := 12
const CHEAT_TEXTS := 3
const FUSE_TEXTS := 2
## The fuse messages: the Korath III fuse's has 2 lines, the other 4.
const FUSE_LINES: PackedInt32Array = [2, 4]
## Map names that GAMEMAPS spells as the program does (2 and 13).
const SAME_NAMES := 2

var _data: GalaxyData


func _init() -> void:
	var files := Keen5Files.locate()
	if files == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_data = Keen5Episode.load_data(files)


func test_version_and_headers() -> void:
	if _data == null:
		return
	assert_equal(_data.executable.version, VERSION, "named by the program's size")
	for piece in HEADERS_V1_4:
		assert_equal(_data.headers.found_at[piece], HEADERS_V1_4[piece], "where 1.4 keeps it")
	assert_equal(_data.graphics.file.chunk_count(), CHUNK_COUNT, "chunks")
	assert_equal(_data.headers.map_tag, 0xABCD, "the RLEW tag")


func test_headers_found_without_the_known_places() -> void:
	if _data == null:
		return
	var episode := Keen5Episode.create()
	episode.known_offsets = {}
	var searched := GalaxyHeaders.find(_data.executable.image, Keen5Files.locate(), episode)
	assert_true(searched != null, "found by content alone")
	if searched != null:
		assert_equal(searched.found_at, _data.headers.found_at, "at the same places")


func test_counts() -> void:
	if _data == null:
		return
	var ranges := _data.graphics.ranges
	assert_equal(ranges.picture_count, PICTURE_COUNT, "pictures")
	assert_equal(ranges.masked_picture_count, MASKED_PICTURE_COUNT, "masked pictures")
	assert_equal(ranges.sprite_count, SPRITE_COUNT, "sprites")
	assert_equal(ranges.back_tile_count, BACK_TILE_COUNT, "background tiles")
	assert_equal(ranges.fore_tile_count, FORE_TILE_COUNT, "foreground tiles")
	assert_equal(ranges.tile8_count, TILE8_COUNT, "8×8 tiles")
	assert_equal(ranges.masked_tile8_count, MASKED_TILE8_COUNT, "masked 8×8 tiles")
	assert_equal(ranges.font_count, FONT_COUNT, "fonts")
	assert_true(ranges.text_start < ranges.misc_start, "the texts before the misc chunks")
	assert_equal(ranges.demo_start + ranges.demo_count, CHUNK_COUNT, "the demos last")
	assert_equal(_data.maps.map_count(), MAP_COUNT, "map slots")
	assert_equal(_data.tile_info.back_count, BACK_TILE_COUNT, "tile info for the background")
	assert_equal(_data.tile_info.fore_count, FORE_TILE_COUNT, "and the foreground")


func test_the_worked_out_border_would_be_wrong() -> void:
	if _data == null:
		return
	var episode := Keen5Episode.create()
	episode.back_tile_count = 0
	var ranges := GalaxyChunkRanges.from_file(_data.graphics.file, episode)
	assert_true(ranges.back_tile_count < BACK_TILE_COUNT, "the last tiles are empty")


func test_every_map_decodes() -> void:
	if _data == null:
		return
	for number in MAP_COUNT:
		if number == Keen5Episode.EMPTY_MAP:
			assert_true(not _data.maps.has_map(number), "slot %d is empty" % number)
			continue
		var map := _data.maps.load_map(number)
		assert_true(map != null, "map %d" % number)
		if map != null:
			for plane in map.planes:
				assert_equal(plane.size(), map.width * map.height, "plane of map %d" % number)


func test_world_map_info_values() -> void:
	if _data == null:
		return
	var map := _data.maps.load_map(Keen5Episode.WORLD_MAP)
	assert_equal(Vector2i(map.width, map.height), WORLD_MAP_SIZE, "its size")
	var info := map.planes[GalaxyMap.Layer.INFO]
	assert_equal(info.count(MAP_KEEN), 1, "Keen once")
	assert_equal(info.count(KORATH_ARRIVAL), 1, "his arrival on Korath III")
	for level in range(1, LEVELS + 1):
		assert_true(info.has(ENTRANCE + level), "the entrance to level %d" % level)
		assert_equal(info.count(FLAG + level), 1, "the flag of level %d" % level)
	assert_true(not info.has(ENTRANCE + LEVELS + 1), "no fourteenth entrance")


func test_level_1_info_values() -> void:
	if _data == null:
		return
	var map := _data.maps.load_map(LEVEL_1)
	assert_equal(Vector2i(map.width, map.height), LEVEL_1_SIZE, "its size")
	var info := map.planes[GalaxyMap.Layer.INFO]
	assert_equal(info.count(KEEN_LEFT), 1, "Keen once, facing left")
	assert_equal(info.count(EXIT_DOOR), EXIT_DOOR_WORDS, "the exit door")
	var others := 0
	for value in info:
		if value > LAST_OBJECT and value < FIRST_TARGET:
			others += 1
	assert_equal(others, 0, "every value an object or a target")


func test_level_names_and_texts() -> void:
	if _data == null:
		return
	var names := _data.executable.level_names()
	var entries := _data.executable.entry_texts()
	assert_equal(names.size(), Keen5Episode.LEVEL_NAME_COUNT, "maps 0-15 have a name")
	assert_equal(entries.size(), names.size(), "and an entry text")
	var same := 0
	for index in names.size():
		var name := GalaxyExeTexts.one_line(names[index])
		assert_true(GalaxyExeTexts.one_line(entries[index]).ends_with(name), "text %d" % index)
		if name == _data.maps.map_name(index):
			same += 1
	assert_equal(same, SAME_NAMES, "two names equal GAMEMAPS's")
	var searching := Keen5Episode.create()
	searching.known_level_name_offsets = PackedInt32Array()
	var searched := GalaxyExecutable.from_image(_data.executable.image, searching)
	assert_equal(searched.level_texts_start(), Keen5Episode.LEVEL_NAMES_V1_4, "found by shape")
	assert_equal(
		_data.executable.random_table().size(),
		GalaxyExecutable.RANDOM_TABLE_SIZE,
		"the random numbers"
	)


func test_message_runs() -> void:
	if _data == null:
		return
	var executable := _data.executable
	var story := executable.messages(Keen5Episode.STORY_MESSAGES)
	assert_equal(story.size(), 1, "the story")
	if story.size() == 1:
		assert_equal(GalaxyExeTexts.line_count(story[0]), STORY_LINES, "its lines")
	assert_equal(executable.texts(Keen5Episode.STATUS_TEXTS).size(), STATUS_LABELS, "status")
	assert_equal(executable.texts(Keen5Episode.GAME_TEXTS).size(), GAME_TEXTS, "game texts")
	assert_equal(executable.texts(Keen5Episode.CHEAT_TEXTS).size(), CHEAT_TEXTS, "cheat")
	var fuse := executable.texts(Keen5Episode.FUSE_TEXTS)
	assert_equal(fuse.size(), FUSE_TEXTS, "the fuse messages")
	for index in fuse.size():
		assert_equal(GalaxyExeTexts.line_count(fuse[index]), FUSE_LINES[index], "fuse %d" % index)
	var korath := executable.texts(Keen5Episode.GAME_TEXTS)[Keen5Episode.KORATH_TEXT]
	assert_equal(GalaxyExeTexts.line_count(korath), 2, "the arrival on Korath III")
	assert_true(korath.ends_with(_data.maps.map_name(13).left(10)), "names Korath III")


func test_message_runs_found_without_the_known_places() -> void:
	if _data == null:
		return
	var episode := Keen5Episode.create()
	var image := _data.executable.image
	for run in episode.text_lengths:
		var start := GalaxyExeTexts.find_by_lengths(
			image, episode.text_lengths[run], PackedInt32Array()
		)
		assert_equal(start, episode.known_text_offsets[run][0], "the %s texts" % run)
	for run in episode.message_shapes:
		var start := GalaxyExeTexts.find_messages(
			image, episode.message_shapes[run], PackedInt32Array()
		)
		assert_equal(start, episode.known_message_offsets[run][0], "the %s messages" % run)


func test_high_score_table() -> void:
	if _data == null:
		return
	var image := _data.executable.image
	var count := Keen5Episode.HIGH_SCORE_COUNT
	var known := GalaxyHighScores.find_defaults(image, count, Keen5Episode.high_score_offsets())
	assert_equal(known, Keen5Episode.HIGH_SCORES_V1_4, "at the known place")
	var searched := GalaxyHighScores.find_defaults(image, count, PackedInt32Array())
	assert_equal(searched, known, "and found by shape")
	var entries := GalaxyHighScores.defaults_at(image, known, count)
	assert_equal(entries.size(), count, "eight places")
	assert_true(not entries[0].name.is_empty(), "a name on top")


func test_graphics_decode() -> void:
	if _data == null:
		return
	var graphics := _data.graphics
	for sprite in [
		Keen5Episode.KEEN_STAND_RIGHT_SPRITE,
		Keen5Episode.KEEN_WALK_RIGHT_SPRITE,
		Keen5Episode.KEEN_STAND_LEFT_SPRITE,
	]:
		var keen := graphics.sprite(sprite)
		assert_true(keen != null and keen.get_height() <= 32, "Keen's sprite %d" % sprite)
	for index in graphics.ranges.picture_count:
		var picture := graphics.picture(index)
		assert_true(picture != null, "picture %d" % index)
		if picture != null:
			assert_equal(picture.get_size(), graphics.picture_size(index), "its size")
	assert_true(graphics.back_tile(0) != null, "the first background tile")
	assert_true(graphics.fore_tile(FORE_TILE_COUNT - 1) != null, "the last foreground tile")
	for index in FONT_COUNT:
		assert_true(graphics.font(index) != null and graphics.font(index).height > 0, "a font")
	for index in DEMO_MAPS.size():
		assert_equal(graphics.demo(index).decode_u16(0), DEMO_MAPS[index], "demo %d" % index)
	for index in graphics.ranges.text_count:
		assert_true(graphics.text(index).size() > 0, "text %d" % index)
	for index in graphics.ranges.misc_count:
		assert_true(graphics.misc(index).size() > 0, "misc %d" % index)
	assert_equal(graphics.misc(graphics.ranges.misc_count - 1).size(), SCREEN_BYTES, "a screen")


func test_tile_info_lines_up() -> void:
	if _data == null:
		return
	var info := _data.tile_info
	var animated_back := 0
	for tile in info.back_count:
		if info.back(GalaxyTileInfo.Back.ANIMATION_TIME, tile) != 0:
			animated_back += 1
			var next := info.next_back_tile(tile)
			assert_true(next >= 0 and next < info.back_count, "an animation stays in the set")
	var animated_fore := 0
	var in_front := 0
	var walls := 0
	for tile in info.fore_count:
		if info.fore(GalaxyTileInfo.Fore.ANIMATION_TIME, tile) != 0:
			animated_fore += 1
		if info.is_in_front(tile):
			in_front += 1
		for side in [GalaxyTileInfo.Fore.LEFT, GalaxyTileInfo.Fore.RIGHT]:
			if info.fore(side, tile) > 1:
				walls += 1
	assert_equal(animated_back, ANIMATED_BACK_TILES, "animated background tiles")
	assert_equal(animated_fore, ANIMATED_FORE_TILES, "animated foreground tiles")
	assert_equal(in_front, IN_FRONT_TILES, "tiles in front of the sprites")
	assert_equal(walls, 0, "side walls are 0 or 1: the tables line up")


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


func test_icon_and_coming_soon_screen() -> void:
	if _data == null:
		return
	var files := Keen5Files.locate()
	var picture := Keen5Icon.picture(files)
	assert_true(picture != null, "Keen on the icon")
	if picture != null:
		var walking := _data.graphics.sprite(Keen5Episode.KEEN_WALK_RIGHT_SPRITE)
		assert_equal(Vector2i(picture.get_size()), walking.get_size(), "walking")
	assert_true(Keen5Icon.title(files, "Keen 5") != null, "the name in Keen 5's font")
	var lines := Keen5View.map_lines(_data, 13)
	assert_equal(lines[1], _data.executable.level_names()[13], "the level's name")
	var plain := Keen5View.picture(_data, -1)
	var named := Keen5View.picture(_data, 13)
	assert_true(plain.get_data() != named.get_data(), "the name is printed")
