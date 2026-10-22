extends "res://tests/test_case.gd"
## Tests for the second round of fixes of 22-10 to the walls behind Keen 1's
## and Keen 2's levels, on tiles and levels made by code: a thin strip of
## lattice between a tile's edge and a black outline is the wall (the ends
## of Keen 2's red beam), the end of a shadow without a line of its own
## joins the shadow (under the small platforms), a straight line of the
## drawing stays whole where the lattice has its colour by chance (a door's
## frame), every frame of an animation gets the same wall, a lone black
## pixel among the lit lattice stays (the zapper's arms); Keen 1's black
## that a block or a sign holds stays black, every frame of an animation is
## shut in, and the sky ends at a gap in a castle wall. The same on the real
## files: test_level_walls_fixes2_data.gd.

const Fixtures := preload("res://tests/fixtures.gd")
const SIZE := EgaGraphics.TILE_SIZE
const KIND := BackdropHoles.Kind
const FIELD := Color8(170, 170, 170)
const LIGHT_LINE := Color8(255, 255, 255)
const DARK_LINE := Color8(85, 85, 85)
const BLACK := Color8(0, 0, 0)
const CYAN := Color8(85, 255, 255)
const LIGHT_DIAGONAL := 15
const LIGHT_ANTI_DIAGONAL := 14
const TILE := 5
## A beam with a black outline that leaves two columns of lattice at its
## left end, framed by the outline above, below and beside them.
const BEAM := Rect2i(2, 3, SIZE - 2, 10)
const BEAM_END := Rect2i(0, 4, 2, 8)
## A platform with a black outline along the top of its tile, and the
## slanted shadow it casts below it (two rows, one pixel further right on
## the lower one), as Keen 2's small platforms (177-181).
const PLATFORM_ROWS := 5
const SHADOW_FROM := 2
const SHADOW_TO := 14
## A door's frame along the left of its tile: white, cyan, two grey and a
## dark grey column, as the right side of Keen 2's exit door (160).
const FRAME: Array[Color] = [LIGHT_LINE, CYAN, FIELD, FIELD, DARK_LINE]
## The zapper made by code: two black arms, one pixel wide, on the lattice,
## and in the second frame a spark that closes the space between them at
## the top.
const ARM_ROWS := Vector2i(4, 12)
const SPARK := Rect2i(3, 1, 10, 3)
const FRAMES: Array[int] = [8, 9]
## Keen 1: a dark studded block (as tile 290): dark grey sides, a light top
## triangle and a black bottom triangle that reaches the bottom edge.
const BLOCK := 7
## A sign: a black face in a grey frame, touching the tile's right edge.
const SIGN_FACE := Rect2i(1, 2, SIZE - 1, 12)
## The castle made by code: tiles of Keen 1's numbers.
const SKY := Keen1Walls.SKY_TILE
const DARK := Keen1Walls.WALL_TILE
const GLASS := 401


func test_a_strip_between_the_edge_and_an_outline_is_the_wall() -> void:
	var tile := _beam()
	var holes := _lattice_holes()
	var before := holes.kinds(tile)
	assert_equal(before[7 * SIZE], KIND.NONE, "too thin and without lines (the bug)")
	var kinds := holes.kinds_of(TILE, tile)
	for y in range(BEAM_END.position.y, BEAM_END.end.y):
		for x in range(BEAM_END.position.x, BEAM_END.end.x):
			assert_equal(kinds[y * SIZE + x], KIND.LIT, "the beam's end at (%d, %d)" % [x, y])
	assert_equal(kinds[7 * SIZE + 8], KIND.NONE, "the beam stays")
	assert_equal(kinds[3 * SIZE + 8], KIND.NONE, "its outline stays")
	# The same strip one EGA step darker is the beam's shadow.
	var shaded := _beam()
	for y in range(BEAM_END.position.y, BEAM_END.end.y):
		for x in range(BEAM_END.position.x, BEAM_END.end.x):
			shaded.set_pixel(x, y, _one_step_darker(shaded.get_pixel(x, y)))
	assert_equal(holes.kinds_of(TILE, shaded)[7 * SIZE], KIND.SHADOW, "the shadow's strip")


