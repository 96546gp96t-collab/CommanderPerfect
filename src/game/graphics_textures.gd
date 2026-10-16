class_name GraphicsTextures
extends RefCounted
## Textures of the game graphics, made the first time they are needed: font
## characters, tiles, sprites, bitmaps and the picture of Keen's house.
## Shared by everything that draws them, so that each picture becomes a
## texture only once.
##
## With [member scaled] graphics (xBRZ or HD) the textures hold the larger
## images but keep the size of the original ones, so they are drawn in the
## same place at the same size; only the picture is sharper. Set it with
## [method use_scaled] and draw everything again.

var graphics: EgaGraphics
## The larger versions of the graphics, or null for the original pixels.
var scaled: ScaledGraphics
var _font: Dictionary[int, ImageTexture] = {}
var _clear_font: Dictionary[int, ImageTexture] = {}
var _tiles: Dictionary[int, ImageTexture] = {}
var _clear_tiles: Dictionary[int, ImageTexture] = {}
var _sprites: Dictionary[int, ImageTexture] = {}
var _bitmaps: Dictionary[String, ImageTexture] = {}
var _doors: Dictionary[PackedInt32Array, ImageTexture] = {}
var _finale: ImageTexture
## Tile atlases with a level's background color left out, by that color.
var _backdrop_atlases: Dictionary[Color, ImageTexture] = {}


static func create(ega_graphics: EgaGraphics) -> GraphicsTextures:
	var textures := GraphicsTextures.new()
	textures.graphics = ega_graphics
	return textures


## Switches to [param scaled_graphics] (null for the original pixels) and
## forgets every texture made so far.
func use_scaled(scaled_graphics: ScaledGraphics) -> void:
	scaled = scaled_graphics
	_font.clear()
	_clear_font.clear()
	_tiles.clear()
	_clear_tiles.clear()
	_sprites.clear()
	_bitmaps.clear()
	_doors.clear()
	_finale = null
	_backdrop_atlases.clear()


## How many times larger the images in the textures are than the original.
func factor() -> int:
	return scaled.factor if scaled != null else 1


## Font character [param code], or null when the font has no such character.
func font_char(code: int) -> ImageTexture:
	if graphics == null or code < 0 or code >= graphics.font_chars.size():
		return null
	if not _font.has(code):
		_font[code] = _texture(graphics.font_chars[code], _scaled_font_char(code))
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
		_clear_font[code] = _derived_texture(image, _scaled_font_char(code))
	return _clear_font[code]


func tile(index: int) -> ImageTexture:
	if graphics == null or index < 0 or index >= graphics.tiles.size():
		return null
	if not _tiles.has(index):
		_tiles[index] = _texture(graphics.tiles[index], _scaled_tile(index))
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
		_clear_tiles[index] = _derived_texture(image, _scaled_tile(index))
	return _clear_tiles[index]


func sprite(index: int) -> ImageTexture:
	if graphics == null or index < 0 or index >= graphics.sprites.size():
		return null
	if not _sprites.has(index):
		var big := scaled.sprites[index] if scaled != null else null
		_sprites[index] = _texture(graphics.sprites[index], big)
	return _sprites[index]


## The bitmap called [param bitmap_name] (such as "TITLE"), or null.
func bitmap(bitmap_name: String) -> ImageTexture:
	if graphics == null:
		return null
	if not _bitmaps.has(bitmap_name):
		var index := graphics.bitmap_index(bitmap_name)
		if index < 0:
			return null
		var big := scaled.bitmaps[index] if scaled != null else null
		_bitmaps[bitmap_name] = _texture(graphics.bitmaps[index], big)
	return _bitmaps[bitmap_name]


## The picture of Keen's house in [param original] (from FINALE.CK1).
func finale(original: Image) -> ImageTexture:
	if _finale == null and original != null:
		var big := scaled.finale if scaled != null else null
		_finale = _texture(original, big if big != null else null)
	return _finale


## The tiles [param tiles] stacked on top of each other in one picture,
## for a door that sinks into the floor.
func door(tiles: PackedInt32Array) -> ImageTexture:
	if not _doors.has(tiles):
		_doors[tiles] = _texture(_stack(graphics.tiles, tiles), _stack(_scaled_tiles(), tiles))
	return _doors[tiles]


## Every tile in one picture, [param columns] tiles wide, each with a border
## of [param padding] pixels that repeats its edge (so that smooth scaling
## never picks up a neighbour). Scaled graphics give a larger picture with
## the size of the original one.
func tile_atlas(columns: int, padding: int) -> ImageTexture:
	var original := _atlas(graphics.tiles, 1, columns, padding)
	var big := _atlas(scaled.tiles, scaled.factor, columns, padding) if scaled != null else null
	return _texture(original, big)


