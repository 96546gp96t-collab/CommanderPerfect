extends "res://tests/test_case.gd"
## Tests waking in widescreen on Keen 4's real screen ([Keen4View], D13.2)
## with the player's files: in a level the view counts with the width it
## is drawn (objects wake up around it) and the width is kept among the
## frames for a save; in 4:3 and in a demo the original's 320 pixels
## count. The screen must be in a running scene tree (its _ready loads the
## files), so the suite runs among the runner's tree suites; settings and
## saves go to a folder of their own in the user folder, removed
## afterwards.

const TEST_DIRECTORY := "user://test_keen4_wide_waking_screen"
const VIEW_SCENE := "res://src/keen4/keen4_view.tscn"
const FIRST_LEVEL := 1
const FIRST_DEMO := 0
const BYTE_BITS := 8

var _view: Keen4View
var _tree: SceneTree


func _init() -> void:
	if Keen4Files.locate() == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null or not _tree.root.is_inside_tree():
		skip("needs a running scene tree (the screen loads its files when it is ready)")


func run_all() -> void:
	if not skip_reason.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	super.run_all()
	_free_view()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_a_level_wakes_objects_around_the_wide_view() -> void:
	if not _create_view():
		return
	_start_game_on(FIRST_LEVEL)
	var width := _view._settings.game_size().x
	assert_true(width > GalaxyCamera.VIEW_PIXELS.x, "widescreen by default")
	assert_equal(_view._played.camera.wide_width, width, "the view counts as wide as it is drawn")
	var frames := _view._recording.frames
	assert_equal(int(frames[0]), int(Keen4SavedGame.Event.VIEW_WIDTH), "kept for a save")
	assert_equal(frames[2] | (frames[3] << BYTE_BITS), width, "with its width")
	_view._settings.aspect = DisplaySettings.Aspect.ORIGINAL
	_view._apply_display_settings()
	assert_equal(_view._played.camera.wide_width, 0, "4:3: the original's view")
	var last := frames.size() - Keen4SavedGame.FRAME_BYTES
	assert_equal(frames[last] | (frames[last + 1] << BYTE_BITS), 0, "kept too")


func test_a_demo_wakes_objects_as_the_original() -> void:
	if not _create_view():
		return
	_view._settings.aspect = DisplaySettings.Aspect.WIDESCREEN
	_view._demo = GalaxyDemo.parse(_view._data.graphics.demo(FIRST_DEMO))
	_view._begin_demo(false)
	assert_true(_view._played != null, "the demo plays")
	assert_equal(_view._played.camera.wide_width, 0, "the original's view, also in widescreen")
	_view._apply_display_settings()
	assert_equal(_view._played.camera.wide_width, 0, "and after the settings")


func _create_view() -> bool:
	_free_view()
	var scene := load(VIEW_SCENE) as PackedScene
	var node := scene.instantiate() if scene != null else null
	if not node is Keen4View:
		if node != null:
			node.free()
		_fail("Keen 4's screen does not load")
		return false
	_view = node as Keen4View
	_view.files = Keen4Files.locate()
	_tree.root.add_child(_view)
	_view._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_view._keen4_settings.path = TEST_DIRECTORY.path_join("keen4.cfg")
	_view._saves.directory = TEST_DIRECTORY.path_join("saves")
	_view._settings.aspect = DisplaySettings.Aspect.WIDESCREEN
	return true


## A Normal game, standing on map [param number] (as a loaded game does).
func _start_game_on(number: int) -> void:
	_view._begin_game()
	_view._inventory = Keen4Inventory.new_game()
	_view._game_progress = Keen4Progress.new()
	_view._difficulty = GalaxyDifficulty.Level.NORMAL
	_view._show_level(number)


func _free_view() -> void:
	if _view != null:
		_view.get_parent().remove_child(_view)
		_view.free()
		_view = null


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
