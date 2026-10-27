extends "res://tests/test_case.gd"
## Tests for the engine's own texts of Keen 1-3 and the start screen in
## Dutch: every menu page (main in and out of a game, joined, online,
## controls, options, messages, name entry), the messages on the status
## line, the notices, the help line and the status screen are translated
## (nothing ends up in [member Lang.missing]) and fit their windows. Every
## text these files hand to [method Lang.text] as a literal has a Dutch
## line. Settings and saved games go to a folder of their own in the user
## folder, which is removed afterwards.

const TEST_DIRECTORY := "user://test_language_keen1_3"
## The files with the engine's own texts of Keen 1-3 and the start screen.
const SOURCES: PackedStringArray = [
	"res://src/menu/menu_controller.gd",
	"res://src/menu/controls_pages.gd",
	"res://src/menu/online_pages.gd",
	"res://src/menu/online_menu_info.gd",
	"res://src/online/online_text.gd",
	"res://src/game/online_play.gd",
	"res://src/game/game_screen.gd",
	"res://src/game/level_view.gd",
	"res://src/game/status_line.gd",
	"res://src/game/status_screen.gd",
	"res://src/game/ship_visit.gd",
	"res://src/game/save_games.gd",
	"res://src/game/hud.gd",
	"res://src/game/map_messages.gd",
	"res://src/game/player_controllers.gd",
	"res://src/data/game_files.gd",
	"res://src/level/ship_levels.gd",
	"res://src/keen2/keen2_view.gd",
	"res://src/keen2/keen2_menu_screen.gd",
	"res://src/keen2/keen2_online_screen.gd",
	"res://src/keen3/keen3_view.gd",
	"res://src/keen3/keen3_menu_screen.gd",
	"res://src/keen3/keen3_online_screen.gd",
	"res://src/keen3/keen3_scene_screen.gd",
	"res://src/launcher/launcher.gd",
]
## The scenes with a help line (F1), and how that line starts.
const HELP_SCENES: PackedStringArray = [
	"res://src/game/level_view.tscn",
	"res://src/keen2/keen2_view.tscn",
	"res://src/keen3/keen3_view.tscn",
]
const HELP_LINE_START := 'text = "Esc:'
## There are about 160 of them; far fewer means the pattern no longer finds
## them.
const MIN_LITERALS := 100
const LITERAL := 'Lang\\.text\\("((?:[^"\\\\]|\\\\.)*)"\\)'
const LEVEL_VIEW := preload("res://src/game/level_view.gd")
## The reasons Steam gives ([SteamService]).
const STEAM_REASONS: PackedStringArray = [
	SteamService.NO_PLUGIN,
	SteamService.NOT_RUNNING,
	"Steam could not open a lobby.",
	"Steam could not let you into that game.",
]

var _window: GameWindow
var _menus: MenuController


