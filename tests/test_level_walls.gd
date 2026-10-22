extends "res://tests/test_case.gd"
## Tests for milestone AB2, the wall fixed behind the level, on tiles made
## by code: the pattern rule of a lattice (lit, shadow, an item on it, a
## plain grey box and a board that are no lattice), the colour rules, the
## holes cut from the atlas and the wall's masks, the wall layer that
## follows the tiles cell for cell, and finding the walls' textures. The
## same on the real Keen 1 and Keen 2 files: test_level_walls_data.gd.

const Fixtures := preload("res://tests/fixtures.gd")
const SIZE := EgaGraphics.TILE_SIZE
const TEST_DIRECTORY := "user://test_level_walls"
const FIELD := Color8(170, 170, 170)
const LIGHT_LINE := Color8(255, 255, 255)
const DARK_LINE := Color8(85, 85, 85)
const BLACK := Color8(0, 0, 0)
## One EGA step darker, as a wall's shadow on the lattice.
const SHADOW_STEP := 85.0 / 255.0
## Where the lines of the lattice made by [method _lattice] run: the light
## line on these diagonals, the dark one a pixel further on each.
const LIGHT_DIAGONAL := 15
const LIGHT_ANTI_DIAGONAL := 14
const ITEM := Rect2i(5, 5, 6, 6)
const KIND := BackdropHoles.Kind


func test_the_lattice_itself_is_all_lit_wall() -> void:
	var walls := LatticeWalls.create(_lattice())
	assert_equal(_count(walls.kinds(_lattice()), KIND.LIT), SIZE * SIZE, "every pixel")


func test_a_shadow_falls_on_the_wall_without_the_lattice() -> void:
	var tile := _lattice()
	for y in SIZE:
		for x in SIZE / 2:
			var color := tile.get_pixel(x, y)
			tile.set_pixel(
				x,
				y,
				Color(color.r - SHADOW_STEP, color.g - SHADOW_STEP, color.b - SHADOW_STEP).clamp()
			)
	var kinds := LatticeWalls.create(_lattice()).kinds(tile)
	assert_equal(_count(kinds, KIND.NONE), 0, "nothing of the lattice is left")
	assert_equal(kinds[3 * SIZE + 2], KIND.SHADOW, "the darker half is the shadow")
	assert_equal(kinds[3 * SIZE + 12], KIND.LIT, "the other half is lit")


func test_an_item_on_the_lattice_stays_whole() -> void:
	var tile := _lattice()
	tile.fill_rect(ITEM, Color.RED)
	var kinds := LatticeWalls.create(_lattice()).kinds(tile)
	for y in range(ITEM.position.y, ITEM.end.y):
		for x in range(ITEM.position.x, ITEM.end.x):
			assert_equal(kinds[y * SIZE + x], KIND.NONE, "the item at (%d, %d)" % [x, y])
	assert_equal(kinds[0], KIND.LIT, "the lattice around it is the wall")


func test_a_plain_grey_box_is_not_the_lattice() -> void:
	# A riveted box: the lattice's grey inside a black and dark grey frame,
	# a colour that equals the lattice wherever its field is.
	var tile := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	tile.fill(BLACK)
	tile.fill_rect(Rect2i(1, 1, SIZE - 2, SIZE - 2), DARK_LINE)
	tile.fill_rect(Rect2i(2, 2, SIZE - 4, SIZE - 4), FIELD)
	tile.fill_rect(Rect2i(3, 3, 2, 1), LIGHT_LINE)
	tile.fill_rect(Rect2i(3, 11, 2, 1), LIGHT_LINE)
	var kinds := LatticeWalls.create(_lattice()).kinds(tile)
	assert_equal(_count(kinds, KIND.NONE), SIZE * SIZE, "no X of wall in it")


