extends "res://tests/test_case.gd"
## Tests for the second round of fixes of 22-10 with the player's own Keen 1
## and Keen 2 files (each part returns early without them): no lattice is
## left at the ends of Keen 2's small platforms and its red beam, the exit
## door keeps a straight frame (also in level 12, with its teal), the
## zapper's frames get the same wall and keep their arms; Keen 1's dark
## studded blocks keep their black triangle, its exit sign stays black in
## both frames, and the light through the gap in the castle wall of level
## 16 is grey from the wall on. The 4:3 tiles stay the original.

const SIZE := EgaGraphics.TILE_SIZE
const KIND := BackdropHoles.Kind
## Keen 2, version 1.31.
const LATTICE := 143
const PLATFORMS: Array[int] = [177, 178, 179, 180, 181]
const PLATFORM_BOTTOM := 5
const BEAM_LEFT := 225
const BEAM_RIGHT := 227
const BEAM_END_ROWS := Vector2i(4, 12)
const DOOR_RIGHT := 160
const DOOR := 159
const DOOR_FRAME := 5
const ZAPPER: Array[int] = [169, 170, 171, 172]
const TEAL_LEVEL := 12
const PLATFORM_LEVEL := 1
## Keen 1: the dark studded block, its black triangle; the exit sign's two
## frames and a pixel of its face; the cells of the light through the
## castle wall of level 16: the gap Keen stands in (and the step of the
## slope beside it) and the light inside.
const DARK_BLOCK := 290
const TRIANGLE_PIXEL := Vector2i(8, 13)
const SIGN_FRAMES: Array[int] = [167, 168]
const SIGN_FACE := Vector2i(4, 4)
const GAP: Array[Vector2i] = [Vector2i(86, 47), Vector2i(86, 48), Vector2i(86, 49)]
const STEP := Vector2i(85, 49)
const INSIDE: Array[Vector2i] = [Vector2i(87, 48), Vector2i(87, 49), Vector2i(88, 50)]


func test_keen_2_platform_and_beam_ends_keep_no_lattice() -> void:
	var data := _keen_2()
	if data.is_empty():
		return
	var tiles: Array[Image] = data.graphics.tiles
	var kinds := _keen_2_kinds(data, PLATFORM_LEVEL)
	var shadow := LatticeWalls.create(tiles[LATTICE])
	for tile in PLATFORMS:
		var looks := shadow.pixel_kinds(tiles[tile])
		for i in range(PLATFORM_BOTTOM * SIZE, SIZE * SIZE):
			if looks[i] != KIND.NONE:
				assert_true(kinds[tile][i] != KIND.NONE, "platform %d at %d" % [tile, i])
	for y in range(BEAM_END_ROWS.x, BEAM_END_ROWS.y):
		for x in 2:
			assert_equal(kinds[BEAM_LEFT][y * SIZE + x], KIND.LIT, "beam's left end")
			assert_equal(kinds[BEAM_RIGHT][y * SIZE + SIZE - 1 - x], KIND.SHADOW, "right end")


func test_keen_2_exit_door_keeps_a_straight_frame() -> void:
	var data := _keen_2()
	if data.is_empty():
		return
	for number in [PLATFORM_LEVEL, TEAL_LEVEL]:
		var kinds := _keen_2_kinds(data, number)
		for y in SIZE:
			for x in DOOR_FRAME:
				var i := y * SIZE + x
				assert_equal(
					kinds[DOOR_RIGHT][i], KIND.NONE, "level %d frame %d,%d" % [number, x, y]
				)
				assert_equal(kinds[DOOR][i], KIND.NONE, "level %d left %d,%d" % [number, x, y])
	var teal := _keen_2_kinds(data, TEAL_LEVEL)
	assert_equal(teal[DOOR].count(KIND.NONE), SIZE * SIZE, "the teal inside the door stays")


func test_keen_2_zapper_frames_get_the_same_wall() -> void:
	var data := _keen_2()
	if data.is_empty():
		return
	var tiles: Array[Image] = data.graphics.tiles
	var kinds := _keen_2_kinds(data, PLATFORM_LEVEL)
	var black := Color8(0, 0, 0)
	for i in SIZE * SIZE:
		var at := Vector2i(i % SIZE, i / SIZE)
		var pixel := tiles[ZAPPER[0]].get_pixelv(at)
		var same := ZAPPER.all(func(tile: int) -> bool: return tiles[tile].get_pixelv(at) == pixel)
		for tile in ZAPPER:
			if same:
				assert_equal(kinds[tile][i], kinds[ZAPPER[0]][i], "%d at %s" % [tile, at])
			if tiles[tile].get_pixelv(at) == black:
				assert_true(kinds[tile][i] != KIND.LIT, "the arms stay: %d at %s" % [tile, at])


