extends "res://tests/test_case.gd"
## Tests the Galaxy control panel's logic ([GalaxyMenuController], milestone
## D10) without game files, against what the original (v1.0) does in js-dos
## and Omnispeak's card code (facts only): the main card in and out of a
## game, New Game per difficulty with the cursor on Normal, the questions
## before ending, quitting or starting over, Load and Save with six slots and
## a typed name, the score box option, Choose Game (D11: C on the quit
## question), the cursor that stops at the ends and blinks every 35 tics. Saved games and settings go to a folder
## of their own in the user folder, which is removed afterwards.

const TEST_DIRECTORY := "user://test_galaxy_menus"
const SLOTS := 6
## The main card's choices, in the original's order (D11: Paddle War in
## its row; Choose Game is on the quit question).
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
const SAVE_ROW := 2
const RETURN_ROW := 4
const END_ROW := 5
const QUIT_ROW := 7
## Seen in the original: the cursor rests 35 tics shown, 35 hidden (Omni).
const BLINK_TICS := 35

var _menus: GalaxyMenuController
var _chosen: Array = []
var _closed := 0
var _redraws := 0


func run_all() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	super.run_all()
	_free_menus()
	KeyBindings.reset()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_main_card_out_of_a_game() -> void:
	_create_menus()
	_menus.open_main(false)
	assert_equal(_labels(), MAIN_OUT_OF_GAME, "the main card's choices")
	assert_equal(_enabled(), [true, true, false, true, true, false, true, true], "which work")
	assert_equal(_menus.top().cursor, 0, "the cursor starts on NEW GAME")
	assert_equal(_menus.top().kind, MenuController.MAIN, "the main card")


func test_main_card_in_a_game() -> void:
	_create_menus()
	_menus.open_main(true)
	var labels := MAIN_OUT_OF_GAME.duplicate()
	labels[RETURN_ROW] = "RETURN TO GAME"
	assert_equal(_labels(), labels, "Return to Game in a game")
	assert_equal(_enabled(), [true, true, true, true, true, true, true, true], "all work")
	assert_equal(_menus.top().cursor, RETURN_ROW, "the cursor starts on RETURN TO GAME")


func test_return_closes_the_panel() -> void:
	_create_menus()
	_menus.open_main(true)
	_press(KEY_ENTER)
	assert_equal(_chosen, [[MenuController.CHOICE_RESUME, 0]], "back to the game")
	assert_true(not _menus.is_open(), "closed")
	assert_equal(_closed, 1, "closed once")
	_create_menus()
	_menus.open_main(false)
	_select(RETURN_ROW)
	_press(KEY_ENTER)
	assert_equal(_chosen, [[MenuController.CHOICE_RESUME, 0]], "back to the demo")


func test_save_and_end_cannot_be_picked_out_of_a_game() -> void:
	_create_menus()
	_menus.open_main(false)
	for row in [SAVE_ROW, END_ROW]:
		_select(row)
		_press(KEY_ENTER)
		assert_equal(_menus.depth(), 1, "row %d does nothing" % row)
	assert_equal(_chosen, [], "nothing chosen")


func test_moving_the_cursor() -> void:
	# It stops at the ends and rests on what cannot be picked; a letter
	# moves it to the choice starting with it (Omni).
	_create_menus()
	_menus.open_main(false)
	_press(KEY_UP)
	assert_equal(_menus.top().cursor, 0, "no wrapping at the top")
	_press(KEY_DOWN)
	_press(KEY_DOWN)
	assert_equal(_menus.top().cursor, SAVE_ROW, "it rests on SAVE GAME (seen in the original)")
	for _step in 10:
		_press(KEY_DOWN)
	assert_equal(_menus.top().cursor, QUIT_ROW, "no wrapping at the bottom")
	_type("c")
	assert_equal(_menus.top().cursor, 3, "C: CONFIGURE, the first with C")
	_type("Q")
	assert_equal(_menus.top().cursor, QUIT_ROW, "Q: QUIT")
	assert_equal(_chosen, [], "a letter only moves")


