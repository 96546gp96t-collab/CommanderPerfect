extends "res://tests/test_case.gd"
## Tests for the texts of Keen 1-3's own files in another language
## ([GameTexts], [Keen1Texts], [Keen2Texts], [Keen3Texts]): every text of
## the catalog has a Dutch translation, the boxes of a fixed size still fit
## (line counts and lengths), the documents lay out in the window, English
## stays exactly as read, and in Dutch the statue, Elder, ship and status
## windows show the Dutch. A game whose files are missing is skipped.

const GAMES: PackedInt32Array = [1, 2, 3]
const DUTCH := "nl"
## The widest window of Keen 1-3 in 4:3 (inside its border).
const MAX_WINDOW_WIDTH := 38
## The ship's message has [constant Keen3View.SHIP_WINDOW] rows, the prompt
## on the last; one row is left free above it.
const SHIP_PROMPT_ROWS := 2
## A city name in the left column of Keen 2's status screen ends before the
## right column starts, with a space between; the right column ends before
## the keycards.
const CITY_LEFT_COLUMN := 0
const CITY_RIGHT_COLUMN := 7
const KEYCARD_COLUMN := 20
const STATUS_WIDTH := 28
## The levels with a statue (Keen 1) and an Elder (Keen 2) checked in a
## window.
const HINT_LEVEL := 2
const ELDER_LEVEL := Keen2LevelPlay.FIRST_ELDER_MESSAGE_LEVEL
## Words that only the Dutch documents have.
const STORY_PHRASE := "Billy Blaze, een achtjarig"
const END_TEXT_PHRASE := "WORDT VERVOLGD"
const KEEN_3_END_TEXT_PHRASE := "Je hebt de laatste episode"
const VIEW_SCENES: Dictionary[int, String] = {
	1: "res://src/game/level_view.tscn",
	2: "res://src/keen2/keen2_view.tscn",
	3: "res://src/keen3/keen3_view.tscn",
}

var _catalogs: Dictionary[int, Dictionary] = {}
var _tree: SceneTree


func run_all() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	for game in GAMES:
		_catalogs[game] = GameTexts.catalog(game)
	if _catalogs.values().all(func(texts: Dictionary) -> bool: return texts.is_empty()):
		skip("no Keen 1-3 game data found")
		return
	super.run_all()
	Lang.use(Languages.ENGLISH)


func test_every_text_has_a_dutch_translation() -> void:
	Lang.use(DUTCH)
	for game in _games():
		var texts := _catalog(game)
		for id in texts:
			assert_true(Lang.has_game(id), "%s is translated" % id)
	var language := Languages.load_language(DUTCH)
	for id in language.game:
		var game := _game_of(id)
		if game in _games():
			assert_true(_catalog(game).has(id), "%s is a name of the catalog" % id)
	Lang.use(Languages.ENGLISH)


func test_english_stays_as_read() -> void:
	Lang.use(Languages.ENGLISH)
	for game in _games():
		var texts := _catalog(game)
		for id in texts:
			var lines := texts[id].split("\n")
			assert_equal(Lang.game_lines(id, lines), lines, id)
			assert_equal(GameTexts.fixed_lines(id, lines), lines, id + " (fixed)")
	var files := GameFiles.locate()
	if files != null:
		var story := files.read(GameFiles.STORY_TEXT)
		assert_equal(GameTexts.document(Keen1Texts.STORY, story), story, "the story's bytes")


func test_statue_and_message_windows_fit() -> void:
	Lang.use(DUTCH)
	var free_ids: Array[String] = []
	for level in HintTexts.HINT_LEVELS:
		free_ids.append(Keen1Texts.HINT % level)
	free_ids.append_array([Keen1Texts.RETURNS_TO_SHIP, Keen2Texts.ELDER % 1, Keen2Texts.ELDER % 2])
	for index in EndingTexts.HOME_MESSAGE_COUNT:
		free_ids.append(Keen1Texts.HOME_MESSAGE % (index + 1))
	for which in Keen2Executable.EndingText.size():
		free_ids.append(Keen2Texts.ending_name(which))
	for id in free_ids:
		if _has_english(id):
			_assert_fits(id, MAX_WINDOW_WIDTH)
	Lang.use(Languages.ENGLISH)


