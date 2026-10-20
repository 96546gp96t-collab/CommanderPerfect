extends "res://tests/test_case.gd"
## Checks how a Galaxy level is drawn (milestone D3) with hand-made maps and
## tile information: the clock, the tile animation, the three tile layers,
## the atlas, the camera with its scroll blocks and the widescreen area,
## the sprite layer's order, the original's drawing steps (D8.1: sprites
## at 8 / shifts pixels, the view at 2) and the rule for pictures behind
## levels. The numbers of the camera are Omnispeak's
## (docs/keen4/research.md).

const BACK_TILES := 8
const FORE_TILES := 8
## Background tiles 1 and 2 loop: 1 → 2 after 4 tics, 2 → 1 after 6.
const BACK_LOOP: PackedInt32Array = [1, 2]
const BACK_TIMES: PackedInt32Array = [4, 6]
## Foreground tile 3 is drawn in front of the sprites, 4 has an offset but
## no time (like a gem holder), 5 → 6 → 5 every 2 tics.
const FRONT_TILE := 3
const STILL_OFFSET_TILE := 4
const FORE_LOOP: PackedInt32Array = [5, 6]
const FORE_TIME := 2
const MAP_SIZE := Vector2i(40, 30)
const UNITS := 16
const TILE := 256

var _scene_root: Node


func test_clock_runs_two_tics_a_frame() -> void:
	var clock := GalaxyClock.new()
	assert_equal(clock.advance(1.0 / 70.0), 0, "one tic is no frame yet")
	assert_equal(clock.advance(1.0 / 70.0), 1, "two tics make a frame")
	assert_equal(clock.run_frame(), 2, "the frame covers two tics")
	assert_equal(clock.tic, 2, "the absolute tic")
	assert_equal(clock.advance(10.0), 2, "at most five tics pile up: two frames")
	clock.run_frame()
	clock.run_frame()
	assert_true(clock.blend() > 0.4 and clock.blend() < 0.6, "the fifth tic is half a frame")


func test_animation_follows_the_tile_info() -> void:
	var info := _tile_info()
	var map := _map()
	map.planes[GalaxyMap.Layer.BACKGROUND][0] = 1
	map.planes[GalaxyMap.Layer.BACKGROUND][5] = 1
	map.planes[GalaxyMap.Layer.BACKGROUND][7] = 2
	var animator := GalaxyTileAnimator.for_map(map, info)
	assert_equal(animator.cycles().size(), 2, "one cycle per start tile")
	assert_equal(animator.advance(2).size(), 0, "nothing after 2 tics")
	var changed := animator.advance(2)
	assert_equal(changed.size(), 1, "tile 1 moves after 4 tics")
	assert_equal(changed[0].tile, 2, "to tile 2")
	assert_equal(changed[0].cells.size(), 2, "both cells that started with it")
	assert_equal(changed[0].time_left, BACK_TIMES[1], "with tile 2's time")
	assert_equal(animator.advance(2)[0].tile, 1, "the cycle that started on 2 moves at 6")


func test_loops_and_still_tiles() -> void:
	var info := _tile_info()
	assert_equal(
		GalaxyTileAnimator.loop_of(info, GalaxyMap.Layer.BACKGROUND, 1), BACK_LOOP, "the back loop"
	)
	assert_equal(
		GalaxyTileAnimator.loop_of(info, GalaxyMap.Layer.FOREGROUND, 6),
		PackedInt32Array([6, 5]),
		"a loop starts where it is"
	)
	assert_true(
		not GalaxyTileAnimator.is_animated(info, GalaxyMap.Layer.FOREGROUND, STILL_OFFSET_TILE),
		"an offset without a time does not move"
	)