func test_new_game_card_starts_on_normal() -> void:
	_create_menus()
	_menus.open_main(false)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, GalaxyMenuController.NEW_GAME, "the New Game card")
	assert_equal(
		_labels(),
		PackedStringArray(["BEGIN EASY GAME", "BEGIN NORMAL GAME", "BEGIN HARD GAME"]),
		"its choices"
	)
	assert_equal(_menus.top().cursor, 1, "the cursor on BEGIN NORMAL GAME (the original)")
	_press(KEY_ENTER)
	assert_equal(
		_chosen,
		[[MenuController.CHOICE_NEW_GAME, GalaxyDifficulty.Level.NORMAL]],
		"Enter, Enter: a Normal game"
	)
	assert_true(not _menus.is_open(), "the panel closes")


func test_new_game_per_difficulty() -> void:
	var ways := {
		GalaxyDifficulty.Level.EASY: [KEY_UP],
		GalaxyDifficulty.Level.NORMAL: [],
		GalaxyDifficulty.Level.HARD: [KEY_DOWN],
	}
	for level: GalaxyDifficulty.Level in ways:
		_create_menus()
		_menus.open_main(false)
		_press(KEY_ENTER)
		for key: Key in ways[level]:
			_press(key)
		_press(KEY_ENTER)
		assert_equal(_chosen, [[MenuController.CHOICE_NEW_GAME, level]], "difficulty %d" % level)


func test_new_game_in_a_game_asks_first() -> void:
	_create_menus()
	_menus.open_main(true)
	_select(0)
	_press(KEY_ENTER)
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, GalaxyMenuController.CONFIRM, "a question")
	assert_equal(
		_menus.top().header,
		PackedStringArray(["YOU'RE IN A GAME", "PRESS Y FOR NEW GAME", "ESC TO BACK OUT"]),
		"the original's words"
	)
	_press(KEY_N)
	assert_equal(_chosen, [], "N: no")
	assert_equal(_menus.top().kind, GalaxyMenuController.NEW_GAME, "back on the card")
	_press(KEY_ENTER)
	_press(KEY_Y)
	assert_equal(
		_chosen, [[MenuController.CHOICE_NEW_GAME, GalaxyDifficulty.Level.HARD]], "Y: a new game"
	)
	assert_true(not _menus.is_open(), "the panel closes")


func test_end_game_asks_and_ends() -> void:
	_create_menus()
	_menus.open_main(true)
	_select(END_ROW)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, GalaxyMenuController.CONFIRM, "a question")
	assert_equal(
		_menus.top().header,
		PackedStringArray(["REALLY END CURRENT GAME?", "PRESS Y TO END IT", "ESC TO BACK OUT"]),
		"the original's words"
	)
	_press(KEY_ESCAPE)
	assert_equal(_menus.top().kind, MenuController.MAIN, "Escape: back on the main card")
	assert_equal(_chosen, [], "not ended")
	_press(KEY_ENTER)
	_press(KEY_Y)
	assert_equal(_chosen, [[GalaxyMenuController.CHOICE_END_GAME, 0]], "Y: the game ends")
	assert_true(not _menus.is_open(), "the panel closes")


func test_quit_asks_also_on_escape() -> void:
	_create_menus()
	_menus.open_main(false)
	_press(KEY_ESCAPE)
	assert_equal(_menus.top().kind, GalaxyMenuController.CONFIRM, "Escape on the main card asks")
	assert_equal(
		_menus.top().header,
		PackedStringArray(
			["REALLY QUIT?", "PRESS Y TO QUIT", "PRESS C TO CHOOSE GAME", "ESC TO BACK OUT"]
		),
		"the original's words and ours (C)"
	)
	_press(KEY_ESCAPE)
	assert_equal(_menus.top().kind, MenuController.MAIN, "Escape: no")
	_select(QUIT_ROW)
	_press(KEY_ENTER)
	_press(KEY_N)
	assert_equal(_chosen, [], "N: no")
	assert_true(_menus.is_open(), "still open")
	_press(KEY_ENTER)
	_press(KEY_Y)
	assert_equal(_chosen, [[MenuController.CHOICE_QUIT, 0]], "Y: quit")


func test_choose_game_goes_back_to_the_start_screen() -> void:
	for in_game in [false, true]:
		_create_menus()
		_menus.open_main(in_game)
		_select(QUIT_ROW)
		_press(KEY_ENTER)
		_press(KEY_C)
		assert_equal(
			_chosen, [[MenuController.CHOICE_CHOOSE_GAME, 0]], "Choose Game (in game %s)" % in_game
		)
		assert_true(not _menus.is_open(), "the panel closes")


