extends "res://tests/test_case.gd"
## Tests for the keys of two players after milestone D12 (decided by the
## user, 19-10-2026): each player gets up and down (player 1 W / S, player
## 2 the arrows), appended after his other keys, so Keen 1-3's pages keep
## their rows. The defaults of the two players never share a key, the new
## keys can be changed and stored like the others, settings from before D12
## keep the new defaults, and [method KeenInput.for_player] reads them.
## The settings go to a folder of their own in the user folder, removed
## afterwards.

const TEST_DIRECTORY := "user://test_keen4_coop_keys"
const OLD_PLAYER_ACTIONS := 5
const NEW_ACTIONS: Array[String] = ["p1_up", "p1_down", "p2_up", "p2_down"]

var _window: GameWindow
var _menus: MenuController


func run_all() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	KeyBindings.reset()
	super.run_all()
	if _menus != null:
		_menus.free()
		_window.free()
	KeyBindings.reset()
	for file_name in ["settings.cfg", "old.cfg"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(file_name)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_up_and_down_come_after_the_old_keys() -> void:
	var player_1: Array = KeyBindings.PLAYER_ACTIONS[0].keys()
	var player_2: Array = KeyBindings.PLAYER_ACTIONS[1].keys()
	assert_equal(
		player_1, ["p1_left", "p1_right", "p1_jump", "p1_pogo", "p1_fire", "p1_up", "p1_down"], "1"
	)
	assert_equal(
		player_2, ["p2_left", "p2_right", "p2_jump", "p2_pogo", "p2_fire", "p2_up", "p2_down"], "2"
	)
	assert_equal(KeyBindings.action_name("p1_up"), "Up", "named Up")
	assert_equal(KeyBindings.action_name("p2_down"), "Down", "named Down")
	assert_equal(KeyBindings.ACTIONS.size(), 8, "playing alone keeps its eight")
	for action in NEW_ACTIONS:
		assert_true(InputMap.has_action(action), "%s is an input action" % action)
		assert_true(action in KeyBindings.all_actions(), "%s can be changed" % action)


func test_default_up_and_down() -> void:
	KeyBindings.reset()
	var expected := {
		"p1_up": [KEY_W],
		"p1_down": [KEY_S],
		"p2_up": [KEY_UP],
		"p2_down": [KEY_DOWN],
	}
	for action: String in expected:
		assert_equal(Array(KeyBindings.keys_of(action)), expected[action], action)


func test_the_two_players_never_share_a_key() -> void:
	KeyBindings.reset()
	var owner := {}
	var together := KeyBindings.actions_used_with("p1_left")
	for action in together:
		for code in KeyBindings.keys_of(action):
			assert_true(
				not owner.has(code),
				"%s of %s is also %s's" % [KeyBindings.key_name(code), action, owner.get(code, "")]
			)
			owner[code] = action
	for action in NEW_ACTIONS:
		assert_true(action in together, "%s is used with the others" % action)
	assert_true(not KeyBindings.keys_of("p1_up").has(KEY_CTRL), "no Ctrl (Mac desktops)")


func test_the_old_two_player_keys_are_unchanged() -> void:
	KeyBindings.reset()
	var left_shift := KeyBindings.make_code(KEY_SHIFT, KEY_LOCATION_LEFT)
	var right_shift := KeyBindings.make_code(KEY_SHIFT, KEY_LOCATION_RIGHT)
	var expected := {
		"p1_left": [KEY_A],
		"p1_right": [KEY_D],
		"p1_jump": [left_shift],
		"p1_pogo": [KEY_QUOTELEFT],
		"p1_fire": [KEY_Z],
		"p2_left": [KEY_LEFT],
		"p2_right": [KEY_RIGHT],
		"p2_jump": [KEY_PERIOD],
		"p2_pogo": [KEY_SLASH],
		"p2_fire": [right_shift],
		"move_up": Array(KeyBindings.keys_of("move_up")),
	}
	for action: String in expected:
		assert_equal(Array(KeyBindings.keys_of(action)), expected[action], action)
	assert_equal(Array(KeyBindings.keys_of("jump")), [KEY_CTRL, KEY_Z], "one player keeps his")


func test_for_player_reads_up_and_down() -> void:
	KeyBindings.reset()
	var cases := [
		[KEY_W, 0, -1],
		[KEY_S, 0, 1],
		[KEY_UP, 1, -1],
		[KEY_DOWN, 1, 1],
	]
	for case: Array in cases:
		Input.action_release("p1_up")
		_hold(case[0], true)
		var held := KeenInput.for_player(case[1])
		var other := KeenInput.for_player(1 - case[1])
		_hold(case[0], false)
		assert_equal(held.vertical, case[2], "%s steers player %d" % [case[0], case[1] + 1])
		assert_equal(other.vertical, 0, "%s leaves the other alone" % case[0])
		assert_equal(held.direction, 0, "and walks nobody sideways")
	assert_equal(KeenInput.for_player(0).vertical, 0, "nothing held: no up or down")


func test_map_combines_up_and_down_of_both() -> void:
	var up := KeenInput.new()
	up.vertical = -1
	var down := KeenInput.new()
	down.vertical = 1
	assert_equal(KeenInput.combine([KeenInput.new(), up, KeenInput.new()]).vertical, -1, "up")
	assert_equal(KeenInput.combine([KeenInput.new(), KeenInput.new(), down]).vertical, 1, "down")
	assert_equal(KeenInput.combine([KeenInput.new(), up, down]).vertical, 0, "both: none")


func test_changing_up_takes_the_key_from_the_partner_only() -> void:
	KeyBindings.reset()
	KeyBindings.bind("p1_up", KEY_LEFT)
	assert_equal(KeyBindings.keys_of("p1_up")[0], KEY_LEFT, "player 1 goes up with Left")
	assert_true(KeyBindings.keys_of("p2_left").is_empty(), "taken from player 2")
	assert_true(KeyBindings.keys_of("move_left").has(KEY_LEFT), "one player keeps it")
	KeyBindings.bind("p2_jump", KEY_DOWN)
	assert_true(KeyBindings.keys_of("p2_down").is_empty(), "down given to jump")
	KeyBindings.reset()


func test_new_keys_are_stored_and_read_back() -> void:
	KeyBindings.reset()
	var path := _path("settings.cfg")
	var settings := UserSettings.load_from(path)
	KeyBindings.bind("p2_up", KEY_I)
	KeyBindings.bind("p1_down", KEY_X)
	assert_true(settings.save(), "saved")
	KeyBindings.reset()
	UserSettings.load_from(path)
	assert_equal(KeyBindings.keys_of("p2_up")[0], KEY_I, "player 2's up")
	assert_equal(KeyBindings.keys_of("p1_down")[0], KEY_X, "player 1's down")
	KeyBindings.reset()


func test_settings_from_before_d12_keep_the_new_defaults() -> void:
	KeyBindings.reset()
	var data := KeyBindings.to_dict()
	for action in NEW_ACTIONS:
		data.erase(action)
	data["p2_jump"] = [KEY_K]
	KeyBindings.apply_dict(data)
	assert_equal(KeyBindings.keys_of("p2_jump")[0], KEY_K, "the old keys are read")
	assert_equal(Array(KeyBindings.keys_of("p1_up")), [KEY_W], "up stays W")
	assert_equal(Array(KeyBindings.keys_of("p2_down")), [KEY_DOWN], "down stays the arrow")
	KeyBindings.reset()


func test_controls_pages_show_up_and_down_after_the_old_rows() -> void:
	KeyBindings.reset()
	_create_menus()
	_menus.open_main(false, false)
	_choose("Controls")
	_choose("Two players: player 1")
	var labels := _labels()
	assert_true(labels.size() >= OLD_PLAYER_ACTIONS + 2, "seven keys or more")
	assert_true(labels[2].contains("LEFT SHIFT"), "jump where it was")
	assert_true(labels[OLD_PLAYER_ACTIONS].begins_with("Up"), "Up after Fire: %s" % labels)
	assert_true(labels[OLD_PLAYER_ACTIONS].contains("W"), "with W")
	assert_true(labels[OLD_PLAYER_ACTIONS + 1].contains("S"), "Down with S")
	_press(KEY_ESCAPE)
	_choose("Two players: player 2")
	labels = _labels()
	assert_true(labels[2].contains("."), "jumps with the period, as before")
	assert_true(labels[OLD_PLAYER_ACTIONS].contains("UP"), "Up with the arrow: %s" % labels)
	assert_true(labels[OLD_PLAYER_ACTIONS + 1].contains("DOWN"), "Down with the arrow")
	_choose(labels[OLD_PLAYER_ACTIONS])
	_press(KEY_O)
	assert_equal(KeyBindings.keys_of("p2_up")[0], KEY_O, "changed in the menu")
	KeyBindings.reset()


func _hold(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _create_menus() -> void:
	if _menus != null:
		_menus.free()
		_window.free()
	_window = GameWindow.new()
	_menus = MenuController.new()
	_menus.window = _window
	_menus.saves = SaveGames.in_directory(_path("saves"))
	_menus.settings = UserSettings.new()
	_menus.settings.path = _path("settings.cfg")


func _labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for item in _menus._top().items:
		labels.append(item.label)
	return labels


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


func _path(file_name: String) -> String:
	return TEST_DIRECTORY.path_join(file_name)
