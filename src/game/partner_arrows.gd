class_name PartnerArrows
extends Node2D
## Small arrows that show each player where the other one is, while the
## screen is split: next to each Keen, pointing toward his partner, in the
## partner's color. The arrows are drawn in the level, so each half of the
## screen shows only the arrow of its own player.

## Distance from the middle of Keen to the tip of the arrow.
const DISTANCE := 20.0
const LENGTH := 6.0
const WIDTH := 6.0
const OUTLINE_COLOR := Color(0.0, 0.0, 0.0, 0.8)
const OUTLINE_WIDTH := 1.0

var _tips := PackedVector2Array()
var _directions := PackedVector2Array()
var _colors := PackedColorArray()


## Shows an arrow next to each Keen whose middle is in [param centers],
## pointing to the other one; [param colors] has the color of each player.
## [param strength] (0-1) fades the arrows in.
func show_arrows(centers: Array[Vector2], colors: Array[Color], strength: float) -> void:
	_tips.clear()
	_directions.clear()
	_colors.clear()
	for player in centers.size():
		var partner := centers[(player + 1) % centers.size()]
		var direction := centers[player].direction_to(partner)
		if direction == Vector2.ZERO:
			continue
		_tips.append(centers[player] + direction * DISTANCE)
		_directions.append(direction)
		var color := colors[(player + 1) % colors.size()]
		color.a *= strength
		_colors.append(color)
	queue_redraw()


func hide_arrows() -> void:
	if _tips.is_empty():
		return
	_tips.clear()
	_directions.clear()
	_colors.clear()
	queue_redraw()


func _draw() -> void:
	for index in _tips.size():
		var tip := _tips[index]
		var direction := _directions[index]
		var side := direction.orthogonal() * WIDTH / 2.0
		var back := tip - direction * LENGTH
		var points := PackedVector2Array([tip, back + side, back - side])
		draw_colored_polygon(points, _colors[index])
		var outline := OUTLINE_COLOR
		outline.a *= _colors[index].a
		points.append(tip)
		draw_polyline(points, outline, OUTLINE_WIDTH)
