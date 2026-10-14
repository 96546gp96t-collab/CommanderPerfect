extends "res://tests/test_case.gd"
## Tests for the extras of the picture: xBRZ, the sheets for Real-ESRGAN, the
## HD graphics, scaled textures and smooth motion. Small hand-made images,
## no game data needed.

const TEST_DIRECTORY := "user://test_graphics"
const FACTOR := 3


func run_all() -> void:
	super.run_all()
	_remove(TEST_DIRECTORY)


func test_xbrz_keeps_flat_areas_and_straight_edges() -> void:
	var image := _image(["..##", "..##", "..##", "..##"])
	var scaled := XbrzScaler.scale(image, FACTOR)
	assert_equal(scaled.get_size(), image.get_size() * FACTOR, "size")
	var nearest := image.duplicate() as Image
	nearest.resize(4 * FACTOR, 4 * FACTOR, Image.INTERPOLATE_NEAREST)
	assert_equal(scaled.get_data(), nearest.get_data(), "a straight edge stays sharp")


func test_xbrz_smooths_a_diagonal_edge() -> void:
	var image := _image(["....##", "...###", "..####", ".#####", "######", "######"])
	var scaled := XbrzScaler.scale(image, FACTOR)
	var mixed := 0
	for y in scaled.get_height():
		for x in scaled.get_width():
			var color := scaled.get_pixel(x, y)
			if color != Color.WHITE and color != Color.BLACK:
				mixed += 1
	assert_true(mixed > 0, "pixels along the diagonal are blended")
	assert_equal(scaled.get_pixel(0, 0), Color.WHITE, "far from the edge: unchanged")
	assert_equal(scaled.get_pixel(17, 17), Color.BLACK, "inside: unchanged")
	# Along the staircase the line now runs between the steps: the corner of
	# a white step pixel (1, 3) towards the black ones is blended.
	var corner := scaled.get_pixel(1 * FACTOR + FACTOR - 1, 3 * FACTOR + FACTOR - 1)
	assert_true(corner != Color.WHITE, "the step corner is cut")


func test_xbrz_keeps_transparency() -> void:
	var image := _image(["....", ".##.", ".##.", "...."], Color.TRANSPARENT)
	var scaled := XbrzScaler.scale(image, FACTOR)
	assert_equal(scaled.get_pixel(0, 0).a, 0.0, "the background stays transparent")
	assert_equal(scaled.get_pixel(6, 6), Color.BLACK, "the middle stays")


func test_color_distance() -> void:
	var black := PackedByteArray([0, 0, 0, 255])
	var white := PackedByteArray([255, 255, 255, 255])
	var clear_red := PackedByteArray([255, 0, 0, 0])
	var clear_blue := PackedByteArray([0, 0, 255, 0])
	assert_equal(XbrzScaler.color_distance(black, black), 0.0, "same color")
	assert_true(absf(XbrzScaler.color_distance(black, white) - 255.0) < 0.01, "black and white")
	assert_equal(XbrzScaler.color_distance(clear_red, clear_blue), 0.0, "all transparent alike")
	assert_equal(XbrzScaler.color_distance(black, clear_blue), 255.0, "visible against not")


func test_sheet_round_trip() -> void:
	var images: Array[Image] = [_image(["#.", ".#"]), _image(["##.", "...", ".#."])]
	var sheet := GraphicsSheet.pack(images)
	assert_equal(
		sheet.image.get_size(), GraphicsSheet.size_for(GraphicsSheet.sizes_of(images)), "size"
	)
	var bigger := sheet.image.duplicate() as Image
	var size := bigger.get_size() * FACTOR
	bigger.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	var cut := GraphicsSheet.cut(bigger, sheet.rects, FACTOR)
	assert_equal(cut.size(), 2, "both images")
	assert_equal(cut[1].get_size(), Vector2i(3, 3) * FACTOR, "scaled size")
	assert_equal(cut[1].get_pixel(0, 0), Color.BLACK, "top left")
	assert_equal(cut[1].get_pixel(2 * FACTOR, 0), Color.WHITE, "top right")
	var rect := sheet.rects[0]
	assert_equal(
		sheet.image.get_pixelv(
			rect.position - Vector2i(GraphicsSheet.PADDING, GraphicsSheet.PADDING)
		),
		Color.BLACK,
		"the border repeats the corner"
	)


func test_sheet_fills_transparent_pixels_and_keeps_masks() -> void:
	var images: Array[Image] = [_image(["#..", "..."], Color.TRANSPARENT)]
	var sheet := GraphicsSheet.pack(images)
	var at := sheet.rects[0].position
	assert_equal(sheet.image.get_pixelv(at + Vector2i(2, 1)), Color.BLACK, "nearest visible color")
	var masks := GraphicsSheet.pack_masks(images)
	assert_equal(masks.image.get_pixelv(at), Color.WHITE, "visible")
	assert_equal(masks.image.get_pixelv(at + Vector2i(1, 0)), Color.BLACK, "transparent")


