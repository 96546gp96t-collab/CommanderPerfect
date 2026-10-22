extends "res://tests/test_case.gd"
## Tests for the fixes of 22-10 with the player's own Keen 1 and Keen 2
## files (each part returns early without them): Keen 2's items keep no
## lattice at their edge, its windows are drawn whole with their glass, its
## HUD icons have no lattice; Keen 1's snow platforms keep their shading,
## the outlines of its blocks stay black, and the steps of grey triangles
## where a shrine's wall meets the sky show the picture (levels 9 and 10).

const SIZE := EgaGraphics.TILE_SIZE
const KIND := BackdropHoles.Kind
## Keen 2, version 1.31.
const LATTICE := 143
const WINDOW_CORNER := 403
## A pixel of the window's glass, drawn in front of Keen through its mask.
const GLASS_PIXEL := Vector2i(15, 8)
const WINDOW_LEVEL := 6
## Keen 1: the middle of a snow platform and its shading; the white block
## of the ice shrines and a pixel of its outline at the tile's edge; the
## black of a dark room.
const SNOW_PLATFORM := 385
const SHADING_PIXEL := Vector2i(5, 13)
const WHITE_BLOCK := 400
const BLOCK_OUTLINE := Vector2i(0, 5)
const DARK := 155
## The grey triangles where the wall of a shrine meets the floor and the
## sky: level 10 left of the red floor, level 9 left of the exit door and
## at the floor right of it (level cells).
const LEVEL_10_STEPS: Array[Vector2i] = [Vector2i(31, 34), Vector2i(32, 35)]
const LEVEL_9_STEPS: Array[Vector2i] = [Vector2i(22, 32), Vector2i(28, 35)]


func test_keen_2_items_keep_no_lattice_at_their_edge() -> void:
	var data := _keen_2()
	if data.is_empty():
		return
	var tiles: Array[Image] = data.graphics.tiles
	var holes := _keen_2_holes(data, WINDOW_LEVEL)
	var items := Keen2Walls.items(data.properties, tiles.size())
	assert_true(items.size() >= 10, "the raygun, the keycards and the points items")
	for tile: int in items:
		var kinds := holes.kinds_of(tile, tiles[tile])
		for i in SIZE * SIZE:
			var at := Vector2i(i % SIZE, i / SIZE)
			if not _on_edge(at) or tiles[tile].get_pixelv(at) != tiles[LATTICE].get_pixelv(at):
				continue
			assert_equal(kinds[i], KIND.LIT, "item %d at %s is the wall" % [tile, at])


func test_keen_2_windows_are_drawn_whole() -> void:
	var data := _keen_2()
	if data.is_empty():
		return
	var holes := _keen_2_holes(data, WINDOW_LEVEL)
	assert_true(holes.whole_tiles.has(WINDOW_CORNER), "a window")
	var tiles: Array[Image] = data.graphics.tiles
	var kinds := holes.kinds_of(WINDOW_CORNER, tiles[WINDOW_CORNER])
	assert_equal(kinds.count(KIND.NONE), SIZE * SIZE, "with the lattice behind the glass")
	var mask := tiles[WINDOW_CORNER + 1]
	assert_equal(mask.get_pixelv(GLASS_PIXEL), Color.BLACK, "the glass is drawn in front")
	var textures := GraphicsTextures.create(data.graphics)
	var atlas := textures.holes_tile_atlas(LevelTileSet.ATLAS_COLUMNS, 1, holes).get_image()
	var corner := LevelTileSet.atlas_coords_of(WINDOW_CORNER) * (SIZE + 2) + Vector2i.ONE
	assert_equal(atlas.get_pixelv(corner + GLASS_PIXEL).a, 1.0, "the glass is in the atlas")


