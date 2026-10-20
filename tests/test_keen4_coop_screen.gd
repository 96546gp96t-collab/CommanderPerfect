extends "res://tests/test_case.gd"
## Tests for two players on one keyboard on Keen 4's real screen
## ([Keen4View], milestone D12) with the player's files: F7 and the control
## panel's Two Players card let player 2 join and leave in a game (not in
## the title loop), in a level at once and from the world map in the next
## level; he walks with his own keys and in his own colours, and the screen
## splits when the Keens are apart; on the map the keys of both steer the
## one Keen; a death of either costs one life and the Try Again box takes
## player 2's keys, after which he is in the level again; he rescues a
## council member, takes the wetsuit and the eighth rescue starts the
## ending as alone; saving keeps player 2 out (a level he played in is
## saved at its start). The screen must be in a running scene tree (its
## _ready loads the files), so the suite is skipped in the headless
## runner's _initialize; settings and saves go to a folder of their own in
## the user folder, removed afterwards.

const TEST_DIRECTORY := "user://test_keen4_coop_screen"
const VIEW_SCENE := "res://src/keen4/keen4_view.tscn"
const WORLD_MAP := 0
const FIRST_LEVEL := 1
const COUNCIL_LEVEL := 3
const WETSUIT_LEVEL := 9
const WELL := 17
## One logic frame of 2 tics at 70 a second.
const FRAME_SECONDS := 2.0 / 70.0
const LIMIT := 2000
const SPLIT_FRAMES := 200
const SLOT := 1
const CONFIGURE_ROW := 3

var _view: Keen4View
var _tree: SceneTree


func _init() -> void:
	if Keen4Files.locate() == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_tree = Engine.get_main_loop() as SceneTree
	if _tree == null or not _tree.root.is_inside_tree():
		skip("needs a running scene tree (the screen loads its files when it is ready)")


func run_all() -> void:
	if not skip_reason.is_empty():
		return
	var probe := _instantiate()
	if probe == null:
		failures.append("run_all: Keen 4's screen does not load")
		return
	probe.free()
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	KeyBindings.reset()
	super.run_all()
	_release_all()
	_free_view()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_f7_does_nothing_in_the_title_loop() -> void:
	_create_view()
	_key(KEY_F7)
	assert_true(not _view.has_partner(), "no player 2 in the title loop")


func test_f7_in_a_level_adds_player_2_and_removes_him() -> void:
	_create_view()
	_start_game_on(FIRST_LEVEL)
	_key(KEY_F7)
	assert_true(_view.has_partner(), "player 2 plays")
	var partner := _view.partner_keen()
	assert_true(partner != null, "his Keen is in the level")
	assert_true(_view.session().world.objects.has(partner), "in the world")
	assert_equal(partner.position, _view.session().player.position, "where player 1 is")
	_frames(2)
	var tinted := false
	for item in _view._objects.items():
		if item.node.material is ShaderMaterial:
			tinted = true
	assert_true(tinted, "drawn in player 2's colours")
	_key(KEY_F7)
	assert_true(not _view.has_partner(), "he left")
	assert_true(_view.partner_keen() == null, "his Keen is gone")
	assert_true(not _view.session().world.objects.has(partner), "out of the world")


func test_player_2_walks_on_his_keys_and_the_screen_splits() -> void:
	_create_view()
	_start_game_on(FIRST_LEVEL)
	_view.toggle_partner()
	var partner := _view.partner_keen()
	_frames(3)
	assert_true(not _view.split_view().is_split(), "together: one screen")
	var first := _view.session().player.position
	var second := partner.position
	partner.god_mode = true
	Input.action_press("p2_left")
	_frames(SPLIT_FRAMES)
	Input.action_release("p2_left")
	assert_true(partner.position.x < second.x - 10 * 256, "player 2 walked left")
	assert_equal(_view.session().player.position.x, first.x, "player 1 stood")
	assert_true(_view.split_view().is_split(), "far apart: the screen splits")
	var views := _view.split_view().views
	assert_true(views[0] != views[1], "two views")


func test_f7_on_the_map_joins_in_the_next_level() -> void:
	_create_view()
	_start_game_on(WORLD_MAP)
	assert_true(_view.map_session() != null, "on the world map")
	_key(KEY_F7)
	assert_true(_view.has_partner(), "player 2 plays along")
	assert_true(_view.partner_keen() == null, "not on the map")
	_frames(5)
	var map_keen := _view.map_session().keen
	var start := map_keen.position
	Input.action_press("p2_right")
	_frames(30)
	Input.action_release("p2_right")
	assert_true(map_keen.position.x > start.x, "player 2's keys walk the one Keen")
	var x := map_keen.position.x
	Input.action_press("p1_left")
	_frames(30)
	Input.action_release("p1_left")
	assert_true(map_keen.position.x < x, "and player 1's")
	_view._show_level(FIRST_LEVEL)
	assert_true(_view.partner_keen() != null, "in the next level he is there")


