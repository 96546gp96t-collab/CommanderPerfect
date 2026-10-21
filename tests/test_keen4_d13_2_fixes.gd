extends "res://tests/test_case.gd"
## Tests for the three fixes of D13.2 on Keen 4's real screen ([Keen4View])
## with the player's files:
##   - split screen: each half moves for its own Keen looking down, as the
##     view does for one player; one shared view does not move for it;
##   - pauses: while the game stands still (the status window, the control
##     panel, the box after a death, the boxes after walking out of a
##     level, the status window on the world map) every sprite and the view
##     stay exactly where they were drawn, frame after frame, with smooth
##     motion on (before, they trembled between two logic frames);
##   - the testing cheats of Keen 1-3: Shift+G god mode and Shift+I all four
##     gems and 99 charges, in a level and on the world map, with Keen 1-3's
##     messages.
## The screen must be in a running scene tree (its _ready loads the files),
## so the suite runs among the runner's tree suites; settings and saves go
## to a folder of their own in the user folder, removed afterwards.

const TEST_DIRECTORY := "user://test_keen4_d13_2_fixes"
const VIEW_SCENE := "res://src/keen4/keen4_view.tscn"
const WORLD_MAP := 0
const FIRST_LEVEL := 1
## One logic frame of 2 tics at 70 a second.
const FRAME_SECONDS := 2.0 / 70.0
## Screen frames of uneven lengths (a 144 Hz screen and worse), so that the
## clock's blend takes many values while the game stands still.
const UNEVEN_SECONDS: Array[float] = [0.0069, 0.0113, 0.0041, 0.0157, 0.0083, 0.0021, 0.0129]
const STILL_FRAMES := 60
const LIMIT := 2000
const SPLIT_FRAMES := 200
## The global random seed for the walk apart, so that it is the same walk
## every time.
const SPLIT_SEED := 1
## Holding down long enough for the whole look down (30 tics, then 1 pixel
## a tic up to 107 pixels).
const LOOK_FRAMES := 120
## How far a look up at least moves player 1's half (27 pixels alone).
const LOOK_UP_SHIFT := 20
## Pixels two views may differ by and still count as the same place (his
## picture's middle changes with the looking sprite).
const SAME_PIXELS := 4
const ITEM_SHOTS := 99
## Points of the control panel's picture outside the online page's box.
const WATCH_SPOTS: Array[Vector2i] = [
	Vector2i(2, 2), Vector2i(317, 2), Vector2i(2, 197), Vector2i(317, 197), Vector2i(40, 100)
]
## Level 9 (Miragia): the glass column next to Keen's start, where it
## stands in the walkway's band (a hole in the floor) and above it (glass
## the picture shows through), and a cell of open sky at the top.
const GLASS_LEVEL := 9
const FLOOR_HOLE_CELL := Vector2i(12, 69)
const GLASS_CELL := Vector2i(12, 60)
const OPEN_CELL := Vector2i(30, 3)
const TILE_PIXELS := 16

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


# --- Bug 1: looking up and down in the split screen ---------------------


func test_a_split_half_moves_for_its_keen_looking_up_and_down() -> void:
	_split_apart()
	assert_true(_view.split_view().is_split(), "far apart: the screen splits")
	_assert_half_follows_look("p1_up", -1)
	_assert_half_follows_look("p1_down", 1)


## Player 1 holds [param action]: his own camera looks ([param sign]: -1
## up, 1 down) and his half moves as his own view does; player 2's stays.
func _assert_half_follows_look(action: String, sign: int) -> void:
	var camera := _view.session().camera
	var before: Array[Rect2i] = _view.split_view().views.duplicate()
	var area := camera.area_pixels()
	# As alone, the view never goes beyond the area between the blocks.
	var room := area.end.y - before[0].end.y if sign > 0 else before[0].position.y - area.position.y
	Input.action_press(action)
	_frames(LOOK_FRAMES)
	var looking: Array[Rect2i] = _view.split_view().views.duplicate()
	var look := camera.look_pixels()
	Input.action_release(action)
	_frames(LOOK_FRAMES)
	var shift := (looking[0].position.y - before[0].position.y) * sign
	assert_true(look * sign > 0, "%s: his own camera looks" % action)
	assert_true(
		shift >= mini(room, LOOK_UP_SHIFT) - SAME_PIXELS and shift <= absi(look) + SAME_PIXELS,
		(
			"%s: player 1's half moved with his look: %d (look %d, room %d)"
			% [action, shift, look, room]
		)
	)
	assert_true(
		absi(looking[1].position.y - before[1].position.y) <= SAME_PIXELS,
		"%s: player 2's half stayed" % action
	)
	assert_true(_keen_in(looking[0], _view.session().player), "player 1 is in his view")
	# Back to his resting place: a jump (the look stays while he stands).
	Input.action_press("p1_jump")
	_frames(2)
	Input.action_release("p1_jump")
	_frames(LOOK_FRAMES)
	assert_equal(camera.look_pixels(), 0, "%s: after a jump his camera rests" % action)


