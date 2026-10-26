extends "res://tests/test_case.gd"
## Tests for the controllers of two players ([PlayerControllers]): playing
## alone every controller still steers; when two play, each player's
## actions only take the buttons of his own controller; automatic and
## chosen controllers, two controllers of the same kind, a chosen one that
## is gone, storing the choice, and choosing in the menus of Keen 1-3 and
## of the Galaxy games. Connected controllers are pretended; the settings
## go to a folder of their own in the user folder, removed afterwards.

const TEST_DIRECTORY := "user://test_player_controllers"
const XBOX_GUID := "030000005e040000e002000000000000"
const PS4_GUID := "030000004c050000cc09000000000000"
## Godot's numbers for the pretended controllers: not 0 and 1, so that a
## mix-up between a player and a device shows.
const FIRST := 3
const SECOND := 5
const THIRD := 6

var _window: GameWindow
var _menus: MenuController


func run_all() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	KeyBindings.reset()
	super.run_all()
	_free_menus()
	PlayerControllers.pretend_connected(null)
	PlayerControllers.reset()
	KeyBindings.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_path("settings.cfg")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_without_controllers_the_players_have_none() -> void:
	_connect([])
	assert_equal(PlayerControllers.devices(), [-1, -1] as Array[int], "nobody has one")
	for action in ["p1_jump", "p1_left", "p2_fire", "p2_down"]:
		assert_true(_controller_events(action).is_empty(), "%s has no buttons" % action)


func test_playing_alone_every_controller_still_steers() -> void:
	_connect([_xbox(FIRST), _xbox(SECOND)])
	for device in [FIRST, SECOND]:
		assert_true(_is_action(_button(JOY_BUTTON_A, device), "jump"), "A jumps (%d)" % device)
		assert_true(_is_action(_stick(-1.0, device), "move_left"), "stick left (%d)" % device)
		assert_true(_is_action(_button(JOY_BUTTON_START, device), "status"), "Start: status")
		assert_true(_is_action(_button(JOY_BUTTON_BACK, device), "menu"), "Back: menu")


func test_automatic_gives_the_first_two_in_order() -> void:
	_connect([_xbox(FIRST), _ps4(SECOND), _xbox(THIRD)])
	assert_equal(PlayerControllers.devices(), [FIRST, SECOND] as Array[int], "first two")
	assert_true(_is_action(_button(JOY_BUTTON_A, FIRST), "p1_jump"), "player 1 jumps")
	assert_true(not _is_action(_button(JOY_BUTTON_A, FIRST), "p2_jump"), "not player 2")
	assert_true(_is_action(_button(JOY_BUTTON_A, SECOND), "p2_jump"), "player 2 jumps")
	assert_true(not _is_action(_button(JOY_BUTTON_A, SECOND), "p1_jump"), "not player 1")
	assert_true(not _is_action(_button(JOY_BUTTON_A, THIRD), "p1_jump"), "the third: nobody's")
	assert_true(not _is_action(_button(JOY_BUTTON_A, THIRD), "p2_jump"), "the third: nobody's")


func test_keen_input_reads_each_players_own_controller() -> void:
	_connect([_xbox(FIRST), _ps4(SECOND)])
	_send(_button(JOY_BUTTON_A, SECOND))
	_send(_stick(-1.0, FIRST))
	assert_true(KeenInput.for_player(1).jump, "player 2 jumps")
	assert_true(not KeenInput.for_player(0).jump, "player 1 does not")
	assert_equal(KeenInput.for_player(0).direction, -1, "player 1 walks left")
	assert_equal(KeenInput.for_player(1).direction, 0, "player 2 stands")
	var alone := KeenInput.from_actions()
	assert_true(alone.jump and alone.direction == -1, "playing alone: both count")
	var released := _button(JOY_BUTTON_A, SECOND)
	released.pressed = false
	_send(released)
	_send(_stick(0.0, FIRST))
	assert_true(not KeenInput.for_player(1).jump, "let go")


