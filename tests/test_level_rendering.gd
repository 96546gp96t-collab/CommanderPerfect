extends "res://tests/test_case.gd"
## Tests for drawing levels, the camera limits and the display settings, with
## small hand-made levels and tiles (no game data needed).

const TILE_COUNT := 20


func test_tile_numbers_map_to_atlas_rows() -> void:
	assert_equal(LevelTileSet.atlas_coords_of(0), Vector2i(0, 0), "tile 0")
	assert_equal(LevelTileSet.atlas_coords_of(17), Vector2i(1, 1), "tile 17")


func test_tile_set_holds_every_tile() -> void:
	var tile_set := LevelTileSet.build(_create_graphics())
	var source := tile_set.get_source(LevelTileSet.SOURCE_ID) as TileSetAtlasSource
	assert_equal(source.get_tiles_count(), TILE_COUNT, "tile count")
	assert_equal(tile_set.tile_size, Vector2i(16, 16), "tile size")


func test_playable_rect_leaves_out_the_border() -> void:
	var level := _create_level(Vector2i(10, 8))
	assert_equal(level.playable_rect(), Rect2i(2, 2, 6, 4), "playable cells")
	assert_equal(LevelMap.playable_pixels(level), Rect2i(32, 32, 96, 64), "playable pixels")


func test_crop_keeps_only_the_chosen_cells() -> void:
	var level := _create_level(Vector2i(10, 8))
	for index in level.tiles.size():
		level.tiles[index] = index
	level.infos[2 * 10 + 5] = 7
	var screen := level.crop(Rect2i(4, 1, 3, 2))
	assert_equal(screen.playable_rect(), Rect2i(2, 2, 3, 2), "the cells, inside a new border")
	assert_equal(screen.tile_at(Vector2i(2, 2)), 1 * 10 + 4, "top left cell")
	assert_equal(screen.info_at(Vector2i(3, 3)), 7, "info layer too")
	assert_equal(screen.tile_at(Vector2i(0, 0)), 0, "outside the old map: tile 0")


func test_hud_shows_only_the_keycards_keen_has() -> void:
	var keycards: Array[bool] = [false, true, false, true]
	assert_equal(
		Hud.keycard_tiles(keycards),
		PackedInt32Array([StatusScreen.KEYCARD_TILES[1], StatusScreen.KEYCARD_TILES[3]]),
		"red and blue"
	)
	assert_true(Hud.keycard_tiles([false, false, false, false]).is_empty(), "none")


func test_find_info_returns_first_match() -> void:
	var level := _create_level(Vector2i(10, 8))
	level.infos[3 * 10 + 4] = LevelData.PLAYER_START_INFO
	assert_equal(level.find_info(LevelData.PLAYER_START_INFO), Vector2i(4, 3), "start cell")
	assert_equal(level.find_info(1234), Vector2i(-1, -1), "missing value")


func test_level_map_draws_only_the_playable_area() -> void:
	var level := _create_level(Vector2i(6, 5))
	var level_map := LevelMap.new()
	level_map.tile_set = LevelTileSet.build(_create_graphics())
	level_map.show_level(level)
	assert_equal(level_map.get_used_cells().size(), 2, "drawn cells")
	assert_equal(
		level_map.get_cell_atlas_coords(Vector2i(3, 2)),
		LevelTileSet.atlas_coords_of(level.tile_at(Vector2i(3, 2))),
		"tile in cell (3, 2)"
	)
	assert_equal(level_map.get_cell_source_id(Vector2i(0, 0)), -1, "border stays empty")
	level_map.free()


func test_level_map_skips_unknown_tiles() -> void:
	var level := _create_level(Vector2i(6, 5))
	level.tiles.fill(TILE_COUNT + 5)
	var level_map := LevelMap.new()
	level_map.tile_set = LevelTileSet.build(_create_graphics())
	level_map.show_level(level)
	assert_equal(level_map.get_used_cells().size(), 0, "drawn cells")
	level_map.free()


func test_camera_limits_match_a_large_level() -> void:
	var area := Rect2i(32, 32, 1000, 500)
	assert_equal(LevelCamera.limits_for(area, Vector2i(320, 200)), area, "limits")


func test_camera_centers_a_narrow_level() -> void:
	var area := Rect2i(32, 32, 320, 500)
	var limits := LevelCamera.limits_for(area, Vector2i(426, 200))
	assert_equal(limits, Rect2i(-21, 32, 426, 500), "limits")
	var center_range := LevelCamera.center_range(limits, Vector2i(426, 200))
	assert_equal(center_range, Rect2(192, 132, 0, 300), "camera center range")


func test_original_view_matches_the_original_game() -> void:
	var settings := DisplaySettings.new()
	assert_equal(settings.game_size(), Vector2i(320, 200), "game pixels")
	assert_equal(settings.display_size(), Vector2(320, 240), "shape on a 4:3 monitor")
	settings.correct_pixel_aspect = false
	assert_equal(settings.game_size(), Vector2i(320, 200), "game pixels, square pixels")
	assert_equal(settings.display_size(), Vector2(320, 200), "shape with square pixels")


func test_widescreen_view_fills_16_by_9() -> void:
	var settings := DisplaySettings.new()
	settings.aspect = DisplaySettings.Aspect.WIDESCREEN
	assert_equal(settings.game_size(), Vector2i(426, 200), "game pixels")
	settings.correct_pixel_aspect = false
	assert_equal(settings.game_size(), Vector2i(356, 200), "game pixels, square pixels")


func test_picture_is_centered_in_the_window() -> void:
	var settings := DisplaySettings.new()
	var rect := settings.fit_rect(Vector2(1280, 720))
	assert_equal(rect, Rect2(160, 0, 960, 720), "4:3 picture in a 16:9 window")


func _create_graphics() -> EgaGraphics:
	var graphics := EgaGraphics.new()
	for i in TILE_COUNT:
		var tile := Image.create_empty(
			EgaGraphics.TILE_SIZE, EgaGraphics.TILE_SIZE, false, Image.FORMAT_RGBA8
		)
		tile.fill(EgaPalette.color(i % 16))
		graphics.tiles.append(tile)
	return graphics


## A level whose cell n holds tile n % TILE_COUNT, with an empty info layer.
func _create_level(size: Vector2i) -> LevelData:
	var level := LevelData.new()
	level.width = size.x
	level.height = size.y
	var cell_count := size.x * size.y
	level.tiles.resize(cell_count)
	level.infos.resize(cell_count)
	for i in cell_count:
		level.tiles[i] = i % TILE_COUNT
	return level