func test_keen_2_four_three_tiles_are_the_original() -> void:
	var data := _keen_2()
	if data.is_empty():
		return
	var tiles: Array[Image] = data.graphics.tiles
	var original := GraphicsTextures.create(data.graphics).tile_atlas(LevelTileSet.ATLAS_COLUMNS, 1)
	var atlas := original.get_image()
	for tile: int in PLATFORMS + ZAPPER + [BEAM_LEFT, BEAM_RIGHT, DOOR, DOOR_RIGHT]:
		var corner := LevelTileSet.atlas_coords_of(tile) * (SIZE + 2) + Vector2i.ONE
		for i in SIZE * SIZE:
			var at := Vector2i(i % SIZE, i / SIZE)
			assert_equal(atlas.get_pixelv(corner + at), tiles[tile].get_pixelv(at), "%d" % tile)


func test_keen_1_blocks_and_the_exit_sign_stay_dark() -> void:
	var files := GameFiles.locate()
	var graphics := EgaGraphics.load_from(files) if files != null else null
	if graphics == null:
		return
	var properties := TileProperties.load_from(files, graphics.tiles.size())
	var walls := Keen1Walls.create(files, graphics.tiles, BackdropPictures.FOLDER, properties)
	var sky := BackdropPictures.color_of(graphics.tiles[Keen1Walls.SKY_TILE])
	var textures := GraphicsTextures.create(graphics)
	for number in [2, 16]:
		var level := LevelData.parse(files.read(GameFiles.level_file_name(number)))
		var kinds := textures.hole_kinds(walls.holes(level, sky, true))
		if number == 2:
			var triangle := TRIANGLE_PIXEL.y * SIZE + TRIANGLE_PIXEL.x
			assert_equal(kinds[DARK_BLOCK][triangle], KIND.NONE, "the block's triangle")
		for tile in SIGN_FRAMES:
			var face := SIGN_FACE.y * SIZE + SIGN_FACE.x
			assert_equal(kinds[tile][face], KIND.NONE, "level %d: sign %d" % [number, tile])


func test_keen_1_light_through_the_castle_wall_is_grey_inside() -> void:
	var files := GameFiles.locate()
	var graphics := EgaGraphics.load_from(files) if files != null else null
	if graphics == null:
		return
	var properties := TileProperties.load_from(files, graphics.tiles.size())
	var walls := Keen1Walls.create(files, graphics.tiles, BackdropPictures.FOLDER, properties)
	var sky := BackdropPictures.color_of(graphics.tiles[Keen1Walls.SKY_TILE])
	var level := LevelData.parse(files.read(GameFiles.level_file_name(16)))
	var kept := walls.sky_kept_cells(level, walls.holes(level, sky, true))
	for cell in GAP + [STEP]:
		assert_true(not kept.has(cell), "the sky in the gap at %s" % cell)
	for cell in INSIDE:
		assert_true(kept.has(cell), "grey inside the wall at %s" % cell)


## Keen 2's graphics and properties, or empty without the files.
static func _keen_2() -> Dictionary:
	var files := Keen2Files.locate()
	var data := Keen2GameData.load_from(files) if files != null else null
	if data == null:
		return {}
	return {"files": files, "graphics": data.graphics, "properties": data.properties}


## The kinds of hole of every tile in Keen 2's level [param number], as the
## game cuts them ([method GraphicsTextures.hole_kinds]).
static func _keen_2_kinds(data: Dictionary, number: int) -> Array:
	var files: GameFiles = data.files
	var walls := Keen2Walls.create(
		files, data.graphics.tiles, Keen2Walls.FOLDER_KEEN_2, data.properties
	)
	var level := LevelData.parse(files.read(files.level_file(number)))
	var holes := walls.holes(level, Color.TRANSPARENT, true)
	return GraphicsTextures.create(data.graphics).hole_kinds(holes)
