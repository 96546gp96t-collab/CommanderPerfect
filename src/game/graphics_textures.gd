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
## Tiles without a patterned background, by tile and background tile.
var _clear_tiles_on: Dictionary[int, ImageTexture] = {}
var _sprites: Dictionary[int, ImageTexture] = {}
var _bitmaps: Dictionary[String, ImageTexture] = {}
var _doors: Dictionary[PackedInt32Array, ImageTexture] = {}
var _finale: ImageTexture
## Tile atlases with a level's background color left out, by that color.
var _backdrop_atlases: Dictionary[Color, ImageTexture] = {}
## The same with the holes of a [BackdropHoles] (by its key and whether the
## sky stays), the wall's masks, and every tile's kinds of hole.
var _hole_atlases: Dictionary[String, ImageTexture] = {}
var _wall_masks: Dictionary[String, ImageTexture] = {}
var _hole_kinds: Dictionary[String, Array] = {}


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
	_clear_tiles_on.clear()
	_sprites.clear()
	_bitmaps.clear()
	_doors.clear()
	_finale = null
	_backdrop_atlases.clear()
	_hole_atlases.clear()
	_wall_masks.clear()


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


## Tile [param index] without the patterned background around the item on
## it: every pixel that equals tile [param background] (Keen 2's lattice)
## at the same place and is joined to the tile's edge through more of
## them. Null when there is no such tile.
func clear_tile_on(index: int, background: int) -> ImageTexture:
	if graphics == null or index < 0 or index >= graphics.tiles.size():
		return null
	if background < 0 or background >= graphics.tiles.size():
		return clear_tile(index)
	var key := index * graphics.tiles.size() + background
	if not _clear_tiles_on.has(key):
		var image := graphics.tiles[index].duplicate() as Image
		image.convert(Image.FORMAT_RGBA8)
		var around := LatticeWalls.create(graphics.tiles[background]).item_background(image)
		for i in around.size():
			if around[i]:
				image.set_pixel(i % image.get_width(), i / image.get_width(), Color.TRANSPARENT)
		_clear_tiles_on[key] = _derived_texture(image, _scaled_tile(index))
	return _clear_tiles_on[key]


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


## The tile atlas of [method tile_atlas] with the holes of [param holes]
## left out: every hole, or with [param keep_sky] only the wall's (for the
## cells where the sky's colour is something else, such as a cone of light
## in a dark room). Scaled graphics get the same holes, enlarged.
func holes_tile_atlas(
	columns: int, padding: int, holes: BackdropHoles, keep_sky := false
) -> ImageTexture:
	var key := holes.key() + ("/sky kept" if keep_sky else "")
	if _hole_atlases.has(key):
		return _hole_atlases[key]
	_forget_other_levels(holes)
	var kinds := hole_kinds(holes)
	var originals: Array[Image] = []
	var bigs: Array[Image] = []
	for index in graphics.tiles.size():
		var image := BackdropHoles.cut(graphics.tiles[index], kinds[index], keep_sky)
		originals.append(image)
		if scaled != null:
			bigs.append(_with_holes_of(scaled.tiles[index], image))
	var original := _atlas(originals, 1, columns, padding)
	var big := _atlas(bigs, scaled.factor, columns, padding) if scaled != null else null
	_hole_atlases[key] = _texture(original, big)
	return _hole_atlases[key]


## Forgets the atlases, masks and kinds made for what another level shuts
## in, with the same rules as [param holes]: one level is played at a time,
## and with scaled graphics an atlas is large.
func _forget_other_levels(holes: BackdropHoles) -> void:
	var base := holes.base_key() + "/"
	var own := holes.key()
	for cache: Dictionary in [_hole_atlases, _hole_kinds, _wall_masks]:
		for key: String in cache.keys():
			if key.begins_with(base) and not key.begins_with(own):
				cache.erase(key)


## The wall's shape on every tile ([method BackdropHoles.mask]) in the
## layout of [method tile_atlas], at the size of the original tiles.
func wall_mask_atlas(columns: int, padding: int, holes: BackdropHoles) -> ImageTexture:
	var key := holes.key()
	if not _wall_masks.has(key):
		var masks: Array[Image] = []
		for kinds: PackedByteArray in hole_kinds(holes):
			masks.append(BackdropHoles.mask(kinds, EgaGraphics.TILE_SIZE))
		_wall_masks[key] = ImageTexture.create_from_image(_atlas(masks, 1, columns, padding))
	return _wall_masks[key]


## The kinds of hole ([method BackdropHoles.kinds_of]) of every tile, the
## frames of an animation alike ([method BackdropHoles.share_between_frames]),
## worked out once per set of rules (they do not depend on the scaled
## graphics); what a level shuts in ([member BackdropHoles.shut_in]) only
## changes the tiles it names.
func hole_kinds(holes: BackdropHoles) -> Array:
	var key := holes.key()
	if _hole_kinds.has(key):
		return _hole_kinds[key]
	var base_key := holes.base_key()
	if not _hole_kinds.has(base_key):
		var base: Array[PackedByteArray] = []
		for index in graphics.tiles.size():
			base.append(holes.base_kinds_of(index, graphics.tiles[index]))
		holes.share_between_frames(base, graphics.tiles)
		_hole_kinds[base_key] = base
	var kinds: Array[PackedByteArray] = []
	for index in graphics.tiles.size():
		kinds.append(holes.without_shut_in(index, _hole_kinds[base_key][index]))
	_hole_kinds[key] = kinds
	return kinds


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
