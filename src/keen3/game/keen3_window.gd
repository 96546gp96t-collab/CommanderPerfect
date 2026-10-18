class_name Keen3Window
extends GameWindow
## The [GameWindow] of Keen 3's screen (set as the script of the Window node
## in keen3_view.tscn), with two things Keen 3's status screen needs and the
## shared window does not have:
##   - tiles that sit half a cell lower than the grid
##     ([method put_tile_shifted]): the original draws the pistol, the ankh
##     and the keycards 4 px below a text row
##   - text in the font's second half ([method put_label]): characters
##     0x80-0xFF, red letters on a gray bar, which the original uses for the
##     status screen's labels
## and one that Mortimer's boxes and the ending need (milestone C7):
##   - a window at a fixed place ([method open_at]): its frame's top left on
##     a text cell of the original 320x200 picture, which sits in the middle
##     of a wider view. [GameWindow] draws it in the middle; the drawing is
##     moved from there.
## Everything else is [GameWindow]'s; the shared class is unchanged.

## The font's second half starts here.
const LABEL_FONT_OFFSET := 0x80
## The original picture, in the middle of the view.
const PICTURE_SIZE := Vector2i(320, 200)

var _shifted_tiles: Array[Dictionary] = []
## Where the frame's top left is, when the window has a fixed place.
var _placed_cell := Vector2i.ZERO
var _is_placed := false


func open(size: Vector2i) -> void:
	_shifted_tiles.clear()
	_is_placed = false
	super.open(size)


## Shows an empty window of [param size] cells (without the border) whose
## frame has its top left on text cell [param cell] of the 320x200 picture.
func open_at(cell: Vector2i, size: Vector2i) -> void:
	open(size)
	_is_placed = true
	_placed_cell = cell


func close() -> void:
	super.close()
	_is_placed = false


## Whether the window has a fixed place ([method open_at]).
func is_placed() -> bool:
	return _is_placed


## Draws tile [param tile] with its top left [param offset] pixels from the
## top left of [param cell].
func put_tile_shifted(cell: Vector2i, tile: int, offset: Vector2) -> void:
	_shifted_tiles.append({"cell": cell, "tile": tile, "offset": offset})
	queue_redraw()


## Writes [param text] from [param cell] in the font's second half.
func put_label(cell: Vector2i, text: String) -> void:
	put_text(cell, label_text(text))


## [param text] with every character moved to the font's second half.
static func label_text(text: String) -> String:
	var label := ""
	for index in text.length():
		label += char(text.unicode_at(index) + LABEL_FONT_OFFSET)
	return label


func _draw() -> void:
	if _is_placed:
		draw_set_transform(placement_offset())
	super._draw()
	if _textures == null or not visible:
		return
	var inside := _inside_origin()
	for item in _shifted_tiles:
		var texture := _textures.tile(item.tile)
		if texture != null:
			draw_texture(texture, inside + Vector2(item.cell * CELL) + item.offset)


## How far a window with a fixed place is drawn from where [GameWindow]
## puts it; zero for any other window.
func placement_offset() -> Vector2:
	if not _is_placed:
		return Vector2.ZERO
	var picture_origin := ((view_size - PICTURE_SIZE) / 2).max(Vector2i.ZERO)
	var wanted := Vector2(picture_origin + _placed_cell * CELL)
	return wanted - _frame_origin()


## The top left of the window's inside, where [GameWindow] puts it: in the
## middle of the view, on whole cells.
func _inside_origin() -> Vector2:
	return _frame_origin() + Vector2(CELL, CELL)


## The top left of the frame, where [GameWindow] puts it.
func _frame_origin() -> Vector2:
	var outer := (_size + Vector2i(2, 2)) * CELL
	var origin := Vector2(((view_size - outer) / 2 / CELL) * CELL)
	if at_bottom:
		origin.y = view_size.y - outer.y
	return origin
