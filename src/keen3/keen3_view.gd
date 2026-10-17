class_name Keen3View
extends Control
## The Keen 3 game scene that the start screen opens. For now (milestone
## C2) it only says that Keen 3 is coming; Enter or Escape goes back to the
## start screen. Milestone C3 replaces it with the real game (see
## docs/keen3/architecture.md).

const BACKGROUND_COLOR := Color("303030")
const TEXT_COLOR := Color("e0e0e0")
const MESSAGE := "Keen 3 - coming soon"
const HINT := "Press Enter or Escape to choose another game."
## The message is this part of the window height; the hint half of it.
const MESSAGE_SHARE := 0.06
const HINT_SHARE := 0.03
const MIN_FONT_SIZE := 12

var _message := Label.new()
var _hint := Label.new()


func _ready() -> void:
	# The start screen asks every game to open its menu; there is none yet.
	GameLaunch.take_menu_request()
	_build()
	resized.connect(_arrange)
	_arrange()


## The text on the screen.
func message() -> String:
	return _message.text


## Whether [param event] leaves for the start screen: Enter or Escape.
static func is_back_event(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept")


func _unhandled_input(event: InputEvent) -> void:
	if not is_back_event(event):
		return
	get_viewport().set_input_as_handled()
	# Deferred: this runs inside the handling of a key, and changing the
	# scene takes this one out of the tree at once.
	get_tree().change_scene_to_file.call_deferred(GameLaunch.LAUNCHER_SCENE)


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	for label: Label in [_message, _hint]:
		label.add_theme_color_override("font_color", TEXT_COLOR)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(label)
	_message.text = MESSAGE
	_hint.text = HINT


## The message in the middle, the hint below it, both scaled to the window.
func _arrange() -> void:
	var message_size := maxi(MIN_FONT_SIZE, roundi(size.y * MESSAGE_SHARE))
	var hint_size := maxi(MIN_FONT_SIZE, roundi(size.y * HINT_SHARE))
	_message.add_theme_font_size_override("font_size", message_size)
	_hint.add_theme_font_size_override("font_size", hint_size)
	var middle := size.y / 2.0
	_message.position = Vector2(0.0, middle - message_size * 2.0)
	_message.size = Vector2(size.x, message_size * 2.0)
	_hint.position = Vector2(0.0, middle + hint_size)
	_hint.size = Vector2(size.x, hint_size * 2.0)
