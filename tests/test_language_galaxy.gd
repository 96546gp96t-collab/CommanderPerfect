extends "res://tests/test_case.gd"
## Checks the engine's own texts of Keen 4 and 5 in Dutch: every card,
## dialog and footer of the wrist watch ([GalaxyMenuController] and
## [GalaxyCoopMenuController], in and out of a game, and the main card of a
## player in somebody else's game) is drawn with the episode's own font
## ([GalaxyMenuView]), nothing asks for a text the language lacks, and every
## label fits where the original puts it: the rows on the watch's screen
## (160 pixels from x 74), a name before its key box, the footer's texts
## beside each other, a dialog on the watch's screen. The status-line
## messages, the help lines (F1) and the help's page number are checked
## too. English stays the original's words. Skipped per episode without its
## files; saved games go to a folder of their own, removed afterwards. With
## GALAXY_SHOTS set to a folder, every drawn picture is saved there as PNG
## (to look at the cards by eye).

const TEST_DIRECTORY := "user://test_language_galaxy"
const SHOTS_ENVIRONMENT := "GALAXY_SHOTS"
const DUTCH := "nl"
## The watch's screen (Omni).
const SCREEN_LEFT := GalaxyMenuView.SCREEN_AT.x
const SCREEN_RIGHT := GalaxyMenuView.SCREEN_AT.x + GalaxyMenuView.SCREEN_SIZE.x
const SCREEN_WIDTH := GalaxyMenuView.SCREEN_SIZE.x
## The least room between the footer's left and right texts.
const FOOTER_GAP := 4
## A text title leaves this much before the line's end.
const TITLE_GAP := GalaxyMenuView.TEXT_TITLE_GAP
## The least room between a name and its key box.
const BOX_GAP := 2
## The help's page number: the most pages a topic has, and the screen.
const MOST_PAGES := 99
const PAGE_SCREEN_WIDTH := 320
## The online pages' box (ours): the widest it may be, less its margins.
const ONLINE_ROOM := GalaxyOnlinePageView.MAX_WIDTH - 2 * GalaxyOnlinePageView.MARGIN.x
const SAVE_SLOT := 1
## The status-line messages of the Galaxy screens and views (their English
## words or formats).
const MESSAGES: PackedStringArray = [
	GalaxyCoopScreen.JOINED_MESSAGE,
	GalaxyCoopScreen.JOINS_LATER_MESSAGE,
	GalaxyCoopScreen.LEFT_MESSAGE,
	GalaxyJoinedScreen.WAITING_MESSAGE,
	GalaxyJoinedScreen.HOST_WALKS_MESSAGE,
	GalaxyFlowScreen.NOT_A_MAP_MESSAGE,
	GalaxyLevelScreen.PREPARING_MESSAGE,
	GalaxyPlayScreen.MAP_NAMED_TITLE,
	GalaxyPlayScreen.MAP_TITLE,
	GalaxyGameRules.MISSING_DATA_MESSAGE,
	GalaxyGameRules.UNREADABLE_MESSAGE,
	GalaxyGameBoxes.PAUSED_TEXT,
	GalaxyHelp.PAGE_NUMBER,
	Keen4View.GOD_MODE_MESSAGE,
	Keen4View.EVERYTHING_MESSAGE,
	Keen5View.GOD_MODE_MESSAGE,
	Keen5View.EVERYTHING_MESSAGE,
	GalaxySaveSlots.DAMAGED_NAME,
	"on",
	"off",
	"Music on",
	"Music off",
	"xBRZ graphics",
]
const VIEW_SCENES: PackedStringArray = [
	"res://src/keen4/keen4_view.tscn", "res://src/keen5/keen5_view.tscn"
]
const HELP_LABEL := "HelpLabel"

var _shots := ""
var _font: GalaxyFont
var _view: GalaxyMenuView
var _cards: GalaxyMenuCards
var _game := ""
var _checked := 0