func test_hd_pack_round_trip() -> void:
	var graphics := _graphics()
	var files := GameFiles.new()
	files.directory = TEST_DIRECTORY
	assert_true(not HdPack.exists(files), "no HD graphics yet")
	var folder := HdPack.folder_of(files)
	assert_true(HdPack.write_sheets(graphics, null, folder), "sheets written")
	# Stand in for Real-ESRGAN: make every sheet twice as large.
	for file_name in DirAccess.get_files_at(folder):
		var sheet := Image.load_from_file(folder.path_join(file_name))
		sheet.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
		sheet.save_png(folder.path_join(file_name))
	assert_true(HdPack.exists(files), "HD graphics found")
	var scaled := HdPack.load_from(files, graphics, null)
	assert_true(scaled != null, "read")
	if scaled == null:
		return
	assert_equal(scaled.factor, 2, "factor")
	assert_true(scaled.matches(graphics), "every image")
	assert_equal(scaled.sprites[0].get_size(), Vector2i(8, 4), "sprite size")
	assert_equal(scaled.sprites[0].get_pixel(0, 0).a, 1.0, "visible part of the sprite")
	assert_equal(scaled.sprites[0].get_pixel(7, 0).a, 0.0, "transparent part of the sprite")


func test_scaled_textures_keep_the_original_size() -> void:
	var graphics := _graphics()
	var textures := GraphicsTextures.create(graphics)
	assert_equal(textures.tile(0).get_size(), Vector2(16, 16), "original")
	textures.use_scaled(ScaledGraphics.with_xbrz(graphics, null, 2))
	assert_equal(textures.factor(), 2, "factor")
	var tile := textures.tile(0)
	assert_equal(tile.get_size(), Vector2(16, 16), "drawn at the original size")
	assert_equal(tile.get_image().get_size(), Vector2i(32, 32), "with twice the pixels")
	assert_equal(textures.sprite(0).get_size(), Vector2(4, 2), "sprite")
	var atlas := textures.tile_atlas(LevelTileSet.ATLAS_COLUMNS, LevelTileSet.PADDING)
	var cell := EgaGraphics.TILE_SIZE + 2 * LevelTileSet.PADDING
	assert_equal(atlas.get_size(), Vector2(LevelTileSet.ATLAS_COLUMNS * cell, cell), "atlas")
	assert_equal(atlas.get_image().get_size(), Vector2i(atlas.get_size()) * 2, "scaled atlas")


func test_tile_atlas_repeats_the_edges_of_each_tile() -> void:
	var graphics := _graphics()
	var atlas := GraphicsTextures.create(graphics).tile_atlas(LevelTileSet.ATLAS_COLUMNS, 1)
	var image := atlas.get_image()
	assert_equal(image.get_pixel(0, 0), image.get_pixel(1, 1), "corner of tile 0")
	assert_equal(image.get_pixel(18, 5), image.get_pixel(19, 5), "left edge of tile 1")
	assert_equal(image.get_pixel(17, 5), image.get_pixel(16, 5), "right edge of tile 0")


func test_interpolation_draws_in_between_ticks() -> void:
	var motion := Interpolation.new()
	motion.move_to(Vector2(10, 0))
	assert_equal(motion.at(0.5, true), Vector2(10, 0), "the first position has nothing before it")
	motion.move_to(Vector2(14, 2))
	assert_equal(motion.at(0.5, true), Vector2(12, 1), "halfway")
	assert_equal(motion.at(0.5, false), Vector2(14, 2), "without smooth motion: the last tick")
	motion.move_to(Vector2(14.6, 2.4))
	assert_equal(motion.at(0.0, false), Vector2(14, 2), "on whole pixels")
	motion.move_to(Vector2(200, 2))
	assert_equal(motion.at(0.0, true), Vector2(200, 2), "a jump is not drawn in between")
	motion.move_to(Vector2(204, 2))
	motion.snap()
	assert_equal(motion.at(0.0, true), Vector2(204, 2), "snap forgets the previous tick")


func test_graphics_switch_skips_hd_until_it_is_made() -> void:
	var original := DisplaySettings.Graphics.ORIGINAL
	var xbrz := DisplaySettings.Graphics.XBRZ
	var hd := DisplaySettings.Graphics.HD
	assert_equal(MenuController.next_graphics(original, false), xbrz, "original to xBRZ")
	assert_equal(MenuController.next_graphics(xbrz, false), original, "no HD")
	assert_equal(MenuController.next_graphics(xbrz, true), hd, "HD")
	assert_equal(MenuController.next_graphics(hd, true), original, "around")
	assert_equal(DisplaySettings.graphics_named("hd"), hd, "by name")
	assert_equal(DisplaySettings.graphics_named("nonsense"), original, "unknown name")


## An image from rows of "#" (black) and "." ([param background]).
static func _image(rows: PackedStringArray, background := Color.WHITE) -> Image:
	var image := Image.create_empty(rows[0].length(), rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in rows[y].length():
			image.set_pixel(x, y, Color.BLACK if rows[y][x] == "#" else background)
	return image


## Two tiles, two font characters, a bitmap and a sprite with transparency.
static func _graphics() -> EgaGraphics:
	var graphics := EgaGraphics.new()
	for i in 2:
		var tile := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
		tile.fill(EgaPalette.color(i + 1))
		tile.set_pixel(0, 0, Color.BLACK)
		graphics.tiles.append(tile)
		graphics.font_chars.append(_image(["#.......", ".#......"]))
	graphics.bitmaps.append(_image(["##..", "..##"]))
	graphics.sprites.append(_image(["##..", "##.."], Color.TRANSPARENT))
	return graphics


static func _remove(path: String) -> void:
	for folder in DirAccess.get_directories_at(path):
		_remove(path.path_join(folder))
	for file_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_name))
	DirAccess.remove_absolute(path)
