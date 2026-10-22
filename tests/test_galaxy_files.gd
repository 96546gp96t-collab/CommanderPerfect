extends "res://tests/test_case.gd"
## Tests for what the Galaxy readers make of hand-made files
## (tests/galaxy_file_fixtures.gd): the chunk ranges worked out from the
## tables, pictures with their plane order, masks, sprites with origin and
## hit box, 8×8 and 16×16 tiles, the font, texts and demos, the maps with
## their three planes, the tile information and the audio chunks; and the
## whole episode loaded from a folder.

const Fixtures := preload("res://tests/galaxy_fixtures.gd")
const FileFixtures := preload("res://tests/galaxy_file_fixtures.gd")
const TEST_DIRECTORY := "user://test_galaxy_files"

var _data: GalaxyData


func _init() -> void:
	var folder := ProjectSettings.globalize_path(TEST_DIRECTORY)
	FileFixtures.write_folder(folder)
	_data = GalaxyData.load_from(GameFiles.open(folder, Fixtures.EXTENSION), Fixtures.episode())
	var directory := DirAccess.open(folder)
	for file_name in directory.get_files():
		directory.remove(file_name)
	DirAccess.remove_absolute(folder)


func test_the_episode_loads() -> void:
	assert_true(_data != null, "every file and header read")
	if _data == null:
		return
	assert_equal(_data.executable.version, Fixtures.VERSION, "the version")
	assert_equal(_data.executable.level_names(), Fixtures.LEVEL_NAMES, "the level names")


func test_chunk_ranges_from_the_tables() -> void:
	if _data == null:
		return
	var ranges := _data.graphics.ranges
	assert_equal(ranges.font_start, 3, "the fonts after the three tables")
	assert_equal(ranges.picture_start, 4, "then the pictures")
	assert_equal(ranges.picture_count, Fixtures.PICTURE_SIZES.size(), "pictures: table / 4")
	assert_equal(ranges.masked_picture_start, 6, "masked pictures")
	assert_equal(ranges.masked_picture_count, 1, "one")
	assert_equal(ranges.sprite_start, 7, "sprites")
	assert_equal(ranges.sprite_count, Fixtures.SPRITES.size(), "sprites: table / 18")
	assert_equal(ranges.tile8_chunk, 9, "8×8 tiles")
	assert_equal(ranges.tile8_count, Fixtures.TILE8_COUNT, "counted from the chunk")
	assert_equal(ranges.masked_tile8_count, Fixtures.MASKED_TILE8_COUNT, "masked 8×8 tiles")
	assert_equal(ranges.back_tile_start, 11, "background tiles")
	assert_equal(
		ranges.back_tile_count, Fixtures.BACK_TILES, "the border on a whole row of 18 tiles"
	)
	assert_equal(ranges.fore_tile_start, 11 + Fixtures.BACK_TILES, "foreground tiles")
	assert_equal(ranges.fore_tile_count, Fixtures.FORE_TILES, "the rest")
	assert_equal(ranges.misc_start, 33, "misc")
	assert_equal(ranges.text_start, 34, "texts")
	assert_equal(ranges.demo_start, 35, "demos last")
	assert_equal(ranges.tile_info_size(), Fixtures.tile_info().size(), "the tile info's size")


func test_picture_planes_blue_green_red_intensity() -> void:
	if _data == null:
		return
	var picture := _data.graphics.picture(0)
	assert_equal(picture.get_size(), Vector2i(8, 2), "8 x 2 pixels")
	for x in 4:
		assert_equal(picture.get_pixel(x, 0), EgaPalette.color(1 << x), "plane %d" % x)
	assert_equal(picture.get_pixel(7, 1), EgaPalette.color(1), "row 1")
	assert_equal(_data.graphics.picture_size(1), Vector2i(16, 1), "the second picture's size")
	assert_equal(_data.graphics.picture(1).get_pixel(15, 0), EgaPalette.color(1), "blue")
	assert_true(_data.graphics.picture(2) == null, "outside the range")


func test_masks_come_first() -> void:
	if _data == null:
		return
	var masked := _data.graphics.masked_picture(0)
	assert_equal(masked.get_pixel(0, 0).a, 0.0, "a set mask bit is see-through")
	assert_equal(masked.get_pixel(4, 0), EgaPalette.color(5), "then the colour planes")
	var sprite := _data.graphics.sprite(0)
	assert_equal(sprite.get_size(), Vector2i(8, 2), "the sprite's size")
	assert_equal(sprite.get_pixel(0, 0), EgaPalette.color(9), "blue and intensity")
	assert_equal(sprite.get_pixel(7, 0).a, 0.0, "masked")
	assert_equal(sprite.get_pixel(7, 1), EgaPalette.color(9), "not masked")
	assert_equal(_data.graphics.sprite(1).get_pixel(10, 0), EgaPalette.color(2), "green")


func test_sprite_origin_and_hit_box() -> void:
	if _data == null:
		return
	var info := _data.graphics.sprite_infos[0]
	assert_equal(Vector2i(info.width, info.height), Vector2i(8, 2), "size in pixels")
	assert_equal(info.origin, Vector2i(0, 16), "origin in global units")
	assert_equal(
		[info.box_left, info.box_top, info.box_right, info.box_bottom],
		[16, 16, 96, 48],
		"box in global units"
	)
	assert_equal(info.shifts, 4, "shifts")
	assert_equal(info.hit_box_pixels(), Rect2i(1, 0, 5, 2), "box in the picture's pixels")
	assert_equal(_data.graphics.sprite_infos[1].origin, Vector2i(-32, 0), "a negative origin")