func test_a_lone_pixel_or_a_plain_grey_tile_is_no_strip() -> void:
	var tile := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	tile.fill(Color.RED)
	tile.fill_rect(Rect2i(1, 0, 3, 3), BLACK)
	tile.set_pixel(2, 0, _lattice().get_pixel(2, 0))
	var holes := _lattice_holes()
	assert_equal(holes.kinds_of(TILE, tile)[2], KIND.NONE, "a single pixel is the drawing's")
	var grey := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	grey.fill(FIELD)
	assert_equal(holes.kinds_of(TILE, grey).count(KIND.NONE), SIZE * SIZE, "a grey box stays")


func test_the_end_of_a_shadow_joins_the_shadow() -> void:
	var tile := _lattice()
	tile.fill_rect(Rect2i(0, 0, SIZE, PLATFORM_ROWS), BLACK)
	tile.fill_rect(Rect2i(0, 1, SIZE, PLATFORM_ROWS - 2), Color.RED)
	var shadow: Array[Vector2i] = []
	for row in 2:
		for x in range(SHADOW_FROM + row, SHADOW_TO + row + 1):
			shadow.append(Vector2i(x, PLATFORM_ROWS + row))
	for at in shadow:
		tile.set_pixelv(at, _one_step_darker(tile.get_pixelv(at)))
	var kinds := _lattice_holes().kinds_of(TILE, tile)
	for at in shadow:
		assert_equal(kinds[at.y * SIZE + at.x], KIND.SHADOW, "the shadow at %s" % at)
	assert_equal(kinds[(PLATFORM_ROWS + 1) * SIZE], KIND.LIT, "the lattice beside it")


func test_a_straight_frame_stays_whole() -> void:
	var tile := _lattice()
	for x in FRAME.size():
		tile.fill_rect(Rect2i(x, 0, 1, SIZE), FRAME[x])
	var holes := _lattice_holes()
	var drawing := holes.lattice.drawing_runs(tile)
	var kinds := holes.kinds_of(TILE, tile)
	for y in SIZE:
		for x in FRAME.size():
			assert_equal(kinds[y * SIZE + x], KIND.NONE, "the frame at (%d, %d)" % [x, y])
			assert_equal(drawing[y * SIZE + x], 1, "a line of the drawing at (%d, %d)" % [x, y])
		for x in range(FRAME.size() + 1, SIZE):
			assert_equal(kinds[y * SIZE + x], KIND.LIT, "the lattice at (%d, %d)" % [x, y])


func test_the_lattice_beside_a_thing_of_its_colour_stays_wall() -> void:
	# A grey bar along the left of the top row, the lattice's field after it:
	# the field is no line of the drawing, the bar's own pixels are.
	var tile := _lattice()
	tile.fill_rect(Rect2i(0, 0, 3, 2), FIELD)
	var drawing := _lattice_holes().lattice.drawing_runs(tile)
	for x in range(4, 12):
		assert_equal(drawing[SIZE + x], 0, "the lattice's field at (%d, 1)" % x)


func test_every_frame_of_an_animation_gets_the_same_wall() -> void:
	var open := _zapper(false)
	var closed := _zapper(true)
	var holes := _lattice_holes()
	var tiles: Array[Image] = []
	for i in FRAMES[-1] + 1:
		tiles.append(_lattice())
	tiles[FRAMES[0]] = open
	tiles[FRAMES[1]] = closed
	var kinds: Array = []
	for i in tiles.size():
		kinds.append(holes.base_kinds_of(i, tiles[i]))
	var inside := 9 * SIZE + 8
	assert_equal(kinds[FRAMES[0]][inside], KIND.LIT, "between the arms, open at the top")
	assert_equal(kinds[FRAMES[1]][inside], KIND.NONE, "shut in by the spark (the bug)")
	holes.animations = {FRAMES[0]: PackedInt32Array(FRAMES), FRAMES[1]: PackedInt32Array(FRAMES)}
	holes.share_between_frames(kinds, tiles)
	for i in SIZE * SIZE:
		var at := Vector2i(i % SIZE, i / SIZE)
		if open.get_pixelv(at) == closed.get_pixelv(at):
			assert_equal(kinds[FRAMES[1]][i], kinds[FRAMES[0]][i], "the same at %s" % at)
	for frame in FRAMES:
		for y in range(ARM_ROWS.x, ARM_ROWS.y):
			assert_true(kinds[frame][y * SIZE + y / 2] != KIND.LIT, "the left arm, row %d" % y)
	assert_equal(kinds[FRAMES[1]][2 * SIZE + 6], KIND.NONE, "the spark stays")


