class_name AlienSignPlates
extends RefCounted
## The plates [AlienSignLabels] shows over the signs, in each game's own
## look: Keen 1-3 as their windows (white, with the pipe border and the 8x8
## font, [GameWindow]); Keen 4 and 5 white with a black edge and the
## game's window font.

const KEEN_CELL := EgaGraphics.FONT_CHAR_SIZE
## Space around the text of a Galaxy plate, and between its lines.
const GALAXY_MARGIN := Vector2i(3, 2)
const GALAXY_LINE_GAP := 1


## A Keen 1-3 window holding [param lines], from the font's [param chars].
static func keen(chars: Array[Image], lines: PackedStringArray) -> Image:
	var width := 0
	for line in lines:
		width = maxi(width, line.length())
	var cells := Vector2i(width + 2, lines.size() + 2)
	var image := Image.create_empty(
		cells.x * KEEN_CELL, cells.y * KEEN_CELL, false, Image.FORMAT_RGBA8
	)
	image.fill(Color.WHITE)
	var last := cells - Vector2i.ONE
	_put(image, chars, GameWindow.BORDER_TOP_LEFT, Vector2i.ZERO)
	_put(image, chars, GameWindow.BORDER_TOP_RIGHT, Vector2i(last.x, 0))
	_put(image, chars, GameWindow.BORDER_BOTTOM_LEFT, Vector2i(0, last.y))
	_put(image, chars, GameWindow.BORDER_BOTTOM_RIGHT, last)
	for x in range(1, last.x):
		_put(image, chars, GameWindow.BORDER_TOP, Vector2i(x, 0))
		_put(image, chars, GameWindow.BORDER_BOTTOM, Vector2i(x, last.y))
	for y in range(1, last.y):
		_put(image, chars, GameWindow.BORDER_LEFT, Vector2i(0, y))
		_put(image, chars, GameWindow.BORDER_RIGHT, Vector2i(last.x, y))
	for row in lines.size():
		var line := lines[row]
		# Centred, as the original centres short lines in its windows.
		var left := 1 + (width - line.length()) / 2
		for index in line.length():
			_put(image, chars, line.unicode_at(index), Vector2i(left + index, row + 1))
	return image


## A Keen 4-5 plate holding [param lines] in [param font].
static func galaxy(font: GalaxyFont, lines: PackedStringArray) -> Image:
	var width := 0
	for line in lines:
		width = maxi(width, font.text_width(line))
	var line_height := font.height + GALAXY_LINE_GAP
	var size := Vector2i(
		width + 2 * GALAXY_MARGIN.x,
		lines.size() * line_height - GALAXY_LINE_GAP + 2 * GALAXY_MARGIN.y
	)
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	image.fill_rect(Rect2i(Vector2i.ONE, size - Vector2i(2, 2)), Color.WHITE)
	for row in lines.size():
		var text := font.render(lines[row], Color.BLACK)
		var left := (size.x - font.text_width(lines[row])) / 2
		var at := Vector2i(left, GALAXY_MARGIN.y + row * line_height)
		image.blend_rect(text, Rect2i(Vector2i.ZERO, text.get_size()), at)
	return image


static func _put(image: Image, chars: Array[Image], code: int, cell: Vector2i) -> void:
	if code < 0 or code >= chars.size():
		return
	var glyph := chars[code]
	if glyph.get_format() != image.get_format():
		glyph = glyph.duplicate() as Image
		glyph.convert(image.get_format())
	image.blit_rect(glyph, Rect2i(Vector2i.ZERO, glyph.get_size()), cell * KEEN_CELL)