func test_one_shared_view_does_not_move_for_one_keen_looking() -> void:
	_create_view()
	_start_game_on(FIRST_LEVEL)
	_view.toggle_partner()
	_frames(3)
	assert_true(not _view.split_view().is_split(), "together: one screen")
	var before := _view.split_view().views[0].position.y
	Input.action_press("p1_up")
	_frames(LOOK_FRAMES)
	Input.action_release("p1_up")
	assert_true(_view.session().camera.look_pixels() < 0, "player 1 looks up")
	assert_true(not _view.split_view().is_split(), "still one screen")
	# Only the middle of his picture moves it (a few pixels), not the look.
	var moved := _view.split_view().views[0].position.y - before
	assert_true(absi(moved) < LOOK_UP_SHIFT, "the shared view stays: %d" % moved)


# --- Bug 2: everything stands still while the game waits ---------------


func test_the_status_window_in_a_level_keeps_everything_still() -> void:
	_walk_in(FIRST_LEVEL, true)
	_key(KEY_ENTER)
	_frames(1)
	assert_true(_view.shows_status(), "the status window is down")
	_assert_stands_still("status window in a level")


func test_the_control_panel_keeps_everything_still() -> void:
	_walk_in(FIRST_LEVEL, true)
	_key(KEY_ESCAPE)
	_frames(1)
	assert_true(_view._panel.is_open(), "the control panel is open")
	_assert_stands_still("control panel")


func test_the_box_after_a_death_keeps_everything_still() -> void:
	_walk_in(FIRST_LEVEL, true)
	_view.session().player.god_mode = false
	_view.session().player.kill()
	var frames := _until(func() -> bool: return _view._choice >= 0)
	assert_true(frames < LIMIT, "the box after the death comes")
	_frames(1)
	_assert_stands_still("Try Again box")


func test_walking_out_of_a_level_keeps_keen_still() -> void:
	_create_view()
	_view._settings.smooth_motion = true
	_start_game_on(FIRST_LEVEL)
	var keen := _view.session().player
	Input.action_press("move_left")
	_uneven_until_moving(20)
	# The level's left edge just before him: his next step walks out.
	_view.session().camera._min.x = keen.box.left - 1
	var frames := _until(func() -> bool: return _view.session() == null)
	Input.action_release("move_left")
	assert_true(frames < LIMIT, "Keen walked out")
	assert_true(_view.shows_message(), "the boxes after the level")
	_frames(1)
	_assert_stands_still("walking out")


func test_the_status_window_on_the_map_keeps_everything_still() -> void:
	_create_view()
	_view._settings.smooth_motion = true
	_start_game_on(WORLD_MAP)
	_frames(5)
	Input.action_press("move_right")
	_uneven_until_moving(20)
	_key(KEY_ENTER)
	Input.action_release("move_right")
	_frames(1)
	assert_true(_view.shows_status(), "the status window is down")
	_assert_stands_still("status window on the map")


func test_without_smooth_motion_a_pause_keeps_everything_still_too() -> void:
	_create_view()
	_view._settings.smooth_motion = false
	_start_game_on(FIRST_LEVEL)
	Input.action_press("move_right")
	_uneven_until_moving(20)
	_key(KEY_ENTER)
	Input.action_release("move_right")
	_frames(1)
	_assert_stands_still("status window, smooth motion off")


# --- Bug 3: Shift+G and Shift+I as in Keen 1-3 -------------------------


