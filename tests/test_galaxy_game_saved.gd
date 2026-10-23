extends "res://tests/test_case.gd"
## Checks the shared Galaxy game's saved games and control panel numbers
## (milestone E9; [GalaxySavedGame], [method GalaxyGameRules.menu_cards],
## [method GalaxyGameRules.saves_folder]) with a hand-made episode
## ([code]galaxy_game_fixtures.gd[/code]) and Keen 5's own saved game
## ([Keen5SavedGame]): a game goes through a dictionary and a save slot
## unchanged, a map the episode does not have is refused, a level played
## with jumps, shots and the cheats comes back exactly when its frames are
## played again, the panel's pictures are counted from the end of the
## picture range by the episode's numbers, and Keen 5 keeps everything in
## its own user folder, never in Keen 4's. No game's files are needed.

const Game := preload("res://tests/galaxy_game_fixtures.gd")
const Keen := preload("res://tests/galaxy_keen_fixtures.gd")

const TEST_DIRECTORY := "user://test_galaxy_game_saved"
const FRAMES_BEFORE_SAVE := 160
const FRAMES_AFTER_LOAD := 60
const RANDOM_START := 33
const SLOT := 4
const ROOM: PackedStringArray = [
	"..........................",
	"..........................",
	"..........................",
	"..........................",
	"..........................",
	"....K.....................",
	"##########################",
]
## Keen 5's 93 pictures (files): its cards from PIC_MENUCARD (61) on.
const KEEN5_PICTURES := 93
const KEEN5_MAIN_CARD := 61
const KEEN5_OPTIONS_CARD := 72
const KEEN5_KEYS_CARD := 70
const KEEN5_PADDLE_WAR := 73
const KEEN5_WATCH := 76
## Keen 4's 115 pictures: PIC_MENUCARD 88 − 6, the watch 103 − 6.
const KEEN4_PICTURES := 115
const KEEN4_MAIN_CARD := 82
const KEEN4_WATCH := 97
## Where the sources live whose paths must never be Keen 4's.
const KEEN5_SOURCES: PackedStringArray = ["res://src/keen5", "res://src/galaxy/game"]


func run_all() -> void:
	super.run_all()
	_remove_recursive(ProjectSettings.globalize_path(TEST_DIRECTORY))


func test_a_game_goes_through_a_slot_unchanged() -> void:
	var rules := Game.rules()
	var game := GalaxySavedGame.new(rules)
	game.difficulty = GalaxyDifficulty.Level.HARD
	game.map_number = 3
	game.random_start = RANDOM_START
	game.inventory.score = 12345
	game.inventory.lives = 6
	game.inventory.gems = PackedInt32Array([1, 0, 2, 0])
	game.progress.mark_done(1, 7)
	game.progress.map_position = Vector2i(0x1200, 0x3400)
	GalaxySavedGame.record_frame(game.frames, KeenInput.create(1, true, false), 2)
	GalaxySavedGame.record_event(game.frames, GalaxySavedGame.Event.ITEMS_CHEAT)
	var slots := GalaxySaveSlots.in_directory(TEST_DIRECTORY.path_join("saves"))
	assert_true(slots.write(SLOT, "Halfway", game.to_dictionary()), "written")
	var loaded := GalaxySavedGame.new(rules)
	assert_true(loaded.load_dictionary(slots.read(SLOT)), "read")
	assert_equal(loaded.to_dictionary(), game.to_dictionary(), "the same game")
	assert_equal(loaded.inventory.lives, 6, "what Keen carries")
	assert_equal(loaded.progress.done_value(1), 7, "the levels done with their values")
	assert_true(loaded.in_level(), "in a level")
	assert_equal(slots.name_of(SLOT), "Halfway", "the slot's name")


func test_a_new_saved_game_is_a_new_game_of_the_rules() -> void:
	var rules := Game.rules()
	var game := GalaxySavedGame.new(rules)
	assert_equal(
		[game.inventory.lives, game.inventory.shots, game.inventory.next_life_at],
		[Game.START_LIVES, Game.START_SHOTS, Game.FIRST_EXTRA_LIFE],
		"the rules' numbers"
	)
	assert_true(not game.in_level(), "on the world map")


func test_a_map_the_episode_does_not_have_is_refused() -> void:
	var rules := Game.rules()
	var game := GalaxySavedGame.new(rules)
	for number in [Game.MISSING_MAP, Game.LAST_MAP + 1, -1]:
		var saved := game.to_dictionary()
		saved[GalaxySavedGame.MAP_KEY] = number
		assert_true(not GalaxySavedGame.new(rules).load_dictionary(saved), "map %d" % number)
	assert_true(not game.load_dictionary({}), "no inventory or progress")
	var saved := game.to_dictionary()
	saved[GalaxySavedGame.DIFFICULTY_KEY] = 9
	assert_true(game.load_dictionary(saved), "a difficulty out of range is clamped")
	assert_equal(game.difficulty, GalaxyDifficulty.Level.HARD, "to Hard")