func test_three_layers_and_set_tile() -> void:
	var level := _level_map()
	var map := level.map
	assert_equal(level.back_tile_at(Vector2i(0, 0)), 1, "background drawn")
	assert_equal(level.fore_tile_at(Vector2i(1, 0)), 5, "foreground behind the sprites")
	assert_equal(level.front_tile_at(Vector2i(2, 0)), FRONT_TILE, "bit 0x80: in front")
	assert_equal(level.fore_tile_at(Vector2i(2, 0)), -1, "not also behind")
	assert_equal(level.front_tile_at(Vector2i(3, 0)), -1, "tile 0 is nothing")
	level.animate(FORE_TIME)
	assert_equal(level.fore_tile_at(Vector2i(1, 0)), 6, "the foreground animates")
	assert_equal(map.tile(GalaxyMap.Layer.FOREGROUND, 1, 0), 6, "and the map knows")
	level.set_tile(GalaxyMap.Layer.FOREGROUND, Vector2i(1, 0), FRONT_TILE)
	assert_equal(level.front_tile_at(Vector2i(1, 0)), FRONT_TILE, "set_tile moves it in front")
	assert_equal(level.fore_tile_at(Vector2i(1, 0)), -1, "and off the layer behind")
	level.animate(FORE_TIME)
	assert_equal(level.front_tile_at(Vector2i(1, 0)), FRONT_TILE, "a set tile leaves its cycle")
	_free(level)


func test_set_tile_asks_for_missing_tiles() -> void:
	var level := _level_map()
	var asked: Array[int] = []
	level.tiles_missing.connect(func(layer: GalaxyMap.Layer) -> void: asked.append(layer))
	level.set_tile(GalaxyMap.Layer.BACKGROUND, Vector2i(4, 4), 7)
	assert_equal(asked, [GalaxyMap.Layer.BACKGROUND] as Array[int], "tile 7 is not in the atlas")
	assert_true(level.wanted_tiles(GalaxyMap.Layer.BACKGROUND).has(7), "now it is wanted")
	_free(level)


func test_atlas_holds_only_its_tiles() -> void:
	var images: Dictionary[int, Image] = {3: _image(Color.RED), 9: _image(Color.BLUE)}
	var atlas := GalaxyTileAtlas.build(images)
	assert_true(atlas.has(3) and atlas.has(9) and not atlas.has(4), "tiles 3 and 9")
	assert_equal(atlas.tile_at(atlas.coords_of(9)), 9, "cell back to tile")
	var big: Dictionary[int, Image] = {}
	for tile in images:
		big[tile] = _image(Color.WHITE, GalaxyTileAtlas.TILE_SIZE * 2)
	var scaled := GalaxyTileAtlas.build(images, big, 2)
	var source := scaled.tile_set.get_source(GalaxyTileAtlas.SOURCE_ID) as TileSetAtlasSource
	var plain := atlas.tile_set.get_source(GalaxyTileAtlas.SOURCE_ID) as TileSetAtlasSource
	assert_equal(source.texture.get_size(), plain.texture.get_size(), "scaled, drawn as large")
	assert_equal(source.texture.get_image().get_width(), plain.texture.get_width() * 2, "twice")


func test_camera_keeps_off_the_border() -> void:
	var camera := GalaxyCamera.for_map(MAP_SIZE)
	camera.reposition(Vector2i(-1000, -1000))
	assert_equal(camera.scroll, Vector2i(2, 2) * TILE, "the 2-tile border")
	camera.reposition(Vector2i(100000, 100000))
	assert_equal(camera.scroll, (MAP_SIZE - Vector2i(22, 15)) * TILE, "the far border")
	assert_equal(camera.view_pixels(), (MAP_SIZE - Vector2i(22, 15)) * 16, "in pixels")