func test_escape_backs_out_of_a_card() -> void:
	_create_menus()
	_menus.open_main(false)
	_select(3)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, GalaxyMenuController.CONFIGURE, "Configure")
	_press(KEY_ESCAPE)
	assert_equal(_menus.top().kind, MenuController.MAIN, "back on the main card")
	assert_equal(_menus.top().cursor, 3, "the cursor where it was")


func test_load_card_offers_saved_slots_only() -> void:
	_create_menus()
	assert_true(_menus.slots.write(3, "Border", {"x": 1}), "a game in slot 3")
	_menus.open_main(false)
	_select(1)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, MenuController.SLOTS_LOAD, "the Load card")
	assert_equal(_menus.top().items.size(), SLOTS, "six slots")
	assert_equal(_enabled(), [false, false, true, false, false, false], "only slot 3")
	assert_equal(_menus.top().items[2].label, "Border", "with its name")
	_press(KEY_ENTER)
	assert_equal(_chosen, [], "an empty slot cannot be loaded")
	_type("3")
	assert_equal(_menus.top().cursor, 2, "the number key moves to slot 3")
	_press(KEY_ENTER)
	assert_equal(_chosen, [[MenuController.CHOICE_LOAD, 3]], "slot 3 loaded")
	assert_true(not _menus.is_open(), "the panel closes")


func test_loading_in_a_game_asks_first() -> void:
	_create_menus()
	_menus.slots.write(1, "One", {})
	_menus.open_main(true)
	_select(1)
	_press(KEY_ENTER)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, GalaxyMenuController.CONFIRM, "a question")
	assert_equal(_menus.top().header[1], "PRESS Y TO LOAD GAME", "load?")
	_press(KEY_Y)
	assert_equal(_chosen, [[MenuController.CHOICE_LOAD, 1]], "Y: loaded")


func test_saving_types_a_name_and_stays_on_the_card() -> void:
	_create_menus()
	_menus.chosen.connect(_write_save)
	_menus.open_main(true)
	_select(SAVE_ROW)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, MenuController.SLOTS_SAVE, "the Save card")
	assert_equal(_enabled(), [true, true, true, true, true, true], "every slot can be written")
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, GalaxyMenuController.SLOT_NAME, "typing a name")
	assert_equal(_menus.typed_save_name, "", "an empty slot starts empty")
	for letter in "Lifewaterx":
		_type(letter)
	_press(KEY_BACKSPACE)
	_press(KEY_ENTER)
	assert_equal(_chosen, [[MenuController.CHOICE_SAVE, 2]], "saved in slot 2")
	assert_equal(_menus.typed_save_name, "Lifewater", "the typed name")
	assert_true(_menus.is_open(), "the panel stays open (the original)")
	assert_equal(_menus.top().kind, MenuController.SLOTS_SAVE, "on the Save card")
	assert_equal(_menus.top().cursor, 1, "on slot 2")
	assert_equal(_menus.top().items[1].label, "Lifewater", "showing the new name")
	# Saving again over it starts from the old name.
	_press(KEY_ENTER)
	assert_equal(_menus.typed_save_name, "Lifewater", "the old name to change")


func test_an_empty_name_is_untitled_and_escape_keeps_the_slot() -> void:
	_create_menus()
	_menus.chosen.connect(_write_save)
	_menus.open_main(true)
	_select(SAVE_ROW)
	_press(KEY_ENTER)
	_press(KEY_ENTER)
	_type("x")
	_press(KEY_ESCAPE)
	assert_equal(_chosen, [], "Escape: not saved")
	assert_equal(_menus.top().kind, MenuController.SLOTS_SAVE, "back on the Save card")
	assert_true(not _menus.slots.exists(1), "slot 1 still empty")
	_press(KEY_ENTER)
	_press(KEY_ENTER)
	assert_equal(_chosen, [[MenuController.CHOICE_SAVE, 1]], "saved")
	assert_equal(_menus.slots.name_of(1), GalaxyMenuController.UNTITLED, "without a name")


