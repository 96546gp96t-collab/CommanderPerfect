extends "res://tests/test_case.gd"
## Tests for the pictures behind the levels: which tile is a level's plain
## background, the background color left out of the tiles (and only where
## it touches the edge), where the picture goes as the view moves, the
## setting (on by default, only in widescreen), the option in the menu, and
## finding the pictures (the player's own folder wins).

const Fixtures := preload("res://tests/fixtures.gd")
const TEST_DIRECTORY := "user://test_backdrops"
const VIEW := Vector2(426, 200)
const PICTURE := Vector2(1536, 1024)
## Mostly air (tile 0), with a wall floor and a few lollipops.
const FIELD: PackedStringArray = [
	"..............................",
	"......o.......o...............",
	"..............................",
	"##############################",
]


func run_all() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY.path_join(BackdropPictures.PLAYER_FOLDER))
	super.run_all()
	var folder := TEST_DIRECTORY.path_join(BackdropPictures.PLAYER_FOLDER)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder.path_join("level07.png")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_background_tile_is_the_plain_one_used_most() -> void:
	var tiles := Fixtures.create_graphics().tiles
	var tile := BackdropPictures.background_tile(
		Fixtures.create_level(FIELD), Fixtures.create_properties(), tiles
	)
	assert_equal(tile, Fixtures.AIR, "the air, not the wall or the items")


func test_no_background_tile_when_nothing_is_plain() -> void:
	var graphics := Fixtures.create_graphics()
	graphics.tiles[Fixtures.AIR].set_pixel(3, 3, Color.RED)
	var tile := BackdropPictures.background_tile(
		Fixtures.create_level(FIELD), Fixtures.create_properties(), graphics.tiles
	)
	assert_equal(tile, -1, "a tile with a dot on it is not plain; the walls are solid")


func test_background_color_is_left_out_only_around_things() -> void:
	var graphics := Fixtures.create_graphics()
	var gray := EgaPalette.color(EgaPalette.LIGHT_GRAY)
	var tile := graphics.tiles[Fixtures.LOLLIPOP]
	tile.fill(gray)
	# A red ring with gray inside it, on a gray background.
	for i in range(4, 12):
		for edge in [4, 11]:
			tile.set_pixel(i, edge, Color.RED)
			tile.set_pixel(edge, i, Color.RED)
	var textures := GraphicsTextures.create(graphics)
	var atlas := textures.backdrop_tile_atlas(LevelTileSet.ATLAS_COLUMNS, 1, gray).get_image()
	var cell := (
		LevelTileSet.atlas_coords_of(Fixtures.LOLLIPOP) * (EgaGraphics.TILE_SIZE + 2) + Vector2i.ONE
	)
	assert_equal(atlas.get_pixelv(cell + Vector2i(0, 0)).a, 0.0, "the background around is gone")
	assert_equal(atlas.get_pixelv(cell + Vector2i(4, 4)).a, 1.0, "the ring stays")
	assert_equal(atlas.get_pixelv(cell + Vector2i(7, 7)).a, 1.0, "and the gray inside it")


func test_picture_covers_the_view_and_glides_across() -> void:
	var level := Rect2(32, 32, 1856, 272)
	var at_left := LevelBackdrop.picture_rect(PICTURE, level, level.position + VIEW / 2.0, VIEW)
	var at_right := LevelBackdrop.picture_rect(
		PICTURE, level, Vector2(level.end.x - VIEW.x / 2.0, 100), VIEW
	)
	assert_true(at_left.size.x >= VIEW.x and at_left.size.y >= VIEW.y, "covers the view")
	assert_true(
		is_equal_approx(at_left.size.x / at_left.size.y, PICTURE.x / PICTURE.y), "in its own shape"
	)
	assert_equal(at_left.position, Vector2.ZERO, "its left edge at the left of the level")
	assert_true(is_equal_approx(at_right.end.x, VIEW.x), "its right edge at the right")
	assert_equal(at_right.position.y, 0.0, "its sky always at the top")


func test_picture_stays_in_the_middle_of_a_narrow_level() -> void:
	var level := Rect2(0, 0, 320, 200)
	var rect := LevelBackdrop.picture_rect(PICTURE, level, Vector2(160, 100), VIEW)
	assert_true(
		is_equal_approx(-rect.position.x, (rect.size.x - VIEW.x) / 2.0),
		"centered from side to side"
	)


func test_backgrounds_are_on_only_in_widescreen() -> void:
	var display := DisplaySettings.new()
	assert_true(display.backgrounds, "on by default")
	assert_true(display.shows_backgrounds(), "and shown in widescreen")
	display.aspect = DisplaySettings.Aspect.ORIGINAL
	assert_true(not display.shows_backgrounds(), "never on the original screen")


func test_backgrounds_setting_is_remembered() -> void:
	var path := TEST_DIRECTORY.path_join("settings.cfg")
	var settings := UserSettings.load_from(path)
	settings.display.backgrounds = false
	settings.save()
	assert_true(not UserSettings.load_from(path).display.backgrounds, "stays off")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_option_in_the_menu_only_for_widescreen() -> void:
	var window := GameWindow.new()
	var menus := MenuController.new()
	menus.window = window
	menus.settings = UserSettings.new()
	menus.settings.path = TEST_DIRECTORY.path_join("menu.cfg")
	var menu := menus._options_menu()
	var item := _item(menu, &"backgrounds")
	assert_equal(item.label, "Backgrounds   ON", "on in widescreen")
	menus.settings.display.aspect = DisplaySettings.Aspect.ORIGINAL
	item = _item(menus._options_menu(), &"backgrounds")
	assert_true(not item.enabled, "cannot be picked on the original screen")
	assert_equal(item.label, "Backgrounds   -", "and says so")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(menus.settings.path))
	menus.free()
	window.free()


func test_player_picture_wins_and_missing_ones_are_none() -> void:
	var image := Image.create_empty(30, 20, false, Image.FORMAT_RGBA8)
	image.fill(Color.MAGENTA)
	var folder := TEST_DIRECTORY.path_join(BackdropPictures.PLAYER_FOLDER)
	image.save_png(folder.path_join("level07.png"))
	var files := GameFiles.new()
	files.directory = ProjectSettings.globalize_path(TEST_DIRECTORY)
	var pictures := BackdropPictures.create(files)
	var picture := pictures.picture(7)
	assert_true(picture != null, "found in the player's folder")
	assert_equal(picture.get_size(), Vector2(30, 20), "that picture")
	assert_true(pictures.picture(11) == null, "no picture for level 11 (a dark room)")


func test_level_1_has_a_picture_of_its_own() -> void:
	assert_true(BackdropPictures.create(null).picture(1) != null, "assets/backgrounds/level01")


func _item(menu: Menu, id: StringName) -> Menu.Item:
	for item in menu.items:
		if item.id == id:
			return item
	return null
