class_name GalaxyWindow
extends RefCounted
## A message window of a Galaxy episode, drawn as the original draws them
## (Omni `id_us_1.c`: US_CenterWindow, US_DrawWindow, US_CPrint; facts
## only; docs/keen4/gameplay.md, "Message windows"), on a 320 × 200 picture
## the size of the original's screen:
##   - a window is a whole number of 8-pixel cells, centred on the 40 × 25
##     cells of the screen (rounded down);
##   - its inside is white; around it a frame of the masked 8×8 tiles 0-8
##     (corners, sides, edges) one cell outside;
##   - text is printed in the menu font, black, one line under the other
##     from the print line down, each line centred in the text area (the
##     window, or the part a picture leaves);
##   - pictures go anywhere in it, by their top-left corner.
## A message box ([Keen4Messages]) is a series of these steps; the picture
## of each box is [method image].

const SCREEN_SIZE := Vector2i(320, 200)
const CELL := 8
## The masked 8×8 tiles of the frame (Omni US_DrawWindow).
const TOP_LEFT := 0
const TOP := 1
const TOP_RIGHT := 2
const LEFT := 3
const RIGHT := 5
const BOTTOM_LEFT := 6
const BOTTOM := 7
const BOTTOM_RIGHT := 8
const INSIDE := Color.WHITE
const TEXT := Color.BLACK

## The window's inside, in screen pixels.
var inside := Rect2i()
## Where text goes: the window, or what a picture leaves of it.
var text_area := Rect2i()
## The top of the next line of text.
var print_y := 0
var _graphics: GalaxyGraphics
var _font: GalaxyFont
var _image: Image


## A window drawer with the tiles and pictures of [param graphics] and its
## font [param font_index].
static func create(graphics: GalaxyGraphics, font_index: int) -> GalaxyWindow:
	var window := GalaxyWindow.new()
	window._graphics = graphics
	window._font = graphics.font(font_index)
	window._image = Image.create_empty(SCREEN_SIZE.x, SCREEN_SIZE.y, false, Image.FORMAT_RGBA8)
	return window


## Draws an empty window of [param cells] (width and height in cells) in
## the middle of the screen (Omni US_CenterWindow).
func open_centred(cells: Vector2i) -> void:
	var screen_cells := SCREEN_SIZE / CELL
	var corner := (screen_cells - cells) / 2
	inside = Rect2i(corner * CELL, cells * CELL)
	text_area = inside
	print_y = inside.position.y
	_image.fill_rect(inside, INSIDE)
	var outer := inside.grow(CELL)
	var right := outer.end.x - CELL
	var bottom := outer.end.y - CELL
	_tile(TOP_LEFT, outer.position)
	_tile(TOP_RIGHT, Vector2i(right, outer.position.y))
	_tile(BOTTOM_LEFT, Vector2i(outer.position.x, bottom))
	_tile(BOTTOM_RIGHT, Vector2i(right, bottom))
	for x in range(outer.position.x + CELL, right, CELL):
		_tile(TOP, Vector2i(x, outer.position.y))
		_tile(BOTTOM, Vector2i(x, bottom))
	for y in range(outer.position.y + CELL, bottom, CELL):
		_tile(LEFT, Vector2i(outer.position.x, y))
		_tile(RIGHT, Vector2i(right, y))


## Draws picture [param index] (of the picture range) with its top-left
## corner [param offset] pixels from the window's.
func draw_picture(index: int, offset: Vector2i) -> void:
	var picture := _graphics.picture(index)
	if picture == null:
		push_error("No picture %d for a window." % index)
		return
	if picture.get_format() != Image.FORMAT_RGBA8:
		picture = picture.duplicate() as Image
		picture.convert(Image.FORMAT_RGBA8)
	_image.blit_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), inside.position + offset)


## Leaves [param left] pixels on the left and [param right] on the right
## of the text area for pictures (Omni: the window's x and width change).
func narrow(left: int, right: int) -> void:
	text_area = Rect2i(
		text_area.position.x + left,
		text_area.position.y,
		text_area.size.x - left - right,
		text_area.size.y
	)


## Moves the print line [param pixels] down.
func skip(pixels: int) -> void:
	print_y += pixels


## Prints [param text], each line centred in the text area, from the print
## line down (Omni US_CPrint).
func print_centred(text: String) -> void:
	if _font == null:
		return
	for line in _lines(text):
		var width := _font.text_width(line)
		_print_line(line, text_area.position.x + (text_area.size.x - width) / 2)


## Prints one line of [param text] in the middle of the window, both ways
## (Omni US_PrintCentered).
func print_in_middle(text: String) -> void:
	if _font == null:
		return
	var size := Vector2i(_font.text_width(text), _font.height)
	var at := inside.position + (inside.size - size) / 2
	print_y = at.y
	_print_line(text, at.x)


## How many pixels [param text] takes from top to bottom.
func text_height(text: String) -> int:
	return _lines(text).size() * (_font.height if _font != null else 0)


## A frame [param thickness] pixels wide just inside [param rect] (screen
## pixels) in [param color].
func outline(rect: Rect2i, thickness: int, color: Color) -> void:
	_image.fill_rect(Rect2i(rect.position, Vector2i(rect.size.x, thickness)), color)
	_image.fill_rect(Rect2i(rect.position.x, rect.end.y - thickness, rect.size.x, thickness), color)
	_image.fill_rect(Rect2i(rect.position, Vector2i(thickness, rect.size.y)), color)
	_image.fill_rect(Rect2i(rect.end.x - thickness, rect.position.y, thickness, rect.size.y), color)


## The screen as it is now: the window on a see-through picture.
func image() -> Image:
	return _image.duplicate() as Image


## Clears the screen picture (no window).
func clear() -> void:
	_image.fill(Color.TRANSPARENT)


## The lines of [param text]; a newline at its end starts none.
static func _lines(text: String) -> PackedStringArray:
	var lines := text.split("\n")
	if text.ends_with("\n"):
		lines.resize(lines.size() - 1)
	return lines


func _print_line(line: String, left: int) -> void:
	var picture := _font.render(line, TEXT)
	_image.blend_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), Vector2i(left, print_y))
	print_y += _font.height


func _tile(index: int, at: Vector2i) -> void:
	var tile := _graphics.tile8(index, true)
	if tile == null:
		return
	if tile.get_format() != Image.FORMAT_RGBA8:
		tile = tile.duplicate() as Image
		tile.convert(Image.FORMAT_RGBA8)
	_image.blend_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), at)
