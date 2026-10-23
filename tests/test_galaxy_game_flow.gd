extends "res://tests/test_case.gd"
## Checks the flow of a game of the shared Galaxy game ([GalaxyFlowScreen],
## [GalaxyGameBoxes], [GalaxyStatusWindow]; milestone E6) with a hand-made
## episode: the fixtures' files written to a folder of their own
## ([code]galaxy_file_fixtures.gd[/code]; its level names stand in for the
## game's texts and the status labels) with the mini levels' tiles and
## boxes, the screen being the node layout of Keen 5's view with the
## generic script: the world map played, an entrance taken ("One moment",
## the loading box, the fade), a level done marked with its value and the
## way back to the map, a death's box with its choice, no life left, and
## the status window holding the game. The screen needs a running scene
## tree, so the suite runs in the first frame.

const Game := preload("res://tests/galaxy_game_fixtures.gd")
const Keen := preload("res://tests/galaxy_keen_fixtures.gd")
const Files := preload("res://tests/galaxy_file_fixtures.gd")
const Data := preload("res://tests/galaxy_fixtures.gd")
const MapFixtures := preload("res://tests/keen4_map_fixtures.gd")

const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const SCREEN_SCRIPT := "res://src/galaxy/game/galaxy_flow_screen.gd"
const TEST_DIRECTORY := "user://test_galaxy_game_flow"
const FRAME_SECONDS := 1.0 / 35.0
const ROOM_SIZE := Vector2i(20, 14)
## The fixture's level names and entry texts, as a run of texts.
const TEXTS := "fixture texts"
const TEXT_LENGTHS: PackedInt32Array = [10, 9, 26, 22]
const WORLD_FIELD: PackedStringArray = [
	"..............................",
	"..............................",
	"..........M...................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
	"..............................",
]
const BELOW_KEEN := Vector2i(12, 5)
const LEVEL := 3
## The loading box: the box and five fingers, three fade steps, black,
## three more.
const LOADING_STEPS := 13
const WALK_FRAMES := 6
const DEATH_FRAMES := 200
const STATUS_FRAMES := 60

var _tree: SceneTree
var _screen: GalaxyFlowScreen


## The boxes with blank loading screens: the fixture has two pictures, not
## the count-down's six.
class QuietBoxes:
	extends GalaxyGameBoxes

	static func like(boxes: GalaxyGameBoxes) -> QuietBoxes:
		var quiet := QuietBoxes.new()
		quiet._rules = boxes._rules
		quiet._graphics = boxes._graphics
		quiet._names = boxes._names
		quiet._entries = boxes._entries
		quiet._game = boxes._game
		return quiet

	func entering(_map: int) -> Array[Image]:
		var screens: Array[Image] = []
		for screen in FINGER_PICTURES + 1:
			screens.append(
				Image.create_empty(
					GalaxyWindow.SCREEN_SIZE.x,
					GalaxyWindow.SCREEN_SIZE.y,
					false,
					Image.FORMAT_RGBA8
				)
			)
		return screens


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
	_release_all()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_a_new_game_has_its_progress_boxes_and_window() -> void:
	_create_loaded()
	assert_true(_screen.progress() is GalaxyProgress, "the progress")
	assert_true(_screen.progress().done_levels().is_empty(), "nothing done")
	assert_true(_screen._boxes != null and _screen._status != null, "the boxes and the window")
	assert_true(not _screen.shows_status(), "the window is up")