func test_shift_g_toggles_god_mode_in_a_level_with_the_message() -> void:
	_create_view()
	_start_game_on(FIRST_LEVEL)
	_shift_key(KEY_G)
	assert_true(_view.session().player.god_mode, "god mode on")
	assert_equal(_view._message, "Cheat: god mode on", "Keen 1-3's message")
	_shift_key(KEY_G)
	assert_true(not _view.session().player.god_mode, "god mode off")
	assert_equal(_view._message, "Cheat: god mode off", "Keen 1-3's message")


func test_shift_g_on_the_map_holds_for_the_next_level() -> void:
	_create_view()
	_start_game_on(WORLD_MAP)
	_shift_key(KEY_G)
	assert_equal(_view._message, "Cheat: god mode on", "the message on the map")
	_view._show_level(FIRST_LEVEL)
	assert_true(_view.session().player.god_mode, "god mode in the level")


func test_shift_g_covers_player_2_too() -> void:
	_create_view()
	_start_game_on(FIRST_LEVEL)
	_view.toggle_partner()
	_shift_key(KEY_G)
	assert_true(_view.partner_keen().god_mode, "player 2 in god mode")


func test_shift_i_in_a_level_gives_the_gems_and_99_charges() -> void:
	_create_view()
	_start_game_on(FIRST_LEVEL)
	var lives := _view.inventory().lives
	_shift_key(KEY_I)
	_assert_everything(lives)
	assert_true(not _view.shows_message(), "no box (B+A+T has one)")
	var frames := _view._recording.frames
	assert_equal(
		frames.slice(frames.size() - 2),
		PackedByteArray([Keen4SavedGame.Event.EVERYTHING, 0]),
		"kept among a saved level's frames"
	)


func test_shift_i_on_the_map_gives_the_gems_and_99_charges() -> void:
	_create_view()
	_start_game_on(WORLD_MAP)
	var lives := _view.inventory().lives
	_shift_key(KEY_I)
	_assert_everything(lives)


func test_shift_i_does_nothing_in_the_title_loop() -> void:
	_create_view()
	_shift_key(KEY_I)
	assert_equal(_view.inventory().gems, PackedInt32Array([0, 0, 0, 0]), "no gems")


func test_a_saved_shift_i_is_given_again_when_the_level_is_loaded() -> void:
	var inventory := Keen4Inventory.new_game()
	var recorded := PackedByteArray()
	Keen4SavedGame.record_event(recorded, Keen4SavedGame.Event.EVERYTHING)
	var session := Keen4LevelSession.new()
	session.inventory = inventory
	Keen4SavedGame._apply(session, recorded[0])
	assert_equal(inventory.gems, PackedInt32Array([1, 1, 1, 1]), "the gems")
	assert_equal(inventory.shots, ITEM_SHOTS, "99 charges")


# --- Bug 4: the online pages over the wrist watch ----------------------


func test_the_online_page_keeps_the_wrist_watch_around_it() -> void:
	_create_view()
	_start_game_on(WORLD_MAP)
	_key(KEY_ESCAPE)
	var panel := _view._panel
	panel._push(panel._online_menu())
	assert_true(panel.shows_online_page(), "Configure > Online Game")
	var page := _view._panel_view.draw(panel)
	var cards := Keen4Episode.menu_cards(_view._data.graphics.ranges.picture_count)
	var watch := _view._data.graphics.picture(cards.watch).duplicate() as Image
	watch.convert(Image.FORMAT_RGBA8)
	var same := 0
	var lit := 0
	for corner in WATCH_SPOTS:
		if page.get_pixelv(corner).is_equal_approx(watch.get_pixelv(corner)):
			same += 1
		if watch.get_pixelv(corner) != Color.BLACK:
			lit += 1
	assert_equal(same, WATCH_SPOTS.size(), "the watch around the page")
	assert_true(lit > 0, "and it is not black there")


# --- Bug 6: level 9's floor has no holes; its glass shows the picture ---


func test_level_9s_floor_keeps_the_sky_colour_behind_the_picture() -> void:
	_create_view()
	_start_game_on(GLASS_LEVEL)
	assert_true(_view._backdrop_picture != null, "a picture behind level 9")
	var patch: GalaxySkyPatch = _view._sky_patch
	assert_true(patch.visible, "the holes in the floor are painted")
	assert_true(_covers(patch.rows(), FLOOR_HOLE_CELL), "the glass column's foot in the walkway")
	assert_true(
		not _covers(patch.rows(), GLASS_CELL), "the glass above the floor shows the picture"
	)
	assert_true(not _covers(patch.rows(), OPEN_CELL), "the open sky shows the picture")


