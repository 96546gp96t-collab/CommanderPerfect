extends "res://tests/test_case.gd"
## Tests for what the game keeps between sessions: saved games, the high
## score table, the settings and the keys. Files go to a folder of their own
## in the user folder, which is removed afterwards.

const TEST_DIRECTORY := "user://test_saving"


func run_all() -> void:
	_remove_test_directory()
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	super.run_all()
	KeyBindings.reset()
	_remove_test_directory()


func test_progress_survives_a_round_trip() -> void:
	var game := GameProgress.new()
	game.inventory.add_points(25000)
	game.inventory.charges = 7
	game.inventory.has_pogo = true
	game.inventory.ship_parts[Inventory.ShipPart.BATTERY] = true
	game.complete_level(1)
	game.complete_level(4)
	game.map_position = Vector2(120, 340)
	var copy := GameProgress.from_dict(JSON.parse_string(JSON.stringify(game.to_dict())))
	assert_true(copy != null, "read back")
	if copy == null:
		return
	assert_equal(copy.inventory.score, 25000, "score")
	assert_equal(copy.inventory.lives, Inventory.START_LIVES + 1, "lives with the extra one")
	assert_equal(copy.inventory.next_extra_life(), 40000, "next extra life")
	assert_equal(copy.inventory.charges, 7, "charges")
	assert_true(copy.inventory.has_pogo, "pogo stick")
	assert_equal(copy.inventory.ship_parts, [false, true, false, false] as Array[bool], "parts")
	assert_equal(copy.completed_levels(), PackedInt32Array([1, 4]), "completed levels")
	assert_equal(copy.map_position, Vector2(120, 340), "place on the map")


func test_new_game_keeps_its_start_position() -> void:
	var copy := GameProgress.from_dict(GameProgress.new().to_dict())
	assert_true(copy != null and not copy.map_position.is_finite(), "starts at the map start")


func test_damaged_progress_is_rejected() -> void:
	assert_true(GameProgress.from_dict({}) == null, "empty")
	var data := GameProgress.new().to_dict()
	data.inventory.erase("score")
	assert_true(GameProgress.from_dict(data) == null, "no score")


func test_save_slots() -> void:
	var saves := SaveGames.in_directory(TEST_DIRECTORY.path_join("saves"))
	assert_true(not saves.exists(3), "empty slot")
	assert_true(saves.read(3) == null, "nothing to read")
	var game := GameProgress.new()
	game.complete_level(2)
	assert_true(saves.write(3, game), "saved")
	assert_true(saves.exists(3), "slot taken")
	var loaded := saves.read(3)
	assert_true(loaded != null and loaded.is_completed(2), "read back")


func test_save_of_another_version_is_rejected() -> void:
	var saves := SaveGames.in_directory(TEST_DIRECTORY.path_join("old"))
	DirAccess.make_dir_recursive_absolute(saves.directory)
	var file := FileAccess.open(saves.directory.path_join("slot1.json"), FileAccess.WRITE)
	file.store_string('{"version": 0, "game": {}}')
	file.close()
	assert_true(saves.exists(1), "there is a file")
	assert_true(saves.read(1) == null, "but not one we can read")


func test_new_high_score_table() -> void:
	var table := HighScores.load_from(_path("none.json"), PackedStringArray(["A", "B"]))
	assert_equal(table.entries.size(), HighScores.PLACES, "seven places")
	assert_equal(table.entries[1].name, "B", "default names")
	assert_equal(table.entries[2].name, "", "then empty places")
	assert_equal(table.place_for(HighScores.DEFAULT_SCORE), -1, "a tie is not enough")
	assert_equal(table.place_for(HighScores.DEFAULT_SCORE + 1), 0, "more is first")


