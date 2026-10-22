extends "res://tests/test_case.gd"
## Tests for the fixes of 22-10 to the pictures and walls behind Keen 1's
## and Keen 2's levels, on tiles and levels made by code: an item's thin
## sides of lattice are the wall, a window is drawn whole, the lattice
## along a tile's edge goes, grey and black that the level's drawing shuts
## in stay while the open sky does not, a thin black outline is no wall,
## and the HUD's item pictures lose the lattice around them. The same on
## the real files: test_level_walls_fixes_data.gd.

const Fixtures := preload("res://tests/fixtures.gd")
const SIZE := EgaGraphics.TILE_SIZE
const KIND := BackdropHoles.Kind
const FIELD := Color8(170, 170, 170)
const LIGHT_LINE := Color8(255, 255, 255)
const DARK_LINE := Color8(85, 85, 85)
const BLACK := Color8(0, 0, 0)
const LIGHT_DIAGONAL := 15
const LIGHT_ANTI_DIAGONAL := 14
## An item with a black outline that leaves one column of lattice on each
## side of the tile, as Keen 2's chocolate bar and keycards do.
const WIDE_ITEM := Rect2i(1, 3, SIZE - 2, 10)
## A sign that stands one pixel from the top edge of its tile.
const SIGN := Rect2i(4, 1, 8, 6)
## The grey shading along the bottom of a snow platform, and its outline.
const SHADING_ROWS := Rect2i(0, 13, SIZE, 2)
const OUTLINE_ROW := 15
const ITEM_TILE := 5
const LATTICE_TILE := 6


func test_an_items_thin_sides_are_the_wall() -> void:
	var tile := _item_on_lattice()
	var holes := _lattice_holes()
	var plain := holes.kinds(tile)
	assert_equal(plain[5 * SIZE], KIND.NONE, "the pattern rule leaves the thin side (the bug)")
	holes.item_tiles = {ITEM_TILE: true}
	var kinds := holes.kinds_of(ITEM_TILE, tile)
	for y in range(WIDE_ITEM.position.y, WIDE_ITEM.end.y):
		assert_equal(kinds[y * SIZE], KIND.LIT, "left side, row %d" % y)
		assert_equal(kinds[y * SIZE + SIZE - 1], KIND.LIT, "right side, row %d" % y)
		for x in range(WIDE_ITEM.position.x, WIDE_ITEM.end.x):
			assert_equal(kinds[y * SIZE + x], KIND.NONE, "the item at (%d, %d)" % [x, y])
	assert_equal(kinds[0], KIND.LIT, "the lattice above it")


func test_a_window_is_drawn_whole() -> void:
	var holes := _lattice_holes()
	holes.whole_tiles = {ITEM_TILE: true}
	var kinds := holes.kinds_of(ITEM_TILE, _lattice())
	assert_equal(kinds.count(KIND.NONE), SIZE * SIZE, "no hole in the window's tile")
	assert_equal(holes.kinds_of(LATTICE_TILE, _lattice()).count(KIND.LIT), SIZE * SIZE, "beside")


func test_the_lattice_along_a_tiles_edge_goes() -> void:
	var tile := _lattice()
	tile.fill_rect(SIGN, BLACK)
	tile.fill_rect(SIGN.grow(-1), Color.RED)
	var holes := _lattice_holes()
	assert_equal(holes.kinds(tile)[6], KIND.NONE, "too thin for the pattern rule (the bug)")
	var kinds := holes.kinds_of(LATTICE_TILE, tile)
	assert_equal(kinds[6], KIND.LIT, "the strip above the sign is the wall")
	assert_equal(kinds[4 * SIZE + 6], KIND.NONE, "the sign stays")


func test_grey_the_drawing_shuts_in_stays() -> void:
	var graphics := _platform_graphics()
	var level := Fixtures.create_level([".....", ".I-S.", "....."])
	var shut := ColorGroups.create(level, graphics.tiles, FIELD).shut_pixels()
	assert_true(shut.has(Fixtures.PLATFORM), "the platform's shading is shut in")
	assert_true(not shut.has(Fixtures.AIR), "the open sky is not")
	var holes := BackdropHoles.create(FIELD)
	holes.shut_in = shut
	var kinds := holes.kinds_of(Fixtures.PLATFORM, graphics.tiles[Fixtures.PLATFORM])
	assert_equal(kinds[SHADING_ROWS.position.y * SIZE], KIND.NONE, "the shading stays grey")
	assert_equal(kinds[0], KIND.NONE, "the white body stays")
	var air := holes.kinds_of(Fixtures.AIR, graphics.tiles[Fixtures.AIR])
	assert_equal(air.count(KIND.SKY), SIZE * SIZE, "the sky shows the picture")
	var end := holes.kinds_of(Fixtures.ICE, graphics.tiles[Fixtures.ICE])
	assert_equal(end[0], KIND.SKY, "the sky above the platform's end shows it too")


