extends "res://tests/test_case.gd"
## Tests for milestone C8 without Keen 3's files: the title and the high
## score table of map 90 ([Keen3Screens], names and scores only, in the
## font's second half), Keen 3's own high score file, saving and loading a
## Keen 3 game in its own folder ([Keen3SaveGames], [Keen3Progress] with the
## view's corner, Messie not saved), the place a save keeps on the map
## ([method Keen3MapSession.remember_place]) and the menus of
## [Keen3MenuScreen]: a second player and (with [Keen3OnlineScreen]) an
## online game since C10, no extra levels, saving only on the map, loading
## starts the game, the attract time.

const Maps := preload("res://tests/keen3_map_fixtures.gd")
const TEST_DIRECTORY := "user://test_keen3_menus"
const NAMES: PackedStringArray = ["Yorpy", "Gargile", "Zzapp!"]
const SLOT := 3
## Messie's loop and Keen's start on a small map (as in test_keen3_messie).
const MAP_SIZE := Vector2i(16, 12)
const LOOP := Rect2i(3, 3, 10, 6)
const KEEN_START := Vector2i(8, 6)


## A menu screen that remembers the game it was asked to start.
class StartingScreen:
	extends Keen3MenuScreen
	var started: Keen3Progress
	var starts := 0

	func _start_game(game: Keen3Progress) -> void:
		started = game
		starts += 1


func test_title_has_its_bitmaps_where_the_original_has_them() -> void:
	var layer := PictureLayer.new()
	Keen3Screens.show_title(layer)
	var origin := Vector2(32, 32)
	assert_equal(_bitmap_at(layer, "TITLE"), origin + Vector2(32, 1), "TITLE at (32,1)")
	assert_equal(_bitmap_at(layer, "F1HELP"), origin + Vector2(120, 182), "F1HELP at (120,182)")
	assert_equal(Keen3Screens.TITLE_SCREEN, Rect2i(2, 2, 20, 13), "cells 2-21 of map 90")
	layer.free()


func test_high_scores_show_names_and_scores_only() -> void:
	var table := Keen2HighScores.load_from(_path("none.json"), NAMES)
	table.insert(0, "Billy", 12345, 0)
	var layer := PictureLayer.new()
	Keen3Screens.show_high_scores(layer, table)
	var origin := Vector2(32, 32)
	assert_equal(_bitmap_at(layer, "HIGHSCOR"), origin + Vector2(88, 7), "HIGHSCOR")
	assert_equal(_bitmap_at(layer, "NAME"), origin + Vector2(80, 44), "NAME")
	assert_equal(_bitmap_at(layer, "SCORE"), origin + Vector2(192, 44), "SCORE")
	assert_equal(_bitmap_at(layer, "SAVED"), Vector2.INF, "no third column")
	assert_equal(layer._texts.size(), 2 * Keen2HighScores.PLACES, "a name and a score per place")
	var name: Dictionary = layer._texts[0]
	assert_equal(name.at, origin + Vector2(80, 64), "the first name at (80,64)")
	assert_equal(name.text, Keen3Window.label_text("Billy"), "in the font's second half")
	var score: Dictionary = layer._texts[1]
	var width := "12345".length() * EgaGraphics.FONT_CHAR_SIZE
	assert_equal(score.at, origin + Vector2(240 - width, 64), "the score ends at x 240")
	var second: Dictionary = layer._texts[2]
	assert_equal(second.at.y, origin.y + 64 + 16, "16 px a row")
	layer.free()


func test_keen_3_high_scores_have_their_own_file() -> void:
	var paths := [HighScores.DEFAULT_PATH, Keen2HighScores.DEFAULT_PATH]
	assert_true(not paths.has(Keen3MenuScreen.HIGH_SCORES_PATH), "apart from Keen 1 and 2")
	assert_true(Keen3MenuScreen.HIGH_SCORES_PATH.begins_with("user://keen3/"), "in keen3/")
	var path := _path("scores.json")
	var table := Keen2HighScores.load_from(path, NAMES)
	table.insert(table.place_for(500), "Keen", 500, 0)
	assert_true(table.save(), "saved")
	var again := Keen2HighScores.load_from(path, NAMES)
	assert_equal(again.entries[0].name, "Keen", "name")
	assert_equal(again.entries[0].score, 500, "score")
	_remove(path)


