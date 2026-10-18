class_name Keen3ScreenTint
extends Node2D
## A colour over the whole game picture, for Keen 3's ending (milestone C7):
## black with some alpha while the hall or the picture fades, or (added)
## light for a camera flash, which in the original switches to a palette
## where every colour is bright. Put it last in the World's UI layer, so
## that it lies over everything the game draws.

## How much lighter a camera flash makes every colour (our reading of the
## camera-flash palette: all colours bright).
const FLASH_LIGHT := Color(0.6, 0.6, 0.6)

## Size of the view in game pixels.
var view_size := Vector2i(320, 200)
var _color := Color.TRANSPARENT


## A tint that darkens (normal blending) or, with [param adds_light],
## lightens every colour.
static func create(adds_light: bool) -> Keen3ScreenTint:
	var tint := Keen3ScreenTint.new()
	if adds_light:
		var light := CanvasItemMaterial.new()
		light.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		tint.material = light
	return tint


## Shows [param color] over the picture; transparent shows nothing.
func show_color(color: Color) -> void:
	if color == _color:
		return
	_color = color
	visible = color.a > 0.0
	queue_redraw()


func _draw() -> void:
	if _color.a > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(view_size)), _color)