func test_each_player_gets_every_button_of_playing_alone() -> void:
	_connect([_xbox(FIRST), _ps4(SECOND)])
	var checks := {
		"left": _stick(-1.0, SECOND),
		"right": _stick(1.0, SECOND),
		"up": _button(JOY_BUTTON_DPAD_UP, SECOND),
		"down": _button(JOY_BUTTON_DPAD_DOWN, SECOND),
		"jump": _button(JOY_BUTTON_A, SECOND),
		"pogo": _button(JOY_BUTTON_B, SECOND),
		"fire": _button(JOY_BUTTON_X, SECOND),
	}
	for part: String in checks:
		assert_true(_is_action(checks[part], "p2_" + part), "player 2's %s" % part)
	assert_equal(
		_controller_events("p2_jump").size(),
		_controller_events("jump").size(),
		"as many as playing alone"
	)


func test_the_keys_stay_as_they_were() -> void:
	KeyBindings.reset()
	var before := KeyBindings.to_dict()
	_connect([_xbox(FIRST), _ps4(SECOND)])
	assert_equal(KeyBindings.to_dict(), before, "the keys are unchanged")
	_connect([])
	assert_equal(KeyBindings.to_dict(), before, "and when the controllers go")


func test_changing_a_key_keeps_the_controller() -> void:
	_connect([_xbox(FIRST), _ps4(SECOND)])
	KeyBindings.bind("p1_jump", KeyBindings.make_code(KEY_K))
	assert_true(_is_action(_button(JOY_BUTTON_A, FIRST), "p1_jump"), "after a new key")
	KeyBindings.reset()
	assert_true(_is_action(_button(JOY_BUTTON_A, FIRST), "p1_jump"), "after resetting the keys")
	assert_true(_is_action(_button(JOY_BUTTON_A, SECOND), "p2_jump"), "player 2 too")


func test_choosing_a_controller() -> void:
	_connect([_xbox(FIRST), _ps4(SECOND)])
	PlayerControllers.choose(1, FIRST)
	assert_true(PlayerControllers.is_chosen(1), "player 2 chose")
	assert_equal(PlayerControllers.devices(), [SECOND, FIRST] as Array[int], "player 1 the other")
	assert_true(_is_action(_button(JOY_BUTTON_A, FIRST), "p2_jump"), "the first is player 2's")
	assert_true(_is_action(_button(JOY_BUTTON_A, SECOND), "p1_jump"), "the second player 1's")


func test_a_controller_belongs_to_one_player() -> void:
	_connect([_xbox(FIRST), _ps4(SECOND)])
	PlayerControllers.choose(1, FIRST)
	PlayerControllers.choose(0, FIRST)
	assert_true(PlayerControllers.is_chosen(0), "player 1 has it now")
	assert_true(not PlayerControllers.is_chosen(1), "player 2 is automatic again")
	assert_equal(PlayerControllers.devices(), [FIRST, SECOND] as Array[int], "both have one")


func test_only_one_controller_for_player_2() -> void:
	_connect([_xbox(FIRST)])
	PlayerControllers.choose(1, FIRST)
	assert_equal(PlayerControllers.devices(), [-1, FIRST] as Array[int], "player 1 on the keys")
	assert_true(_controller_events("p1_jump").is_empty(), "player 1 has no buttons")


func test_two_controllers_of_the_same_kind_stay_apart() -> void:
	_connect([_xbox(FIRST), _xbox(SECOND)])
	PlayerControllers.choose(0, SECOND)
	assert_equal(PlayerControllers.devices(), [SECOND, FIRST] as Array[int], "the second one")
	# Godot numbers them anew after a reconnect; the order stays.
	PlayerControllers.pretend_connected(
		[_xbox(FIRST), _xbox(THIRD)] as Array[PlayerControllers.Pad]
	)
	assert_equal(PlayerControllers.devices(), [THIRD, FIRST] as Array[int], "still the second")


