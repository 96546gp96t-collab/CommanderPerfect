extends "res://tests/test_case.gd"
## Tests for E12.1, the fixes to the pictures behind Keen 5's levels after
## the user's test in widescreen ([GalaxyRevealedSky], [Keen5OpenSky],
## tools/make_keen5_backgrounds.py). Without files: a revealed part shows
## the picture when it is joined to it and keeps the sky's colour when shut
## in; a cloud on Korath III's sky loses all of its sky, also in its curls,
## and counts as open sky; a pole in front of a window does not shut the
## strip beside it off, while an item's dark inside stays dark; the world
## map's picture has no stars. With the player's files (on the screen): a
## vial taken over Korath III's sky and an item taken in level 11's window
## leave the picture (E12 painted the whole cell in the sky's colour),
## Korath III's cloud tiles keep no sky, the strip beside the pole in
## level 12's window shows the picture, and nothing changes in 4:3.

const TILE := 16
const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const TEST_DIRECTORY := "user://test_keen5_picture_fixes"
const FRAME_SECONDS := 1.0 / 35.0
const QUEUE_FRAMES := 400
## Made-up tiles: space, stars, a solid frame, a pole, an item with a dark
## inside.
const SPACE := 0
const STARS := 1
const SOLID := 2
const POLE := 3
const ITEM := 4
const MADE_UP_SIZE := Vector2i(16, 12)
## The world map's picture (ours) and where its galaxy and moon are, in
## the painter's small pixels (tools/make_keen5_backgrounds.py, level00).
const WORLD_PICTURE := "res://assets/backgrounds/keen5/level00.webp"
const PAINT_SCALE := 5
const GALAXY_BOX := Rect2i(232, 40, 90, 52)
const MOON_BOX := Rect2i(68, 38, 18, 18)
## Brighter than this in any channel is a star (the space, the nebula and
## the glow stay darker).
const STAR_LEVEL := 0.4
## Files: a vial over Korath III's sky (level 13), an item in level 11's
## window over a star tile, the strip beside the pole in level 12's window,
## Korath III's cloud tiles.
const VIAL_LEVEL := 13
const VIAL_CELL := Vector2i(35, 83)
const WINDOW_LEVEL := 11
const WINDOW_ITEM_CELL := Vector2i(40, 39)
const POLE_LEVEL := 12
const POLE_STRIP_CELL := Vector2i(18, 47)
const CLOUD_TILES: Array[int] = [721, 722, 723, 724, 725, 726, 727, 728, 729, 730, 731, 732]

var _data: GalaxyData
var _files: GameFiles
var _view: Keen5View
var _tree: SceneTree


func _init() -> void:
	_files = Keen5Files.locate()
	if _files != null:
		_data = Keen5Episode.load_data(_files)
	_tree = Engine.get_main_loop() as SceneTree


