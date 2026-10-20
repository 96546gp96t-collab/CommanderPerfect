extends "res://tests/test_case.gd"
## Tests Keen 4's control panel on the real screen ([Keen4View], milestone
## D11) with the player's files, against what v1.0 does in js-dos: the Sound
## and Music cards change the shared settings and [Keen4Audio] at once (the
## quiet AdLib sounds in Keen 4's own settings), the cards show what the
## settings say, F1 on a card opens the help and leaving it shows the same
## card, the music stops while the panel is open in a game and the map's
## song starts from its beginning on Return to Game (heard in v1.0), and
## Paddle War runs on the screen's time with its sounds going to the audio.
## The screen must be in a running scene tree (its _ready loads the files),
## so the suite is skipped in the headless runner's _initialize; settings go
## to a folder of their own in the user folder, removed afterwards.

const TEST_DIRECTORY := "user://test_keen4_d11_screen"
const CONFIGURE_ROW := 3
const RETURN_ROW := 4
const PADDLE_ROW := 6
const SOUND_ROW := 0
const MUSIC_ROW := 1
const WORLD_MAP := 0
const FIRST_LEVEL := 1
## Seconds of Paddle War: more than the 70-tic serve.
const SERVE_SECONDS := 1.1
const FRAME_SECONDS := 1.0 / 60.0

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


func test_the_sound_card_switches_at_once() -> void:
	_create_view()
	var settings := _view._user_settings
	settings.sound_device = "adlib"
	_view._keen4_settings.quiet_adlib = false
	_open_card(SOUND_ROW)
	var menus := _view.menus()
	assert_equal(menus.top().kind, GalaxyMenuController.SOUND_CARD, "the Sound card")
	assert_equal(menus.top().cursor, 2, "on ADLIB/SOUNDBLASTER, the setting")
	var expected := [
		["off", GalaxySoundPlayer.Mode.OFF, false],
		["pc", GalaxySoundPlayer.Mode.PC, false],
		["adlib", GalaxySoundPlayer.Mode.ADLIB, false],
		["adlib", GalaxySoundPlayer.Mode.ADLIB, true],
	]
	for row in [1, 3, 0, 2]:
		menus.top().cursor = row
		_key(KEY_ENTER)
		var wanted: Array = expected[row]
		assert_equal(settings.sound_device, wanted[0], "row %d: the shared setting" % row)
		assert_equal(_view._audio.mode, wanted[1], "row %d: the audio at once" % row)
		assert_equal(_view._audio.quiet_adlib, wanted[2], "row %d: quiet AdLib" % row)
		assert_equal(_view._keen4_settings.quiet_adlib, wanted[2], "row %d: Keen 4's setting" % row)
		assert_equal(menus.top().kind, GalaxyMenuController.SOUND_CARD, "row %d: card stays" % row)
		var stored := UserSettings.load_from(settings.path)
		assert_equal(stored.sound_device, wanted[0], "row %d: saved" % row)
		var keen4 := Keen4Settings.load_from(_view._keen4_settings.path)
		assert_equal(keen4.quiet_adlib, wanted[2], "row %d: quiet saved" % row)


func test_the_music_card_switches_at_once() -> void:
	_create_view()
	var settings := _view._user_settings
	settings.music_enabled = true
	_open_card(MUSIC_ROW)
	var menus := _view.menus()
	assert_equal(menus.top().kind, GalaxyMenuController.MUSIC_CARD, "the Music card")
	assert_equal(menus.top().cursor, 1, "on ADLIB/SOUNDBLASTER: music is on")
	menus.top().cursor = 0
	_key(KEY_ENTER)
	assert_true(not settings.music_enabled, "music off in the settings")
	assert_true(not _view._audio.music_on, "and in the audio at once")
	assert_true(not UserSettings.load_from(settings.path).music_enabled, "saved")
	menus.top().cursor = 1
	_key(KEY_ENTER)
	assert_true(settings.music_enabled, "on again")
	assert_true(_view._audio.music_on, "the audio too")


