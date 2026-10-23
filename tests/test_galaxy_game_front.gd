extends "res://tests/test_case.gd"
## Checks what the shared Galaxy game shows around its games (milestone
## E7: [GalaxyTitleLoop], [GalaxyHelp], [GalaxyEnding],
## [GalaxyHighScoreBoard], [GalaxyCheats], [GalaxyScene] and
## [GalaxyFrontScreen]) with a hand-made episode: the fixtures' files
## written to a folder of their own ([code]galaxy_file_fixtures.gd[/code]:
## one text, two small pictures, a one-letter font), the screen being the
## node layout of Keen 5's view with the generic script. The screen needs a
## running scene tree, so the suite runs in the first frame.

const Game := preload("res://tests/galaxy_game_fixtures.gd")
const Keen := preload("res://tests/galaxy_keen_fixtures.gd")
const Files := preload("res://tests/galaxy_file_fixtures.gd")
const Data := preload("res://tests/galaxy_fixtures.gd")
const MapFixtures := preload("res://tests/keen4_map_fixtures.gd")

const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const SCREEN_SCRIPT := "res://src/galaxy/game/galaxy_front_screen.gd"
const TEST_DIRECTORY := "user://test_galaxy_game_front"
const FRAME_SECONDS := 1.0 / 35.0
const ROOM_SIZE := Vector2i(20, 14)
const LETTER := "A"
const PLACES := 8
const HIGH_SCORE := 10000
## The one text of the fixtures is one page without pictures.
const TEXT := 0
const SCENE_TICS := 20
const MAP_ROWS: PackedStringArray = ["....................", "...................."]
## The fixture's level names and entry texts, as a run of texts.
const TEXTS := "fixture texts"
const TEXT_LENGTHS: PackedInt32Array = [10, 9, 26, 22]

var _tree: SceneTree
var _screen: GalaxyFrontScreen


## A scene that lasts [constant SCENE_TICS] tics or until a key.
class ShortScene:
	extends GalaxyScene
	var tics := 0
	var pressed := false

	func advance(more: int) -> bool:
		tics += more
		return true

	func press() -> bool:
		pressed = true
		return true

	func is_done() -> bool:
		return pressed or tics >= SCENE_TICS


func _init() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null or not _tree.root.is_inside_tree():
		skip("needs a running scene tree (the screen finds its nodes when it is ready)")


func run_all() -> void:
	if not skip_reason.is_empty():
		return
	Files.write_folder(ProjectSettings.globalize_path(_folder()))
	super.run_all()
	_free_screen()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_the_title_loop_plays_intro_demos_story_and_high_scores() -> void:
	var loop := GalaxyTitleLoop.create(7)
	var steps: Array[GalaxyTitleLoop.Step] = []
	var demos := PackedInt32Array()
	for step in GalaxyTitleLoop.STEPS.size() + 1:
		steps.append(loop.next())
		demos.append(loop.demo())
	var expected: Array[GalaxyTitleLoop.Step] = [
		GalaxyTitleLoop.Step.INTRO,
		GalaxyTitleLoop.Step.DEMO,
		GalaxyTitleLoop.Step.STORY,
		GalaxyTitleLoop.Step.DEMO,
		GalaxyTitleLoop.Step.HIGH_SCORES,
		GalaxyTitleLoop.Step.DEMO,
		GalaxyTitleLoop.Step.DEMO,
		GalaxyTitleLoop.Step.INTRO,
	]
	assert_equal(steps, expected, "Keen 4's and 5's order, then round again")
	assert_equal(demos, PackedInt32Array([-1, 0, -1, 1, 7, 2, 3, -1]), "the high scores' demo")