func test_a_board_keeps_its_edge() -> void:
	# The top left corner of a white board: a black, dark grey and grey edge.
	var tile := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	tile.fill(LIGHT_LINE)
	tile.fill_rect(Rect2i(0, 0, SIZE, 1), BLACK)
	tile.fill_rect(Rect2i(0, 0, 1, SIZE), BLACK)
	tile.fill_rect(Rect2i(1, 1, SIZE - 1, 1), DARK_LINE)
	tile.fill_rect(Rect2i(1, 1, 1, SIZE - 1), DARK_LINE)
	tile.fill_rect(Rect2i(2, 2, SIZE - 2, 1), FIELD)
	tile.fill_rect(Rect2i(2, 2, 1, SIZE - 2), FIELD)
	var kinds := LatticeWalls.create(_lattice()).kinds(tile)
	assert_equal(_count(kinds, KIND.NONE), SIZE * SIZE, "no dots of wall in it")


func test_colour_rules_for_sky_and_wall() -> void:
	var tile := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	tile.fill(FIELD)
	tile.fill_rect(Rect2i(0, 8, SIZE, 8), BLACK)
	tile.fill_rect(Rect2i(4, 4, 4, 8), Color.RED)
	tile.set_pixel(5, 6, FIELD)
	var kinds := BackdropHoles.create(FIELD, BLACK).kinds(tile)
	assert_equal(kinds[0], KIND.SKY, "the grey is the sky")
	assert_equal(kinds[15 * SIZE], KIND.LIT, "the black is the wall")
	assert_equal(kinds[6 * SIZE + 5], KIND.NONE, "grey inside the item stays")
	assert_equal(kinds[6 * SIZE + 4], KIND.NONE, "and the item")


func test_holes_and_masks_in_the_atlas() -> void:
	var graphics := Fixtures.create_graphics()
	graphics.tiles[Fixtures.LOLLIPOP] = _lattice()
	graphics.tiles[Fixtures.LOLLIPOP].fill_rect(ITEM, Color.RED)
	var textures := GraphicsTextures.create(graphics)
	var holes := BackdropHoles.create(
		Color.TRANSPARENT, Color.TRANSPARENT, LatticeWalls.create(_lattice()), "test"
	)
	var atlas := textures.holes_tile_atlas(LevelTileSet.ATLAS_COLUMNS, 1, holes).get_image()
	var masks := textures.wall_mask_atlas(LevelTileSet.ATLAS_COLUMNS, 1, holes).get_image()
	var corner := LevelTileSet.atlas_coords_of(Fixtures.LOLLIPOP) * (SIZE + 2) + Vector2i.ONE
	assert_equal(atlas.get_pixelv(corner).a, 0.0, "the lattice is left out of the tile")
	assert_equal(atlas.get_pixelv(corner + ITEM.position).a, 1.0, "the item stays")
	assert_equal(masks.get_pixelv(corner).r, BackdropHoles.LIT_BRIGHTNESS, "the wall's mask, lit")
	assert_equal(masks.get_pixelv(corner + ITEM.position).a, 0.0, "no wall behind the item")
	var tile_set := LevelTileSet.build_wall_masks(textures, holes)
	var source := tile_set.get_source(LevelTileSet.SOURCE_ID) as TileSetAtlasSource
	assert_true(source.has_tile(LevelTileSet.atlas_coords_of(Fixtures.LOLLIPOP)), "a wall tile")
	assert_true(not source.has_tile(LevelTileSet.atlas_coords_of(Fixtures.WALL)), "no wall there")


func test_sky_only_holes_are_the_old_backdrop_atlas() -> void:
	# Keen 1's level 1 keeps its picture exactly as before AB2.
	var graphics := Fixtures.create_graphics()
	var gray := EgaPalette.color(EgaPalette.LIGHT_GRAY)
	graphics.tiles[Fixtures.LOLLIPOP].fill(gray)
	graphics.tiles[Fixtures.LOLLIPOP].fill_rect(ITEM, Color.RED)
	var textures := GraphicsTextures.create(graphics)
	var old := textures.backdrop_tile_atlas(LevelTileSet.ATLAS_COLUMNS, 1, gray).get_image()
	var holes := BackdropHoles.create(gray)
	var new := textures.holes_tile_atlas(LevelTileSet.ATLAS_COLUMNS, 1, holes).get_image()
	assert_equal(new.get_data(), old.get_data(), "the same pixels")