func test_grey_open_to_the_sky_is_the_sky() -> void:
	# A platform without ends: its shading meets the open sky at the edge.
	var graphics := _platform_graphics()
	var level := Fixtures.create_level([".....", ".---.", "....."])
	var groups := ColorGroups.create(level, graphics.tiles, FIELD)
	assert_true(groups.shut_pixels().is_empty(), "nothing is shut in")
	var cell := Vector2i(LevelData.BORDER_CELLS + 2, LevelData.BORDER_CELLS + 1)
	assert_true(groups.is_open(cell, Vector2i(5, SHADING_ROWS.position.y)), "it joins the sky")


func test_a_thin_black_outline_is_no_wall() -> void:
	var tile := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	tile.fill(LIGHT_LINE)
	tile.fill_rect(Rect2i(0, OUTLINE_ROW, SIZE, 1), BLACK)
	tile.fill_rect(Rect2i(0, 0, 4, 4), BLACK)
	var holes := BackdropHoles.create(Color.TRANSPARENT, BLACK)
	assert_equal(holes.kinds(tile)[OUTLINE_ROW * SIZE + 8], KIND.LIT, "without the fix")
	holes.thick_wall = true
	var kinds := holes.kinds(tile)
	assert_equal(kinds[OUTLINE_ROW * SIZE + 8], KIND.NONE, "the outline stays black")
	assert_equal(kinds[SIZE + 1], KIND.LIT, "a thick black corner is the wall")


func test_black_the_drawing_shuts_in_is_no_wall() -> void:
	var graphics := _platform_graphics()
	graphics.tiles[Fixtures.WALL].fill(BLACK)
	var level := Fixtures.create_level(["#####", ".....", ".I-S.", "....."])
	var shut := ColorGroups.create(level, graphics.tiles, BLACK).shut_pixels()
	assert_true(shut.has(Fixtures.PLATFORM), "the platform's outline is shut in")
	assert_true(not shut.has(Fixtures.WALL), "the dark room is not")


func test_hud_icons_lose_the_lattice_around_them() -> void:
	var graphics := Fixtures.create_graphics()
	graphics.tiles[ITEM_TILE] = _item_on_lattice()
	graphics.tiles[LATTICE_TILE] = _lattice()
	var textures := GraphicsTextures.create(graphics)
	var old := textures.clear_tile(ITEM_TILE).get_image()
	assert_equal(old.get_pixel(0, 0).a, 1.0, "the gray rule leaves the lattice's lines (the bug)")
	var icon := textures.clear_tile_on(ITEM_TILE, LATTICE_TILE).get_image()
	for y in SIZE:
		for x in SIZE:
			var item := WIDE_ITEM.has_point(Vector2i(x, y))
			assert_equal(icon.get_pixel(x, y).a, 1.0 if item else 0.0, "(%d, %d)" % [x, y])
	var hud := Hud.new()
	assert_equal(hud.background_tile, -1, "Keen 1's HUD keeps its gray rule")
	hud.free()


## The holes of the lattice made by [method _lattice], with its own name.
static func _lattice_holes() -> BackdropHoles:
	return BackdropHoles.create(
		Color.TRANSPARENT, Color.TRANSPARENT, LatticeWalls.create(_lattice()), "fixes"
	)


static func _item_on_lattice() -> Image:
	var tile := _lattice()
	tile.fill_rect(WIDE_ITEM, BLACK)
	tile.fill_rect(WIDE_ITEM.grow(-1), Color.RED)
	return tile


## The fixture's tiles with plain grey sky (AIR) and a snow platform: ICE
## its left end, PLATFORM its middle, SLIPPERY its right end. The middle's
## grey shading runs from edge to edge; the ends close it with black.
static func _platform_graphics() -> EgaGraphics:
	var graphics := Fixtures.create_graphics()
	graphics.tiles[Fixtures.AIR].fill(FIELD)
	for tile in [Fixtures.ICE, Fixtures.PLATFORM, Fixtures.SLIPPERY]:
		var image: Image = graphics.tiles[tile]
		image.fill(LIGHT_LINE)
		image.fill_rect(Rect2i(0, 0, SIZE, 1), BLACK)
		image.fill_rect(SHADING_ROWS, FIELD)
		image.fill_rect(Rect2i(0, OUTLINE_ROW, SIZE, 1), BLACK)
	# The ends: sky above and beside a closed outline.
	var left: Image = graphics.tiles[Fixtures.ICE]
	left.fill_rect(Rect2i(0, 0, 4, SIZE), FIELD)
	left.fill_rect(Rect2i(4, 0, 1, SIZE), BLACK)
	var right: Image = graphics.tiles[Fixtures.SLIPPERY]
	right.fill_rect(Rect2i(SIZE - 4, 0, 4, SIZE), FIELD)
	right.fill_rect(Rect2i(SIZE - 5, 0, 1, SIZE), BLACK)
	return graphics


## A lattice like Keen 2's (as in test_level_walls.gd).
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