func test_the_missing_parts_keep_their_empty_lines() -> void:
	if not _has_english(Keen1Texts.MISSING_PARTS):
		return
	Lang.use(DUTCH)
	var english := _english_lines(Keen1Texts.MISSING_PARTS)
	var dutch := GameTexts.fixed_lines(Keen1Texts.MISSING_PARTS, english)
	assert_true(dutch != english, "translated")
	assert_equal(dutch.size(), english.size(), "as many lines")
	for row in english.size():
		assert_equal(dutch[row].strip_edges().is_empty(), english[row].is_empty(), "row %d" % row)
		assert_true(dutch[row].length() <= _longest(english), "row %d not wider" % row)
	Lang.use(Languages.ENGLISH)


func test_the_status_boxes_keep_their_layout() -> void:
	Lang.use(DUTCH)
	for id in [Keen2Texts.STATUS, Keen3Texts.STATUS]:
		if not _has_english(id):
			continue
		var english := _english_lines(id)
		var dutch := GameTexts.fixed_lines(id, english)
		assert_true(dutch != english, id + " translated")
		for row in english.size():
			assert_equal(dutch[row].length(), english[row].length(), "%s row %d" % [id, row])
			if english[row].strip_edges().is_empty():
				assert_true(dutch[row].strip_edges().is_empty(), "%s row %d empty" % [id, row])
	if _has_english(Keen2Texts.CITY % 1):
		for index in Keen2StatusScreen.CITY_CELLS.size():
			var column := Keen2StatusScreen.CITY_CELLS[index].x
			var end := CITY_RIGHT_COLUMN - 1 if column == CITY_LEFT_COLUMN else KEYCARD_COLUMN - 1
			var name := Lang.game(Keen2Texts.CITY % (index + 1), "")
			assert_true(column + name.length() <= end, "city %d fits: %s" % [index + 1, name])
	Lang.use(Languages.ENGLISH)


func test_keen_3_boxes_fit_their_frames() -> void:
	if _catalog(3).is_empty():
		return
	Lang.use(DUTCH)
	for index in Keen3Mortimer.BOX_SIZES.size():
		var size := Keen3Mortimer.BOX_SIZES[index]
		_assert_fits(Keen3Texts.MORTIMER % (index + 1), size.x, size.y)
	for index in Keen3Ending.PAGE_FRAME_STARTS.size():
		var frame := Keen3Ending.frame_on_picture(
			Keen3Ending.PAGE_FRAME_STARTS[index], Keen3Ending.PAGE_FRAME_ENDS[index]
		)
		_assert_fits(Keen3Texts.ENDING_PAGE % (index + 1), frame.size.x, frame.size.y)
	var the_end := Keen3Ending.frame_on_picture(
		Keen3Ending.THE_END_FRAME_START, Keen3Ending.THE_END_FRAME_END
	)
	var end_rows := _english_lines(Keen3Texts.THE_END).size()
	_assert_fits(Keen3Texts.THE_END, the_end.size.x, end_rows)
	var ship := Keen3View.SHIP_WINDOW
	for index in 4:
		_assert_fits(Keen3Texts.SHIP % (index + 1), ship.x, ship.y - SHIP_PROMPT_ROWS)
	_assert_fits(Keen3Texts.SHIP_PROMPT, ship.x, 1)
	_assert_fits(Keen3Texts.READER_FOOTER, Keen3Ending.TEXT_WIDTH, 1)
	Lang.use(Languages.ENGLISH)


