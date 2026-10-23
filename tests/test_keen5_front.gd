extends "res://tests/test_case.gd"
## Checks what Keen 5 shows around its games ([Keen5View] on
## [GalaxyFrontScreen], milestone E7) with the player's files: the title
## loop's order (intro, demo 0, story, demo 1, the high scores, demos 2
## and 3), its colours, a key opening the control panel (E9) for a new
## game, the help with its five
## topics, the end pages (and the secret end when Korath III's fuse was
## broken), the name typed in on map 15 and kept in Keen 5's own folder,
## game over as the exploding galaxy, the cheats, and the order of the
## sprites of one priority in the high-score demo. The screen must be in a
## running scene tree (its _ready loads the files), so the suite runs in
## the first frame. Skipped without the files.

const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const TEST_DIRECTORY := "user://test_keen5_front"
const FRAME_SECONDS := 1.0 / 35.0
const QUEUE_FRAMES := 400
const DEATH_FRAMES := 300
## The pages of the help's topics (files): ComputerWrist, The Game, The
## Story, Order Info, About Id.
const HELP_PAGES: PackedInt32Array = [13, 21, 4, 15, 2]
const END_PAGES := 9
const DEFAULT_NAMES: PackedStringArray = [
	"Id Software - '91",
	"",
	"Jason Blochowiak",
	"Adrian Carmack",
	"John Carmack",
	"Tom Hall",
	"John Romero",
	"",
]
const DEFAULT_SCORE := 10000
const NEW_SCORE := 20000
const NAME := "KE"
## The title loop's steps after the intro and the demo each plays.
const LOOP_DEMOS: PackedInt32Array = [-1, 0, -1, 1, 4, 2, 3]
const LIGHT_CYAN := 11
## The high-score demo's first frame: its diagonal Slicestar is placed
## before its Volteface and drawn over it (seen in the original, E7).
const HIGH_SCORE_DEMO := 4

var _view: Keen5View
var _tree: SceneTree


func _init() -> void:
	if Keen5Files.locate() == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null or not _tree.root.is_inside_tree():
		skip("needs a running scene tree (the screen loads its files when it is ready)")


func run_all() -> void:
	if not skip_reason.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	KeyBindings.reset()
	super.run_all()
	_free_view()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_the_title_loop_plays_in_the_originals_order() -> void:
	_create_view()
	assert_true(_view.in_title_loop(), "the title loop first")
	assert_equal(_view.front(), GalaxyFrontScreen.Front.INTRO, "the intro")
	assert_equal(_view._intro.word_color, Keen5Episode.INTRO_WORD_COLORS[0], "red words")
	assert_equal(_view._title_layer.word_colors, Keen5Episode.INTRO_WORD_COLORS, "light red over")
	var demos := PackedInt32Array([_view._loop.demo()])
	for step in range(1, LOOP_DEMOS.size()):
		_view._next_title_step()
		demos.append(_view._loop.demo())
		if _view._loop.step() == GalaxyTitleLoop.Step.STORY:
			assert_equal(_view.front(), GalaxyFrontScreen.Front.STORY, "the story")
			assert_equal(
				_view._story.text_color, EgaPalette.color(LIGHT_CYAN), "the story in light cyan"
			)
		else:
			assert_true(_view.shows_message(), "step %d: the demo's box or fade" % step)
	assert_equal(demos, LOOP_DEMOS, "intro, 0, story, 1, high scores (4), 2, 3")


func test_a_demo_plays_on_normal_with_the_demo_sign() -> void:
	_create_view()
	_view._next_title_step()
	_run_queue()
	assert_equal(_view.front(), GalaxyFrontScreen.Front.DEMO, "demo 0")
	assert_equal(_view.map_number(), 1, "on map 1")
	assert_true(_view._demo_sign.visible and not _view._score_box.visible, "DEMO, no score box")
	assert_equal(_view._clock.tics_per_frame, GalaxyClock.DEMO_TICS, "3 tics a frame")
	assert_true(not _view.inventory().extra_lives_for_points, "no lives for points")