func test_keen_2_hud_icons_have_no_lattice() -> void:
	var data := _keen_2()
	if data.is_empty():
		return
	var tiles: Array[Image] = data.graphics.tiles
	var textures := GraphicsTextures.create(data.graphics)
	var icons := Keen2Icons.keycards(data.properties)
	icons.append(Keen2Icons.raygun(data.properties))
	for tile in icons:
		var icon := textures.clear_tile_on(tile, LATTICE).get_image()
		for i in SIZE * SIZE:
			var at := Vector2i(i % SIZE, i / SIZE)
			if _on_edge(at) and tiles[tile].get_pixelv(at) == tiles[LATTICE].get_pixelv(at):
				assert_equal(icon.get_pixelv(at).a, 0.0, "icon %d at %s" % [tile, at])


func test_keen_1_platforms_and_outlines_stay() -> void:
	var files := GameFiles.locate()
	var graphics := EgaGraphics.load_from(files) if files != null else null
	if graphics == null:
		return
	var walls := Keen1Walls.create(files, graphics.tiles)
	var sky := BackdropPictures.color_of(graphics.tiles[Keen1Walls.SKY_TILE])
	var level_8 := LevelData.parse(files.read(GameFiles.level_file_name(8)))
	var holes := walls.holes(level_8, sky, false)
	var platform := holes.kinds_of(SNOW_PLATFORM, graphics.tiles[SNOW_PLATFORM])
	var shading := SHADING_PIXEL.y * SIZE + SHADING_PIXEL.x
	assert_equal(holes.kinds(graphics.tiles[SNOW_PLATFORM])[shading], KIND.SKY, "the bug")
	assert_equal(platform[shading], KIND.NONE, "the shading under the platform stays grey")
	var open := holes.kinds_of(Keen1Walls.SKY_TILE, graphics.tiles[Keen1Walls.SKY_TILE])
	assert_equal(open.count(KIND.SKY), SIZE * SIZE, "the open sky shows the picture")
	var level_10 := LevelData.parse(files.read(GameFiles.level_file_name(10)))
	holes = walls.holes(level_10, sky, true)
	var block := holes.kinds_of(WHITE_BLOCK, graphics.tiles[WHITE_BLOCK])
	assert_equal(block[BLOCK_OUTLINE.y * SIZE + BLOCK_OUTLINE.x], KIND.NONE, "outline black")
	var dark := holes.kinds_of(DARK, graphics.tiles[DARK])
	assert_equal(dark.count(KIND.LIT), SIZE * SIZE, "the dark room is the wall")


func test_keen_1_steps_at_a_shrines_wall_show_the_sky() -> void:
	var files := GameFiles.locate()
	var graphics := EgaGraphics.load_from(files) if files != null else null
	if graphics == null:
		return
	var walls := Keen1Walls.create(files, graphics.tiles)
	var sky := BackdropPictures.color_of(graphics.tiles[Keen1Walls.SKY_TILE])
	for number: int in [10, 9]:
		var level := LevelData.parse(files.read(GameFiles.level_file_name(number)))
		var kept := walls.sky_kept_cells(level, walls.holes(level, sky, true))
		var steps := LEVEL_10_STEPS if number == 10 else LEVEL_9_STEPS
		for cell in steps:
			var tile := level.tile_at(cell)
			assert_true(tile != Keen1Walls.SKY_TILE, "level %d %s is a triangle" % [number, cell])
			assert_true(not kept.has(cell), "level %d %s shows the sky" % [number, cell])


static func _on_edge(at: Vector2i) -> bool:
	return at.x == 0 or at.y == 0 or at.x == SIZE - 1 or at.y == SIZE - 1


## Keen 2's graphics and properties, or empty without the files.
static func _keen_2() -> Dictionary:
	var files := Keen2Files.locate()
	var data := Keen2GameData.load_from(files) if files != null else null
	if data == null:
		return {}
	return {"files": files, "graphics": data.graphics, "properties": data.properties}


static func _keen_2_holes(data: Dictionary, number: int) -> BackdropHoles:
	var files: GameFiles = data.files
	var walls := Keen2Walls.create(
		files, data.graphics.tiles, Keen2Walls.FOLDER_KEEN_2, data.properties
	)
	var level := LevelData.parse(files.read(files.level_file(number)))
	return walls.holes(level, Color.TRANSPARENT, true)