func run_all() -> void:
	KeyBindings.reset()
	super.run_all()
	_free_view()
	DirAccess.remove_absolute(
		ProjectSettings.globalize_path(TEST_DIRECTORY.path_join("settings.cfg"))
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


# --- Without files -----------------------------------------------------------


func test_a_revealed_part_joined_to_the_picture_shows_it() -> void:
	var mask := _full_mask()
	var showed := func(index: int) -> bool: return index == 0
	var shows := func(_pixel: Vector2i) -> bool: return false
	var rows := GalaxyRevealedSky.kept_rows(Vector2i(3, 2), mask, showed, shows)
	assert_true(rows.is_empty(), "joined to what showed the picture before")
	showed = func(_index: int) -> bool: return false
	shows = func(pixel: Vector2i) -> bool: return pixel == Vector2i(3 * TILE - 1, 2 * TILE + 5)
	rows = GalaxyRevealedSky.kept_rows(Vector2i(3, 2), mask, showed, shows)
	assert_true(rows.is_empty(), "joined across the side to the picture")


func test_a_revealed_part_shut_in_keeps_the_sky_colour() -> void:
	var nothing := func(_value: Variant) -> bool: return false
	var rows := GalaxyRevealedSky.kept_rows(Vector2i(3, 2), _full_mask(), nothing, nothing)
	assert_equal(_pixels(rows), TILE * TILE, "the whole cell keeps its colour")
	assert_equal(rows[0].position, Vector2i(3, 2) * TILE, "in level pixels")


func test_a_cloud_loses_all_of_its_sky() -> void:
	var sky := Color(1.0 / 3.0, 1.0, 1.0)
	var cloud := _cloud_tile(sky)
	assert_true(Keen5OpenSky.is_clouds(cloud, sky), "sky and cloud colours only")
	var cleared := Keen5OpenSky.cleared(cloud, sky)
	assert_equal(_count(cleared, sky), 0, "the sky in its curl goes too")
	assert_true(Keen5OpenSky.is_cleared_clouds(cleared), "it is a cloud cleared")
	var drawn := cloud.duplicate() as Image
	drawn.set_pixel(0, 0, Color.RED)
	assert_true(not Keen5OpenSky.is_clouds(drawn, sky), "another colour: no cloud")


func test_a_cloud_counts_as_open_sky() -> void:
	var map := _made_up_map()
	var inside := Rect2i(5, 4, 3, 3)
	_frame(map, inside)
	for y in range(inside.position.y, inside.end.y):
		for x in range(inside.position.x, inside.end.x):
			_put(map, GalaxyMap.Layer.BACKGROUND, Vector2i(x, y), SPACE)
	_put(map, GalaxyMap.Layer.BACKGROUND, Vector2i(6, 5), ITEM)
	var sky := Color(1.0 / 3.0, 1.0, 1.0)
	var back_image := func(tile: int) -> Image:
		if tile == ITEM:
			return Keen5OpenSky.cleared(_cloud_tile(sky), sky)
		var image := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT if tile == SPACE else Color.GRAY)
		return image
	var rows := Keen5OpenSky.closed(map, back_image, _fore_image(), PackedInt32Array())
	assert_true(rows.is_empty(), "the box with a cloud in it is open sky")


func test_a_pole_does_not_shut_off_the_strip_beside_it() -> void:
	var map := _window_with_a_pole()
	var strip := Vector2i(5, 5)
	var rows := _closed(map, Callable())
	assert_true(_pixels_in(rows, strip) > 0, "the bug: the strip keeps its black")
	rows = _closed(map, func(tile: int) -> bool: return tile == POLE)
	assert_equal(_pixels_in(rows, strip), 0, "the strip beside the pole shows the picture")
	assert_equal(_pixels_in(rows, Vector2i(8, 5)), 0, "and the window beside it")


func test_an_items_dark_inside_stays_dark() -> void:
	var map := _window_with_a_pole()
	_put(map, GalaxyMap.Layer.FOREGROUND, Vector2i(8, 6), ITEM)
	var rows := _closed(map, func(tile: int) -> bool: return tile == POLE)
	assert_equal(_pixels_in(rows, Vector2i(8, 6)), 4, "the 2x2 inside of the item")


func test_the_world_maps_picture_has_no_stars() -> void:
	var image := (load(WORLD_PICTURE) as Texture2D).get_image()
	image.decompress()
	var stars := 0
	for y in range(0, image.get_height(), PAINT_SCALE):
		for x in range(0, image.get_width(), PAINT_SCALE):
			var small := Vector2i(x, y) / PAINT_SCALE
			if GALAXY_BOX.has_point(small) or MOON_BOX.has_point(small):
				continue
			var pixel := image.get_pixel(x, y)
			if maxf(pixel.r, maxf(pixel.g, pixel.b)) > STAR_LEVEL:
				stars += 1
	assert_equal(stars, 0, "no star beside the galaxy and the moon")


# --- With files, on the screen -----------------------------------------------


func test_a_vial_taken_over_korath_leaves_the_picture() -> void:
	if not _can_show():
		return
	_create_view(DisplaySettings.Aspect.WIDESCREEN)
	_view._show_level(VIAL_LEVEL)
	_run_queue()
	_take(VIAL_CELL)
	assert_equal(_view._map.tile(GalaxyMap.Layer.FOREGROUND, VIAL_CELL.x, VIAL_CELL.y), 0, "taken")
	assert_equal(_pixels_in(_view._sky_patch.rows(), VIAL_CELL), 0, "no square of sky")


