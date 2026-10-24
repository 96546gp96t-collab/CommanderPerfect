extends SceneTree
## Measures how long the game takes per frame with the realistic look off
## and on (docs/realistic/research.md §10: at least 60 frames per second,
## 99 % of the frames under 16.7 ms; with smooth motion on a 120 Hz screen
## under 8.3 ms). Vsync is off, so the numbers show what the computer can
## do, not the screen's rate. Keen walks right and left in turn and jumps
## meanwhile, so the view scrolls; he cannot die (god mode). Each
## measurement starts the game screen anew, and the game moves on by a
## fixed 1/60 s per frame, however long the frame took: both measurements
## see the same game, frame for frame (before, the second went on where the
## first ended, and a slow frame let Keen walk further, often out of the
## level). The report says where Keen was at the end. The settings file is
## not changed.
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
## Frames Keen walks one way before he turns.
const TURN_EVERY := 240
## How far the game moves on per frame.
const GAME_STEP := 1.0 / 60.0
const BUDGET_60_MS := 1000.0 / 60.0
const BUDGET_120_MS := 1000.0 / 120.0
const SHARE_UNDER_BUDGET := 0.99
const USEC_PER_MS := 1000.0

var _scene: GameScreen
var _packed: PackedScene
var _frames_per_run := DEFAULT_FRAMES
## The runs still to do (false: the look off, true: on), and the frame
## times of the one going on.
var _runs: Array[bool] = [false, true]
var _times: PackedFloat64Array = []
var _settle_left := SETTLE_FRAMES
var _last_usec := 0
var _frame := 0
## Whether the new scene still waits for its settings (it is ready a frame
## after it is added).
var _set_up_pending := true


func _initialize() -> void:
	var frames := OS.get_environment("FRAMES")
	if frames.is_valid_int():
		_frames_per_run = maxi(frames.to_int(), 1)
	RealisticLook.may_get_lighter = false
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var path := OS.get_environment("SCENE")
	_packed = load(path if not path.is_empty() else MAIN_SCENE)
	_start_scene()


## A new game screen: with the command-line options it starts where they
## say, as the game itself does.
func _start_scene() -> void:
	if _scene != null:
		root.remove_child(_scene)
		_scene.free()
	_scene = _packed.instantiate() as GameScreen
	root.add_child(_scene)
	current_scene = _scene
	_set_up_pending = true
	_frame = 0
	_settle_left = SETTLE_FRAMES


func _set_up_scene() -> void:
	var settings := _scene._settings
	var graphics := OS.get_environment("GRAPHICS")
	if not graphics.is_empty():
		settings.graphics = DisplaySettings.graphics_named(graphics)
	settings.smooth_motion = OS.get_environment("SMOOTH") == "1"
	_scene._apply_graphics()
	_switch(_runs[0])
	# The game moves on in fixed steps, from here (see the top).
	_scene.set_process(false)
	_scene._god_mode = true
	if _scene._session != null:
		_scene._session.set_invincible(true)
	if OS.get_environment("TWO") == "1":
		_press(&"toggle_second_player")


func _process(_delta: float) -> bool:
	if _set_up_pending:
		# The scene is ready from the frame after it was added.
		_set_up_pending = false
		_set_up_scene()
	var now := Time.get_ticks_usec()
	var elapsed_ms := (now - _last_usec) / USEC_PER_MS
	_last_usec = now
	_frame += 1
	_steer()
	_scene._process(GAME_STEP)
	if _settle_left > 0:
		_settle_left -= 1
		return false
	_times.append(elapsed_ms)
	if _times.size() < _frames_per_run:
		return false
	_report(_runs.pop_front())
	_times.clear()
	for action: StringName in [&"move_right", &"move_left", &"jump"]:
		Input.action_release(action)
	if _runs.is_empty():
		return true
	_start_scene()
	return false


## Keen walks right and left in turn and jumps every
## [constant JUMP_EVERY] frames.
func _steer() -> void:
	var right := (_frame / TURN_EVERY) % 2 == 0
	if right:
		Input.action_release(&"move_left")
		Input.action_press(&"move_right")
	else:
		Input.action_release(&"move_right")
		Input.action_press(&"move_left")
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
			"Realistic %s (%dx%d, %d frames, ended %s): average %.2f ms (%.0f fps),"
			+ " 99%% under %.2f ms, slowest %.2f ms, %d frames over 16.7 ms."
			+ " 60 fps: %s. 120 fps: %s."
		)
		% [
			"on " if realistic else "off",
			window.x,
			window.y,
			sorted.size(),
			_place(),
			average,
			1000.0 / average,
			p99,
			sorted[-1],
			slow,
			"pass" if p99 < BUDGET_60_MS else "FAIL",
			"pass" if p99 < BUDGET_120_MS else "fail",
		]
	)
	print(line)


## Where Keen is now: "in the level", "on the map", ...
func _place() -> String:
	match _scene._mode:
		GameScreen.Mode.LEVEL:
			return "in the level"
		GameScreen.Mode.MAP:
			return "on the map"
	return "elsewhere (" + GameScreen.Mode.keys()[_scene._mode].to_lower() + ")"
