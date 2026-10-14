class_name GraphicsSheet
extends RefCounted
## Many small images on one large one, so that an upscaler such as
## Real-ESRGAN can do them all at once and they can be cut out again
## afterwards ([method cut]).
##
## Every image gets a border of [constant PADDING] pixels that repeats its
## edge pixels: the upscaler then sees the image continue past its edges
## instead of running into its neighbour, and the edges stay clean.
## The layout only depends on the sizes of the images, so the same images
## always give the same sheet.

const PADDING := 4
const MIN_WIDTH := 512

var image: Image
## Where each image sits on the sheet, without its border.
var rects: Array[Rect2i] = []


## The images packed in rows, in the order given. Transparent pixels get
## the color of the nearest visible one, and the sheet itself is opaque:
## the transparency goes on a separate sheet ([method pack_masks]).
static func pack(images: Array[Image]) -> GraphicsSheet:
	var sheet := GraphicsSheet.new()
	sheet.rects = layout(sizes_of(images))
	sheet.image = Image.create_empty(
		_width_of(sheet.rects), _height_of(sheet.rects), false, Image.FORMAT_RGB8
	)
	for i in images.size():
		var source := images[i].duplicate() as Image
		source.convert(Image.FORMAT_RGBA8)
		_fill_transparent(source)
		source.convert(Image.FORMAT_RGB8)
		sheet._put(source, sheet.rects[i])
	return sheet


## The transparency of [param images] as a sheet with the same layout as
## [method pack]: white where an image can be seen, black where not.
static func pack_masks(images: Array[Image]) -> GraphicsSheet:
	var masks: Array[Image] = []
	for source in images:
		var mask := Image.create_empty(
			source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8
		)
		for y in source.get_height():
			for x in source.get_width():
				var alpha := source.get_pixel(x, y).a
				mask.set_pixel(x, y, Color(alpha, alpha, alpha))
		masks.append(mask)
	return pack(masks)


## Where images of [param sizes] go on a sheet: in rows, from left to right.
static func layout(sizes: Array[Vector2i]) -> Array[Rect2i]:
	var width := MIN_WIDTH
	for size in sizes:
		width = maxi(width, size.x + 2 * PADDING)
	var rects: Array[Rect2i] = []
	var at := Vector2i.ZERO
	var row_height := 0
	for size in sizes:
		var outer := size + Vector2i(2 * PADDING, 2 * PADDING)
		if at.x + outer.x > width:
			at = Vector2i(0, at.y + row_height)
			row_height = 0
		rects.append(Rect2i(at + Vector2i(PADDING, PADDING), size))
		at.x += outer.x
		row_height = maxi(row_height, outer.y)
	return rects


## The size of the sheet for images of [param sizes].
static func size_for(sizes: Array[Vector2i]) -> Vector2i:
	var rects := layout(sizes)
	return Vector2i(_width_of(rects), _height_of(rects))


## Cuts the images out of [param scaled], a sheet made by [method pack] and
## then scaled up [param factor] times.
static func cut(scaled: Image, rects: Array[Rect2i], factor: int) -> Array[Image]:
	var images: Array[Image] = []
	for rect in rects:
		images.append(scaled.get_region(Rect2i(rect.position * factor, rect.size * factor)))
	return images


## The sizes of [param images], for [method layout].
static func sizes_of(images: Array[Image]) -> Array[Vector2i]:
	var sizes: Array[Vector2i] = []
	for source in images:
		sizes.append(source.get_size())
	return sizes


static func _width_of(rects: Array[Rect2i]) -> int:
	var width := MIN_WIDTH
	for rect in rects:
		width = maxi(width, rect.end.x + PADDING)
	return width


static func _height_of(rects: Array[Rect2i]) -> int:
	var height := 1
	for rect in rects:
		height = maxi(height, rect.end.y + PADDING)
	return height


## Puts [param source] at [param rect], with its edge pixels repeated around
## it.
func _put(source: Image, rect: Rect2i) -> void:
	var size := source.get_size()
	for y in range(-PADDING, size.y + PADDING):
		for x in range(-PADDING, size.x + PADDING):
			var color := source.get_pixel(clampi(x, 0, size.x - 1), clampi(y, 0, size.y - 1))
			image.set_pixel(rect.position.x + x, rect.position.y + y, color)


## Gives every transparent pixel the color of a visible neighbour, spreading
## outward step by step; pixels that no visible color reaches become black.
static func _fill_transparent(source: Image) -> void:
	var size := source.get_size()
	var pending: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			if source.get_pixel(x, y).a == 0.0:
				pending.append(Vector2i(x, y))
	while not pending.is_empty():
		var filled: Dictionary[Vector2i, Color] = {}
		for pixel in pending:
			for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbour: Vector2i = pixel + step
				if Rect2i(Vector2i.ZERO, size).has_point(neighbour):
					var color := source.get_pixelv(neighbour)
					if color.a > 0.0:
						filled[pixel] = Color(color, 1.0)
						break
		if filled.is_empty():
			break
		for pixel in filled:
			source.set_pixelv(pixel, filled[pixel])
		pending = pending.filter(func(pixel: Vector2i) -> bool: return not filled.has(pixel))
	for pixel in pending:
		source.set_pixelv(pixel, Color.BLACK)
