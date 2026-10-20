class_name GalaxyViewClip
extends Node2D
## Holds the tiles and sprites of a Galaxy level and lets them show only
## inside the area the original's view may show: between the scroll blocks
## (or the map's border) around the view ([method GalaxyCamera.area_pixels]).
##
## Only a view wider than the original's (widescreen) can reach beyond that
## area; there the level is not drawn, so the black behind it shows, or the
## picture behind the level when one is shown ([LevelBackdrop], on a canvas
## layer below). Decided by the user (19-10-2026; docs/keen4/research.md
## §13). While the view lies inside the area (always in 4:3) nothing is
## clipped, so the picture is exactly the original's.

var _area := Rect2i()


## Lets the level show only inside [param area] (pixels) while
## [param view] (pixels) reaches beyond it; otherwise nothing is clipped.
func show_area(area: Rect2i, view: Rect2i) -> void:
	var clipping := not area.encloses(view)
	if area != _area or clipping != is_clipping():
		_area = area
		clip_children = (
			CanvasItem.CLIP_CHILDREN_ONLY if clipping else CanvasItem.CLIP_CHILDREN_DISABLED
		)
		queue_redraw()


## Whether the level is clipped now.
func is_clipping() -> bool:
	return clip_children != CanvasItem.CLIP_CHILDREN_DISABLED


## The area the level may show, in pixels.
func area() -> Rect2i:
	return _area


func _draw() -> void:
	# Only the shape counts: with clip_children only, this rectangle is not
	# drawn itself. Without clipping it must not be drawn at all.
	if is_clipping():
		draw_rect(Rect2(_area), Color.WHITE)
