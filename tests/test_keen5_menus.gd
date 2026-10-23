extends "res://tests/test_case.gd"
## Checks Keen 5's control panel ([Keen5View] on [GalaxyMenuScreen],
## milestone E9) with the player's files: a key in the title loop and
## Escape in a game open it; every card shows Keen 5's own title picture
## on Keen 5's wrist watch; New Game on each difficulty (8 charges a
## stunner on Easy); a game saved on the world map and one saved halfway
## through a level come back as they were (the level's frames played
## again); the score box and the sound settings are kept in Keen 5's own
## settings file; Paddle War opens and runs; End Game leads to the high
## scores; F1 on a card shows the help and comes back; a ride on the map
## makes Escape wait; and nothing is ever written in Keen 4's user folder.
## The screen must be in a running scene tree, so the suite runs in the
## first frame; settings and saves go to a folder of their own, removed
## afterwards. Skipped without the files.

const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const TEST_DIRECTORY := "user://test_keen5_menus"
const KEEN4_FOLDER := "user://keen4"
const FRAME_SECONDS := 1.0 / 35.0
const QUEUE_FRAMES := 400
const REPLAY_FRAMES := 200
const WALK_FRAMES := 40
const LEVEL_FRAMES := 180
const MORE_FRAMES := 60
const PADDLE_SECONDS := 1.5
## The main card's rows (the original's order).
const SAVE_ROW := 2
const CONFIGURE_ROW := 3
const END_ROW := 5
const PADDLE_ROW := 6
## Configure's rows.
const SOUND_ROW := 0
const OPTIONS_ROW := 2
const KEYS_ROW := 3
const LOAD_ROW := 1
const SLOT := 3
const SAVE_NAME := "KORATH"
## Where the title picture of a card and of Paddle War lie (Omni).
const TITLE_AT := GalaxyMenuView.TITLE_AT
const PADDLE_TITLE_AT := Vector2i(128, 48)
## The rows of a title picture above the first choice (y 60).
const TITLE_ROWS := 12

var _view: Keen5View
var _tree: SceneTree
## The files in Keen 4's user folder before the suite ran.
var _keen4_before: Dictionary


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
	_keen4_before = _listing(KEEN4_FOLDER)
	super.run_all()
	_free_view()
	_check_keen4_untouched()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_a_key_in_the_title_loop_opens_the_main_card() -> void:
	_create_view()
	_key(KEY_SPACE)
	var menus := _view.menus()
	assert_true(menus.is_open(), "the panel")
	assert_equal(menus.top().kind, MenuController.MAIN, "the main card")
	assert_equal(menus.top().items[4].label, GalaxyMenuPages.RETURN_TO_DEMO, "out of a game")
	assert_equal(menus.top().cursor, 0, "on New Game")
	assert_true(not menus.top().items[SAVE_ROW].enabled, "no saving out of a game")
	assert_equal(_view.audio().song(), GalaxySoundPlayer.NO_SONG, "the music stops")
	_check_title(MenuController.MAIN)
	_key(KEY_ESCAPE)
	assert_equal(menus.top().kind, GalaxyMenuController.CONFIRM, "Escape: REALLY QUIT?")
	assert_equal(menus.top().header, GalaxyMenuController.QUIT_LINES, "with Choose Game")
	_key(KEY_N)
	assert_equal(menus.top().kind, MenuController.MAIN, "any other key backs out")
	menus.top().cursor = 4
	_key(KEY_ENTER)
	assert_true(not menus.is_open() and _view.in_title_loop(), "Return to Demo")


func test_every_card_shows_keen5s_picture() -> void:
	_create_view()
	_start_game_on(Keen5Episode.WORLD_MAP)
	_key(KEY_ESCAPE)
	var menus := _view.menus()
	assert_true(menus.is_open() and menus.in_game, "Escape in a game: the panel")
	assert_equal(menus.top().cursor, GalaxyMenuPages.RETURN_ROW, "on Return to Game")
	var picture := _panel_picture()
	var watch := _picture(_view._data.graphics.ranges.picture_count - Keen5Episode.WATCH_FROM_END)
	assert_equal(picture.get_pixel(0, 0), watch.get_pixel(0, 0), "Keen 5's wrist watch")
	for row in [0, 1, SAVE_ROW]:
		menus.top().cursor = row
		_key(KEY_ENTER)
		_check_title(menus.top().kind)
		_key(KEY_ESCAPE)
	menus.top().cursor = CONFIGURE_ROW
	_key(KEY_ENTER)
	_check_title(GalaxyMenuController.CONFIGURE)
	for row in [SOUND_ROW, 1, OPTIONS_ROW, KEYS_ROW]:
		menus.top().cursor = row
		_key(KEY_ENTER)
		_check_title(menus.top().kind)
		_key(KEY_ESCAPE)
	_key(KEY_ESCAPE)
	menus.top().cursor = PADDLE_ROW
	_key(KEY_ENTER)
	var title := _picture(
		_view._data.graphics.ranges.picture_count - Keen5Episode.PADDLE_WAR_FROM_END
	)
	assert_true(
		_shows(_panel_picture(), title, PADDLE_TITLE_AT), "Paddle War's title, on whole bytes"
	)


