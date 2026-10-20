extends "res://tests/test_case.gd"
## Checks the Galaxy readers and Keen 4's screens against the shareware
## v1.4 (milestone D13), next to the user's v1.0 that every other Keen 4
## suite reads. Skipped without a v1.4 in game_data/keen4-v14 (or the
## folder in the environment variable KEEN4_V14_DIR); it is never part of
## the repository. The numbers are the files' (docs/keen4/file-formats.md,
## research.md "1.0 and 1.4"); no text of the game is written here. When
## v1.0 is there too, what both versions share is compared between them.

const FOLDER := "res://game_data/keen4-v14"
const FOLDER_VARIABLE := "KEEN4_V14_DIR"
const VERSION := "1.4"
const PICTURES := 115
const SPRITES := 397
const CHUNKS := 4751
const MAPS := 20
## Where each range starts (chunk numbers of v1.4; CG's table).
const RANGE_STARTS: Dictionary[String, int] = {
	"pictures": 6,
	"masked pictures": 121,
	"sprites": 124,
	"8×8 tiles": 521,
	"masked 8×8 tiles": 522,
	"background tiles": 523,
	"foreground tiles": 1819,
	"misc": 4735,
	"texts": 4739,
	"demos": 4746,
}
## Where v1.4 keeps its headers (files, D13; CG had EGAHEAD, MAPHEAD,
## TILEINFO and EGADICT).
const HEADERS: Dictionary[GalaxyEpisode.Header, int] = {
	GalaxyEpisode.Header.AUDIOHED: 0x20DF0,
	GalaxyEpisode.Header.EGAHEAD: 0x21080,
	GalaxyEpisode.Header.MAPHEAD: 0x24830,
	GalaxyEpisode.Header.TILEINFO: 0x249C2,
	GalaxyEpisode.Header.AUDIODCT: 0x354F6,
	GalaxyEpisode.Header.EGADICT: 0x358F6,
}
const RANDOM_TABLE_AT := 0x1ED32
const AUDIO_CHUNKS := 162
const FIRST_SONG := 156
const SONG_COUNT := 6
const DEMO_MAPS: PackedInt32Array = [1, 9, 11, 15, 19]
## v1.4's first demo is another recording than v1.0's (744 frames).
const DEMO_FRAMES: PackedInt32Array = [812, 687, 749, 645, 271]
## The help's topics have other page counts than in v1.0 (seen in v1.4).
const HELP_PAGES: PackedInt32Array = [15, 21, 9, 20, 2]
const END_PAGES := 16
## The control panel's title pictures are 16 pixels high, the watch is a
## whole screen (counted from the end, the same as in v1.0).
const CARD_HEIGHT := 16
const SCREEN := Vector2i(320, 200)
## The message pictures counted from the end (Keen4Messages): the elder,
## Keen talking, Keen's thumb, the cross face, Lindsey, the count-down.
const MESSAGE_SIZES: Dictionary[int, Vector2i] = {
	11: Vector2i(48, 64),
	10: Vector2i(48, 64),
	9: Vector2i(48, 64),
	8: Vector2i(24, 24),
	7: Vector2i(48, 64),
	6: Vector2i(48, 64),
	5: Vector2i(24, 24),
	1: Vector2i(24, 24),
}
## The end's arrows: 16 × 8 in v1.4 (16 × 16 in v1.0).
const ARROW_SIZE := Vector2i(16, 8)
## The red of the help and end pages, and a place inside the frame.
const RED := 4
const INSIDE := Vector2i(150, 120)
## Demo 0 of v1.4 in the original (js-dos, the shareware v1.4, D13): per
## frame, Keen's sprite and where it is on the screen; the jump of frame
## 176 starts as he stops walking (the walk's last step still moves him:
## the view moves 4 pixels in that frame).
const DEMO_0_SEEN: PackedInt32Array = [
	170,
	15,
	144,
	110,
	175,
	18,
	144,
	111,
	176,
	19,
	144,
	109,
	177,
	44,
	136,
	102,
	183,
	21,
	144,
	77,
	193,
	43,
	136,
	111,
	206,
	7,
	148,
	110,
	214,
	7,
	184,
	110,
	232,
	72,
	192,
	109,
	260,
	15,
	158,
	97,
	308,
	6,
	152,
	109,
	400,
	21,
	144,
	42,
	600,
	90,
	144,
	58,
	810,
	22,
	144,
	111,
]
const SEEN_ROW := 4
const JUMP_FRAME := 176
const JUMP_VIEW_STEP := 4

