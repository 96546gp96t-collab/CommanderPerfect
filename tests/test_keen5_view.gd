extends "res://tests/test_case.gd"
## Checks Keen 5's game screen ([Keen5View], milestones E3-E6) with the
## player's files: a new game (since E7 after the title loop) starts on the
## world map behind its box; a level entered from the map is played and
## leads back to the map at the place he entered, marked done (every level,
## 1-13); a broken fuse shows its message first and counts 14; the door to
## Korath III puts him there behind its own box; a death shows Try Again
## and Exit to Armageddon and takes the keycard and gems; the status window
## shows the keycard; Shift+N / Shift+P step over the missing map 14;
## Shift+G and Shift+I as in Keen 1-4. The screen must be in a running
## scene tree (its _ready loads the files), so the suite runs in the first
## frame; settings go to a folder of their own in the user folder, removed
## afterwards. Skipped without the files.

const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const TEST_DIRECTORY := "user://test_keen5_view"
const FRAME_SECONDS := 1.0 / 35.0
const DEATH_FRAMES := 300
const QUEUE_FRAMES := 400
## The upper fuse of level 4 (files): its upper tile, where Keen's feet
## are when he breaks it.
const FUSE_4 := Vector2i(58, 7)
## Enough frames for the fuse message's 30 tics.
const KEY_WAIT_FRAMES := 20
## Where Keen starts on the map and where Korath III's arrival is (files).
const MAP_START := Vector2i(28, 95)
const KORATH := Vector2i(37, 107)
const TILE := 256
const LEVELS := 13
const STATUS_FRAMES := 40

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


func test_a_new_game_starts_on_the_world_map() -> void:
	_create_view()
	assert_true(_view.shows_message(), "the map's box first")
	var box := _view._boxes.entering(Keen5Episode.WORLD_MAP)
	assert_equal(_view.queue().current().image.get_data(), box[0].get_data(), "Keen enters ...")
	_run_queue()
	assert_equal(_view.map_number(), Keen5Episode.WORLD_MAP, "the world map")
	assert_true(_view.map_session() is Keen5MapSession, "played")
	assert_equal(_view.map_session().keen.position, MAP_START * TILE, "on info 3")
	assert_true(_view.inventory() is Keen5Inventory, "Keen 5's inventory")
	assert_true(_view.progress() is Keen5Progress, "Keen 5's progress")
	assert_true(_view._score_box.visible, "the score box")


func test_every_level_is_entered_from_the_map_and_left_back_to_it() -> void:
	_create_view()
	_run_queue()
	for level in range(1, LEVELS + 1):
		var entrance := _entrance(level)
		_view.progress().map_position = entrance * TILE
		_view._show_level(Keen5Episode.WORLD_MAP)
		_press_jump()
		assert_true(_view.shows_message(), "level %d: One moment" % level)
		_run_queue()
		assert_equal(_view.map_number(), level, "level %d is played" % level)
		assert_true(_view.session() is Keen5LevelSession, "level %d: Keen 5's level" % level)
		_view.session().world.complete(&"")
		_frames(3)
		_run_queue()
		assert_equal(
			_view.map_number(), Keen5Episode.WORLD_MAP, "level %d: back on the map" % level
		)
		assert_equal(
			_view.map_session().keen.position, entrance * TILE, "level %d: where he entered" % level
		)
		assert_equal(_view.progress().done_value(level), 1, "level %d counts 1" % level)
	assert_equal(_view.map_session().flags.size(), LEVELS, "a flag for every level")


func test_a_broken_fuse_shows_its_message_then_the_map() -> void:
	_create_view()
	_run_queue()
	_view._show_level(4)
	_view.session().world.complete(Keen5LevelEnd.FUSE_ENDING)
	_frames(2)
	assert_true(_view.shows_message(), "the fuse message")
	assert_equal(
		_view.progress().done_value(4), Keen5Progress.DONE_BY_FUSE, "level 4 done by its fuse"
	)
	assert_equal(_view.queue().steps.size(), 4, "two screens, each 30 tics and then a key")
	_press_key()
	assert_equal(_view.queue().steps.size(), 4, "a key within the 30 tics does nothing")
	_frames(KEY_WAIT_FRAMES)
	assert_equal(_view.queue().steps.size(), 3, "after 30 tics it waits for a key")
	_press_key()
	_frames(KEY_WAIT_FRAMES)
	_press_key()
	assert_true(_view.shows_message(), "the map's box")
	_run_queue()
	assert_equal(_view.map_number(), Keen5Episode.WORLD_MAP, "back on the map")


func test_a_broken_fuse_shows_its_rubble_also_in_xbrz() -> void:
	_create_view()
	_run_queue()
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


