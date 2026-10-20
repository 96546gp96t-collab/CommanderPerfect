extends "res://tests/test_case.gd"
## Tests for a Keen 4 game played online (milestone D12), with two real
## screens ([Keen4View]) in one scene tree, one hosting by IP on this
## machine and one joining it, both with the player's files: the joiner
## sees the host's level, plays player 2 there with the buttons he sends
## (the host's own Keen does not move), his copies of the sprites follow
## the host's, the shared inventory and a changed tile reach him, his death
## shows the Try Again box on both screens, on the world map only the host
## walks, and when he leaves the host plays on alone; when the host stops,
## the joiner is back on his own screen. The screens must be
## in a running scene tree (their _ready loads the files), so the suite is
## skipped in the headless runner's _initialize; settings go to a folder of
## their own in the user folder, removed afterwards.

const TEST_DIRECTORY := "user://test_keen4_online_play"
const VIEW_SCENE := "res://src/keen4/keen4_view.tscn"
const FIRST_LEVEL := 1
const WORLD_MAP := 0
const FRAME_SECONDS := 2.0 / 70.0
const LIMIT := 600
const WALK_FRAMES := 40
const SCORE := 4321
const TILE_CELL := Vector2i(10, 5)

var _tree: SceneTree
var _host: Keen4View
var _joiner: Keen4View


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
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	super.run_all()
	_free_views()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_the_joiner_plays_player_2_in_the_hosts_level() -> void:
	if not _connect(FIRST_LEVEL):
		return
	var partner := _host.partner_keen()
	assert_true(partner != null, "the joiner's Keen is player 2 in the host's level")
	var shown := _pump(func() -> bool: return _joiner.map_number() == FIRST_LEVEL)
	assert_true(shown, "the joiner shows level 1")
	_pump_frames(5)
	assert_true(_joiner._mirrors.size() > 0, "he draws the host's sprites")
	var keen := _host.session().player
	var start := keen.position
	var partner_start := partner.position
	_send_buttons(KeenInput.create(-1))
	_pump_frames(WALK_FRAMES)
	_send_buttons(KeenInput.new())
	_pump_frames(5)
	assert_true(partner.position.x < partner_start.x, "his buttons walk player 2")
	assert_equal(keen.position, start, "not the host's Keen")
	var snapshot := _joiner._remote_snapshot
	assert_true(snapshot != null, "snapshots arrive")
	if snapshot != null:
		var place := _partner_place(snapshot)
		assert_true(place.distance_to(partner.position) < 256 * 2, "his copy is where he is")
	_host.toggle_partner()
	_joiner.toggle_partner()
	assert_true(not _host.has_partner() and not _joiner.has_partner(), "F7 is off online")
	assert_true(_host.partner_keen() == partner, "the joiner keeps his Keen")


func test_the_inventory_and_tiles_reach_the_joiner() -> void:
	if not _connect(FIRST_LEVEL):
		return
	_pump(func() -> bool: return _joiner.map_number() == FIRST_LEVEL)
	_host.inventory().score = SCORE
	var world := _host.session().world
	var tile := world.fore_tile(TILE_CELL.x, TILE_CELL.y) + 1
	world.set_fore_tile(TILE_CELL, tile)
	var arrived := _pump(
		func() -> bool:
			return (
				_joiner.inventory().score == SCORE
				and _joiner._map != null
				and _joiner._map.tile(GalaxyMap.Layer.FOREGROUND, TILE_CELL.x, TILE_CELL.y) == tile
			)
	)
	assert_true(arrived, "the score and the changed tile on the joiner's screen")


func test_the_joiners_death_shows_try_again_on_both() -> void:
	if not _connect(FIRST_LEVEL):
		return
	_pump(func() -> bool: return _joiner.map_number() == FIRST_LEVEL)
	var lives := _host.inventory().lives
	_host.partner_keen().kill()
	var boxed := _pump(
		func() -> bool:
			return (
				_host._choice >= 0
				and not _joiner._remote_box.is_empty()
				and _joiner._remote_box[0] == Keen4BoxNames.Kind.TRY_AGAIN
			)
	)
	assert_true(boxed, "the Try Again box on both screens")
	assert_equal(_host.inventory().lives, lives - 1, "one life for both")
	_pump_frames(5)
	var host_box: PackedInt32Array = _host._score_box._shown
	var joiner_box: PackedInt32Array = _joiner._score_box._shown
	assert_equal(joiner_box, host_box, "both score boxes show the same behind the box")
	assert_equal(host_box[1], lives, "the old lives, as the host's (v1.0) until a frame runs")


