extends "res://tests/test_case.gd"
## Tests Keen 4's difficulty and saved levels with the player's real files
## (milestone D10): a level started on Easy gives 8 charges a stunner and
## the higher jump, on Normal and Hard not; every level 1-17 places the
## creatures the info plane asks for on each difficulty (counted here from
## research.md §6's values, apart from [Keen4Creatures]); and a level saved
## halfway ([Keen4SavedGame]: the frames played since it began) comes back
## exactly as it was after the trip through a save slot: Keen, every
## object, the tiles, the inventory and the random table. Skipped without
## the files.

const TEST_DIRECTORY := "user://test_keen4_save_play"
const LAST_LEVEL := 17
## Research.md §6: per creature (its class name), its info values on
## every difficulty / from Normal / only on Hard.
const CENSUS_VALUES := [
	[&"Keen4Slug", [22], [43], [44]],
	[&"Keen4Lick", [14], [47], [48]],
	[&"Keen4Berkeloid", [5], [49], [50]],
	[&"Keen4Wormmouth", [7], [51], [52]],
	[&"Keen4Skypest", [8], [45], [46]],
	[&"Keen4Arachnut", [20], [73], [74]],
	[&"Keen4DartGun", [53, 54, 55, 56], [79, 80, 81, 82], [83, 84, 85, 86]],
	[&"Keen4Dopefish", [15], [87], [88]],
	[&"Keen4WaterSprite", [17], [23], [24]],
	[&"Keen4Bounder", [12], [], []],
	[&"Keen4Mushroom", [21], [], []],
]
const FRAMES_BEFORE_SAVE := 600
const FRAMES_AFTER_LOAD := 200
const RANDOM_START := 77

var _data: GalaxyData


func _init() -> void:
	var files := Keen4Files.locate()
	if files == null:
		skip("no Keen 4 files in game_data/keen4")
		return
	_data = Keen4Episode.load_data(files)


func run_all() -> void:
	super.run_all()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_easy_gives_8_charges_and_the_higher_jump() -> void:
	var expected := {
		GalaxyDifficulty.Level.EASY: [8, true],
		GalaxyDifficulty.Level.NORMAL: [5, false],
		GalaxyDifficulty.Level.HARD: [5, false],
	}
	for level: GalaxyDifficulty.Level in expected:
		var session := _start(1, level, Keen4Inventory.new_game())
		assert_equal(
			[session.inventory.charges_per_stunner, session.keen.easy_jumps],
			expected[level],
			"level 1 on difficulty %d: charges a stunner, Easy's jump" % level
		)
		var shots := session.inventory.shots
		session.inventory.collect(GalaxyInventory.STUNNER_ITEM)
		assert_equal(session.inventory.shots - shots, expected[level][0], "a stunner item")


func test_every_level_places_its_creatures_per_difficulty() -> void:
	var totals := [0, 0, 0]
	for number in range(1, LAST_LEVEL + 1):
		var map := _data.maps.load_map(number)
		var counts := {}
		for value in map.planes[GalaxyMap.Layer.INFO]:
			counts[value] = counts.get(value, 0) + 1
		for level in [
			GalaxyDifficulty.Level.EASY, GalaxyDifficulty.Level.NORMAL, GalaxyDifficulty.Level.HARD
		]:
			var session := _start(number, level, Keen4Inventory.new_game())
			if session == null:
				_fail("level %d did not start" % number)
				continue
			totals[level] += session.world.objects.size()
			for row: Array in CENSUS_VALUES:
				var wanted := 0
				for tier in level + 1:
					for value: int in row[tier + 1]:
						wanted += counts.get(value, 0)
				var placed := 0
				for object in session.world.objects:
					if _class_of(object) == row[0] and not object.removed:
						placed += 1
				assert_equal(
					placed, wanted, "level %d, difficulty %d: %s" % [number, level, row[0]]
				)
	assert_true(
		totals[0] < totals[1] and totals[1] < totals[2],
		"more creatures on harder levels, Easy < Normal < Hard: %s" % [totals]
	)


func test_a_level_saved_halfway_comes_back_as_it_was() -> void:
	_check_round_trip(1, GalaxyDifficulty.Level.NORMAL)
	_check_round_trip(4, GalaxyDifficulty.Level.EASY)
	_check_round_trip(17, GalaxyDifficulty.Level.HARD)


