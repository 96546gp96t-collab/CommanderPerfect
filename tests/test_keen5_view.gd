extends "res://tests/test_case.gd"
## Checks Keen 5's game screen ([Keen5View], milestone E3) with the player's
## files: it starts in level 1 with Keen 5's Keen and score box; a level
## done (the exit, the door to Korath III) goes to the next one, after a
## broken fuse first the fuse message (E5), a death starts it again with a
## life less; Shift+N / Shift+P step over the
## missing map 14, the world map is looked at; Shift+G and Shift+I as in
## Keen 1-4. The screen must be in a running scene tree (its _ready loads
## the files), so the suite runs in the first frame; settings go to a
## folder of their own in the user folder, removed afterwards. Skipped
## without the files.

const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const TEST_DIRECTORY := "user://test_keen5_view"
const FRAME_SECONDS := 1.0 / 35.0
const DEATH_FRAMES := 300
## The upper fuse of level 4 (files): its upper tile, where Keen's feet
## are when he breaks it.
const FUSE_4 := Vector2i(58, 7)
## Enough frames for the fuse message's 30 tics.
const KEY_WAIT_FRAMES := 20

var _view: Keen5View
var _tree: SceneTree


func _init() -> void:
	if Keen5Files.locate() == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null or not _tree.root.is_inside_tree():
		skip("needs a running scene tree (the screen loads its files when it is ready)")


func run_all() -> void:
	if not skip_reason.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	KeyBindings.reset()
	super.run_all()
	_free_view()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_it_starts_in_level_1_with_keen_5s_keen() -> void:
	_create_view()
	assert_equal(_view.map_number(), 1, "level 1")
	assert_true(_view.session() is Keen5LevelSession, "Keen 5's level")
	assert_true(_view.session().keen is Keen5Keen, "Keen 5's Keen")
	assert_true(_view.inventory() is Keen5Inventory, "Keen 5's inventory")
	assert_equal(_view.session().keen.direction.x, -1, "facing left (info 2)")
	assert_true(_view._score_box.visible, "the score box")
	assert_equal(_view._score_box._shown, PackedInt32Array([0, 3, 5]), "score, lives, charges")
	assert_true(_view.galaxy_camera().column_blocks.size() == 2, "no column blocks")


func test_a_level_done_goes_to_the_next() -> void:
	_create_view()
	_view.session().world.complete(&"")
	_frames(2)
	assert_equal(_view.map_number(), 2, "level 2")
	assert_true(_view.session() != null and _view.session().is_playing(), "played")
	_view._show_level(13)
	_view.session().world.complete(Keen5Keen.KORATH_ENDING)
	_frames(2)
	assert_equal(_view.map_number(), 1, "13 is followed by 1; Korath III's door ends too")


func test_a_broken_fuse_shows_its_message_then_the_next_level() -> void:
	_create_view()
	_view._show_level(4)
	_view.session().world.complete(Keen5LevelEnd.FUSE_ENDING)
	_frames(2)
	assert_true(_view.shows_message(), "the fuse message")
	assert_equal(
		_view.levels_done.get(4), Keen5LevelSession.DONE_BY_FUSE, "level 4 done by its fuse"
	)
	assert_equal(_view.queue().steps.size(), 4, "two screens, each 30 tics and then a key")
	_press_key()
	assert_equal(_view.queue().steps.size(), 4, "a key within the 30 tics does nothing")
	_frames(KEY_WAIT_FRAMES)
	assert_equal(_view.queue().steps.size(), 3, "after 30 tics it waits for a key")
	_press_key()
	_frames(KEY_WAIT_FRAMES)
	_press_key()
	assert_true(not _view.shows_message(), "the boxes are gone")
	assert_equal(_view.map_number(), 5, "the next level")
	_view.session().world.complete(&"")
	_frames(2)
	assert_equal(_view.levels_done.get(5), Keen5LevelSession.DONE, "an exit counts 1")
	assert_true(not _view.shows_message(), "no message")


