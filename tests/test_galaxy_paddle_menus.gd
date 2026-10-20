extends "res://tests/test_case.gd"
## Tests what milestone D11 adds to the Galaxy control panel
## ([GalaxyMenuController]) without game files, against what Keen 4 v1.0
## does in js-dos: PADDLE WAR on the main card's 7th row (Choose Game moved
## into the quit question), Paddle War played from the panel (its sounds,
## Escape and the end at 21 back to the main card with the cursor on PADDLE
## WAR), the Sound and Music cards (a choice of one, checked at once, the
## card stays, the cursor starts on the checked one), and the score box's
## message over the card that still shows the old state. Settings go to a
## folder of their own in the user folder, which is removed afterwards.

const TEST_DIRECTORY := "user://test_galaxy_paddle_menus"
## The main card as v1.0 shows it out of a game (seen: 0 pixels differ).
const MAIN_OUT_OF_GAME: PackedStringArray = [
	"NEW GAME",
	"LOAD GAME",
	"SAVE GAME",
	"CONFIGURE",
	"RETURN TO DEMO",
	"END GAME",
	"PADDLE WAR",
	"QUIT",
]
const CONFIGURE_ROW := 3
const PADDLE_ROW := 6
const QUIT_ROW := 7
## The quit question's lines in v1.0 (seen); ours adds one for Choose Game.
const QUIT_FIRST := "REALLY QUIT?"
const QUIT_YES := "PRESS Y TO QUIT"
const BACK_OUT := "ESC TO BACK OUT"
## The Sound and Music cards in v1.0 (seen).
const SOUND_LABELS: PackedStringArray = [
	"NO SOUND EFFECTS", "PC SPEAKER", "ADLIB/SOUNDBLASTER", "QUIET ADLIB/SOUNDBLASTER"
]
const MUSIC_LABELS: PackedStringArray = ["NO MUSIC", "ADLIB/SOUNDBLASTER"]
const SERVE_TICS := 70
const WINNING_SCORE := 21
const TICS_PER_FRAME := 4

var _menus: GalaxyMenuController
var _chosen: Array = []
var _sounds: Array[StringName] = []
var _redraws := 0


func run_all() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	super.run_all()
	_free_menus()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_the_main_card_is_the_originals() -> void:
	_create_menus()
	_menus.open_main(false)
	assert_equal(_labels(), MAIN_OUT_OF_GAME, "PADDLE WAR on the 7th row, as v1.0")
	assert_equal(_menus.top().items[PADDLE_ROW].id, GalaxyMenuController.PADDLE_WAR, "its id")
	assert_true(_menus.top().items[PADDLE_ROW].enabled, "it can be picked out of a game")
	_create_menus()
	_menus.open_main(true)
	assert_equal(_labels()[PADDLE_ROW], "PADDLE WAR", "and in a game")
	assert_true(_menus.top().items[PADDLE_ROW].enabled, "picked in a game too")
	for label in _labels():
		assert_true(not label.contains("CHOOSE"), "no Choose Game row: %s" % label)


func test_p_moves_to_paddle_war() -> void:
	_create_menus()
	_menus.open_main(false)
	_type("P")
	assert_equal(_menus.top().cursor, PADDLE_ROW, "P: PADDLE WAR (Omni IN_SC_P)")
	assert_equal(_chosen, [], "only moves")


func test_paddle_war_starts_from_the_main_card() -> void:
	_create_menus()
	_menus.open_main(false)
	assert_true(_menus.paddle_war() == null, "no game before")
	_start_paddle_war()
	assert_equal(_menus.top().kind, GalaxyMenuController.PADDLE_WAR, "the Paddle War card")
	var game := _menus.paddle_war()
	assert_true(game != null, "a game")
	assert_equal([game.keen_score, game.computer_score], [0, 0], "0 - 0")
	assert_true(not game.ball_visible, "the ball comes later")
	assert_equal(_chosen, [], "nothing chosen")
	assert_true(_menus.is_open(), "the panel stays open")


func test_paddle_war_runs_on_the_games_clock() -> void:
	_create_menus()
	_menus.open_main(true)
	_start_paddle_war()
	var game := _menus.paddle_war()
	_redraws = 0
	_menus.run_paddle_war(TICS_PER_FRAME, true, false)
	assert_equal(game.keen_x, GalaxyPaddleWar.START_X - 8, "Keen's paddle moved 4 tics")
	assert_true(_redraws > 0, "drawn again")
	_menus.run_paddle_war(20, false, true)
	assert_equal(game.keen_x, GalaxyPaddleWar.START_X, "at most 4 tics a frame")
	for _frame in SERVE_TICS / TICS_PER_FRAME:
		_menus.run_paddle_war(TICS_PER_FRAME, false, false)
	assert_true(game.ball_visible, "served after 70 tics")


