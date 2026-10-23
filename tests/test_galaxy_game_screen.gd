extends "res://tests/test_case.gd"
## Checks the shared Galaxy game's screens ([GalaxyLevelScreen],
## [GalaxyPlayScreen]; milestone E3) with a hand-made episode: the
## fixtures' files written to a folder of their own ([code]
## galaxy_file_fixtures.gd[/code]) with the mini levels' tiles and boxes
## ([code]galaxy_game_fixtures.gd[/code]), so no game's files are needed.
## The screen is the node layout of Keen 5's view with the generic script:
## the message without files, a new game's inventory by the rules, a level
## played on the clock with the score box, a map without a level looked
## at, the boxes that hold the game until a key, and the wider view in
## widescreen. The screen needs a running scene tree (its nodes are found
## when it is ready), so the suite runs in the first frame.

const Game := preload("res://tests/galaxy_game_fixtures.gd")
const Keen := preload("res://tests/galaxy_keen_fixtures.gd")
const Files := preload("res://tests/galaxy_file_fixtures.gd")
const Data := preload("res://tests/galaxy_fixtures.gd")

const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const SCREEN_SCRIPT := "res://src/galaxy/game/galaxy_play_screen.gd"
const TEST_DIRECTORY := "user://test_galaxy_game_screen"
const FRAME_SECONDS := 1.0 / 35.0
const WALK_FRAMES := 20
const ROOM_SIZE := Vector2i(20, 14)

var _tree: SceneTree
var _screen: GalaxyPlayScreen


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


func test_without_files_the_screen_says_why() -> void:
	_create(Game.rules())
	assert_true(not _screen._load_data(), "nothing to read")
	assert_equal(_screen._status_label.text, Game.rules().missing_data_message(), "why")


func test_a_new_game_carries_what_the_rules_say() -> void:
	_create_loaded()
	var carried := _screen.inventory()
	assert_equal(carried.lives, Game.START_LIVES, "lives")
	assert_equal(carried.shots, Game.START_SHOTS, "charges")
	assert_equal(carried.next_life_at, Game.FIRST_EXTRA_LIFE, "the first extra life")
	assert_equal(_screen.map_number(), Game.FIRST_LEVEL, "the first level")


func test_a_level_is_played_on_the_clock() -> void:
	_create_loaded()
	var session := _play_room()
	assert_equal(_screen._mode, GameScreen.Mode.LEVEL, "a level")
	assert_true(_screen.session() == session, "this session")
	assert_true(_screen._score_box.visible, "the score box")
	assert_true(_screen._galaxy_map.map == session.map, "its map is drawn")
	assert_true(session.world.sound_player.is_valid(), "sounds go to the screen")
	session.world.play_sound(&"keen_jump")
	var start := session.keen.position.x
	Input.action_press("move_right")
	_frames(WALK_FRAMES)
	Input.action_release("move_right")
	assert_true(session.keen.position.x > start, "Keen walks right")
	assert_true(session.is_playing(), "and plays on")


func test_boxes_hold_the_game_until_a_key() -> void:
	_create_loaded()
	var session := _play_room()
	var called: Array[bool] = []
	var box := Image.create_empty(320, 200, false, Image.FORMAT_RGBA8)
	_screen._show_screens([box], func() -> void: called.append(true))
	assert_true(_screen.shows_message(), "the box is up")
	assert_true(_screen._window_sprite.visible, "drawn")
	var start := session.keen.position.x
	Input.action_press("move_right")
	_frames(WALK_FRAMES)
	Input.action_release("move_right")
	assert_equal(session.keen.position.x, start, "the game stands still")
	assert_true(_screen._queue.press(), "a key")
	assert_equal(called, [true] as Array[bool], "then what follows")
	assert_true(not _screen.shows_message(), "gone")


func test_a_map_without_a_level_is_looked_at() -> void:
	_create_loaded()
	var map := Keen.level(_room(ROOM_SIZE, "k"))
	Keen.put_info(map, Vector2i(2, 2), Game.rules().map_keen_info)
	_screen._start = GalaxyStart.find(map, _screen.rules)
	assert_true(_screen._new_session(map, 0, 0) == null, "no level: Keen is on the map")
	_screen._look_at(map)
	assert_equal(_screen._mode, GameScreen.Mode.LOOK, "looking around")
	assert_true(not _screen._score_box.visible, "no score box")
	assert_true(_screen._keen_item != null, "Keen stands")


func test_widescreen_widens_the_view_that_wakes_objects() -> void:
	_create_loaded()
	var session := _play_room()
	_screen._settings.aspect = DisplaySettings.Aspect.WIDESCREEN
	_screen._apply_display_settings()
	assert_true(session.camera.wide_width > GalaxyCamera.VIEW_PIXELS.x, "wider")
	_screen._settings.aspect = DisplaySettings.Aspect.ORIGINAL
	_screen._apply_display_settings()
	assert_equal(session.camera.wide_width, 0, "the original's view in 4:3")


func _create(rules: GalaxyGameRules) -> void:
	_free_screen()
	var node := (load(VIEW_SCENE) as PackedScene).instantiate()
	node.set_script(load(SCREEN_SCRIPT))
	_screen = node as GalaxyPlayScreen
	_screen.rules = rules
	_tree.root.add_child(_screen)
	_screen._set_up_screen()
	_screen._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_screen._settings.aspect = DisplaySettings.Aspect.ORIGINAL


## A screen with the hand-made episode read.
func _create_loaded() -> void:
	var rules := Game.rules()
	var folder := ProjectSettings.globalize_path(_folder())
	rules.locate_files = func() -> GameFiles: return GameFiles.open(folder, Data.EXTENSION)
	rules.load_data = func(files: GameFiles) -> GalaxyData:
		var data := GalaxyData.load_from(files, Data.episode())
		data.tile_info = Keen.tile_info()
		data.graphics.sprite_infos = Keen.sprite_infos()
		return data
	_create(rules)
	assert_true(_screen._load_data(), "the hand-made episode is read")
	_screen._set_up_play()


## Plays a room as large as the view, Keen on its floor.
func _play_room() -> GalaxyLevelSession:
	var map := Keen.level(_room(ROOM_SIZE, "K"))
	_screen._start = GalaxyStart.find(map, _screen.rules)
	var session := _screen._new_session(map, Game.FIRST_LEVEL, 0)
	_screen._play(session, map)
	return session


static func _room(size: Vector2i, keen: String) -> PackedStringArray:
	var rows := PackedStringArray()
	for row in size.y - 2:
		rows.append(".".repeat(size.x))
	rows.append("...." + keen + ".".repeat(size.x - 5))
	rows.append("#".repeat(size.x))
	return rows


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
