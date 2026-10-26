extends "res://tests/test_case.gd"
## Tests for the menus: moving the cursor, the main menu in and out of a
## game, saving into a slot, changing a key, the options and typing a name
## for the high score table. The settings and saved games go to a folder of
## their own in the user folder, which is removed afterwards.

const TEST_DIRECTORY := "user://test_menus"

var _window: GameWindow
var _menus: MenuController
var _chosen: Array = []


func run_all() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	super.run_all()
	_free_nodes()
	KeyBindings.reset()
	for file_name in ["settings.cfg", "saves/slot2.json", "saves/slot5.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(file_name)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_path("saves")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_cursor_skips_what_cannot_be_picked() -> void:
	var menu := Menu.create(&"test").add("A", &"a", 0, false).add("B", &"b").add(
		"C", &"c", 0, false
	)
	menu.add("D", &"d")
	assert_equal(menu.current().id, &"b", "starts on the first that can be picked")
	menu.move(1)
	assert_equal(menu.current().id, &"d", "skips C")
	menu.move(1)
	assert_equal(menu.current().id, &"b", "wraps around and skips A")
	menu.move(-1)
	assert_equal(menu.current().id, &"d", "wraps backwards")
	menu.select(&"b")
	assert_equal(menu.current().id, &"b", "select")


func test_menu_without_choices_has_none() -> void:
	var menu := Menu.create(&"test").add("A", &"a", 0, false)
	assert_true(menu.current() == null, "nothing to pick")


func test_main_menu_only_offers_saving_in_a_game() -> void:
	_create_menus()
	_menus.open_main(false, false)
	assert_true(not _labels().has("Save Game"), "not at the title")
	assert_true(not _labels().has("Return to Game"), "nothing to return to")
	_menus.open_main(true, true)
	assert_equal(_labels()[0], "Return to Game", "first choice in a game")
	assert_true(_labels().has("Save Game"), "save")
	_press(KEY_ENTER)
	assert_true(not _menus.is_open(), "closed")
	assert_equal(_chosen, [[MenuController.CHOICE_RESUME, 0]], "back to the game")


func test_saving_away_from_the_map_shows_a_message() -> void:
	_create_menus()
	_menus.open_main(true, false)
	_choose("Save Game")
	assert_equal(_menus._top().kind, MenuController.MESSAGE, "a message")
	_press(KEY_SPACE)
	assert_true(_menus.is_open(), "back in the main menu")
	assert_equal(_chosen, [], "nothing saved")


func test_saving_into_a_slot() -> void:
	_create_menus()
	_menus.open_main(true, true)
	_choose("Save Game")
	assert_equal(_menus._top().kind, MenuController.SLOTS_SAVE, "the slots")
	_press(KEY_2)
	assert_equal(_chosen, [[MenuController.CHOICE_SAVE, 2]], "slot 2 by its number")
	_press(KEY_SPACE)
	assert_true(not _menus.is_open(), "the message closes")


func test_taken_slot_asks_before_overwriting() -> void:
	_create_menus()
	_menus.saves.write(5, GameProgress.new())
	_menus.open_main(true, true)
	_choose("Save Game")
	_press(KEY_5)
	assert_equal(_menus._top().kind, MenuController.OVERWRITE, "asks")
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_equal(_chosen, [], "kept")
	_press(KEY_5)
	_press(KEY_ENTER)
	assert_equal(_chosen, [[MenuController.CHOICE_SAVE, 5]], "overwritten")


func test_only_saved_games_can_be_continued() -> void:
	_create_menus()
	_menus.saves.write(5, GameProgress.new())
	_menus.open_main(false, false)
	_choose("Continue Game")
	_press(KEY_1)
	assert_equal(_chosen, [], "slot 1 is empty")
	_press(KEY_ENTER)
	assert_equal(_chosen, [[MenuController.CHOICE_LOAD, 5]], "the cursor starts on slot 5")


func test_changing_a_key() -> void:
	KeyBindings.reset()
	_create_menus()
	_menus.open_main(false, false)
	_choose("Controls")
	_choose("One player")
	_press(KEY_DOWN)
	_press(KEY_DOWN)
	_press(KEY_DOWN)
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_equal(_menus._top().kind, MenuController.PRESS_KEY, "waits for a key")
	_press(KEY_F2)
	assert_equal(_menus._top().kind, MenuController.PRESS_KEY, "F2 is taken by the game")
	_press(KEY_K)
	assert_equal(KeyBindings.keys_of("jump")[0], KEY_K, "jump is now K")
	assert_true(_labels()[4].contains("K"), "the menu shows it")
	var stored := ConfigFile.new()
	assert_equal(stored.load(_menus.settings.path), OK, "settings saved")
	KeyBindings.reset()


func test_main_menu_adds_and_removes_player_2() -> void:
	_create_menus()
	_menus.open_main(false, false)
	assert_true(not _labels().has("Add Player 2"), "not at the title")
	_menus.open_main(true, false)
	_choose("Add Player 2")
	assert_equal(_chosen, [[MenuController.CHOICE_SECOND_PLAYER, 0]], "joins")
	_menus.open_main(true, false, true)
	assert_true(_labels().has("Remove Player 2"), "can leave again")


func test_changing_a_key_of_player_2() -> void:
	KeyBindings.reset()
	_create_menus()
	_menus.open_main(false, false)
	_choose("Controls")
	_choose("Two players: player 2")
	assert_true(_labels()[2].contains("."), "jumps with the period")
	_choose(_labels()[2])
	var right_shift := InputEventKey.new()
	right_shift.physical_keycode = KEY_SHIFT
	right_shift.location = KEY_LOCATION_RIGHT
	right_shift.pressed = true
	_menus.handle_input(right_shift)
	var code := KeyBindings.make_code(KEY_SHIFT, KEY_LOCATION_RIGHT)
	assert_equal(KeyBindings.keys_of("p2_jump"), [code] as Array[int], "jumps with right shift")
	assert_true(KeyBindings.keys_of("p2_fire").is_empty(), "taken from fire")
	assert_true(_labels()[2].contains("RIGHT SHIFT"), "the menu shows it")
	KeyBindings.reset()


func test_options_change_the_settings() -> void:
	_create_menus()
	var changes := []
	_menus.settings_changed.connect(func() -> void: changes.append(true))
	_menus.open_main(false, false)
	_choose("Options")
	_press(KEY_ENTER)
	assert_true(not _menus.settings.sound_enabled, "sound off")
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_equal(_menus.settings.display.aspect, DisplaySettings.Aspect.ORIGINAL, "widescreen off")
	assert_equal(changes.size(), 2, "the game is told twice")
	_press(KEY_DOWN)
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_true(not _menus.settings.fullscreen, "full screen off")
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_true(_menus.settings.display.smooth_motion, "smooth motion on")
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_equal(_menus.settings.display.graphics, DisplaySettings.Graphics.XBRZ, "xBRZ")
	_press(KEY_ENTER)
	assert_equal(
		_menus.settings.display.graphics, DisplaySettings.Graphics.ORIGINAL, "no HD graphics made"
	)
	_menus.hd_available = true
	_press(KEY_ENTER)
	_press(KEY_ENTER)
	assert_equal(_menus.settings.display.graphics, DisplaySettings.Graphics.HD, "HD once made")
	assert_true(_labels()[-3].ends_with("HD"), "the menu shows it")
	assert_true(not _menus.settings.display.realistic, "realistic off by default")
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_true(_menus.settings.display.realistic, "realistic on")
	assert_true(_labels()[-2].ends_with("REALISTIC"), "the menu shows the realistic lighting")
	assert_true(_menus.settings.extra_levels, "extra levels on by default")
	_press(KEY_DOWN)
	_press(KEY_ENTER)
	assert_true(not _menus.settings.extra_levels, "extra levels off")
	assert_true(_labels()[-1].ends_with("OFF"), "the menu shows that too")
	_press(KEY_ESCAPE)
	_press(KEY_ESCAPE)
	assert_true(not _menus.is_open(), "Escape goes back one menu at a time")


func test_typing_a_name() -> void:
	_create_menus()
	var names: Array[String] = []
	_menus.name_entered.connect(func(player_name: String) -> void: names.append(player_name))
	_menus.ask_name("first")
	for letter in "Billyy":
		_type(letter)
	_press(KEY_BACKSPACE)
	for letter in "x".repeat(HighScores.MAX_NAME_LENGTH):
		_type(letter)
	_press(KEY_ENTER)
	assert_equal(names.size(), 1, "entered")
	assert_equal(names[0].length(), HighScores.MAX_NAME_LENGTH, "no longer than allowed")
	assert_true(names[0].begins_with("Billy"), "with backspace")
	assert_true(not _menus.is_open(), "closed")


func test_story_scrolls_and_closes() -> void:
	_create_menus()
	for line in 40:
		_menus.story.append("line %d" % line)
	_menus.open_main(false, false)
	_choose("Story")
	_press(KEY_PAGEDOWN)
	assert_equal(_menus._story_offset, 40 - MenuController.TEXT_LINES, "to the last page")
	_press(KEY_UP)
	assert_equal(_menus._story_offset, 40 - MenuController.TEXT_LINES - 1, "one line up")
	_press(KEY_ESCAPE)
	assert_equal(_menus._top().kind, MenuController.MAIN, "back to the main menu")


func _create_menus() -> void:
	_free_nodes()
	_window = GameWindow.new()
	_menus = MenuController.new()
	_menus.window = _window
	_menus.saves = SaveGames.in_directory(_path("saves"))
	for slot in range(1, SaveGames.SLOT_COUNT + 1):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_menus.saves._path(slot)))
	_menus.settings = UserSettings.new()
	_menus.settings.path = _path("settings.cfg")
	_chosen = []
	_menus.chosen.connect(func(id: StringName, value: int) -> void: _chosen.append([id, value]))


func _free_nodes() -> void:
	if _menus != null:
		_menus.free()
		_window.free()
		_menus = null


func _labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for item in _menus._top().items:
		labels.append(item.label)
	return labels


## Moves the cursor to the choice called [param label] and picks it.
func _choose(label: String) -> void:
	var menu := _menus._top()
	for index in menu.items.size():
		if menu.items[index].label == label:
			menu.cursor = index
	_press(KEY_ENTER)


func _press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	_menus.handle_input(event)


func _type(letter: String) -> void:
	var event := InputEventKey.new()
	event.unicode = letter.unicode_at(0)
	event.pressed = true
	_menus.handle_input(event)


func _path(file_name: String) -> String:
	return TEST_DIRECTORY.path_join(file_name)