func test_the_high_scores_draw_the_sprites_in_the_originals_order() -> void:
	_create_view()
	_view._start_demo(HIGH_SCORE_DEMO, true)
	_run_queue()
	assert_true(_view._board_sprite.visible, "the table over map 15")
	_frames(1)
	var star := -1
	var volteface := -1
	for object in _view._objects._shown:
		var item: GalaxyObjectLayer.Item = _view._objects._shown[object]
		if object is Keen5Slicestar:
			star = item.node.get_index()
		elif object is Keen5Volteface:
			volteface = item.node.get_index()
	assert_true(star > volteface, "the Slicestar over the Volteface")


func test_a_key_in_the_title_loop_opens_the_panel_for_a_new_game() -> void:
	_create_view()
	_press_key(KEY_SPACE)
	assert_true(_view.menus().is_open(), "the control panel (milestone E9)")
	_press_key(KEY_ENTER)
	_press_key(KEY_ENTER)
	assert_true(not _view.in_title_loop(), "New Game, Normal: the game")
	_run_queue()
	assert_equal(_view.map_number(), Keen5Episode.WORLD_MAP, "on the world map")
	assert_true(_view.map_session() != null, "played")


func test_the_help_has_five_topics_in_the_frame() -> void:
	_create_view()
	_press_key(KEY_F1)
	assert_equal(_view.front(), GalaxyFrontScreen.Front.HELP, "F1 opens the help")
	var help := _view._help
	var menu := help.screen()
	var top := _view._data.graphics.picture(Keen5Episode.PAGE_FRAME_PICTURE)
	assert_equal(menu.get_pixel(0, 0), top.get_pixel(0, 0), "in the red frame")
	var pages := PackedInt32Array()
	for topic in HELP_PAGES.size():
		help.topic = topic
		help.act(GalaxyHelp.Action.OPEN)
		pages.append(help.page_count())
		help.act(GalaxyHelp.Action.ESCAPE)
	assert_equal(pages, HELP_PAGES, "the pages of each topic")
	_press_key(KEY_ESCAPE)
	assert_true(_view.front() != GalaxyFrontScreen.Front.HELP, "Escape leaves it")
	assert_true(_view.in_title_loop(), "the title loop goes on")


func test_the_end_and_the_secret_end() -> void:
	_create_view()
	_view._new_game()
	assert_equal(_view.end_text(), Keen5Episode.END_TEXT, "the end")
	_view.progress().mark_done(Keen5Progress.KORATH_LEVEL, Keen5Progress.DONE_BY_FUSE)
	assert_equal(_view.end_text(), Keen5Episode.SECRET_END_TEXT, "Korath III's fuse: the secret")
	for text in [Keen5Episode.END_TEXT, Keen5Episode.SECRET_END_TEXT]:
		var ending := GalaxyEnding.create(_view._data.graphics, _view.rules, text)
		assert_equal(ending.page_count(), END_PAGES, "text %d: nine pages" % text)


func test_the_end_leads_to_the_name_on_the_high_scores() -> void:
	_create_view()
	assert_equal(
		_view.rules.high_scores_path(), "user://keen5/high_scores.json", "Keen 5's own folder"
	)
	var names := PackedStringArray()
	for entry in _view.high_scores().entries:
		names.append(entry.name)
		assert_equal(entry.score, DEFAULT_SCORE, "10,000 each")
	assert_equal(names, DEFAULT_NAMES, "the original's table")
	_view._new_game()
	_run_queue()
	_view.inventory().score = NEW_SCORE
	var held: Array[Key] = [KEY_E, KEY_N, KEY_D]
	_view._key_held = func(key: Key) -> bool: return held.has(key)
	_frames(2)
	assert_equal(_view.front(), GalaxyFrontScreen.Front.ENDING, "E+N+D: the end pages")
	held.clear()
	for page in END_PAGES:
		_press_key(KEY_SPACE)
	_run_queue()
	assert_equal(_view.front(), GalaxyFrontScreen.Front.NAME_ENTRY, "the name is typed in")
	assert_equal(_view.map_number(), Keen5Episode.HIGH_SCORE_MAP, "on map 15")
	_type(NAME)
	_press_key(KEY_ENTER)
	assert_equal(_view.high_scores().entries[0].name, NAME, "at the top")
	assert_true(FileAccess.file_exists(_view.high_scores().path), "kept")
	assert_true(_view.in_title_loop(), "then the high scores in the title loop")