func test_new_game_on_each_difficulty() -> void:
	var charges := [8, 5, 5]
	for level in [
		GalaxyDifficulty.Level.EASY, GalaxyDifficulty.Level.NORMAL, GalaxyDifficulty.Level.HARD
	]:
		_create_view()
		_key(KEY_SPACE)
		_key(KEY_ENTER)
		var menus := _view.menus()
		assert_equal(menus.top().kind, GalaxyMenuController.NEW_GAME, "New Game")
		assert_equal(menus.top().cursor, GalaxyDifficulty.Level.NORMAL, "on Normal")
		menus.top().cursor = level
		_key(KEY_ENTER)
		_run_queue()
		assert_true(_view.map_session() != null, "difficulty %d: on the world map" % level)
		assert_equal(_view._difficulty, level, "difficulty %d kept" % level)
		_view._show_level(1)
		var session := _view.session()
		assert_equal(session.difficulty, level, "difficulty %d: the level's" % level)
		assert_equal(
			session.inventory.charges_per_stunner, charges[level], "difficulty %d: charges" % level
		)


func test_a_game_saved_on_the_map_comes_back() -> void:
	_create_view()
	_start_game_on(Keen5Episode.WORLD_MAP)
	_view.progress().mark_done(4, Keen5Progress.DONE_BY_FUSE)
	_view.inventory().score = 4200
	_hold("move_left", WALK_FRAMES)
	var place := _view.map_session().keen.position
	_save_in_slot()
	assert_true(_view.saves().exists(SLOT), "saved")
	assert_equal(_view.saves().name_of(SLOT), SAVE_NAME, "under its name")
	_return_to_game()
	_hold("move_right", WALK_FRAMES)
	assert_true(_view.map_session().keen.position != place, "he walked on")
	_view.inventory().score = 0
	_load_slot()
	assert_true(_view.map_session() != null, "on the world map")
	assert_equal(_view.map_session().keen.position, place, "where he stood")
	assert_equal(_view.inventory().score, 4200, "the score")
	assert_equal(_view.progress().done_value(4), Keen5Progress.DONE_BY_FUSE, "the fuse's 14")
	assert_true(_view.queue().current() != null, "PAUSED")
	_key(KEY_SPACE)
	assert_true(not _view.shows_message(), "a key goes on")


func test_a_level_saved_halfway_comes_back_as_it_was() -> void:
	_create_view()
	# God mode keeps him alive, and goes into the frames.
	_view._god_mode = true
	_start_game_on(1)
	_hold("move_right", LEVEL_FRAMES, "jump")
	var before := _state()
	_save_in_slot()
	_return_to_game()
	_hold("move_left", MORE_FRAMES, "fire")
	assert_true(_state() != before, "the level went on")
	_key(KEY_ESCAPE)
	_view.menus().top().cursor = LOAD_ROW
	_key(KEY_ENTER)
	_view.menus().top().cursor = SLOT - 1
	_key(KEY_ENTER)
	assert_equal(_view.menus().top().kind, GalaxyMenuController.CONFIRM, "YOU'RE IN A GAME")
	_key(KEY_Y)
	_finish_loading()
	assert_equal(_state(), before, "Keen, every object, the tiles, the view, the random table")
	assert_true(_view._recording.frames.size() > 0, "its frames are kept for a new save")
	assert_true(_view.session().player.god_mode, "god mode from the frames")


func test_the_settings_are_kept_in_keen5s_own_file() -> void:
	_create_view()
	_start_game_on(Keen5Episode.WORLD_MAP)
	_key(KEY_ESCAPE)
	var menus := _view.menus()
	menus.top().cursor = CONFIGURE_ROW
	_key(KEY_ENTER)
	menus.top().cursor = OPTIONS_ROW
	_key(KEY_ENTER)
	assert_equal(menus.top().kind, MenuController.OPTIONS, "Options")
	assert_equal(menus.top().items[0].label, "SCORE BOX (ON)", "on by default")
	_key(KEY_ENTER)
	_key(KEY_SPACE)
	var path := _view._galaxy_settings.path
	assert_true(not GalaxySettings.load_from(path).score_box, "the score box off, kept")
	_key(KEY_ESCAPE)
	menus.top().cursor = SOUND_ROW
	_key(KEY_ENTER)
	menus.top().cursor = GalaxyMenuController.SoundChoice.QUIET_ADLIB
	_key(KEY_ENTER)
	assert_true(GalaxySettings.load_from(path).quiet_adlib, "quiet AdLib, kept")
	assert_equal(UserSettings.load_from(_view._user_settings.path).sound_device, "adlib", "shared")
	assert_true(_view.audio().quiet_adlib, "at once")
	_return_to_game()
	assert_true(not _view.menus().is_open(), "Return to Game")
	assert_true(not _view._score_box.visible, "no score box")
	var fresh := GalaxySettings.load_from(path)
	assert_true(path.begins_with(TEST_DIRECTORY), "the test's own file")
	assert_true(not fresh.score_box and fresh.quiet_adlib, "both read back")