func test_the_cards_show_what_the_settings_say() -> void:
	# Shift+S / Shift+M may have changed them before the panel opened.
	var cases := [
		["off", false, false, GalaxyMenuController.SoundChoice.OFF],
		["pc", false, true, GalaxyMenuController.SoundChoice.PC],
		["adlib", false, true, GalaxyMenuController.SoundChoice.ADLIB],
		["adlib", true, false, GalaxyMenuController.SoundChoice.QUIET_ADLIB],
	]
	for case: Array in cases:
		_create_view()
		_view._user_settings.sound_device = case[0]
		_view._keen4_settings.quiet_adlib = case[1]
		_view._user_settings.music_enabled = case[2]
		_view._open_panel()
		var menus := _view.menus()
		assert_equal(menus.sound_choice, case[3], "sound %s quiet %s" % [case[0], case[1]])
		assert_equal(menus.music_on, case[2], "music %s" % case[2])


func test_f1_on_a_card_opens_the_help_and_escape_comes_back() -> void:
	_create_view()
	_view._open_panel()
	var menus := _view.menus()
	menus.top().cursor = PADDLE_ROW
	_key(KEY_F1)
	assert_equal(_view._front, Keen4FrontScreen.Front.HELP, "F1: the help (seen in v1.0)")
	assert_true(menus.is_open(), "the panel waits behind it")
	_key(KEY_DOWN)
	assert_equal(menus.top().cursor, PADDLE_ROW, "the keys go to the help, not the panel")
	_key(KEY_ENTER)
	assert_equal(_view._front, Keen4FrontScreen.Front.HELP, "a topic's pages")
	_key(KEY_ESCAPE)
	assert_equal(_view._front, Keen4FrontScreen.Front.HELP, "Escape: the help's menu")
	_key(KEY_ESCAPE)
	assert_equal(_view._front, Keen4FrontScreen.Front.NONE, "Escape again: out of the help")
	assert_true(menus.is_open(), "the panel again (seen)")
	assert_equal(menus.top().kind, MenuController.MAIN, "the same card")
	assert_equal(menus.top().cursor, PADDLE_ROW, "the cursor where it was (seen)")
	_key(KEY_DOWN)
	assert_equal(menus.top().cursor, PADDLE_ROW + 1, "the panel takes the keys again")


func test_f1_on_a_deeper_card_comes_back_to_it() -> void:
	_create_view()
	_open_card(SOUND_ROW)
	var menus := _view.menus()
	_key(KEY_F1)
	assert_equal(_view._front, Keen4FrontScreen.Front.HELP, "F1 on the Sound card")
	_key(KEY_ESCAPE)
	assert_equal(menus.top().kind, GalaxyMenuController.SOUND_CARD, "back on the Sound card")


func test_f1_does_nothing_over_a_question_or_paddle_war() -> void:
	_create_view()
	_view._open_panel()
	var menus := _view.menus()
	_key(KEY_ESCAPE)
	assert_equal(menus.top().kind, GalaxyMenuController.CONFIRM, "REALLY QUIT?")
	_key(KEY_F1)
	assert_true(_view._front != Keen4FrontScreen.Front.HELP, "no help over the question")
	_create_view()
	_view._open_panel()
	menus = _view.menus()
	menus.top().cursor = PADDLE_ROW
	_key(KEY_ENTER)
	_key(KEY_F1)
	assert_true(_view._front != Keen4FrontScreen.Front.HELP, "no help over Paddle War")
	assert_true(menus.paddle_war() != null, "still playing")


func test_the_music_stops_in_the_panel_and_starts_again_from_its_beginning() -> void:
	for number in [WORLD_MAP, FIRST_LEVEL]:
		_create_view()
		_start_game_on(number)
		var song := Keen4Sounds.song_for_map(number)
		assert_equal(_view._audio.song(), song, "map %d plays its song" % number)
		_view._open_panel()
		assert_true(_view.menus().is_open(), "the panel (map %d)" % number)
		assert_equal(
			_view._audio.song(), GalaxySoundPlayer.NO_SONG, "map %d: silent in the panel" % number
		)
		_key(KEY_ESCAPE)
		_key(KEY_ESCAPE)
		assert_equal(_view._audio.song(), GalaxySoundPlayer.NO_SONG, "a question does not start it")
		_view.menus().top().cursor = RETURN_ROW
		_key(KEY_ENTER)
		assert_true(not _view.menus().is_open(), "back in the game")
		assert_equal(_view._audio.song(), song, "map %d: its song again (heard)" % number)