func test_on_the_world_map_only_the_host_walks() -> void:
	if not _connect(WORLD_MAP):
		return
	_pump(func() -> bool: return _joiner.is_remote() and _joiner._remote_snapshot != null)
	var map_keen := _host.map_session().keen
	var start := map_keen.position
	_send_buttons(KeenInput.create(1))
	_pump_frames(WALK_FRAMES)
	_send_buttons(KeenInput.new())
	assert_equal(map_keen.position, start, "the joiner's buttons do not walk the map Keen")
	assert_true(_host.partner_keen() == null, "no second Keen on the map")


func test_when_the_joiner_leaves_the_host_plays_on_alone() -> void:
	if not _connect(FIRST_LEVEL):
		return
	_joiner._on_panel_chosen(MenuController.CHOICE_LEAVE_ONLINE, 0)
	var alone := _pump(func() -> bool: return not _host.online().has_partner())
	assert_true(alone, "the host sees him go")
	_pump_frames(3)
	assert_true(_host.partner_keen() == null, "his Keen left the level")
	assert_true(_host.session() != null and _host.session().is_playing(), "the level goes on")
	assert_true(not _joiner.is_remote(), "Leave Game: the joiner is back on his own screen")


func test_when_the_host_stops_the_joiner_goes_back_to_his_own_screen() -> void:
	if not _connect(FIRST_LEVEL):
		return
	_host._on_panel_chosen(MenuController.CHOICE_LEAVE_ONLINE, 0)
	var back := _pump(func() -> bool: return not _joiner.is_remote())
	assert_true(back, "Stop Hosting: the joiner is on his own screen again")
	assert_true(_host.partner_keen() == null, "the host plays alone")
	assert_true(_host.session() != null, "in his level")


## A host on map [param number] and a joiner connected by IP on this
## machine; false (and a failure) when they did not meet.
func _connect(number: int) -> bool:
	_free_views()
	_host = _make_view("host")
	_joiner = _make_view("joiner")
	if _host == null or _joiner == null:
		_fail("Keen 4's screen does not load")
		return false
	_host._begin_game()
	_host._inventory = Keen4Inventory.new_game()
	_host._game_progress = Keen4Progress.new()
	_host._difficulty = GalaxyDifficulty.Level.NORMAL
	_host._show_level(number)
	_host._user_settings.online_name = "Hosty"
	_host.menus().host_locked = false
	_host.online().handle_choice(MenuController.CHOICE_HOST, MenuController.HOST_BY_IP)
	# The window that says how to join, closed as by a key.
	_host.menus().close_all()
	_joiner._user_settings.online_name = "Joiny"
	_joiner.menus().join_address = "127.0.0.1"
	_joiner.menus().join_password = ""
	_joiner.online().handle_choice(MenuController.CHOICE_JOIN_IP, 0)
	var met := _pump(func() -> bool: return _host.online().has_partner() and _joiner.is_remote())
	assert_true(met, "the joiner got in")
	return met


func _make_view(name: String) -> Keen4View:
	var scene := load(VIEW_SCENE) as PackedScene
	if scene == null or not scene.can_instantiate():
		return null
	var view := scene.instantiate() as Keen4View
	if view == null:
		return null
	view.files = Keen4Files.locate()
	_tree.root.add_child(view)
	view._user_settings.path = TEST_DIRECTORY.path_join(name + ".cfg")
	view._keen4_settings.path = TEST_DIRECTORY.path_join(name + "_keen4.cfg")
	view._saves.directory = TEST_DIRECTORY.path_join(name + "_saves")
	return view


func _free_views() -> void:
	for view in [_host, _joiner]:
		if view != null and is_instance_valid(view):
			view.online().leave()
			view.get_parent().remove_child(view)
			view.free()
	_host = null
	_joiner = null


## Runs both screens and their network until [param done]; returns whether
## it came true in time.
func _pump(done: Callable) -> bool:
	for frame in LIMIT:
		if done.call():
			return true
		_pump_frames(1)
	return done.call()


func _pump_frames(count: int) -> void:
	for frame in count:
		for view: Keen4View in [_host, _joiner]:
			view._process(FRAME_SECONDS)
			view.online().session.poll(FRAME_SECONDS)
		OS.delay_msec(2)


## The joiner sends [param input] as his buttons, as his screen does.
func _send_buttons(input: KeenInput) -> void:
	_joiner.online().session.send(OnlineMessages.input(OnlineInput.to_bits(input)), true)


## Where the snapshot draws player 2's Keen (his sprite's place).
static func _partner_place(snapshot: GalaxySnapshot) -> Vector2i:
	for index in snapshot.figure_count():
		var at := index * GalaxySnapshot.FIGURE_FIELDS
		if snapshot.figures[at + 3] & GalaxySnapshot.PARTNER_KEEN:
			return Vector2i(snapshot.figures[at], snapshot.figures[at + 1])
	return Vector2i(-100000, -100000)


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
