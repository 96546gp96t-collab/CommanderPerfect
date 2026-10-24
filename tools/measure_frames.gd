extends SceneTree
## Measures how long the game takes per frame with the realistic look off
## and on (docs/realistic/research.md §10: at least 60 frames per second,
## 99 % of the frames under 16.7 ms; with smooth motion on a 120 Hz screen
## under 8.3 ms). Vsync is off, so the numbers show what the computer can
## do, not the screen's rate. Keen walks to the right and jumps meanwhile,
## so the view scrolls. The settings file is not changed.
##
## Usage (not headless: it needs a window to render into), for example on
## the Mac, in full screen, in Keen 1's level 1:
##   godot --path . --script res://tools/measure_frames.gd -- --level=1
## SCENE picks another game's screen (res://src/keen4/keen4_view.tscn ...),
## FRAMES the number of frames per measurement (default 1800, 30 s at
## 60 frames per second), GRAPHICS=xbrz measures with xBRZ graphics,
## SMOOTH=1 with smooth motion, TWO=1 with a second player (F7).

const MAIN_SCENE := "res://src/game/level_view.tscn"
const DEFAULT_FRAMES := 1800
## Frames to let the scene start and the graphics be made before measuring,
## and again after switching.
const SETTLE_FRAMES := 180
const JUMP_EVERY := 50
const BUDGET_60_MS := 1000.0 / 60.0
const BUDGET_120_MS := 1000.0 / 120.0
const SHARE_UNDER_BUDGET := 0.99
const USEC_PER_MS := 1000.0

var _scene: GameScreen
var _frames_per_run := DEFAULT_FRAMES
## The runs still to do (false: the look off, true: on), and the frame
## times of the one going on.
var _runs: Array[bool] = [false, true]
var _times: PackedFloat64Array = []
var _settle_left := SETTLE_FRAMES
var _last_usec := 0
var _frame := 0
var _realistic_before := false


func _initialize() -> void:
	var frames := OS.get_environment("FRAMES")
	if frames.is_valid_int():
		_frames_per_run = maxi(frames.to_int(), 1)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var path := OS.get_environment("SCENE")
	var packed: PackedScene = load(path if not path.is_empty() else MAIN_SCENE)
	_scene = packed.instantiate() as GameScreen
	root.add_child(_scene)
	current_scene = _scene


func _set_up_scene() -> void:
	var settings := _scene._settings
	var graphics := OS.get_environment("GRAPHICS")
	if not graphics.is_empty():
		settings.graphics = DisplaySettings.graphics_named(graphics)
	settings.smooth_motion = OS.get_environment("SMOOTH") == "1"
	_scene._apply_graphics()
	_switch(_runs[0])
	if OS.get_environment("TWO") == "1":
		_press(&"toggle_second_player")


func _process(_delta: float) -> bool:
	if _frame == 0:
		# The scene is ready from the first frame on.
		_realistic_before = _scene._settings.realistic
		_set_up_scene()
	var now := Time.get_ticks_usec()
	var elapsed_ms := (now - _last_usec) / USEC_PER_MS
	_last_usec = now
	_frame += 1
	_steer()
	if _settle_left > 0:
		_settle_left -= 1
		return false
	_times.append(elapsed_ms)
	if _times.size() < _frames_per_run:
		return false
	_report(_runs.pop_front())
	_times.clear()
	if _runs.is_empty():
		_scene._settings.realistic = _realistic_before
		Input.action_release(&"move_right")
		return true
	_switch(_runs[0])
	_settle_left = SETTLE_FRAMES
	return false


## Keen walks right all the time and jumps every [constant JUMP_EVERY]
## frames.
func _steer() -> void:
	Input.action_press(&"move_right")
	if _frame % JUMP_EVERY == 0:
		Input.action_press(&"jump")
	elif _frame % JUMP_EVERY == JUMP_EVERY / 2:
		Input.action_release(&"jump")


func _switch(realistic: bool) -> void:
	_scene._settings.realistic = realistic
	_scene._apply_display_settings()


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)


func _report(realistic: bool) -> void:
	var sorted := _times.duplicate()
	sorted.sort()
	var total := 0.0
	for time in sorted:
		total += time
	var average := total / sorted.size()
	var p99 := sorted[mini(int(sorted.size() * SHARE_UNDER_BUDGET), sorted.size() - 1)]
	var slow := 0
	for time in sorted:
		if time > BUDGET_60_MS:
			slow += 1
	var window := DisplayServer.window_get_size()
	var line := (
		(
			"Realistic %s (%dx%d, %d frames): average %.2f ms (%.0f fps), 99%% under %.2f ms,"
			+ " slowest %.2f ms, %d frames over 16.7 ms. 60 fps: %s. 120 fps: %s."
		)
		% [
			"on " if realistic else "off",
			window.x,
			window.y,
			sorted.size(),
			average,
			1000.0 / average,
			p99,
			sorted[-1],
			slow,
			"pass" if p99 < BUDGET_60_MS else "FAIL",
			"pass" if p99 < BUDGET_120_MS else "fail",
		]
	)
	if realistic and RealisticLook.lighter:
		line += " The glow was switched off: too slow."
	print(line)