func test_the_well_has_two_swimmers() -> void:
	_create_view()
	_start_game_on(WELL)
	_view.toggle_partner()
	assert_true(_view.partner_keen() is Keen4SwimmingKeen, "player 2 swims")


func test_player_2_dying_costs_a_life_and_his_keys_try_again() -> void:
	_create_view()
	_start_game_on(FIRST_LEVEL)
	_view.toggle_partner()
	var lives := _view.inventory().lives
	_frames(3)
	_view.partner_keen().kill()
	var waited := _until(func() -> bool: return _view._choice >= 0)
	assert_true(waited < LIMIT, "the Try Again box")
	assert_equal(_view.inventory().lives, lives - 1, "one life for both")
	assert_true(_view.session() == null, "the level stopped")
	_press_action("p2_jump", KEY_PERIOD)
	assert_true(_view._choice < 0, "player 2's jump takes the choice")
	waited = _until(func() -> bool: return _view.session() != null)
	assert_true(waited < LIMIT, "the level again")
	assert_equal(_view.map_number(), FIRST_LEVEL, "the same level")
	assert_true(_view.partner_keen() != null, "with player 2")


func test_player_2_rescues_a_council_member() -> void:
	_create_view()
	_start_game_on(COUNCIL_LEVEL)
	_view.toggle_partner()
	var rescued := _view.progress().rescued
	_frames(2)
	var waited := _rescue_with_partner()
	assert_true(waited < LIMIT, "the level ends")
	assert_equal(_view.progress().rescued, rescued + 1, "a rescue")
	assert_true(_view.progress().is_done(COUNCIL_LEVEL), "the level is done")
	_skip_boxes_until(func() -> bool: return _view.map_session() != null)
	assert_true(_view.map_session() != null, "back on the map after the messages")
	assert_true(_view.has_partner(), "player 2 still plays along")


func test_player_2_takes_the_wetsuit() -> void:
	_create_view()
	_start_game_on(WETSUIT_LEVEL)
	_view.toggle_partner()
	_frames(2)
	_put_partner_on(Keen4Wetsuit)
	_until(func() -> bool: return _view.session() == null)
	assert_true(_view.progress().wetsuit, "the wetsuit is the game's")


func test_the_eighth_rescue_by_player_2_starts_the_ending() -> void:
	_create_view()
	_start_game_on(COUNCIL_LEVEL)
	_view._game_progress.rescued = 7
	_view.toggle_partner()
	_frames(2)
	_rescue_with_partner()
	_skip_boxes_until(func() -> bool: return _view._front == Keen4FrontScreen.Front.ENDING)
	assert_equal(_view._front, Keen4FrontScreen.Front.ENDING, "the ending, as alone")
	_key(KEY_F7)
	assert_true(_view.has_partner(), "F7 changes nothing in the ending")


func test_saving_in_a_level_with_player_2_keeps_its_start() -> void:
	_create_view()
	_start_game_on(4)
	_view.toggle_partner()
	var start := _view.session().player.position
	Input.action_press("p1_right")
	_frames(40)
	Input.action_release("p1_right")
	assert_true(_view.session().player.position != start, "player 1 moved")
	_view._save_game(SLOT)
	var saved := Keen4SavedGame.from_dictionary(_view.saves().read(SLOT))
	assert_true(saved != null and saved.in_level(), "saved in the level")
	assert_equal(saved.map_number, 4, "level 4")
	assert_equal(saved.frames.size(), 0, "no frames: the level's start")
	_view._load_game(SLOT)
	_until(func() -> bool: return _view._replay == null and _view.session() != null)
	assert_equal(_view.session().player.position, start, "loaded at the level's start")


func test_saving_alone_keeps_the_frames() -> void:
	_create_view()
	_start_game_on(4)
	Input.action_press("move_right")
	_frames(40)
	Input.action_release("move_right")
	_view._save_game(SLOT)
	var saved := Keen4SavedGame.from_dictionary(_view.saves().read(SLOT))
	assert_true(saved.frames.size() > 0, "alone the frames are saved, as in D10")


func test_saving_on_the_map_has_nothing_of_player_2() -> void:
	_create_view()
	_start_game_on(WORLD_MAP)
	_view._save_game(SLOT)
	var alone := _view.saves().read(SLOT)
	_view.toggle_partner()
	_view._save_game(SLOT + 1)
	var together := _view.saves().read(SLOT + 1)
	assert_equal(together.keys(), alone.keys(), "the same fields")
	var game: Dictionary = together.get("game", together)
	var game_alone: Dictionary = alone.get("game", alone)
	assert_equal(str(game), str(game_alone), "the same game")


