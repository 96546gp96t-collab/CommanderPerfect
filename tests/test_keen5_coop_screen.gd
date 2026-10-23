extends "res://tests/test_case.gd"
## Tests for two players on one keyboard on Keen 5's real screen
## ([Keen5View] on [GalaxyCoopScreen], milestone E11) with the player's
## files: F7 and the control panel's Two Players card let player 2 join
## and leave in a game (not in the title loop), in a level at once (Keen
## 5's Keen, in his own colours) and from the world map in the next level;
## he walks with his own keys and the screen splits when the Keens are
## apart; on the world map the keys of both steer the one Keen, who rides
## an elevator for both (the panel waits while he rides); a death of
## either costs one life and the Try Again box takes player 2's keys, after
## which he is in the level again; each breaks a fuse of level 4, the fuse
## message (named for online) follows and the level counts 14; saving
## keeps player 2 out. The screen must be in a running scene tree (its
## _ready loads the files), so the suite runs among the tree suites;
## settings and saves go to a folder of their own in the user folder,
## removed afterwards.

const TEST_DIRECTORY := "user://test_keen5_coop_screen"
const VIEW_SCENE := "res://src/keen5/keen5_view.tscn"
const WORLD_MAP := 0
const FIRST_LEVEL := 1
const FUSE_LEVEL := 4
const SAVE_LEVEL := 3
## One logic frame of 2 tics at 70 a second.
const FRAME_SECONDS := 2.0 / 70.0
const LIMIT := 2000
const SPLIT_FRAMES := 100
## Keen stands this far into the left of a door, his feet this far above
## the floor's row (Omni).
const DOOR_SPOT := 96
const STANDING_RISE := 241
const WALK_FRAMES := 30
const SLOT := 1
const CONFIGURE_ROW := 3
const TILE := 256
## The bottom elevator's left half (files); Keen stands two rows below.
const BOTTOM_ELEVATOR := Vector2i(24, 77)
const GATE_LEVEL := 2
## Keen comes down on a fuse at this speed (breaking needs 48).
const POGO_SPEED := 60

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
	_release_all()
	_free_view()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_f7_does_nothing_in_the_title_loop() -> void:
	_create_view()
	_key(KEY_F7)
	assert_true(not _view.has_partner(), "no player 2 in the title loop")


func test_f7_in_a_level_adds_keen_5s_keen_and_removes_him() -> void:
	_create_view()
	_start_game_on(FIRST_LEVEL)
	_key(KEY_F7)
	assert_true(_view.has_partner(), "player 2 plays")
	var partner := _view.partner_keen()
	assert_true(partner is Keen5Keen, "Keen 5's Keen")
	assert_true(_view.session().world.objects.has(partner), "in the world")
	assert_true(partner.inventory == _view.inventory(), "the shared inventory")
	_frames(2)
	var tinted := false
	for item in _view._objects.items():
		if item.node.material is ShaderMaterial:
			tinted = true
	assert_true(tinted, "drawn in player 2's colours")
	_key(KEY_F7)
	assert_true(not _view.has_partner(), "he left")
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
	_view.session().player.god_mode = true
	Input.action_press("p2_left")
	_frames(WALK_FRAMES)
	Input.action_release("p2_left")
	assert_true(partner.position.x < second.x, "player 2 walked left")
	assert_equal(_view.session().player.position.x, first.x, "player 1 stood")
	# At the exit door, far along the level (a wall stops him a few tiles
	# out).
	var exit := _cell_with_info(_view.session().map, Keen5Keen.EXIT_TARGET)
	partner.position = Vector2i(exit.x * TILE + DOOR_SPOT, (exit.y + 1) * TILE - STANDING_RISE)
	partner.reset_box()
	partner.start(partner.actions[&"stand"])
	_frames(SPLIT_FRAMES)
	assert_true(_view.split_view().is_split(), "far apart: the screen splits")
	assert_true(_view._split_view.visible, "the second half shows")


func test_on_the_map_both_steer_the_one_keen_and_he_rides_for_both() -> void:
	_create_view()
	_start_game_on(WORLD_MAP)
	_key(KEY_F7)
	assert_true(_view.has_partner(), "player 2 plays along")
	assert_true(_view.partner_keen() == null, "not on the map")
	_frames(5)
	var map_keen := _view.map_session().keen
	var start := map_keen.position
	Input.action_press("p2_left")
	_frames(WALK_FRAMES)
	Input.action_release("p2_left")
	assert_true(map_keen.position.x < start.x, "player 2's keys walk the one Keen")
	var x := map_keen.position.x
	Input.action_press("p1_right")
	_frames(WALK_FRAMES)
	Input.action_release("p1_right")
	assert_true(map_keen.position.x > x, "and player 1's")
	# To the bottom elevator, as a game saved there would put him; level
	# 2's gate stands in the way until it is done (files).
	_view._game_progress.mark_done(GATE_LEVEL)
	_view._game_progress.map_position = (BOTTOM_ELEVATOR + Vector2i(0, 2)) * TILE
	_view._show_level(WORLD_MAP)
	var keen := _view.map_session().keen as Keen5MapKeen
	var flew := false
	var waited := false
	Input.action_press("p2_up")
	for frame in LIMIT / 4:
		_frames(1)
		var riding := keen.is_flying() or (_view.map_session() as Keen5MapSession).rides()
		flew = flew or keen.is_flying()
		waited = waited or (riding and _view._panel_waits())
		if flew and not riding:
			break
	Input.action_release("p2_up")
	assert_true(flew, "player 2's up takes the one Keen into the elevator")
	assert_true(waited, "the panel waits while he rides")
	assert_true(keen.position.y < BOTTOM_ELEVATOR.y * TILE, "up the shaft")
	_view._show_level(FIRST_LEVEL)
	assert_true(_view.partner_keen() != null, "in the next level player 2 is there")


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
	_press_action("p2_jump", KEY_PERIOD)
	assert_true(_view._choice < 0, "player 2's jump takes the choice")
	waited = _until(func() -> bool: return _view.session() != null)
	assert_true(waited < LIMIT, "the level again")
	assert_equal(_view.map_number(), FIRST_LEVEL, "the same level")
	assert_true(_view.partner_keen() != null, "with player 2")