func run_all() -> void:
	_shots = OS.get_environment(SHOTS_ENVIRONMENT)
	if not _shots.is_empty():
		DirAccess.make_dir_recursive_absolute(_shots)
	_remove(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	super.run_all()
	Lang.use(Languages.ENGLISH)
	Lang.missing.clear()
	_remove(TEST_DIRECTORY)


func test_keen_4s_watch_in_dutch() -> void:
	_check_episode(Keen4Episode.game_rules(), "keen4")


func test_keen_5s_watch_in_dutch() -> void:
	_check_episode(Keen5Episode.game_rules(), "keen5")


func test_the_messages_in_dutch() -> void:
	Lang.use(DUTCH)
	Lang.missing.clear()
	for message in MESSAGES:
		Lang.text(message)
	for words: String in GalaxyAudio.SOUND_MODE_TITLES.values():
		Lang.text(words)
	for scene in VIEW_SCENES:
		var help := _help_line(scene)
		assert_true(not help.is_empty(), "the help line of " + scene)
		assert_true(Lang.text(help) != help, "the help line in Dutch: " + scene)
	assert_true(Lang.missing.is_empty(), "messages without Dutch: %s" % [Lang.missing.keys()])
	var format_count := GalaxyGameRules.MISSING_DATA_MESSAGE.count("%s")
	assert_equal(Lang.text(GalaxyGameRules.MISSING_DATA_MESSAGE).count("%s"), format_count, "%s")
	Lang.use(Languages.ENGLISH)


func test_english_stays_the_original() -> void:
	Lang.use(Languages.ENGLISH)
	var menus := GalaxyMenuController.new()
	menus.settings = UserSettings.new()
	menus.open_main(true)
	var labels := PackedStringArray()
	for item in menus.top().items:
		labels.append(item.label)
	assert_equal(labels, GalaxyMenuPages.MAIN_LABELS, "the main card")
	menus._confirm(GalaxyMenuController.QUIT_LINES, MenuController.CHOICE_QUIT)
	assert_equal(menus.top().header, GalaxyMenuController.QUIT_LINES, "the quit question")
	assert_equal(GalaxyMenuPages.new_game().items[0].label, "BEGIN EASY GAME", "difficulty")
	assert_equal(GalaxyMenuPages.keys().items[0].label.get_slice("\t", 0), "LEFT", "a key")
	menus.free()


## Every card, dialog and footer of [param rules]' watch in Dutch.
func _check_episode(rules: GalaxyGameRules, game: String) -> void:
	var files: GameFiles = rules.locate_files.call()
	if files == null:
		print("  (no %s files: its watch is not checked)" % game)
		return
	var data: GalaxyData = rules.load_data.call(files)
	assert_true(data != null, game + " read")
	if data == null:
		return
	_game = game
	_cards = rules.menu_cards(data.graphics.ranges.picture_count)
	_view = GalaxyMenuView.create(data.graphics, _cards)
	_font = data.graphics.font(_cards.font)
	Lang.use(DUTCH)
	Lang.missing.clear()
	_checked = 0
	var plain := GalaxyMenuController.new()
	_walk(plain, "solo")
	plain.free()
	var coop := GalaxyCoopMenuController.new()
	_walk(coop, "coop")
	_walk_coop(coop)
	coop.free()
	_check_page_number(data.graphics.font(rules.menu_font))
	assert_true(_checked > 40, "%s: every card drawn (%d)" % [game, _checked])
	assert_true(Lang.missing.is_empty(), "%s: no Dutch for %s" % [game, Lang.missing.keys()])
	Lang.use(Languages.ENGLISH)


func _walk(menus: GalaxyMenuController, name: String) -> void:
	menus.settings = UserSettings.new()
	menus.settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	menus.settings.language = DUTCH
	menus.slots = GalaxySaveSlots.in_directory(TEST_DIRECTORY.path_join(name))
	for in_game in [false, true]:
		var where := "%s_%s" % [name, "game" if in_game else "demo"]
		menus.open_main(in_game)
		_check(menus, where + "_main")
		for id in [GalaxyMenuController.NEW_GAME, MenuController.SLOTS_LOAD]:
			menus._pick_main(id)
			_check(menus, "%s_%s" % [where, id])
			menus._pop()
		_walk_dialogs(menus, where)
	_walk_save(menus, name)
	_walk_configure(menus, name)


## The questions and the messages.
func _walk_dialogs(menus: GalaxyMenuController, where: String) -> void:
	var questions: Array[PackedStringArray] = [
		GalaxyMenuController.QUIT_LINES,
		GalaxyMenuController.END_LINES,
		GalaxyMenuController.NEW_GAME_LINES,
		GalaxyMenuController.LOAD_LINES,
	]
	for index in questions.size():
		menus._confirm(questions[index], MenuController.CHOICE_QUIT)
		_check(menus, "%s_question_%d" % [where, index])
		menus._pop()
	var messages: Array[PackedStringArray] = [
		GalaxyMenuController.PADDLE_WON_LINES,
		GalaxyMenuController.PADDLE_LOST_LINES,
		GalaxyMenuController.KEYS_RESET_LINES,
		GalaxyMenuScreen.SAVE_FAILED_LINES,
		GalaxyMenuScreen.LOAD_FAILED_LINES,
	]
	for index in messages.size():
		menus._tell(messages[index])
		_check(menus, "%s_message_%d" % [where, index])
		menus._pop()


## The save card, and a name typed into a box.
func _walk_save(menus: GalaxyMenuController, name: String) -> void:
	menus.open_main(true)
	menus._pick_main(MenuController.SLOTS_SAVE)
	_check(menus, name + "_save")
	var save := menus.top()
	menus._pick(save, save.items[SAVE_SLOT - 1])
	menus.typed_save_name = "KORATH"
	_check(menus, name + "_save_typing")
	menus._pop()


## Configure and the cards behind it.
func _walk_configure(menus: GalaxyMenuController, name: String) -> void:
	menus.open_main(true)
	menus._pick_main(GalaxyMenuController.CONFIGURE)
	_check(menus, name + "_configure")
	var configure := menus.top()
	for item in configure.items:
		if item.id in [MenuController.ONLINE, &"reset"]:
			continue
		menus._pick(configure, item)
		_check(menus, "%s_%s" % [name, item.id])
		if item.id == MenuController.OPTIONS:
			_walk_options(menus, name)
		elif item.id == MenuController.KEY_SET:
			_walk_buttons(menus, "%s_keys" % name)
		menus._pop()
		while menus.top() != configure:
			menus._pop()
	menus._toggle_option(&"score_box")
	_check(menus, name + "_score_box")
	menus._close_message()


## The Options card scrolled to its end, and the languages.
func _walk_options(menus: GalaxyMenuController, name: String) -> void:
	var options := menus.top()
	assert_true(options.items.size() > GalaxyMenuView.MAX_ROWS, "the options scroll")
	options.cursor = options.items.size() - 1
	_check(menus, name + "_options_scrolled")
	menus._toggle_option(OptionsPages.LANGUAGE)
	_check(menus, name + "_languages")
	menus._pop()
	options.cursor = 0


## The Buttons row at the end of a keys card, and its card.
func _walk_buttons(menus: GalaxyMenuController, name: String) -> void:
	var keys := menus.top()
	keys.cursor = keys.items.size() - 1
	menus._pick(keys, keys.current())
	_check(menus, name + "_buttons")
	menus._pop()


## The Two Players card, each player's keys and buttons, the text pages
## and the main card of a player in somebody else's game.
func _walk_coop(menus: GalaxyCoopMenuController) -> void:
	for partner in [false, true]:
		menus.open_main(true)
		menus.two_players = partner
		menus.offers_partner = true
		menus._pick_main(GalaxyMenuController.CONFIGURE)
		menus._pick_configure(menus.top().items[-2])
		assert_equal(menus.top().kind, GalaxyCoopMenuController.TWO_PLAYERS, "two players")
		_check(menus, "coop_two_players_%d" % int(partner))
	var card := menus.top()
	for item in card.items:
		if item.id != MenuController.KEY_SET:
			continue
		menus._pick(card, item)
		_check(menus, "coop_keys_%d" % item.value)
		_walk_buttons(menus, "coop_keys_%d" % item.value)
		menus._pop()
	for purpose in [
		MenuController.TEXT_PLAYER_NAME,
		MenuController.TEXT_ADDRESS,
		MenuController.TEXT_HOST_PASSWORD,
		MenuController.TEXT_PASSWORD,
	]:
		menus._text_purpose = purpose
		for line in menus.text_lines():
			var width := _font.text_width(line)
			assert_true(width <= ONLINE_ROOM, "%s: %s (%d px)" % [_game, line, width])
	menus.online.role = OnlineMenuInfo.Role.CLIENT
	for in_game in [false, true]:
		menus.open_main(in_game)
		_check(menus, "client_main_%d" % int(in_game))
		menus._pick_main(GalaxyMenuController.CONFIGURE)
		_check(menus, "client_configure_%d" % int(in_game))
	menus.online.role = OnlineMenuInfo.Role.OFFLINE


## Draws the panel as it is and checks that the top card fits.
func _check(menus: GalaxyMenuController, name: String) -> void:
	_checked += 1
	var image := _view.draw(menus)
	if not _shots.is_empty():
		image.save_png(_shots.path_join("%s_%s.png" % [_game, name]))
	var top := menus.top()
	if top.kind in [MenuController.MESSAGE, GalaxyMenuController.CONFIRM]:
		_check_dialog(top.header, name)
		return
	var card := menus.below() if top.kind == GalaxyMenuController.SLOT_NAME else top
	_check_footer(top.kind == GalaxyMenuController.SLOT_NAME, menus.depth(), name)
	var place := _cards.card(card.kind)
	if place.picture < 0 and not card.header.is_empty():
		var right := (
			GalaxyMenuView.TITLE_AT.x
			+ GalaxyMenuView.TEXT_TITLE_INDENT
			+ _width(card.header[0])
			+ TITLE_GAP
		)
		_fits(right <= GalaxyMenuView.LINE_RIGHT, card.header[0], name)
	var left := (
		ceili(float(GalaxyMenuView.ITEMS_AT.x + place.offset.x) / GalaxyMenuView.BYTE)
		* GalaxyMenuView.BYTE
	)
	if card.kind in [MenuController.SLOTS_LOAD, MenuController.SLOTS_SAVE]:
		var empty := Lang.text(GalaxyMenuView.EMPTY)
		var end := GalaxyMenuView.EMPTY_TEXT_X + _width(empty)
		_fits(end <= GalaxyMenuView.SLOT_SIZE.x, empty, name)
		return
	var text_left := left + GalaxyMenuView.TEXT_SHIFT.x
	for item in card.items:
		var parts := item.label.trim_prefix(GalaxyMenuController.GAP).split("\t")
		var end := text_left + _width(parts[0])
		if parts.size() == 1:
			_fits(end <= SCREEN_RIGHT, parts[0], name)
			continue
		_fits(end + BOX_GAP <= left + GalaxyMenuView.KEY_BOX_X, parts[0], name)
		var box_text := left + GalaxyMenuView.KEY_TEXT_X + _width(parts[1])
		_fits(box_text <= SCREEN_RIGHT, parts[1], name)


## The footer's left and right texts side by side, the bottom one on the
## screen.
func _check_footer(typing: bool, depth: int, name: String) -> void:
	var left := Lang.text(GalaxyMenuView.TYPE_NAME_TEXT if typing else GalaxyMenuView.ARROWS_TEXT)
	var right := Lang.text(GalaxyMenuView.ACCEPTS_TEXT if typing else GalaxyMenuView.SELECTS_TEXT)
	var bottom := Lang.text(
		GalaxyMenuView.QUIT_TEXT if depth <= 1 else GalaxyMenuView.BACK_OUT_TEXT
	)
	var room := GalaxyMenuView.FOOTER_RIGHT - GalaxyMenuView.FOOTER_LEFT
	_fits(_width(left) + FOOTER_GAP + _width(right) <= room, left + " / " + right, name)
	_fits(_width(bottom) <= SCREEN_WIDTH, bottom, name)


## A dialog's box on the watch's screen.
func _check_dialog(lines: PackedStringArray, name: String) -> void:
	for line in lines:
		var box := _width(line) + GalaxyMenuView.DIALOG_EXTRA_WIDTH
		_fits(box <= SCREEN_WIDTH, line, name)


## The help's page number on its screen, plain and framed.
func _check_page_number(font: GalaxyFont) -> void:
	var number := Lang.text(GalaxyHelp.PAGE_NUMBER) % [MOST_PAGES, MOST_PAGES]
	var width := font.text_width(number)
	assert_true(
		GalaxyHelp.PAGE_NUMBER_AT.x + width <= PAGE_SCREEN_WIDTH,
		"%s: %s (%d px)" % [_game, number, width]
	)


func _fits(fits: bool, text: String, name: String) -> void:
	assert_true(fits, '%s %s: "%s" does not fit (%d px)' % [_game, name, text, _width(text)])


func _width(text: String) -> int:
	return _font.text_width(text)


## The English help line (F1) of the view scene [param path].
static func _help_line(path: String) -> String:
	var state := (load(path) as PackedScene).get_state()
	for node in state.get_node_count():
		if state.get_node_name(node) != HELP_LABEL:
			continue
		for property in state.get_node_property_count(node):
			if state.get_node_property_name(node, property) == &"text":
				return str(state.get_node_property_value(node, property))
	return ""


static func _remove(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	for folder in DirAccess.get_directories_at(absolute):
		_remove(path.path_join(folder))
	for file_name in DirAccess.get_files_at(absolute):
		DirAccess.remove_absolute(absolute.path_join(file_name))
	DirAccess.remove_absolute(absolute)
