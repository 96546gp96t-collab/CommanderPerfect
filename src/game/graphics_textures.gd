class_name GraphicsTextures
extends RefCounted
## Textures of the game graphics, made the first time they are needed: font
## characters, tiles, sprites and bitmaps. Shared by the nodes that draw
## windows and screens, so that each picture becomes a texture only once.

var graphics: EgaGraphics
var _font: Dictionary[int, ImageTexture] = {}
var _clear_font: Dictionary[int, ImageTexture] = {}
var _tiles: Dictionary[int, ImageTexture] = {}
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


## Draws [param text] in the game font on [param canvas], starting at
## [param at] (top left, in pixels). With [param clear] the white around
## the letters is left out.
func draw_text(canvas: CanvasItem, at: Vector2, text: String, clear := false) -> void:
	for index in text.length():
		var code := text.unicode_at(index)
		var texture := clear_font_char(code) if clear else font_char(code)
		if texture != null:
			canvas.draw_texture(texture, at + Vector2(index * EgaGraphics.FONT_CHAR_SIZE, 0))
