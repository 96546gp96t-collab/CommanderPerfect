class_name GalaxyViewCover
extends Node2D
## Covers what a view wider than the original's (widescreen) would show
## beyond the area the original may show: past the scroll blocks or the
## map's border around the view ([method GalaxyCamera.area_pixels]).
## Decided by the user (19-10-2026; docs/keen4/research.md §13): covered
## with black, or with the picture behind the level when one is shown
## (the same picture at the same place as [LevelBackdrop] draws it, so it
## runs on seamlessly). While the view lies inside the area (always in
## 4:3) nothing is drawn, so the picture is exactly the original's.
##
## It is drawn over everything in the level (tiles of every layer and the
## sprites of every priority), in level pixels. (Clipping the level with
## [member CanvasItem.clip_children] does not work here: the tiles in
## front and the sprites have their own z index, which escapes the clip.)

## Over the in-front tiles and the sprites of the highest priority.
const COVER_Z := RenderingServer.CANVAS_ITEM_Z_MAX
const COVER_COLOR := Color.BLACK

var _area := Rect2i()
var _strips: Array[Rect2i] = []
var _picture: Texture2D
var _picture_rect := Rect2()


func _init() -> void:
	z_index = COVER_Z
	z_as_relative = false
	# As LevelBackdrop draws the picture.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## The parts of [param view] (pixels) outside [param area]: what must be
## covered. Empty when the view lies inside the area.
static func strips(area: Rect2i, view: Rect2i) -> Array[Rect2i]:
	var parts: Array[Rect2i] = []
	if area.encloses(view):
		return parts
	var inside := area.intersection(view)
	if inside.size.x <= 0 or inside.size.y <= 0:
		parts.append(view)
		return parts
	if inside.position.y > view.position.y:
		parts.append(
			Rect2i(
				view.position.x, view.position.y, view.size.x, inside.position.y - view.position.y
			)
		)
	if inside.end.y < view.end.y:
		parts.append(Rect2i(view.position.x, inside.end.y, view.size.x, view.end.y - inside.end.y))
	if inside.position.x > view.position.x:
		parts.append(
			Rect2i(
				view.position.x,
				inside.position.y,
				inside.position.x - view.position.x,
				inside.size.y
			)
		)
	if inside.end.x < view.end.x:
		parts.append(
			Rect2i(inside.end.x, inside.position.y, view.end.x - inside.end.x, inside.size.y)
		)
	return parts


## Covers what [param view] (pixels) shows outside [param area]. With
## [param picture] the cover shows that picture, drawn over
## [param picture_rect] (level pixels); otherwise black.
func cover(area: Rect2i, view: Rect2i, picture: Texture2D = null, picture_rect := Rect2()) -> void:
	_area = area
	_strips = strips(area, view)
	_picture = picture
	_picture_rect = picture_rect
	queue_redraw()


## Whether something is covered now.
func is_covering() -> bool:
	return not _strips.is_empty()


## The area the level may show, in pixels.
func area() -> Rect2i:
	return _area


func _draw() -> void:
	for strip in _strips:
		draw_rect(Rect2(strip), COVER_COLOR)
		if _picture == null or _picture_rect.size.x <= 0.0 or _picture_rect.size.y <= 0.0:
			continue
		var scale := Vector2(_picture.get_size()) / _picture_rect.size
		var source := Rect2(
			(Vector2(strip.position) - _picture_rect.position) * scale, Vector2(strip.size) * scale
		)
		draw_texture_rect_region(_picture, Rect2(strip), source)