func run_all() -> void:
	_remove(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	Lang.use("nl")
	super.run_all()
	_free_nodes()
	Lang.use(Languages.ENGLISH)
	Lang.missing.clear()
	_remove(TEST_DIRECTORY)


func test_every_literal_text_has_a_dutch_line() -> void:
	var language := Languages.load_language("nl")
	var pattern := RegEx.create_from_string(LITERAL)
	var count := 0
	for path in SOURCES:
		var source := FileAccess.get_file_as_string(path)
		assert_true(not source.is_empty(), "read " + path)
		for found in pattern.search_all(source):
			var english := found.get_string(1).c_unescape()
			assert_true(language.texts.has(english), "%s: %s" % [path.get_file(), english])
			count += 1
	assert_true(count > MIN_LITERALS, "the texts are found: %d" % count)


func test_the_main_menus_in_dutch() -> void:
	_create_menus()
	_menus.story = PackedStringArray(["A story"])
	Lang.missing.clear()
	var outside := _menus._build_main(false, false, false)
	assert_equal(outside.header[0], "     HOOFDMENU", "title")
	assert_equal(outside.items[0].label, "Nieuw spel", "first choice")
	_check_menu(outside, "main menu")
	_check_menu(_menus._build_main(true, true, false), "main menu in a game")
	_check_menu(_menus._build_main(true, false, true), "main menu with two players")
	_menus.online.role = OnlineMenuInfo.Role.CLIENT
	_menus.online.partner_name = "Billy"
	var joined := _menus._build_main(true, false, false)
	assert_equal(joined.header[0], "  SPEL VAN BILLY", "whose game")
	_check_menu(joined, "joined menu")
	_check_menu(_menus._build_main(false, false, false), "joined, not in a game")
	_check_nothing_missing("main menus")


func test_loading_and_saving_in_dutch() -> void:
	_create_menus()
	var saves := SaveGames.in_directory(TEST_DIRECTORY.path_join("saves"))
	assert_true(saves.write(1, GameProgress.new()), "a saved game")
	_menus.saves = saves
	Lang.missing.clear()
	assert_equal(saves.summary(1), "Score 0, 0 levels", "a slot")
	_menus.open_main(true, true)
	_menus._pick_main(MenuController.SLOTS_LOAD)
	_check_menu(_menus._top(), "load")
	_menus._pick_main(MenuController.SLOTS_SAVE)
	_check_menu(_menus._top(), "save")
	_menus._pick(_menus._top(), _menus._top().items[0])
	assert_equal(_menus._top().kind, MenuController.OVERWRITE, "overwrite?")
	_check_menu(_menus._top(), "overwrite")
	_menus._pick_main(&"save_not_here")
	_check_menu(_menus._top(), "only on the map")
	_menus._save(3)
	_check_menu(_menus._top(), "saved")
	_check_nothing_missing("loading and saving")


func test_the_controls_in_dutch() -> void:
	_create_menus()
	Lang.missing.clear()
	var controls := ControlsPages.controls()
	assert_equal(controls.header[0], "  BESTURING", "title")
	_check_menu(controls, "controls")
	for set_index in 3:
		var keys := ControlsPages.key_set(set_index)
		_check_menu(keys, "keys %d" % set_index)
		_check_menu(ControlsPages.button_set(set_index), "buttons %d" % set_index)
		for item in keys.items.slice(0, -1):
			# "%-7s": the name of an action is seven letters at most.
			assert_true(item.label.substr(7, 1) == " ", "action name fits: " + item.label)
	_check_menu(ControlsPages.controllers(), "controllers")
	_check_menu(ControlsPages.key_prompt("jump"), "new key")
	_check_menu(ControlsPages.button_prompt("move_right"), "new button")
	_check_menu(ControlsPages.controller_prompt(1), "a player's controller")
	_menus.open_main(false, false)
	_menus._pick(controls, controls.items[-1])
	_check_menu(_menus._top(), "keys back as they were")
	_check_nothing_missing("controls")


func test_the_options_in_dutch() -> void:
	_create_menus()
	Lang.missing.clear()
	_check_menu(OptionsPages.options(_menus.settings, true), "options")
	_check_menu(OptionsPages.languages("nl"), "languages")
	_check_nothing_missing("options")


func test_the_name_for_the_high_scores_in_dutch() -> void:
	_create_menus()
	Lang.missing.clear()
	_menus.ask_name("eerste")
	assert_true(_window._size.x <= MenuController.TEXT_WIDTH, "fits")
	assert_true(_window_has("Je hebt de eerste plaats!"), "the place")
	_check_nothing_missing("name entry")


func test_the_online_pages_in_dutch() -> void:
	_create_menus()
	Lang.missing.clear()
	var online := _menus.online
	online.local_addresses = ["192.168.1.10", "10.0.0.2"]
	_check_menu(OnlinePages.online_menu(online, ""), "online")
	_check_menu(OnlinePages.host_setup(online, true, "ABCDEF", true), "host by IP")
	online.public_lookup_done = true
	online.local_addresses = []
	_check_menu(OnlinePages.host_setup(online, true, "ABCDEF", false), "host, nothing found")
	_check_menu(OnlinePages.host_setup(online, false, "", false), "host through Steam")
	online.role = OnlineMenuInfo.Role.HOST
	online.public_address = "203.0.113.9"
	online.host_lines = online.address_lines()
	online.host_lines.append(OnlinePages.password_line(""))
	_check_menu(OnlinePages.online_menu(online, "Billy"), "hosting, nobody yet")
	online.partner_name = "Robin"
	_check_menu(OnlinePages.online_menu(online, "Billy"), "hosting with someone")
	_check_menu(OnlinePages.hosting(online), "how to join")
	_check_menu(OnlinePages.steam_games(online), "no games on Steam")
	online.steam_games = ["Robin (1/2) *"]
	_check_menu(OnlinePages.steam_games(online), "a game on Steam")
	for purpose in [
		MenuController.TEXT_PLAYER_NAME,
		MenuController.TEXT_ADDRESS,
		MenuController.TEXT_PASSWORD,
		MenuController.TEXT_STEAM_PASSWORD,
		MenuController.TEXT_HOST_PASSWORD,
	]:
		_menus._text_purpose = purpose
		_menus._typed_text = "x".repeat(MenuController.ADDRESS_LENGTH)
		_menus._show_text_entry()
		assert_true(_window._size.x <= MenuController.TEXT_WIDTH, "typing fits: " + purpose)
		_check_lines(OnlinePages.text_prompt(purpose), "typing " + purpose)
	_check_nothing_missing("online pages")


func test_the_online_messages_in_dutch() -> void:
	Lang.missing.clear()
	_check_lines(OnlineText.missing_game("Keen 3"), "missing game")
	for reason in [
		OnlineSession.NO_ANSWER,
		JoinHandshake.WRONG_PASSWORD,
		JoinHandshake.NEEDS_PASSWORD,
		JoinHandshake.OTHER_VERSION,
		JoinHandshake.OTHER_DATA,
		JoinHandshake.FULL,
		JoinHandshake.TOO_MANY_TRIES,
		JoinHandshake.OTHER_GAME,
		JoinHandshake.NOT_OURS,
		JoinHandshake.REFUSED,
	]:
		_check_lines(OnlineText.join_failed(reason), "join failed: " + reason)
	_check_lines(OnlineText.host_left(), "host left")
	_check_lines(OnlineText.host_failed(ERR_ALREADY_IN_USE), "port in use")
	for reason in STEAM_REASONS:
		_check_lines(OnlineText.steam(reason), "Steam: " + reason)
	_check_nothing_missing("online messages")


func test_the_status_line_in_dutch() -> void:
	Lang.missing.clear()
	var display := DisplaySettings.new()
	display.realistic = true
	var picture := StatusLine.picture_text(ShipLevels.title(ShipLevels.INSIDE_LEVEL), display)
	assert_true(picture.begins_with("In het schip   breedbeeld"), picture)
	var inventory := Inventory.new()
	inventory.has_pogo = true
	inventory.keycards.fill(true)
	inventory.ship_parts[0] = true
	var carried := StatusLine.inventory_text(inventory)
	assert_true(carried.contains("Sleutelkaarten: Geel, Rood, Groen, Blauw"), carried)
	for number in [GameFiles.WORLD_MAP_LEVEL, GameFiles.ENDING_LEVEL, 1, ShipLevels.OUTSIDE_LEVEL]:
		ShipLevels.title(number)
	for title in StatusLine.GRAPHICS_TITLES:
		Lang.text(title)
	for both in [true, false]:
		GameScreen.on_off(both)
		for in_level in [true, false]:
			GameScreen.second_player_message(both, in_level)
	_check_nothing_missing("status line")


func test_the_messages_of_each_game_in_dutch() -> void:
	Lang.missing.clear()
	var messages: PackedStringArray = [
		GameScreen.MISSING_HD_MESSAGE,
		GameScreen.LIGHTER_MESSAGE,
		LEVEL_VIEW.MISSING_DATA_MESSAGE,
		LEVEL_VIEW.ONLY_HOST_WALKS_MESSAGE,
		Keen2View.MISSING_DATA_MESSAGE,
		Keen2View.UNREADABLE_MESSAGE,
		Keen2View.NOT_PLAYABLE_MESSAGE,
		Keen2View.ELDER_PROMPT,
		Keen2MenuScreen.SAVE_FAILED_MESSAGE,
		Keen2OnlineScreen.ONLY_HOST_WALKS_MESSAGE,
		Keen2OnlineScreen.HOSTING_STOPPED_MESSAGE,
		Keen2OnlineScreen.NOT_ONLINE_MESSAGE,
		Keen3SceneScreen.MISSING_DATA_MESSAGE,
		Keen3SceneScreen.UNREADABLE_MESSAGE,
		Keen3View.NOT_PLAYABLE_MESSAGE,
		Keen3MenuScreen.SAVE_FAILED_MESSAGE,
		Keen3OnlineScreen.ONLY_HOST_WALKS_MESSAGE,
		Keen3OnlineScreen.HOSTING_STOPPED_MESSAGE,
		Keen3OnlineScreen.NOT_ONLINE_MESSAGE,
		Launcher.QUIT_MESSAGE,
		Launcher.MISSING_FILES_MESSAGE,
		Hud.SCORE_LABEL,
	]
	for english in messages:
		Lang.text(english)
	_check_lines(Lang.texts(Keen2MenuScreen.LOAD_FAILED_LINES), "Keen 2 load failed")
	_check_lines(Lang.texts(Keen3MenuScreen.LOAD_FAILED_LINES), "Keen 3 load failed")
	_check_nothing_missing("messages")


func test_the_notes_in_the_game_in_dutch() -> void:
	Lang.missing.clear()
	var notes: Array[String] = []
	var visit := ShipVisit.new()
	visit.note_shown.connect(func(text: String) -> void: notes.append(text))
	for part in Inventory.ShipPart.values():
		visit._on_part_missing(part)
	assert_equal(notes[1], "Batterij ontbreekt nog", "a part still missing")
	var title := Lang.text(Keen3SceneScreen.LIVES_TITLE)
	var room := Keen3SceneScreen.LIVES_CELLS.x - Keen3SceneScreen.LIVES_TITLE_COLUMN
	assert_true(title.length() <= room, "Keen 3's Keens Left window")
	var window := GameWindow.new()
	MapMessages.show_lives(window, 3)
	assert_true(window._size.x <= MenuController.TEXT_WIDTH, "Keen 1's Keens Left window")
	window.free()
	_check_nothing_missing("notes")


func test_the_help_lines_in_dutch() -> void:
	Lang.missing.clear()
	for path in HELP_SCENES:
		var found := false
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if line.begins_with(HELP_LINE_START):
				found = true
				var english := line.trim_prefix("text = ").trim_prefix('"').trim_suffix('"')
				assert_true(Lang.text(english) != english, "translated: " + path)
		assert_true(found, "a help line in " + path)
	_check_nothing_missing("help lines")


func test_the_status_screen_in_dutch_keeps_its_columns() -> void:
	Lang.missing.clear()
	for english: String in StatusScreen.LABEL_ROOM:
		var dutch := Lang.text(english)
		assert_true(dutch.length() <= StatusScreen.LABEL_ROOM[english], "fits: " + dutch)
	var window := GameWindow.new()
	var inventory := Inventory.new()
	StatusScreen.fill(window, inventory, true)
	assert_equal(window._size, StatusScreen.SIZE, "the original's size")
	for item in window._texts:
		var end: int = item.cell.x + item.text.length()
		assert_true(end <= StatusScreen.SIZE.x, "inside the window: " + item.text)
	window.free()
	_check_nothing_missing("status screen")


func test_english_stays_as_it_was() -> void:
	Lang.use(Languages.ENGLISH)
	_create_menus()
	var main := _menus._build_main(false, false, false)
	assert_equal(main.header[0], "     MAIN MENU", "title")
	assert_equal(ControlsPages.key_set(0).items[0].label.left(8), "Left    ", "a key")
	var online := OnlinePages.host_setup(_menus.online, false, "ABC", true)
	assert_equal(online.items[1].label, "Password      ON", "password row")
	assert_equal(OnlinePages.password_line(""), "Password: none", "no password")
	var window := GameWindow.new()
	StatusScreen.fill(window, Inventory.new(), false)
	var texts := {}
	for item in window._texts:
		texts[item.text] = item.cell
	assert_equal(texts.get("PRESS ENTER"), Vector2i(9, 13), "the prompt where it was")
	assert_equal(texts.get("SHIP PARTS"), Vector2i(0, 11), "a label where it was")
	window.free()
	Lang.use("nl")


func _check_menu(menu: Menu, what: String) -> void:
	assert_true(menu.width() <= MenuController.TEXT_WIDTH, "%s fits: %d" % [what, menu.width()])


func _check_lines(lines: PackedStringArray, what: String) -> void:
	for line in lines:
		assert_true(line.length() <= MenuController.TEXT_WIDTH, "%s fits: %s" % [what, line])


func _check_nothing_missing(what: String) -> void:
	assert_equal(Lang.missing.keys(), [], "nothing left in English: " + what)


func _window_has(text: String) -> bool:
	for item in _window._texts:
		if item.text == text:
			return true
	return false


func _create_menus() -> void:
	_free_nodes()
	_window = GameWindow.new()
	_menus = MenuController.new()
	_menus.window = _window
	_menus.settings = UserSettings.new()
	_menus.settings.path = TEST_DIRECTORY.path_join("menus.cfg")


func _free_nodes() -> void:
	if _menus != null:
		_menus.free()
		_window.free()
		_menus = null


static func _remove(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	for folder in DirAccess.get_directories_at(absolute):
		_remove(path.path_join(folder))
	for file_name in DirAccess.get_files_at(absolute):
		DirAccess.remove_absolute(absolute.path_join(file_name))
	DirAccess.remove_absolute(absolute)