func test_an_item_taken_in_a_window_leaves_the_picture() -> void:
	if not _can_show():
		return
	_create_view(DisplaySettings.Aspect.WIDESCREEN)
	_view._show_level(WINDOW_LEVEL)
	_run_queue()
	var back := _view._map.tile(GalaxyMap.Layer.BACKGROUND, WINDOW_ITEM_CELL.x, WINDOW_ITEM_CELL.y)
	assert_true(Keen5Episode.OPEN_SKY_TILES.has(back), "a star tile behind the item")
	_take(WINDOW_ITEM_CELL)
	assert_equal(_pixels_in(_view._sky_patch.rows(), WINDOW_ITEM_CELL), 0, "no black square")


func test_korath_iiis_clouds_keep_no_sky() -> void:
	if not _can_show():
		return
	_create_view(DisplaySettings.Aspect.WIDESCREEN)
	_view._show_level(VIAL_LEVEL)
	_run_queue()
	for tile in CLOUD_TILES:
		var image := _data.graphics.back_tile(tile)
		assert_true(Keen5OpenSky.is_clouds(image, _view._sky_color), "%d is a cloud" % tile)
		assert_equal(_count(_view._cleared(tile, image), _view._sky_color), 0, "%d" % tile)
	var map := _view._map
	var rows: Array[Rect2i] = _view._sky_patch.rows()
	for y in map.height:
		for x in map.width:
			var bare := map.tile(GalaxyMap.Layer.FOREGROUND, x, y) == 0
			if bare and CLOUD_TILES.has(map.tile(GalaxyMap.Layer.BACKGROUND, x, y)):
				assert_equal(_pixels_in(rows, Vector2i(x, y)), 0, "cloud at %d, %d" % [x, y])


func test_the_strip_beside_a_pole_in_a_window_shows_the_picture() -> void:
	if not _can_show():
		return
	_create_view(DisplaySettings.Aspect.WIDESCREEN)
	_view._show_level(POLE_LEVEL)
	_run_queue()
	var fore := _view._map.tile(GalaxyMap.Layer.FOREGROUND, POLE_STRIP_CELL.x, POLE_STRIP_CELL.y)
	assert_equal(_data.tile_info.misc_kind(fore), GalaxyTileKinds.POLE, "a pole in front")
	assert_equal(_pixels_in(_view._sky_patch.rows(), POLE_STRIP_CELL), 0, "beside it the picture")


func test_nothing_in_4_3_when_an_item_is_taken() -> void:
	if not _can_show():
		return
	_create_view(DisplaySettings.Aspect.ORIGINAL)
	_view._show_level(VIAL_LEVEL)
	_run_queue()
	_take(VIAL_CELL)
	assert_true(_view._backdrop_picture == null, "no picture")
	assert_true(not _view._sky_patch.visible, "nothing painted")


# --- Helpers -------------------------------------------------------------------


func _take(cell: Vector2i) -> void:
	var world := _view._played.world
	var kind := world.misc_of(world.fore_tile(cell.x, cell.y))
	assert_true(
		kind == GalaxyTileKinds.DROP or GalaxyTileKinds.is_item(kind), "an item at %s" % cell
	)
	world.set_fore_tile(cell, GalaxyTileKinds.EMPTY_TILE)


static func _full_mask() -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(TILE * TILE)
	mask.fill(1)
	return mask


## A cloud on [param sky]: magenta with a pocket of sky in its curl, the
## sky around it, a dark cyan edge.
static func _cloud_tile(sky: Color) -> Image:
	var image := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	image.fill(sky)
	image.fill_rect(Rect2i(2, 4, 12, 8), Keen5OpenSky.CLOUD_COLORS[1])
	image.fill_rect(Rect2i(6, 6, 3, 3), sky)
	image.set_pixel(2, 3, Keen5OpenSky.CLOUD_COLORS[0])
	return image


## A window (cells 5-9 by 4-7) in a solid frame: plain black in column 5
## (no stars: not open by itself, as the inside of a frame's corner tile),
## stars in the others, a pole in front of column 6 from top to bottom.
## Left of the pole the black of column 5 and the strip of column 6 are
## joined to nothing open but through the pole's cells.
func _window_with_a_pole() -> GalaxyMap:
	var map := _made_up_map()
	var inside := Rect2i(5, 4, 5, 4)
	_frame(map, inside)
	for y in range(inside.position.y, inside.end.y):
		for x in range(inside.position.x, inside.end.x):
			_put(map, GalaxyMap.Layer.BACKGROUND, Vector2i(x, y), STARS if x > 5 else SPACE)
		_put(map, GalaxyMap.Layer.FOREGROUND, Vector2i(6, y), POLE)
	return map