func test_scroll_blocks_push_the_view() -> void:
	var camera := GalaxyCamera.for_map(MAP_SIZE, PackedInt32Array([24]))
	camera.reposition(Vector2i(15, 2) * TILE)
	assert_equal(camera.scroll.x, 25 * TILE, "a block in the left half: the view goes right of it")
	camera.reposition(Vector2i(8, 2) * TILE)
	assert_equal(camera.scroll.x, 4 * TILE, "a block in the right half: the view ends before it")
	camera.reposition(Vector2i(2, 2) * TILE)
	camera.smooth_scroll(Vector2i(200, 0))
	assert_equal(camera.scroll.x, 2 * TILE + 200, "free to scroll")
	camera.reposition(Vector2i(4, 2) * TILE)
	camera.smooth_scroll(Vector2i(10, 0))
	assert_equal(camera.scroll.x, 4 * TILE, "stops when the right edge reaches the block")


func test_row_blocks_stop_vertical_scrolling() -> void:
	var camera := GalaxyCamera.for_map(MAP_SIZE, PackedInt32Array(), PackedInt32Array([16]))
	camera.reposition(Vector2i(2, 2) * TILE)
	camera.smooth_scroll(Vector2i(0, 255))
	assert_equal(camera.scroll.y, 2 * TILE + 255, "free while the bottom edge is above row 16")
	camera.smooth_scroll(Vector2i(0, 255))
	assert_equal(camera.scroll.y, 3 * TILE, "13 rows: the bottom edge stops on row 16")
	assert_equal(camera.area_pixels(), Rect2i(32, 32, (MAP_SIZE.x - 4) * 16, 14 * 16), "area")


func test_centre_and_follow() -> void:
	var camera := GalaxyCamera.for_map(MAP_SIZE)
	var feet := 20 * TILE + 255
	camera.centre_on(15 * TILE, feet)
	assert_equal(camera.scroll, Vector2i(15 * TILE - 152 * UNITS, feet - 140 * UNITS), "152 / 140")
	var target := GalaxyCamera.Target.new()
	target.x = 15 * TILE
	target.feet = feet
	var before := camera.scroll
	camera.follow(target)
	assert_equal(camera.scroll, before, "a standing Keen in place moves nothing")
	target.x += 48 * UNITS
	camera.follow(target)
	assert_equal(camera.scroll.x, before.x + 8 * UNITS, "past 192 px the view follows")
	target.look = -1
	camera.follow(target)
	assert_equal(camera.feet_on_screen, 142, "looking up: 1 px a tic")
	target.look = 0
	target.grounded = false
	target.feet = camera.scroll.y + 20 * UNITS
	camera.follow(target)
	assert_equal(camera.scroll.y, target.feet - 32 * UNITS, "feet never above 33 px")
	assert_equal(camera.feet_on_screen, GalaxyCamera.FEET_REST, "in the air: back to 140")


func test_wide_view_stays_between_the_blocks() -> void:
	var camera := GalaxyCamera.for_map(MAP_SIZE, PackedInt32Array([24]))
	camera.reposition(Vector2i(2, 2) * TILE)
	assert_equal(camera.area_pixels().position.x, 32, "from the border")
	assert_equal(camera.area_pixels().end.x, 24 * 16, "to the block")
	assert_equal(camera.wide_view_left(320), 32, "4:3 as the original")
	assert_equal(camera.wide_view_left(352), 32, "wider: inside the area")
	assert_equal(camera.wide_view_left(400), 32 - 24, "wider than the area: centred on it")
	var cover := GalaxyViewCover.new()
	cover.cover(camera.area_pixels(), Rect2i(32, 32, 320, 200))
	assert_true(not cover.is_covering(), "4:3 is never covered")
	var strips := GalaxyViewCover.strips(camera.area_pixels(), Rect2i(8, 32, 400, 200))
	assert_equal(
		strips,
		[Rect2i(8, 32, 24, 200), Rect2i(384, 32, 24, 200)] as Array[Rect2i],
		"beyond the border and the block it is covered"
	)
	cover.free()


