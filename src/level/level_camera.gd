class_name LevelCamera
extends Camera2D
## Camera that scrolls smoothly through a level without ever showing anything
## outside the playable area.
##
## The camera follows its parent node. When a level is smaller than the view
## along one axis (a narrow level on a widescreen display) the camera stays
## centered on that axis, with black bars on both sides.

const SMOOTHING_SPEED := 8.0
## Part of the view on each side of the center that Keen can move through
## without the view scrolling. Still to be compared with the original.
const DEAD_ZONE := Vector2(0.1, 0.2)


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = SMOOTHING_SPEED
	limit_smoothed = true


## Lets the followed node move freely near the center of the view
## ([param enabled], for Keen), or keeps it exactly centered (free look).
func use_dead_zone(enabled: bool) -> void:
	drag_horizontal_enabled = enabled
	drag_vertical_enabled = enabled
	drag_left_margin = DEAD_ZONE.x
	drag_right_margin = DEAD_ZONE.x
	drag_top_margin = DEAD_ZONE.y
	drag_bottom_margin = DEAD_ZONE.y


## Sets the scroll limits for a level area of [param area] pixels seen
## through a view of [param view_size] pixels.
func frame(area: Rect2i, view_size: Vector2i) -> void:
	var limits := limits_for(area, view_size)
	limit_left = limits.position.x
	limit_top = limits.position.y
	limit_right = limits.end.x
	limit_bottom = limits.end.y


## Scroll limits: [param area], grown evenly on every axis where it is
## smaller than [param view_size], so that the area ends up centered.
static func limits_for(area: Rect2i, view_size: Vector2i) -> Rect2i:
	var shortfall := (view_size - area.size).max(Vector2i.ZERO)
	return area.grow_individual(
		shortfall.x / 2,
		shortfall.y / 2,
		shortfall.x - shortfall.x / 2,
		shortfall.y - shortfall.y / 2
	)


## Where the center of the view can be, given the scroll limits. A point
## outside this range would only push the camera against its limits.
static func center_range(limits: Rect2i, view_size: Vector2i) -> Rect2:
	var half_view := Vector2(view_size) / 2.0
	return Rect2(Vector2(limits.position) + half_view, Vector2(limits.size - view_size))
