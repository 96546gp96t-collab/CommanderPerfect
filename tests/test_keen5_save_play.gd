extends "res://tests/test_case.gd"
## Checks Keen 5's saved levels with the player's real files (milestone
## E9; [Keen5SavedGame]): a level saved halfway (the frames played since it
## began, with god mode and B+A+T among them) comes back exactly as it was
## after the trip through a save slot in a folder of its own: Keen, every
## object, the tiles, the inventory with the keycard, the fuses still to
## break and the random table, and both go on alike. Levels with fuses, the
## QED's map and Korath III's base, on each difficulty. Skipped without the
## files.

const TEST_DIRECTORY := "user://test_keen5_save_play"
const FRAMES_BEFORE_SAVE := 500
const FRAMES_AFTER_LOAD := 150
const CHEAT_FRAME := 200
const RANDOM_START := 91
const SLOT := 2
## Level, difficulty: a fuse level, the QED's map, Korath III's base.
const CASES := [
	[1, GalaxyDifficulty.Level.NORMAL],
	[4, GalaxyDifficulty.Level.EASY],
	[12, GalaxyDifficulty.Level.HARD],
	[13, GalaxyDifficulty.Level.NORMAL],
]

var _data: GalaxyData
var _rules: GalaxyGameRules


func _init() -> void:
	var files := Keen5Files.locate()
	if files == null:
		skip("no Keen 5 files in game_data/keen5")
		return
	_data = Keen5Episode.load_data(files)
	_rules = Keen5Episode.game_rules()


func run_all() -> void:
	super.run_all()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_a_level_saved_halfway_comes_back_as_it_was() -> void:
	for case: Array in CASES:
		_check_round_trip(case[0], case[1])


func _check_round_trip(number: int, level: GalaxyDifficulty.Level) -> void:
	var game := Keen5SavedGame.new(_rules)
	game.difficulty = level
	game.map_number = number
	game.random_start = RANDOM_START
	game.inventory.score = 4200
	(game.progress as Keen5Progress).mark_done(4, Keen5Progress.DONE_BY_FUSE)
	var played := _start(game)
	played.player.god_mode = true
	GalaxySavedGame.record_event(game.frames, GalaxySavedGame.Event.GOD_MODE_ON)
	var tic := 0
	for frame in FRAMES_BEFORE_SAVE:
		if frame == CHEAT_FRAME:
			GalaxySavedGame.record_event(game.frames, GalaxySavedGame.Event.ITEMS_CHEAT)
			game.give_items(played.inventory)
		var input := _input(frame)
		var tics := GalaxyClock.LEVEL_START_TICS if frame == 0 else GalaxyClock.NORMAL_TICS
		tic += tics
		GalaxySavedGame.record_frame(game.frames, input, tics)
		played.run_frame(input, tics, tic)
		played.take_conversation()
		if not played.is_playing():
			break
	var slots := GalaxySaveSlots.in_directory(TEST_DIRECTORY.path_join("saves"))
	assert_true(slots.write(SLOT, "Halfway", game.to_dictionary()), "saved")
	var loaded := Keen5SavedGame.new(_rules)
	if not loaded.load_dictionary(slots.read(SLOT)):
		_fail("level %d could not be loaded" % number)
		return
	var again := _start(loaded)
	var where := "level %d, difficulty %d" % [number, level]
	assert_equal(loaded.replay(again, loaded.frames), tic, "%s: replayed to the same tic" % where)
	_compare(played, again, where + " after loading")
	assert_true((again.inventory as Keen5Inventory).keycard, "%s: B+A+T's keycard" % where)
	for frame in FRAMES_AFTER_LOAD:
		var input := _input(FRAMES_BEFORE_SAVE + frame)
		tic += GalaxyClock.NORMAL_TICS
		played.run_frame(input, GalaxyClock.NORMAL_TICS, tic)
		again.run_frame(input, GalaxyClock.NORMAL_TICS, tic)
	_compare(played, again, where + " later")


func _start(game: Keen5SavedGame) -> Keen5LevelSession:
	return Keen5LevelSession.start_level(
		_data,
		_rules,
		_data.maps.load_map(game.map_number),
		game.copy_inventory(game.inventory),
		game.random_start,
		game.difficulty,
		game.map_number
	)


func _compare(played: Keen5LevelSession, again: Keen5LevelSession, where: String) -> void:
	assert_equal(again.player.position, played.player.position, "%s: Keen's place" % where)
	assert_equal(again.player.velocity, played.player.velocity, "%s: Keen's speed" % where)
	assert_equal(again.player.action.name, played.player.action.name, "%s: his action" % where)
	var saved := Keen5SavedGame.new(_rules)
	assert_equal(
		saved.inventory_to_dictionary(again.inventory),
		saved.inventory_to_dictionary(played.inventory),
		"%s: inventory, keycard and fuses" % where
	)
	assert_equal(again.world.random_index, played.world.random_index, "%s: random" % where)
	assert_equal(_objects(again), _objects(played), "%s: every object" % where)
	for layer in [GalaxyMap.Layer.BACKGROUND, GalaxyMap.Layer.FOREGROUND, GalaxyMap.Layer.INFO]:
		assert_true(
			again.map.planes[layer] == played.map.planes[layer], "%s: plane %d" % [where, layer]
		)
	assert_equal(again.camera.scroll, played.camera.scroll, "%s: the view" % where)


static func _objects(session: Keen5LevelSession) -> Array:
	var described := []
	for object in session.world.objects:
		(
			described
			. append(
				[
					object.get_script().get_global_name(),
					object.position,
					object.velocity,
					object.action.name if object.action != null else &"",
					object.removed,
				]
			)
		)
	return described


## Walking right with jumps, pogo bounces and shots, now and then left.
static func _input(frame: int) -> KeenInput:
	var direction := -1 if (frame / 90) % 4 == 3 else 1
	var input := KeenInput.create(direction, frame % 40 < 12, frame % 150 > 140)
	input.fire = frame % 33 == 0
	return input


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