func test_a_keen_3_game_is_saved_and_loaded_in_its_own_folder() -> void:
	var saves := Keen3SaveGames.in_folder(_path("saves"))
	var progress := Keen3Progress.new()
	progress.inventory.score = 777
	progress.inventory.charges = 9
	progress.inventory.lives = 2
	progress.complete_level(4)
	progress.complete_level(15)
	progress.map_position = Vector2(100, 200)
	progress.map_corner = Vector2(48, 96)
	assert_true(saves.write(SLOT, progress), "saved")
	var game := saves.read(SLOT) as Keen3Progress
	assert_true(game != null, "read back as a Keen 3 game")
	if game == null:
		return
	assert_equal(game.inventory.score, 777, "score")
	assert_equal(game.inventory.charges, 9, "charges")
	assert_equal(game.inventory.lives, 2, "lives")
	assert_true(game.inventory.has_pogo, "the pogo stick")
	assert_equal(game.completed_levels(), PackedInt32Array([4, 15]), "done levels")
	assert_equal(game.map_position, Vector2(100, 200), "place on the map")
	assert_equal(game.map_corner, Vector2(48, 96), "the view's corner")
	assert_true(game.messie == null, "Messie starts at her start again")
	assert_equal(saves.summary(SLOT), "Score 777, 2 levels", "the menu's line")
	assert_equal(Keen3SaveGames.DIRECTORY, "user://keen3/saves", "Keen 3's folder")
	assert_true(SaveGames.DEFAULT_DIRECTORY != Keen3SaveGames.DIRECTORY, "apart from Keen 1")
	assert_true(Keen2MenuScreen.SAVES_DIRECTORY != Keen3SaveGames.DIRECTORY, "and Keen 2")
	_remove(_path("saves").path_join("slot%d.json" % SLOT))
	_remove(_path("saves"))


func test_a_game_without_a_view_corner_loads_without_one() -> void:
	var game := GameProgress.new()
	game.complete_level(2)
	var loaded := Keen3Progress.from_game(game, {Keen3Progress.MAP_CORNER_KEY: []})
	assert_true(not loaded.map_corner.is_finite(), "no corner")
	assert_true(loaded.is_completed(2), "the levels")
	var keen_3 := Keen3Progress.new()
	assert_equal(keen_3.to_dict()[Keen3Progress.MAP_CORNER_KEY], [], "saved as empty")


func test_a_save_keeps_keen_and_the_view_but_not_on_messie() -> void:
	var session := _open_map()
	session.keen.position = Maps.top_left(KEEN_START)
	session.remember_place()
	var game := session.progress as Keen3Progress
	assert_equal(game.map_position, session.keen.position, "Keen's place")
	assert_equal(game.map_corner, session.scroll.corner, "the view")
	session.messie.take_on()
	session.remember_place()
	assert_true(not game.map_corner.is_finite(), "on Messie the view is not kept")


func test_keen_3_menu_offers_a_second_player_but_no_extra_levels() -> void:
	var screen := StartingScreen.new()
	screen._menus.window = GameWindow.new()
	screen._set_up_menus()
	assert_true(screen._menus.offers_second_player, "a second player (C10)")
	assert_true(not screen._menus.offers_extra_levels, "no extra levels")
	assert_equal(screen._menus.saves.directory, Keen3SaveGames.DIRECTORY, "Keen 3's saves")
	screen._menus.open_main(true, true)
	var labels := PackedStringArray()
	for item in screen._menus._top().items:
		labels.append(item.label)
	for label in ["Add Player 2", "New Game", "Continue Game", "Save Game", "High Scores"]:
		assert_true(labels.has(label), label)
	assert_true(labels.has("Choose Game"), "Choose Game")
	screen._menus.window.free()
	_free_screen(screen)