func test_a_chosen_controller_that_is_gone() -> void:
	_connect([_xbox(FIRST), _ps4(SECOND)])
	PlayerControllers.choose(0, SECOND)
	PlayerControllers.pretend_connected([_xbox(FIRST)] as Array[PlayerControllers.Pad])
	assert_equal(PlayerControllers.devices(), [-1, FIRST] as Array[int], "player 1 waits for it")
	assert_equal(PlayerControllers.describe(0), "PS4 (OFF)", "the menu says it is off")
	assert_equal(PlayerControllers.describe(1), "AUTO 1 XBOX", "player 2 automatic")
	PlayerControllers.pretend_connected([_xbox(FIRST), _ps4(THIRD)] as Array[PlayerControllers.Pad])
	assert_equal(PlayerControllers.devices(), [THIRD, FIRST] as Array[int], "it is back")
	assert_equal(PlayerControllers.describe(0), "2 PS4", "the menu shows it")


func test_short_names() -> void:
	assert_equal(PlayerControllers.short_name("Xbox Wireless Controller"), "XBOX", "Xbox")
	assert_equal(PlayerControllers.short_name("PS4 Controller"), "PS4", "PS4")
	assert_equal(PlayerControllers.short_name("Controller"), "CONTROLLER", "nothing else")
	_connect([])
	assert_equal(PlayerControllers.describe(0), "AUTO -", "nothing connected")
	assert_equal(PlayerControllers.describe_short(0, 9), "AUTO -", "short")
	_connect([_xbox(FIRST), _ps4(SECOND)])
	PlayerControllers.choose(1, SECOND)
	assert_equal(PlayerControllers.describe_short(0, 9), "AUTO 1", "automatic, short")
	assert_equal(PlayerControllers.describe_short(1, 9), "2 PS4", "chosen, short")


func test_the_choice_is_stored() -> void:
	_connect([_xbox(FIRST), _ps4(SECOND)])
	PlayerControllers.choose(0, SECOND)
	var settings := UserSettings.new()
	settings.path = _path("settings.cfg")
	assert_true(settings.save(), "saved")
	PlayerControllers.reset()
	assert_true(not PlayerControllers.is_chosen(0), "forgotten")
	UserSettings.load_from(_path("settings.cfg"))
	assert_true(PlayerControllers.is_chosen(0), "loaded again")
	assert_equal(PlayerControllers.devices(), [SECOND, FIRST] as Array[int], "the same one")
	PlayerControllers.apply_array("nonsense")
	assert_equal(PlayerControllers.to_array(), [{}, {}], "unreadable: automatic")


func test_choosing_in_the_controls_menu() -> void:
	_connect([_xbox(FIRST), _ps4(SECOND)])
	_create_menus(MenuController.new())
	_menus.open_main(false, false)
	_choose("Controls")
	_choose("Controllers")
	assert_equal(_menus._top().kind, MenuController.CONTROLLERS, "the controllers menu")
	assert_equal(_labels()[0], "Player 1  AUTO 1 XBOX", "player 1 automatic")
	assert_equal(_labels()[1], "Player 2  AUTO 2 PS4", "player 2 automatic")
	_choose(_labels()[1])
	assert_equal(_menus._top().kind, MenuController.PRESS_BUTTON, "waits for a button")
	_press(KEY_K)
	assert_equal(_menus._top().kind, MenuController.PRESS_BUTTON, "a key does not count")
	_menus.handle_input(_button(JOY_BUTTON_B, FIRST))
	assert_equal(_menus._top().kind, MenuController.CONTROLLERS, "back in the menu")
	assert_equal(_labels()[1], "Player 2  1 XBOX", "player 2 has the Xbox")
	assert_equal(_labels()[0], "Player 1  AUTO 2 PS4", "player 1 the other")
	var stored := ConfigFile.new()
	assert_equal(stored.load(_menus.settings.path), OK, "settings saved")
	_choose(_labels()[0])
	_press(KEY_ESCAPE)
	assert_equal(_menus._top().kind, MenuController.CONTROLLERS, "Escape leaves it")
	assert_true(not PlayerControllers.is_chosen(0), "nothing changed")
	_choose("Both automatic")
	assert_equal(_labels()[1], "Player 2  AUTO 2 PS4", "automatic again")