func test_paddle_war_opens_and_runs() -> void:
	_create_view()
	_view._open_panel()
	var menus := _view.menus()
	menus.top().cursor = PADDLE_ROW
	_key(KEY_ENTER)
	var game := menus.paddle_war()
	assert_true(game != null, "Paddle War")
	var seconds := 0.0
	while seconds < PADDLE_SECONDS:
		_view._process(FRAME_SECONDS)
		seconds += FRAME_SECONDS
	assert_true(game.ball_visible, "served")
	_key(KEY_ESCAPE)
	assert_equal(menus.top().kind, MenuController.MAIN, "Escape: the main card")


func test_end_game_shows_the_high_scores() -> void:
	_create_view()
	_start_game_on(Keen5Episode.WORLD_MAP)
	_key(KEY_ESCAPE)
	_view.menus().top().cursor = END_ROW
	_key(KEY_ENTER)
	assert_equal(_view.menus().top().header, GalaxyMenuController.END_LINES, "REALLY END?")
	_key(KEY_Y)
	assert_true(_view.in_title_loop(), "the title loop")
	_run_queue()
	assert_equal(_view.map_number(), Keen5Episode.HIGH_SCORE_MAP, "the high scores")
	assert_true(_view._board_sprite.visible, "with the table")


func test_f1_on_a_card_shows_the_help_and_comes_back() -> void:
	_create_view()
	_view._open_panel()
	var menus := _view.menus()
	menus.top().cursor = CONFIGURE_ROW
	_key(KEY_ENTER)
	_key(KEY_F1)
	assert_equal(_view.front(), GalaxyFrontScreen.Front.HELP, "the help")
	_key(KEY_ESCAPE)
	assert_equal(_view.front(), GalaxyFrontScreen.Front.NONE, "left")
	assert_equal(menus.top().kind, GalaxyMenuController.CONFIGURE, "the same card")
	_check_title(GalaxyMenuController.CONFIGURE)


func test_escape_waits_while_a_ride_holds_the_map() -> void:
	_create_view()
	_start_game_on(Keen5Episode.WORLD_MAP)
	var on_map := _view.map_session() as Keen5MapSession
	on_map.ride = Keen5MapRide.new()
	_key(KEY_ESCAPE)
	assert_true(not _view.menus().is_open(), "not during a ride")
	on_map.ride = null
	_key(KEY_ESCAPE)
	assert_true(_view.menus().is_open(), "after it")


func test_the_saves_are_keen5s_own() -> void:
	var scene := load(VIEW_SCENE) as PackedScene
	var view := scene.instantiate() as Keen5View
	_tree.root.add_child(view)
	assert_equal(view.saves().directory, "user://keen5/saves", "Keen 5's folder")
	assert_equal(view.saves().count, 6, "six slots, as the original")
	assert_equal(view._galaxy_settings.path, "user://keen5/settings.cfg", "Keen 5's settings")
	assert_true(view._new_saved_game() is Keen5SavedGame, "Keen 5's saved game")
	view.get_parent().remove_child(view)
	view.free()


## The state of the level played, as one value to compare.
func _state() -> Array:
	var session := _view.session()
	var objects := []
	for object in session.world.objects:
		(
			objects
			. append(
				[
					object.get_script().get_global_name(),
					object.position,
					object.velocity,
					object.action.name if object.action != null else &"",
					object.removed,
				]
			)
		)
	return [
		session.player.position,
		session.player.velocity,
		session.player.action.name,
		session.world.random_index,
		session.camera.scroll,
		objects,
		session.map.planes[GalaxyMap.Layer.FOREGROUND].duplicate(),
		session.map.planes[GalaxyMap.Layer.INFO].duplicate(),
		_view.inventory().score,
		_view.inventory().shots,
	]


## A Normal game, standing on map [param number] (as a loaded game does).
func _start_game_on(number: int) -> void:
	_view._begin_game()
	_view._inventory = _view._new_inventory()
	_view._game_progress = _view._new_progress()
	_view._difficulty = GalaxyDifficulty.Level.NORMAL
	_view._show_level(number)
	assert_true(_view.in_game(), "in a game on map %d" % number)