func test_wall_follows_the_tiles_cell_for_cell() -> void:
	var graphics := Fixtures.create_graphics()
	graphics.tiles[Fixtures.AIR] = _lattice()
	var textures := GraphicsTextures.create(graphics)
	var holes := BackdropHoles.create(
		Color.TRANSPARENT, Color.TRANSPARENT, LatticeWalls.create(_lattice()), "test"
	)
	var map := LevelMap.new()
	map.tile_set = LevelTileSet.build_with_holes(graphics, textures, holes)
	map.show_level(Fixtures.create_level(["....", "####"]), Fixtures.create_properties())
	var texture := ImageTexture.create_from_image(_lattice())
	map.use_wall(LevelTileSet.build_wall_masks(textures, holes), texture, {})
	var wall := map.wall()
	assert_true(wall.get_parent() == map and wall.transform == Transform2D.IDENTITY, "on the level")
	assert_true(wall.z_index < 0, "behind the tiles")
	assert_equal(wall.get_used_cells().size(), 4, "behind the four cells of air")
	map.set_tile(Vector2i(1, 0), Fixtures.WALL)
	assert_equal(wall.get_cell_source_id(Vector2i(1, 0)), -1, "a changed tile takes its wall")
	map.use_wall(null, null, {})
	assert_true(not wall.is_showing() and wall.get_used_cells().is_empty(), "and gone")
	map.free()


func test_cells_can_keep_the_sky_colour() -> void:
	var graphics := Fixtures.create_graphics()
	var gray := EgaPalette.color(EgaPalette.LIGHT_GRAY)
	var textures := GraphicsTextures.create(graphics)
	var map := LevelMap.new()
	map.tile_set = LevelTileSet.build_with_holes(graphics, textures, BackdropHoles.create(gray))
	map.show_level(Fixtures.create_level(["....", "####"]), Fixtures.create_properties())
	var cells := map.get_used_cells()
	var kept: Dictionary[Vector2i, bool] = {cells[0]: true}
	map.use_wall(null, null, kept)
	assert_equal(map.get_cell_source_id(cells[0]), LevelTileSet.SKY_KEPT_SOURCE_ID, "kept")
	assert_equal(map.get_cell_source_id(cells[1]), LevelTileSet.SOURCE_ID, "the sky")
	map.free()


func test_wall_textures_and_the_players_own() -> void:
	var folder := TEST_DIRECTORY.path_join(BackdropPictures.PLAYER_FOLDER)
	DirAccess.make_dir_recursive_absolute(folder)
	_lattice().save_png(folder.path_join("wall05.png"))
	var files := GameFiles.new()
	files.directory = ProjectSettings.globalize_path(TEST_DIRECTORY)
	var walls := BackdropPictures.walls(files)
	assert_equal(walls.file_name(5), "wall05", "named after the level")
	var texture := walls.picture(5)
	assert_true(texture != null and texture.get_size() == Vector2(SIZE, SIZE), "found")
	assert_true(not texture.get_image().has_mipmaps(), "drawn pixel for pixel")
	assert_true(walls.picture(6) == null, "none for level 6")
	assert_true(BackdropPictures.create(files).picture(5) == null, "not a picture to glide")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder.path_join("wall05.png")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(folder))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_no_texture_no_wall() -> void:
	var tiles := Fixtures.create_graphics().tiles
	var level := Fixtures.create_level(["....", "####"])
	assert_true(
		Keen1Walls.create(null, tiles).holes(level, Color.TRANSPARENT, false) == null, "Keen 1"
	)
	assert_true(
		Keen2Walls.create(null, tiles).holes(level, Color.TRANSPARENT, true) == null,
		"Keen 2 without its lattice tiles"
	)


## A lattice like Keen 2's: a grey field with a white and a dark grey line
## along both diagonals, repeating every tile.
static func _lattice() -> Image:
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(FIELD)
	for y in SIZE:
		for x in SIZE:
			if posmod(x - y, SIZE) == LIGHT_DIAGONAL or (x + y) % SIZE == LIGHT_ANTI_DIAGONAL:
				image.set_pixel(x, y, LIGHT_LINE)
			elif posmod(x - y, SIZE) == 1 or (x + y) % SIZE == 0:
				image.set_pixel(x, y, DARK_LINE)
	return image


static func _count(kinds: PackedByteArray, kind: int) -> int:
	return kinds.count(kind)
