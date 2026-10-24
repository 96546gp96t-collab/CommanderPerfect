extends "res://tests/test_case.gd"
## Tests for milestone R2: the option Realistic (F8) and its atmosphere
## ([RealisticLook], docs/realistic/research.md §7 and §10). Without files:
## off by default, the picture is the original then, and the look's layer
## only appears once the option is on, in front of the level and behind the
## HUD and the windows, in both viewports. With Keen 1's files: the game
## plays exactly the same with the option on (positions, score, lives,
## enemies, tick for tick). It needs a running scene tree; settings go to a
## folder of their own, removed afterwards.

const VIEW_SCENE := "res://src/game/level_view.tscn"
const TEST_DIRECTORY := "user://test_realistic_look"
const FRAME_SECONDS := 1.0 / 60.0
## Frames played in level 1 for the comparison, and every how many frames
## Keen jumps (with the right arrow held all the time).
const PLAY_FRAMES := 600
const JUMP_EVERY := 45
const JUMP_FRAMES := 20
const LEVEL := 1
## The game screens of all five games, each with a colour grade of its own.
const VIEW_SCENES: Array[String] = [
	"res://src/game/level_view.tscn",
	"res://src/keen2/keen2_view.tscn",
	"res://src/keen3/keen3_view.tscn",
	"res://src/keen4/keen4_view.tscn",
	"res://src/keen5/keen5_view.tscn",
]

var _tree: SceneTree
## Keen 1's game screen (level_view.gd has no class name).
var _view: GameScreen


func _init() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func run_all() -> void:
	KeyBindings.reset()
	super.run_all()
	_free_view()
	var path := ProjectSettings.globalize_path(TEST_DIRECTORY.path_join("settings.cfg"))
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_off_by_default_and_the_original_picture() -> void:
	var display := DisplaySettings.new()
	assert_true(not display.realistic, "off by default")
	assert_true(display.is_original_picture(), "the original picture")
	display.realistic = true
	assert_true(not display.is_original_picture(), "on: no longer the original picture")


func test_no_layer_until_the_option_is_on() -> void:
	_create_view()
	_view._settings.realistic = false
	_view._apply_display_settings()
	assert_true(_view._realistic_looks.is_empty(), "off: nothing made")
	assert_true(_view._world.get_node_or_null(^"RealisticLook") == null, "off: no layer")
	assert_equal(_view._world.size, _view._settings.game_size(), "off: the original viewport")


func test_the_layer_is_behind_the_hud_in_both_viewports() -> void:
	_create_view()
	_view._settings.realistic = true
	_view._apply_display_settings()
	assert_equal(_view._realistic_looks.size(), 2, "a look per viewport")
	var look: RealisticLook = _view._realistic_looks[0]
	var ui := _view._world.get_node(^"Ui") as CanvasLayer
	assert_true(look.get_parent() == _view._world, "the first in World")
	assert_true(_view._realistic_looks[1].get_parent() == _view._world_2, "the second in World2")
	assert_equal(look.layer, ui.layer, "the HUD's layer")
	assert_equal(look.get_index() + 1, ui.get_index(), "just before the HUD and the windows")
	assert_true(look.visible, "shown")
	assert_true(_view._world.size.y >= 2 * _view._settings.game_size().y, "a larger viewport")
	_view._settings.realistic = false
	_view._apply_display_settings()
	assert_true(not look.visible, "off again: hidden")
	assert_equal(_view._world.size, _view._settings.game_size(), "off again: the original")


func test_f8_switches_it_and_remembers() -> void:
	_create_view()
	var event := InputEventAction.new()
	event.action = &"toggle_realistic"
	event.pressed = true
	assert_true(_view._handle_display_keys(event), "F8 is a display key")
	assert_true(_view._settings.realistic, "on")
	var stored := UserSettings.load_from(_view._user_settings.path)
	assert_true(stored.display.realistic, "remembered")
	_view._handle_display_keys(event)
	assert_true(not _view._settings.realistic, "off again")
	assert_true(not UserSettings.load_from(_view._user_settings.path).display.realistic, "saved")


func test_a_slow_computer_loses_the_glow_not_frames() -> void:
	var look := RealisticLook.new()
	assert_true(not look.note_second(59.0, 60.0), "a second just under 60 is fine")
	assert_true(not look.note_second(40.0, 60.0), "one slow second")
	assert_true(not look.note_second(40.0, 60.0), "two")
	assert_true(not look.note_second(58.0, 60.0), "a good second starts again")
	assert_true(not look.note_second(30.0, 60.0), "one")
	assert_true(not look.note_second(30.0, 60.0), "two")
	assert_true(look.note_second(30.0, 60.0), "three slow seconds in a row")
	var other := RealisticLook.new()
	for second in RealisticLook.SLOW_SECONDS:
		assert_true(not other.note_second(46.0, 50.0), "a 50 Hz screen wants 50")
	look.free()
	other.free()


func test_every_game_has_its_own_grade() -> void:
	var tints: Array[Color] = []
	for path in VIEW_SCENES:
		var scene := load(path) as PackedScene
		var view := scene.instantiate() as GameScreen
		var grade := view._realistic_grade()
		view.free()
		assert_true(grade.shadow_tint != RealisticGrade.neutral().shadow_tint, path + ": a mood")
		assert_true(not tints.has(grade.shadow_tint), path + ": its own")
		tints.append(grade.shadow_tint)


func test_the_game_plays_the_same_with_it_on() -> void:
	if GameFiles.locate() == null:
		return
	var off := _record_level(false)
	var on := _record_level(true)
	assert_equal(off.size(), PLAY_FRAMES, "every frame recorded")
	assert_true(off[0] != off[-1], "Keen played: " + off[-1])
	for frame in off.size():
		if off[frame] != on[frame]:
			assert_equal(on[frame], off[frame], "frame %d" % frame)
			return


## Plays level 1 with the same keys and the option [param realistic], and
## returns what the game holds after every frame.
func _record_level(realistic: bool) -> Array[String]:
	_create_view()
	_view._settings.realistic = realistic
	_view._apply_display_settings()
	_view.call(&"_enter_level", LEVEL)
	var states: Array[String] = []
	Input.action_press(&"move_right")
	for frame in PLAY_FRAMES:
		if frame % JUMP_EVERY == 0:
			Input.action_press(&"jump")
		elif frame % JUMP_EVERY == JUMP_FRAMES:
			Input.action_release(&"jump")
		_view._process(FRAME_SECONDS)
		states.append(_state())
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	return states


func _state() -> String:
	var session: LevelSession = _view._session
	if session == null:
		return "no level"
	var parts := PackedStringArray(
		[
			str(session.keen.position),
			str(session.keen.velocity),
			str(_view._progress.inventory.score),
			str(_view._progress.inventory.lives),
			str(session.outcome),
		]
	)
	for actor in session.actors:
		parts.append(str(actor.position))
	return " ".join(parts)


func _create_view() -> void:
	_free_view()
	var scene := load(VIEW_SCENE) as PackedScene
	_view = scene.instantiate() as GameScreen
	_tree.root.add_child(_view)
	_view._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_view._settings.realistic = false
	_view._apply_display_settings()


func _free_view() -> void:
	if _view != null:
		_view.get_parent().remove_child(_view)
		_view.free()
		_view = null
