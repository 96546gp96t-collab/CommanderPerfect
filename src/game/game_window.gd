class_name GameWindow
extends Node2D
## A window like the ones in the original game: white, framed with the pipe
## border from the font (characters 1-8), with text in the 8x8 font and,
## where needed, 16x16 tiles, sprites and bitmaps. The window sits in the
## middle of the view, or at the bottom (for the messages over the pictures
## of the ending).
##
## The content is laid out on a grid of 8x8 cells inside the border. Put the
## node in a CanvasLayer, so that the camera does not move it.

## Font characters that draw the border.
const BORDER_TOP_LEFT := 1
const BORDER_TOP := 2
const BORDER_TOP_RIGHT := 3
const BORDER_LEFT := 4
const BORDER_RIGHT := 5
const BORDER_BOTTOM_LEFT := 6
const BORDER_BOTTOM := 7
const BORDER_BOTTOM_RIGHT := 8
const CELL := EgaGraphics.FONT_CHAR_SIZE
## How faint a tile is drawn when it stands for something Keen does not have.
const DIMMED := Color(1, 1, 1, 0.2)

## Size of the view in game pixels; the window is centered in it.
var view_size := Vector2i(320, 200)
## Puts the window at the bottom of the view instead of in the middle.
var at_bottom := false
var _textures: GraphicsTextures
## Inside of the window in cells, without the border.
var _size := Vector2i.ONE
var _texts: Array[Dictionary] = []
var _tile_items: Array[Dictionary] = []
var _sprite_items: Array[Dictionary] = []
var _bitmap_items: Array[Dictionary] = []


func _init() -> void:
	visible = false


func set_textures(textures: GraphicsTextures) -> void:
	_textures = textures
	queue_redraw()


## Shows an empty window of [param size] cells (without the border).
func open(size: Vector2i) -> void:
	_size = size
	_texts.clear()
	_tile_items.clear()
	_sprite_items.clear()
	_bitmap_items.clear()
	visible = true
	queue_redraw()


func close() -> void:
	visible = false
	at_bottom = false


## Writes [param text] starting at [param cell].
func put_text(cell: Vector2i, text: String) -> void:
	_texts.append({"cell": cell, "text": text})
	queue_redraw()


## Writes [param text] so that it ends just before column [param end_column].
func put_text_right(end_column: int, row: int, text: String) -> void:
	put_text(Vector2i(end_column - text.length(), row), text)


## Draws tile [param tile] with its top left at [param cell]; a tile covers
## 2x2 cells.
func put_tile(cell: Vector2i, tile: int, dimmed := false) -> void:
	_tile_items.append({"cell": cell, "tile": tile, "dimmed": dimmed})
	queue_redraw()


## Draws sprite [param sprite] with its top left [param offset] pixels
## from the top left of [param cell].
func put_sprite(cell: Vector2i, sprite: int, offset := Vector2.ZERO) -> void:
	_sprite_items.append({"cell": cell, "sprite": sprite, "offset": offset})
	queue_redraw()


## Draws bitmap [param bitmap_name] (such as "GAMEOVER") with its top left
## at [param cell].
func put_bitmap(cell: Vector2i, bitmap_name: String) -> void:
	_bitmap_items.append({"cell": cell, "name": bitmap_name})
	queue_redraw()


## Shows [param lines] in a window just big enough for them, at least
## [param min_width] cells wide.
func show_lines(lines: PackedStringArray, min_width := 0) -> void:
	var width := min_width
	for line in lines:
		width = maxi(width, line.length())
	open(Vector2i(width, lines.size()))
	for row in lines.size():
		put_text(Vector2i(0, row), lines[row])


func _draw() -> void:
	if _textures == null:
		return
	var outer := (_size + Vector2i(2, 2)) * CELL
	var origin := Vector2(((view_size - outer) / 2 / CELL) * CELL)
	if at_bottom:
		origin.y = view_size.y - outer.y
	draw_rect(Rect2(origin, outer), Color.WHITE)
	_draw_border(origin)
	var inside := origin + Vector2(CELL, CELL)
	for item in _bitmap_items:
		var bitmap := _textures.bitmap(item.name)
		if bitmap != null:
			draw_texture(bitmap, inside + Vector2(item.cell * CELL))
	for item in _tile_items:
		var texture := _textures.tile(item.tile)
		if texture != null:
			draw_texture(
				texture, inside + Vector2(item.cell * CELL), DIMMED if item.dimmed else Color.WHITE
			)
	for item in _sprite_items:
		var sprite := _textures.sprite(item.sprite)
		if sprite != null:
			draw_texture(sprite, inside + Vector2(item.cell * CELL) + item.offset)
	for item in _texts:
		_textures.draw_text(self, inside + Vector2(item.cell * CELL), item.text)


func _draw_border(origin: Vector2) -> void:
	var last := _size + Vector2i.ONE
	_draw_char(origin, BORDER_TOP_LEFT)
	_draw_char(origin + Vector2(last.x, 0) * CELL, BORDER_TOP_RIGHT)
	_draw_char(origin + Vector2(0, last.y) * CELL, BORDER_BOTTOM_LEFT)
	_draw_char(origin + Vector2(last) * CELL, BORDER_BOTTOM_RIGHT)
	for x in range(1, last.x):
		_draw_char(origin + Vector2(x, 0) * CELL, BORDER_TOP)
		_draw_char(origin + Vector2(x, last.y) * CELL, BORDER_BOTTOM)
	for y in range(1, last.y):
		_draw_char(origin + Vector2(0, y) * CELL, BORDER_LEFT)
		_draw_char(origin + Vector2(last.x, y) * CELL, BORDER_RIGHT)


func _draw_char(at: Vector2, code: int) -> void:
	var texture := _textures.font_char(code)
	if texture != null:
		draw_texture(texture, at)