func test_a_blocks_black_triangle_is_no_wall() -> void:
	var tile := _studded_block()
	var holes := BackdropHoles.create(Color.TRANSPARENT, BLACK)
	holes.thick_wall = true
	var bottom := (SIZE - 3) * SIZE + SIZE / 2
	assert_equal(holes.kinds_of(BLOCK, tile)[bottom], KIND.LIT, "not a block: the bug")
	holes.block_tiles = {BLOCK: true}
	var kinds := holes.kinds_of(BLOCK, tile)
	assert_equal(kinds[bottom], KIND.NONE, "the block's black triangle stays black")
	assert_equal(kinds[(SIZE - 1) * SIZE + SIZE / 2], KIND.NONE, "down to the edge")
	var room := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	room.fill(BLACK)
	room.fill_rect(Rect2i(4, 8, 8, 8), Color.RED)
	assert_equal(holes.kinds_of(BLOCK, room)[0], KIND.LIT, "the room's dark above a thing")


func test_a_signs_black_face_is_no_wall() -> void:
	var tile := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	tile.fill(FIELD)
	tile.fill_rect(SIGN_FACE, BLACK)
	for x in range(3, SIZE - 3, 3):
		tile.set_pixel(x, SIZE / 2, Color.RED)
	var holes := BackdropHoles.create(Color.TRANSPARENT, BLACK)
	holes.thick_wall = true
	assert_equal(holes.kinds(tile)[4 * SIZE + 4], KIND.LIT, "without the rule (the bug)")
	assert_equal(holes.kinds_of(TILE, tile)[4 * SIZE + 4], KIND.NONE, "the face stays black")


func test_every_frame_of_an_animation_is_shut_in() -> void:
	var graphics := _platform_graphics()
	var level := Fixtures.create_level([".....", ".IAS.", "....."])
	var properties := Fixtures.create_properties()
	var once := ColorGroups.create(level, graphics.tiles, FIELD).shut_pixels()
	assert_true(not once.has(Fixtures.ANIMATION_START + 1), "a frame not in the level (the bug)")
	var shut := ColorGroups.shut_in_every_step(level, graphics.tiles, FIELD, properties)
	for step in Fixtures.ANIMATION_FRAMES:
		assert_true(shut.has(Fixtures.ANIMATION_START + step), "frame %d is shut in" % step)
	assert_true(not shut.has(Fixtures.AIR), "the open sky is not")


func test_the_sky_ends_at_a_gap_in_the_castle_wall() -> void:
	var tiles := _castle_tiles()
	var level := _castle()
	var walls := Keen1Walls.create(null, tiles)
	var holes := walls.holes(level, FIELD, true)
	var kept := walls.sky_kept_cells(level, holes)
	var border := Vector2i(LevelData.BORDER_CELLS, LevelData.BORDER_CELLS)
	assert_true(not kept.has(border + Vector2i(4, 3)), "the gap shows the sky")
	assert_true(not kept.has(border + Vector2i(1, 3)), "the sky outside")
	for cell: Vector2i in [Vector2i(5, 3), Vector2i(6, 3), Vector2i(6, 4), Vector2i(8, 5)]:
		assert_true(kept.has(border + cell), "the light inside at %s is grey" % cell)


## A castle made by code: open sky on the left (x 0-3), a wall of glass
## blocks (x 4) with a gap in row 3, and the dark inside with a band of
## light from the gap down to the right; glass all around.
static func _castle() -> LevelData:
	var rows: Array[String] = [
		"....#ddddd",
		"....#ddddd",
		"....#ddddd",
		".......ddd",
		"....#d..dd",
		"....#dd...",
		"....#ddddd",
		"....#ddddd",
	]
	var border := LevelData.BORDER_CELLS
	var level := LevelData.new()
	level.width = rows[0].length() + border * 2
	level.height = rows.size() + border * 2
	level.tiles.resize(level.width * level.height)
	level.infos.resize(level.width * level.height)
	level.tiles.fill(GLASS)
	for y in rows.size():
		for x in rows[y].length():
			var tile: int = {".": SKY, "#": GLASS, "d": DARK}[rows[y][x]]
			level.tiles[(y + border) * level.width + x + border] = tile
	return level


