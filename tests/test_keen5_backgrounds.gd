extends "res://tests/test_case.gd"
## Tests for milestone E10: the pictures behind Keen 5's levels and its
## world map ([Keen5BackdropPictures], [Keen5OpenSky]; painted by
## tools/make_keen5_backgrounds.py). Without files: the pictures in
## assets/backgrounds/keen5 are exactly those of maps 0, 1, 3, 4, 6, 10,
## 11, 12 and 13 and cover the widescreen view; a tile that is mostly sky
## loses all its sky at the edge, another one only the wide parts (not a
## hazard stripe); on made-up maps a door's black inside keeps its colour
## while a window with stars and the space at the map's edge show the
## picture; which maps may show one; the player's own picture wins. With
## the player's files: the real maps that get a picture, the star tiles,
## and Keen 5's screen: a door keeps its black and a window shows the
## picture in level 4, nothing behind the 4:3 picture and nothing with the
## option off, the world map's space beyond the station's star field shows
## the picture (black with the option off), and since E12 the broken QED's
## tiles keep their black. The screen tests need a running
## scene tree; settings go to a folder of their own, removed afterwards.

## The maps with open space or sky (docs/keen5/gameplay.md, "Pictures
## behind the levels").
const PICTURE_MAPS: PackedInt32Array = [0, 1, 3, 4, 6, 10, 11, 12, 13]
## Maps 0 (the world map) to 15 (the high scores).
const MAP_COUNT := 16
const WIDESCREEN := 16.0 / 9.0
const TILE := 16
const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const TEST_DIRECTORY := "user://test_keen5_backgrounds"
const FRAME_SECONDS := 1.0 / 35.0
const QUEUE_FRAMES := 400
## Level 4 (files): the inside of the door at the bottom left, and a
## window with stars.
const DOOR_LEVEL := 4
const DOOR_CELL := Vector2i(6, 54)
const WINDOW_CELL := Vector2i(40, 25)
## The world map (files): a cell of the yellow filler beyond the star
## field (back tile 850 in the file, black since E6).
const FILLER_CELL := Vector2i(3, 3)
const FILLER_TILE := 850
## The level of the QED (E12: its broken tiles keep their black).
const QED_LEVEL := 12
## Made-up tiles for the maps without files: plain black space, a star
## tile, a door frame (foreground, all solid).
const SPACE := 0
const STARS := 1
const SOLID := 2
const MADE_UP_SIZE := Vector2i(16, 12)

var _data: GalaxyData
var _files: GameFiles
var _view: Keen5View
var _tree: SceneTree


func _init() -> void:
	# Not skipped without the files: the pictures and the rules are ours.
	_files = Keen5Files.locate()
	if _files != null:
		_data = Keen5Episode.load_data(_files)
	_tree = Engine.get_main_loop() as SceneTree


