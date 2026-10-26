extends "res://tests/test_case.gd"
## Tests for changing the controller buttons ([ButtonBindings]): the
## defaults are the buttons of before, playing alone and each of two
## players have a set of their own, a button belongs to one action within
## its set, the triggers can be used, the game's own buttons cannot, the
## sticks keep walking, storing and resetting, and changing them in the
## menus of Keen 1-3 and of the Galaxy games. Connected controllers are
## pretended; the settings go to a folder of their own in the user folder,
## removed afterwards.

const TEST_DIRECTORY := "user://test_button_bindings"
const GUID := "030000005e040000e002000000000000"
const FIRST := 3
const SECOND := 5
const RIGHT_TRIGGER := ButtonBindings.TRIGGER_BASE + JOY_AXIS_TRIGGER_RIGHT

var _window: GameWindow
var _menus: MenuController


func run_all() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	_reset()
	super.run_all()
	_free_menus()
	_reset()
	PlayerControllers.pretend_connected(null)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_path("settings.cfg")))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_the_defaults_are_the_buttons_of_before() -> void:
	_reset()
	var expected := {
		"jump": "A",
		"pogo": "B",
		"fire": "X",
		"status": "START",
		"move_left": "D-LEFT",
		"move_up": "D-UP",
		"p1_jump": "A",
		"p2_pogo": "B",
		"p2_fire": "X",
		"p1_down": "D-DOWN",
	}
	for action: String in expected:
		assert_equal(ButtonBindings.describe(action), expected[action], action)


func test_a_button_belongs_to_one_action_of_its_set() -> void:
	_reset()
	ButtonBindings.bind("jump", JOY_BUTTON_B)
	assert_equal(ButtonBindings.buttons_of("jump"), [JOY_BUTTON_B] as Array[int], "jumps with B")
	assert_true(ButtonBindings.buttons_of("pogo").is_empty(), "taken from pogo")
	assert_equal(ButtonBindings.describe("pogo"), "-", "the menu shows none")
	assert_equal(ButtonBindings.describe("p1_jump"), "A", "player 1 keeps his own")
	assert_equal(ButtonBindings.describe("p1_pogo"), "B", "and his pogo")


func test_each_player_has_his_own_buttons() -> void:
	_reset()
	_connect()
	ButtonBindings.bind("p1_jump", JOY_BUTTON_B)
	assert_true(_is_action(_button(JOY_BUTTON_B, FIRST), "p1_jump"), "player 1 jumps with B")
	assert_true(not _is_action(_button(JOY_BUTTON_B, FIRST), "p1_pogo"), "no pogo with B")
	assert_true(not _is_action(_button(JOY_BUTTON_A, FIRST), "p1_jump"), "A no longer jumps")
	assert_true(_is_action(_button(JOY_BUTTON_A, SECOND), "p2_jump"), "player 2 still with A")
	assert_true(_is_action(_button(JOY_BUTTON_B, SECOND), "p2_pogo"), "and pogoes with B")
	assert_true(_is_action(_button(JOY_BUTTON_A, FIRST), "jump"), "playing alone: still A")


func test_the_sticks_keep_walking() -> void:
	_reset()
	_connect()
	ButtonBindings.bind("p1_left", JOY_BUTTON_Y)
	assert_true(_is_action(_button(JOY_BUTTON_Y, FIRST), "p1_left"), "Y walks left")
	assert_true(_is_action(_stick(-1.0, FIRST), "p1_left"), "the stick too")
	ButtonBindings.bind("move_left", JOY_BUTTON_Y)
	assert_true(_is_action(_stick(-1.0, SECOND), "move_left"), "playing alone too")


func test_the_triggers() -> void:
	_reset()
	_connect()
	assert_equal(ButtonBindings.code_of(_trigger(0.8, SECOND)), RIGHT_TRIGGER, "pulled")
	assert_equal(ButtonBindings.code_of(_trigger(0.2, SECOND)), -1, "barely touched")
	assert_equal(ButtonBindings.code_of(_stick(1.0, SECOND)), -1, "a stick is no button")
	ButtonBindings.bind("p2_fire", RIGHT_TRIGGER)
	assert_equal(ButtonBindings.describe("p2_fire"), "RT", "named RT")
	assert_true(_is_action(_trigger(1.0, SECOND), "p2_fire"), "player 2 fires with RT")
	assert_true(not _is_action(_trigger(1.0, FIRST), "p2_fire"), "not with player 1's")
	ButtonBindings.bind("fire", RIGHT_TRIGGER)
	assert_true(_is_action(_trigger(1.0, FIRST), "fire"), "playing alone too")
	assert_true(_is_action(_stick(1.0, FIRST), "move_right"), "the stick still walks")


