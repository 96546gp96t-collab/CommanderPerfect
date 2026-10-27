extends "res://tests/test_case.gd"
## Tests for the Dutch texts of Keen 4's and 5's own files ([GalaxyTexts],
## languages/nl/keen4.txt and keen5.txt): every text the game shows has a
## translation, the boxes and the status window keep their original sizes
## and the Dutch fits them in the original fonts, every help and end page
## lays out without running over, the story keeps to the letters of its
## font, the screens show the Dutch, and English stays exactly as it is.
## An episode whose files are missing is left out; without both the suite
## is skipped. No text of the game is written here.

const DUTCH := "nl"
const GAMES: Array[int] = [4, 5]
## A text in a box: how wide and how high it may be, in pixels.
const ONE_LINE := 1
## The boxes of 26 × 8 cells with a picture of 48 pixels at one side, and
## where their text starts (Keen4Messages, Keen5Messages).
const BOX_SIZE := Vector2i(26 * 8, 8 * 8)
const BOX_TEXT_WIDTH := 26 * 8 - 0x30
const SPEAKER_DOWN := 6
const KEEN_DOWN := 12
## The box of the cheat (20 × 7 cells), after a death (20 × 8) and of
## "Game Over!" (16 × 3).
const CHEAT_BOX := Vector2i(20 * 8, 7 * 8)
const TRY_AGAIN_WIDTH := 20 * 8
const GAME_OVER_WIDTH := 16 * 8
## Keen 4's council run: Lindsey's hints, "Princess Lindsey says:", the
## member's thanks (the rest is Keen's); the janitor's run: Keen's reply.
const LINDSEY_HINTS: Array[int] = [0, 1]
const LINDSEY_SAYS := 4
const MEMBER_THANKS: Array[int] = [15, 16]
const JANITOR_KEEN := 2
## A map name has at most two lines (the status window's white bar).
const NAME_LINES := 2

## Game -> [data, rules] of the episodes whose files are there.
var _games: Dictionary[int, Array] = {}
var _dutch: LanguageFile


func _init() -> void:
	for game in GAMES:
		var rules := _rules(game)
		var files: GameFiles = rules.locate_files.call()
		if files == null:
			continue
		var data: GalaxyData = rules.load_data.call(files)
		if data != null:
			_games[game] = [data, rules]
	if _games.is_empty():
		skip("no Keen 4 or 5 in game_data")
	_dutch = Languages.load_language(DUTCH)


func run_all() -> void:
	Lang.use(DUTCH)
	super.run_all()
	Lang.use(Languages.ENGLISH)


func test_every_text_has_a_dutch_translation() -> void:
	for game in _games:
		var catalog := GalaxyTexts.catalog(_data(game), _rules(game))
		assert_true(not catalog.is_empty(), "Keen %d: a catalog" % game)
		for name in catalog:
			assert_true(Lang.has_game(name), "%s has no Dutch" % name)
		var prefix := _rules(game).text_names + "."
		for name in _dutch.game:
			if name.begins_with(prefix):
				assert_true(catalog.has(name), "%s is no text of the game" % name)


func test_the_dutch_uses_letters_the_fonts_have() -> void:
	for game in _games:
		var font := _data(game).graphics.font(_rules(game).menu_font)
		for name in GalaxyTexts.catalog(_data(game), _rules(game)):
			var dutch := Lang.game(name, "")
			for index in dutch.length():
				var character := dutch.unicode_at(index)
				if character != GalaxyTextPages.NEWLINE and character != GalaxyTextPages.CARET:
					assert_true(
						font.width_of(character) > 0,
						"%s: the font has no '%s'" % [name, dutch[index]]
					)


func test_help_and_end_pages_keep_their_commands_and_fit() -> void:
	for game in _games:
		var rules := _rules(game)
		var graphics := _data(game).graphics
		var layout := GalaxyHelp.page_layout(graphics, rules)
		for chunk in GalaxyTexts.text_chunks(rules):
			var name := GalaxyTexts.id(rules.text_names, GalaxyTexts.TEXT, chunk)
			var english := graphics.text(chunk)
			var merged := GalaxyTexts.merge_pages(english, Lang.game(name, ""))
			assert_true(not merged.is_empty(), "%s: the same commands as the game's" % name)
			if merged.is_empty():
				continue
			var pages := GalaxyTextPages.parse(merged)
			assert_equal(
				pages.page_count(), GalaxyTextPages.parse(english).page_count(), name + " pages"
			)
			for page in pages.page_count():
				layout.lay_out(pages, page)
				assert_true(not layout.overflowed, "%s: page %d runs over" % [name, page + 1])