func test_the_menu_follows_a_controller_that_connects() -> void:
	_connect([])
	_create_menus(MenuController.new())
	_menus.open_main(false, false)
	_choose("Controls")
	_choose("Controllers")
	assert_equal(_labels()[0], "Player 1  AUTO -", "none yet")
	PlayerControllers.pretend_connected([_xbox(FIRST)] as Array[PlayerControllers.Pad])
	_menus._on_joy_connection_changed(FIRST, true)
	assert_equal(_labels()[0], "Player 1  AUTO 1 XBOX", "shown when it connects")


func test_choosing_on_the_galaxy_two_players_card() -> void:
	_connect([_xbox(FIRST), _ps4(SECOND)])
	var coop := GalaxyCoopMenuController.new()
	_create_menus(coop)
	coop.open_main(false)
	_pick(GalaxyMenuController.CONFIGURE)
	_pick(GalaxyCoopMenuController.TWO_PLAYERS)
	var pad := _item(MenuController.PLAYER_PAD, 1)
	assert_true(pad != null, "a row for player 2's controller")
	assert_true(pad.label.ends_with("\tAUTO 2"), "automatic: " + pad.label)
	_menus._top().cursor = _menus._top().items.find(pad)
	_press(KEY_ENTER)
	assert_equal(_menus._top().kind, MenuController.PRESS_BUTTON, "waits for a button")
	assert_true(not coop.allows_help(), "no help while waiting")
	_menus.handle_input(_button(JOY_BUTTON_A, FIRST))
	assert_equal(_menus._top().kind, GalaxyCoopMenuController.TWO_PLAYERS, "back on the card")
	assert_true(_item(MenuController.PLAYER_PAD, 1).label.ends_with("\t1 XBOX"), "chosen")
	assert_true(PlayerControllers.is_chosen(1), "player 2 chose")
	_pick(MenuController.AUTOMATIC_PADS)
	assert_true(not PlayerControllers.is_chosen(1), "automatic again")


func _connect(pads: Array[PlayerControllers.Pad]) -> void:
	PlayerControllers.reset()
	PlayerControllers.pretend_connected(pads)


func _xbox(device: int) -> PlayerControllers.Pad:
	return PlayerControllers.Pad.create(device, "Xbox Wireless Controller", XBOX_GUID)


func _ps4(device: int) -> PlayerControllers.Pad:
	return PlayerControllers.Pad.create(device, "PS4 Controller", PS4_GUID)


func _button(button: JoyButton, device: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.device = device
	event.pressed = true
	return event


func _stick(value: float, device: int) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	event.device = device
	return event


static func _is_action(event: InputEvent, action: String) -> bool:
	return InputMap.event_is_action(event, action, true)


static func _controller_events(action: String) -> Array[InputEvent]:
	var events: Array[InputEvent] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			events.append(event)
	return events


func _create_menus(menus: MenuController) -> void:
	_free_menus()
	_window = GameWindow.new()
	_menus = menus
	_menus.window = _window
	_menus.settings = UserSettings.new()
	_menus.settings.path = _path("settings.cfg")


func _free_menus() -> void:
	if _menus != null:
		_menus.free()
		_window.free()
		_menus = null


func _labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for item in _menus._top().items:
		labels.append(item.label)
	return labels


func _item(id: StringName, value := 0) -> Menu.Item:
	for item in _menus._top().items:
		if item.id == id and item.value == value:
			return item
	return null


## Puts the cursor on the choice [param id] and picks it.
func _pick(id: StringName) -> void:
	_menus._top().cursor = _menus._top().items.find(_item(id))
	_press(KEY_ENTER)


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


func _path(file_name: String) -> String:
	return TEST_DIRECTORY.path_join(file_name)


static func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()