func test_keys_do_not_leave_paddle_war_but_escape_does() -> void:
	_create_menus()
	_menus.open_main(false)
	_start_paddle_war()
	for key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_ENTER, KEY_SPACE, KEY_Y, KEY_Q]:
		_press(key)
		assert_equal(_menus.top().kind, GalaxyMenuController.PADDLE_WAR, "key %d plays on" % key)
	_press(KEY_ESCAPE)
	assert_equal(_menus.top().kind, MenuController.MAIN, "Escape: the main card (seen)")
	assert_equal(_menus.top().cursor, PADDLE_ROW, "the cursor on PADDLE WAR (seen)")
	assert_true(_menus.paddle_war() == null, "no game any more")
	assert_equal(_chosen, [], "nothing chosen")
	_menus.run_paddle_war(TICS_PER_FRAME, true, false)
	assert_equal(_menus.top().kind, MenuController.MAIN, "running it does nothing now")


func test_a_new_paddle_war_starts_from_0() -> void:
	_create_menus()
	_menus.open_main(false)
	_start_paddle_war()
	_play_until(func() -> bool: return _menus.paddle_war().computer_score >= 2)
	_press(KEY_ESCAPE)
	_press(KEY_ENTER)
	var game := _menus.paddle_war()
	assert_equal([game.keen_score, game.computer_score], [0, 0], "a new game, not the old one")


func test_the_sounds_are_asked_for() -> void:
	_create_menus()
	_menus.open_main(false)
	_start_paddle_war()
	_play_until(func() -> bool: return _menus.paddle_war().computer_score >= 1)
	assert_true(
		_sounds.has(&"paddle_computer_scores"), "the computer's point sound: %s" % str(_sounds)
	)
	for sound in _sounds:
		assert_true(Keen4Sounds.NUMBERS.has(sound), "%s is one of Keen 4's sounds" % sound)


func test_the_end_at_21_says_who_won() -> void:
	_create_menus()
	_menus.open_main(false)
	_start_paddle_war()
	var game := _menus.paddle_war()
	_play_until(func() -> bool: return game.is_done(), 20000)
	assert_true(game.is_done(), "the game ends")
	assert_equal(game.computer_score, WINNING_SCORE, "the computer won 21 - %d" % game.keen_score)
	assert_equal(_menus.top().kind, MenuController.MESSAGE, "a message")
	assert_equal(
		_menus.top().header, GalaxyMenuController.PADDLE_LOST_LINES, "the original's words"
	)
	assert_equal(
		GalaxyMenuController.PADDLE_LOST_LINES,
		PackedStringArray(["You lost!", "Press any key"]),
		"seen in v1.0"
	)
	assert_equal(
		GalaxyMenuController.PADDLE_WON_LINES,
		PackedStringArray(["You won!", "Press any key"]),
		"Omni ck_str_paddleWarVictory"
	)
	assert_equal(_menus.below().kind, GalaxyMenuController.PADDLE_WAR, "over the field")
	var shown := _menus.depth()
	_menus.run_paddle_war(TICS_PER_FRAME, false, false)
	assert_equal(_menus.depth(), shown, "running on does not ask twice")
	_press(KEY_SPACE)
	assert_equal(_menus.top().kind, MenuController.MAIN, "any key: the main card (seen)")
	assert_equal(_menus.top().cursor, PADDLE_ROW, "the cursor on PADDLE WAR (seen)")
	assert_true(_menus.is_open(), "the panel stays open")
	assert_equal(_chosen, [], "nothing chosen")


func test_the_cursor_does_not_blink_in_paddle_war() -> void:
	_create_menus()
	_menus.open_main(false)
	_start_paddle_war()
	_redraws = 0
	_menus.advance(GalaxyMenuController.BLINK_TICS * 3)
	assert_equal(_redraws, 0, "no blinking redraws over the field")


func test_quit_asks_with_choose_game() -> void:
	for way in ["row", "escape"]:
		_create_menus()
		_menus.open_main(false)
		if way == "row":
			_select(QUIT_ROW)
			_press(KEY_ENTER)
		else:
			_press(KEY_ESCAPE)
		assert_equal(_menus.top().kind, GalaxyMenuController.CONFIRM, "a question (%s)" % way)
		var lines: PackedStringArray = _menus.top().header
		assert_equal(lines, GalaxyMenuController.QUIT_LINES, "the quit lines (%s)" % way)
		assert_equal(lines[0], QUIT_FIRST, "the original's first line")
		assert_equal(lines[1], QUIT_YES, "the original's second line")
		assert_equal(lines[-1], BACK_OUT, "the original's last line")
		assert_true(lines.size() == 4 and lines[2].contains("C"), "a line for C: %s" % lines[2])
		assert_true(lines[2].length() <= 24, "it fits the watch: %s" % lines[2])