func test_sprites_by_priority() -> void:
	assert_equal(GalaxyObjectLayer.z_of(0), 1, "priority 0 over the tiles")
	assert_true(GalaxyObjectLayer.z_of(2) < GalaxyLevelMap.FRONT_Z, "2 under the front tiles")
	assert_true(GalaxyObjectLayer.z_of(3) > GalaxyLevelMap.FRONT_Z, "3 over them")
	var info := GalaxySpriteInfo.new()
	info.origin = Vector2i(0, 32)
	assert_equal(
		GalaxyObjectLayer.pixel_of(info, Vector2i(5 * TILE, 3 * TILE - 241)),
		Vector2i(80, 34),
		"position + origin, on the original's pixel"
	)
	var layer := GalaxyObjectLayer.new()
	var first := layer.add(0, Vector2i.ZERO, 1)
	var second := layer.add(0, Vector2i.ZERO, 1)
	assert_true(
		second.node.get_index() < first.node.get_index(), "the newest is drawn under the others"
	)
	layer.free()


func test_sprites_drawn_in_their_shift_steps() -> void:
	var info := GalaxySpriteInfo.new()
	info.origin = Vector2i(-16, 0)
	# Position + origin is pixel 87 and a bit: rounded down per shift count.
	var position := Vector2i(88 * UNITS + 5, 10 * UNITS)
	var drawn := PackedInt32Array()
	for shifts in [4, 2, 1, 0]:
		info.shifts = shifts
		drawn.append(GalaxyObjectLayer.pixel_of(info, position).x)
	assert_equal(drawn, PackedInt32Array([86, 84, 80, 87]), "steps of 2, 4, 8, 1 pixels")
	assert_equal(GalaxyObjectLayer.pixel_of(info, position).y, 10, "y on its whole pixel")
	info.shifts = 4
	assert_equal(
		GalaxyObjectLayer.pixel_of(info, Vector2i(-3 * UNITS, 0)).x, -4, "left of 0: down, too"
	)


func test_door_sprite_jumps_to_its_byte() -> void:
	# Keen walking (4 shifts) at pixel 94, then the door's sprite (1 shift,
	# same origin): the original draws it at 88, 6 pixels left (D8).
	var walking := GalaxySpriteInfo.new()
	walking.shifts = 4
	var door := GalaxySpriteInfo.new()
	door.shifts = 1
	var position := Vector2i(94 * UNITS + 9, 0)
	var jump := (
		GalaxyObjectLayer.pixel_of(walking, position).x
		- GalaxyObjectLayer.pixel_of(door, position).x
	)
	assert_equal(jump, 6, "6 pixels left into the door")


func test_view_pans_in_two_pixel_steps() -> void:
	var camera := GalaxyCamera.for_map(MAP_SIZE)
	var at := Vector2i(41 * UNITS + 15, 37 * UNITS + 3)
	camera.reposition(at)
	assert_equal(camera.view_pixels(), Vector2i(40, 37), "x to an even pixel, y whole")
	assert_equal(camera.scroll_pixels(), Vector2i(41, 37), "smooth motion: the whole pixel")
	assert_equal(camera.wide_view_left(320), 40, "4:3 in the original's step")
	assert_equal(camera.wide_view_left(320, true), 41, "smooth motion: exact")
	var lefts := PackedInt32Array()
	for step in 4:
		camera.smooth_scroll(Vector2i(UNITS, 0))
		lefts.append(camera.view_pixels().x)
	assert_equal(lefts, PackedInt32Array([42, 42, 44, 44]), "1 px a frame: 2 px every other")