func test_the_world_map_is_played_and_an_entrance_loads_its_level() -> void:
	_create_loaded()
	var on_map := _play_world_map()
	assert_true(_screen.map_session() == on_map, "the world map is played")
	assert_equal(_screen._mode, GameScreen.Mode.LEVEL, "on the clock")
	assert_true(_screen._score_box.visible, "with the score box")
	var start := on_map.keen.position.x
	Input.action_press("move_right")
	_frames(WALK_FRAMES)
	Input.action_release("move_right")
	assert_true(on_map.keen.position.x > start, "Keen walks")
	_put_entrance_under_keen(on_map)
	Input.action_press("jump")
	_frames(2)
	Input.action_release("jump")
	assert_equal(_screen.progress().map_position, on_map.keen.map_position, "where he stood")
	var steps := _screen.queue().steps
	assert_equal(steps.size(), 1 + LOADING_STEPS, "One moment, then the loading box")
	assert_equal(steps[0].tics, GalaxyFlowScreen.ONE_MOMENT_TICS, "One moment: 28 tics")
	assert_equal(steps[1].tics, GalaxyFlowScreen.BOX_TICS, "the box")
	var black := steps[1 + GalaxyFlowScreen.FADE_STEPS.size() + 6]
	assert_equal(black.brightness, 0.0, "black")
	assert_true(black.start.is_valid(), "the map is shown while it is black")


func test_a_level_done_is_marked_and_the_way_leads_to_the_map() -> void:
	_create_loaded()
	var session := _play_room()
	_screen._map_number = LEVEL
	session.world.complete(&"")
	_frames(3)
	assert_true(_screen.session() == null, "the level is over")
	assert_equal(_screen.progress().done_value(LEVEL), GalaxyProgress.DONE, "done with 1")
	assert_equal(_screen.progress().last_finished, LEVEL, "just finished")
	assert_equal(_screen.queue().steps.size(), LOADING_STEPS, "the map's box, no One moment")


func test_a_death_offers_try_again_or_the_map() -> void:
	_create_loaded()
	var session := _play_room()
	_screen._map_number = LEVEL
	var lives := _screen.inventory().lives
	session.keen.kill()
	for frame in DEATH_FRAMES:
		_frames(1)
		if _screen._choice >= 0:
			break
	assert_equal(_screen._choice, GalaxyFlowScreen.TRY_AGAIN, "the box, Try Again chosen")
	assert_equal(_screen.inventory().lives, lives - 1, "a life less")
	assert_true(_screen.shows_message(), "the box is up")
	var first := _screen.queue().current().image
	Input.action_press("move_down")
	_send_key(KEY_DOWN)
	Input.action_release("move_down")
	assert_equal(_screen._choice, GalaxyFlowScreen.EXIT_TO_MAP, "down: the exit")
	assert_true(_screen.queue().current().image != first, "drawn again")
	var before := _screen.queue().current().image
	_frames(10)
	assert_true(_screen.queue().current().image != before, "the frame blinks")
	_send_key(KEY_ENTER)
	assert_equal(_screen._choice, -1, "taken")
	assert_equal(_screen.queue().steps.size(), LOADING_STEPS, "to the map, behind its box")


func test_no_life_left_ends_the_game() -> void:
	_create_loaded()
	var session := _play_room()
	_screen.inventory().lives = 0
	session.keen.kill()
	for frame in DEATH_FRAMES:
		_frames(1)
		if _screen.shows_message():
			break
	assert_equal(_screen._choice, -1, "no choice")
	assert_equal(_screen.queue().steps.size(), 1, "the game-over box")
	assert_equal(_screen.queue().current().tics, GalaxyFlowScreen.GAME_OVER_TICS, "4.76 s")
	assert_equal(_screen.queue().then.get_method(), &"_game_ended", "then the game ends")
	_screen._queue.clear()


func test_the_status_window_holds_the_game() -> void:
	_create_loaded()
	var on_map := _play_world_map()
	var status := InputEventAction.new()
	status.action = &"status"
	status.pressed = true
	assert_true(_screen._flow_input(status), "the status key")
	assert_true(_screen.shows_status(), "it drops")
	assert_true(_screen._status_sprites[GalaxyFlowScreen.StatusPart.WINDOW].visible, "drawn")
	var start := on_map.keen.position
	Input.action_press("move_right")
	_frames(STATUS_FRAMES)
	Input.action_release("move_right")
	assert_equal(on_map.keen.position, start, "the game stands still")
	_send_key(KEY_SPACE)
	_frames(STATUS_FRAMES)
	assert_true(not _screen.shows_status(), "a key lifts it")