func test_without_a_picture_nothing_is_painted() -> void:
	_create_view()
	_view._settings.backgrounds = false
	_start_game_on(GLASS_LEVEL)
	assert_true(not _view._sky_patch.visible, "the level's own sky")


# --- Helpers -----------------------------------------------------------


static func _covers(rows: Array[Rect2i], cell: Vector2i) -> bool:
	var area := Rect2i(cell * TILE_PIXELS, Vector2i(TILE_PIXELS, TILE_PIXELS))
	for row in rows:
		if area.encloses(row):
			return true
	return false


func _assert_everything(lives: int) -> void:
	var inventory := _view.inventory()
	assert_equal(inventory.gems, PackedInt32Array([1, 1, 1, 1]), "all four gems")
	assert_equal(inventory.shots, ITEM_SHOTS, "99 charges")
	assert_equal(inventory.lives, lives, "no life more (B+A+T gives one)")
	assert_equal(_view._message, "Cheat: all four gems and 99 stunner charges", "the message")


## Two players apart (player 2 walked left), the screen split.
func _split_apart() -> void:
	# The level starts at a random place in the original's random table;
	# from some places a creature stops player 2 on his way left.
	seed(SPLIT_SEED)
	_create_view()
	_start_game_on(FIRST_LEVEL)
	_view.toggle_partner()
	# Creatures wake at random places: nobody dies meanwhile.
	_view.session().player.god_mode = true
	_view.partner_keen().god_mode = true
	_frames(3)
	Input.action_press("p2_left")
	_frames(SPLIT_FRAMES)
	Input.action_release("p2_left")
	_frames(SPLIT_FRAMES)
	# Player 1 stood so long he reads a book: a step wakes him.
	Input.action_press("p1_right")
	_frames(1)
	Input.action_release("p1_right")
	_frames(LOOK_FRAMES)


## A level with smooth motion (or not), Keen walking right until a sprite
## is drawn between two different places.
func _walk_in(number: int, smooth: bool) -> void:
	_create_view()
	_view._settings.smooth_motion = smooth
	_start_game_on(number)
	_view.session().player.god_mode = true
	Input.action_press("move_right")
	_uneven_until_moving(30)
	Input.action_release("move_right")


## Runs uneven frames, at least [param count], until a sprite moved in the
## last logic frame (so that a blend would move it).
func _uneven_until_moving(count: int) -> void:
	for frame in LIMIT:
		_view._process(UNEVEN_SECONDS[frame % UNEVEN_SECONDS.size()])
		if frame >= count and _something_moves():
			return


func _something_moves() -> bool:
	for item in _view._objects.items():
		if item.motion.previous != item.motion.current:
			return true
	return false


## Over many uneven frames, every sprite and the view stay where they are.
func _assert_stands_still(what: String) -> void:
	var first := _drawn()
	for frame in STILL_FRAMES:
		_view._process(UNEVEN_SECONDS[frame % UNEVEN_SECONDS.size()])
		var now := _drawn()
		if now != first:
			failures.append("%s: moved on frame %d: %s -> %s" % [what, frame, first, now])
			return


## The places of every sprite and of the view as drawn now.
func _drawn() -> Array[Vector2]:
	var places: Array[Vector2] = [_view._camera_anchor.position]
	for item in _view._objects.items():
		places.append(item.node.position)
	return places


func _keen_in(view: Rect2i, keen: GalaxyKeenBody) -> bool:
	var box := keen.box
	var middle := Vector2(box.left + box.right, box.top + box.bottom) / 2.0
	return Rect2(view).has_point(middle / GalaxyUnits.PER_PIXEL)


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


func _key(key: Key, shift := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.shift_pressed = shift
	event.pressed = true
	_view._unhandled_input(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	_view._unhandled_input(release)


func _shift_key(key: Key) -> void:
	_key(key, true)


func _release_all() -> void:
	for action in KeyBindings.all_actions():
		Input.action_release(action)


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
