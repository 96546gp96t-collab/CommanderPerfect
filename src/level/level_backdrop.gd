class_name LevelBackdrop
extends CanvasLayer
## Draws a picture behind a level ([BackdropPictures]), on a canvas layer
## below the tiles, so the camera does not move it: [method follow] does.
##
## The picture is a little larger than the view, in its own shape, with
## its top at the top of the view, so its sky and horizon are always in
## sight (the level has its own floor). It glides from side to side as the
## view moves through the level: at the left edge of the level the left
## edge of the picture shows, at the right edge its right edge. So it moves
## more slowly than the level, which makes it look far away, and its edges
## are never seen. The wider the picture, the more it glides.

## Below the tiles, which are on the default layer 0.
const LAYER := -1
## The picture is this much larger than it has to be to cover the view, so
## that it has room to glide also in a level hardly larger than the view.
const ROOM := 1.15

var _sprite := Sprite2D.new()
var _level_area := Rect2()


func _init() -> void:
	layer = LAYER
	visible = false
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_sprite)


## Shows [param texture] behind the level whose playable area is
## [param level_area] (in level pixels); null shows nothing.
func show_picture(texture: Texture2D, level_area: Rect2) -> void:
	_sprite.texture = texture
	_level_area = level_area
	visible = texture != null


func is_showing() -> bool:
	return visible


## Puts the picture where it belongs for a view of [param view_size]
## centered on [param view_center] (in level pixels).
func follow(view_center: Vector2, view_size: Vector2) -> void:
	if not visible or _sprite.texture == null:
		return
	var rect := picture_rect(_sprite.texture.get_size(), _level_area, view_center, view_size)
	_sprite.position = rect.position
	_sprite.scale = rect.size / _sprite.texture.get_size()


## Where a picture of [param picture_size] goes in the view (in view
## pixels, from its top left), for a view of [param view_size] centered on
## [param view_center] in a level of [param level_area].
static func picture_rect(
	picture_size: Vector2, level_area: Rect2, view_center: Vector2, view_size: Vector2
) -> Rect2:
	if picture_size.x <= 0.0 or picture_size.y <= 0.0:
		return Rect2()
	var cover := maxf(view_size.x / picture_size.x, view_size.y / picture_size.y)
	var size := picture_size * cover * ROOM
	var view_left := view_center.x - view_size.x / 2.0
	var progress := _progress(view_left - level_area.position.x, level_area.size.x - view_size.x)
	return Rect2(Vector2(-(size.x - view_size.x) * progress, 0.0), size)


## How far through [param travel] the view is at [param offset], from 0 to
## 1; the middle when it cannot move at all.
static func _progress(offset: float, travel: float) -> float:
	if travel <= 0.0:
		return 0.5
	return clampf(offset / travel, 0.0, 1.0)
