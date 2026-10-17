extends SceneTree
## Plays the game with scripted key presses and saves screenshots, to check
## screens and menus without playing by hand.
##
## Usage (not headless: it needs a window to render into):
##   STEPS="20:Space,30:shot_menu,32:Down,34:Enter" OUT=/tmp/shots \
##     godot --path . --script res://tools/scripted_play.gd
##
## STEPS is a list of FRAME:ACTION, where ACTION is one of
##   KEY        press and release a key (a Godot key name: Space, Down, A,
##              also with modifiers: Shift+I, and LeftShift or RightShift
##              for one of the two keys of a pair)
##   hold_KEY   press a key and keep it down
##   up_KEY     release a key
##   shot_NAME  save the window as OUT/NAME.png
##   type_TEXT  type TEXT, one key per character (for names and addresses)
##   mouse_X_Y  move the mouse to window pixel X, Y
##   click_X_Y  move the mouse there and click the left button
## SCENE picks another scene than the game screen, such as the start screen
## (res://src/launcher/launcher.tscn).
## WAIT_FOR_WINDOW=1 loads the scene and starts counting frames only once
## the window shows a picture. On macOS a new window can stay blank (white)
## for a varying number of frames, which made the frame numbers useless.
## Key events are handled one frame after they are sent. Note that the game
## remembers settings, saved games and high scores in the user folder.

const MAIN_SCENE := "res://src/game/level_view.tscn"
const HOLD_PREFIX := "hold_"
const RELEASE_PREFIX := "up_"
const SHOT_PREFIX := "shot_"
const TYPE_PREFIX := "type_"
const MOUSE_PREFIX := "mouse_"
const CLICK_PREFIX := "click_"
## Characters whose key has a name of its own.
const KEY_NAMES: Dictionary[String, String] = {".": "Period", ":": "Semicolon", "-": "Minus"}
## Prefixes for the left or right one of keys such as Shift.
const SIDES: Dictionary[String, KeyLocation] = {
	"Left": KEY_LOCATION_LEFT, "Right": KEY_LOCATION_RIGHT
}
## Frames to wait after the last step, so that it takes effect.
const FRAMES_AFTER := 2
## What the window gives before it has drawn anything.
const BLANK_COLOR := Color.WHITE

var _frame := 0
var _steps: Array[Array] = []
var _out := ""
var _scene_path := ""
var _waiting_for_window := false


func _initialize() -> void:
	_out = OS.get_environment("OUT")
	for part in OS.get_environment("STEPS").split(",", false):
		var bits := part.split(":")
		if bits.size() == 2 and bits[0].is_valid_int():
			_steps.append([bits[0].to_int(), bits[1]])
	if _steps.is_empty() or _out.is_empty():
		push_error("Set STEPS and OUT, see the comment at the top of this script.")
		quit(1)
		return
	_scene_path = OS.get_environment("SCENE")
	_waiting_for_window = OS.get_environment("WAIT_FOR_WINDOW") == "1"
	if not _waiting_for_window:
		_start_scene()


func _start_scene() -> void:
	var scene: PackedScene = load(_scene_path if not _scene_path.is_empty() else MAIN_SCENE)
	var node := scene.instantiate()
	root.add_child(node)
	# As the game itself does, so that changing scenes replaces this one.
	current_scene = node


func _process(_delta: float) -> bool:
	if _waiting_for_window:
		if _window_is_blank():
			return false
		_waiting_for_window = false
		_start_scene()
		return false
	_frame += 1
	for step in _steps:
		if step[0] == _frame:
			_do(step[1])
	return _steps.is_empty() or _frame > _steps[-1][0] + FRAMES_AFTER


func _do(action: String) -> void:
	if action.begins_with(SHOT_PREFIX):
		var path := _out.path_join(action.trim_prefix(SHOT_PREFIX) + ".png")
		root.get_texture().get_image().save_png(path)
		return
	if action.begins_with(MOUSE_PREFIX) or action.begins_with(CLICK_PREFIX):
		_mouse(action)
		return
	if action.begins_with(TYPE_PREFIX):
		for character in action.trim_prefix(TYPE_PREFIX):
			_type(character)
		return
	var key_name := action.trim_prefix(HOLD_PREFIX).trim_prefix(RELEASE_PREFIX)
	var event := InputEventKey.new()
	for side: String in SIDES:
		if key_name.begins_with(side) and key_name.length() > side.length():
			key_name = key_name.trim_prefix(side)
			event.location = SIDES[side]
	var code := OS.find_keycode_from_string(key_name)
	event.physical_keycode = code & KEY_CODE_MASK
	event.keycode = event.physical_keycode
	event.shift_pressed = code & KEY_MASK_SHIFT != 0
	event.ctrl_pressed = code & KEY_MASK_CTRL != 0
	event.alt_pressed = code & KEY_MASK_ALT != 0
	if key_name.length() == 1:
		event.unicode = key_name.unicode_at(0)
	event.pressed = not action.begins_with(RELEASE_PREFIX)
	Input.parse_input_event(event)
	if not action.begins_with(HOLD_PREFIX) and not action.begins_with(RELEASE_PREFIX):
		var release: InputEventKey = event.duplicate()
		release.pressed = false
		Input.parse_input_event(release)


## Whether the window has not drawn anything yet.
func _window_is_blank() -> bool:
	var image := root.get_texture().get_image()
	return image.get_pixel(image.get_width() / 2, image.get_height() / 2) == BLANK_COLOR


## Presses and releases the key for [param character], with its text.
func _type(character: String) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = OS.find_keycode_from_string(
		KEY_NAMES.get(character, character.to_upper())
	)
	event.keycode = event.physical_keycode
	event.unicode = character.unicode_at(0)
	event.pressed = true
	Input.parse_input_event(event)
	var release: InputEventKey = event.duplicate()
	release.pressed = false
	Input.parse_input_event(release)


## Moves the mouse to the place in [param action] (mouse_X_Y or
## click_X_Y), and clicks for click_.
func _mouse(action: String) -> void:
	var parts := action.split("_")
	var at := Vector2(parts[1].to_float(), parts[2].to_float())
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	if not action.begins_with(CLICK_PREFIX):
		return
	for pressed in [true, false]:
		var button := InputEventMouseButton.new()
		button.button_index = MOUSE_BUTTON_LEFT
		button.position = at
		button.global_position = at
		button.pressed = pressed
		Input.parse_input_event(button)