func test_a_cheat_counts_once_while_its_keys_are_held() -> void:
	var cheats := GalaxyCheats.new()
	var held: Array[Key] = [KEY_B, KEY_A, KEY_T]
	var is_held := func(key: Key) -> bool: return held.has(key)
	assert_equal(cheats.check(is_held), GalaxyCheats.Cheat.ITEMS, "B+A+T")
	assert_equal(cheats.check(is_held), GalaxyCheats.Cheat.NONE, "only once while held")
	held.assign([KEY_E, KEY_N, KEY_D])
	assert_equal(cheats.check(is_held), GalaxyCheats.Cheat.END, "E+N+D")
	var carried := GalaxyInventory.new()
	carried.lives = 2
	GalaxyCheats.give_items(carried)
	assert_equal([carried.shots, carried.lives], [GalaxyCheats.ITEM_SHOTS, 3], "99 charges, a life")
	assert_equal(carried.gems, PackedInt32Array([1, 1, 1, 1]), "four gems")


func test_the_end_pages_wait_with_a_blinking_arrow() -> void:
	var data := _data()
	var rules := _front_rules()
	var ending := GalaxyEnding.create(data.graphics, rules, TEXT)
	assert_equal(ending.page_count(), 1, "one page")
	assert_true(ending.waits(), "no timed pictures: it waits at once")
	var dim := ending.screen()
	assert_true(not ending.advance(GalaxyEnding.ARROW_TICS - 1), "dim for 70 tics")
	assert_true(ending.advance(1), "then bright")
	var arrow := Rect2i(GalaxyEnding.ARROW_AT, Vector2i(2, 2))
	assert_true(
		ending.screen().get_region(arrow).get_data() != dim.get_region(arrow).get_data(),
		"the arrow's two pictures"
	)
	assert_true(ending.press(), "a key")
	assert_true(ending.is_done(), "after the last page")


func test_the_help_menu_chooses_a_topic_and_pages() -> void:
	var data := _data()
	var rules := _front_rules()
	var help := GalaxyHelp.create(data.graphics, rules)
	assert_true(help.in_menu(), "the menu first")
	var menu := help.screen()
	assert_equal(menu.get_pixel(0, 0), EgaPalette.color(GalaxyHelp.PAGE_BACKGROUND), "unframed")
	help.act(GalaxyHelp.Action.UP)
	assert_equal(help.topic, 0, "not above the first")
	help.act(GalaxyHelp.Action.DOWN)
	help.act(GalaxyHelp.Action.DOWN)
	assert_equal(help.topic, 1, "not below the last of the rules' topics")
	help.act(GalaxyHelp.Action.OPEN)
	assert_equal([help.page, help.page_count()], [0, 1], "its pages")
	help.act(GalaxyHelp.Action.NEXT_PAGE)
	assert_equal(help.page, 0, "not past the last page")
	assert_true(help.act(GalaxyHelp.Action.ESCAPE) and help.in_menu(), "back to the menu")
	assert_equal(help.topic, 1, "the hand still there")
	assert_true(not help.act(GalaxyHelp.Action.ESCAPE), "Escape leaves the help")


func test_the_table_is_printed_by_the_rules_margins_without_a_column() -> void:
	var data := _data()
	var rules := _front_rules()
	var scores := _scores(TEST_DIRECTORY.path_join("board.json"))
	scores.entries[0].name = LETTER
	scores.entries[0].count = 3
	var map := MapFixtures.map(MAP_ROWS)
	var board := GalaxyHighScoreBoard.create(data.graphics, rules, scores, map, Vector2i.ZERO)
	var overlay := board.overlay()
	var letter_pixel := Vector2i(rules.high_score_left, rules.high_score_top)
	assert_true(overlay.get_pixelv(letter_pixel).a > 0.5, "the name at the margins")
	assert_true(overlay.get_pixelv(letter_pixel + Vector2i(1, 0)).a < 0.5, "only its set pixels")
	var icon := Vector2i(GalaxyHighScoreBoard.ICONS_LEFT, rules.high_score_top + 1)
	assert_true(overlay.get_pixelv(icon).a < 0.5, "no extra column")
	rules.high_score_icon_tile = 0
	board = GalaxyHighScoreBoard.create(data.graphics, rules, scores, map, Vector2i.ZERO)
	assert_true(board.overlay().get_pixelv(icon).a > 0.5, "with a tile: one per counted thing")
	board.start_typing(1)
	board.type_character(LETTER)
	assert_equal(scores.entries[1].name, LETTER, "typed in")
	board.finish(false)
	assert_equal(scores.entries[1].name, "", "Escape: no name")