func test_c_in_the_quit_question_goes_to_the_start_screen() -> void:
	for in_game in [false, true]:
		_create_menus()
		_menus.open_main(in_game)
		_press(KEY_ESCAPE)
		_press(KEY_C)
		assert_equal(
			_chosen,
			[[MenuController.CHOICE_CHOOSE_GAME, 0]],
			"C: Choose Game (in game %s)" % in_game
		)
		assert_true(not _menus.is_open(), "the panel closes")


func test_y_quits_and_other_keys_back_out() -> void:
	_create_menus()
	_menus.open_main(false)
	_select(QUIT_ROW)
	for key in [KEY_N, KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_Q]:
		_press(KEY_ENTER)
		assert_equal(_menus.top().kind, GalaxyMenuController.CONFIRM, "asked")
		_press(key)
		assert_equal(_menus.top().kind, MenuController.MAIN, "key %d backs out" % key)
		assert_equal(_menus.top().cursor, QUIT_ROW, "the cursor stays on QUIT")
	assert_equal(_chosen, [], "nothing chosen")
	_press(KEY_ENTER)
	_press(KEY_Y)
	assert_equal(_chosen, [[MenuController.CHOICE_QUIT, 0]], "Y: quit")


func test_c_elsewhere_does_not_choose_a_game() -> void:
	# Only the quit question knows C; on the End Game question it is "no".
	_create_menus()
	_menus.open_main(true)
	_select(5)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, GalaxyMenuController.CONFIRM, "End Game asks")
	_press(KEY_C)
	assert_equal(_chosen, [], "C there: no")
	assert_equal(_menus.top().kind, MenuController.MAIN, "back on the main card")


func test_configure_has_sound_and_music_first() -> void:
	_open_configure()
	var labels := _labels()
	assert_equal(labels.slice(0, 3), PackedStringArray(["SOUND", "MUSIC", "OPTIONS"]), "as v1.0")
	assert_true(labels.has("KEYBOARD"), "the keys")
	assert_equal(_menus.top().cursor, 0, "the cursor on SOUND")


func test_the_sound_card() -> void:
	_open_configure()
	_menus.sound_choice = GalaxyMenuController.SoundChoice.ADLIB
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, GalaxyMenuController.SOUND_CARD, "the Sound card")
	assert_equal(_labels(), SOUND_LABELS, "v1.0's four choices")
	assert_equal(_menus.top().cursor, 2, "the cursor on the checked one (seen)")
	assert_equal(_checked(), [false, false, true, false], "AdLib checked")
	_press(KEY_UP)
	assert_equal(_checked(), [false, false, true, false], "moving does not check")
	assert_equal(_chosen, [], "nor choose")
	_press(KEY_ENTER)
	assert_equal(_chosen, [[GalaxyMenuController.CHOICE_SOUND, 1]], "PC speaker chosen at once")
	assert_equal(_menus.sound_choice, GalaxyMenuController.SoundChoice.PC, "kept")
	assert_equal(_checked(), [false, true, false, false], "PC checked, AdLib not (seen)")
	assert_equal(_menus.top().kind, GalaxyMenuController.SOUND_CARD, "the card stays (seen)")
	assert_equal(_menus.top().cursor, 1, "the cursor stays")
	assert_true(_menus.is_open(), "the panel stays open")
	_press(KEY_DOWN)
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_equal(
		_chosen[-1], [GalaxyMenuController.CHOICE_SOUND, 3], "quiet AdLib is a choice of its own"
	)
	assert_equal(_checked(), [false, false, false, true], "quiet AdLib checked")
	_type("N")
	assert_equal(_menus.top().cursor, 0, "N: NO SOUND EFFECTS")
	_press(KEY_ENTER)
	assert_equal(_chosen[-1], [GalaxyMenuController.CHOICE_SOUND, 0], "off")
	_press(KEY_ESCAPE)
	assert_equal(_menus.top().kind, GalaxyMenuController.CONFIGURE, "Escape: Configure (seen)")
	assert_equal(_menus.top().cursor, 0, "the cursor on SOUND (seen)")
	_press(KEY_ENTER)
	assert_equal(_menus.top().cursor, 0, "opened again: the cursor on the checked one")
	assert_equal(_checked(), [true, false, false, false], "off is checked")


