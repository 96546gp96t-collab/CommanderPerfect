extends "res://tests/test_case.gd"
## Tests for the online part of the menus: hosting and joining by IP or
## through Steam, typing a name, an address and a password, and the main
## menu of the host and of the player who joined. The settings go to a
## folder of their own in the user folder, which is removed afterwards.

const TEST_DIRECTORY := "user://test_online_menus"

var _window: GameWindow
var _menus: MenuController
var _chosen: Array = []


func run_all() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	super.run_all()
	_free_nodes()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_settings_path()))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_main_menu_offers_online_play() -> void:
	_create_menus()
	_menus.open_main(false, false)
	assert_true(_labels().has("Online Game"), "at the title")
	_menus.online.role = OnlineMenuInfo.Role.HOST
	_menus.open_main(true, true)
	assert_true(not _labels().has("Add Player 2"), "no second player on the keyboard online")
	assert_true(_labels().has("Save Game"), "the host saves")


func test_joined_player_has_a_menu_of_his_own() -> void:
	_create_menus()
	_menus.online.role = OnlineMenuInfo.Role.CLIENT
	_menus.online.partner_name = "Billy"
	_menus.open_main(true, false)
	assert_equal(_menus._top().header[0], "  BILLY'S GAME", "whose game")
	for label in ["New Game", "Continue Game", "Save Game", "High Scores", "Quit to Title"]:
		assert_true(not _labels().has(label), "the host decides: " + label)
	_choose("Leave Game")
	assert_equal(_chosen, [[MenuController.CHOICE_LEAVE_ONLINE, 0]], "leaves")


func test_hosting_by_ip_asks_a_name_first() -> void:
	_create_menus()
	_menus.open_main(false, false)
	_choose("Online Game")
	_choose("Host via IP")
	assert_equal(_menus._top().kind, MenuController.TEXT, "asks for a name")
	_type_text("Billy")
	_press(KEY_ENTER)
	assert_equal(_menus.settings.online_name, "Billy", "remembered")
	assert_equal(_menus._top().kind, MenuController.HOST_SETUP, "then on to hosting")
	assert_true(_menus.host_locked, "a password by default over IP")
	assert_equal(_menus.host_password.length(), OnlineMenuInfo.PASSWORD_LENGTH, "made up")
	_choose("Password      ON")
	assert_true(not _menus.host_locked, "switched off")
	_choose("Start Hosting")
	assert_equal(_chosen, [[MenuController.CHOICE_HOST, MenuController.HOST_BY_IP]], "hosts")


func test_hosting_through_steam_has_no_password_by_default() -> void:
	_create_menus()
	_menus.open_main(false, false)
	_choose("Online Game")
	_choose("Host via Steam")
	assert_true(not _menus.host_locked, "friends only, no password")
	_choose("Start Hosting")
	assert_equal(
		_chosen, [[MenuController.CHOICE_HOST, MenuController.HOST_THROUGH_STEAM]], "hosts"
	)


func test_joining_by_ip_asks_address_and_password() -> void:
	_create_menus()
	_menus.settings.online_name = "Billy"
	_menus.open_main(false, false)
	_choose("Online Game")
	_choose("Join via IP")
	_type_text("10.0.0.7 x!")
	_press(KEY_ENTER)
	assert_equal(_menus.join_address, "10.0.0.7x", "only what an address can hold")
	assert_equal(_menus.settings.online_address, "10.0.0.7x", "remembered for next time")
	_type_text("pw")
	_press(KEY_ENTER)
	assert_equal(_menus.join_password, "pw", "password")
	assert_equal(_chosen, [[MenuController.CHOICE_JOIN_IP, 0]], "joins")


func test_steam_games_list() -> void:
	_create_menus()
	var asked := []
	_menus.steam_games_wanted.connect(func() -> void: asked.append(true))
	_menus.open_main(false, false)
	_choose("Online Game")
	_choose("Join via Steam")
	assert_equal(asked.size(), 1, "asks Steam")
	assert_true(_labels().has("(none found)"), "nothing yet")
	var locked: Array[bool] = [false, true]
	_menus.show_steam_games(["Billy (1/2)", "Yorp (1/2) *"], locked)
	assert_equal(_labels()[1], "Yorp (1/2) *", "the list fills in")
	_choose("Yorp (1/2) *")
	assert_equal(_menus._top().kind, MenuController.TEXT, "asks the password")
	_type_text("x")
	_press(KEY_ENTER)
	assert_equal(_chosen, [[MenuController.CHOICE_JOIN_STEAM, 1]], "joins the second")
	assert_equal(_menus.join_password, "x", "with the password")