## Escape, Save Game, slot [constant SLOT], its name, Enter.
func _save_in_slot() -> void:
	_key(KEY_ESCAPE)
	var menus := _view.menus()
	menus.top().cursor = SAVE_ROW
	_key(KEY_ENTER)
	menus.top().cursor = SLOT - 1
	_key(KEY_ENTER)
	assert_equal(menus.top().kind, GalaxyMenuController.SLOT_NAME, "the name is typed")
	for index in SAVE_NAME.length():
		_send(OS.find_keycode_from_string(SAVE_NAME[index]), SAVE_NAME.unicode_at(index))
	_key(KEY_ENTER)
	assert_equal(menus.top().kind, MenuController.SLOTS_SAVE, "the save card stays")


## Back to the main card and Return to Game.
func _return_to_game() -> void:
	var menus := _view.menus()
	while menus.is_open() and menus.depth() > 1:
		_key(KEY_ESCAPE)
	menus.top().cursor = GalaxyMenuPages.RETURN_ROW
	_key(KEY_ENTER)


## Escape, Load Game, slot [constant SLOT] (yes when asked), and the game.
func _load_slot() -> void:
	_key(KEY_ESCAPE)
	var menus := _view.menus()
	menus.top().cursor = LOAD_ROW
	_key(KEY_ENTER)
	menus.top().cursor = SLOT - 1
	_key(KEY_ENTER)
	if menus.is_open() and menus.top().kind == GalaxyMenuController.CONFIRM:
		_key(KEY_Y)
	_finish_loading()


## Frames until the loaded game stands behind its PAUSED box.
func _finish_loading() -> void:
	for frame in REPLAY_FRAMES:
		_frames(1)
		if _view._replay == null and _view.queue().current() != null:
			if _view.queue().current().image != null:
				return


## Holds [param action] (and [param also]) for [param frames] frames.
func _hold(action: String, frames: int, also := "") -> void:
	Input.action_press(action)
	for frame in frames:
		if not also.is_empty():
			if frame % 20 < 6:
				Input.action_press(also)
			else:
				Input.action_release(also)
		_frames(1)
	Input.action_release(action)
	if not also.is_empty():
		Input.action_release(also)


## The title picture of card [param kind] is on the panel (its rows above
## the choices: a card whose choices start at y 60 draws them over the
## picture's last rows, as the original).
func _check_title(kind: StringName) -> void:
	var count := _view._data.graphics.ranges.picture_count
	var title := _picture(count - Keen5Episode.MENU_CARDS_FROM_END[kind])
	title = title.get_region(Rect2i(0, 0, title.get_width(), TITLE_ROWS))
	assert_true(_shows(_panel_picture(), title, TITLE_AT), "card %s: Keen 5's picture" % kind)


func _panel_picture() -> Image:
	return _view._panel_view.draw(_view.menus())


func _picture(index: int) -> Image:
	var picture := _view._data.graphics.picture(index).duplicate() as Image
	picture.convert(Image.FORMAT_RGBA8)
	return picture


## Whether [param picture] shows [param part] at [param at].
static func _shows(picture: Image, part: Image, at: Vector2i) -> bool:
	var region := picture.get_region(Rect2i(at, part.get_size()))
	return region.get_data() == part.get_data()


func _create_view() -> void:
	_free_view()
	for action in KeyBindings.all_actions():
		Input.action_release(action)
	var scene := load(VIEW_SCENE) as PackedScene
	_view = scene.instantiate() as Keen5View
	_tree.root.add_child(_view)
	_view._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	var episode_settings := TEST_DIRECTORY.path_join("keen5.cfg")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(episode_settings))
	_view._galaxy_settings = GalaxySettings.load_from(episode_settings)
	_view._saves.directory = TEST_DIRECTORY.path_join("saves")
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


func _run_queue() -> void:
	for frame in QUEUE_FRAMES:
		if not _view.shows_message():
			return
		_frames(1)


func _key(key: Key) -> void:
	_send(key, 0)


func _send(key: Key, unicode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.unicode = unicode
	event.pressed = true
	_view._unhandled_input(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	_view._unhandled_input(release)


## Keen 4's folder as it was before the suite: nothing in it changed.
func _check_keen4_untouched() -> void:
	assert_equal(_listing(KEEN4_FOLDER), _keen4_before, "nothing written in Keen 4's folder")


## Every file under [param folder] with its size and time.
static func _listing(folder: String) -> Dictionary:
	var found := {}
	var directory := DirAccess.open(folder)
	if directory == null:
		return found
	for file_name in directory.get_files():
		var path := folder.path_join(file_name)
		found[path] = [FileAccess.get_size(path), FileAccess.get_modified_time(path)]
	for sub in directory.get_directories():
		found.merge(_listing(folder.path_join(sub)))
	return found


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