func test_the_music_card() -> void:
	_open_configure()
	_menus.music_on = false
	_select(1)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, GalaxyMenuController.MUSIC_CARD, "the Music card")
	assert_equal(_labels(), MUSIC_LABELS, "v1.0's two choices")
	assert_equal(_menus.top().cursor, 0, "the cursor on NO MUSIC, the checked one (seen)")
	assert_equal(_checked(), [true, false], "no music checked")
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_equal(_chosen, [[GalaxyMenuController.CHOICE_MUSIC, 1]], "music on at once")
	assert_true(_menus.music_on, "kept")
	assert_equal(_checked(), [false, true], "AdLib checked (seen)")
	assert_equal(_menus.top().kind, GalaxyMenuController.MUSIC_CARD, "the card stays")
	_press(KEY_ENTER)
	assert_equal(_chosen.size(), 2, "picking the checked one again still tells")
	assert_true(_menus.music_on, "still on")
	_press(KEY_UP)
	_press(KEY_ENTER)
	assert_equal(_chosen[-1], [GalaxyMenuController.CHOICE_MUSIC, 0], "off")
	assert_true(not _menus.music_on, "kept off")
	_press(KEY_ESCAPE)
	assert_equal(_menus.top().kind, GalaxyMenuController.CONFIGURE, "back on Configure")
	assert_equal(_menus.top().cursor, 1, "the cursor on MUSIC")


func test_the_score_box_message_shows_the_old_state_behind_it() -> void:
	_open_configure()
	_select(2)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, MenuController.OPTIONS, "Options")
	assert_equal(_labels()[0], "SCORE BOX (ON)", "on")
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, MenuController.MESSAGE, "the message")
	assert_equal(
		_menus.top().header,
		PackedStringArray(["Score box now off", "Press any key"]),
		"v1.0's words"
	)
	assert_equal(_menus.below().kind, MenuController.OPTIONS, "over the Options card")
	assert_equal(_menus.below().items[0].label, "SCORE BOX (ON)", "which still says ON (seen)")
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, MenuController.OPTIONS, "a key: the card")
	assert_equal(_labels()[0], "SCORE BOX (OFF)", "now OFF (seen)")
	assert_equal(_menus.top().cursor, 0, "the cursor on SCORE BOX")
	_press(KEY_ENTER)
	assert_equal(_menus.top().header[0], "Score box now on", "and on again")
	assert_equal(_menus.below().items[0].label, "SCORE BOX (OFF)", "the card still says OFF")
	_press(KEY_ESCAPE)
	assert_equal(_labels()[0], "SCORE BOX (ON)", "Escape is a key too")


func test_a_stale_card_is_only_the_options_card() -> void:
	# The Reset Keys message is not followed by an Options card rebuild.
	_open_configure()
	var keys_row := _labels().find("RESET KEYS")
	assert_true(keys_row >= 0, "RESET KEYS on Configure")
	_select(keys_row)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, MenuController.MESSAGE, "its message")
	_press(KEY_SPACE)
	assert_equal(_menus.top().kind, GalaxyMenuController.CONFIGURE, "back on Configure")
	assert_equal(_menus.top().cursor, keys_row, "the cursor where it was")
	KeyBindings.reset()


func _create_menus() -> void:
	_free_menus()
	_menus = GalaxyMenuController.new()
	_menus.slots = GalaxySaveSlots.in_directory(TEST_DIRECTORY.path_join("saves"))
	_menus.settings = UserSettings.new()
	_menus.settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	# A fixed random: every serve goes right (1 − 0 mod 3) and misses Keen.
	_menus.random = func() -> int: return 0
	_chosen = []
	_sounds = []
	_redraws = 0
	_menus.chosen.connect(func(id: StringName, value: int) -> void: _chosen.append([id, value]))
	_menus.redrawn.connect(func() -> void: _redraws += 1)
	_menus.sound_requested.connect(_sounds.append)


func _free_menus() -> void:
	if _menus != null:
		_menus.free()
		_menus = null


func _open_configure() -> void:
	_create_menus()
	_menus.open_main(false)
	_select(CONFIGURE_ROW)
	_press(KEY_ENTER)


func _start_paddle_war() -> void:
	_select(PADDLE_ROW)
	_press(KEY_ENTER)


## Runs Paddle War frame by frame (4 tics, no keys) until [param done].
func _play_until(done: Callable, frames := 2000) -> void:
	for _frame in frames:
		if _menus.paddle_war() == null or done.call():
			return
		_menus.run_paddle_war(TICS_PER_FRAME, false, false)


func _checked() -> Array:
	var checked := []
	for index in _menus.top().items.size():
		checked.append(_menus.is_checked(_menus.top(), index))
	return checked


func _labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for item in _menus.top().items:
		labels.append(item.label.strip_edges())
	return labels


func _select(row: int) -> void:
	_menus.top().cursor = row


func _press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	_menus.handle_input(event)


func _type(letter: String) -> void:
	var event := InputEventKey.new()
	event.unicode = letter.unicode_at(0)
	var key := OS.find_keycode_from_string(letter.to_upper())
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	_menus.handle_input(event)


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