func test_the_games_own_buttons_cannot_be_used() -> void:
	_reset()
	for button in [
		JOY_BUTTON_BACK, JOY_BUTTON_GUIDE, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER
	]:
		assert_true(not ButtonBindings.can_bind(button), ButtonBindings.button_name(button))
		ButtonBindings.bind("jump", button)
		assert_equal(ButtonBindings.describe("jump"), "A", "not given to jump")
	assert_true(ButtonBindings.can_bind(JOY_BUTTON_Y), "Y is free")
	assert_true(ButtonBindings.can_bind(RIGHT_TRIGGER), "and RT")


func test_the_status_button_is_shared() -> void:
	_reset()
	ButtonBindings.bind("p2_jump", JOY_BUTTON_START)
	assert_true(ButtonBindings.buttons_of("status").is_empty(), "taken from status")
	ButtonBindings.bind("status", JOY_BUTTON_Y)
	ButtonBindings.bind("status", JOY_BUTTON_Y)
	assert_equal(ButtonBindings.describe("status"), "Y", "again the same: no change")


func test_the_keys_stay_and_resetting_the_keys_keeps_the_buttons() -> void:
	_reset()
	var keys := KeyBindings.to_dict()
	ButtonBindings.bind("jump", JOY_BUTTON_Y)
	ButtonBindings.bind("p1_fire", RIGHT_TRIGGER)
	assert_equal(KeyBindings.to_dict(), keys, "the keys are unchanged")
	KeyBindings.reset()
	assert_equal(ButtonBindings.describe("jump"), "Y", "the buttons stay")
	assert_equal(ButtonBindings.describe("p1_fire"), "RT", "player 1's too")
	ButtonBindings.reset()
	assert_equal(ButtonBindings.describe("jump"), "A", "reset")
	assert_equal(ButtonBindings.describe("p1_fire"), "X", "reset")
	assert_equal(KeyBindings.to_dict(), keys, "the keys are still unchanged")


func test_the_buttons_are_stored() -> void:
	_reset()
	ButtonBindings.bind("jump", JOY_BUTTON_Y)
	ButtonBindings.bind("p2_pogo", RIGHT_TRIGGER)
	var settings := UserSettings.new()
	settings.path = _path("settings.cfg")
	assert_true(settings.save(), "saved")
	ButtonBindings.reset()
	UserSettings.load_from(_path("settings.cfg"))
	assert_equal(ButtonBindings.describe("jump"), "Y", "jump read back")
	assert_equal(ButtonBindings.describe("p2_pogo"), "RT", "player 2's pogo read back")
	assert_equal(ButtonBindings.describe("p1_pogo"), "B", "player 1's pogo as it was")
	ButtonBindings.apply_dict({"fire": [JOY_BUTTON_BACK, JOY_BUTTON_Y, "x"], "nonsense": [1]})
	assert_equal(ButtonBindings.describe("fire"), "Y", "the game's own buttons are left out")