var _data: GalaxyData
var _files: GameFiles
## v1.0, when it is there too; null otherwise.
var _v1_0: GalaxyData


func _init() -> void:
	var folder := OS.get_environment(FOLDER_VARIABLE)
	if folder.is_empty():
		folder = ProjectSettings.globalize_path(FOLDER)
	_files = Keen4Files.open(folder)
	if _files == null or not Keen4Files.is_complete(_files):
		skip("no Keen 4 v1.4 in game_data/keen4-v14")
		return
	_data = Keen4Episode.load_data(_files)
	var other := Keen4Files.locate()
	if other != null:
		var data := Keen4Episode.load_data(other)
		if data != null and data.executable.version == "1.0":
			_v1_0 = data


func test_version_counts_and_ranges() -> void:
	if _data == null:
		return
	assert_equal(_data.executable.version, VERSION, "the sign-on says 1.4")
	var ranges := _data.graphics.ranges
	assert_equal(ranges.picture_count, PICTURES, "pictures")
	assert_equal(ranges.sprite_count, SPRITES, "sprites")
	assert_equal(_data.graphics.file.chunk_count(), CHUNKS, "chunks")
	var starts: Dictionary[String, int] = {
		"pictures": ranges.picture_start,
		"masked pictures": ranges.masked_picture_start,
		"sprites": ranges.sprite_start,
		"8×8 tiles": ranges.tile8_chunk,
		"masked 8×8 tiles": ranges.masked_tile8_chunk,
		"background tiles": ranges.back_tile_start,
		"foreground tiles": ranges.fore_tile_start,
		"misc": ranges.misc_start,
		"texts": ranges.text_start,
		"demos": ranges.demo_start,
	}
	assert_equal(starts, RANGE_STARTS, "where each range starts")


func test_the_six_headers() -> void:
	if _data == null:
		return
	for piece in HEADERS:
		assert_equal(_data.headers.found_at[piece], HEADERS[piece], "where 1.4 keeps it")
	var episode := Keen4Episode.create()
	episode.known_offsets = {}
	var searched := GalaxyHeaders.find(_data.executable.image, _files, episode)
	assert_true(searched != null, "found by content alone")
	if searched != null:
		assert_equal(searched.found_at, _data.headers.found_at, "at the same places")


func test_maps_names_and_texts() -> void:
	if _data == null:
		return
	for number in MAPS:
		var map := _data.maps.load_map(number)
		assert_true(map != null, "map %d" % number)
		if map != null:
			for plane in map.planes:
				assert_equal(plane.size(), map.width * map.height, "plane of map %d" % number)
	var executable := _data.executable
	assert_equal(executable.level_names().size(), Keen4Episode.LEVEL_NAME_COUNT, "level names")
	assert_equal(executable.entry_texts().size(), Keen4Episode.LEVEL_NAME_COUNT, "entry texts")
	var shapes := Keen4Episode.create().message_shapes
	for run in shapes:
		assert_equal(executable.messages(run).size(), shapes[run].size(), "the run %s" % run)
	var lengths := Keen4Episode.create().text_lengths
	for run in lengths:
		assert_equal(executable.texts(run).size(), lengths[run].size(), "the texts %s" % run)
	assert_equal(GalaxyExecutable.find_random_table(executable.image), RANDOM_TABLE_AT, "random")
	assert_equal(executable.random_table().size(), GalaxyExecutable.RANDOM_TABLE_SIZE, "256")