func test_the_frames_keep_the_keys_and_the_events() -> void:
	var input := KeenInput.create(-1, false, true)
	input.vertical = 1
	input.fire = true
	var frames := PackedByteArray()
	GalaxySavedGame.record_frame(frames, input, 3)
	GalaxySavedGame.record_view_width(frames, 427)
	var back := GalaxySavedGame.input_of(frames[0])
	assert_equal(
		[back.direction, back.vertical, back.jump, back.pogo, back.fire],
		[-1, 1, false, true, true],
		"the keys"
	)
	assert_equal(frames[1], 3, "the tics")
	assert_equal(
		Array(frames.slice(2)), [GalaxySavedGame.Event.VIEW_WIDTH, 0, 427 & 0xFF, 427 >> 8], "width"
	)


func test_a_level_played_again_is_where_it_was() -> void:
	var rules := Game.rules()
	var map := Keen.level(ROOM)
	var game := GalaxySavedGame.new(rules)
	game.map_number = Game.FIRST_LEVEL
	game.random_start = RANDOM_START
	var played := _start(rules, game, map)
	var tic := 0
	for frame in FRAMES_BEFORE_SAVE:
		if frame == FRAMES_BEFORE_SAVE / 2:
			GalaxySavedGame.record_event(game.frames, GalaxySavedGame.Event.EVERYTHING)
			game.give_everything(played.inventory)
			GalaxySavedGame.record_event(game.frames, GalaxySavedGame.Event.GOD_MODE_ON)
			played.player.god_mode = true
		var input := _input(frame)
		tic += GalaxyClock.NORMAL_TICS
		GalaxySavedGame.record_frame(game.frames, input, GalaxyClock.NORMAL_TICS)
		played.run_frame(input, GalaxyClock.NORMAL_TICS, tic)
	var loaded := GalaxySavedGame.new(rules)
	assert_true(loaded.load_dictionary(game.to_dictionary()), "read")
	var again := _start(rules, loaded, Keen.level(ROOM))
	assert_equal(loaded.replay_all(again, loaded.frames), tic, "played to the same tic")
	_compare(played, again, "after loading")
	for frame in FRAMES_AFTER_LOAD:
		var input := _input(FRAMES_BEFORE_SAVE + frame)
		tic += GalaxyClock.NORMAL_TICS
		played.run_frame(input, GalaxyClock.NORMAL_TICS, tic)
		again.run_frame(input, GalaxyClock.NORMAL_TICS, tic)
	_compare(played, again, "later")
	assert_true(again.inventory.shots > Game.START_SHOTS + Game.START_SHOTS, "Shift+I's charges")
	assert_true(again.player.god_mode, "god mode from the frames")


func test_the_panels_pictures_are_counted_from_the_end() -> void:
	var keen_5 := Keen5Episode.game_rules().menu_cards(KEEN5_PICTURES)
	assert_equal(keen_5.card(MenuController.MAIN).picture, KEEN5_MAIN_CARD, "MAIN MENU")
	assert_equal(keen_5.card(MenuController.OPTIONS).picture, KEEN5_OPTIONS_CARD, "OPTIONS")
	assert_equal(keen_5.card(MenuController.KEY_SET).picture, KEEN5_KEYS_CARD, "BUTTON SETUP")
	assert_equal(keen_5.paddle_war_picture, KEEN5_PADDLE_WAR, "Paddle War")
	assert_equal(keen_5.watch, KEEN5_WATCH, "the wrist watch")
	assert_equal(
		keen_5.card(GalaxyMenuController.NEW_GAME).offset, Vector2i(8, 0), "the engine's places"
	)
	var keen_4 := GalaxyGameRules.new().menu_cards(KEEN4_PICTURES)
	var keen_4_cards := Keen4Episode.menu_cards(KEEN4_PICTURES)
	assert_equal(keen_4.watch, KEEN4_WATCH, "the defaults are Keen 4's")
	assert_equal(keen_4.card(MenuController.MAIN).picture, KEEN4_MAIN_CARD, "Keen 4's main card")
	for kind in keen_4_cards.cards:
		assert_equal(keen_4.card(kind).picture, keen_4_cards.card(kind).picture, "Keen 4: " + kind)
	assert_equal(keen_4.paddle_war_picture, keen_4_cards.paddle_war_picture, "Keen 4's Paddle War")


