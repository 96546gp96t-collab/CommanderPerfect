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
## Everything else is [GameWindow]'s; the shared class is unchanged.

## The font's second half starts here.
const LABEL_FONT_OFFSET := 0x80

var _shifted_tiles: Array[Dictionary] = []


func open(size: Vector2i) -> void:
	_shifted_tiles.clear()
	super.open(size)


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
	super._draw()
	if _textures == null or not visible:
		return
	var inside := _inside_origin()
	for item in _shifted_tiles:
		var texture := _textures.tile(item.tile)
		if texture != null:
			draw_texture(texture, inside + Vector2(item.cell * CELL) + item.offset)


## The top left of the window's inside, where [GameWindow] puts it: in the
## middle of the view, on whole cells.
func _inside_origin() -> Vector2:
	var outer := (_size + Vector2i(2, 2)) * CELL
	var origin := Vector2(((view_size - outer) / 2 / CELL) * CELL)
	if at_bottom:
		origin.y = view_size.y - outer.y
	return origin + Vector2(CELL, CELL)