func test_pictures_only_behind_sky() -> void:
	var map := _map()
	map.number = 3
	var pictures := GalaxyBackdropPictures.for_episode(null, "res://nowhere", [6, 7], 1, 17)
	assert_equal(pictures.sky_tile(map), -1, "no sky in the top row")
	for x in MAP_SIZE.x:
		map.planes[GalaxyMap.Layer.BACKGROUND][2 * MAP_SIZE.x + x] = 7
	assert_equal(pictures.sky_tile(map), 7, "sky in the first row the view shows")
	map.number = 0
	assert_equal(pictures.sky_tile(map), -1, "the world map is no level")
	var image := _image(Color.CYAN)
	image.fill_rect(Rect2i(4, 4, 8, 8), Color.RED)
	image.fill_rect(Rect2i(6, 6, 4, 4), Color.CYAN)
	var cleared := GalaxyBackdropPictures.cleared(image, Color.CYAN)
	assert_equal(cleared.get_pixel(0, 0).a, 0.0, "sky at the edge goes")
	assert_equal(cleared.get_pixel(7, 7), Color.CYAN, "sky inside a cloud stays")


func _tile_info() -> GalaxyTileInfo:
	var data := PackedByteArray()
	data.resize(GalaxyTileInfo.BACK_TABLES * BACK_TILES + GalaxyTileInfo.FORE_TABLES * FORE_TILES)
	var back_time := GalaxyTileInfo.Back.ANIMATION_TIME * BACK_TILES
	var back_offset := GalaxyTileInfo.Back.ANIMATION_OFFSET * BACK_TILES
	data[back_time + 1] = BACK_TIMES[0]
	data[back_time + 2] = BACK_TIMES[1]
	data[back_offset + 1] = 1
	data[back_offset + 2] = 0xFF
	var fore := GalaxyTileInfo.BACK_TABLES * BACK_TILES
	data[fore + GalaxyTileInfo.Fore.MISC * FORE_TILES + FRONT_TILE] = GalaxyTileInfo.IN_FRONT
	data[fore + GalaxyTileInfo.Fore.ANIMATION_OFFSET * FORE_TILES + STILL_OFFSET_TILE] = 2
	data[fore + GalaxyTileInfo.Fore.ANIMATION_OFFSET * FORE_TILES + 5] = 1
	data[fore + GalaxyTileInfo.Fore.ANIMATION_OFFSET * FORE_TILES + 6] = 0xFF
	data[fore + GalaxyTileInfo.Fore.ANIMATION_TIME * FORE_TILES + 5] = FORE_TIME
	data[fore + GalaxyTileInfo.Fore.ANIMATION_TIME * FORE_TILES + 6] = FORE_TIME
	return GalaxyTileInfo.parse(data, BACK_TILES, FORE_TILES)


func _map() -> GalaxyMap:
	var map := GalaxyMap.new()
	map.width = MAP_SIZE.x
	map.height = MAP_SIZE.y
	for layer in GalaxyMap.PLANE_COUNT:
		var plane := PackedInt32Array()
		plane.resize(MAP_SIZE.x * MAP_SIZE.y)
		map.planes.append(plane)
	return map


## A level map of [method _map] with tile 1 at (0, 0), the animated tile 5
## at (1, 0) and the in-front tile at (2, 0).
func _level_map() -> GalaxyLevelMap:
	var info := _tile_info()
	var map := _map()
	map.planes[GalaxyMap.Layer.BACKGROUND][0] = 1
	map.planes[GalaxyMap.Layer.FOREGROUND][1] = 5
	map.planes[GalaxyMap.Layer.FOREGROUND][2] = FRONT_TILE
	var level := GalaxyLevelMap.new()
	level.show_map(
		map,
		info,
		_atlas_for(GalaxyLevelMap.tiles_of(map, info, GalaxyMap.Layer.BACKGROUND)),
		_atlas_for(GalaxyLevelMap.tiles_of(map, info, GalaxyMap.Layer.FOREGROUND))
	)
	return level


func _atlas_for(tiles: PackedInt32Array) -> GalaxyTileAtlas:
	var images: Dictionary[int, Image] = {}
	for tile in tiles:
		images[tile] = _image(Color(tile / 10.0, 0.5, 0.5))
	return GalaxyTileAtlas.build(images)


func _image(color: Color, size := GalaxyTileAtlas.TILE_SIZE) -> Image:
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image


func _free(node: Node) -> void:
	node.free()