func test_high_scores_are_inserted_and_saved() -> void:
	var path := _path("scores.json")
	var table := HighScores.load_from(path)
	var parts: Array[bool] = [true, false, true, false]
	table.insert(0, "Keen", 5000, parts)
	table.insert(table.place_for(300), "A very long name indeed", 300, parts)
	assert_equal(table.entries.size(), HighScores.PLACES, "still seven")
	assert_equal(table.entries[1].name.length(), HighScores.MAX_NAME_LENGTH, "name cut off")
	assert_true(table.save(), "saved")
	var loaded := HighScores.load_from(path)
	assert_equal(loaded.entries[0].name, "Keen", "name")
	assert_equal(loaded.entries[0].score, 5000, "score")
	assert_equal(loaded.entries[0].ship_parts, parts, "parts")
	assert_equal(loaded.place_for(400), 1, "between the two new ones")


func test_binding_a_key_moves_it_between_actions() -> void:
	KeyBindings.reset()
	var arrows := KeyBindings.keys_of("move_left")
	assert_true(arrows.size() >= 2, "arrow and a letter")
	KeyBindings.bind("move_left", KEY_J)
	assert_equal(KeyBindings.keys_of("move_left")[0], KEY_J, "new first key")
	assert_equal(KeyBindings.keys_of("move_left").slice(1), arrows.slice(1), "others kept")
	var jump_key := KeyBindings.keys_of("jump")[0]
	KeyBindings.bind("fire", jump_key)
	assert_true(not KeyBindings.keys_of("jump").has(jump_key), "taken from jump")
	assert_equal(KeyBindings.keys_of("fire")[0], jump_key, "given to fire")
	KeyBindings.bind("pogo", KEY_ESCAPE)
	assert_true(not KeyBindings.keys_of("pogo").has(KEY_ESCAPE), "Escape is for the menu")
	KeyBindings.reset()
	assert_equal(KeyBindings.keys_of("move_left"), arrows, "reset")


func test_controller_buttons_stay_when_keys_change() -> void:
	KeyBindings.reset()
	var events := InputMap.action_get_events("jump").size()
	var keys := KeyBindings.keys_of("jump").size()
	KeyBindings.set_keys("jump", [KEY_K] as Array[int])
	assert_equal(InputMap.action_get_events("jump").size(), events - keys + 1, "buttons kept")
	KeyBindings.reset()


func test_settings_survive_a_round_trip() -> void:
	KeyBindings.reset()
	var path := _path("settings.cfg")
	var settings := UserSettings.load_from(path)
	assert_true(settings.sound_enabled, "sound on by default")
	assert_equal(
		settings.display.aspect, DisplaySettings.Aspect.WIDESCREEN, "widescreen by default"
	)
	settings.sound_enabled = false
	settings.display.aspect = DisplaySettings.Aspect.WIDESCREEN
	settings.display.correct_pixel_aspect = false
	settings.fullscreen = false
	settings.display.graphics = DisplaySettings.Graphics.XBRZ
	settings.display.smooth_motion = true
	KeyBindings.bind("pogo", KEY_P)
	assert_true(settings.save(), "saved")
	KeyBindings.reset()
	var loaded := UserSettings.load_from(path)
	assert_true(not loaded.sound_enabled, "sound off")
	assert_equal(loaded.display.aspect, DisplaySettings.Aspect.WIDESCREEN, "widescreen")
	assert_true(not loaded.display.correct_pixel_aspect, "square pixels")
	assert_true(not loaded.fullscreen, "in a window")
	assert_equal(loaded.display.graphics, DisplaySettings.Graphics.XBRZ, "graphics")
	assert_true(loaded.display.smooth_motion, "smooth motion")
	assert_equal(KeyBindings.keys_of("pogo")[0], KEY_P, "keys")
	KeyBindings.reset()


func _path(file_name: String) -> String:
	return TEST_DIRECTORY.path_join(file_name)


func _remove_test_directory() -> void:
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	for file_name in directory.get_files():
		directory.remove(file_name)
	DirAccess.remove_absolute(path)