func test_the_boxes_fit() -> void:
	for game in _games:
		var rules := _rules(game)
		var font := _data(game).graphics.font(rules.menu_font)
		for name in _box_limits(game):
			var limit: Vector2i = _box_limits(game)[name]
			var size := _size(font, Lang.game(name, ""))
			assert_true(
				size.x <= limit.x and size.y <= limit.y,
				"%s is %s, the box holds %s" % [name, size, limit]
			)
		if game == 4:
			var says := Lang.game(_id(game, Keen4Episode.COUNCIL_MESSAGES, LINDSEY_SAYS), "")
			for hint in LINDSEY_HINTS:
				var said := says + Lang.game(_id(game, Keen4Episode.COUNCIL_MESSAGES, hint), "")
				var size := _size(font, said)
				assert_true(
					size.x <= BOX_TEXT_WIDTH and size.y <= BOX_SIZE.y - SPEAKER_DOWN,
					"Lindsey's hint %d is %s" % [hint, size]
				)


func test_the_status_labels_fit() -> void:
	for game in _games:
		var rules := _rules(game)
		var font := _data(game).graphics.font(rules.menu_font)
		var widths := _label_widths(game)
		for which in widths:
			var name := _id(game, rules.status_texts, which)
			var width := font.text_width(Lang.game(name, ""))
			assert_true(
				width <= widths[which], "%s is %d wide of %d" % [name, width, widths[which]]
			)


func test_the_story_keeps_to_its_letters() -> void:
	for game in _games:
		var rules := _rules(game)
		var font := _data(game).graphics.font(rules.story_font)
		var name := _id(game, rules.story_messages, 0)
		for line in Lang.game(name, "").split("\n"):
			for index in line.length():
				var character := line.unicode_at(index)
				var letter := String.chr(character).to_upper() != String.chr(character).to_lower()
				assert_true(
					letter or GalaxyStoryScroller.SIGNS.has(character),
					"%s: '%s' is not in the story's font" % [name, line[index]]
				)
			var width := font.text_width(GalaxyStoryScroller.translate(line))
			assert_true(
				width <= GalaxyStoryScroller.STRIP_WIDTH, "%s: '%s' too wide" % [name, line]
			)


func test_the_screens_show_the_dutch() -> void:
	if _games.has(4):
		var data := _data(4)
		var window := Keen4StatusWindow.create(data)
		assert_equal(window.map_name(1), Lang.game("keen4.level.1", ""), "map name")
		assert_true(window.map_name(1) != data.executable.level_names()[1], "not English")
		assert_equal(
			window.label(GalaxyStatusWindow.Text.LOCATION), Lang.game("keen4.status.0", ""), "label"
		)
		var messages := Keen4Messages.create(data)
		messages.council(1, 0)
		assert_equal(messages.texts[0], Lang.game("keen4.council.16", ""), "council member")
		var help := GalaxyHelp.create(data.graphics, _rules(4))
		help.act(GalaxyHelp.Action.OPEN)
		var dutch := help.screen()
		Lang.use(Languages.ENGLISH)
		var english_help := GalaxyHelp.create(data.graphics, _rules(4))
		english_help.act(GalaxyHelp.Action.OPEN)
		assert_true(dutch.get_data() != english_help.screen().get_data(), "a Dutch help page")
		Lang.use(DUTCH)
	if _games.has(5):
		var messages := Keen5Messages.create(_data(5))
		messages.fuse(1)
		assert_equal(messages.texts[0], Lang.game("keen5.fuse.1", ""), "fuse message")


func test_english_stays_as_it_is() -> void:
	Lang.use(Languages.ENGLISH)
	for game in _games:
		var rules := _rules(game)
		var data := _data(game)
		for chunk in GalaxyTexts.text_chunks(rules):
			var english := data.graphics.text(chunk)
			assert_equal(GalaxyTexts.pages(rules.text_names, chunk, english), english, "pages")
		var window := GalaxyStatusWindow.create(data, rules)
		assert_equal(window.map_name(1), data.executable.level_names()[1], "map name")
		var labels := data.executable.texts(rules.status_texts)
		assert_equal(window.label(GalaxyStatusWindow.Text.SCORE), labels[1], "label")
	Lang.use(DUTCH)


func test_a_chunk_of_another_release_stays_english() -> void:
	var english := "^P\n^G1,2,3\nWords\n^E\n".to_ascii_buffer()
	var merged := GalaxyTexts.merge_pages(english, "^P\n^G9,9,9\nWoorden\n^E\n")
	assert_equal(
		merged.get_string_from_ascii(), "^P\n^G1,2,3\nWoorden\n^E\n", "the game's commands"
	)
	assert_true(GalaxyTexts.merge_pages(english, "^P\nWoorden\n^E\n").is_empty(), "other commands")