func test_a_scene_runs_on_the_clock_and_goes_on_after_it() -> void:
	_create_loaded()
	var after := [0]
	var scene := ShortScene.new()
	_screen._start_scene(scene, func() -> void: after[0] += 1)
	assert_equal(_screen.front(), GalaxyFrontScreen.Front.SCENE, "the scene")
	assert_true(not _screen._score_box.visible, "over the whole screen")
	_frames(SCENE_TICS / GalaxyClock.NORMAL_TICS + 1)
	assert_equal(after[0], 1, "then what follows, once")
	assert_equal(_screen.front(), GalaxyFrontScreen.Front.NONE, "over")
	scene = ShortScene.new()
	_screen._start_scene(scene, Callable())
	_send_key(KEY_SPACE)
	assert_true(scene.pressed and _screen.front() == GalaxyFrontScreen.Front.NONE, "a key")


func test_the_end_pages_lead_to_the_high_scores() -> void:
	_create_loaded()
	_screen._start_ending(TEXT)
	assert_equal(_screen.front(), GalaxyFrontScreen.Front.ENDING, "the end pages")
	assert_true(_screen._title_layer.visible, "over the whole screen")
	_screen.inventory().score = 0
	_send_key(KEY_SPACE)
	assert_true(_screen.in_title_loop(), "no place on the table: the title loop")
	assert_true(_screen._after_game, "the title picture after the high scores")
	assert_true(_screen.shows_message(), "the high scores' map fades in")


func test_a_score_that_makes_the_table_is_typed_in_and_saved() -> void:
	_create_loaded()
	_screen.inventory().score = HIGH_SCORE + 1
	_screen._game_ended()
	assert_equal(_screen.high_scores().entries[0].score, HIGH_SCORE + 1, "at the top")
	assert_true(_screen.shows_message(), "the fade to its map")
	assert_true(not _screen.in_title_loop(), "not yet the title loop")
	_screen._queue.clear()
	_screen._board = GalaxyHighScoreBoard.create(
		_screen._data.graphics,
		_screen.rules,
		_screen.high_scores(),
		MapFixtures.map(MAP_ROWS),
		Vector2i.ZERO
	)
	_screen._board.start_typing(0)
	_screen._front = GalaxyFrontScreen.Front.NAME_ENTRY
	_type_key(KEY_A, "A".unicode_at(0))
	_type_key(KEY_ENTER, 0)
	assert_equal(_screen.high_scores().entries[0].name, LETTER, "the name")
	var path := _screen.rules.high_scores_path()
	assert_equal(path, TEST_DIRECTORY.path_join("high_scores.json"), "in the episode's folder")
	assert_true(FileAccess.file_exists(path), "saved")
	assert_true(_screen.in_title_loop(), "then the high scores in the title loop")


func test_the_cheats_end_the_game_or_give_the_items() -> void:
	_create_loaded()
	var held: Array[Key] = [KEY_B, KEY_A, KEY_T]
	_screen._key_held = func(key: Key) -> bool: return held.has(key)
	_play_room()
	var lives := _screen.inventory().lives
	assert_true(_screen._check_cheats(), "B+A+T")
	assert_true(_screen.shows_message(), "its box")
	_send_key(KEY_SPACE)
	assert_equal(_screen.inventory().lives, lives + 1, "a life more")
	assert_equal(_screen.inventory().shots, GalaxyCheats.ITEM_SHOTS, "99 charges")
	_screen._in_title_loop = true
	held.assign([KEY_E, KEY_N, KEY_D])
	assert_true(not _screen._check_cheats(), "none in the title loop")