func test_host_sees_how_to_join() -> void:
	_create_menus()
	_menus.online.role = OnlineMenuInfo.Role.HOST
	_menus.online.host_lines = ["Via IP, UDP port 24800"]
	_menus.open_main(true, true)
	_choose("Online Game")
	assert_true(_menus._top().header.has("Via IP, UDP port 24800"), "the address")
	assert_true(_menus._top().header.has("Nobody joined yet"), "who plays")
	_choose("Stop Hosting")
	assert_equal(_chosen, [[MenuController.CHOICE_LEAVE_ONLINE, 0]], "stops")


func test_host_setup_shows_the_addresses() -> void:
	_create_menus()
	_menus.settings.online_name = "Billy"
	var asked := []
	_menus.addresses_wanted.connect(func() -> void: asked.append(true))
	_menus.online.local_addresses = ["192.168.1.20"]
	_menus.open_main(false, false)
	_choose("Online Game")
	_choose("Host via IP")
	assert_equal(asked.size(), 1, "asks for the addresses")
	var header := _menus._top().header
	assert_true(header.has("Network:  192.168.1.20"), "the own network")
	assert_true(header.has("Internet: looking up..."), "the internet one is on its way")
	_menus.online.public_address = "203.0.113.5"
	_menus.online.public_lookup_done = true
	_menus.refresh_online()
	assert_true(_menus._top().header.has("Internet: 203.0.113.5"), "filled in when found")


func test_hosting_window_follows_the_addresses() -> void:
	_create_menus()
	_menus.online.host_lines = ["Internet: looking up..."]
	_menus.show_hosting()
	assert_equal(_menus._top().kind, MenuController.HOSTING, "the hosting window")
	_menus.online.host_lines = ["Internet: 203.0.113.5"]
	_menus.refresh_online()
	assert_true(_menus._top().header.has("Internet: 203.0.113.5"), "updated")
	_press(KEY_SPACE)
	assert_true(not _menus.is_open(), "any key closes it")


func test_address_lines() -> void:
	var info := OnlineMenuInfo.new()
	assert_equal(
		info.address_lines(),
		PackedStringArray(["Network:  not found", "Internet: looking up..."]),
		"nothing known yet"
	)
	info.local_addresses = ["10.0.0.2", "10.0.0.3", "192.168.1.4"]
	info.public_lookup_done = true
	var lines := info.address_lines()
	assert_equal(lines.size(), 3, "at most two on the network")
	assert_equal(lines[-1], "Internet: not found", "the look-up failed")


func test_host_types_his_own_password() -> void:
	_create_menus()
	_menus.settings.online_name = "Billy"
	_menus.open_main(false, false)
	_choose("Online Game")
	_choose("Host via IP")
	_choose("Type Password")
	assert_equal(_menus._top().kind, MenuController.TEXT, "asks for it")
	_press(KEY_ENTER)
	assert_equal(_menus._top().kind, MenuController.TEXT, "not empty")
	_type_text("Yorp Pogo")
	_press(KEY_ENTER)
	assert_equal(_menus._top().kind, MenuController.HOST_SETUP, "back to the setup")
	assert_equal(_menus.host_password, "Yorp Pogo", "the typed password")
	assert_true(_menus._top().header.has("Password: Yorp Pogo"), "shown")
	var stored := UserSettings.load_from(_settings_path())
	assert_equal(stored.host_password, "Yorp Pogo", "remembered")
	_choose("Password      ON")
	_choose("Start Hosting")
	_menus.open_main(false, false)
	_choose("Online Game")
	_choose("Host via IP")
	assert_equal(_menus.host_password, "Yorp Pogo", "used again next time")
	_choose("Random Password")
	assert_true(_menus.host_password != "Yorp Pogo", "a random one")
	assert_equal(_menus.host_password.length(), OnlineMenuInfo.PASSWORD_LENGTH, "made up")
	assert_equal(_menus.settings.host_password, "", "the typed one is forgotten")
	KeyBindings.reset()


func _create_menus() -> void:
	_free_nodes()
	_window = GameWindow.new()
	_menus = MenuController.new()
	_menus.window = _window
	_menus.settings = UserSettings.new()
	_menus.settings.path = _settings_path()
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


func _type_text(text: String) -> void:
	for character in text:
		var event := InputEventKey.new()
		event.unicode = character.unicode_at(0)
		event.pressed = true
		_menus.handle_input(event)


func _settings_path() -> String:
	return TEST_DIRECTORY.path_join("settings.cfg")