## The tile atlas of [method tile_atlas], with every pixel of
## [param color] that touches the edge of its tile (directly or through more
## of that color) left out: a level's plain background, so that a picture
## behind the level shows through ([LevelBackdrop]). Color inside the things
## on a tile stays. Scaled graphics get the same holes, enlarged.
func backdrop_tile_atlas(columns: int, padding: int, color: Color) -> ImageTexture:
	if _backdrop_atlases.has(color):
		return _backdrop_atlases[color]
	var originals: Array[Image] = []
	var bigs: Array[Image] = []
	for index in graphics.tiles.size():
		var image := graphics.tiles[index].duplicate() as Image
		image.convert(Image.FORMAT_RGBA8)
		_clear_background(image, color)
		originals.append(image)
		if scaled != null:
			bigs.append(_with_holes_of(scaled.tiles[index], image))
	var original := _atlas(originals, 1, columns, padding)
	var big := _atlas(bigs, scaled.factor, columns, padding) if scaled != null else null
	_backdrop_atlases[color] = _texture(original, big)
	return _backdrop_atlases[color]


func _scaled_font_char(code: int) -> Image:
	return scaled.font_chars[code] if scaled != null else null


func _scaled_tile(index: int) -> Image:
	return scaled.tiles[index] if scaled != null else null


func _scaled_tiles() -> Array[Image]:
	return scaled.tiles if scaled != null else ([] as Array[Image])


## A texture of [param original], showing [param big] (a scaled version of
## it, or null) at the size of the original.
static func _texture(original: Image, big: Image) -> ImageTexture:
	if big == null:
		return ImageTexture.create_from_image(original)
	var texture := ImageTexture.create_from_image(big)
	texture.set_size_override(original.get_size())
	return texture


## A texture of [param processed], an image made from an original one whose
## scaled version is [param big].
func _derived_texture(processed: Image, big: Image) -> ImageTexture:
	if scaled == null:
		return ImageTexture.create_from_image(processed)
	return _texture(processed, scaled.derive(processed, big))


## [param indices] of [param images] stacked on top of each other, or null
## when there are no such images.
static func _stack(images: Array[Image], indices: PackedInt32Array) -> Image:
	if images.is_empty():
		return null
	var size := images[indices[0]].get_size()
	var image := Image.create_empty(size.x, size.y * indices.size(), false, Image.FORMAT_RGBA8)
	for i in indices.size():
		var part := images[indices[i]].duplicate() as Image
		part.convert(Image.FORMAT_RGBA8)
		image.blit_rect(part, Rect2i(Vector2i.ZERO, size), Vector2i(0, i * size.y))
	return image


## [param images] (square, [param factor] times the tile size) in a grid of
## [param columns], each with a border of [param padding] original pixels.
static func _atlas(images: Array[Image], factor: int, columns: int, padding: int) -> Image:
	var tile := EgaGraphics.TILE_SIZE * factor
	var border := padding * factor
	var cell := tile + 2 * border
	var rows := ceili(images.size() / float(columns))
	var atlas := Image.create_empty(columns * cell, rows * cell, false, Image.FORMAT_RGBA8)
	for i in images.size():
		var source := images[i].duplicate() as Image
		source.convert(Image.FORMAT_RGBA8)
		var corner := Vector2i(i % columns, i / columns) * cell
		atlas.blit_rect(source, Rect2i(0, 0, tile, tile), corner + Vector2i(border, border))
		_repeat_edges(
			atlas, Rect2i(corner + Vector2i(border, border), Vector2i(tile, tile)), border
		)
	return atlas


## Copies the edge pixels of [param rect] in [param image] outward over
## [param border] pixels.
static func _repeat_edges(image: Image, rect: Rect2i, border: int) -> void:
	for step in border:
		var top := rect.position.y - 1 - step
		var bottom := rect.end.y + step
		var left := rect.position.x - 1 - step
		var right := rect.end.x + step
		image.blit_rect(
			image,
			Rect2i(rect.position.x, rect.position.y, rect.size.x, 1),
			Vector2i(rect.position.x, top)
		)
		image.blit_rect(
			image,
			Rect2i(rect.position.x, rect.end.y - 1, rect.size.x, 1),
			Vector2i(rect.position.x, bottom)
		)
		var tall := Rect2i(rect.position.x, top, 1, bottom - top + 1)
		image.blit_rect(image, tall, Vector2i(left, top))
		image.blit_rect(
			image, Rect2i(rect.end.x - 1, top, 1, bottom - top + 1), Vector2i(right, top)
		)


## [param big] (a scaled image) with the transparent pixels of
## [param small] (the original it was made from, with holes) cut out.
static func _with_holes_of(big: Image, small: Image) -> Image:
	var size := big.get_size()
	var mask := small.duplicate() as Image
	mask.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	var source := big.duplicate() as Image
	source.convert(Image.FORMAT_RGBA8)
	var result := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	result.blit_rect_mask(source, mask, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
	return result


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