## Name -> how wide and high a text may be, for every boxed text of
## [param game].
func _box_limits(game: int) -> Dictionary[String, Vector2i]:
	var rules := _rules(game)
	var limits: Dictionary[String, Vector2i] = {}
	var loading := Vector2i(BOX_TEXT_WIDTH, BOX_SIZE.y - 2 * GalaxyGameBoxes.TEXT_RAISE)
	var speaker := Vector2i(BOX_TEXT_WIDTH, BOX_SIZE.y - SPEAKER_DOWN)
	var keen := Vector2i(BOX_TEXT_WIDTH, BOX_SIZE.y - KEEN_DOWN)
	var choice := (
		TRY_AGAIN_WIDTH
		- 2 * (GalaxyGameBoxes.CHOICE_FRAME_INSET + GalaxyGameBoxes.CHOICE_FRAME_WIDTH)
	)
	var line_height := _data(game).graphics.font(rules.menu_font).height
	for map in _data(game).executable.level_names().size():
		limits[_id(game, GalaxyTexts.ENTER, map)] = loading
		limits[_id(game, GalaxyTexts.LEVEL, map)] = Vector2i(
			GalaxyStatusWindow.NAME_AREA.size.x, NAME_LINES * line_height
		)
	limits[_id(game, rules.game_texts, rules.demo_text)] = loading
	limits[_id(game, rules.game_texts, rules.try_again_intro_text)] = Vector2i(
		choice, ONE_LINE * line_height
	)
	limits[_id(game, rules.game_texts, rules.try_again_text)] = Vector2i(choice, line_height)
	limits[_id(game, rules.game_texts, rules.exit_text)] = Vector2i(choice, line_height)
	limits[_id(game, rules.game_texts, rules.one_moment_text)] = Vector2i(BOX_SIZE.x, line_height)
	if rules.game_over_text >= 0:
		limits[_id(game, rules.game_texts, rules.game_over_text)] = Vector2i(
			GAME_OVER_WIDTH, line_height
		)
	limits[_id(game, rules.cheat_texts, GalaxyCheats.CHEAT_TEXT)] = CHEAT_BOX
	if game == 4:
		var council := Keen4Episode.COUNCIL_MESSAGES
		for index in Keen4Episode.translated_runs()[council]:
			var said_by_keen := index not in MEMBER_THANKS + LINDSEY_HINTS + [LINDSEY_SAYS]
			limits[_id(game, council, index)] = keen if said_by_keen else speaker
		for index in Keen4Episode.translated_runs()[Keen4Episode.JANITOR_MESSAGES]:
			limits[_id(game, Keen4Episode.JANITOR_MESSAGES, index)] = (
				keen if index == JANITOR_KEEN else speaker
			)
	else:
		limits[_id(game, rules.game_texts, Keen5Episode.KORATH_TEXT)] = loading
		for index in [Keen5Episode.KORATH_FUSE_TEXT, Keen5Episode.FUSE_TEXT]:
			limits[_id(game, Keen5Episode.FUSE_TEXTS, index)] = keen
	return limits


## Status label -> how wide it may be: the name over the white bar, labels
## centred over a column, and labels left of their black bars.
func _label_widths(game: int) -> Dictionary[int, int]:
	var column := GalaxyStatusWindow.COLUMN_WIDTH
	var widths: Dictionary[int, int] = {
		GalaxyStatusWindow.Text.LOCATION: GalaxyStatusWindow.NAME_AREA.size.x,
		GalaxyStatusWindow.Text.SCORE: column,
		GalaxyStatusWindow.Text.EXTRA: column,
		GalaxyStatusWindow.Text.LEVEL: column,
		GalaxyStatusWindow.Text.EASY: column,
		GalaxyStatusWindow.Text.NORMAL: column,
		GalaxyStatusWindow.Text.HARD: column,
		GalaxyStatusWindow.Text.KEYS:
		_left_of(GalaxyStatusWindow.KEYS_BAR, GalaxyStatusWindow.LEFT),
		GalaxyStatusWindow.Text.AMMO:
		_left_of(GalaxyStatusWindow.AMMO_BAR, GalaxyStatusWindow.RIGHT),
		GalaxyStatusWindow.Text.LIVES:
		_left_of(GalaxyStatusWindow.LIVES_BAR, GalaxyStatusWindow.LEFT),
		GalaxyStatusWindow.Text.DROPS:
		_left_of(GalaxyStatusWindow.DROPS_BAR, GalaxyStatusWindow.RIGHT),
	}
	if game == 4:
		widths[Keen4StatusWindow.RESCUED_TEXT] = column
		widths[Keen4StatusWindow.WETSUIT_TEXT] = Keen4StatusWindow.WETSUIT_BAR.size.x
		widths[Keen4StatusWindow.NO_WETSUIT_TEXT] = Keen4StatusWindow.WETSUIT_BAR.size.x
	else:
		widths[GalaxyStatusWindow.Text.MIDDLE] = (
			Keen5StatusWindow.KEYCARD_BOX.position.x - Keen5StatusWindow.KEYCARD_LABEL_AT.x - 1
		)
	return widths


static func _left_of(bar: Rect2i, left: int) -> int:
	return bar.position.x - left - 1


## How wide and high [param text] is in [param font], line by line.
static func _size(font: GalaxyFont, text: String) -> Vector2i:
	var lines := GalaxyWindow._lines(text)
	var width := 0
	for line in lines:
		width = maxi(width, font.text_width(line))
	return Vector2i(width, lines.size() * font.height)


func _id(game: int, kind: String, index: int) -> String:
	return GalaxyTexts.id(_rules(game).text_names, kind, index)


func _data(game: int) -> GalaxyData:
	return _games[game][0]


func _rules(game: int) -> GalaxyGameRules:
	if _games.has(game):
		return _games[game][1]
	return Keen4Episode.game_rules() if game == 4 else Keen5Episode.game_rules()