func run_all() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY.path_join(BackdropPictures.PLAYER_FOLDER))
	KeyBindings.reset()
	super.run_all()
	_free_view()
	var folder := TEST_DIRECTORY.path_join(BackdropPictures.PLAYER_FOLDER)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder.path_join("level01.png")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
	DirAccess.remove_absolute(
		ProjectSettings.globalize_path(TEST_DIRECTORY.path_join("settings.cfg"))
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


# --- Our pictures ----------------------------------------------------------


func test_the_folder_holds_the_pictures_of_exactly_those_maps() -> void:
	var expected := PackedStringArray()
	for number in PICTURE_MAPS:
		expected.append(BackdropPictures.picture_name(number) + ".webp")
	var found := PackedStringArray()
	for file_name in DirAccess.get_files_at(Keen5Episode.BACKDROP_FOLDER):
		if file_name.get_extension() in BackdropPictures.EXTENSIONS:
			found.append(file_name)
	found.sort()
	assert_equal(found, expected, "the pictures in %s" % Keen5Episode.BACKDROP_FOLDER)


func test_every_picture_is_wide_enough_for_widescreen() -> void:
	var pictures := _pictures(null)
	for number in PICTURE_MAPS:
		var picture := pictures.picture(number)
		assert_true(picture != null, "map %d's picture loads" % number)
		if picture != null:
			var size := picture.get_size()
			assert_true(size.x >= size.y * WIDESCREEN, "map %d's picture is 16:9 or wider" % number)


func test_the_players_own_picture_wins() -> void:
	var image := Image.create_empty(64, 36, false, Image.FORMAT_RGB8)
	image.fill(Color.RED)
	image.save_png(
		TEST_DIRECTORY.path_join(BackdropPictures.PLAYER_FOLDER).path_join("level01.png")
	)
	var files := GameFiles.new()
	files.directory = ProjectSettings.globalize_path(TEST_DIRECTORY)
	var picture := _pictures(files).picture(1)
	assert_equal(picture.get_size(), Vector2(64, 36), "the player's level01.png")
	assert_true(_pictures(files).picture(3).get_size().x > 64, "our own for level 3")


# --- Which pixels may show it (made-up tiles) -------------------------------


func test_a_tile_of_space_loses_all_its_black_at_the_edge() -> void:
	var tile := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	tile.fill(Color.BLACK)
	tile.set_pixel(5, 5, Color.WHITE)
	tile.set_pixel(1, 0, Color.WHITE)
	var cleared := Keen5OpenSky.cleared(tile, Color.BLACK)
	assert_equal(_clear_pixels(cleared), TILE * TILE - 2, "all black, the stars stay")


func test_hazard_stripes_keep_their_black() -> void:
	var tile := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	for y in TILE:
		for x in TILE:
			var black := (x + y) % 6 < 3
			tile.set_pixel(x, y, Color.BLACK if black else Color.YELLOW)
	assert_equal(_clear_pixels(Keen5OpenSky.cleared(tile, Color.BLACK)), 0, "stripes are narrow")


func test_a_wide_part_of_space_in_a_drawn_tile_is_cleared() -> void:
	# A pipe's end on space: the left 6 columns are space, the rest the
	# pipe with a thin black line in it.
	var tile := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
	tile.fill(Color.CYAN)
	tile.fill_rect(Rect2i(0, 0, 6, TILE), Color.BLACK)
	tile.fill_rect(Rect2i(10, 0, 1, TILE), Color.BLACK)
	assert_equal(_clear_pixels(Keen5OpenSky.cleared(tile, Color.BLACK)), 6 * TILE, "the space only")


func test_a_door_keeps_its_black_and_a_window_shows_the_picture() -> void:
	var map := _made_up_map()
	# A door: 2 x 2 cells of plain black shut in by its frame.
	_frame(map, Rect2i(3, 3, 2, 2))
	# A window: 2 x 2 cells with a star tile in it, also framed.
	_frame(map, Rect2i(9, 3, 2, 2))
	_put(map, GalaxyMap.Layer.BACKGROUND, Vector2i(10, 4), STARS)
	var rows := _closed(map)
	assert_true(_covers(rows, Vector2i(3, 3)), "the door's inside keeps its colour")
	assert_true(not _covers(rows, Vector2i(9, 3)), "the window's inside shows the picture")
	assert_true(not _covers(rows, Vector2i(7, 8)), "the space around shows the picture")


func test_space_along_the_maps_edge_is_open_without_stars() -> void:
	var map := _made_up_map()
	_frame(map, Rect2i(4, 4, 4, 3))
	var rows := _closed(map)
	assert_true(not _covers(rows, Vector2i(2, 2)), "beside the border: the outside")
	assert_true(_covers(rows, Vector2i(5, 5)), "the black room inside the frame")


func test_which_maps_may_show_a_picture() -> void:
	var pictures := _pictures(null)
	var map := _made_up_map()
	assert_equal(pictures.sky_tile(map), Keen5Episode.SPACE_TILE, "space at the edge: level 1")
	map.number = Keen5Episode.WORLD_MAP
	assert_equal(pictures.sky_tile(map), Keen5Episode.SPACE_TILE, "the world map")
	map.number = Keen5Episode.HIGH_SCORE_MAP
	assert_equal(pictures.sky_tile(map), -1, "the high scores")
	var doors := _made_up_map()
	for y in MADE_UP_SIZE.y:
		for x in MADE_UP_SIZE.x:
			if not Rect2i(4, 4, 2, 2).has_point(Vector2i(x, y)):
				_put(doors, GalaxyMap.Layer.FOREGROUND, Vector2i(x, y), SOLID)
	assert_equal(pictures.sky_tile(doors), -1, "only a door's black: no picture")
	_put(doors, GalaxyMap.Layer.BACKGROUND, Vector2i(4, 4), Keen5Episode.OPEN_SKY_TILES[1])
	assert_equal(pictures.sky_tile(doors), Keen5Episode.SPACE_TILE, "a window with stars")


# --- With the player's files -------------------------------------------------


func test_the_real_maps_with_a_picture() -> void:
	if _data == null:
		return  # Needs the player's maps (game_data/keen5).
	var pictures := _pictures(null)
	var shown := PackedInt32Array()
	for number in MAP_COUNT:
		if _data.maps.has_map(number) and pictures.picture_for(_world_or_map(number)) != null:
			shown.append(number)
	assert_equal(shown, PICTURE_MAPS, "the maps that show a picture")
	assert_equal(
		pictures.sky_tile(_data.maps.load_map(13)), Keen5Episode.KORATH_SKY_TILE, "Korath's sky"
	)


func test_the_star_tiles_are_space() -> void:
	if _data == null:
		return
	for tile in Keen5Episode.OPEN_SKY_TILES:
		var image := _data.graphics.back_tile(tile)
		if tile == Keen5Episode.KORATH_SKY_TILE:
			assert_equal(_count(image, image.get_pixel(0, 0)), TILE * TILE, "105 is plain")
			continue
		var black := _count(image, Color.BLACK)
		assert_true(black >= 224 and black < TILE * TILE, "tile %d: stars on black" % tile)
	var space := _data.graphics.back_tile(Keen5Episode.SPACE_TILE)
	assert_equal(_count(space, Color.BLACK), TILE * TILE, "tile 0 is all black")


func test_level_4s_door_keeps_its_black_and_its_window_shows_the_picture() -> void:
	if not _can_show():
		return
	_create_view(DisplaySettings.Aspect.WIDESCREEN)
	_view._show_level(DOOR_LEVEL)
	_run_queue()
	assert_true(_view._backdrop_picture != null, "a picture behind level 4")
	var rows: Array[Rect2i] = _view._sky_patch.rows()
	assert_true(_covers(rows, DOOR_CELL), "the door's inside stays black")
	assert_true(not _covers(rows, WINDOW_CELL), "the window shows the picture")


func test_nothing_behind_the_4_3_picture() -> void:
	if not _can_show():
		return
	_create_view(DisplaySettings.Aspect.ORIGINAL)
	_view._show_level(1)
	_run_queue()
	_assert_no_picture("4:3")


func test_nothing_with_the_option_off() -> void:
	if not _can_show():
		return
	_create_view(DisplaySettings.Aspect.WIDESCREEN)
	_view._settings.backgrounds = false
	_view._apply_display_settings()
	_view._show_level(1)
	_run_queue()
	_assert_no_picture("Backgrounds off")


func test_the_broken_qed_keeps_its_black() -> void:
	if not _can_show():
		return
	for aspect: DisplaySettings.Aspect in [
		DisplaySettings.Aspect.WIDESCREEN, DisplaySettings.Aspect.ORIGINAL
	]:
		_create_view(aspect)
		_view._show_level(QED_LEVEL)
		_run_queue()
		var world := _view._played.world
		var qed: Keen5Qed = null
		for object in world.objects:
			if object is Keen5Qed:
				qed = object
		assert_true(qed != null, "the QED is in level 12")
		qed.hit_by_piece(null)
		var rows: Array[Rect2i] = _view._sky_patch.rows()
		var wide: bool = aspect == DisplaySettings.Aspect.WIDESCREEN
		for y in Keen5Qed.BLOCK_SIZE.y * 2:
			for x in Keen5Qed.BLOCK_SIZE.x:
				var cell := Keen5Qed.UPPER_TO + Vector2i(x, y)
				if wide:
					assert_true(_covers(rows, cell), "the broken QED's cell %s stays black" % cell)
		if not wide:
			_assert_no_picture("4:3, the QED broken")


func test_the_world_maps_space_shows_the_picture() -> void:
	if not _can_show():
		return
	_create_view(DisplaySettings.Aspect.WIDESCREEN)
	_view._show_level(Keen5Episode.WORLD_MAP)
	_run_queue()
	assert_true(_view._backdrop_picture != null, "a picture behind the world map")
	var map := _view._map
	var filler := map.tile(GalaxyMap.Layer.BACKGROUND, FILLER_CELL.x, FILLER_CELL.y)
	assert_equal(filler, Keen5Episode.SPACE_TILE, "the filler is space")
	var rows: Array[Rect2i] = _view._sky_patch.rows()
	assert_true(not _covers(rows, FILLER_CELL), "and shows the picture")
	_view._settings.backgrounds = false
	_view._apply_display_settings()
	assert_true(_view._backdrop_picture == null, "off: no picture")
	assert_true(not _view._sky_patch.visible, "off: the space is black again")


# --- Helpers -----------------------------------------------------------------


func _pictures(files: GameFiles) -> GalaxyGameBackdrops:
	return Keen5Episode.make_backdrops(files, Keen5Episode.game_rules())


## Map [param number], the world map with its filler as the game shows it.
func _world_or_map(number: int) -> GalaxyMap:
	var map := _data.maps.load_map(number)
	if number == Keen5Episode.WORLD_MAP:
		var plane := map.planes[GalaxyMap.Layer.BACKGROUND]
		for index in plane.size():
			if plane[index] == FILLER_TILE and index / map.width <= Keen5MapSession.KORATH_ROW:
				plane[index] = Keen5Episode.SPACE_TILE
	return map


## A level (1) of plain space with a solid border of two tiles.
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


## A solid frame of foreground tiles around [param inside].
func _frame(map: GalaxyMap, inside: Rect2i) -> void:
	var outer := inside.grow(1)
	for y in range(outer.position.y, outer.end.y):
		for x in range(outer.position.x, outer.end.x):
			if not inside.has_point(Vector2i(x, y)):
				_put(map, GalaxyMap.Layer.FOREGROUND, Vector2i(x, y), SOLID)


func _put(map: GalaxyMap, layer: GalaxyMap.Layer, cell: Vector2i, tile: int) -> void:
	map.planes[layer][cell.y * map.width + cell.x] = tile


## The made-up maps' see-through pixels that keep their colour.
func _closed(map: GalaxyMap) -> Array[Rect2i]:
	var back_image := func(tile: int) -> Image:
		var image := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
		image.fill(Color.BLACK)
		if tile == STARS:
			image.set_pixel(7, 7, Color.WHITE)
		return Keen5OpenSky.cleared(image, Color.BLACK)
	var fore_image := func(tile: int) -> Image:
		var image := Image.create_empty(TILE, TILE, false, Image.FORMAT_RGBA8)
		image.fill(Color.GRAY if tile == SOLID else Color.TRANSPARENT)
		return image
	return Keen5OpenSky.closed(map, back_image, fore_image, PackedInt32Array([STARS]))


static func _covers(rows: Array[Rect2i], cell: Vector2i) -> bool:
	var area := Rect2i(cell * TILE, Vector2i(TILE, TILE))
	for row in rows:
		if area.encloses(row):
			return true
	return false


static func _clear_pixels(image: Image) -> int:
	return _count(image, Color.TRANSPARENT)


static func _count(image: Image, color: Color) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).is_equal_approx(color):
				count += 1
	return count


func _can_show() -> bool:
	return _data != null and _tree != null and _tree.root.is_inside_tree()


func _assert_no_picture(what: String) -> void:
	assert_true(_view._backdrop_picture == null, "%s: no picture" % what)
	assert_true(_view._sky_color.a == 0.0, "%s: the tiles keep their black" % what)
	assert_true(not _view._sky_patch.visible, "%s: nothing painted" % what)


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