func test_changing_a_button_in_the_controls_menu() -> void:
	_reset()
	_create_menus(MenuController.new())
	_menus.open_main(false, false)
	_choose("Controls")
	_choose("Two players: player 1")
	assert_equal(_labels()[-1], "Controller buttons", "the last row")
	_choose("Controller buttons")
	assert_equal(_menus._top().kind, MenuController.BUTTON_SET, "the buttons")
	assert_equal(_menus._top().header[0], "  BUTTONS: PLAYER 1 OF TWO", "of player 1")
	assert_equal(_labels()[2], "Jump    A", "jumps with A")
	_choose(_labels()[2])
	assert_equal(_menus._top().kind, MenuController.NEW_BUTTON, "waits for a button")
	_menus.handle_input(_button(JOY_BUTTON_LEFT_SHOULDER, FIRST))
	assert_equal(_menus._top().kind, MenuController.NEW_BUTTON, "LB skips levels")
	_press(KEY_K)
	assert_equal(_menus._top().kind, MenuController.NEW_BUTTON, "a key does not count")
	_menus.handle_input(_trigger(1.0, SECOND))
	assert_equal(_menus._top().kind, MenuController.BUTTON_SET, "back in the buttons")
	assert_equal(_labels()[2], "Jump    RT", "jumps with RT")
	assert_equal(ButtonBindings.describe("jump"), "A", "playing alone unchanged")
	var stored := ConfigFile.new()
	assert_equal(stored.load(_menus.settings.path), OK, "settings saved")
	_choose(_labels()[2])
	_menus.handle_input(_button(JOY_BUTTON_BACK, FIRST))
	assert_equal(_menus._top().kind, MenuController.BUTTON_SET, "Back leaves it")
	_choose(_labels()[2])
	_press(KEY_ESCAPE)
	assert_equal(_labels()[2], "Jump    RT", "Escape too, unchanged")


func test_reset_to_defaults_puts_the_buttons_back() -> void:
	_reset()
	ButtonBindings.bind("p2_jump", JOY_BUTTON_Y)
	KeyBindings.bind("jump", KeyBindings.make_code(KEY_K))
	_create_menus(MenuController.new())
	_menus.open_main(false, false)
	_choose("Controls")
	_choose("Reset to defaults")
	assert_equal(ButtonBindings.describe("p2_jump"), "A", "the buttons")
	assert_equal(KeyBindings.keys_of("jump")[0], KEY_CTRL, "and the keys")


func test_changing_a_button_on_the_galaxy_cards() -> void:
	_reset()
	var galaxy := GalaxyCoopMenuController.new()
	_create_menus(galaxy)
	galaxy.open_main(false)
	_pick(GalaxyMenuController.CONFIGURE)
	_pick(MenuController.KEY_SET)
	var last := _menus._top().items[-1]
	assert_equal(last.label, GalaxyMenuPages.BUTTONS_LABEL, "the keys end with BUTTONS")
	assert_true(_menus._top().items.size() <= GalaxyMenuView.MAX_ROWS, "all rows on the card")
	_pick(MenuController.BUTTON_SET)
	assert_equal(_menus._top().header[0], "BUTTONS", "its title")
	assert_equal(_item(&"fire").label, "FIRE\tX", "fire in its box")
	_pick(&"fire")
	assert_equal(_menus._top().kind, MenuController.NEW_BUTTON, "waits")
	assert_true(not galaxy.allows_help(), "no help while waiting")
	_menus.handle_input(_button(JOY_BUTTON_Y, FIRST))
	assert_equal(_item(&"fire").label, "FIRE\tY", "fires with Y")
	_press(KEY_ESCAPE)
	_press(KEY_ESCAPE)
	_pick(GalaxyCoopMenuController.TWO_PLAYERS)
	_menus._top().cursor = _menus._top().items.find(_item(MenuController.KEY_SET, 2))
	_press(KEY_ENTER)
	assert_true(_menus._top().items.size() <= GalaxyMenuView.MAX_ROWS, "player 2's rows fit")
	_pick(MenuController.BUTTON_SET, 2)
	assert_equal(_menus._top().header[0], "PLAYER 2 BUTTONS", "player 2's")
	assert_equal(_item(&"p2_fire").label, "FIRE\tX", "his own fire")


func _reset() -> void:
	KeyBindings.reset()
	ButtonBindings.reset()
	PlayerControllers.reset()


func _connect() -> void:
	var pads: Array[PlayerControllers.Pad] = [
		PlayerControllers.Pad.create(FIRST, "Xbox Controller", GUID),
		PlayerControllers.Pad.create(SECOND, "Xbox Controller", GUID),
	]
	PlayerControllers.pretend_connected(pads)


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


func _trigger(value: float, device: int) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_TRIGGER_RIGHT
	event.axis_value = value
	event.device = device
	return event


static func _is_action(event: InputEvent, action: String) -> bool:
	return InputMap.event_is_action(event, action, true)


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
func _pick(id: StringName, value := 0) -> void:
	_menus._top().cursor = _menus._top().items.find(_item(id, value))
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