func _check_round_trip(number: int, level: GalaxyDifficulty.Level) -> void:
	var start_inventory := Keen4Inventory.new_game()
	start_inventory.score = 4200
	start_inventory.shots = 9
	var game := Keen4SavedGame.new()
	game.difficulty = level
	game.map_number = number
	game.random_start = RANDOM_START
	game.progress.rescued = 2
	game.inventory = Keen4SavedGame.inventory_from_dictionary(
		Keen4SavedGame.inventory_to_dictionary(start_inventory)
	)
	var played := _start(number, level, start_inventory)
	played.player.god_mode = true
	Keen4SavedGame.record_event(game.frames, Keen4SavedGame.Event.GOD_MODE_ON)
	var tic := 0
	for frame in FRAMES_BEFORE_SAVE:
		var input := _input(frame)
		var tics := GalaxyClock.LEVEL_START_TICS if frame == 0 else GalaxyClock.NORMAL_TICS
		tic += tics
		Keen4SavedGame.record_frame(game.frames, input, tics)
		played.run_frame(input, tics, tic)
		played.take_conversation()
		if not played.is_playing():
			break
	var slots := GalaxySaveSlots.in_directory(TEST_DIRECTORY.path_join("saves"))
	assert_true(slots.write(5, "Halfway", game.to_dictionary()), "saved")
	var loaded := Keen4SavedGame.from_dictionary(slots.read(5))
	if loaded == null:
		_fail("level %d could not be loaded" % number)
		return
	var again := Keen4LevelSession.start(
		_data,
		_data.maps.load_map(loaded.map_number),
		loaded.inventory,
		loaded.random_start,
		loaded.difficulty,
		loaded.map_number
	)
	var replayed_to := Keen4SavedGame.replay(again, loaded.frames)
	var where := "level %d, difficulty %d" % [number, level]
	assert_equal(replayed_to, tic, "%s: replayed to the same tic" % where)
	_compare(played, again, where + " after loading")
	# And they go on alike.
	for frame in FRAMES_AFTER_LOAD:
		var input := _input(FRAMES_BEFORE_SAVE + frame)
		tic += GalaxyClock.NORMAL_TICS
		played.run_frame(input, GalaxyClock.NORMAL_TICS, tic)
		again.run_frame(input, GalaxyClock.NORMAL_TICS, tic)
	_compare(played, again, where + " 200 frames later")


func _compare(played: Keen4LevelSession, again: Keen4LevelSession, where: String) -> void:
	assert_equal(again.player.position, played.player.position, "%s: Keen's place" % where)
	assert_equal(again.player.velocity, played.player.velocity, "%s: Keen's speed" % where)
	assert_equal(again.player.action.name, played.player.action.name, "%s: Keen's action" % where)
	assert_equal(again.player.god_mode, played.player.god_mode, "%s: god mode" % where)
	assert_equal(
		Keen4SavedGame.inventory_to_dictionary(again.inventory),
		Keen4SavedGame.inventory_to_dictionary(played.inventory),
		"%s: inventory" % where
	)
	assert_equal(again.world.random_index, played.world.random_index, "%s: random" % where)
	assert_equal(again.world.state, played.world.state, "%s: level state" % where)
	assert_equal(_objects(again), _objects(played), "%s: every object" % where)
	for layer in [GalaxyMap.Layer.BACKGROUND, GalaxyMap.Layer.FOREGROUND, GalaxyMap.Layer.INFO]:
		assert_true(
			again.map.planes[layer] == played.map.planes[layer], "%s: plane %d" % [where, layer]
		)
	assert_equal(again.camera.scroll, played.camera.scroll, "%s: the view" % where)


## The class name of [param object] (the census counts by name).
static func _class_of(object: GalaxyObject) -> StringName:
	return object.get_script().get_global_name()


static func _objects(session: Keen4LevelSession) -> Array:
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


func _start(
	number: int, level: GalaxyDifficulty.Level, carried: GalaxyInventory
) -> Keen4LevelSession:
	return Keen4LevelSession.start(
		_data, _data.maps.load_map(number), carried, RANDOM_START, level, number
	)


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