## Plain tiles up to the glass block: Keen 1's grey sky, black dark room and
## a cyan glass block with a black outline.
static func _castle_tiles() -> Array[Image]:
	var tiles: Array[Image] = []
	for i in GLASS + 1:
		var tile := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		tile.fill(Color.RED)
		tiles.append(tile)
	tiles[SKY].fill(FIELD)
	tiles[DARK].fill(BLACK)
	tiles[GLASS].fill(BLACK)
	tiles[GLASS].fill_rect(Rect2i(1, 1, SIZE - 2, SIZE - 2), CYAN)
	return tiles


## The beam on the lattice, its outline along the whole top and bottom
## rows as Keen 2's red beam (225).
static func _beam() -> Image:
	var tile := _lattice()
	tile.fill_rect(BEAM, BLACK)
	tile.fill_rect(BEAM.grow(-1), Color.RED)
	tile.fill_rect(Rect2i(0, BEAM.position.y, SIZE, 1), BLACK)
	tile.fill_rect(Rect2i(0, BEAM.end.y - 1, SIZE, 1), BLACK)
	return tile


## Keen 1's dark studded block made by code (as tile 290).
static func _studded_block() -> Image:
	var tile := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	tile.fill(DARK_LINE)
	for y in SIZE:
		for x in SIZE:
			var top := y < x and y < SIZE - 1 - x
			var bottom := y > x and y > SIZE - 1 - x
			if top:
				tile.set_pixel(x, y, FIELD)
			elif bottom:
				tile.set_pixel(x, y, BLACK)
	tile.fill_rect(Rect2i(0, SIZE - 1, SIZE, 1), BLACK)
	return tile


## The zapper made by code: arms one pixel wide along the diagonals from
## the bottom middle, on the lattice; with [param spark] closed at the top.
static func _zapper(spark: bool) -> Image:
	var tile := _lattice()
	for y in range(ARM_ROWS.x, ARM_ROWS.y):
		tile.set_pixel(y / 2, y, BLACK)
		tile.set_pixel(SIZE - 1 - y / 2, y, BLACK)
	if spark:
		tile.fill_rect(SPARK, CYAN)
		tile.fill_rect(Rect2i(SPARK.position.x, SPARK.end.y, 1, ARM_ROWS.y), BLACK)
		tile.fill_rect(Rect2i(SPARK.end.x - 1, SPARK.end.y, 1, ARM_ROWS.y), BLACK)
		tile.fill_rect(Rect2i(0, ARM_ROWS.y, SIZE, 1), BLACK)
	return tile


## [param color] one EGA step darker, as a shadow on the lattice.
static func _one_step_darker(color: Color) -> Color:
	var step := LatticeWalls.EGA_STEP
	return Color8(maxi(color.r8 - step, 0), maxi(color.g8 - step, 0), maxi(color.b8 - step, 0))


## The holes of the lattice made by [method _lattice], with its own name.
static func _lattice_holes() -> BackdropHoles:
	return BackdropHoles.create(
		Color.TRANSPARENT, Color.TRANSPARENT, LatticeWalls.create(_lattice()), "fixes 2"
	)


## The fixture's tiles with plain grey sky (AIR) and a snow platform: ICE
## its left end, the frames of the animation (8-11) its middle, SLIPPERY its
## right end. The middle's grey shading runs from edge to edge, one row
## lower in each frame; the ends close it with black.
static func _platform_graphics() -> EgaGraphics:
	var graphics := Fixtures.create_graphics()
	graphics.tiles[Fixtures.AIR].fill(FIELD)
	var middles: Array[int] = []
	for step in Fixtures.ANIMATION_FRAMES:
		middles.append(Fixtures.ANIMATION_START + step)
	for tile: int in [Fixtures.ICE, Fixtures.SLIPPERY] + middles:
		var image: Image = graphics.tiles[tile]
		image.fill(LIGHT_LINE)
		image.fill_rect(Rect2i(0, 0, SIZE, 1), BLACK)
		var row := 8 + maxi(tile - Fixtures.ANIMATION_START, 0) % Fixtures.ANIMATION_FRAMES
		image.fill_rect(Rect2i(0, row, SIZE, 2), FIELD)
		image.fill_rect(Rect2i(0, SIZE - 1, SIZE, 1), BLACK)
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
