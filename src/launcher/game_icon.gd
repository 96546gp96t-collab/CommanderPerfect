class_name GameIcon
extends Control
## The icon of one game on the start screen: a small light panel, like the
## [Hud], with Keen from the player's own graphics and the name of the game
## in the game's font. Drawn in "icon pixels" and enlarged by a whole
## number ([member pixel_scale]), so the pixels stay sharp.
##
## Under the mouse, or chosen with the keys or the controller, it is drawn a
## little darker. A click, Enter or A starts the game ([signal chosen]).
## Without the game's files it is gray, with the name in a plain font.

signal chosen

## Size in icon pixels: the sprite on the left, the name on the right.
const BASE_SIZE := Vector2i(96, 32)
const SPRITE_X := 6
const TEXT_X := 34
const CHAR := EgaGraphics.FONT_CHAR_SIZE
## How much darker it is under the mouse or when chosen with the keys.
const DARKER := Color(0.8, 0.8, 0.8)
const UNAVAILABLE := Color(0.55, 0.55, 0.55)
const TEXT_COLOR := Color("1a1a1a")

var title := ""
## Drawn on the left; null without the game's files.
var sprite: Texture2D
## The game's graphics, for its font; null without the game's files.
var textures: GraphicsTextures
## The name already drawn in the game's own font, for a game whose font
## [member textures] cannot hold (Keen 4); null: the name is drawn as text.
var title_picture: Texture2D
var available := true:
	set(value):
		available = value
		_update_look()
var pixel_scale := 1:
	set(value):
		pixel_scale = maxi(1, value)
		custom_minimum_size = Vector2(BASE_SIZE * pixel_scale)
		size = custom_minimum_size
		queue_redraw()
var _hovered := false


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_set_hovered.bind(true))
	mouse_exited.connect(_set_hovered.bind(false))
	focus_entered.connect(_update_look)
	focus_exited.connect(_update_look)
	pixel_scale = 1


## Whether it is drawn darker: under the mouse, or chosen with the keys.
func is_darker() -> bool:
	return _hovered or has_focus()


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	var clicked := button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT
	if clicked or event.is_action_pressed("ui_accept"):
		accept_event()
		chosen.emit()


func _set_hovered(hovered: bool) -> void:
	_hovered = hovered
	_update_look()


func _update_look() -> void:
	var tint := UNAVAILABLE if not available else Color.WHITE
	modulate = tint * DARKER if is_darker() else tint


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(pixel_scale, pixel_scale))
	var panel := Rect2(Vector2(1, 1), Vector2(BASE_SIZE) - Vector2(2, 2))
	draw_rect(panel, Hud.PANEL_COLOR)
	draw_rect(panel, Hud.OUTLINE_COLOR, false, 1.0)
	if sprite != null:
		var top := floorf((BASE_SIZE.y - sprite.get_height()) / 2.0)
		draw_texture(sprite, Vector2(SPRITE_X, top))
	var text_top := (BASE_SIZE.y - CHAR) / 2
	if title_picture != null:
		var title_top := floorf((BASE_SIZE.y - title_picture.get_height()) / 2.0)
		draw_texture(title_picture, Vector2(TEXT_X, title_top))
	elif textures != null:
		textures.draw_text(self, Vector2(TEXT_X, text_top), title, true)
	else:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(TEXT_X, text_top + CHAR), title, 0, -1, CHAR + 2, TEXT_COLOR)
