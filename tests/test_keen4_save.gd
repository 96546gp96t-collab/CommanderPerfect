extends "res://tests/test_case.gd"
## Tests Keen 4's saved games, settings and difficulty without the game's
## files (milestone D10): the six slots of [GalaxySaveSlots] in a folder of
## their own (apart from Keen 1-3's), a [Keen4SavedGame] that survives the
## trip through a JSON file (inventory, progress, map position, level,
## random start, recorded frames), damaged and foreign files, Keen 4's own
## score box setting ([Keen4Settings]), the stunner's 8 charges on Easy and
## Easy's higher jump (gravity mid after the push, Omni CK_KeenJumpThink;
## measured in the original, below). The files go to a folder of their own
## in the user folder, which is removed afterwards.

const Fixtures := preload("res://tests/galaxy_keen_fixtures.gd")

const TEST_DIRECTORY := "user://test_keen4_save"
const SLOTS := 6
const UNITS := 16
## Seen in the original (D4): a held jump rises 67 pixels on Normal.
const NORMAL_JUMP_PIXELS := 67
## Seen in the original (D10, js-dos, the user's v1.0, level 1 on Easy,
## twice): the same 9 frames of 5 px as on Normal, then 4, 4, 4, 4, 3, 3, 2,
## 2, 2, 1, 1 and four frames at the top, down again in 19 frames; 43
## frames in the air. Frame for frame what gravity mid gives: 75 pixels.
const EASY_JUMP_PIXELS := 75
const OPEN_SKY: PackedStringArray = [
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"..............",
	"....K.........",
	"##############",
]


func run_all() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIRECTORY)
	super.run_all()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_keen_4_saves_are_apart_from_keen_1_to_3() -> void:
	var folder := GalaxySaveSlots.DEFAULT_DIRECTORY
	assert_equal(folder, "user://keen4/saves", "in Keen 4's own folder")
	for other in [
		SaveGames.DEFAULT_DIRECTORY, Keen2MenuScreen.SAVES_DIRECTORY, Keen3SaveGames.DIRECTORY
	]:
		assert_true(folder != other, "apart from %s" % other)
	assert_equal(GalaxySaveSlots.SLOT_COUNT, SLOTS, "six slots, as the original")
	assert_equal(GalaxySaveSlots.new().count, SLOTS, "six by default")
	assert_true(Keen4Settings.DEFAULT_PATH.begins_with("user://keen4/"), "settings in keen4/")
	assert_true(Keen4Settings.DEFAULT_PATH != UserSettings.DEFAULT_PATH, "not the shared file")


func test_six_slots_with_their_names() -> void:
	var slots := _slots("names")
	for slot in range(1, SLOTS + 1):
		assert_true(not slots.exists(slot), "slot %d empty" % slot)
		assert_equal(slots.name_of(slot), "", "no name in slot %d" % slot)
	for slot in range(1, SLOTS + 1):
		assert_true(slots.write(slot, "Game %d" % slot, {"slot": slot}), "slot %d written" % slot)
	for slot in range(1, SLOTS + 1):
		assert_equal(slots.name_of(slot), "Game %d" % slot, "slot %d's name" % slot)
		assert_equal(int(slots.read(slot).get("slot", 0)), slot, "slot %d's game" % slot)
	assert_true(not slots.write(0, "No", {}), "there is no slot 0")
	assert_true(not slots.write(SLOTS + 1, "No", {}), "there is no slot 7")
	assert_true(not slots.exists(SLOTS + 1), "nor does it exist")
	assert_true(
		not FileAccess.file_exists(slots._path(SLOTS + 1)), "and nothing was written for it"
	)