func test_a_saved_game_ends_without_a_question() -> void:
	_create_menus()
	_menus.chosen.connect(_write_save)
	_menus.open_main(true)
	_select(SAVE_ROW)
	_press(KEY_ENTER)
	_press(KEY_ENTER)
	_type("a")
	_press(KEY_ENTER)
	_press(KEY_ESCAPE)
	_select(END_ROW)
	_chosen.clear()
	_press(KEY_ENTER)
	assert_equal(
		_chosen, [[GalaxyMenuController.CHOICE_END_GAME, 0]], "just saved: no question (Omni)"
	)


func test_configure_and_the_score_box() -> void:
	_create_menus()
	_menus.open_main(false)
	_select(3)
	_press(KEY_ENTER)
	var labels := _labels()
	assert_true(labels.size() >= 2, "Configure has choices")
	assert_equal(
		labels.slice(0, 3),
		PackedStringArray(["SOUND", "MUSIC", "OPTIONS"]),
		"Sound, Music, Options"
	)
	_select(2)
	_press(KEY_ENTER)
	assert_equal(_menus.top().kind, MenuController.OPTIONS, "the Options card")
	assert_equal(_labels()[0], "SCORE BOX (ON)", "the score box, on")
	_press(KEY_ENTER)
	assert_equal(_chosen, [[GalaxyMenuController.CHOICE_SCORE_BOX, 0]], "switched off")
	assert_true(not _menus.score_box, "off")
	assert_equal(_menus.top().kind, MenuController.MESSAGE, "a message (the original)")
	assert_equal(_menus.top().header[0], "Score box now off", "the original's words")
	_press(KEY_SPACE)
	assert_equal(_menus.top().kind, MenuController.OPTIONS, "any key: back on Options")
	assert_equal(_labels()[0], "SCORE BOX (OFF)", "shown off")
	_press(KEY_ENTER)
	assert_equal(_chosen[-1], [GalaxyMenuController.CHOICE_SCORE_BOX, 1], "on again")
	_press(KEY_SPACE)
	# The picture's settings are the shared ones (all games): widescreen.
	var changed := [0]
	_menus.settings_changed.connect(func() -> void: changed[0] += 1)
	var aspect := _menus.settings.display.aspect
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_true(_menus.settings.display.aspect != aspect, "widescreen switched")
	assert_equal(changed[0], 1, "the game is told")
	assert_true(FileAccess.file_exists(_menus.settings.path), "kept in the shared settings file")


func test_the_cursor_blinks_every_35_tics() -> void:
	_create_menus()
	_menus.open_main(false)
	_redraws = 0
	assert_true(_menus.cursor_shown, "shown at first")
	_menus.advance(BLINK_TICS - 1)
	assert_true(_menus.cursor_shown, "still shown after 34 tics")
	assert_equal(_redraws, 0, "nothing to draw")
	_menus.advance(1)
	assert_true(not _menus.cursor_shown, "hidden after 35")
	assert_equal(_redraws, 1, "drawn again")
	_menus.advance(BLINK_TICS)
	assert_true(_menus.cursor_shown, "shown after 70")
	_menus.advance(BLINK_TICS)
	_press(KEY_DOWN)
	assert_true(_menus.cursor_shown, "a key shows it at once")


func _create_menus() -> void:
	_free_menus()
	_menus = GalaxyMenuController.new()
	_menus.slots = GalaxySaveSlots.in_directory(TEST_DIRECTORY.path_join("saves"))
	for slot in range(1, SLOTS + 1):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_menus.slots._path(slot)))
	_menus.settings = UserSettings.new()
	_menus.settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_chosen = []
	_closed = 0
	_redraws = 0
	_menus.chosen.connect(func(id: StringName, value: int) -> void: _chosen.append([id, value]))
	_menus.closed.connect(func() -> void: _closed += 1)
	_menus.redrawn.connect(func() -> void: _redraws += 1)


## What a game does when the panel asks to save: write the slot.
func _write_save(id: StringName, slot: int) -> void:
	if id == MenuController.CHOICE_SAVE:
		_menus.slots.write(slot, _menus.typed_save_name, {"slot": slot})


func _free_menus() -> void:
	if _menus != null:
		_menus.free()
		_menus = null


func _labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for item in _menus.top().items:
		labels.append(item.label.strip_edges())
	return labels


func _enabled() -> Array:
	var enabled := []
	for item in _menus.top().items:
		enabled.append(item.enabled)
	return enabled


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