func test_the_door_to_korath_iii_puts_him_there() -> void:
	_create_view()
	_run_queue()
	_view._show_level(11)
	_view.session().world.complete(Keen5Keen.KORATH_ENDING)
	_frames(2)
	assert_equal(_view.progress().done_value(11), 1, "level 11 is done")
	var korath := _view._boxes.loading(_view._boxes.game_text(Keen5Episode.KORATH_TEXT))
	assert_equal(
		_view.queue().current().image.get_data(),
		korath[0].get_data(),
		"Keen steps out onto Korath III"
	)
	assert_true(_view._boxes.game_text(Keen5Episode.KORATH_TEXT).contains("Korath"), "its text")
	_run_queue()
	assert_equal(_view.map_session().keen.position, KORATH * TILE, "on info 26")
	assert_true(not (_view.progress() as Keen5Progress).korath_arrival, "only once")


func test_a_death_offers_try_again_and_exit_to_armageddon() -> void:
	_create_view()
	_run_queue()
	_view._show_level(1)
	var first := _view.session()
	_view.inventory().gems = PackedInt32Array([1, 0, 0, 0])
	(_view.inventory() as Keen5Inventory).keycard = true
	first.keen.kill()
	for frame in DEATH_FRAMES:
		_frames(1)
		if _view._choice >= 0:
			break
	assert_equal(_view._choice, GalaxyFlowScreen.TRY_AGAIN, "the box after a death")
	assert_equal(_view.inventory().lives, 2, "a life less")
	assert_true(not (_view.inventory() as Keen5Inventory).keycard, "the keycard is gone")
	assert_equal(_view.inventory().gems, PackedInt32Array([0, 0, 0, 0]), "the gems too")
	assert_equal(_view._boxes.game_text(Keen5Episode.EXIT_TEXT), "Exit to Armageddon", "its exit")
	_press_key(KEY_ENTER)
	_run_queue()
	assert_true(_view.session() != first and _view.session() != null, "Try Again: the level")
	assert_equal(_view.map_number(), 1, "the same level")
	_view.session().keen.kill()
	for frame in DEATH_FRAMES:
		_frames(1)
		if _view._choice >= 0:
			break
	_press_key(KEY_ESCAPE)
	_run_queue()
	assert_equal(_view.map_number(), Keen5Episode.WORLD_MAP, "Escape: the map")


func test_the_status_window_shows_the_keycard() -> void:
	_create_view()
	_run_queue()
	(_view.inventory() as Keen5Inventory).keycard = true
	var status := InputEventAction.new()
	status.action = &"status"
	status.pressed = true
	_view._unhandled_input(status)
	assert_true(_view.shows_status(), "Enter drops it")
	assert_true(_view._status is Keen5StatusWindow, "Keen 5's window")
	var start := _view.map_session().keen.position
	_frames(STATUS_FRAMES)
	assert_equal(_view.map_session().keen.position, start, "the game waits")
	_press_key()
	_frames(STATUS_FRAMES)
	assert_true(not _view.shows_status(), "a key lifts it")


func test_shift_n_and_p_step_over_the_missing_map() -> void:
	_create_view()
	_run_queue()
	_view._show_level(13)
	_shift_key(KEY_N)
	assert_equal(_view.map_number(), 15, "over 14 to the high-score map")
	assert_true(_view.session() != null, "Keen plays in map 15")
	_shift_key(KEY_N)
	assert_equal(_view.map_number(), 0, "round to the world map")
	assert_true(_view.map_session() != null, "the world map is played")
	_shift_key(KEY_P)
	assert_equal(_view.map_number(), 15, "back")
	_view._show_level(14)
	assert_equal(_view._message, "Keen 5 has no map 14", "no map 14")


func test_the_testing_cheats() -> void:
	_create_view()
	_run_queue()
	_view._show_level(1)
	_shift_key(KEY_G)
	assert_true(_view.session().player.god_mode, "god mode on")
	assert_equal(_view._message, Keen5View.GOD_MODE_MESSAGE % "on", "its message")
	_shift_key(KEY_G)
	assert_true(not _view.session().player.god_mode, "god mode off")
	_view._show_level(0)
	_shift_key(KEY_I)
	var carried := _view.inventory() as Keen5Inventory
	assert_true(carried.keycard, "the keycard, also on the map")
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
	# The title loop runs first (E7); a key starts a new game.
	_view._new_game()


func _free_view() -> void:
	if _view != null:
		_view.get_parent().remove_child(_view)
		_view.free()
		_view = null


## The first cell of level [param level]'s entrance on the world map.
func _entrance(level: int) -> Vector2i:
	var map := _view._data.maps.load_map(Keen5Episode.WORLD_MAP)
	for y in map.height:
		for x in map.width:
			if map.tile(GalaxyMap.Layer.INFO, x, y) == GalaxyMapKeen.ENTRY_BASE + level:
				return Vector2i(x, y)
	return Vector2i.ZERO


## Runs frames until the boxes and fades are done.
func _run_queue() -> void:
	for frame in QUEUE_FRAMES:
		if not _view.shows_message():
			return
		_frames(1)


func _frames(count: int) -> void:
	for frame in count:
		_view._process(FRAME_SECONDS)


func _press_jump() -> void:
	Input.action_press("jump")
	for frame in 4:
		_frames(1)
		if _view.shows_message():
			break
	Input.action_release("jump")


func _press_key(key := KEY_SPACE) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
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