func test_keen5_keeps_its_own_state() -> void:
	var rules := Keen5Episode.game_rules()
	var game := Keen5SavedGame.new(rules)
	var carried := game.inventory as Keen5Inventory
	assert_true(carried != null, "Keen 5's inventory")
	carried.keycard = true
	carried.fuses_remaining = 2
	var progress := game.progress as Keen5Progress
	progress.mark_done(4, Keen5Progress.DONE_BY_FUSE)
	progress.korath_arrival = true
	var loaded := Keen5SavedGame.new(rules)
	assert_true(loaded.load_dictionary(game.to_dictionary()), "read")
	var back := loaded.inventory as Keen5Inventory
	assert_equal([back.keycard, back.fuses_remaining], [true, 2], "the keycard and the fuses")
	var back_progress := loaded.progress as Keen5Progress
	assert_equal(back_progress.done_value(4), Keen5Progress.DONE_BY_FUSE, "a fuse's 14")
	assert_true(back_progress.korath_arrival, "the arrival on Korath III")
	var fresh := Keen5Inventory.new_game()
	loaded.give_items(fresh)
	assert_true(fresh.keycard, "B+A+T among the frames gives the keycard")
	var none := Keen5Inventory.new_game()
	loaded.give_everything(none)
	assert_true(none.keycard and none.shots == GalaxySavedGame.EVERYTHING_SHOTS, "Shift+I too")
	var saved := game.to_dictionary()
	saved[GalaxySavedGame.MAP_KEY] = Keen5Episode.EMPTY_MAP
	assert_true(not Keen5SavedGame.new(rules).load_dictionary(saved), "map 14 does not exist")


func test_keen5_writes_only_in_its_own_folder() -> void:
	var rules := Keen5Episode.game_rules()
	var paths := [
		rules.saves_folder(),
		rules.settings_path(),
		rules.high_scores_path(),
		rules.sound_cache_folder(),
	]
	for path: String in paths:
		assert_true(path.begins_with(Keen5Episode.USER_FOLDER + "/"), path)
		assert_true(not path.contains("keen4"), path)
	assert_equal(rules.saves_folder(), "user://keen5/saves", "the saves")
	assert_equal(rules.save_slot_count, GalaxySaveSlots.SLOT_COUNT, "six slots, as the original")
	for folder in KEEN5_SOURCES:
		for file in _scripts(folder):
			var text := FileAccess.get_file_as_string(file)
			assert_true(not text.contains("user://keen4"), "%s names Keen 4's folder" % file)


func _start(rules: GalaxyGameRules, game: GalaxySavedGame, map: GalaxyMap) -> GalaxyLevelSession:
	return GalaxyLevelSession.start_level(
		Game.data(),
		rules,
		map,
		game.copy_inventory(game.inventory),
		game.random_start,
		game.difficulty,
		game.map_number
	)


func _compare(played: GalaxyLevelSession, again: GalaxyLevelSession, where: String) -> void:
	assert_equal(again.player.position, played.player.position, "%s: Keen's place" % where)
	assert_equal(again.player.velocity, played.player.velocity, "%s: Keen's speed" % where)
	assert_equal(again.player.action.name, played.player.action.name, "%s: his action" % where)
	assert_equal(again.inventory.shots, played.inventory.shots, "%s: charges" % where)
	assert_equal(again.world.random_index, played.world.random_index, "%s: random" % where)
	assert_equal(again.world.objects.size(), played.world.objects.size(), "%s: objects" % where)
	assert_equal(again.camera.scroll, played.camera.scroll, "%s: the view" % where)


## Walking right with jumps and pogo bounces, now and then left, firing.
static func _input(frame: int) -> KeenInput:
	var direction := -1 if (frame / 40) % 3 == 2 else 1
	var input := KeenInput.create(direction, frame % 30 < 8, frame % 70 > 60)
	input.fire = frame % 25 == 0
	return input


## Every script under [param folder].
static func _scripts(folder: String) -> PackedStringArray:
	var found := PackedStringArray()
	var directory := DirAccess.open(folder)
	if directory == null:
		return found
	for file_name in directory.get_files():
		if file_name.ends_with(".gd"):
			found.append(folder.path_join(file_name))
	for sub in directory.get_directories():
		found.append_array(_scripts(folder.path_join(sub)))
	return found


static func _remove_recursive(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name in directory.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub in directory.get_directories():
		_remove_recursive(path.path_join(sub))
	DirAccess.remove_absolute(path)