func test_saving_only_on_the_world_map() -> void:
	var screen := StartingScreen.new()
	screen.play = Keen3LevelPlay.new()
	screen._mode = GameScreen.Mode.TITLE
	assert_true(not screen._can_save(), "not on the title")
	screen._mode = GameScreen.Mode.MAP
	assert_true(not screen._can_save(), "no map yet")
	screen.play.map_session = _open_map()
	screen.play.progress = screen.play.map_session.progress
	assert_true(screen._can_save(), "on the map")
	screen.play.map_session.outcome = MapSession.Outcome.ENTER_LEVEL
	assert_true(not screen._can_save(), "not while entering a level")
	screen._mode = GameScreen.Mode.LEVEL
	assert_true(not screen._can_save(), "not in a level")
	_free_screen(screen)


func test_the_menu_saves_and_loads_a_game() -> void:
	var screen := StartingScreen.new()
	screen._saves = Keen3SaveGames.in_folder(_path("menu_saves"))
	screen.play = Keen3LevelPlay.new()
	screen.play.map_session = _open_map()
	screen.play.progress = screen.play.map_session.progress
	screen.play.inventory = screen.play.progress.inventory
	screen.play.inventory.score = 4321
	screen.play.progress.complete_level(7)
	screen._mode = GameScreen.Mode.MAP
	screen._on_menu_chosen(MenuController.CHOICE_SAVE, SLOT)
	screen._on_menu_chosen(MenuController.CHOICE_LOAD, SLOT)
	assert_equal(screen.starts, 1, "the loaded game starts")
	var loaded := screen.started
	assert_true(loaded != null and loaded != screen.play.progress, "a new game object")
	if loaded != null:
		assert_equal(loaded.inventory.score, 4321, "its score")
		assert_true(loaded.is_completed(7), "its levels")
		assert_equal(loaded.map_position, screen.play.map_session.keen.position, "Keen's place")
	screen._on_menu_chosen(MenuController.CHOICE_NEW_GAME, 0)
	assert_true(screen.starts == 2 and screen.started == null, "a new game")
	_remove(_path("menu_saves").path_join("slot%d.json" % SLOT))
	_remove(_path("menu_saves"))
	_free_screen(screen)


func test_title_and_high_scores_take_turns_every_2400_clock_ticks() -> void:
	assert_true(absf(Keen3MenuScreen.ATTRACT_SECONDS - 16.48) < 0.01, "16.5 s")


func _open_map() -> Keen3MapSession:
	var infos: Dictionary[Vector2i, int] = {}
	for x in range(LOOP.position.x + 1, LOOP.end.x - 1):
		infos[Vector2i(x, LOOP.position.y)] = Keen3MapInfo.PATH
		infos[Vector2i(x, LOOP.end.y - 1)] = Keen3MapInfo.PATH
	for y in range(LOOP.position.y + 1, LOOP.end.y - 1):
		infos[Vector2i(LOOP.position.x, y)] = Keen3MapInfo.PATH
		infos[Vector2i(LOOP.end.x - 1, y)] = Keen3MapInfo.PATH
	return Maps.open_map(Maps.field_rows(MAP_SIZE), infos, KEEN_START)


## Where bitmap [param bitmap_name] is drawn, or INF when it is not.
static func _bitmap_at(layer: PictureLayer, bitmap_name: String) -> Vector2:
	for item in layer._bitmaps:
		if item.name == bitmap_name:
			return item.at
	return Vector2.INF


## Frees a screen that never entered the tree, with the nodes it made.
static func _free_screen(screen: Node) -> void:
	for property in screen.get_property_list():
		var value: Variant = screen.get(property.name)
		if value is Node and value != screen and is_instance_valid(value):
			if value.get_parent() == null:
				value.free()
	screen.free()


func _path(file_name: String) -> String:
	return TEST_DIRECTORY.path_join(file_name)


func _remove(path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