func test_the_panel_from_the_story_stops_its_song() -> void:
	# Heard in v1.0: a key during the story opens the panel and the story's
	# song stops at once; Return to Demo goes on with the title loop's next
	# step (a demo, after its box), not the story again.
	_create_view()
	_view._start_story()
	assert_equal(
		_view._audio.song(), Keen4Sounds.song_for_map(Keen4Sounds.STORY_MAP), "the story's song"
	)
	_key(KEY_SPACE)
	assert_true(_view.menus().is_open(), "a key opens the panel")
	assert_equal(_view._audio.song(), GalaxySoundPlayer.NO_SONG, "the song stops (heard)")
	_view.menus().top().cursor = RETURN_ROW
	_key(KEY_ENTER)
	assert_true(not _view.menus().is_open(), "Return to Demo")
	assert_true(_view._front != Keen4FrontScreen.Front.STORY, "the next step, not the story")


func test_switching_music_on_in_the_panel_waits_for_the_game() -> void:
	_create_view()
	_view._user_settings.music_enabled = false
	_view._audio.set_music(false)
	_start_game_on(WORLD_MAP)
	_view._open_panel()
	var menus := _view.menus()
	menus.top().cursor = CONFIGURE_ROW
	_key(KEY_ENTER)
	menus.top().cursor = MUSIC_ROW
	_key(KEY_ENTER)
	menus.top().cursor = 1
	_key(KEY_ENTER)
	assert_true(_view._audio.music_on, "music on")
	assert_equal(_view._audio.song(), GalaxySoundPlayer.NO_SONG, "but not in the panel")
	_key(KEY_ESCAPE)
	_key(KEY_ESCAPE)
	menus.top().cursor = RETURN_ROW
	_key(KEY_ENTER)
	assert_equal(_view._audio.song(), Keen4Sounds.song_for_map(WORLD_MAP), "the map's song")


func test_f1_in_the_panel_in_a_game_keeps_the_music_off() -> void:
	_create_view()
	_start_game_on(WORLD_MAP)
	_view._open_panel()
	_key(KEY_F1)
	_key(KEY_ESCAPE)
	assert_true(_view.menus().is_open(), "the panel again")
	assert_equal(_view._audio.song(), GalaxySoundPlayer.NO_SONG, "still silent")


func test_paddle_war_runs_on_the_screens_time() -> void:
	_create_view()
	_view._open_panel()
	var menus := _view.menus()
	var asked: Array[StringName] = []
	menus.sound_requested.connect(asked.append)
	assert_true(menus.sound_requested.is_connected(_view._audio.play), "its sounds go to the audio")
	menus.top().cursor = PADDLE_ROW
	_key(KEY_ENTER)
	var game := menus.paddle_war()
	assert_true(game != null, "Paddle War")
	var seconds := 0.0
	while seconds < SERVE_SECONDS:
		_view._process(FRAME_SECONDS)
		seconds += FRAME_SECONDS
	assert_true(game.ball_visible, "served after about a second (seen: ~985 ms)")
	for _frame in 600:
		_view._process(FRAME_SECONDS)
		if game.computer_score + game.keen_score > 0:
			break
	assert_true(game.computer_score + game.keen_score > 0, "a point within 10 s")
	assert_true(not asked.is_empty(), "sounds were asked for: %s" % str(asked))
	_key(KEY_ESCAPE)
	assert_equal(menus.top().kind, MenuController.MAIN, "Escape: the main card")
	assert_true(menus.paddle_war() == null, "no game")


func test_paddle_war_does_not_move_the_games_random_numbers() -> void:
	_create_view()
	_start_game_on(FIRST_LEVEL)
	var world := _view._played.world
	var before := world.random_index
	_view._open_panel()
	_view.menus().top().cursor = PADDLE_ROW
	_key(KEY_ENTER)
	for _frame in 300:
		_view._process(FRAME_SECONDS)
	_key(KEY_ESCAPE)
	assert_equal(world.random_index, before, "the level's random table is where it was")


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


## A Normal game, standing on map [param number] (as a loaded game does).
func _start_game_on(number: int) -> void:
	_view._begin_game()
	_view._inventory = Keen4Inventory.new_game()
	_view._game_progress = Keen4Progress.new()
	_view._difficulty = GalaxyDifficulty.Level.NORMAL
	_view._show_level(number)
	assert_true(_view.in_game(), "in a game on map %d" % number)


## Opens the panel's Configure card and the card on row [param row].
func _open_card(row: int) -> void:
	_view._open_panel()
	var menus := _view.menus()
	menus.top().cursor = CONFIGURE_ROW
	_key(KEY_ENTER)
	menus.top().cursor = row
	_key(KEY_ENTER)


func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	_view._unhandled_input(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	_view._unhandled_input(release)


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
