class_name GraphicsTextures
extends RefCounted
## Textures of the game graphics, made the first time they are needed: font
## characters, tiles, sprites and bitmaps. Shared by the nodes that draw
## windows and screens, so that each picture becomes a texture only once.

var graphics: EgaGraphics
var _font: Dictionary[int, ImageTexture] = {}
var _clear_font: Dictionary[int, ImageTexture] = {}
var _tiles: Dictionary[int, ImageTexture] = {}
var _clear_tiles: Dictionary[int, ImageTexture] = {}
var _sprites: Dictionary[int, ImageTexture] = {}
var _bitmaps: Dictionary[String, ImageTexture] = {}


static func create(ega_graphics: EgaGraphics) -> GraphicsTextures:
	var textures := GraphicsTextures.new()
	textures.graphics = ega_graphics
	return textures


## Font character [param code], or null when the font has no such character.
func font_char(code: int) -> ImageTexture:
	if graphics == null or code < 0 or code >= graphics.font_chars.size():
		return null
	if not _font.has(code):
		_font[code] = ImageTexture.create_from_image(graphics.font_chars[code])
	return _font[code]


## Font character [param code] with its white background made transparent,
## for text straight on a map; null when there is no such character.
func clear_font_char(code: int) -> ImageTexture:
	if graphics == null or code < 0 or code >= graphics.font_chars.size():
		return null
	if not _clear_font.has(code):
		var image := graphics.font_chars[code].duplicate() as Image
		image.convert(Image.FORMAT_RGBA8)
		var white := EgaPalette.color(EgaPalette.WHITE)
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x, y).is_equal_approx(white):
					image.set_pixel(x, y, Color.TRANSPARENT)
		_clear_font[code] = ImageTexture.create_from_image(image)
	return _clear_font[code]


func tile(index: int) -> ImageTexture:
	if graphics == null or index < 0 or index >= graphics.tiles.size():
		return null
	if not _tiles.has(index):
		_tiles[index] = ImageTexture.create_from_image(graphics.tiles[index])
	return _tiles[index]


## Tile [param index] without the gray level background around the item on
## it, or null when there is no such tile. Only gray that touches the edge
## of the tile (directly or through other such gray) is removed, so gray
## inside the item stays.
func clear_tile(index: int) -> ImageTexture:
	if graphics == null or index < 0 or index >= graphics.tiles.size():
		return null
	if not _clear_tiles.has(index):
		var image := graphics.tiles[index].duplicate() as Image
		image.convert(Image.FORMAT_RGBA8)
		_clear_background(image, EgaPalette.color(EgaPalette.LIGHT_GRAY))
		_clear_tiles[index] = ImageTexture.create_from_image(image)
	return _clear_tiles[index]


func sprite(index: int) -> ImageTexture:
	if graphics == null or index < 0 or index >= graphics.sprites.size():
		return null
	if not _sprites.has(index):
		_sprites[index] = ImageTexture.create_from_image(graphics.sprites[index])
	return _sprites[index]


## The bitmap called [param bitmap_name] (such as "TITLE"), or null.
func bitmap(bitmap_name: String) -> ImageTexture:
	if graphics == null:
		return null
	if not _bitmaps.has(bitmap_name):
		var image := graphics.find_bitmap(bitmap_name)
		if image == null:
			return null
		_bitmaps[bitmap_name] = ImageTexture.create_from_image(image)
	return _bitmaps[bitmap_name]


## Makes every pixel of [param color] that is connected to the edge of
## [param image] transparent (a flood fill from the edges).
static func _clear_background(image: Image, color: Color) -> void:
	var size := image.get_size()
	var pending: Array[Vector2i] = []
	for x in size.x:
		pending.append_array([Vector2i(x, 0), Vector2i(x, size.y - 1)])
	for y in size.y:
		pending.append_array([Vector2i(0, y), Vector2i(size.x - 1, y)])
	while not pending.is_empty():
		var pixel: Vector2i = pending.pop_back()
		if not Rect2i(Vector2i.ZERO, size).has_point(pixel):
			continue
		if not image.get_pixelv(pixel).is_equal_approx(color):
			continue
		image.set_pixelv(pixel, Color.TRANSPARENT)
		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			pending.append(pixel + step)


## Draws [param text] in the game font on [param canvas], starting at
## [param at] (top left, in pixels). With [param clear] the white around
## the letters is left out.
func draw_text(canvas: CanvasItem, at: Vector2, text: String, clear := false) -> void:
	for index in text.length():
		var code := text.unicode_at(index)
		var texture := clear_font_char(code) if clear else font_char(code)
		if texture != null:
			canvas.draw_texture(texture, at + Vector2(index * EgaGraphics.FONT_CHAR_SIZE, 0))
