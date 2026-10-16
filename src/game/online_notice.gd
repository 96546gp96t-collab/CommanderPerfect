class_name OnlineNotice
extends Node2D
## A short note in the bottom right corner of the view, such as "Billy
## joined": on a small light panel like the [Hud], with the game font, for
## a few seconds. Put the node in a CanvasLayer, so that the camera does
## not move it.

const SECONDS := 4.0
const CHAR := EgaGraphics.FONT_CHAR_SIZE
const MARGIN := Hud.MARGIN
const PADDING := 3

## Size of the view in game pixels; the panel sits in its corner.
var view_size := Vector2i(426, 200)
var _textures: GraphicsTextures
var _text := ""
var _time_left := 0.0


func _init() -> void:
	visible = false


func set_textures(textures: GraphicsTextures) -> void:
	_textures = textures
	queue_redraw()


## Shows [param text] for [constant SECONDS] seconds.
func show_text(text: String) -> void:
	_text = text
	_time_left = SECONDS
	visible = true
	queue_redraw()


func text() -> String:
	return _text if visible else ""


func _process(delta: float) -> void:
	if not visible:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		visible = false


func _draw() -> void:
	if _textures == null or _text.is_empty():
		return
	var size := Vector2(_text.length() * CHAR + 2 * PADDING, CHAR + 2 * PADDING)
	var rect := Rect2(Vector2(view_size) - size - Vector2(MARGIN, MARGIN), size)
	draw_rect(rect, Hud.PANEL_COLOR)
	draw_rect(rect.grow(1), Hud.OUTLINE_COLOR, false, 1.0)
	_textures.draw_text(self, rect.position + Vector2(PADDING, PADDING), _text, true)
