extends "res://tests/test_case.gd"
## Checks how Keen 4's maps are drawn (milestone D3) with the player's real
## files: Keen's start in every map, the scroll blocks, the camera's first
## view, the tiles each map needs, the animated tiles and those drawn in
## front, and which levels may show a picture behind them. Skipped without
## the files (they are never part of the repository). The numbers are from
## the user's v1.0 (files) and Omnispeak.

const MAP_COUNT := 20
## The maps whose start is Keen standing (info 1 or 2): all but the world
## map (0) and the Well of Wishes (17).
const WORLD_MAP := 0
const SWIMMING_MAP := 17
## Level 1: Keen starts at tile (108, 16) facing left (files).
const LEVEL_1_START := Vector2i(108, 16)
## Where the original's first view of level 1 lies, in pixels: at the
## right edge of the map (112 tiles, 2 of border), the last row of Keen's
## feet (pixel 271) 140 pixels from the top (Omni CK_CentreCamera; seen in
## js-dos, docs/keen4/research.md).
const LEVEL_1_VIEW := Vector2i((112 - 2) * 16 - 320, 271 - 140)
## Keen standing: his hit box ends on the 31st row of units (496 = 31 px).
const STANDING_BOX_BOTTOM := 496
## Scroll blocks (files, v1.0): level 4 has a column at 28, level 14 one at 49.
const LEVEL_4_COLUMN := 28
const LEVEL_14_COLUMN := 49
## The levels with sky in their top row (docs/keen4/gameplay.md).
const SKY_LEVELS: PackedInt32Array = [5, 7, 8, 9, 10, 11, 12, 13, 14, 16]

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_data = Keen4Episode.load_data(files)


func test_keen_starts_in_every_map() -> void:
	for number in MAP_COUNT:
		var start := Keen4Start.find(_data.maps.load_map(number))
		var expected := Keen4Start.Kind.STANDING
		if number == WORLD_MAP:
			expected = Keen4Start.Kind.WORLD_MAP
		elif number == SWIMMING_MAP:
			expected = Keen4Start.Kind.SWIMMING
		assert_equal(start.kind, expected, "Keen's start in map %d" % number)
		assert_true(_data.graphics.sprite(start.sprite) != null, "his sprite in map %d" % number)
	var level_1 := Keen4Start.find(_data.maps.load_map(1))
	assert_equal(level_1.cell, LEVEL_1_START, "level 1's start")
	assert_equal(level_1.facing, -1, "facing left")


func test_standing_keen_rests_on_the_tile_below() -> void:
	for sprite in [Keen4Episode.KEEN_STAND_RIGHT_SPRITE, Keen4Episode.KEEN_STAND_LEFT_SPRITE]:
		var info := _data.graphics.sprite_infos[sprite]
		assert_equal(info.box_bottom, STANDING_BOX_BOTTOM, "box of sprite %d" % sprite)
		assert_equal(
			-Keen4Start.STANDING_RISE + info.box_bottom,
			GalaxyCamera.UNITS_PER_TILE - 1,
			"feet on the last unit of the info tile"
		)


func test_first_view_of_level_1() -> void:
	var map := _data.maps.load_map(1)
	var start := Keen4Start.find(map)
	var camera := _camera_for(map)
	var info := _data.graphics.sprite_infos[start.sprite]
	camera.centre_on(start.position.x, start.position.y + info.box_bottom)
	assert_equal(camera.view_pixels(), LEVEL_1_VIEW, "the view at the start of level 1")


func test_scroll_blocks_are_found() -> void:
	var level_4 := _camera_for(_data.maps.load_map(4))
	assert_true(level_4.column_blocks.has(LEVEL_4_COLUMN), "level 4's column")
	var level_14 := _camera_for(_data.maps.load_map(14))
	assert_true(level_14.column_blocks.has(LEVEL_14_COLUMN), "level 14's column")
	for number in MAP_COUNT:
		var map := _data.maps.load_map(number)
		var camera := _camera_for(map)
		var start := Keen4Start.find(map)
		camera.centre_on(start.position.x, start.position.y, start.is_world_map(), start.position.y)
		var view := Rect2i(camera.view_pixels(), GalaxyCamera.VIEW_PIXELS)
		assert_true(camera.area_pixels().encloses(view), "map %d: the view between blocks" % number)


func test_every_tile_a_map_needs_exists() -> void:
	for number in MAP_COUNT:
		var map := _data.maps.load_map(number)
		for tile in GalaxyLevelMap.tiles_of(map, _data.tile_info, GalaxyMap.Layer.BACKGROUND):
			assert_true(
				_data.graphics.back_tile(tile) != null, "map %d back tile %d" % [number, tile]
			)
		for tile in GalaxyLevelMap.tiles_of(map, _data.tile_info, GalaxyMap.Layer.FOREGROUND):
			assert_true(
				tile == 0 or _data.graphics.fore_tile(tile) != null,
				"map %d fore tile %d" % [number, tile]
			)


func test_animated_and_in_front_tiles_in_level_1() -> void:
	var map := _data.maps.load_map(1)
	var animator := GalaxyTileAnimator.for_map(map, _data.tile_info)
	assert_true(animator.cycles().size() > 0, "level 1 has animated tiles")
	var changed := 0
	for frame in 35:
		changed += animator.advance(GalaxyClock.NORMAL_TICS).size()
	assert_true(changed > 0, "and they move within a second")
	var in_front := 0
	for tile in map.planes[GalaxyMap.Layer.FOREGROUND]:
		if tile != 0 and _data.tile_info.is_in_front(tile):
			in_front += 1
	assert_true(in_front > 0, "level 1 has tiles in front of Keen")


func test_levels_with_sky() -> void:
	var pictures := GalaxyBackdropPictures.for_episode(
		null,
		Keen4Episode.BACKDROP_FOLDER,
		Keen4Episode.SKY_TILES,
		Keen4Episode.FIRST_LEVEL,
		Keen4Episode.LAST_LEVEL
	)
	var with_sky := PackedInt32Array()
	for number in MAP_COUNT:
		if pictures.sky_tile(_data.maps.load_map(number)) >= 0:
			with_sky.append(number)
	assert_equal(with_sky, SKY_LEVELS, "the levels that may show a picture")


func _camera_for(map: GalaxyMap) -> GalaxyCamera:
	return GalaxyCamera.for_map(
		Vector2i(map.width, map.height),
		GalaxyCamera.blocks_in(map, Keen4Episode.COLUMN_BLOCK_INFO, true),
		GalaxyCamera.blocks_in(map, Keen4Episode.ROW_BLOCK_INFO, false)
	)
