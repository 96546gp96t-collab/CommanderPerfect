extends "res://tests/test_case.gd"
## Tests for the languages: reading a language file, finding the languages
## in their folders, English staying the game as it is, translations with
## the letters the original fonts have, the setting, and picking a language
## in the options of Keen 1-3 and on the Galaxy watch. Files go to a folder
## of their own in the user folder, which is removed afterwards.

const TEST_DIRECTORY := "user://test_language"
const SAMPLE := """# a comment
@name Testish

New Game = Nieuw spel
Two\\nlines = Twee\\nregels
@alien THIS IS NEAT = DIT IS TOF
@text keen1.hint.2 = Een hint
@text keen1.story
  ~Het verhaal
tweede regel
@end
"""

var _window: GameWindow
var _menus: MenuController


func run_all() -> void:
	_remove(TEST_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	super.run_all()
	_free_nodes()
	Lang.use(Languages.ENGLISH)
	Lang.missing.clear()
	_remove(TEST_DIRECTORY)


func test_a_language_file_is_read() -> void:
	var language := LanguageFile.parse(SAMPLE)
	assert_equal(language.name, "Testish", "name")
	assert_equal(language.texts["New Game"], "Nieuw spel", "engine text")
	assert_equal(language.texts["Two\\nlines"], "Twee\nregels", "new line in a value")
	assert_equal(language.alien["THIS IS NEAT"], "DIT IS TOF", "alien sign")
	assert_equal(language.game["keen1.hint.2"], "Een hint", "game text on one line")
	assert_equal(language.game["keen1.story"], "  ~Het verhaal\ntweede regel", "block kept exactly")


func test_a_later_file_wins() -> void:
	var language := LanguageFile.parse("@name A\nYes = Ja\nNo = Nee")
	language.merge(LanguageFile.parse("Yes = Jawel"))
	assert_equal(language.name, "A", "name kept")
	assert_equal(language.texts["Yes"], "Jawel", "the later translation")
	assert_equal(language.texts["No"], "Nee", "the rest kept")


func test_english_is_the_game_as_it_is() -> void:
	Lang.use(Languages.ENGLISH)
	assert_true(Lang.is_english(), "English")
	assert_equal(Lang.text("New Game"), "New Game", "engine text")
	assert_equal(Lang.game("keen1.hint.2", "A hint"), "A hint", "game text")
	assert_equal(Lang.alien("THIS IS NEAT"), "THIS IS NEAT", "alien sign")
	Lang.use("no such language")
	assert_true(Lang.is_english(), "an unknown language is English")


func test_a_translation_is_used_and_a_missing_one_stays_english() -> void:
	Lang.use_file(LanguageFile.parse(SAMPLE))
	Lang.missing.clear()
	assert_equal(Lang.text("New Game"), "Nieuw spel", "translated")
	assert_equal(Lang.text("Quit"), "Quit", "not translated")
	assert_true(Lang.missing.has("Quit"), "noted as missing")
	assert_equal(Lang.game("keen1.hint.2", "A hint"), "Een hint", "game text")
	assert_equal(Lang.game("keen1.hint.6", "Other"), "Other", "game text not translated")
	assert_equal(
		Lang.game_lines("keen1.story", ["x"]),
		PackedStringArray(["  ~Het verhaal", "tweede regel"]),
		"lines"
	)
	assert_equal(Lang.alien("DIE"), "DIE", "alien sign not translated")
	Lang.use(Languages.ENGLISH)


func test_letters_the_fonts_lack_are_made_plain() -> void:
	assert_equal(Lang.fold("Geïnstalleerd, één café"), "Geinstalleerd, een cafe", "accents")
	assert_equal(Lang.fold("Straße “x”"), 'Strasse "x"', "other letters")
	assert_equal(Lang.fold("Ω"), Lang.UNKNOWN, "a letter the fonts cannot draw")
	assert_equal(Lang.fold("a\\x80b"), "a" + String.chr(0x80) + "b", "a picture character")


func test_languages_are_found_in_their_folders() -> void:
	var built_in := TEST_DIRECTORY.path_join("app")
	var own := TEST_DIRECTORY.path_join("player")
	_write(built_in.path_join("nl/a.txt"), "@name Nederlands\nYes = Ja\nNo = Nee")
	_write(own.path_join("nl/b.txt"), "Yes = Jawel")
	_write(own.path_join("de/de.txt"), "@name Deutsch\nYes = Ja")
	_write(own.path_join("fr/readme.md"), "not a language file")
	var search := PackedStringArray(
		[ProjectSettings.globalize_path(built_in), ProjectSettings.globalize_path(own)]
	)
	var available := Languages.available(search)
	assert_equal(available.keys(), ["en", "de", "nl"], "English first, then by name")
	assert_equal(available["nl"], "Nederlands", "name")
	Lang.use("nl", search)
	assert_equal(Lang.code(), "nl", "in use")
	assert_equal(Lang.text("Yes"), "Jawel", "the player's own file wins")
	assert_equal(Lang.text("No"), "Nee", "the app's file still counts")
	Lang.use(Languages.ENGLISH)


func test_dutch_comes_with_the_game() -> void:
	var available := Languages.available()
	assert_equal(available.get("nl", ""), "Nederlands", "Dutch in the list")
	Lang.use("nl")
	assert_equal(Lang.text("Sound"), "Geluid", "Dutch is used")
	Lang.use(Languages.ENGLISH)


func test_the_language_is_remembered() -> void:
	var settings := UserSettings.new()
	settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	assert_equal(settings.language, Languages.ENGLISH, "English by default")
	assert_true(not settings.alien_text, "alien signs as in the original by default")
	settings.language = "nl"
	settings.alien_text = true
	assert_true(settings.save(), "saved")
	var loaded := UserSettings.load_from(settings.path)
	assert_equal(loaded.language, "nl", "language")
	assert_true(loaded.alien_text, "alien signs")
	assert_equal(Lang.code(), "nl", "loading the settings switches the language")
	Lang.use(Languages.ENGLISH)


func test_the_english_options_are_as_before() -> void:
	Lang.use(Languages.ENGLISH)
	var menu := OptionsPages.options(UserSettings.new(), true)
	assert_equal(menu.header, PackedStringArray(["  OPTIONS"]), "title")
	assert_equal(menu.items[0].label, "Sound         ON", "sound")
	assert_equal(menu.items[4].label, "Smooth motion OFF", "longest name")
	assert_equal(menu.items[-2].label, "Alien text    ORIGINAL", "alien signs")
	assert_equal(menu.items[-1].label, "Language      English", "language")


func test_the_options_in_dutch_line_up() -> void:
	Lang.use("nl")
	var menu := OptionsPages.options(UserSettings.new(), true)
	var column := menu.items[0].label.find("AAN")
	assert_true(column > "Geluid".length(), "value after the name")
	for item in menu.items:
		assert_true(item.label[column - 1] == " ", "values in one column: " + item.label)
	assert_true(menu.width() <= MenuController.TEXT_WIDTH, "fits the window")
	Lang.use(Languages.ENGLISH)


func test_picking_a_language_in_keen_1_to_3() -> void:
	_create_menus()
	_menus.open_main(false, false)
	_choose("Options")
	_choose("Language      English")
	assert_equal(_menus._top().kind, OptionsPages.LANGUAGES, "the list of languages")
	assert_equal(_menus._top().current().id, &"en", "the cursor on the language in use")
	_choose("Nederlands")
	assert_equal(_menus.settings.language, "nl", "stored")
	assert_equal(Lang.code(), "nl", "in use")
	assert_equal(_menus._top().kind, MenuController.OPTIONS, "back on the options")
	assert_true(_labels()[0].begins_with("Geluid"), "the options in Dutch")
	_press(KEY_ESCAPE)
	assert_equal(_menus._top().kind, MenuController.MAIN, "the main menu")
	Lang.use(Languages.ENGLISH)
	_free_nodes()


func test_picking_a_language_on_the_watch() -> void:
	_free_nodes()
	var menus := GalaxyMenuController.new()
	menus.settings = UserSettings.new()
	menus.settings.path = TEST_DIRECTORY.path_join("watch.cfg")
	var options := GalaxyMenuPages.options(menus.settings, true)
	assert_equal(options.items[-2].label, "ALIEN TEXT (OFF)", "alien signs")
	assert_equal(options.items[-1].label, "LANGUAGE (ENGLISH)", "language")
	menus.open_main(false)
	menus._pick(menus.top(), menus.top().items[3])
	assert_equal(menus.top().kind, GalaxyMenuController.CONFIGURE, "configure")
	menus._pick(menus.top(), menus.top().items[2])
	assert_equal(menus.top().kind, MenuController.OPTIONS, "options")
	menus._pick(menus.top(), menus.top().items[-1])
	var card := menus.top()
	assert_equal(card.kind, OptionsPages.LANGUAGES, "the languages card")
	assert_true(menus.is_checked(card, 0), "English checked")
	var dutch := Languages.available().keys().find("nl")
	menus._pick(card, card.items[dutch])
	assert_equal(menus.settings.language, "nl", "stored")
	assert_true(menus.is_checked(menus.top(), dutch), "Dutch checked at once")
	assert_equal(menus.top().header, PackedStringArray(["TAAL"]), "the card in Dutch")
	assert_equal(menus._stack[2].items[-1].label, "TAAL (NEDERLANDS)", "the options too")
	menus.free()
	Lang.use(Languages.ENGLISH)


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
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ENTER
	event.keycode = KEY_ENTER
	event.pressed = true
	_menus.handle_input(event)


func _press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	_menus.handle_input(event)


static func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


static func _remove(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	for folder in DirAccess.get_directories_at(absolute):
		_remove(path.path_join(folder))
	for file_name in DirAccess.get_files_at(absolute):
		DirAccess.remove_absolute(absolute.path_join(file_name))
	DirAccess.remove_absolute(absolute)