func test_the_same_as_v1_0() -> void:
	if _data == null or _v1_0 == null:
		return
	var ours := _data.executable
	var theirs := _v1_0.executable
	assert_equal(ours.level_names(), theirs.level_names(), "level names")
	assert_equal(ours.entry_texts(), theirs.entry_texts(), "entry texts")
	for run in Keen4Episode.create().message_shapes:
		assert_equal(ours.messages(run), theirs.messages(run), "the run %s" % run)
	for run in Keen4Episode.create().text_lengths:
		assert_equal(ours.texts(run), theirs.texts(run), "the texts %s" % run)
	assert_equal(ours.random_table(), theirs.random_table(), "the random numbers")
	assert_equal(_data.headers.tile_info.slice(0, _tile_info_size()), _v1_0_tile_info(), "tiles")
	for number in MAPS:
		assert_equal(
			_data.maps.load_map(number).planes,
			_v1_0.maps.load_map(number).planes,
			"map %d" % number
		)
	for index in AUDIO_CHUNKS:
		assert_equal(_data.audio.chunk(index), _v1_0.audio.chunk(index), "audio chunk %d" % index)


func test_menu_cards_and_message_pictures_by_place_from_the_end() -> void:
	if _data == null:
		return
	var graphics := _data.graphics
	var cards := Keen4Episode.menu_cards(PICTURES)
	assert_equal(graphics.picture_size(cards.watch), SCREEN, "the wrist watch")
	for kind in cards.cards:
		var picture := cards.cards[kind].picture
		assert_equal(graphics.picture_size(picture).y, CARD_HEIGHT, "the card %s" % kind)
	for from_end in MESSAGE_SIZES:
		var size := graphics.picture_size(PICTURES - from_end)
		assert_equal(size, MESSAGE_SIZES[from_end], "message picture %d from the end" % from_end)
	for from_end in range(1, 34):
		var picture := graphics.picture(PICTURES - from_end)
		assert_true(picture != null, "picture %d from the end decodes" % from_end)


func test_sounds_and_songs_decode() -> void:
	if _data == null:
		return
	var audio := _data.audio
	assert_equal(audio.chunk_count(), AUDIO_CHUNKS, "audio chunks")
	assert_equal(Keen4Sounds.first_song(audio), FIRST_SONG, "the songs from chunk 156")
	for index in Keen4Sounds.SOUND_COUNT:
		assert_true(audio.chunk(index).size() > 0, "PC sound %d" % index)
	for index in SONG_COUNT:
		var song := audio.chunk(FIRST_SONG + index)
		assert_equal(song.decode_u16(0) + 2, song.size(), "song %d starts with its length" % index)


func test_the_high_score_defaults() -> void:
	if _data == null:
		return
	var defaults := Keen4FrontScreen.default_high_scores(_data)
	assert_equal(defaults.size(), Keen4Episode.HIGH_SCORE_COUNT, "eight places")
	var scores: Array = defaults.map(func(entry: GalaxyHighScores.Entry) -> int: return entry.score)
	assert_equal(scores, [10000, 10000, 10000, 10000, 10000, 10000, 10000, 10000])
	if _v1_0 != null:
		var theirs := Keen4FrontScreen.default_high_scores(_v1_0)
		for place in defaults.size():
			assert_equal(defaults[place].name, theirs[place].name, "place %d as in 1.0" % place)


func test_the_demos() -> void:
	if _data == null:
		return
	var maps := PackedInt32Array()
	var frames := PackedInt32Array()
	for index in DEMO_MAPS.size():
		var demo := GalaxyDemo.parse(_data.graphics.demo(index))
		maps.append(demo.map_number)
		frames.append(demo.frame_count())
	assert_equal(maps, DEMO_MAPS, "their maps")
	assert_equal(frames, DEMO_FRAMES, "frames of 3 tics")