func test_game_over_is_the_exploding_galaxy() -> void:
	_create_view()
	_view._new_game()
	_run_queue()
	_view._show_level(1)
	_view.inventory().lives = 0
	_view.session().keen.kill()
	for frame in DEATH_FRAMES:
		_frames(1)
		if _view.front() == GalaxyFrontScreen.Front.SCENE:
			break
	assert_equal(_view.front(), GalaxyFrontScreen.Front.SCENE, "the scene")
	var scene := _view._scene as Keen5GalaxyExplosion
	assert_true(scene != null, "the galaxy explodes")
	_frames(30)
	assert_equal(scene.stage, Keen5GalaxyExplosion.Stage.FLASH, "it flashes")
	_press_key(KEY_SPACE)
	assert_equal(scene.stage, Keen5GalaxyExplosion.Stage.GAME_OVER, "a key: GAME OVER")
	_press_key(KEY_SPACE)
	assert_true(_view.front() != GalaxyFrontScreen.Front.SCENE, "a key: over")
	assert_true(_view.in_title_loop(), "no place on the table: the high scores")


func test_bat_gives_the_keycard_too() -> void:
	_create_view()
	_view._new_game()
	_run_queue()
	var held: Array[Key] = [KEY_B, KEY_A, KEY_T]
	_view._key_held = func(key: Key) -> bool: return held.has(key)
	_frames(2)
	assert_true(_view.shows_message(), "the box")
	held.clear()
	_press_key(KEY_SPACE)
	var carried := _view.inventory() as Keen5Inventory
	assert_true(carried.keycard, "the keycard")
	assert_equal(carried.shots, GalaxyCheats.ITEM_SHOTS, "99 charges")
	assert_equal(carried.lives, Keen5Inventory.START_LIVES + 1, "a life")


func _create_view() -> void:
	_free_view()
	_release_all()
	var scene := load(VIEW_SCENE) as PackedScene
	_view = scene.instantiate() as Keen5View
	_tree.root.add_child(_view)
	_view._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_view._settings.aspect = DisplaySettings.Aspect.ORIGINAL
	_view._apply_display_settings()
	# Never the player's own table.
	var path := TEST_DIRECTORY.path_join("high_scores.json")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_view._high_scores = GalaxyHighScores.load_from(
		path, GalaxyHighScoreBoard.defaults(_view._data, _view.rules)
	)


func _free_view() -> void:
	if _view != null:
		_view.get_parent().remove_child(_view)
		_view.free()
		_view = null


func _frames(count: int) -> void:
	for frame in count:
		_view._process(FRAME_SECONDS)


func _run_queue() -> void:
	for frame in QUEUE_FRAMES:
		if not _view.shows_message():
			return
		_frames(1)


func _press_key(key: Key) -> void:
	_send(key, 0)


func _type(text: String) -> void:
	for index in text.length():
		_send(OS.find_keycode_from_string(text[index]), text.unicode_at(index))


func _send(key: Key, unicode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.unicode = unicode
	event.pressed = true
	_view._unhandled_input(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	_view._unhandled_input(release)


func _release_all() -> void:
	for action in KeyBindings.all_actions():
		Input.action_release(action)


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file in directory.get_files():
		directory.remove(file)
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
