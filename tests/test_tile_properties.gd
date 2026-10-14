extends "res://tests/test_case.gd"
## Tests for unpacking executables and reading tile properties, with small
## hand-made data (no game data needed).

const Fixtures := preload("res://tests/fixtures.gd")


## One literal "A", one literal "B", a short copy of 4 bytes from 2 back, and
## the end marker. Control bits, lowest first: 1 1 | 0 0 1 0 | 0 1.
func test_lzexe_stream_is_unpacked() -> void:
	var control_word := 0b1001_0011
	var stream := PackedByteArray([control_word, 0x00, 0x41, 0x42, 0xFE, 0x00, 0x00, 0x00])
	assert_equal(LzexeDecompressor.decompress(stream).get_string_from_ascii(), "ABABAB", "output")


func test_truncated_lzexe_stream_fails() -> void:
	var stream := PackedByteArray([0xFF, 0xFF, 0x41])
	assert_equal(LzexeDecompressor.decompress(stream).size(), 0, "output of a truncated stream")


func test_uncompressed_executable_image_follows_the_header() -> void:
	var exe := PackedByteArray()
	exe.resize(32 + 4)
	exe.encode_u16(0, DosExecutable.MZ_SIGNATURE)
	exe.encode_u16(DosExecutable.HEADER_PARAGRAPHS_OFFSET, 2)
	exe.encode_u32(32, 0xDEADBEEF)
	var image := DosExecutable.load_image(exe)
	assert_equal(image.size(), 4, "image size")
	assert_equal(image.decode_u32(0), 0xDEADBEEF, "image contents")


func test_table_is_found_between_other_data() -> void:
	var table := Fixtures.create_table()
	var image := PackedByteArray()
	image.resize(102)
	image.fill(0x77)
	image.append_array(table)
	image.append_array(PackedByteArray([0x77, 0x77, 0x77]))
	var properties := TileProperties.find_in_image(image, Fixtures.TILE_COUNT)
	assert_true(properties != null, "table should be found")
	if properties == null:
		return
	assert_true(properties.blocks_left(Fixtures.WALL), "wall blocks from the left")
	assert_true(properties.is_deadly(Fixtures.FIRE), "fire is deadly")
	assert_true(properties.is_foreground(Fixtures.PILLAR), "pillar is in front")
	assert_equal(properties.floor_type(Fixtures.ICE), TileProperties.Floor.ICE, "ice floor")


func test_sides_are_read_separately() -> void:
	var properties := Fixtures.create_properties()
	var platform := Fixtures.PLATFORM
	assert_true(properties.blocks_top(platform), "platform top")
	assert_true(not properties.blocks_bottom(platform), "platform bottom")
	assert_true(not properties.blocks_left(platform), "platform left")
	assert_true(not properties.blocks_right(platform), "platform right")


func test_animation_cycles_within_its_run() -> void:
	var properties := Fixtures.create_properties()
	var first := Fixtures.ANIMATION_START
	assert_equal(properties.animated_tile(first, 1), first + 1, "next frame")
	assert_equal(properties.animated_tile(first + 3, 1), first, "wraps to the first frame")
	assert_equal(properties.animated_tile(first + 2, 5), first + 3, "starts from its own frame")
	assert_equal(properties.animated_tile(first + 4, 1), first + 5, "second animation of the run")
	assert_equal(properties.animated_tile(first + 7, 1), first + 4, "second animation wraps")
	assert_equal(properties.animated_tile(Fixtures.WALL, 3), Fixtures.WALL, "still tile")


func test_level_map_draws_foreground_tiles_in_front() -> void:
	var level := Fixtures.create_level(["..P#", "...."])
	var level_map := LevelMap.new()
	level_map.tile_set = LevelTileSet.build(Fixtures.create_graphics())
	level_map.show_level(level, Fixtures.create_properties())
	var pillar_cell := Vector2i(4, 2)
	assert_equal(level_map.get_cell_source_id(pillar_cell), -1, "pillar not behind Keen")
	assert_equal(
		level_map.foreground().get_cell_atlas_coords(pillar_cell),
		LevelTileSet.atlas_coords_of(Fixtures.PILLAR),
		"pillar in front of Keen"
	)
	assert_true(level_map.foreground().z_index > 0, "foreground drawn above sprites")
	level_map.free()


func test_level_map_animates_tiles() -> void:
	var level := Fixtures.create_level(["A..."])
	var level_map := LevelMap.new()
	level_map.tile_set = LevelTileSet.build(Fixtures.create_graphics())
	level_map.show_level(level, Fixtures.create_properties())
	var cell := Vector2i(2, 2)
	level_map.animate(LevelMap.ANIMATION_FRAME_TIME * 2.5)
	assert_equal(
		level_map.get_cell_atlas_coords(cell),
		LevelTileSet.atlas_coords_of(Fixtures.ANIMATION_START + 2),
		"third frame after two frame times"
	)
	level_map.free()