func test_each_breaks_a_fuse_and_the_fuse_message_follows() -> void:
	_create_view()
	_start_game_on(FUSE_LEVEL)
	_view.toggle_partner()
	_frames(2)
	var session := _view.session() as Keen5LevelSession
	var fuses := _fuse_cells(session.world)
	assert_equal(fuses.size(), 2, "two fuses")
	var keens: Array[GalaxyKeenBody] = [session.player, session.partner]
	var cameras: Array[GalaxyCamera] = [session.camera, session.camera_2]
	for index in keens.size():
		keens[index].god_mode = true
		_pogo_onto(keens[index], cameras[index], fuses[index])
		_until(
			func() -> bool:
				return _view.session() == null or not _is_fuse(session.world, fuses[index])
		)
	var named := false
	for frame in LIMIT:
		if _view.map_session() != null:
			break
		var step := _view._queue.current()
		if step != null and step.image != null:
			var name := _view._box_names.description_of(step.image)
			named = named or (not name.is_empty() and name[0] == Keen5BoxNames.FUSE)
			_key(KEY_SPACE)
		_frames(1)
	assert_true(named, "the fuse message, named for the joiner")
	assert_true(_view.map_session() != null, "back on the map")
	assert_equal(
		_view.progress().done_value(FUSE_LEVEL), Keen5Progress.DONE_BY_FUSE, "the level counts 14"
	)
	assert_true(_view.has_partner(), "player 2 still plays along")


func test_saving_in_a_level_with_player_2_keeps_its_start() -> void:
	_create_view()
	_start_game_on(SAVE_LEVEL)
	_view.toggle_partner()
	var start := _view.session().player.position
	_view.session().player.god_mode = true
	Input.action_press("p1_right")
	_frames(40)
	Input.action_release("p1_right")
	assert_true(_view.session().player.position != start, "player 1 moved")
	_view._save_game(SLOT)
	var saved := Keen5SavedGame.new(_view.rules)
	assert_true(saved.load_dictionary(_view.saves().read(SLOT)), "saved")
	assert_true(saved.in_level(), "in the level")
	assert_equal(saved.frames.size(), 0, "no frames: the level's start")


func test_the_panel_adds_player_2() -> void:
	_create_view()
	_start_game_on(FIRST_LEVEL)
	_view._open_panel()
	var menus := _view.menus()
	menus.top().cursor = CONFIGURE_ROW
	_key(KEY_ENTER)
	assert_true(_pick(GalaxyCoopMenuController.TWO_PLAYERS), "Configure has TWO PLAYERS")
	assert_true(_pick(GalaxyCoopMenuController.PARTNER), "Add Player 2 picked")
	assert_true(_view.has_partner(), "player 2 joined")
	assert_true(_view.partner_keen() != null, "in the level")


func _create_view() -> void:
	_free_view()
	_release_all()
	var scene := load(VIEW_SCENE) as PackedScene
	_view = scene.instantiate() as Keen5View
	_tree.root.add_child(_view)
	_view._user_settings.path = TEST_DIRECTORY.path_join("settings.cfg")
	var episode_settings := TEST_DIRECTORY.path_join("keen5.cfg")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(episode_settings))
	_view._galaxy_settings = GalaxySettings.load_from(episode_settings)
	_view._saves.directory = TEST_DIRECTORY.path_join("saves")
	_view._settings.aspect = DisplaySettings.Aspect.ORIGINAL
	_view._apply_display_settings()


func _free_view() -> void:
	if _view != null:
		_view.get_parent().remove_child(_view)
		_view.free()
		_view = null


## A Normal game, standing on map [param number] (as a loaded game does).
func _start_game_on(number: int) -> void:
	_view._begin_game()
	_view._inventory = _view._new_inventory()
	_view._game_progress = _view._new_progress()
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


## [param keen] on the pogo, coming down fast just over the fuse at
## [param cell], his view [param view] on him.
static func _pogo_onto(keen: GalaxyKeenBody, view: GalaxyCamera, cell: Vector2i) -> void:
	keen.set_action(keen.actions[&"pogo_2"])
	keen.reset_box()
	var bottom := keen.box.bottom - keen.position.y
	var middle := keen.box.middle - keen.position.x
	keen.position = Vector2i(
		GalaxyUnits.from_tile(cell.x) + GalaxyUnits.PER_TILE / 2 - middle,
		GalaxyUnits.from_tile(cell.y) - 1 - bottom - 8
	)
	keen.reset_box()
	keen.jump_timer = 0
	keen.velocity = Vector2i(0, POGO_SPEED)
	view.centre_on(keen.position.x, keen.box.bottom)


## The first cell of [param map] whose info is [param info].
static func _cell_with_info(map: GalaxyMap, info: int) -> Vector2i:
	for y in map.height:
		for x in map.width:
			if map.tile(GalaxyMap.Layer.INFO, x, y) == info:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


static func _fuse_cells(world: GalaxyWorld) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in world.map.height:
		for x in world.map.width:
			if _is_fuse(world, Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	return cells


static func _is_fuse(world: GalaxyWorld, cell: Vector2i) -> bool:
	var tile := world.fore_tile(cell.x, cell.y)
	return world.tile_info.fore(GalaxyTileInfo.Fore.TOP, tile) == Keen5Fuses.FUSE_TOP


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