func test_the_documents_lay_out_in_dutch() -> void:
	Lang.use(DUTCH)
	var phrases: Dictionary[String, String] = {
		Keen1Texts.STORY: STORY_PHRASE,
		Keen1Texts.END_TEXT: END_TEXT_PHRASE,
		Keen2Texts.STORY: STORY_PHRASE,
		Keen2Texts.END_TEXT: END_TEXT_PHRASE,
		Keen3Texts.STORY: STORY_PHRASE,
	}
	for id in phrases:
		if not _has_english(id):
			continue
		var data := GameTexts.document(id, _bytes(_catalog(_game_of(id))[id]))
		var lines := TextDocument.layout(data, MenuController.TEXT_WIDTH)
		_assert_laid_out(id, lines, phrases[id])
	if _has_english(Keen3Texts.END_TEXT):
		var data := GameTexts.document(
			Keen3Texts.END_TEXT, _bytes(_catalog(3)[Keen3Texts.END_TEXT])
		)
		var lines := Keen3EndText.layout(data, Keen3Ending.TEXT_WIDTH)
		_assert_laid_out(Keen3Texts.END_TEXT, lines, KEEN_3_END_TEXT_PHRASE)
	Lang.use(Languages.ENGLISH)


func test_the_story_follows_the_language() -> void:
	var files := GameFiles.locate()
	if files == null or not files.has_file(GameFiles.STORY_TEXT):
		return
	var menus := MenuController.new()
	menus.window = GameWindow.new()
	Lang.use(Languages.ENGLISH)
	menus.set_story(Keen1Texts.STORY, files.read(GameFiles.STORY_TEXT))
	var english := menus.story
	Lang.use(DUTCH)
	menus._pick_main(MenuController.STORY)
	assert_true(menus.story != english, "laid out again in Dutch")
	assert_true("\n".join(menus.story).contains(STORY_PHRASE), "the Dutch story")
	Lang.use(Languages.ENGLISH)
	menus._pick_main(MenuController.STORY)
	assert_equal(menus.story, english, "English again, as it was")
	menus.window.free()
	menus.free()


func test_the_statue_window_in_dutch() -> void:
	if not _has_english(Keen1Texts.HINT % HINT_LEVEL):
		return
	# Keen 1's game screen has no class name of its own.
	var view := _open_view(1)
	Lang.use(DUTCH)
	view.set("_level_number", HINT_LEVEL)
	view.call("_on_hint_touched")
	var texts := _window_texts(view.get("_window"))
	assert_equal(texts[0], Lang.game(Keen1Texts.HINT % HINT_LEVEL, "").split("\n")[0], "Dutch")
	assert_equal(texts[-1], "Druk op ENTER:", "the prompt in Dutch")
	_close_view(view)


func test_the_elder_window_in_dutch() -> void:
	if not _has_english(Keen2Texts.ELDER % 1):
		return
	var view := _open_view(2) as Keen2View
	Lang.use(DUTCH)
	view._show_elder_message(ELDER_LEVEL)
	var texts := _window_texts(view._window)
	var index := Keen2LevelPlay.elder_message_index(ELDER_LEVEL)
	var dutch := Lang.game(Keen2Texts.ELDER % (index + 1), "").split("\n")
	assert_equal(texts[0], dutch[0], "the Elder speaks Dutch")
	assert_equal(texts[-1], "Druk op ENTER:", "the prompt in Dutch")
	_close_view(view)


func test_the_ship_window_in_dutch() -> void:
	if not _has_english(Keen3Texts.SHIP % 1):
		return
	var view := _open_view(3) as Keen3View
	Lang.use(DUTCH)
	view._show_ship_message(0)
	var texts := _window_texts(view._window)
	assert_equal(texts[0], Lang.game(Keen3Texts.SHIP % 1, "").split("\n")[0], "the ship in Dutch")
	assert_equal(texts[-1], Lang.game(Keen3Texts.SHIP_PROMPT, ""), "the prompt in Dutch")
	_close_view(view)