func _closed(map: GalaxyMap, is_pole: Callable) -> Array[Rect2i]:
	var back_image := func(tile: int) -> Image:
		var image := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
		image.fill(Color.BLACK)
		if tile == STARS:
			image.set_pixel(7, 7, Color.WHITE)
		return Keen5OpenSky.cleared(image, Color.BLACK)
	return Keen5OpenSky.closed(
		map, back_image, _fore_image(), PackedInt32Array([STARS]), PackedInt32Array(), is_pole
	)


## Foreground tiles: solid; a pole (a bar in the middle of the cell); an
## item (a ring with a dark 2x2 inside).
static func _fore_image() -> Callable:
	return func(tile: int) -> Image:
		var image := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		match tile:
			SOLID:
				image.fill(Color.GRAY)
			POLE:
				image.fill_rect(Rect2i(6, 0, 4, TILE), Color.YELLOW)
			ITEM:
				image.fill_rect(Rect2i(4, 4, 4, 4), Color.GREEN)
				image.fill_rect(Rect2i(5, 5, 2, 2), Color.TRANSPARENT)
		return image


func _made_up_map() -> GalaxyMap:
	var map := GalaxyMap.new()
	map.number = 1
	map.width = MADE_UP_SIZE.x
	map.height = MADE_UP_SIZE.y
	for layer in GalaxyMap.PLANE_COUNT:
		var plane := PackedInt32Array()
		plane.resize(MADE_UP_SIZE.x * MADE_UP_SIZE.y)
		map.planes.append(plane)
	var inner := Rect2i(2, 2, MADE_UP_SIZE.x - 4, MADE_UP_SIZE.y - 4)
	for y in MADE_UP_SIZE.y:
		for x in MADE_UP_SIZE.x:
			if not inner.has_point(Vector2i(x, y)):
				_put(map, GalaxyMap.Layer.FOREGROUND, Vector2i(x, y), SOLID)
	return map


func _frame(map: GalaxyMap, inside: Rect2i) -> void:
	var outer := inside.grow(1)
	for y in range(outer.position.y, outer.end.y):
		for x in range(outer.position.x, outer.end.x):
			if not inside.has_point(Vector2i(x, y)):
				_put(map, GalaxyMap.Layer.FOREGROUND, Vector2i(x, y), SOLID)


func _put(map: GalaxyMap, layer: GalaxyMap.Layer, cell: Vector2i, tile: int) -> void:
	map.planes[layer][cell.y * map.width + cell.x] = tile


static func _pixels(rows: Array[Rect2i]) -> int:
	var count := 0
	for row in rows:
		count += row.size.x * row.size.y
	return count


static func _pixels_in(rows: Array[Rect2i], cell: Vector2i) -> int:
	var area := Rect2i(cell * TILE, Vector2i(TILE, TILE))
	var count := 0
	for row in rows:
		var inside := row.intersection(area)
		count += inside.size.x * inside.size.y
	return count


static func _count(image: Image, color: Color) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0 and pixel.is_equal_approx(color):
				count += 1
	return count


func _can_show() -> bool:
	return _data != null and _tree != null and _tree.root.is_inside_tree()


func _create_view(aspect: DisplaySettings.Aspect) -> void:
	_free_view()
	var scene := load(VIEW_SCENE) as PackedScene
	_view = scene.instantiate() as Keen5View
	_tree.root.add_child(_view)
	_view._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_view._settings.aspect = aspect
	_view._settings.backgrounds = true
	_view._apply_display_settings()
	_view._new_game()
	_run_queue()


func _free_view() -> void:
	if _view != null:
		_view.get_parent().remove_child(_view)
		_view.free()
		_view = null


func _run_queue() -> void:
	for frame in QUEUE_FRAMES:
		if not _view.shows_message():
			return
		_view._process(FRAME_SECONDS)