func test_a_broken_fuse_shows_its_rubble_also_in_xbrz() -> void:
	_create_view()
	_view._settings.graphics = DisplaySettings.Graphics.XBRZ
	_view._show_level(4)
	_view._scaled.finish()
	_view._apply_graphics()
	assert_true(_view._showing_scaled, "level 4 in xBRZ")
	var session := _view.session() as Keen5LevelSession
	var world := session.world
	var rubble := world.fore_tile(0, 0)
	var carried := _view.inventory() as Keen5Inventory
	Keen5Fuses.break_fuse(world, FUSE_4, carried, _view.rules.sprites)
	assert_equal(_view._galaxy_map.fore_tile_at(FUSE_4), rubble, "the rubble is drawn")
	assert_true(_view._showing_scaled, "still xBRZ")
	assert_true(not _view._stand_ins, "the rubble's tile was scaled with the map")
	assert_true(_view._scaled.fore_tile(rubble) != null, "its xBRZ picture")
	assert_equal(session.fuses_remaining(), 1, "one fuse of two left")


func test_a_death_starts_the_level_again_with_a_life_less() -> void:
	_create_view()
	var first := _view.session()
	_view.inventory().gems = PackedInt32Array([1, 0, 0, 0])
	(_view.inventory() as Keen5Inventory).keycard = true
	first.keen.kill()
	for frame in DEATH_FRAMES:
		_frames(1)
		if _view.session() != first:
			break
	assert_true(_view.session() != first and _view.session() != null, "the level again")
	assert_equal(_view.map_number(), 1, "the same level")
	assert_equal(_view.inventory().lives, 2, "a life less")
	assert_true(not (_view.inventory() as Keen5Inventory).keycard, "the keycard is gone")
	assert_equal(_view.inventory().gems, PackedInt32Array([0, 0, 0, 0]), "the gems too")


func test_shift_n_and_p_step_over_the_missing_map() -> void:
	_create_view()
	_view._show_level(13)
	_shift_key(KEY_N)
	assert_equal(_view.map_number(), 15, "over 14 to the high-score map")
	assert_true(_view.session() != null, "Keen plays in map 15")
	_shift_key(KEY_N)
	assert_equal(_view.map_number(), 0, "round to the world map")
	assert_equal(_view._mode, GameScreen.Mode.LOOK, "the world map is looked at (E6)")
	assert_true(_view.start().is_world_map(), "Keen on the map")
	_shift_key(KEY_P)
	assert_equal(_view.map_number(), 15, "back")
	_view._show_level(14)
	assert_equal(_view._message, Keen5View.NOT_A_MAP_MESSAGE % 14, "no map 14")


func test_the_testing_cheats() -> void:
	_create_view()
	_shift_key(KEY_G)
	assert_true(_view.session().player.god_mode, "god mode on")
	assert_equal(_view._message, Keen5View.GOD_MODE_MESSAGE % "on", "its message")
	_shift_key(KEY_G)
	assert_true(not _view.session().player.god_mode, "god mode off")
	_shift_key(KEY_I)
	var carried := _view.inventory() as Keen5Inventory
	assert_true(carried.keycard, "the keycard")
	assert_equal(carried.gems, PackedInt32Array([1, 1, 1, 1]), "all four gems")
	assert_equal(carried.shots, Keen5View.CHEAT_SHOTS, "99 charges")
	assert_equal(_view._message, Keen5View.EVERYTHING_MESSAGE, "its message")


func _create_view() -> void:
	_free_view()
	_release_all()
	var scene := load(VIEW_SCENE) as PackedScene
	_view = scene.instantiate() as Keen5View
	_tree.root.add_child(_view)
	_view._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_view._settings.aspect = DisplaySettings.Aspect.ORIGINAL
	_view._apply_display_settings()


func _free_view() -> void:
	if _view != null:
		_view.get_parent().remove_child(_view)
		_view.free()
		_view = null


func _frames(count: int) -> void:
	for frame in count:
		_view._process(FRAME_SECONDS)


func _press_key() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.keycode = KEY_SPACE
	event.pressed = true
	_view._unhandled_input(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	_view._unhandled_input(release)


func _shift_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.shift_pressed = true
	event.pressed = true
	_view._unhandled_input(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	_view._unhandled_input(release)


func _release_all() -> void:
	for action in KeyBindings.all_actions():
		Input.action_release(action)


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file in directory.get_files():
		directory.remove(file)
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
