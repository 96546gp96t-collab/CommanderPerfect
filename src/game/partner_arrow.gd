class_name PartnerArrow
extends Node2D
## Online each player sees only his own screen, so when the other player
## is out of sight a small arrow at the edge of the view points to him, in
## the color of his helmet (yellow for the host's Keen, blue for the other).
## Only for playing online: on one screen the split shows the way.
## Put the node in a CanvasLayer, so that the camera does not move it.

## The helmet colors of the two Keens (EGA yellow, and turned half way
## around the color wheel like player 2's sprite).
const HOST_COLOR := Color("ffff55")
const PARTNER_COLOR := Color("5555ff")
const OUTLINE_COLOR := Color("000000")
## Distance of the arrow's point from the edge of the view.
const MARGIN := 4.0
const LENGTH := 9.0
const HALF_WIDTH := 5.0

var color := PARTNER_COLOR
var _point := Vector2.ZERO
var _direction := Vector2.RIGHT


func _init() -> void:
	visible = false


## Points from the view [param view] (in level pixels) toward [param target]
## (in level pixels), or hides the arrow when the target is in sight.
func point_at(view: Rect2, target: Vector2) -> void:
	var placement := place(view, target)
	visible = not placement.is_empty()
	if visible:
		_point = placement[0]
		_direction = placement[1]
		queue_redraw()


## Where the arrow's point goes on the screen and which way it points, or
## empty when [param target] is in [param view].
static func place(view: Rect2, target: Vector2) -> Array:
	if not view.has_area() or view.has_point(target):
		return []
	var center := view.get_center()
	var direction := (target - center).normalized()
	var reach := view.size / 2.0 - Vector2(MARGIN, MARGIN)
	# How far along the direction the edge of the view (less the margin) is.
	var scale_x := reach.x / absf(direction.x) if not is_zero_approx(direction.x) else INF
	var scale_y := reach.y / absf(direction.y) if not is_zero_approx(direction.y) else INF
	var screen_point := view.size / 2.0 + direction * minf(scale_x, scale_y)
	return [screen_point, direction]


func _draw() -> void:
	var side := Vector2(-_direction.y, _direction.x) * HALF_WIDTH
	var back := _point - _direction * LENGTH
	var shape := PackedVector2Array([_point, back + side, back - side])
	draw_colored_polygon(shape, color)
	shape.append(_point)
	draw_polyline(shape, OUTLINE_COLOR, 1.0)