func test_the_panel_adds_player_2() -> void:
	_create_view()
	_start_game_on(FIRST_LEVEL)
	_view._open_panel()
	var menus := _view.menus()
	menus.top().cursor = CONFIGURE_ROW
	_key(KEY_ENTER)
	assert_true(_pick(GalaxyCoopMenuController.TWO_PLAYERS), "Configure has TWO PLAYERS")
	assert_true(_label_of(GalaxyCoopMenuController.PARTNER) == "ADD PLAYER 2", "Add Player 2")
	assert_true(_pick(GalaxyCoopMenuController.PARTNER), "picked")
	assert_true(_view.has_partner(), "player 2 joined")
	assert_true(_view.partner_keen() != null, "in the level")


func test_the_panel_offers_no_partner_out_of_a_game() -> void:
	_create_view()
	_view._open_panel()
	var menus := _view.menus()
	menus.top().cursor = CONFIGURE_ROW
	_key(KEY_ENTER)
	_pick(GalaxyCoopMenuController.TWO_PLAYERS)
	var item := _item_of(GalaxyCoopMenuController.PARTNER)
	assert_true(item != null and not item.enabled, "Add Player 2 cannot be picked")


func _create_view() -> void:
	_free_view()
	_release_all()
	_view = _instantiate()
	_view.files = Keen4Files.locate()
	_tree.root.add_child(_view)
	_view._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	_view._keen4_settings.path = TEST_DIRECTORY.path_join("keen4.cfg")
	_view._saves.directory = TEST_DIRECTORY.path_join("saves")


## A new Keen 4 screen, or null when its scene does not load.
static func _instantiate() -> Keen4View:
	var scene := load(VIEW_SCENE) as PackedScene
	if scene == null or not scene.can_instantiate():
		return null
	var node := scene.instantiate()
	if not node is Keen4View:
		if node != null:
			node.free()
		return null
	return node as Keen4View


func _free_view() -> void:
	if _view != null:
		_view.get_parent().remove_child(_view)
		_view.free()
		_view = null


## A Normal game, standing on map [param number] (as a loaded game does).
func _start_game_on(number: int) -> void:
	_view._begin_game()
	_view._inventory = Keen4Inventory.new_game()
	_view._game_progress = Keen4Progress.new()
	_view._difficulty = GalaxyDifficulty.Level.NORMAL
	_view._show_level(number)


func _frames(count: int) -> void:
	for frame in count:
		_view._process(FRAME_SECONDS)


## Runs frames until [param done]; returns how many it took (LIMIT: never).
func _until(done: Callable) -> int:
	for frame in LIMIT:
		if done.call():
			return frame
		_frames(1)
	return LIMIT


## Runs frames and presses Space for every box, until [param done].
func _skip_boxes_until(done: Callable) -> void:
	for frame in LIMIT:
		if done.call():
			return
		if not _view._queue.is_empty():
			_key(KEY_SPACE)
		_frames(1)


## Player 2's Keen, in god mode, falling onto the floor where the first
## object of [param type] is, with his view on him.
func _put_partner_on(type: Script) -> void:
	var target: GalaxyObject
	for object in _view.session().world.objects:
		if is_instance_of(object, type):
			target = object
			break
	assert_true(target != null, "the level has a %s" % type.get_global_name())
	if target == null:
		return
	var partner := _view.partner_keen()
	partner.god_mode = true
	partner.position = Vector2i(target.position.x, target.box.bottom - 511)
	partner.reset_box()
	partner.set_action(partner.actions[&"fall_1"])
	# His view goes with him, so that what is there wakes up.
	_view.session().camera_2.centre_on(partner.position.x, partner.box.bottom)


## Keeps player 2 falling onto the walking council member until the level
## ends; returns the frames it took (LIMIT: never).
func _rescue_with_partner() -> int:
	_put_partner_on(Keen4Council)
	var member: GalaxyObject
	for object in _view.session().world.objects:
		if object is Keen4Council:
			member = object
	for frame in LIMIT:
		if _view.session() == null:
			return frame
		var partner := _view.partner_keen()
		partner.position.x = member.position.x
		partner.reset_box()
		_frames(1)
	return LIMIT


func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	_view._unhandled_input(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	_view._unhandled_input(release)


## Holds [param action] while its key [param key] is pressed on the screen.
func _press_action(action: String, key: Key) -> void:
	Input.action_press(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	_view._unhandled_input(event)
	Input.action_release(action)


func _release_all() -> void:
	for action in KeyBindings.all_actions():
		Input.action_release(action)


func _item_of(id: StringName) -> Menu.Item:
	for item in _view.menus().top().items:
		if item.id == id:
			return item
	return null


func _label_of(id: StringName) -> String:
	var item := _item_of(id)
	return item.label if item != null else ""


## Moves the panel's cursor to the choice [param id] and picks it.
func _pick(id: StringName) -> bool:
	var menu := _view.menus().top()
	for index in menu.items.size():
		if menu.items[index].id == id:
			menu.cursor = index
			_key(KEY_ENTER)
			return true
	return false


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
