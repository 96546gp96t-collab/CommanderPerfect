extends "res://tests/test_case.gd"
## Tests smooth motion and xBRZ in Keen 4 on the real screen ([Keen4View],
## milestone D11) with the player's files: a level shown in xBRZ stays in
## xBRZ when a switch or a gem puts a tile its atlas lacks (a stand-in, the
## original tile made larger, until the tile is scaled; it used to flash
## back to the original graphics), the overlays (title layer with the
## panel, the help, the boxes) keep the original's sharp pixels when the
## World viewport filters for xBRZ, and with smooth motion the view and the
## sprites move between the logic frames (more places than without). The
## screen must be in a running scene tree (a TREE_SUITES suite).

const TEST_DIRECTORY := "user://test_keen4_d11_xbrz"
const FIRST_LEVEL := 1
const UNDER_WATER := 17
## Screen frames at 120 a second: about 1.5 s of play.
const FRAME_SECONDS := 1.0 / 120.0
const FRAMES := 180

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
	super.run_all()
	_free_view()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_an_xbrz_level_stays_xbrz_when_a_tile_is_missing() -> void:
	_create_view()
	_view._settings.graphics = DisplaySettings.Graphics.XBRZ
	_start_game_on(FIRST_LEVEL)
	_view._scaled.finish()
	_view._apply_graphics()
	assert_true(_view._showing_scaled, "level 1 in xBRZ once scaled")
	assert_true(not _view._stand_ins, "no stand-ins then")
	var tile := _missing_fore_tile()
	assert_true(tile > 0, "a foreground tile level 1 does not show")
	_view._galaxy_map.set_tile(GalaxyMap.Layer.FOREGROUND, Vector2i(2, 2), tile)
	assert_true(_view._showing_scaled, "still xBRZ (no flash back to the original)")
	assert_true(_view._stand_ins, "the new tile is a stand-in while it is scaled")
	assert_true(_view._scaled.fore_tile(tile) == null, "not scaled yet")
	_view._scaled.finish()
	_view._apply_graphics()
	assert_true(_view._showing_scaled, "xBRZ")
	assert_true(not _view._stand_ins, "the stand-in replaced by the scaled tile")
	assert_true(_view._scaled.fore_tile(tile) != null, "the tile scaled")


func test_a_stand_in_is_the_original_made_larger() -> void:
	_create_view()
	_view._settings.graphics = DisplaySettings.Graphics.XBRZ
	_start_game_on(FIRST_LEVEL)
	_view._scaled.finish()
	_view._apply_graphics()
	var tile := _missing_fore_tile()
	var original := _view._data.graphics.fore_tile(tile)
	var big := _view._stand_in(original)
	var factor: int = _view._scaled.factor
	assert_equal(big.get_size(), original.get_size() * factor, "%d× larger" % factor)
	assert_equal(
		big.get_pixel(factor * 3 + factor - 1, factor * 5),
		original.get_pixel(3, 5),
		"nearest: each pixel a block"
	)


func test_the_original_graphics_have_no_stand_ins() -> void:
	_create_view()
	_view._settings.graphics = DisplaySettings.Graphics.ORIGINAL
	_start_game_on(FIRST_LEVEL)
	var tile := _missing_fore_tile()
	_view._galaxy_map.set_tile(GalaxyMap.Layer.FOREGROUND, Vector2i(2, 2), tile)
	assert_true(not _view._showing_scaled, "original graphics")
	assert_true(not _view._stand_ins, "nothing stands in")


func test_the_overlays_keep_sharp_pixels() -> void:
	_create_view()
	assert_equal(
		_view._title_layer.texture_filter,
		CanvasItem.TEXTURE_FILTER_NEAREST,
		"the title layer (the panel, the help, the end pages)"
	)
	_view._settings.graphics = DisplaySettings.Graphics.XBRZ
	_start_game_on(FIRST_LEVEL)
	_view._open_panel()
	assert_equal(
		_view._title_layer.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "the panel in xBRZ"
	)


func test_smooth_motion_moves_between_the_frames() -> void:
	# Level 1: Keen starts at its right end and walks left; level 17: he
	# swims right (seen in the screenshots).
	for way: Array in [[FIRST_LEVEL, "move_left"], [UNDER_WATER, "move_right"]]:
		var number: int = way[0]
		var without := _places(number, way[1], false)
		var with := _places(number, way[1], true)
		assert_true(
			with[0] > without[0] * 2,
			"level %d: the view takes %d places with, %d without" % [number, with[0], without[0]]
		)
		assert_true(
			with[1] > without[1] * 2,
			"level %d: the sprites take %d places with, %d without" % [number, with[1], without[1]]
		)


## Keen goes by [param action] on map [param number] for [constant FRAMES]
## screen frames; returns how many different places the view and the
## sprites took.
func _places(number: int, action: String, smooth: bool) -> Array[int]:
	_create_view()
	_view._settings.smooth_motion = smooth
	_view._settings.graphics = DisplaySettings.Graphics.ORIGINAL
	_start_game_on(number)
	var views := {}
	var sprites := {}
	Input.action_press(action)
	for _frame in FRAMES:
		_view._process(FRAME_SECONDS)
		views[_view._camera_anchor.position] = true
		var placed := PackedVector2Array()
		for node in _view._objects.get_children():
			if node is Node2D:
				placed.append((node as Node2D).position)
		sprites[placed] = true
	Input.action_release(action)
	return [views.size(), sprites.size()]


func _missing_fore_tile() -> int:
	var shown := _view._galaxy_map.wanted_tiles(GalaxyMap.Layer.FOREGROUND)
	for tile in range(1, _view._data.graphics.ranges.fore_tile_count):
		if not shown.has(tile) and _view._data.graphics.fore_tile(tile) != null:
			return tile
	return -1


func _create_view() -> void:
	_free_view()
	_view = (load("res://src/keen4/keen4_view.tscn") as PackedScene).instantiate() as Keen4View
	_view.files = Keen4Files.locate()
	_tree.root.add_child(_view)
	_view._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_view._keen4_settings.path = TEST_DIRECTORY.path_join("keen4.cfg")


func _free_view() -> void:
	if _view != null:
		_view.get_parent().remove_child(_view)
		_view.free()
		_view = null


## A Normal game on map [param number] (as a loaded game does).
func _start_game_on(number: int) -> void:
	_view._begin_game()
	_view._inventory = Keen4Inventory.new_game()
	_view._game_progress = Keen4Progress.new()
	_view._difficulty = GalaxyDifficulty.Level.NORMAL
	_view._show_level(number)


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