func _front_rules() -> GalaxyGameRules:
	var rules := Game.rules()
	rules.user_folder = TEST_DIRECTORY
	rules.help_menu_picture = 0
	rules.help_pointer_picture = 1
	rules.help_topic_texts = PackedInt32Array([TEXT, TEXT])
	rules.page_frame_picture = -1
	rules.end_text = TEXT
	rules.arrow_dim_picture = 0
	rules.arrow_bright_picture = 1
	rules.high_score_top = 3
	rules.high_score_left = 5
	rules.high_score_right = 300
	rules.high_score_color = 12
	rules.high_score_icon_tile = -1
	rules.high_score_map = Game.WORLD_MAP
	rules.cheat_texts = TEXTS
	rules.game_texts = TEXTS
	rules.status_texts = TEXTS
	rules.game_over_text = 0
	rules.try_again_intro_text = 1
	rules.try_again_text = 2
	rules.exit_text = 3
	rules.one_moment_text = 0
	rules.demo_text = 0
	rules.demo_sign_sprite = 0
	rules.high_score_demo = 0
	rules.high_score_count = 0
	return rules


func _data() -> GalaxyData:
	var folder := ProjectSettings.globalize_path(_folder())
	return GalaxyData.load_from(GameFiles.open(folder, Data.EXTENSION), _episode())


static func _episode() -> GalaxyEpisode:
	var episode := Data.episode()
	episode.text_lengths = {TEXTS: TEXT_LENGTHS}
	return episode


func _scores(path: String) -> GalaxyHighScores:
	var defaults: Array[GalaxyHighScores.Entry] = []
	for place in PLACES:
		defaults.append(GalaxyHighScores.Entry.create("", HIGH_SCORE, 0))
	return GalaxyHighScores.load_from(path, defaults)


func _create_loaded() -> void:
	_free_screen()
	var rules := _front_rules()
	var folder := ProjectSettings.globalize_path(_folder())
	rules.locate_files = func() -> GameFiles: return GameFiles.open(folder, Data.EXTENSION)
	rules.load_data = func(files: GameFiles) -> GalaxyData:
		var data := GalaxyData.load_from(files, _episode())
		data.tile_info = MapFixtures.tile_info()
		data.graphics.sprite_infos = Keen.sprite_infos()
		return data
	var node := (load(VIEW_SCENE) as PackedScene).instantiate()
	node.set_script(load(SCREEN_SCRIPT))
	_screen = node as GalaxyFrontScreen
	_screen.rules = rules
	_tree.root.add_child(_screen)
	_screen._set_up_screen()
	_screen._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_screen._settings.aspect = DisplaySettings.Aspect.ORIGINAL
	assert_true(_screen._load_data(), "the hand-made episode is read")
	_screen._set_up_play()
	_screen._set_up_flow()
	_screen._set_up_front()
	_screen._high_scores = _scores(rules.high_scores_path())


## Plays a room as large as the view, Keen on its floor.
func _play_room() -> GalaxyLevelSession:
	var rows := PackedStringArray()
	for row in ROOM_SIZE.y - 2:
		rows.append(".".repeat(ROOM_SIZE.x))
	rows.append("....K" + ".".repeat(ROOM_SIZE.x - 5))
	rows.append("#".repeat(ROOM_SIZE.x))
	var map := Keen.level(rows)
	_screen._start = GalaxyStart.find(map, _screen.rules)
	var session := _screen._new_session(map, Game.FIRST_LEVEL, 0)
	_screen._play(session, map)
	return session


func _send_key(key: Key) -> void:
	_type_key(key, 0)


func _type_key(key: Key, unicode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.unicode = unicode
	event.pressed = true
	if not _screen._front_input(event):
		_screen._flow_input(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	if not _screen._front_input(release):
		_screen._flow_input(release)


func _frames(count: int) -> void:
	for frame in count:
		_screen._process(FRAME_SECONDS)


func _free_screen() -> void:
	if _screen != null:
		_screen.get_parent().remove_child(_screen)
		_screen.free()
		_screen = null


static func _folder() -> String:
	return TEST_DIRECTORY.path_join("files")


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file in directory.get_files():
		directory.remove(file)
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
