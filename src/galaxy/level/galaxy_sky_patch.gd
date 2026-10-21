class_name GalaxySkyPatch
extends Node2D
## Paints the sky that the picture behind a level must not take
## ([GalaxySkyPockets]: such as the inside of level 9's glass) in the
## sky's own colour, behind the level's tiles and in front of the picture,
## so it looks as in the original (ours, D13.2).

var _rows: Array[Rect2i] = []
var _color := Color.TRANSPARENT


## Paints [param rows] (level pixels) in [param color]; nothing when empty.
func show_rows(rows: Array[Rect2i], color: Color) -> void:
	_rows = rows
	_color = color
	visible = not rows.is_empty()
	queue_redraw()


## The rows painted now (tests).
func rows() -> Array[Rect2i]:
	return _rows


func _draw() -> void:
	for row in _rows:
		draw_rect(Rect2(row), _color)