func test_the_boxes_and_the_window_follow_the_rules() -> void:
	_create_loaded()
	var boxes := _screen._boxes
	assert_equal(boxes.game_text(1), Data.LEVEL_NAMES[1], "the rules' run of texts")
	assert_equal(boxes.one_moment().get_size(), GalaxyWindow.SCREEN_SIZE, "a whole screen")
	assert_true(boxes.game_over() != null, "a game-over box by the rules")
	assert_true(
		GalaxyGameBoxes.blink_color(0) != GalaxyGameBoxes.blink_color(16), "blinks every 16 tics"
	)
	_screen.rules.game_over_text = -1
	assert_true(boxes.game_over() == null, "none for an episode without the text")
	var window := _screen._status
	assert_equal(window.label(GalaxyStatusWindow.Text.SCORE), Data.LEVEL_NAMES[1], "its labels")
	assert_equal(window.key_tiles_at, GalaxyStatusWindow.KEEN_4_KEY_TILES_AT, "Keen 4's place")
	var picture := window.window(0, _screen.inventory(), _screen.progress(), 1)
	assert_equal(picture.get_size(), GalaxyWindow.SCREEN_SIZE, "on a whole screen")
	var inside := GalaxyStatusWindow.INSIDE.position + Vector2i(2, 2)
	assert_equal(picture.get_pixelv(inside), GalaxyStatusWindow.GREY, "grey inside")


func _create_loaded() -> void:
	_free_screen()
	_release_all()
	var rules := Game.rules()
	rules.game_texts = TEXTS
	rules.status_texts = TEXTS
	rules.game_over_text = 0
	rules.try_again_intro_text = 1
	rules.try_again_text = 2
	rules.exit_text = 3
	rules.one_moment_text = 0
	var folder := ProjectSettings.globalize_path(_folder())
	rules.locate_files = func() -> GameFiles: return GameFiles.open(folder, Data.EXTENSION)
	rules.load_data = func(files: GameFiles) -> GalaxyData:
		var episode := Data.episode()
		episode.text_lengths = {TEXTS: TEXT_LENGTHS}
		var data := GalaxyData.load_from(files, episode)
		data.tile_info = MapFixtures.tile_info()
		data.graphics.sprite_infos = Keen.sprite_infos()
		return data
	var node := (load(VIEW_SCENE) as PackedScene).instantiate()
	node.set_script(load(SCREEN_SCRIPT))
	_screen = node as GalaxyFlowScreen
	_screen.rules = rules
	_tree.root.add_child(_screen)
	_screen._set_up_screen()
	_screen._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_screen._settings.aspect = DisplaySettings.Aspect.ORIGINAL
	assert_true(_screen._load_data(), "the hand-made episode is read")
	_screen._set_up_play()
	_screen._set_up_flow()
	_screen._boxes = QuietBoxes.like(_screen._boxes)


func _play_world_map() -> GalaxyMapSession:
	var map := MapFixtures.map(WORLD_FIELD)
	_screen._map_number = Game.WORLD_MAP
	_screen._start = GalaxyStart.find(map, _screen.rules)
	var on_map := _screen._new_map_session(map, 0)
	_screen._play_map(on_map)
	return on_map


func _put_entrance_under_keen(on_map: GalaxyMapSession) -> void:
	var box := on_map.keen.box
	on_map.world.set_info(Vector2i(box.tile_middle, box.tile_bottom), 0xC000 + LEVEL)


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
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	_screen._flow_input(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	_screen._flow_input(release)


func _frames(count: int) -> void:
	for frame in count:
		_screen._process(FRAME_SECONDS)


func _release_all() -> void:
	for action in KeyBindings.all_actions():
		Input.action_release(action)


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
