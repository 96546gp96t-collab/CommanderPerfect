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
##              also with modifiers: Shift+I)
##   hold_KEY   press a key and keep it down
##   up_KEY     release a key
##   shot_NAME  save the window as OUT/NAME.png
## Key events are handled one frame after they are sent. Note that the game
## remembers settings, saved games and high scores in the user folder.

const MAIN_SCENE := "res://src/game/level_view.tscn"
const HOLD_PREFIX := "hold_"
const RELEASE_PREFIX := "up_"
const SHOT_PREFIX := "shot_"
## Frames to wait after the last step, so that it takes effect.
const FRAMES_AFTER := 2

var _frame := 0
var _steps: Array[Array] = []
var _out := ""


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
	var scene: PackedScene = load(MAIN_SCENE)
	root.add_child(scene.instantiate())


func _process(_delta: float) -> bool:
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
	var key_name := action.trim_prefix(HOLD_PREFIX).trim_prefix(RELEASE_PREFIX)
	var event := InputEventKey.new()
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
