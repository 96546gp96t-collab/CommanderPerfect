extends "res://tests/test_case.gd"
## Tests for milestone B7 without Keen 2's files: Keen 2's high score table
## ([Keen2HighScores], [Keen2Screens]), saving and loading a Keen 2 game in
## its own folder, starting a new or loaded game ([Keen2LevelPlay]), and the
## main menu without online play, a second player or Keen 1's extra levels
## (while Keen 1's menu keeps them).

const TEST_DIRECTORY := "user://test_keen2_menus"
const NAMES: PackedStringArray = ["Yorpy", "Gargile", "Zzapp!"]


func test_new_high_score_table_has_the_default_names() -> void:
	var table := Keen2HighScores.load_from(_path("none.json"), NAMES)
	assert_equal(table.entries.size(), Keen2HighScores.PLACES, "seven places")
	assert_equal(table.entries[0].name, "Yorpy", "first name")
	assert_equal(table.entries[3].name, "", "no fourth name")
	assert_equal(table.entries[6].score, Keen2HighScores.DEFAULT_SCORE, "default score")
	assert_equal(table.entries[0].cities, 0, "no cities")


func test_high_scores_take_a_place_and_are_saved_with_cities() -> void:
	var path := _path("scores.json")
	var table := Keen2HighScores.load_from(path, NAMES)
	assert_equal(table.place_for(Keen2HighScores.DEFAULT_SCORE), -1, "too low")
	var place := table.place_for(5000)
	assert_equal(place, 0, "the top")
	table.insert(place, "A very long name indeed", 5000, 3)
	assert_equal(table.entries.size(), Keen2HighScores.PLACES, "still seven")
	assert_true(table.save(), "saved")
	var again := Keen2HighScores.load_from(path, NAMES)
	assert_equal(again.entries[0].score, 5000, "score")
	assert_equal(again.entries[0].cities, 3, "cities")
	assert_equal(again.entries[0].name.length(), Keen2HighScores.MAX_NAME_LENGTH, "name cut")
	assert_equal(again.entries[1].name, "Yorpy", "the old first is second")
	_remove(path)


func test_high_score_screen_shows_the_cities() -> void:
	var table := Keen2HighScores.load_from(_path("none.json"), NAMES)
	table.insert(0, "Billy", 12345, 8)
	var layer := PictureLayer.new()
	Keen2Screens.show_high_scores(layer, table)
	var bitmaps: Array = layer._bitmaps.map(func(item: Dictionary) -> String: return item.name)
	for name: String in ["HIGHSCOR", "NAME", "SCORE", "SAVED"]:
		assert_true(bitmaps.has(name), name)
	var texts: Array = layer._texts.map(func(item: Dictionary) -> String: return item.text)
	assert_true(texts.has("Billy") and texts.has("12345") and texts.has("8"), "the new entry")
	assert_equal(texts.count("0"), Keen2HighScores.PLACES - 1, "no cities for the others")
	layer.free()


func test_a_keen_2_game_is_saved_and_loaded_in_its_own_folder() -> void:
	var saves := SaveGames.in_directory(_path("saves"))
	var progress := Keen2Progress.new()
	progress.inventory.score = 777
	progress.inventory.charges = 3
	progress.complete_level(4)
	progress.map_position = Vector2(100, 200)
	assert_true(saves.write(2, progress), "saved in slot 2")
	var game := saves.read(2)
	assert_true(game != null, "read back")
	if game == null:
		return
	var loaded := Keen2Progress.from_game(game)
	assert_equal(loaded.inventory.score, 777, "score")
	assert_equal(loaded.inventory.charges, 3, "charges")
	assert_true(loaded.inventory.has_pogo, "the pogo stick")
	assert_equal(loaded.saved_city_count(), 1, "London is saved")
	assert_equal(loaded.map_position, Vector2(100, 200), "place on the map")
	assert_true(SaveGames.DEFAULT_DIRECTORY != Keen2MenuScreen.SAVES_DIRECTORY, "apart from Keen 1")
	_remove(_path("saves").path_join("slot2.json"))
	_remove(_path("saves"))


func test_new_game_starts_over() -> void:
	var play := Keen2LevelPlay.create(null, null)
	play.progress.complete_level(4)
	play.inventory.score = 100
	play.new_game()
	assert_equal(play.progress.saved_city_count(), 0, "no cities")
	assert_equal(play.inventory.score, 0, "no score")
	assert_true(play.inventory is Keen2Inventory, "Keen 2's inventory")
	var loaded := Keen2Progress.new()
	loaded.complete_level(6)
	play.new_game(loaded)
	assert_true(play.progress == loaded and play.inventory == loaded.inventory, "the loaded one")


func test_keen_2_menu_has_no_online_second_player_or_extra_levels() -> void:
	var labels := _main_menu_labels(false)
	for label in ["Online Game", "Add Player 2"]:
		assert_true(not labels.has(label), "no %s" % label)
	assert_true(labels.has("New Game") and labels.has("Choose Game"), "the rest")
	var menus := _menus(false)
	assert_true(not _has_extra_levels(menus._options_menu()), "no extra levels")
	menus.window.free()
	menus.free()


func test_keen_1_menu_keeps_online_second_player_and_extra_levels() -> void:
	var labels := _main_menu_labels(true)
	assert_true(labels.has("Online Game"), "online")
	assert_true(labels.has("Add Player 2"), "second player")
	var menus := _menus(true)
	assert_true(_has_extra_levels(menus._options_menu()), "extra levels")
	menus.window.free()
	menus.free()


## The labels of the main menu during a game, with Keen 1's offers on or off.
func _main_menu_labels(keen_1: bool) -> PackedStringArray:
	var menus := _menus(keen_1)
	menus.open_main(true, true)
	var labels := _labels(menus._top())
	menus.window.free()
	menus.free()
	return labels


func _menus(keen_1: bool) -> MenuController:
	var menus := MenuController.new()
	menus.window = GameWindow.new()
	if not keen_1:
		menus.offers_online = false
		menus.offers_second_player = false
		menus.offers_extra_levels = false
	return menus


static func _labels(menu: Menu) -> PackedStringArray:
	var labels := PackedStringArray()
	for item in menu.items:
		labels.append(item.label)
	return labels


static func _has_extra_levels(menu: Menu) -> bool:
	for label in _labels(menu):
		if label.begins_with("Extra levels"):
			return true
	return false


func _path(file_name: String) -> String:
	return TEST_DIRECTORY.path_join(file_name)


func _remove(path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