func test_a_game_on_the_map_survives_a_save() -> void:
	var game := Keen4SavedGame.new()
	game.difficulty = GalaxyDifficulty.Level.HARD
	game.inventory.score = 123450
	game.inventory.next_life_at = 160000
	game.inventory.lives = 7
	game.inventory.shots = 42
	game.inventory.drops = 99
	game.inventory.gems = PackedInt32Array([1, 0, 2, 0])
	game.progress.rescued = 5
	game.progress.wetsuit = true
	for level in [1, 2, 3, 6, 9]:
		game.progress.mark_done(level)
	game.progress.map_position = Vector2i(12345, 6789)
	var slots := _slots("map")
	assert_true(slots.write(2, "On the map", game.to_dictionary()), "written")
	var loaded := Keen4SavedGame.from_dictionary(slots.read(2))
	assert_true(loaded != null, "read back")
	if loaded == null:
		return
	assert_equal(loaded.difficulty, GalaxyDifficulty.Level.HARD, "difficulty")
	assert_equal(loaded.inventory.score, 123450, "score")
	assert_equal(loaded.inventory.next_life_at, 160000, "next extra life")
	assert_equal(loaded.inventory.lives, 7, "lives")
	assert_equal(loaded.inventory.shots, 42, "charges")
	assert_equal(loaded.inventory.drops, 99, "drops")
	assert_equal(loaded.inventory.gems, PackedInt32Array([1, 0, 2, 0]), "gems")
	assert_equal(loaded.progress.rescued, 5, "rescued")
	assert_true(loaded.progress.wetsuit, "the wetsuit")
	assert_equal(loaded.progress.done_levels(), PackedInt32Array([1, 2, 3, 6, 9]), "levels done")
	assert_equal(loaded.progress.map_position, Vector2i(12345, 6789), "place on the map")
	assert_equal(loaded.map_number, Keen4Episode.WORLD_MAP, "on the world map")
	assert_true(not loaded.in_level(), "not in a level")
	assert_true(loaded.inventory is Keen4Inventory, "Keen 4's inventory")
	assert_equal(typeof(loaded.inventory.lives), TYPE_INT, "numbers stay whole numbers")


func test_a_game_in_a_level_keeps_its_frames() -> void:
	var game := Keen4SavedGame.new()
	game.difficulty = GalaxyDifficulty.Level.EASY
	game.map_number = 6
	game.random_start = 200
	var held := KeenInput.create(1, true, false)
	held.vertical = -1
	held.fire = true
	Keen4SavedGame.record_frame(game.frames, held, 3)
	Keen4SavedGame.record_event(game.frames, Keen4SavedGame.Event.GOD_MODE_ON)
	Keen4SavedGame.record_frame(game.frames, KeenInput.create(-1, false, true), 2)
	var slots := _slots("level")
	slots.write(4, "In a level", game.to_dictionary())
	var loaded := Keen4SavedGame.from_dictionary(slots.read(4))
	assert_true(loaded != null, "read back")
	if loaded == null:
		return
	assert_equal(loaded.difficulty, GalaxyDifficulty.Level.EASY, "difficulty")
	assert_equal(loaded.map_number, 6, "the level")
	assert_true(loaded.in_level(), "in a level")
	assert_equal(loaded.random_start, 200, "where the random table started")
	assert_equal(loaded.frames, game.frames, "the frames, byte for byte")
	assert_equal(loaded.frames.size(), 3 * Keen4SavedGame.FRAME_BYTES, "two frames, one event")


func test_a_damaged_slot_is_named_and_not_loaded() -> void:
	var slots := _slots("damaged")
	DirAccess.make_dir_recursive_absolute(slots.directory)
	_write_text(slots._path(1), "{ this is not json")
	_write_text(slots._path(2), JSON.stringify({"version": 99, "name": "Future", "game": {}}))
	_write_text(slots._path(3), JSON.stringify({"version": 1, "name": "Odd", "game": [1, 2]}))
	_write_text(slots._path(4), "")
	for slot in [1, 2, 4]:
		assert_true(slots.exists(slot), "slot %d has a file" % slot)
		assert_equal(slots.read(slot), {}, "slot %d cannot be read" % slot)
		assert_true(slots.name_of(slot) != "", "slot %d still shows something" % slot)
	assert_equal(slots.read(3), {}, "a game that is not a dictionary")
	assert_equal(slots.name_of(3), "Odd", "but its name is shown")


func test_a_damaged_game_is_refused() -> void:
	assert_equal(Keen4SavedGame.from_dictionary({}), null, "nothing in it")
	var good := Keen4SavedGame.new().to_dictionary()
	var broken := [
		_without(good, Keen4SavedGame.INVENTORY_KEY),
		_without(good, Keen4SavedGame.PROGRESS_KEY),
		_with(good, Keen4SavedGame.INVENTORY_KEY, "lots"),
		_with(good, Keen4SavedGame.MAP_KEY, 99),
		_with(good, Keen4SavedGame.MAP_KEY, -1),
	]
	for index in broken.size():
		assert_equal(Keen4SavedGame.from_dictionary(broken[index]), null, "broken %d" % index)
	var odd := Keen4SavedGame.from_dictionary(_with(good, Keen4SavedGame.DIFFICULTY_KEY, 7))
	assert_true(odd != null, "an unknown difficulty still loads")
	if odd != null:
		assert_equal(odd.difficulty, GalaxyDifficulty.Level.HARD, "as the nearest one")
	var junk := Keen4SavedGame.from_dictionary(_with(good, Keen4SavedGame.FRAMES_KEY, "%%%"))
	assert_true(junk == null or junk.frames.size() % Keen4SavedGame.FRAME_BYTES == 0, "frames")