func test_the_status_screens_in_dutch() -> void:
	Lang.use(DUTCH)
	if _has_english(Keen2Texts.STATUS):
		var window := GameWindow.new()
		var progress := Keen2Progress.new()
		progress.complete_level(Keen2Progress.CITY_LEVELS[0])
		var cities := PackedStringArray()
		for index in Keen2Progress.CITY_LEVELS.size():
			cities.append(_catalog(2)[Keen2Texts.CITY % (index + 1)])
		Keen2StatusScreen.fill(window, progress, _english_lines(Keen2Texts.STATUS), cities)
		var texts := _window_texts(window)
		assert_true(texts.has("   STEDEN GERED     SLEUTELS"), "Keen 2's labels in Dutch")
		assert_true(texts.has("Londen"), "the saved city in Dutch")
		window.free()
	if _has_english(Keen3Texts.STATUS):
		var window := Keen3Window.new()
		var lines := _english_lines(Keen3Texts.STATUS)
		Keen3StatusScreen.fill(window, Keen3Inventory.new(), 0, lines)
		var label := Keen3Window.label_text(" ANKHTIJD    SLEUTELKAARTEN ")
		assert_true(_window_texts(window).has(label), "Keen 3's labels in Dutch")
		window.free()
	Lang.use(Languages.ENGLISH)


func _assert_fits(id: String, width: int, rows := -1) -> void:
	assert_true(Lang.has_game(id), id + " translated")
	var lines := Lang.game(id, "").split("\n")
	if rows >= 0:
		assert_true(lines.size() <= rows, "%s: %d lines, room for %d" % [id, lines.size(), rows])
	for line in lines:
		assert_true(line.length() <= width, "%s: %s is wider than %d" % [id, line, width])


func _assert_laid_out(id: String, lines: PackedStringArray, dutch_part: String) -> void:
	assert_true(not lines.is_empty(), id + " laid out")
	for line in lines:
		assert_true(line.length() <= MAX_WINDOW_WIDTH, "%s: %s fits" % [id, line])
	assert_true("\n".join(lines).contains(dutch_part.strip_edges()), id + " in Dutch")


func _open_view(game: int) -> GameScreen:
	Lang.use(Languages.ENGLISH)
	var view := (load(VIEW_SCENES[game]) as PackedScene).instantiate() as GameScreen
	_tree.root.add_child(view)
	return view


func _close_view(view: GameScreen) -> void:
	Lang.use(Languages.ENGLISH)
	view.get_parent().remove_child(view)
	view.free()


static func _window_texts(window: GameWindow) -> PackedStringArray:
	var texts := PackedStringArray()
	for item in window._texts:
		texts.append(item.text)
	return texts


func _games() -> PackedInt32Array:
	var games := PackedInt32Array()
	for game in GAMES:
		if not _catalog(game).is_empty():
			games.append(game)
	return games


func _catalog(game: int) -> Dictionary[String, String]:
	var texts: Dictionary[String, String] = {}
	texts.assign(_catalogs.get(game, {}))
	return texts


func _has_english(id: String) -> bool:
	return _catalog(_game_of(id)).has(id)


func _english_lines(id: String) -> PackedStringArray:
	return _catalog(_game_of(id)).get(id, "").split("\n")


static func _game_of(id: String) -> int:
	if not id.begins_with("keen"):
		return 0
	return id.substr("keen".length(), 1).to_int()


static func _longest(lines: PackedStringArray) -> int:
	var longest := 0
	for line in lines:
		longest = maxi(longest, line.length())
	return longest


## The bytes of a document's text from the catalog, as in its file.
static func _bytes(text: String) -> PackedByteArray:
	var bytes := PackedByteArray()
	var crlf := text.replace("\n", GameTexts.DOCUMENT_LINE_END)
	for index in crlf.length():
		bytes.append(crlf.unicode_at(index) & 0xFF)
	bytes.append(TextDocument.END_MARK)
	return bytes