func test_tiles() -> void:
	if _data == null:
		return
	var graphics := _data.graphics
	for index in Fixtures.TILE8_COUNT:
		assert_equal(graphics.tile8(index).get_pixel(3, 3), EgaPalette.color(1 << index), "8×8")
	assert_equal(graphics.tile8(0, true).get_pixel(0, 0), EgaPalette.color(1), "masked 8×8")
	assert_equal(graphics.tile8(1, true).get_pixel(0, 0).a, 0.0, "see-through")
	assert_equal(graphics.back_tile(5).get_pixel(5, 0), EgaPalette.color(1), "tile 5: 00000101")
	assert_equal(graphics.back_tile(5).get_pixel(4, 0), EgaPalette.color(0), "a clear bit")
	assert_true(graphics.back_tile(16) == null, "an empty tile")
	assert_true(graphics.fore_tile(0) == null, "the empty foreground tile")
	assert_equal(graphics.fore_tile(1).get_pixel(9, 9), EgaPalette.color(4), "red")
	var atlas := graphics.tile_atlas(true, 2)
	assert_equal(atlas.get_size(), Vector2i(32, 32), "two by two tiles")
	assert_equal(atlas.get_pixel(0, 0).a, 0.0, "the empty tile is see-through")


func test_font_text_demo_and_misc() -> void:
	if _data == null:
		return
	var font := _data.graphics.font(0)
	assert_equal(font.height, Fixtures.FONT_HEIGHT, "height")
	assert_equal(font.width_of(Fixtures.FONT_CHARACTER), Fixtures.FONT_WIDTH, "width")
	assert_true(font.is_set(Fixtures.FONT_CHARACTER, 0, 0), "a set pixel")
	assert_true(not font.is_set(Fixtures.FONT_CHARACTER, 1, 0), "a clear pixel")
	assert_true(font.is_set(Fixtures.FONT_CHARACTER, 1, 1), "row 2")
	assert_equal(font.text_width("AA"), Fixtures.FONT_WIDTH * 2, "a word")
	var image := font.render("A", Color.WHITE)
	assert_equal(image.get_pixel(2, 0), Color.WHITE, "drawn")
	assert_equal(_data.graphics.text(0).get_string_from_ascii(), Fixtures.TEXT_BYTES, "text")
	assert_equal(_data.graphics.demo(0)[0], Fixtures.DEMO_MAP, "the demo's map")
	assert_equal(_data.graphics.misc(0).get_string_from_ascii(), Fixtures.MISC_BYTES, "misc")


func test_maps_with_three_planes() -> void:
	if _data == null:
		return
	var maps := _data.maps
	assert_equal(maps.map_count(), 3, "up to the last slot with a map")
	assert_true(not maps.has_map(1), "slot 1 is empty")
	assert_true(maps.load_map(1) == null, "and gives no map")
	for slot in Fixtures.MAPS:
		var map := maps.load_map(slot)
		assert_equal(map.name, Fixtures.MAPS[slot][0], "name of map %d" % slot)
		assert_equal(Vector2i(map.width, map.height), maps.map_size(slot), "size")
		assert_equal(map.planes, Fixtures.map_planes(slot), "the three planes of map %d" % slot)
	var first := maps.load_map(0)
	assert_equal(first.tile(GalaxyMap.Layer.INFO, 0, 0), 0xA712, "a word like a Carmack marker")
	assert_equal(first.tile(GalaxyMap.Layer.BACKGROUND, 2, 1), 6, "row by row")
	assert_equal(first.tile(GalaxyMap.Layer.BACKGROUND, 3, 0), 0, "outside the map")


func test_tile_info() -> void:
	if _data == null:
		return
	var info := _data.tile_info
	assert_equal(info.back(GalaxyTileInfo.Back.ANIMATION_TIME, 1), 8, "animation time")
	assert_equal(info.next_back_tile(1), 2, "to the next tile")
	assert_equal(info.next_back_tile(2), 1, "and back (a negative offset)")
	assert_equal(info.fore(GalaxyTileInfo.Fore.TOP, 1), 3, "a slope on top")
	assert_equal(info.fore(GalaxyTileInfo.Fore.LEFT, 1), 1, "a wall on the left")
	assert_true(info.is_in_front(2), "drawn in front of the sprites")
	assert_equal(info.misc_kind(2), 5, "its kind")
	assert_equal(info.fore(GalaxyTileInfo.Fore.ANIMATION_TIME, 3), 10, "the last table")
	assert_true(GalaxyTileInfo.parse(PackedByteArray([1, 2]), 1, 1) == null, "too short")


func test_audio_chunks() -> void:
	if _data == null:
		return
	var audio := _data.audio
	var sounds := Fixtures.SOUNDS.size()
	assert_equal(audio.chunk_count(), sounds + Fixtures.BOGUS_ENTRIES + 1, "every chunk")
	for index in sounds:
		assert_equal(
			audio.chunk(index).get_string_from_ascii(), Fixtures.SOUNDS[index], "sound %d" % index
		)
	for index in Fixtures.BOGUS_ENTRIES:
		assert_true(audio.is_empty(sounds + index), "the bogus block is empty")
	assert_equal(
		audio.chunk(sounds + Fixtures.BOGUS_ENTRIES).get_string_from_ascii(), Fixtures.SONG, "song"
	)