func test_demo_0_plays_as_in_the_original() -> void:
	if _data == null:
		return
	var demo := GalaxyDemo.parse(_data.graphics.demo(0))
	var inventory := Keen4Inventory.new_game()
	inventory.extra_lives_for_points = false
	var map := _data.maps.load_map(demo.map_number)
	var session := Keen4LevelSession.start(_data, map, inventory, 0, GalaxyDifficulty.DEFAULT, 1)
	session.world.random_index = 0
	var clock := GalaxyClock.new()
	clock.start_level()
	clock.tics_per_frame = GalaxyClock.DEMO_TICS
	var firing := GalaxyTwoButtonFiring.new()
	var seen: Dictionary[int, PackedInt32Array] = {}
	var views: Dictionary[int, int] = {}
	for frame in DEMO_0_SEEN[-SEEN_ROW] + 1:
		var tics := clock.run_frame()
		session.run_frame(firing.convert(demo.controls_at(frame), tics), tics, clock.tic)
		seen[frame] = _as_drawn(session)
		views[frame] = session.camera.view_pixels().x
	var different: Array = []
	for at in range(0, DEMO_0_SEEN.size(), SEEN_ROW):
		var ours := seen[DEMO_0_SEEN[at]]
		if ours != DEMO_0_SEEN.slice(at + 1, at + SEEN_ROW):
			different.append([DEMO_0_SEEN[at], ours])
	assert_equal(different, [], "Keen's sprite and place in every measured frame")
	var step := views[JUMP_FRAME - 1] - views[JUMP_FRAME]
	assert_equal(step, JUMP_VIEW_STEP, "the walk's last step as he jumps")


func test_help_and_end_pages() -> void:
	if _data == null:
		return
	var counts := PackedInt32Array()
	for text in Keen4Help.TOPIC_TEXTS:
		counts.append(GalaxyTextPages.parse(_data.graphics.text(text)).page_count())
	assert_equal(counts, HELP_PAGES, "ComputerWrist, the game, the story, ordering, about Id")
	var ending := GalaxyTextPages.parse(_data.graphics.text(Keen4Ending.END_TEXT))
	assert_equal(ending.page_count(), END_PAGES, "the end's pages")
	assert_equal(_data.graphics.picture_size(Keen4Ending.ARROW_DIM), ARROW_SIZE, "dim arrow")
	assert_equal(_data.graphics.picture_size(Keen4Ending.ARROW_BRIGHT), ARROW_SIZE, "bright")


func test_pages_are_red_inside_the_frame() -> void:
	if _data == null:
		return
	var frame := GalaxyPageFrame.find(_data.graphics, Keen4Episode.PAGE_FRAME_PICTURE)
	assert_true(frame != null, "1.4 has the frame's pictures")
	var help := Keen4Help.create(_data.graphics)
	var menu := help.screen()
	assert_equal(menu.get_pixelv(INSIDE), EgaPalette.color(RED), "the help's menu on red")
	help.act(Keen4Help.Action.OPEN)
	var page := help.screen()
	var top := _data.graphics.picture(Keen4Episode.PAGE_FRAME_PICTURE).duplicate() as Image
	top.convert(page.get_format())
	var drawn := page.get_region(Rect2i(Vector2i.ZERO, top.get_size()))
	assert_equal(drawn.get_data(), top.get_data(), "the frame's top picture at the top")
	var ending := Keen4Ending.create(_data.graphics)
	for frame_count in 400:
		ending.advance(2)
	assert_true(ending.waits(), "the first end page is whole")
	assert_equal(ending.screen().get_pixelv(INSIDE + Vector2i(0, 60)), EgaPalette.color(RED), "red")
	if _v1_0 != null:
		assert_true(
			GalaxyPageFrame.find(_v1_0.graphics, Keen4Episode.PAGE_FRAME_PICTURE) == null,
			"1.0 has no frame"
		)


func _as_drawn(session: Keen4LevelSession) -> PackedInt32Array:
	var keen := session.player
	var info := _data.graphics.sprite_infos[keen.sprite]
	var pixel := GalaxyObjectLayer.pixel_of(info, keen.position)
	var view := session.camera.view_pixels()
	return PackedInt32Array([keen.sprite, pixel.x - view.x, pixel.y - view.y])


func _tile_info_size() -> int:
	return _data.graphics.ranges.tile_info_size()


func _v1_0_tile_info() -> PackedByteArray:
	return _v1_0.headers.tile_info.slice(0, _v1_0.graphics.ranges.tile_info_size())