func test_the_score_box_setting_is_kept() -> void:
	var path := TEST_DIRECTORY.path_join("keen4/settings.cfg")
	var settings := Keen4Settings.load_from(path)
	assert_true(settings.score_box, "on in a new installation (the original)")
	settings.score_box = false
	assert_true(settings.save(), "saved")
	assert_true(not Keen4Settings.load_from(path).score_box, "off after loading")
	_write_text(path, "[[[ not a config")
	assert_true(Keen4Settings.load_from(path).score_box, "a damaged file: the default")


func test_a_stunner_gives_8_charges_on_easy() -> void:
	assert_equal(Keen4Inventory.charges_for(GalaxyDifficulty.Level.EASY), 8, "Easy (Omni)")
	assert_equal(Keen4Inventory.charges_for(GalaxyDifficulty.Level.NORMAL), 5, "Normal")
	assert_equal(Keen4Inventory.charges_for(GalaxyDifficulty.Level.HARD), 5, "Hard")
	var inventory := Keen4Inventory.new_game()
	inventory.charges_per_stunner = Keen4Inventory.charges_for(GalaxyDifficulty.Level.EASY)
	inventory.collect(GalaxyInventory.STUNNER_ITEM)
	assert_equal(inventory.shots, 5 + 8, "5 to start with, 8 more")
	assert_equal(Keen4Inventory.new_game().shots, 5, "a new game starts with 5 on every level")


func test_easy_jumps_higher() -> void:
	var normal := _held_jump(false)
	var easy := _held_jump(true)
	assert_equal(normal, NORMAL_JUMP_PIXELS, "Normal: 67 pixels")
	assert_equal(easy, EASY_JUMP_PIXELS, "Easy: 75 pixels (the original)")


func test_easy_pogo_is_higher_too() -> void:
	# Omni CK_KeenPogoThink: gravity mid once the bounce's push is over.
	var normal := _held_pogo(false)
	var easy := _held_pogo(true)
	assert_true(easy > normal, "a held bounce rises higher on Easy: %d > %d" % [easy, normal])
	# The push itself (24 tics of -48) is the same: the difference is small.
	assert_true(easy - normal < 20, "but not by much: %d" % (easy - normal))


## The pixels a held jump rises from the floor.
func _held_jump(easy: bool) -> int:
	var world := Fixtures.world(OPEN_SKY)
	var keen := world.player() as GalaxyKeen
	keen.easy_jumps = easy
	var start := keen.position.y
	var highest := Fixtures.run(
		world, 70, func(_frame: int) -> KeenInput: return Fixtures.press(0, 0, true)
	)
	return (start - highest) / UNITS


## The pixels the second held pogo bounce rises.
func _held_pogo(easy: bool) -> int:
	var world := Fixtures.world(OPEN_SKY)
	var keen := world.player() as GalaxyKeen
	keen.easy_jumps = easy
	var start := keen.position.y
	Fixtures.run(world, 1, func(_frame: int) -> KeenInput: return Fixtures.press(0, 0, false, true))
	var jump := func(_frame: int) -> KeenInput: return Fixtures.press(0, 0, true)
	Fixtures.run(world, 70, jump)
	var highest := Fixtures.run(world, 60, jump)
	return (start - highest) / UNITS


func _slots(folder: String) -> GalaxySaveSlots:
	var slots := GalaxySaveSlots.in_directory(TEST_DIRECTORY.path_join(folder))
	for slot in range(1, SLOTS + 2):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slots._path(slot)))
	return slots


static func _with(base: Dictionary, key: String, value: Variant) -> Dictionary:
	var changed := base.duplicate(true)
	changed[key] = value
	return changed


static func _without(base: Dictionary, key: String) -> Dictionary:
	var changed := base.duplicate(true)
	changed.erase(key)
	return changed


static func _write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
